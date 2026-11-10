"""Validate and package the installable addon using only the Python standard library."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import zipfile


ADDON = "AshenBuilds"
VERSION_RE = r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)"
ZIP_TIME = (1980, 1, 1, 0, 0, 0)
DEV_DIRECTORIES = {".git", ".github", ".venv", "venv", "dist", "tests", "tools", "__pycache__"}


class ReleaseError(ValueError):
    pass


def exact_file(root, relative):
    """Check portable paths component by component, including on case-insensitive Windows."""
    normalized = relative.replace("\\", "/")
    parts = normalized.split("/")
    if any(part in ("", ".", "..") or ":" in part or "\0" in part for part in parts):
        raise ReleaseError("Unsafe package path: " + relative)
    current = root
    for part in parts:
        if not current.is_dir() or part not in {entry.name for entry in current.iterdir()}:
            raise ReleaseError("Missing file or incorrect filename case: " + relative)
        current = current / part
        if current.is_symlink() or getattr(current, "is_junction", lambda: False)():
            raise ReleaseError("Symlinks are not allowed in packages: " + relative)
    if not current.is_file() or not current.resolve().is_relative_to(root.resolve()):
        raise ReleaseError("Not a regular file inside the addon: " + relative)
    return current


def validate(root, tag=None):
    root = Path(root)
    toc = exact_file(root, ADDON + ".toc")
    metadata, load_files = {}, []
    for line in toc.read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("##"):
            match = re.fullmatch(r"##\s*([^:]+):\s*(.*)", line)
            if match:
                key, value = match.group(1).strip(), match.group(2).strip()
                if key in metadata:
                    raise ReleaseError("Duplicate TOC metadata: " + key)
                metadata[key] = value
        elif not line.startswith("#"):
            exact_file(root, line)
            normalized = line.replace("\\", "/")
            if any(part.casefold() in DEV_DIRECTORIES for part in normalized.split("/")):
                raise ReleaseError("TOC references a development directory: " + line)
            load_files.append(normalized)
    version = metadata.get("Version", "")
    if not re.fullmatch(VERSION_RE, version):
        raise ReleaseError("TOC Version must be numeric x.y.z")
    for key, expected in (("Interface", "11200"), ("SavedVariables", "AshenBuildsDB")):
        if metadata.get(key) != expected:
            raise ReleaseError("TOC " + key + " must be " + expected)
    if "Core.lua" not in load_files or len(load_files) != len(set(load_files)):
        raise ReleaseError("TOC must load Core.lua once and contain no duplicate files")
    core = exact_file(root, "Core.lua").read_text(encoding="utf-8-sig")
    core_versions = re.findall(r'''(?m)^\s*AshenBuilds\.VERSION\s*=\s*["']([^"']+)["']''', core)
    if core_versions != [version]:
        raise ReleaseError("Core.lua VERSION must match TOC Version " + version)
    if tag is not None and tag != "v" + version:
        raise ReleaseError("Release tag must be v" + version)
    files = {ADDON + ".toc", *load_files}
    textures = root / "Textures"
    if not textures.is_dir() or textures.is_symlink() or getattr(textures, "is_junction", lambda: False)():
        raise ReleaseError("Missing regular Textures directory")
    for path in textures.rglob("*"):
        relative = path.relative_to(root).as_posix()
        if path.is_symlink() or getattr(path, "is_junction", lambda: False)():
            raise ReleaseError("Symlinks are not allowed in packages: " + relative)
        if path.is_file():
            if any(part.casefold() in DEV_DIRECTORIES for part in path.relative_to(textures).parts):
                continue
            exact_file(root, relative)
            files.add(relative)
    if not any(name.startswith("Textures/") for name in files):
        raise ReleaseError("Textures directory contains no files")
    for document in ("README.md", "CHANGELOG.md", "UPSTREAM.md"):
        if (root / document).exists():
            exact_file(root, document)
            files.add(document)
    if len({name.casefold() for name in files}) != len(files):
        raise ReleaseError("Package filenames collide on case-insensitive systems")
    return version, sorted(files)


def git_metadata(root, allow_dirty=False):
    def git(*args):
        try:
            return subprocess.check_output(["git", "-C", str(root), *args], text=True, stderr=subprocess.PIPE).strip()
        except (OSError, subprocess.CalledProcessError) as error:
            raise ReleaseError("A Git checkout is required for package provenance") from error

    if Path(git("rev-parse", "--show-toplevel")).resolve() != root.resolve():
        raise ReleaseError("Package source must be the Git repository root")
    commit = git("rev-parse", "HEAD")
    dirty = bool(git("status", "--porcelain", "--untracked-files=all"))
    if dirty and not allow_dirty:
        raise ReleaseError("Worktree is dirty; commit changes or use --allow-dirty for a local preview")
    return {"source_commit": commit, "dirty": dirty}


def build_release(root, output_dir, tag=None, allow_dirty=False):
    root = Path(root).resolve()
    version, files = validate(root, tag)
    provenance = {"addon": ADDON, "version": version, **git_metadata(root, allow_dirty)}
    payload = {name: exact_file(root, name).read_bytes() for name in files}
    payload["BUILD-INFO.json"] = (json.dumps(provenance, indent=2, sort_keys=True) + "\n").encode("utf-8")
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    archive = output_dir / (ADDON + "-" + version + ".zip")
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        for name, content in sorted(payload.items()):
            info = zipfile.ZipInfo(ADDON + "/" + name, date_time=ZIP_TIME)
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            package.writestr(info, content, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    checksum = archive.with_suffix(archive.suffix + ".sha256")
    checksum.write_text(digest + "  " + archive.name + "\n", encoding="ascii", newline="\n")
    return archive, checksum


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate without building or requiring Git")
    parser.add_argument("--output-dir", type=Path, default=Path("dist"))
    parser.add_argument("--tag", help="Require a tag matching the TOC version, for example v1.0.1")
    parser.add_argument("--allow-dirty", action="store_true", help="Allow a local preview and record dirty=true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    try:
        if args.check:
            version, files = validate(root, args.tag)
            print("Validated " + ADDON + " " + version + ": " + str(len(files)) + " package files")
        else:
            archive, checksum = build_release(root, args.output_dir, args.tag, args.allow_dirty)
            print(archive)
            print(checksum)
    except (ReleaseError, OSError, UnicodeError) as error:
        print("Release error: " + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
