# Octo item audit for 1.0.11

Checked 2026-11-15. The bundled AshenDB item snapshot is Tortoise-WoW
`ec14bfe00852`. The acquisition metadata uses SQLite snapshot `3ab59b9aab18`
and the bundled AtlasLoot 3.4.6 evidence. The installed Octo AtlasLoot 4.2.0
comparison used revision `841b232c56d92bc45c600b1e57c508d47066b28a`.
Its row and rank formats changed, so its catalog was compared independently of
the bundled phase rules. No AtlasLoot snapshot replacement was made.

## Restored acquisition routes

| IDs | Evidence |
| --- | --- |
| 55056 | [Spellwoven Nobility Drape](https://octowow.st/db/?item=55056) was already cataloged. [Pattern 55055](https://octowow.st/db/?item=55055) comes from Shen'dralar Provisioner, requires Tailoring 300 and Shen'dralar Exalted. The old summary left the phase unresolved. |
| 55060 | [Grandstaff of the Shen'dralar Elder](https://octowow.st/db/?item=55060) had the same unresolved phase. [Plans 55059](https://octowow.st/db/?item=55059) are listed by the same vendor. |
| 58251–58259 | The live Octo database's vendor list for [Elisandra Spellbinder](https://octowow.st/db/?npc=80945) lists nine pieces of Shen'dralar reputation gear in Dire Maul. The bundled AtlasLoot reputation page lacked a phase. |
| 60622 | [The Tome of Arcane Intricacies and Magical Phenomenon IX](https://octowow.st/db/?quest=40425) awards [Ring of the Academy](https://octowow.st/db/?item=60622). It is an Alliance quest in Stormwind Vault. |
| 60624–60626 | [Ending Arc'Tiras, Alliance](https://octowow.st/db/?quest=40427) and [Horde](https://octowow.st/db/?quest=41139) award the same three choices. |

The quests above have display level 63 and can be accepted at level 58. The
snapshot provides minimum levels for 1,301 awarding quests whose acceptance
level differs from their display level. The fixed usability filter uses the
minimum. [Octo's roadmap](https://octowow.st/roadmap) lists phase 2 as open.
Stormwind Vault and Dire Maul are part of base dungeon content.

## Added item definitions

| IDs | Evidence |
| --- | --- |
| 90051 | [Bokken stats](https://octowow.st/db/?item=90051) and [a player report of receiving the starter weapon](https://octowow.st/forum/viewtopic.php?p=8002). |
| 90053 | [Simple Katana](https://octowow.st/db/?item=90053), sold by weapon vendors in both factions. |
| 90060, 90061 | Ring of Friendship, [Together Forever challenge reward](https://octowow.st/index.php/challenges). Octo's client cache distinguishes the 24-hour and level-60 one-hour versions. |
| 93223 | [Simple Bronze Katana](https://octowow.st/db/?item=93223), [Blacksmithing spell 65210](https://octowow.st/db/?spell=65210) and [Octo release notes](https://octowow.st/forum/viewtopic.php?t=650). |
| 58247, 83605, 83608 | Champion's Insignia and two Bloody Gladiator Lamellar items, from Octo's item tooltips and client item cache. Exact acquisition remains unverified. Damage reduction from the Lamellar items is documented in tooltips and does not change hit-table or crit chance calculations. |

## Coverage and remaining gaps

The public Octo item list was compared in bounded item-level and item-category
queries for Rare-or-better weapons and armor from item level 60 through 200.
This returned 4,456 records, including 4,432 wearable items. The original
embedded catalog lacked 183 wearable IDs in that comparison. Three of those
definitions were added above. The remaining 180 are mostly arena and PvP
variants without a confirmed exact acquisition route. Octo's [arena changes](https://octowow.st/forum/viewtopic.php?t=3295)
confirm arena gear exists but do not identify all available item IDs.

The AtlasLoot comparison and the local Octo item cache provided additional
lower-level and challenge entries. Appearance copies, NPC/test items and
non-wearable tokens were excluded. The audited lists do not enumerate every
obtainable item on the live realm. Unverified stays off by default, and no
future raid or honor gates were relaxed.

The crafting audit also found 28 candidates whose phase resolves only with a
fresh traversal of Tortoise's cyclic recipe dependencies. Octo evidence was
checked for the two Shen'dralar craft products above. The other candidates
remain subject to the existing phase checks.
