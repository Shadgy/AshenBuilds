"""AtlasLoot evidence contracts; fixture data needs neither a game install nor SQLite."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

SPEC=importlib.util.spec_from_file_location("atlasloot_export",Path(__file__).resolve().parents[1]/"tools/build_atlasloot_sources.py")
source=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(source)


def title(label,group,context=None):
    result={1:label,2:group}
    if context:result[3]=context
    return result


class AtlasLootExportTests(unittest.TestCase):
    def test_real_raid_is_verified_at_its_own_phase(self):
        items,_,_=source.collect({"AtlasLootItems":{"UKHBoss":{1:{1:55285,2:"icon"}}}},
            {"UKHBoss":title("Keeper Gnarlmoon","AtlasLootItems","|cffff0000[RAID]|r Tower of Karazhan")},
            {},{},{"items":{55285:{"p":0}}})
        route=items[55285]["routes"][0]
        self.assertEqual((route["phase"],route["instance"],route["kind"]),(7,"Tower of Karazhan","raid"))

    def test_showcase_does_not_make_ashbringer_obtainable(self):
        data={"AtlasLootSetItems":{"Legendaries":{1:{1:13262},2:{1:18582}}},
              "AtlasLootItems":{"NAXHorsemen":{1:{1:22691}}}}
        titles={"Legendaries":title("Legendaries","AtlasLootSetItems"),
                "NAXHorsemen":title("Four Horsemen","AtlasLootItems","[RAID] Naxxramas")}
        items,_,_=source.collect(data,titles,{},{},{})
        self.assertNotIn(13262,items);self.assertNotIn(18582,items)
        self.assertEqual(items[22691]["routes"][0]["phase"],6)

    def test_crafting_spell_joins_product_without_confusing_spell_and_item_ids(self):
        data={"AtlasLootCrafting":{"Weapons":{1:{1:"s123",2:"icon"}}}}
        items,_,_=source.collect(data,{"Weapons":title("Crafted weapons","AtlasLootCrafting")},
            {"craftspells":{123:{"item":444}}},{},{"items":{444:{"p":2}}},{123:{444}})
        self.assertIn(444,items);self.assertNotIn(123,items)
        self.assertEqual(items[444]["routes"][0]["phase"],2)

    def test_crafting_presence_does_not_erase_a_future_recipe(self):
        data={"AtlasLootCrafting":{"Enchanting":{1:{1:"e25084"}}}}
        _,enchants,_=source.collect(data,{"Enchanting":title("Enchanting","AtlasLootCrafting")},
            {},{48:{"spell":25084}},{"enchants":{48:{"p":4}}})
        self.assertEqual(enchants[48]["routes"][0]["phase"],4)

    def test_incomplete_phase_stays_a_minimum_not_an_open_route(self):
        data={"AtlasLootCrafting":{"Enchanting":{1:{1:"e123"}}}}
        _,enchants,_=source.collect(data,{"Enchanting":title("Enchanting","AtlasLootCrafting")},
            {},{70:{"spell":123}},{"enchants":{70:{"l":6,"u":True}}})
        route=enchants[70]["routes"][0]
        self.assertNotIn("phase",route);self.assertEqual(route["minimumPhase"],6)

    def test_unknown_crafting_phase_does_not_default_to_zero(self):
        data={"AtlasLootCrafting":{"Enchanting":{1:{1:"e123"}}}}
        _,enchants,_=source.collect(data,{"Enchanting":title("Enchanting","AtlasLootCrafting")},{},{70:{"spell":123}},{})
        self.assertNotIn("phase",enchants[70]["routes"][0])

    def test_enchant_application_item_and_recipe_keep_acquisition_context(self):
        data={"AtlasLootItems":{"Sapphiron":{1:{1:23548}},"Timbermaw":{1:{1:42187}}}}
        titles={"Sapphiron":title("Sapphiron","AtlasLootItems","[RAID] Naxxramas"),
                "Timbermaw":title("Kronn","AtlasLootItems","[RAID] Timbermaw Hold")}
        _,enchants,_=source.collect(data,titles,{}, {37:{"spell":29480},149016:{"spell":49016}}, {},
            application={29480:{23548}},taught={49016:{42187}})
        self.assertEqual(enchants[37]["routes"][0]["phase"],6)
        self.assertEqual(enchants[149016]["routes"][0]["phase"],5)
        self.assertEqual(enchants[149016]["routes"][0]["recipe"],42187)

    def test_unregistered_nested_craft_rewards_remain_acquisition_evidence(self):
        items,_,_=source.collect({"AtlasLootCrafting":{"SteelPlateC":{1:{1:{1:83415}}}}},
                                 {},{},{},{"items":{83415:{"p":0}}})
        self.assertEqual(items[83415]["routes"][0]["kind"],"craft")

    def test_pvp_rank_is_taken_from_the_actual_acquisition_row(self):
        data={"AtlasLootGeneralPvPItems":{"PVPHunter":{1:{1:16466,4:"=q7=Rank 13"}},
                                            "PVPHunterAC":{1:{1:{1:16466}}}}}
        items,_,_=source.collect(data,{"PVPHunter":title("PvP Hunter","AtlasLootGeneralPvPItems")},{},{},{})
        self.assertEqual(items[16466]["routes"],[{"table":"PVPHunter","source":"PvP Hunter","kind":"pvp","rank":13,"phase":3}])

    def test_real_tier_set_can_supply_its_phase_without_showcase_laundering(self):
        data={"AtlasLootSetItems":{"T3Paladin":{1:{1:22428}},"T35Warrior":{1:{1:90000}},
                                   "T25Paladin":{1:{1:21389}},"Legendaries":{1:{1:13262}}}}
        items,_,_=source.collect(data,{}, {},{},{"items":{13262:{"p":0}}})
        self.assertEqual(items[22428]["routes"][0]["phase"],6)
        self.assertEqual(items[90000]["routes"][0]["phase"],7)
        self.assertEqual(items[21389]["routes"][0]["phase"],4)
        self.assertNotIn(13262,items)

    def test_tier2_helmet_retains_a_real_earlier_onyxia_route(self):
        data={"AtlasLootSetItems":{"T2Paladin":{1:{1:16955}}}}
        summaries={"items":{16955:{"p":0,"z":[249]}},"locations":{249:{"name":"Onyxia's Lair","type":2,"phase":0}}}
        items,_,_=source.collect(data,{}, {},{},summaries)
        self.assertEqual((items[16955]["routes"][0]["phase"],items[16955]["routes"][0]["instance"]),(0,"Onyxia's Lair"))

    def test_curated_removed_or_temporary_items_are_never_promoted(self):
        data={"AtlasLootItems":{"Boss":{1:{1:17782},2:{1:22736}}}}
        items,_,_=source.collect(data,{"Boss":title("Boss","AtlasLootItems","[RAID] Molten Core")},{},{},{})
        self.assertFalse(items)

    def test_pvp_headers_are_inherited_in_numeric_row_order(self):
        data={"AtlasLootGeneralPvPItems":{"PVPWeapons1":{1:{1:0,3:"Rank 14"},2:{1:700},
                  10:{1:0,3:"Rank 11"},11:{1:701}}}}
        items,_,_=source.collect(data,{}, {},{},{})
        self.assertEqual(items[700]["routes"][0]["phase"],6)
        self.assertEqual(items[700]["routes"][0]["rank"],14)
        self.assertEqual(items[701]["routes"][0]["phase"],1)

    def test_set_earlier_phase_does_not_keep_an_unproven_bwl_instance(self):
        data={"AtlasLootSetItems":{"T2Paladin":{1:{1:42}}}}
        items,_,_=source.collect(data,{}, {},{},{"items":{42:{"p":0,"z":[0]}},"locations":{0:{"name":"World","type":0,"phase":0}}})
        self.assertEqual(items[42]["routes"][0]["phase"],0)
        self.assertNotIn("instance",items[42]["routes"][0])

    def test_application_join_can_use_resolved_enchant_phase(self):
        data={"AtlasLootCrafting":{"Engineering":{1:{1:12645}}}}
        _,enchants,_=source.collect(data,{}, {},{14:{"spell":16623}}, {"enchants":{14:{"p":0}}},application={16623:{12645}})
        self.assertEqual(enchants[14]["routes"][0]["phase"],0)

    def test_instance_wings_use_the_same_names_as_content_filters(self):
        for raw,canonical in (("Dire Maul (East)","Dire Maul"),("Lower Blackrock Spire","Blackrock Spire"),
                              ("The Sunken Temple","The Temple of Atal'Hakkar")):
            with self.subTest(raw=raw):
                route=source.table_route("Boss","AtlasLootItems",title("Boss","AtlasLootItems","[50-60] "+raw))
                self.assertEqual(route["instance"],canonical)

    def test_generic_collection_cannot_reopen_a_phased_event_reward(self):
        data={"AtlasLootWorldEvents":{"ScourgeInvasionEvent1":{1:{1:22999}}},
              "AtlasLootSetItems":{"Tabards":{1:{1:22999}}}}
        items,_,_=source.collect(data,{}, {},{},{"items":{22999:{"p":0}}})
        self.assertEqual(len(items[22999]["routes"]),1)
        self.assertEqual(items[22999]["routes"][0]["phase"],6)

    def test_actual_onyxia_helmet_source_replaces_generic_tier2_alias(self):
        data={"AtlasLootItems":{"Onyxia":{1:{1:16955}}},"AtlasLootSetItems":{"T2Paladin":{1:{1:16955}}}}
        titles={"Onyxia":title("Onyxia","AtlasLootItems","[RAID] Onyxia's Lair")}
        items,_,_=source.collect(data,titles,{}, {},{"items":{16955:{"p":0}}})
        self.assertEqual(items[16955]["routes"],[{"table":"Onyxia","kind":"raid","source":"Onyxia","instance":"Onyxia's Lair","phase":0}])

    def test_declarative_loader_resolves_localized_labels(self):
        loader=source.DataLoader()
        loader.load('local AL=AtlasLoot.L; AtlasLoot_Data["AtlasLootItems"]={Test={{42,"icon",AL["Test"]}}}')
        self.assertEqual(loader.env["AtlasLoot_Data"]["AtlasLootItems"]["Test"][1][3],"Test")

    def test_declarative_loader_rejects_functions_calls_and_loops(self):
        for text in ('os.execute("bad")','while true do end','x=function() end','x=loadstring("bad")'):
            with self.subTest(text=text),self.assertRaises(ValueError):source.DataLoader().load(text)

    def test_loader_does_not_treat_comment_or_label_words_as_code(self):
        loader=source.DataLoader()
        loader.load('-- while (bad)\nAtlasLoot_Data["AtlasLootItems"]={Test={{42,"for (if) -- label"}}}')
        self.assertEqual(loader.env["AtlasLoot_Data"]["AtlasLootItems"]["Test"][1][1],42)

    def test_output_is_deterministic_and_uses_original_item_ids(self):
        data={"meta":{"version":"fixture"},"items":{42:{"routes":[{"table":"Test","phase":0}]}},"enchants":{}}
        root=Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(dir=root) as temporary:
            self.assertTrue(Path(temporary).resolve().is_relative_to(root))
            path=Path(temporary)/"data.lua";source.write(data,path);first=path.read_bytes();source.write(data,path)
            self.assertEqual(first,path.read_bytes());self.assertIn(b"I[42]",first)


if __name__=="__main__":unittest.main()
