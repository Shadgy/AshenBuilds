"""Update the TOC and runtime version together: python tools/set_version.py 1.0.2."""
import argparse
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
VERSION = re.compile(r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\Z")


def set_version(version, root=ROOT):
    if not VERSION.fullmatch(version):
        raise ValueError("Use a numeric version such as 1.0.2 (no v prefix or suffix)")
    edits = []
    for filename, pattern in (
        ("AshenBuilds.toc", r"(?m)^(## Version: )([^\r\n]+)$"),
        ("Core.lua", r'(?m)^(AshenBuilds\.VERSION = ")([^"\r\n]+)(")$'),
    ):
        path = Path(root) / filename
        source = path.read_text(encoding="utf-8")
        matches = list(re.finditer(pattern, source))
        if len(matches) != 1:
            raise ValueError("Expected exactly one version in " + filename)
        match = matches[0]
        edits.append((path, source[:match.start(2)] + version + source[match.end(2):], match.group(2)))
    if edits[0][2] != edits[1][2]:
        raise ValueError("TOC and runtime versions disagree; repair them before bumping")
    for path, content, _ in edits:
        path.write_text(content, encoding="utf-8", newline="\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    args = parser.parse_args()
    try:
        set_version(args.version)
    except ValueError as exc:
        parser.error(str(exc))
    print("TOC and Core.lua version set to " + args.version)


if __name__ == "__main__":
    main()
