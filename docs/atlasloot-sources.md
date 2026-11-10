# AtlasLoot acquisition baseline

The user selected the locally installed AtlasLoot as the reference for supported
acquisition sources. The recorded package is **AtlasLoot TurtleWOW 3.4.6**, read from
the Octo client's `Interface/AddOns/AtlasLoot`. This is a reference snapshot, not a
claim that every listed source has been independently observed on the live server.
Octo phase restrictions still apply. Later server exceptions can be recorded without
changing item IDs, build codes or item statistics.

`Data/AtlasLootSources.lua` records the extracted evidence. It contains 7,632 item IDs
across all relevant loot/crafting data, including consumables, formulas and materials.
**5,999** of those IDs match the embedded planner catalog. Of those, **5,560** have
at least one mapped phase and **439** have reference evidence with unresolved phase.
The export maps **239 of 263** stable addon enchant IDs; the remaining 24 are listed
below. Seven of the 239 evidenced enchants still have an unresolved phase. These
evidence counts are not counts of items available in phase 2.

## Rebuilding and provenance

```text
python tools/build_atlasloot_sources.py PATH_TO_ATLASLOOT --database tools/work/tortoise-3ab59b9aab18.sqlite
```

The output's `meta.files` stores SHA-256 hashes for AtlasLoot's TOC and loaded
Database files, plus the unchanged addon enchant/source catalogs. The optional
SQLite join snapshot is recorded by SHA-256
`3ab59b9aab18adc8bcbba2363635e5eef666d8423d5e5ee376913fd6b24743b4`.
It supplies exact spell-to-product, use-item and recipe joins; its presence alone
never makes an item AtlasLoot-verified. Use-item joins require an on-use trigger,
not an equipped-item aura with a coincidentally matching spell ID.

Only declarative Database data is read. The exporter rejects loops, functions and
ordinary calls before loading the tables into a restricted Lua environment without
I/O, imports, game APIs or standard libraries. The known client-only formatting
expression for item charges is replaced with a harmless literal. The runtime addon
does not depend on AtlasLoot being enabled, and the exporter does not read character
SavedVariables or modify the installed AtlasLoot.

The same inputs produce identical output bytes. Item/enchant stats and their
permanent IDs are unchanged. The official launcher repository reference is
[shaga/AtlasLoot on Octo's Git server](https://octowow.st/git/shaga/AtlasLoot), as
listed in the [official launcher's addon sources](https://octowow.st/git/OctoWoW/OctoLauncher/src/branch/main/server/src/addons-sources.ts).
This reference does not prove the local files match the current remote revision.
The recorded local hashes, rather than the version number alone, identify this data.

## What qualifies as evidence

- Actual instance, world-boss, faction, battleground, crafting and event tables.
- Spell rows `sSPELL`/`eSPELL`, joined through AtlasLoot's `craftspells`/`enchants`
  product data and the recorded SQLite joins. A spell number is never mistaken
  for an item ID or a stable addon enchant ID.
- Known set acquisition families: dungeon tier 0, tiers 1/2/3/3.5, AQ20/AQ40,
  Zul'Gurub and Timbermaw. Exact family/class patterns distinguish T25 from T2
  and T35 from T3. Independently mapped earlier sources retain their earlier
  phase, such as Onyxia's tier-2 helmets.
- Other collection entries require an independently mapped phase/lower bound.
  A generic showcase listing alone does not establish acquisition.

Collection aliases are removed when an actual acquisition route exists for the
same item. For example, an old generic Tabards phase-0 summary cannot reopen the
Scourge Invasion tabard 22999, whose actual AtlasLoot event source is phase 6.
An Onyxia helmet likewise keeps its actual Onyxia route rather than a BWL set alias.

`Legendaries`, pet showcases and empty pages are excluded. PvP AC/HC collection
aliases are excluded in favor of the real rank pages, which carry explicit rank
requirements per item or section header, processed in numeric row order. Thus
the rank-14 weapon pages remain phase 6 even when individual rows omit the rank.
The existing Octo honor schedule maps rank 11 to phase 1,
12 to phase 2, 13 to phase 3 and 14 to phase 6; lower explicit ranks use the base
phase. Battleground reputation rewards without a rank use the base content phase.

The following curated exceptions remain outside the supported baseline even if an
old AtlasLoot page mentions them:

| Item ID | Reason |
| --- | --- |
| 13262 | Original Ashbringer; unsupported acquisition |
| 18582, 18583, 18584 | Original Twin Blades of Azzinoth showcase versions |
| 17782 | Talisman of Binding Shard; removed/test loot |
| 22736 | Andonisus; temporary encounter weapon rather than permanent equipment |

Corrupted Ashbringer **22691** remains a real Naxxramas source in phase 6.
Thunderfury **19019** and Sulfuras **17182** retain their actual Molten Core
tables in phase 0; excluding the generic Legendaries showcase does not remove them.

## Phase handling

Named raid context supplies its Octo phase directly. Tower of Karazhan drops such
as 55285, 55098, 55278 and 55283 therefore carry phase 7 despite incomplete older
source summaries. Corrupted Ashbringer carries phase 6. Sapphiron application items
23548/23545/23547/23549 map to stable enchant IDs 37/38/39/40 and phase 6.

Crafting-table presence does not imply phase 0. Resolved dependency summaries retain
their phase; unresolved summaries with a guaranteed lower bound emit `minimumPhase`
rather than a fully resolved `phase`. Generic unknown routes stay phase-unknown.
Examples: Subtlety 48 and Threat 66 remain phase 4; Nature Power 146602 and Mighty
Mana 157119 remain phase 3; Timbermaw enchant recipes 42187–42190 map to enchant IDs
149016/149018/149020/149022 and phase 5.

The runtime's current phase filter and dependency lower bounds still decide whether
an evidenced source is open. Missing AtlasLoot evidence is not proof an item can
never exist; it belongs outside the normal supported baseline until reviewed.

## Enchants without AtlasLoot evidence in this snapshot

| Stable addon IDs | Enchants |
| --- | --- |
| 15–19 | Lesser Arcanum of Voracity: Strength, Agility, Stamina, Intellect, Spirit |
| 20–23 | Lesser Arcanum of Constitution, Rumination, Tenacity, Resilience |
| 128163, 128165 | Ice Guard, Shadow Guard |
| 145739 | Gift of Ferocity |
| 146603 | Holy Power |
| 149013 | Crystalized Topaz Gemstone |
| 156536–156538 | Invocation of Greater Voracity, Greater Constitution, Shadow Resistance |
| 157032, 157034, 157036 | Spell Penetration, Greater Spell Penetration, Superior Spell Penetration |
| 157155–157157, 157185 | Sigil of Leeching, Quickness, Penetration, Resilience |

These are missing from this acquisition snapshot, not declared impossible to obtain.
Their exact IDs/names/spells are also retained in `meta.missingEnchants` for review.
