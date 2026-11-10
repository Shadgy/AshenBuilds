# Weapon skill quest preview (local 1.0.5)

At the top of the planner, select a weapon family beside **Weapon skill quest +5**
and tick it if the planned character has completed that family's mastery. Each
family is remembered independently. Sword, Axe and Mace mastery covers both the
one- and two-handed skill lines; a Sword book does not improve an off-hand Axe.

The bonus stacks once with racial, gear and talent skill. The planner keeps flat
gear/talent Hit separate internally, but displayed **Melee Hit** also includes
0.2 percentage points per bonus weapon-skill point above level x5. Its tooltip
shows miss and the flat Hit cap against the selected target level. A +5 melee
mastery therefore improves the displayed bonus by 1 percentage point. With 4% flat
Hit against a level-63 target, skill 303 to 308 reduces miss from 3.4% to 2.4%.
Dual-wield white miss is shown separately, including off-hand-only talent Hit.
There is no new hard cap imposed on the displayed skill total.

The warrior simulator uses the same miss function and raw flat Hit, so it counts
weapon skill once. Skill above the target's Defense continues to reduce miss.
The inherited 1.12 sheet model also gives +0.04 percentage points of physical crit
per bonus skill. This contribution is retained per simulated weapon; it is not
substituted for the miss reduction. Its exact live Octo behavior remains unverified.
Ranged Hit remains explicitly a gear/talent bonus: the cited Octo formula is for melee.

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
- [Octo developer's melee miss formula](https://octowow.st/forum/viewtopic.php?p=6549): `miss = 5 - 0.2 * (weapon skill - target Defense)`, before flat Hit. This is the source for the 1.0.4 melee correction.
- The inherited crit model follows [vmangos 1.12 StatSystem.cpp](https://github.com/vmangos/core/blob/development/src/game/StatSystem.cpp) and [Unit.cpp](https://github.com/vmangos/core/blob/development/src/game/Objects/Unit.cpp). These explain the 1.12 model and are not direct evidence of Octo's server code.
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

The local 1.0.5 candidate is checked with Lua 5.1 behavioral regressions and Lua 5.0
API lint. A Lua 5.0 compiler is not installed locally; no remote CI was started
because publication is disabled. The running Octo client remains the final check.

Also check **CLASS** before testing defense: Warlock cannot parry or use shields.
The shield Bulwark of Unshaken Earth (33135) has a recorded native 48 Block Value;
Paladin/Warrior totals include this base, applicable bonuses and Strength. The main
panel marks unsupported abilities N/A and exposes incompatible equipment notes.

## Unresolved Octo crit verification

Research on 2026-11-10 did not find a public Octo server implementation or a direct
Octo statement confirming +0.04 percentage points of crit per bonus weapon skill.
The developer post confirms melee miss. The official Turtle 1.17.2 weapon-skill
changes discuss Hit and glancing damage; silence about crit is not confirmation
of the old rule. The addon retains its inherited model and labels this limit in
the crit tooltip.

A controlled check should use the native **Attack** spellbook tooltip, with the
same fully trained weapon, equipment, Agility and buffs before and after learning
the corresponding mastery book. Record actual skill and all available crit decimals.
The model predicts +5 skill and +0.20 percentage points of sheet crit. Changing the
planner checkbox tests the addon, not the server. A native tooltip comparison checks
the client display; proving server-side attack rolls needs server evidence or a
separate combat-log study. Do not treat a small sample of attacks as proof.
