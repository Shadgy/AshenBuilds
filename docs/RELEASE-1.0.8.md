# Ashen Builds 1.0.8 verification

Date: 2026-11-10. Publication was explicitly authorized by the maintainer after
the previous local-only development stage.

## Automated checks

- 892 addon assertions and 50 Python tooling tests passed locally.
- Package manifest validation and Lua 5.0 API lint passed.
- GitHub Actions built checksum-verified Lua 5.0.3 and successfully compiled
  every TOC-loaded file, reran both test suites and built the installation ZIP.
- [Pre-release code check](https://github.com/Shadgy/AshenBuilds/actions/runs/42832989279)
  checked code revision `d6b87e6280f2e3bdab4d58256086797e4821ca90`.
  Subsequent release-record changes are documentation only.
- The local ZIP contains one `AshenBuilds/` directory, 157 files including
  BUILD-INFO.json, and 38 TGA textures. Installed files were checked against it.

## Real Octo client smoke check

Observed in the running Octo client with an existing Human Paladin plan:

- `/ab` opened version 1.0.8, including the six-tab header without overlap.
- Enchant Database showed 219 entries in phase 2 with future/unverified off.
  Next changed page; searching Crusader returned one entry. Its target menu
  enabled the equipped main-hand sword and greyed the off-hand shield.
- Planner, Talents, Item Database, Saved Builds, Enchant Database and the
  existing Community list rendered and switched without an AshenBuilds error
  dialog during the observed actions. No user build was published to Community.
- The existing plan showed Defense 350, main Block 73%, Block Value 74,
  sheet coverage 102.20/102.40%, attacker coverage 99.80/100%, gap 0.20 points.
- Turning Holy Shield off changed main Block to 28%, detail Block to 27.40%,
  sheet coverage to 57.20/102.40%, attacker coverage to 54.80/100% and gap to
  45.20 points. Restoring Holy Shield restored the initial values.
- After installing the final migration correction, `/reload` completed and
  `/ab` reopened the same equipment, enchants and 51-point talent allocation.
  Talent, item, saved-build and enchant pages remained usable after reload.
- The availability window showed Octo phase 2, all instances, future off and
  unverified off. Testing left those settings and the original gear intact.

## Scope and remaining limits

The client check covers the UI/actions above. Warrior calculations/simulation,
import cancellation and repeated-login migration were covered by automated
regressions; no new two-character login comparison or second-player sync test
was performed during this release check. The presence of a model in the planner
does not independently verify every private-server mechanic or catalog record.

Weapon skill → crit remains the inherited model and is explicitly unverified
on Octo. Its separate verification is deferred. Source availability uses the
recorded AtlasLoot baseline and Octo phase mapping; later server changes and
confirmed race-mask exceptions require maintained overrides.

## Distribution

Octo Launcher custom Git URL: **https://github.com/Shadgy/AshenBuilds**.
The launcher clones/updates `main`; the release tag and ZIP serve manual installs
and reproducible source provenance. See `LAUNCHER.md`.
