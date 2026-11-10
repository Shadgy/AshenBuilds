"""Regression checks for maintaining versions and selecting test suites."""
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("set_version", ROOT / "tools" / "set_version.py")
versions = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(versions)


class MaintenanceToolsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="maintenance-fixture-", dir=ROOT / "tests")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "AshenBuilds.toc").write_text("## Version: 1.0.1\nCore.lua\n", encoding="utf-8")
        (self.root / "Core.lua").write_text('AshenBuilds.VERSION = "1.0.1"\n', encoding="utf-8")

    def test_version_update_keeps_metadata_and_runtime_together(self):
        versions.set_version("1.0.2", self.root)
        self.assertEqual((self.root / "AshenBuilds.toc").read_text(), "## Version: 1.0.2\nCore.lua\n")
        self.assertEqual((self.root / "Core.lua").read_text(), 'AshenBuilds.VERSION = "1.0.2"\n')

    def test_bad_version_or_inconsistent_source_does_not_change_files(self):
        for version in ("v1.0.2", "1.0.2-beta.1", "01.0.2", "1.2"):
            with self.subTest(version=version), self.assertRaises(ValueError):
                versions.set_version(version, self.root)
        original = (self.root / "AshenBuilds.toc").read_bytes()
        (self.root / "Core.lua").write_text('AshenBuilds.VERSION = "9.0.0"\n', encoding="utf-8")
        with self.assertRaises(ValueError):
            versions.set_version("1.0.2", self.root)
        self.assertEqual((self.root / "AshenBuilds.toc").read_bytes(), original)

    def test_empty_suite_selection_fails(self):
        result = subprocess.run([sys.executable, str(ROOT / "tests" / "run.py"), "no-such-suite-928372"],
                                cwd=ROOT, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("NO TEST SUITES MATCH", result.stdout)


if __name__ == "__main__":
    unittest.main()
