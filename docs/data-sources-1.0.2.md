# Native shield block data in 1.0.2

`Data/ShieldBlock.lua` supplements the existing item catalog with the native
`items.block` field. It does not replace item names, stats, loot sources or the
original July 2026 catalog. Native block is distinct from block **chance** and
from additional `Equip: increases the block value...` effects.

## Source snapshot

- Source project: <https://github.com/Xian55/tortoise-db-viewer>
- Version: `3ab59b9aab18`; source metadata built at `2026-11-06T04:40:57.294Z`.
- Archive: <https://cdn.jsdelivr.net/gh/Xian55/tortoise-db-viewer@cdn-v3ab59b9aab18/data/tortoise.sqlite.br>
- Compressed archive SHA256: `36ebf3d28ce459026872d56f35407ff61d6aeeede2dc1334b1fccaf1c7c278b1`.
- Uncompressed SQLite SHA256: `3ab59b9aab18adc8bcbba2363635e5eef666d8423d5e5ee376913fd6b24743b4`.
- Extracted table/columns: `items.entry`, `items.inventory_type`, `items.block`;
  shield inventory type is `14`.
- Checked on 2026-11-10: the source's **454 shield IDs exactly match all 454 shield
  IDs** in the embedded catalog. Ten records explicitly contain zero; zero is
  preserved and distinguished from a missing value.

The original catalog version `ec14bfe00852` was not available at its historical
CDN tag when the supplement was prepared. The supplement therefore records its
own newer source revision explicitly rather than claiming the whole catalog was
updated.

Octo cross-check: [Elementium Reinforced Bulwark, item 19349](https://octowow.st/db/?item=19349)
shows **54 Block** and a separate **+19 shield block value** Equip effect. The
supplement retains the 54; the existing item-effect parser retains the 19. The
454 values are sourced from Tortoise, not individually verified against a live
Octo character. Server-specific differences should be recorded as verified
overrides with their own source, not inferred from phase availability.

## Rebuilding

Download the pinned archive into ignored `tools/work/`, verify its compressed
SHA256 above, and decompress it using Brotli (generation-only dependency
`Brotli==1.2.0`). Verify the SQLite hash before exporting:

```text
python tools/build_shield_block.py --database tools/work/tortoise-3ab59b9aab18.sqlite --verified-at 2026-11-10
```

The exporter uses the standard library after decompression, reads the database
without writing it and refuses any missing/null/invalid native block value for a
shield in the embedded catalog. The SQLite hash is included in the generated
Lua metadata. CI tests need neither the downloaded database nor Brotli.

New full item exports retain native shield block as positional field **21**.
The adapter prefers that field; older 20-field records use this supplement.
For an unmapped shield, `shieldBlockKnown=false` and the native value is absent.
An explicitly sourced zero instead yields `shieldBlockKnown=true` and value `0`.

## Permanent set bonuses

`Data/StaticSetStats.lua` uses the same pinned SQLite snapshot and exact hash as
the shield supplement. `tools/build_static_set_stats.py` reads the unique bonus
spell IDs in the existing `Data/SetCatalog.lua`, then classifies each spell's
structured `spells.effects` records. It does not infer numeric bonuses from prose.
The metadata also records the SetCatalog SHA256 with line endings normalized to LF.

The current export recognizes **112 of 494** bonus spells completely and one
additional permanent spell partly: **113** spells have known numeric stats.
There are **382** entries in `AshenBuilds.StaticSetStatsUnhandled`: 381 wholly
unhandled spells and the unhandled threat modifier of that one partial spell.
These effects are not claimed to have zero effect. Existing simulation-specific
handling of procs and other effects remains separate.

Accepted spells must have permanent duration, no class mask restriction, the
source's unconditional-passive marker, self-only constant aura effects, and no
conditional/form/stance/trigger text. Nonconstant, periodic or non-self effects
exclude the entire spell. Within an otherwise eligible permanent self-only spell,
known independent numeric auras are retained and unknown modifiers remain noted.
For example, Lionheart Battleplate's spell 51836 contributes its known **+67 BV**,
while its separate Holy Shield threat modifier remains explicitly unhandled.
The simulator must skip stat fields already included by this layer.

Recognized aura types include primary stats, Defense skill, armor and the five
ordinary magic resistances, dodge/parry/block chance, shield block value, physical
crit/hit, global spell crit/hit, unrestricted magic damage/healing, mana regeneration,
flat health/mana and common/ranged attack power. School-specific spell crit is not
applied globally. Aura **55 means spell hit**, not spell crit. Paired melee/ranged
AP effects become one common `ap` value because the planner already adds common
AP to both attack types; `rap` is only the ranged excess.

Physical armor from aura 22 is stored as **`bonusArmor`**, separate from equipment
base armor, so item-armor percentage talents do not amplify it.
[vmangos' HandleAuraModResistance](https://github.com/vmangos/core/blob/development/src/game/Spells/SpellAuras.cpp#L4551)
applies that aura to `TOTAL_VALUE`, separately from the `BASE_PCT` modifier used
by base-armor percentage effects.

The included regression cases cover Deathbone's +3 Defense / +50 armor / +15
resistances / +1 parry thresholds and Might's +30 shield BV. Triggered or conditional
effects such as Might's extra Rage and Berserker Stance crit are excluded from the
permanent stat catalog.

```text
python tools/build_static_set_stats.py --database tools/work/tortoise-3ab59b9aab18.sqlite
```
