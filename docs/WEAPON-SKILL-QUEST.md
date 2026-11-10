# Weapon skill quest preview (1.0.3)

At the top of the planner, select a weapon family beside **Weapon skill quest +5**
and tick it if the planned character has completed that family's mastery. Each
family is remembered independently. Sword, Axe and Mace mastery covers both the
one- and two-handed skill lines; a Sword book does not improve an off-hand Axe.

The bonus is a weapon-skill contribution. It stacks once with racial, gear and
talent skill and enters the existing simulator's attack-table calculations. It is
not a flat Hit bonus. There is no new hard cap imposed on the displayed skill total.

Available families: swords, maces, axes, daggers, fist weapons, polearms, staves,
thrown weapons, bows, crossbows and guns. Shields, wands, unarmed, fishing poles
and feral attacks do not receive this preview bonus.

## Level and source scope

The prerequisite quests list level 55, whereas mastery book item pages list level
60. The planner conservatively enables the book preview at level 60; it does not
claim to certify the earliest quest-completion level on the running server.

Checked sources:

- User-provided [weapon skill dataset](https://docs.google.com/spreadsheets/d/1b5wfBLYoopE7_4r2lhrJHx395K1AlZKx8qMeu821nW4/htmlview#gid=0), read through its public CSV export on 2026-11-10. It distinguishes racial skill and mastery books from flat Hit.
- [Weapon Skill wiki](https://turtle-wow.fandom.com/wiki/Weapon_Skill), describing the mastery quest chain.
- [Octo weapon skill guide](https://octowow.st/forum/viewtopic.php?t=1666), describing separate weapon-specific quests/books.
- Octo item pages for [Sword mastery 70228](https://octowow.st/db/?item=70228) and [Mace mastery 70229](https://octowow.st/db/?item=70229), which list level 60; [Iron Determination 41387](https://octowow.st/db/?quest=41387) lists the level-55 prerequisite.
- Recorded Tortoise snapshot `3ab59b9aab18`: mastery spells 57671/57673/57675 give +5 to the paired Mace/Axe/Sword skill lines; 57677 through 57691 cover the remaining families. Snapshot provenance is in `data-sources-1.0.2.md`. Direct Octo spell pages were not readable during this check.

## Saving and checking

Book selections are stored in `weaponSkillQuests` inside the local saved plan and
participate in revision-aware autosave. Reading the stat panel or selecting which
family to inspect does not modify a saved build. Existing AB2/AB3 shared-code formats
are unchanged and do not carry the local selections; select books again after import.

In game, compare the same equipped weapon with the checkbox off and on. With no
other skill bonuses, a level-60 Human Sword changes from 303 to 308; a character
without the matching racial changes from 300 to 305. Changing the family selection
alone should not change any total. Verify save/load and, for mixed dual wield,
that each hand receives only its own marked family's bonus.

Offline regressions and Lua 5.0 compilation validate the implementation; the running
Octo client remains the final check of its observed values.
