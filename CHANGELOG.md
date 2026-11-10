# Changelog

## 1.0.2 — unreleased

### Correct character and defense totals

- Add recorded native Block Value for all 454 shields in the embedded catalog.
- Normalize item totals so the planner, Block Value filter and item sorting use the same values.
- Replace talent text-number guessing with explicit class/spell/rank effects; separate passive,
  active, form-specific and spell-school-specific effects.
- Include verified permanent set statistics, preserving notes for conditional or unsupported parts.
- Apply item-armor multipliers separately from flat armor granted by enchants and set auras.
- Show effective frontal melee defense against a selected attacker level, including miss,
  avoidance, attack-table coverage, critical/crushing chance and coverage gap.
- Make Defense and attacker-level adjustments consistent between the panel and warrior simulator.
- Add explicit Holy Shield, Redoubt and Shield Block snapshot controls.
- Prevent talent removal or level/class changes from leaving invalid talent allocations.

### Content selection

- Add an Octo phase profile, multi-instance filters and future/unverified-source controls for items and enchants.
- Use full supplemental acquisition-route metadata rather than the shortened tooltip source list.
- Apply enchant availability before hiding statistically weaker alternatives.
- Preserve saved items/enchant IDs regardless of browsing filters and mark restricted or unknown sources.
- Correct hidden-item markers so ordinary Gold, Cold and Smoldering names remain searchable.

### Saved plans and imports

- Skip autosaves on unchanged refreshes and protect shared builds with revision checks.
- Preserve stale/conflicting character plans as separate drafts.
- Replace obsolete gear and enchants when importing equipped items; recognize native enchant IDs.
- Retain unknown item/enchant IDs with calculation warnings; preserve the previous plan before a cross-class or lower-level import resets incompatible talents.

This is a test candidate. Game-client checks and Octo-specific formula/source validation
remain separate from offline tests; see `docs/TESTING-1.0.2.md`.

## 1.0.1 — unreleased

### Maintenance foundation (2026-11-10)

- Establish Shadgy's maintenance fork from upstream revision `bd141a5`.
- Add validated, reproducible installation ZIPs with build provenance and SHA256 checksums.
- Add automated package checks, pinned test dependencies and a draft-release workflow.
- Bound compiler downloads and use a checksum-verified mirror if the Lua server is unavailable.
- Keep the TOC and runtime version synchronized with one version command.
- Make an empty test selection fail and read Lua sources as strict UTF-8.
- Preserve the `AshenBuilds` installation folder, `AshenBuildsDB` saves and community protocol.

### Upstream work included after the original v1.0.0 ZIP

- Separate current plans for each character; initialize new plans from the character.
- Filter items by usability and armor type.
- Improve community build synchronization and catch-up.
- Restore talent-tree background artwork.

Offline checks and game-client smoke checks are separate. This candidate has not yet
been verified in a running Turtle WoW client.

## 1.0.0 — upstream

See the original change history in `README.md` and the upstream Git history.
