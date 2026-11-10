"""Source graph contracts; no downloaded SQLite snapshot is needed in CI."""
from collections import defaultdict
import importlib.util
from pathlib import Path
import unittest


SPEC=importlib.util.spec_from_file_location("content_sources",Path(__file__).resolve().parents[1]/"tools/build_content_sources.py")
source=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(source)


def route(phase,minimum=None,unknown=False,zones=()):
    return {"p":phase,"l":phase if minimum is None else minimum,"u":unknown,"z":set(zones),"r":1}


class ContentSourceGraphTests(unittest.TestCase):
    def test_one_open_alternative_wins_over_future_route(self):
        result=source.Sources.any([route(0,zones=(0,)),route(6,zones=(533,))])
        self.assertEqual(result["p"],0)
        self.assertEqual(result["l"],0)
        self.assertEqual(result["z"],{0,533})

    def test_all_required_ingredients_use_latest_phase(self):
        result=source.Sources.required([route(0),route(4),route(2)])
        self.assertEqual(result["p"],4)
        self.assertEqual(result["l"],4)

    def test_unknown_alternative_prevents_future_only_claim(self):
        result=source.Sources.any([route(6),source.Sources.unknown()])
        self.assertEqual(result["p"],6)
        self.assertEqual(result["l"],0)
        self.assertTrue(result["u"])

    def test_unknown_material_does_not_bypass_required_future_recipe(self):
        result=source.Sources.required([route(4),source.Sources.unknown()])
        self.assertIsNone(result["p"])
        self.assertEqual(result["l"],4)
        self.assertTrue(result["u"])

    def test_container_cycle_stays_unknown_without_recursing_forever(self):
        graph=source.Sources.__new__(source.Sources)
        graph.items={1:{"required_honor_rank":0},2:{"required_honor_rank":0}}
        graph.routes=defaultdict(list,{1:[("i",2)],2:[("i",1)]})
        graph.categories=defaultdict(set)
        graph.cache={}; graph.busy=set()
        result=graph.item(1)
        self.assertIsNone(result["p"])
        self.assertEqual(result["l"],0)
        self.assertTrue(result["u"])
        self.assertFalse(graph.busy)

    def test_hidden_map_is_neither_a_route_nor_a_dropdown_location(self):
        maps={29:{"name":"CashTest","type":1,"hidden":1},
              469:{"name":"Blackwing Lair","type":2,"hidden":0}}
        graph=source.Sources.__new__(source.Sources); graph.maps=maps
        result=graph.location({29})
        self.assertIsNone(result["p"])
        self.assertFalse(result["z"])
        exported=source.location_records(maps)
        self.assertNotIn(29,exported)
        self.assertEqual(exported[469]["phase"],2)


if __name__=="__main__": unittest.main()
