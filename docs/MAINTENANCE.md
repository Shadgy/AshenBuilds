# Maintaining this fork

## Current local status — 2026-11-10

Status: **gotowe**. Release build **1.0.8** adds Enchant Database and fixes
the audited calculation, import, character-migration, filter and simulator defects.
It retains the AtlasLoot acquisition baseline, independent phase gates and verified-only defaults. Install only the local package
in `D:\Games\Octo-clean\Interface\AddOns\AshenBuilds` for client validation.
The user explicitly authorized publishing 1.0.8 on 2026-11-10 after verification.

- The user reports testing 1.0.5 on Paladin and Warrior. The supplied Paladin
  screenshot is internally consistent: 350 Defense, active Block 73%, coverage
  102.20 / 102.40% (sheet), 99.80 / 100% (attacker-adjusted), gap 0.20 points.
  No Warrior screenshot/numeric results have yet been supplied for checking.
- The Paladin screenshot's BV 74 is consistent with shield 33135's native 48,
  Strength 206 and a 30% BV talent, provided no other BV contribution applies.
  This is an arithmetic consistency check, not an independent native-character
  comparison or proof of every item/talent value.
- Priorities are native shield Block Value, Defense contributions, active
  Holy Shield/Redoubt/Shield Block in the main gear panel, both coverage
  conventions and save/load. The checklist and 102.4% / 100% example are in
  `DEFENSE-COVERAGE.md` and `TESTING-1.0.2.md` (updated for 1.0.5).
- The previous 1.0.5 candidate passed 560 addon assertions, 26 release-tooling
  tests, Lua 5.0 API lint, independent review and a geometry preview. Validate
  the new profile menus separately before describing 1.0.6 as client-tested.
  Local Lua 5.0 compilation is unavailable; offline checks do not replace Octo.
- Local 1.0.6 validation passed 634 addon assertions and 26 release-tooling tests,
  plus manifest/API lint, independent review and menu geometry/color previews.
- The user accepted the profile menus and reported phase-2 Tower loot leaking as
  Unverified. Root cause: the old Turtle summary combined a real phase-7 route
  with Development Land and lost its guaranteed minimum. Real AtlasLoot Tower
  routes now retain phase 7. New source-policy checks are recorded separately.
- The user explicitly chose normal suggestions confirmed by AtlasLoot and open
  in the selected phase, with Unverified off by default. Retain the snapshot and
  hashes; revise the baseline later if Octo changes drops/items. Missing evidence
  is not a reason to delete an item or change its saved stats.
- Local 1.0.7 validation passed 720 addon assertions and 48 tooling tests,
  plus manifest/API lint, independent source/phase review and picker previews.
  At phase 2 the source policy yields 4,470 available, 1,090 future and 10,509
  unverified item records; enchants are 219 available, 13 future and 31 unverified.
  Source evidence exists for 5,999 catalog items and 239 enchants, including
  439 items and 7 enchants with unresolved phase. Unlisted entries are not
  automatically declared unobtainable.
- 1.0.8 migration uses `perCharacterMigration=1` and a separate
  `legacySharedCurrent` for genuinely pre-character-map saves. Existing
  `currentByChar` entries remain authoritative; a new alt never claims the last
  active character's plan. Existing drafts already copied by an older version
  are retained rather than guessed away. Unknown item/enchant IDs survive AB1/2/3
  decoding; missing data remains uncounted and explicitly labelled/warned.
- Existing Scarlet Monastery wing selections migrate to `Scarlet Monastery`,
  matching the recorded source snapshot. Race masks come from the embedded
  catalog, not a new live Octo verification; `ItemRaceMaskOverrides` supports
  later documented server exceptions. Turning off both usability/class filters
  permits deliberate browsing across these restrictions.
- The 1.0.8 client checklist is in `TESTING-1.0.8.md`. Offline UI previews use
  approximate fonts/geometry; they do not establish in-game rendering quality.
- Local 1.0.8 validation passed 883 addon assertions and 50 tooling tests,
  package validation and Lua 5.0 API lint. Independent review covered the
  import/migration/calculation/filter changes and the new enchant page; its
  unknown-enchant hover and multi-select findings were fixed and retested.
  The rendered phase-2 page has no text outside the window in the geometry
  fixture. Native Lua 5.0 compilation and real-client rendering remain unchecked.
- Pre-release review added nine migration checks for a saved entry named
  `New Build`, existing detached drafts and repeated login. The corrected build
  passes 892 addon assertions and 50 tooling tests; only genuine legacy migration
  may restore a missing saved-name link. This supersedes the 883-check candidate.
