"""The shield supplement must preserve source zeros and reject incomplete inputs."""
import importlib.util
from contextlib import closing
from pathlib import Path
import sqlite3
import tempfile
import unittest


ROOT=Path(__file__).resolve().parents[1]
SPEC=importlib.util.spec_from_file_location("build_shield_block",ROOT/"tools/build_shield_block.py")
exporter=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(exporter)


class ShieldExportTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix="shield-fixture-",dir=ROOT/"tests")
        self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name)
        items=self.root/"Data/AshenDB/Data/Items"
        items.mkdir(parents=True)
        (items/"Items_001.lua").write_text('I[1]={"Shield",2,"SHIELD"}\nI[2]={"Zero shield",1,"SHIELD"}\n',encoding="utf-8")
        self.db=self.root/"source.sqlite"
        with closing(sqlite3.connect(self.db)) as connection, connection:
            connection.execute("create table items (entry integer, inventory_type integer, block integer)")
            connection.executemany("insert into items values (?,?,?)",[(1,14,54),(2,14,0),(3,1,0)])
        self.out=self.root/"ShieldBlock.lua"

    def test_native_values_zero_provenance_and_repeatable_output(self):
        meta=exporter.build(self.db,self.out,"2026-11-10",self.root)
        first=self.out.read_bytes()
        self.assertIn(b"[1]=54",first)
        self.assertIn(b"[2]=0",first)
        self.assertEqual(meta["count"],2)
        self.assertTrue(meta["sqliteSha256"].startswith(meta["sourceVersion"]))
        exporter.build(self.db,self.out,"2026-11-10",self.root)
        self.assertEqual(self.out.read_bytes(),first)

    def test_missing_or_null_native_values_fail_instead_of_inventing_zero(self):
        with closing(sqlite3.connect(self.db)) as connection, connection:
            connection.execute("delete from items where entry=2")
        with self.assertRaisesRegex(ValueError,"lacks embedded shield"):
            exporter.build(self.db,self.out,"2026-11-10",self.root)
        with closing(sqlite3.connect(self.db)) as connection, connection:
            connection.execute("insert into items values (2,14,null)")
        with self.assertRaisesRegex(ValueError,"Invalid native shield block"):
            exporter.build(self.db,self.out,"2026-11-10",self.root)


if __name__=="__main__":
    unittest.main()
