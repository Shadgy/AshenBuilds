"""Keep the recorded enchant effect reproducible by its source generator."""
import importlib.util
from pathlib import Path
import unittest


path = Path(__file__).resolve().parents[1] / "tools" / "build_enchants.py"
spec = importlib.util.spec_from_file_location("build_enchants", path)
enchants = importlib.util.module_from_spec(spec)
spec.loader.exec_module(enchants)


class EnchantStatsTests(unittest.TestCase):
    def test_sigil_reduces_received_crit_only(self):
        stats = enchants.parse_stats(
            "Permanently reduces your chance to be critically hit by melee and "
            "ranged attacks by -3% to a shoulder slot item."
        )
        self.assertEqual(stats, {"critTakenReduction": 3})

    def test_critical_damage_reduction_is_a_different_effect(self):
        stats = enchants.parse_stats(
            "Attaches a buckle to your belt that reduces damage taken from "
            "critical hits and damage over time effects by -3%."
        )
        self.assertEqual(stats, {})


if __name__ == "__main__":
    unittest.main()