- The installed Octo launcher 1.4.3 clones the repository's default branch and
  updates it with Git pull; release ZIPs and latest tags do not control its
  custom-addon installer. Publish verified builds to `main`. The URL to paste is
  `https://github.com/Shadgy/AshenBuilds`; see `LAUNCHER.md`.
- The final code passed CI including compilation of every TOC file with native
  Lua 5.0.3, all 892 addon assertions and 50 tooling tests. The real-client smoke
  check on 2026-11-10 verified loading/reload, preserved existing gear/talents,
  page navigation, enchant search/paging/target restrictions, and Paladin active
  block/coverage changes. This supersedes the older candidate's unchecked-client
  note. See `RELEASE-1.0.8.md` for the exact scope and remaining limits.
- Keep the current weapon-skill crit model: +0.20 percentage points per +5
  skill. Its Octo verification remains unresolved and the user explicitly
  deferred that check. Do not mark the coefficient as Octo-verified.
- Publication of 1.0.8 and the necessary branch/main/tag/CI operations are
  authorized by the user's later instruction. Verify checks before publishing;
  this authorization does not establish live verification of every Octo mechanic.

## Development setup

Use Python 3.12 or newer. From the repository root:

```text
python -m venv .venv
```

Activate it (`.venv\Scripts\Activate.ps1` on Windows; `source .venv/bin/activate` on Linux), then:

```text
python -m pip install -r requirements-dev.txt
python tools/package_release.py --check
python -m unittest discover -s tests -p "test_*.py"
python tests/run.py
```

Behavior suites use Lupa's Lua 5.1 runtime with a stand-in WoW API. CI separately
compiles every TOC-loaded file with Lua 5.0.3. Neither step replaces an in-game check.
The stub tolerates missing UI methods and does not reproduce the client's full event
registration behavior.

## A normal update

1. Create a branch from the fork's current `main` and make one focused change.
2. Add or adjust a regression test when behavior changes.
3. Set a plain numeric version with `python tools/set_version.py 1.0.2`.
4. Describe the result in `CHANGELOG.md`, including any save migration or known limit.
5. Run all checks above, commit the change and let GitHub Actions finish.
6. Build a candidate with `python tools/package_release.py`. For an uncommitted
   local preview only, add `--allow-dirty`; that fact is recorded inside the ZIP.
7. Install the candidate and complete the client checks below.
8. Follow the release process. Keep unverified candidates explicitly marked as such.

## Installation and client smoke check

Close the game and back up the relevant `WTF` saved-variable files. Replace only
`Interface\AddOns\AshenBuilds` with the `AshenBuilds` folder inside the ZIP. Do not
delete `WTF`. Fully restart the client after replacing addon files.

- Confirm the addon loads with the expected version and `/ab` opens the planner.
- Confirm an existing saved build still opens and survives logout/login.
- Check a second character: its current plan stays separate from the first character.
- Inspect window textures, minimap icon, item browser and all class talent backgrounds.
- Search items, use armor/usability filters, equip an item, add an enchant and save/load.
- Export and import a build, confirming equipment, enchants and talents survive.
- Run the warrior simulator and open its result/log/settings windows.
- With a second player, check community publish/load/sync and `/ab sync off`.
- Confirm there are no new Lua errors; record client/server version and results in the release notes.

## Releases

Normal pushes run checks and produce a candidate artifact; they do not publish a release.
For a verified version, push a matching `vX.Y.Z` tag from `main`, or run the Release
workflow manually for that existing tag. The workflow verifies the tag/version,
reruns checks, builds the ZIP/checksum and creates a **draft** release. Review its
notes and recorded client checks before publishing it on GitHub.

Installers always contain one `AshenBuilds/` folder. Development files are excluded.
The metadata file records the source commit; the `.sha256` file verifies the ZIP.
Rebuilding identical inputs in the same Python/zlib environment produces identical
ZIP bytes. Do not edit published tags or replace an existing version's files.

## Following upstream

The local `upstream` remote points to `Tracer96/AshenBuilds`; `origin` points to this fork.
In a fresh clone add it once:

```text
git remote add upstream https://github.com/Tracer96/AshenBuilds.git
git fetch upstream
git switch -c maintenance/upstream-sync
git merge upstream/main
```

Review conflicts, versions and embedded-data changes, then run the same checks and
client smoke test before merging. Preserve original author credits and record the
new upstream revision in `UPSTREAM.md` when advancing the tracked base.
