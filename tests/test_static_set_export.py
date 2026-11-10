"""Conservative aura classification prevents set procs from becoming permanent stats."""
import importlib.util
from pathlib import Path
import unittest
import json


ROOT=Path(__file__).resolve().parents[1]
SPEC=importlib.util.spec_from_file_location("build_static_set_stats",ROOT/"tools/build_static_set_stats.py")
exporter=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(exporter)


def spell(effects,**overrides):
    row={"duration_ms":-1,"class_mask":0,"proc_chance":101,"attr":192,
         "name":"Static bonus","description":"Increases a statistic.","effects":json.dumps(effects)}
    row.update(overrides)
    return row


def aura(aura,value,misc=0):return {"effect":6,"aura":aura,"value":value,"misc":misc,"period":0,"radius":None}


class StaticSetExportTests(unittest.TestCase):
    def test_defense_block_and_resist_effects(self):
        self.assertEqual(exporter.spell_stats(spell([aura(30,3,95)])),({"defense":3},None))
        self.assertEqual(exporter.spell_stats(spell([aura(158,30)])),({"blockValue":30},None))
        stats,reason=exporter.spell_stats(spell([aura(22,15,126)]))
        self.assertIsNone(reason)
        self.assertEqual(stats,{"fireRes":15,"natureRes":15,"frostRes":15,"shadowRes":15,"arcaneRes":15})

    def test_hit_is_not_spell_crit_and_attack_power_is_not_doubled(self):
        self.assertEqual(exporter.spell_stats(spell([aura(55,2)])),({"spellHit":2},None))
        self.assertEqual(exporter.spell_stats(spell([aura(99,40),aura(124,40)])),({"ap":40},None))
        self.assertEqual(exporter.spell_stats(spell([aura(124,12)])),({"rap":12},None))

    def test_conditional_proc_scoped_or_partial_effects_are_not_global(self):
        cases=[spell([aura(52,2)],description="Increases critical strike chance while in Berserker Stance."),
               spell([aura(52,2)],duration_ms=10000),spell([aura(52,2)],class_mask=1),
               spell([aura(52,2)],proc_chance=20),spell([aura(71,2,4)]),spell([aura(35,10,3)]),
               spell([aura(99,56)],description="Attack power in Cat Form."),
               spell([aura(99,56)]),spell([aura(22,10,2)])]
        for case in cases:
            with self.subTest(case=case):
                stats,reason=exporter.spell_stats(case)
                self.assertIsNone(stats)
                self.assertTrue(reason)

    def test_unconditional_mixed_spell_preserves_known_stats_and_unknown_note(self):
        stats,reason=exporter.spell_stats(spell([aura(158,67),aura(108,40,2)]))
        self.assertEqual(stats,{"blockValue":67})
        self.assertIn("unsupported aura 108",reason)
        stats,reason=exporter.spell_stats(spell([aura(22,50,1)]))
        self.assertEqual(stats,{"bonusArmor":50})
        self.assertIsNone(reason)


if __name__=="__main__":unittest.main()
