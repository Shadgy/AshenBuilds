# Ashen Builds 1.0.2 candidate checks

## Use the new controls

Open `/ab`. In the DEFENSE section choose **Details...**. Select the attacker's level
and, when applicable, enable Holy Shield, Redoubt or Shield Block. The normal character
panel originally showed passive values in 1.0.2. Since 1.0.5, its **Block (active)**
also previews the selected effects; the tooltip separates the passive contribution.

- Avoidance is incoming miss + dodge + parry.
- Attack-table coverage adds block to avoidance.
- The coverage gap is measured against 100% of the modeled incoming table, after the
  target-level adjustment. Do not add another fixed boss adjustment to this result.
- Active previews assume the effect is up and has charges remaining. They do not
  promise permanent coverage throughout a fight.
- The model assumes frontal physical NPC melee, maximum trained Defense for the
  selected character level, and no enemy-specific hit modifiers. It does not model
  attacks from behind, stunned/casting states, spells or boss-specific exceptions.
- Calculation notes identify unknown data and scoped/conditional effects omitted from
  the passive summary. Spell-school-specific talent bonuses are not global spell crit.

Both the item and enchant browser have an **Octo: phase 2** content button. The default
profile uses the Octo roadmap checked on 2026-11-10. Change the phase to plan future
content, or enable **Show future phases**. Select multiple acquisition instances when
you want to restrict suggestions. Unverified routes can be included or hidden explicitly.
Changing these controls does not delete items or enchants from existing plans.

## Before installing

Close the game. Back up `WTF` saved variables and the existing `AshenBuilds` addon
folder. Extract the candidate ZIP so the path remains
`Interface\AddOns\AshenBuilds\AshenBuilds.toc`, then fully restart the client.
Do not rename the folder or delete `WTF`.

## Paladin and warrior checks in Octo

Record the client build, character level, equipment, talents, buffs and relevant
character-sheet values. Compare like-for-like states; remove unrelated buffs first.

1. Equip a shield and confirm native Block Value contributes separately from Equip
   bonuses and Strength. Example item 19349 has native 54 and Equip +19 in Octo's
   public database. A fixture with 120 Strength and no BV talent gives 78 under the
   reference formula; actual character Strength may differ.
2. Check each rank of warrior Toughness and paladin Shield Specialization against
   the character's observed Block Value. Check armor separately from flat enchant armor.
3. Swap a known +10 Defense contribution. At the same target level, the reference
   model increases each applicable miss/dodge/parry/block chance by 0.4 percentage
   points, avoidance by 1.2 and raw coverage by 1.6. A shield/weapon must be equipped
   for block/parry to be applicable.
4. Compare attacker levels 60 and 63. Equal-level attacks have no ordinary crushing
   entry in the reference model. Extra Defense reduces crit chance but does not
   directly remove the base crushing entry; sufficient table coverage pushes it off.
5. Toggle Holy Shield/Redoubt/Shield Block. In 1.0.5 the main **Block (active)** and
   effective table must both update; passive block inputs and BV remain unchanged.
   Remove the shield and confirm block/BV are zero.
6. Equip two Deathbone pieces and verify +3 Defense; equip three Might pieces and
   verify the static +30 BV bonus is included once.
7. At Octo phase 2, verify Sapphiron shoulder enchants are excluded from normal
   suggestions; select phase 6 and confirm they return. Check selected open/closed
   instance filters and **Show future phases** independently.
8. Load a saved build containing future gear or enchants. Its contents must survive
   every filter change; the source tooltip should explain the restriction.
9. Edit a saved build on character A, then log character B holding an older snapshot.
   A's saved version must survive; a differing old plan is recovered separately.
10. Import currently equipped gear, including empty slots. Old planned items and
    enchants must disappear from those slots. Unknown IDs remain explicit warnings.

## Scope and provenance

Reference defense formulas were checked against vmangos `StatSystem.cpp`,
`SpellCaster.cpp` and `Player::GetShieldBlockValue`; this is a reference model, not
an assertion of access to Octo's running server code. Native shield values and static
auras come from the recorded snapshot described in `data-sources-1.0.2.md`.
Acquisition metadata and its limits are described in `content-sources.md`.

The existing AB2/AB3 sharing formats remain compatible. Explicit defense preview
settings and a Custom Druid's selected form are local saved-plan metadata and are
not carried by those sharing codes. Bear-form armor and complete school-specific
spell calculations are not newly certified by this release.

Offline regression tests and a rendered frame-geometry preview cover the changes.
The preview uses approximate fonts/textures and is not a screenshot from WoW.
Stable release verification still requires completing and recording the client
checks above; no game-client result is claimed by the candidate.
