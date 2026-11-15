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

    def test_on_use_tool_resolves_a_craft_chain_without_bypassing_material_phases(self):
        graph=self.crafting_graph(tool=route(2,zones=(469,)),material=route(4,zones=(531,)))
        result=graph.spell(20)
        self.assertEqual(result["p"],4)
        self.assertEqual(result["l"],4)
        self.assertEqual(graph.spell(10)["z"],{469})
        self.assertEqual(result["z"],set())

    def test_on_use_alone_does_not_promote_an_aura_or_teaching_spell(self):
        graph=self.crafting_graph(tool=route(0),material=route(0))
        graph.creation_spells=set()
        self.assertIsNone(graph.spell(10)["p"])

    def test_unknown_reagent_leaves_craft_phase_unresolved(self):
        graph=self.crafting_graph(tool=route(2),material=source.Sources.unknown())
        result=graph.spell(20)
        self.assertIsNone(result["p"])
        self.assertEqual(result["l"],2)

    @staticmethod
    def crafting_graph(tool,material):
        graph=source.Sources.__new__(source.Sources)
        graph.creation_spells={10,20}
        graph.application_items={10:{1}}
        graph.spell_sources={20:[("profession",0)]}
        graph.reagents={10:[2],20:[3]}
        graph.cache={}; graph.busy=set()
        def item(item_id):
            if item_id==3:
                return graph.spell(10)
            return {1:tool,2:material}[item_id]
        graph.item=item
        return graph

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
