# Ashen Builds maintenance

- Target Turtle WoW's 1.12 client and Lua 5.0. Do not add Lua 5.1 syntax or APIs.
- Keep the installation folder and TOC named `AshenBuilds`. Textures and startup events depend on it.
- Preserve `AshenBuildsDB` and build import/export formats. Any migration needs regression coverage and an explicit migration note.
- Preserve the TOC load order, original author credit and source provenance in `UPSTREAM.md`.
- Use `python tools/set_version.py X.Y.Z` to change the numeric version in both places.
- Update `CHANGELOG.md` for user-visible or maintenance changes. Distinguish inherited upstream changes from fork changes.
- Before committing: `python tools/package_release.py --check`, `python -m unittest discover -s tests -p "test_*.py"`, and `python tests/run.py`. CI additionally compiles TOC files using Lua 5.0.3.
- Build installation ZIPs with `tools/package_release.py`; never ship the development checkout or rename the addon folder.
- Do not regenerate embedded data without recording its source snapshot and reviewing the generated diff.
- Offline API stubs do not verify game rendering or all client behavior. Record the manual checks in `docs/MAINTENANCE.md` before publishing a stable release.
