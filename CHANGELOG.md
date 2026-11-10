# Changelog

## 1.0.8 — 2026-11-10

- Add an Enchant Database tab beside Item Database. Browse without equipped gear; search names/effects, filter by slot/stat/content phase, page results and choose a compatible equipped target. Share source/phase controls with existing pickers; keep Unverified off by default.
- Apply Paladin Divine Strength to Strength, Attack Power and Block Value. Count Sigil of Resilience as a separate reduction to received critical-hit chance, without increasing avoidance/coverage.
- Protect unsaved imports (including notes-only drafts), preserve valid unknown item/enchant IDs and show explicit missing-data labels. Reject malformed codes atomically while retaining AB1/AB2/AB3 and old 17-slot compatibility.
- Complete per-character migration once: preserve a genuine legacy shared plan separately until its matching class logs in; existing per-character plans take precedence and new alts start independently.
- Infer old saved-name links only during genuine shared-plan migration. A new or existing unsaved draft named New Build must not attach to an identically named library entry on any login.
- Normalize old Scarlet Monastery wing selections to the common instance. Apply catalog race restrictions to usability filters and warn about incompatible saved gear; keep explicit Octo exceptions possible without deleting saved items.
- Filter item text/stat candidates before computing availability. Preserve result ordering, source aliases and phase checks while avoiding thousands of unnecessary availability calculations for narrow searches.
- Make the warrior simulator reject incompatible weapon enchants and apply Death Wish's recorded armor penalty to incoming physical hits.
- Preserve the deferred weapon-skill crit model; its Octo-specific verification remains open.

## 1.0.7 — local candidate, not published

- Use a recorded AtlasLoot acquisition snapshot as the user-approved source baseline, alongside the existing Octo phase/dependency model. Store file hashes, table provenance and stable item/enchant IDs without replacing stats.
- Default Unverified to off and migrate the previous permissive setting once. Later explicit user choices persist. Source verification and phase availability are separate conditions.
- Keep Tower of Karazhan in phase 7 despite unrelated Development Land spawns. Preserve recipe/material gates and explicit PvP ranks; Unverified cannot bypass established future requirements.
- Keep original Ashbringer/Azzinoth and excluded showcase/temporary artifacts in Unverified only. Preserve actual Corrupted Ashbringer in Naxxramas and real legendary acquisition routes.
- Merge AtlasLoot categories and source names into item filtering/search, including items missing their old short source excerpt.
- Move the phase button away from profile controls. Bound item/enchant rows to single-line names/descriptions, shortening long text with full text on hover.
- Preserve saved builds and the deferred weapon-skill crit model. No publication or remote CI was performed.

## 1.0.6 — local candidate, not published

- Replace cycling CLASS/RACE/BUILD selectors with direct dropdown choices, preserving their existing pointed art, dimensions and positions.
- Show unsupported race/class combinations in grey with an explanatory tooltip and reject selection. Include 59 supported pairs from the Octo race pages and additional-combination list.
- Explain the existing requirement to reset talents before changing class. Selecting the current class/race/build is a no-op and does not reset a custom label.
- Preserve older incompatible saved/imported plans and show a calculation warning; compatible selections can repair the profile.
- Add regressions for the user's Paladin 1.0.5 screenshot: 350 Defense, active Block 73%, sheet coverage 102.20 / 102.40%, attacker coverage 99.80 / 100% and a 0.20-point gap.
- Keep block/Defense calculations and the deferred weapon-skill crit model unchanged. No publication or remote CI was performed.

## 1.0.5 — local candidate, not published

- Update the main gear panel's **Block (active)** immediately when Holy Shield, Redoubt or Shield Block is selected. Keep passive block separate internally for simulation inputs and show both contributions in the tooltip.
- Display both sheet coverage / required cap and attacker-adjusted coverage / 100% in Defense Details. The familiar 102.4% shield-tank cap and the adjusted 100% table give the same gap; do not apply the boss penalty twice.
- Preserve correct thresholds for classes without parry/block, low chances floored at zero and block above 100%.
- Clearly mark weapon-skill crit as the inherited, Octo-unverified 1.12 model in the stat tooltip. Research found direct Octo confirmation for melee miss, not for the crit coefficient.
- Add regressions reproducing the user's 94.12 / 102.40% sheet coverage and 91.72 / 100% boss coverage, both with an 8.28-point gap.
- No GitHub push, remote CI or release was performed for this local candidate.

## 1.0.4 — local candidate, not published

- Include the matching weapon-skill contribution in displayed Melee Hit. Show target level, remaining special/single-wield and dual-wield miss, and the flat Hit cap in its tooltip; keep simulator flat Hit separate to avoid counting skill twice.
- Share the Octo developer's melee miss formula between the planner and warrior simulator, including skill above the target's Defense.
- Retain the inherited 1.12 weapon-skill crit contribution for each simulated weapon; the sheet's +0.2 percentage point crit from +5 skill is preserved. Octo-specific crit behavior still needs a client check.
- Include Warrior Dual Wield Specialization's off-hand-only Hit in both the tooltip and simulator.
- Recognize staves and polearms as two-handed for applicable weapon-skill talents while preserving their mastery families.
- Mark class-unsupported parry/block as N/A, identify the calculation class, and expose incompatible equipment warnings on the main panel. Defense does not grant a class a new parry/block ability.
- This candidate is local only. No GitHub push, workflow run or release was performed for 1.0.4.

## 1.0.3 — unreleased

- Add **Weapon skill quest +5** at the top of the planner with an independent selection for each weapon family.
- Apply the matching mastery book alongside racial, gear and talent skill in character totals and the warrior simulator, including each hand separately.
- Show the quest contribution in main-hand and ranged weapon-skill tooltips.
- Save book selections with local builds and protect them with the existing revision-aware autosave.
- Exclude shields, wands, fishing poles, unarmed and feral attacks; use a conservative level-60 book preview gate.
- Preserve existing AB2/AB3 sharing compatibility. Local book selections must be selected again after importing those codes.

Source scope and checks are described in `docs/WEAPON-SKILL-QUEST.md`.

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
