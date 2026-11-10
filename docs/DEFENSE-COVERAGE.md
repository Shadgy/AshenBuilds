# Defense coverage conventions (local 1.0.5)

The main gear card uses character-sheet probabilities. Its **Block (active)**
includes selected Holy Shield, Redoubt or Shield Block while those effects have
time and charges remaining. Hover it to see the passive and selected contributions.
Passive block remains a separate calculation input; active buffs count once.

Defense Details also shows incoming frontal melee chances adjusted for the selected
attacker level. These are two views of the same attack table.

## The user's level-60 Paladin example

Defense 342 gives 6.68% same-level incoming miss under the reference model.
Holy Shield adds 45 percentage points of block and Redoubt adds 15.

| Outcome | Character sheet with active effects | Against level 63 |
| --- | ---: | ---: |
| Miss | 6.68% | 6.08% |
| Dodge | 7.08% | 6.48% |
| Parry | 11.68% | 11.08% |
| Block | 8.68 + 45 + 15 = 68.68% | 68.08% |
| Coverage | 94.12% | 91.72% |
| Required cap | 102.40% | 100.00% |
| Remaining gap | 8.28 percentage points | 8.28 percentage points |

The level-63 attacker has 315 weapon skill versus the level-60 baseline of 300.
Each applicable category loses `15 x 0.04 = 0.60` percentage points. Four categories
therefore lose 2.40 points. Subtracting them from the chances and then comparing the
result to 102.40 would count the boss adjustment twice.

Avoidance is miss + dodge + parry. Coverage additionally includes block. Block
reduces incoming damage rather than avoiding it entirely. The selected active
snapshot is not a promise of permanent coverage during an encounter.

## Other levels and classes

The familiar 102.40 figure assumes all four categories are available and above
their zero floor. The addon derives the correction per available category: for
example, it excludes parry for a Shaman and excludes block without a shield.
It handles very low chances and excess block without changing the effective gap.
The actual modeled attack table is always bounded at 100%.

The character's own mastery book does not increase Defense or its defensive
dodge/parry/block. The attacking enemy's weapon skill is used in the incoming model.
An equipped weapon and the appropriate class ability are prerequisites for parry;
a shield and the appropriate class ability are prerequisites for block.

## Evidence and limits

The reference engine uses Defense in [StatSystem.cpp](https://github.com/vmangos/core/blob/development/src/game/StatSystem.cpp)
and the attacking unit's skill in [SpellCaster.cpp](https://github.com/vmangos/core/blob/development/src/game/Objects/SpellCaster.cpp).
These are primary sources for the inherited 1.12 model, not proof of Octo's current
private server implementation. The screenshot values and both gap conventions are
covered by local regressions. Live buffs, charges and encounter exceptions still
need a client check. Weapon-skill crit verification is documented separately in
[WEAPON-SKILL-QUEST.md](WEAPON-SKILL-QUEST.md).
