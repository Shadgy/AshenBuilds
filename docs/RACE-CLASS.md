# Octo profile selection (local 1.0.6)

CLASS, RACE and BUILD now open menus while retaining their existing header art.
Unavailable combinations are visible in grey, cannot be selected and explain the
restriction on hover. Race choices depend on the selected class; class choices
depend on the selected race. Changing to another class also requires an explicit
talent reset, as before. BUILD retains the existing label/form behavior; it does
not replace the allocated talent tree with a new preset.

Old saved/imported incompatible plans are preserved with a calculation warning.
Choose an available race or class to repair them. Reading a menu and selecting
the already-current value do not modify a saved plan or clear its custom label.

## Supported combinations

Checked against Octo's official pages on 2026-11-10: 59 allowed pairs.

| Race | Available classes |
| --- | --- |
| Human | Warrior, Paladin, Hunter, Rogue, Priest, Mage, Warlock |
| Dwarf | Warrior, Paladin, Hunter, Rogue, Priest, Mage, Warlock |
| Night Elf | Warrior, Hunter, Rogue, Priest, Druid |
| Gnome | Warrior, Hunter, Rogue, Mage, Warlock |
| Orc | Warrior, Hunter, Rogue, Shaman, Mage, Warlock |
| Tauren | Warrior, Hunter, Priest, Shaman, Druid |
| Troll | Warrior, Hunter, Rogue, Priest, Shaman, Mage, Warlock |
| Undead | Warrior, Hunter, Rogue, Priest, Mage, Warlock |
| High Elf | Warrior, Paladin, Hunter, Rogue, Priest, Mage |
| Goblin | Warrior, Hunter, Rogue, Mage, Warlock |

Sources:

- [Additional Octo class/race combinations](https://forge.octowow.st/class-race-combinations)
  explicitly adds Tauren Priest, Dwarf Warlock, Orc Mage, Dwarf Mage, Gnome Hunter,
  Undead Hunter, Human Hunter and Troll Warlock to the vanilla combinations.
- [High Elves](https://forge.octowow.st/high-elves) and its
  [available-class artwork](https://forge.octowow.st/turtle_assets/build/assets/classes-DXRvdrjP.png).
- [Goblins](https://forge.octowow.st/goblins) and its
  [available-class artwork](https://forge.octowow.st/turtle_assets/build/assets/classes_gob-DZgkbhZU.png).

The addon stat dataset contains only 40 vanilla race/class rows. Missing rows use
the existing racial-offset fallback; their absence is not evidence that an Octo
combination is unavailable. The matrix follows the official public material, not
a direct test of every choice on the character-creation screen.

## Client checks

1. Each header button opens a menu; opening it does not change the current value.
2. Pick a valid class/race/build in one selection. Current choices are checked.
3. For Tauren Warrior, Rogue is grey and unavailable. For Human Rogue, Tauren is
   grey and unavailable. The tooltip explains the restriction.
4. Dwarf Warlock and Tauren Priest remain available on Octo.
5. With allocated talents, other classes are unavailable until Reset Talents;
   race and build choices still respect their own restrictions.
6. Open other addon dropdowns afterward: valid rows regain normal color and
   behavior. Save/load retains the selected profile and equipment.

Crit remains deferred and publication remains unauthorized.
