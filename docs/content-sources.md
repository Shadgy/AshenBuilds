# Content source supplement

`Data/ContentSources.lua` supplements the existing catalog; it does not replace item
records, IDs, saved builds, enchant IDs, or the short source lists shown in tooltips.

The supplement is generated from the Tortoise-WoW snapshot `3ab59b9aab18`:
https://github.com/Xian55/tortoise-db-viewer. The exact SQLite SHA256 is recorded in
`AshenBuildsContentSources.meta`. Its 16,069 item IDs are taken from the embedded
catalog, and its 263 enchant IDs/spell IDs are taken from `Data/Enchants.lua`.

## Rebuild

```text
python tools/build_content_sources.py tools/work/tortoise-3ab59b9aab18.sqlite
python tools/build_content_sources.py tools/work/tortoise-3ab59b9aab18.sqlite --check
```

The generator opens SQLite read-only, uses the Python standard library, writes only
the supplement, and produces a stable result for the same database/catalog inputs.

## Evidence and phase interpretation

The generator reads every recorded creature/pickpocket/skinning drop, object drop,
container relation, direct/template vendor, quest reward and crafting recipe.
Creature instance/spawn maps and object spawn maps identify locations by numeric
map ID. Recipe item IDs, actual trainer relations, profession-learn records, required
materials and explicit honor-rank requirements are retained or traced.

This runs **before** the UI source list is limited to eight drops. A `more` row in
the tooltip therefore no longer makes a fully mapped Naxxramas-only item unknown.
Unknown map IDs, unsupported source types, missing dependencies and cycles remain
explicitly unresolved. Missing source data never proves that an item is unavailable.

The Octo phase profile follows the roadmap checked on **2026-11-10**:
https://octowow.st/roadmap. Map IDs identify ZG/phase 1, BWL/2, Emerald Sanctum/3,
AQ/4, Timbermaw/5, Naxxramas/6 and upper Karazhan/7. Lower Karazhan is separate
and belongs to the base profile. Non-hidden ordinary dungeons and world maps are
interpreted as base content under Octo's completed unphased restoration. Unknown
raids remain unknown rather than being assigned to the base phase.

Honor enum 5 is Private/rank 1; the database's explicit honor requirement is converted
by subtracting four. Ranks 11/12/13/14 map to phases 1/2/3/6. A PvP vendor relation
without an explicit rank remains unverified; the generator does not infer rank from
an item's name.

These are **source routes from a Turtle snapshot interpreted through an Octo content
profile**, not certification of every current Octo drop table, spawn, recipe or cost.
Verified Octo exceptions can override individual item/enchant IDs.

Since local 1.0.7, this Turtle graph supplies phase/dependency information but no
longer certifies a normal suggestion by itself. The user-approved verification
baseline is the recorded AtlasLoot acquisition snapshot, described in
`atlasloot-sources.md`. Sources or phases that remain unverified are hidden by
default and can be inspected explicitly. The old permissive setting is migrated
once; later user choices persist. A known future requirement remains gated.

## Compact fields

- `p`: phase of a resolved acquisition route, if one is known.
- `l`: necessary lower phase bound, if later than the base phase.
- `u`: at least one recorded route/dependency is unresolved.
- `z`: map IDs contributing acquisition locations, without the tooltip drop limit.
- `r`: number of immediate routes combined; `h`: explicit PvP rank when present.
- Enchants additionally retain `spell`, applying `items`, learning `recipes` and
  actual `trainers` IDs when the snapshot provides them.
- `questMinimumLevels` records known differences between acceptance and display
  level. The item index uses the acceptance level for quest-only rewards, while
  the source tooltip keeps displaying the quest level.

Alternative acquisition routes use the earliest possible phase; required ingredients
and recipe learning use the latest necessary phase. A currently mapped route wins
over future alternatives. A guaranteed future recipe/rank gate stays future even
if some other required material is unresolved.

The character planner retains existing items and enchants regardless of these
filters. Availability is evaluated before the enchant dominance pass, so a stronger
future enchant cannot hide a currently usable lower option.

## Crafts triggered by items in 1.0.13

The generator now traces item-use activations for visible spells with a Create
Item effect. The tool is an alternative to learning the spell. Access to that
tool and all the required reagents still determines the phase. This production
path requires an on-use trigger linked to the creation spell.

Corehound Belt depends on Cured Rugged Hide, which requires Refined Deeprock
Salt. The [official Salt Shaker spell](https://octowow.st/db/?spell=19566)
confirms that using the tool creates the salt. This route is available in base
content under the existing Octo map rules. The recipe remains tied to
[Lokhtos Darkbargainer](https://octowow.st/db/?item=19332).

The same SQLite snapshot and exact AtlasLoot 3.4.6 files were used for the
comparison. Across the item catalog, 55 AtlasLoot-backed entries change from
unresolved to a known phase. Of these, 52 pieces of gear are eligible in phase
2 with Unverified off. Two bags become phase 0 catalog entries outside the
gear picker and Dreamhide Mantle becomes phase 3. The offline comparison also
checked every existing future-phase gate and enchant across all eight phases.

| Phase | Corrected equipment |
| --- | --- |
| 0 | Blue Dragonscale Breastplate (15048), Shoulders (15049), Leggings (20295) and Boots (65015) |
| 0 | Black Dragonscale Breastplate (15050), Shoulders (15051) and Leggings (15052), Green Dragonscale Gauntlets (20296) |
| 0 | Stormshroud Armor (15056) and Gloves (21278), Living Breastplate (15059) and Leggings (15060), Ironfeather Breastplate (15066), Frostsaber Tunic (15068) |
| 0 | Heavy Scorpid Helm (15080) and Shoulders (15081), Wicked Leather Armor (15085) and Pants (15087), Runic Leather Armor (15090) and Shoulders (15096) |
| 0 | Might of the Timbermaw (19044), Timbermaw Brawlers (19049), Dawn Treaders (19052), Golden Mantle of the Dawn (19058) |
| 0 | Lava Belt (19149), Chromatic Gauntlets (19157), Corehound Belt (19162), Molten Belt (19163), Chromatic Leggings (65036), Molten Leggings (65037), Corehound Gloves (65038) |
| 0 | Dreamscale Breastplate (20380), Sandstalker Gauntlets (20477) and Breastplate (20478), Spitfire Breastplate (20479) and Gauntlets (20480), Bramblewood Boots (22760) and Belt (22761) |
| 0 | Harness of the High Thane (55043), Inscribed Runic Bracers (61188), Stormscale Leggings (65006), Verdant Dreamer's Breastplate (65021), Primalist's Vest (81066) |
| 0 | Dreamhide Bracers (61357), Leggings (61358) and Belt (61359) |
| 1 | Primal Batskin Jerkin (19685), Gloves (19686) and Bracers (19687), Blood Tiger Breastplate (19688) and Shoulders (19689), Bramblewood Helm (22759) |
| 3 | Dreamhide Mantle (61356) |

The phase 0 bag entries are Skinner's Carryall (33378) and Cooling Rations Bag
(33379). The phase results come from the recorded sources and the Octo map
profile used in the offline comparison.
