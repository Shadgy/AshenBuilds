# Maintaining this fork

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
