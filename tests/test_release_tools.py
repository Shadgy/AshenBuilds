"""Release contract tests; fixtures do not need a Git repository or Lua runtime."""

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock
import zipfile


SCRIPT = Path(__file__).resolve().parents[1] / "tools" / "package_release.py"
SPEC = importlib.util.spec_from_file_location("package_release", SCRIPT)
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="release-fixture-", dir=Path(__file__).resolve().parent)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "source"
        self.root.mkdir()
        self.output = Path(self.temp.name) / "dist"
        self.toc = (
            "## Interface: 11200\n## Version: 2.3.4\n"
            "## SavedVariables: AshenBuildsDB\nCore.lua\nData\\Items.lua\n"
        )
        self.write("AshenBuilds.toc", self.toc)
        self.write("Core.lua", 'AshenBuilds = {}\nAshenBuilds.VERSION = "2.3.4"\n')
        self.write("Data/Items.lua", "Items = {}\n")
        self.write("Textures/Buttons/button.tga", "texture fixture")

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")

    def build(self, **kwargs):
        with mock.patch.object(release, "git_metadata", return_value={"source_commit": "a" * 40, "dirty": False}):
            return release.build_release(self.root, self.output, **kwargs)

    def test_installable_contents_and_provenance(self):
        for name in ("README.md", "CHANGELOG.md", "UPSTREAM.md", "tests/test_dev.lua", "tools/work/private.sqlite", ".github/workflows/tests.yml", ".git/config", ".venv/secret", "dist/old.zip", "Textures/.git/config"):
            self.write(name, "fixture\n")
        archive, checksum = self.build(tag="v2.3.4")
        with zipfile.ZipFile(archive) as package:
            self.assertEqual(set(package.namelist()), {
                "AshenBuilds/AshenBuilds.toc", "AshenBuilds/Core.lua", "AshenBuilds/Data/Items.lua",
                "AshenBuilds/Textures/Buttons/button.tga", "AshenBuilds/README.md",
                "AshenBuilds/CHANGELOG.md", "AshenBuilds/UPSTREAM.md", "AshenBuilds/BUILD-INFO.json",
            })
            info = json.loads(package.read("AshenBuilds/BUILD-INFO.json"))
            self.assertEqual(info, {"addon": "AshenBuilds", "version": "2.3.4", "source_commit": "a" * 40, "dirty": False})
        self.assertEqual(checksum.read_text().split()[0], hashlib.sha256(archive.read_bytes()).hexdigest())

    def test_deterministic_archive(self):
        archive, checksum = self.build()
        first_bytes, first_checksum = archive.read_bytes(), checksum.read_bytes()
        (self.root / "Core.lua").touch()
        archive, checksum = self.build()
        self.assertEqual(archive.read_bytes(), first_bytes)
        self.assertEqual(checksum.read_bytes(), first_checksum)
        with zipfile.ZipFile(archive) as package:
            self.assertTrue(all(info.date_time == release.ZIP_TIME for info in package.infolist()))
            self.assertTrue(all(info.external_attr >> 16 == 0o100644 for info in package.infolist()))

    def test_mismatched_or_non_numeric_version(self):
        self.write("Core.lua", 'AshenBuilds.VERSION = "2.3.5"\n')
        with self.assertRaisesRegex(release.ReleaseError, "must match"):
            release.validate(self.root)
        self.write("AshenBuilds.toc", self.toc.replace("2.3.4", "2.3.4-beta"))
        with self.assertRaisesRegex(release.ReleaseError, "numeric"):
            release.validate(self.root)

    def test_required_metadata(self):
        for field, bad_value in (("11200", "11400"), ("AshenBuildsDB", "OtherDB")):
            with self.subTest(field=field):
                self.write("AshenBuilds.toc", self.toc.replace(field, bad_value))
                with self.assertRaises(release.ReleaseError):
                    release.validate(self.root)

    def test_missing_or_wrong_case_load_file(self):
        for name in ("Data/Missing.lua", "data/Items.lua", "Data/items.lua"):
            with self.subTest(name=name):
                self.write("AshenBuilds.toc", self.toc.replace("Data\\Items.lua", name))
                with self.assertRaisesRegex(release.ReleaseError, "Missing file|case"):
                    release.validate(self.root)

    def test_path_traversal_and_absolute_paths(self):
        for name in ("../outside.lua", "/outside.lua", "C:\\outside.lua", "Data/../Core.lua"):
            with self.subTest(name=name):
                self.write("AshenBuilds.toc", self.toc.replace("Data\\Items.lua", name))
                with self.assertRaisesRegex(release.ReleaseError, "Unsafe"):
                    release.validate(self.root)

    def test_tag_mismatch(self):
        with self.assertRaisesRegex(release.ReleaseError, "tag must be v2.3.4"):
            release.validate(self.root, "v2.3.5")

    def test_toc_cannot_include_development_files(self):
        self.write("tests/private.lua", "private")
        self.write("AshenBuilds.toc", self.toc + "tests/private.lua\n")
        with self.assertRaisesRegex(release.ReleaseError, "development directory"):
            release.validate(self.root)

    def test_check_does_not_require_git(self):
        with mock.patch.object(release, "git_metadata", side_effect=AssertionError("Git must not be called")):
            self.assertEqual(release.validate(self.root)[0], "2.3.4")

    def test_dirty_worktree_rejected_or_reported(self):
        def fake_git(command, **kwargs):
            if command[-1] == "--show-toplevel":
                return str(self.root) + "\n"
            if command[-1] == "HEAD":
                return "b" * 40 + "\n"
            return " M Core.lua\n"

        with mock.patch.object(release.subprocess, "check_output", side_effect=fake_git):
            with self.assertRaisesRegex(release.ReleaseError, "dirty"):
                release.build_release(self.root, self.output)
            archive, _ = release.build_release(self.root, self.output, allow_dirty=True)
        with zipfile.ZipFile(archive) as package:
            self.assertTrue(json.loads(package.read("AshenBuilds/BUILD-INFO.json"))["dirty"])

    def test_symlink_cannot_escape_package(self):
        outside = Path(self.temp.name) / "outside.lua"
        outside.write_text("outside", encoding="utf-8")
        link = self.root / "Data" / "link.lua"
        try:
            link.symlink_to(outside)
        except OSError:
            self.skipTest("Creating symlinks requires local permissions")
        self.write("AshenBuilds.toc", self.toc.replace("Data\\Items.lua", "Data/link.lua"))
        with self.assertRaisesRegex(release.ReleaseError, "Symlinks"):
            release.validate(self.root)


if __name__ == "__main__":
    unittest.main()
