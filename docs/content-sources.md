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
Verified Octo exceptions can override individual item/enchant IDs. Unknown sources
are marked and kept by default; the user can exclude them explicitly.

## Compact fields

- `p`: phase of a resolved acquisition route, if one is known.
- `l`: necessary lower phase bound, if later than the base phase.
- `u`: at least one recorded route/dependency is unresolved.
- `z`: map IDs contributing acquisition locations, without the tooltip drop limit.
- `r`: number of immediate routes combined; `h`: explicit PvP rank when present.
- Enchants additionally retain `spell`, applying `items`, learning `recipes` and
  actual `trainers` IDs when the snapshot provides them.

Alternative acquisition routes use the earliest possible phase; required ingredients
and recipe learning use the latest necessary phase. A currently mapped route wins
over future alternatives. A guaranteed future recipe/rank gate stays future even
if some other required material is unresolved.

The character planner retains existing items and enchants regardless of these
filters. Availability is evaluated before the enchant dominance pass, so a stronger
future enchant cannot hide a currently usable lower option.
