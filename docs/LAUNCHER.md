# Install with Octo Launcher

Open **Addons → Add custom git addon**, paste:

**https://github.com/Shadgy/AshenBuilds**

Then select **Install**. Keep the folder/repository name `AshenBuilds` so the
launcher installs `Interface/AddOns/AshenBuilds/AshenBuilds.toc` correctly.
Back up the existing addon and saved variables before switching installations.
Do not run two copies of the addon under different folder names.

The launcher clones the repository's default branch (`main`); later updates use
Git pull on the installed branch. A GitHub Release ZIP URL or a `/tree/branch`
URL is not the custom Git-addon input. The `main` branch is therefore reserved
for verified builds; development work stays on separate branches.

Manual ZIP packages remain available on the repository's Releases page.
The launcher replaces addon files, while character/build data remains in `WTF`.

The install/update logic was checked on 2026-11-10 in the locally installed
Octo Launcher 1.4.3. The public source currently identifies itself as 1.3.6 and
has the same relevant logic:

- [URL validation and installation](https://octowow.st/git/OctoWoW/OctoLauncher/src/branch/main/src/main/modules/addons.ts#L133)
- [Clone worker](https://octowow.st/git/OctoWoW/OctoLauncher/src/branch/main/src/main/workers/gitClone.ts#L15)
- [Update worker](https://octowow.st/git/OctoWoW/OctoLauncher/src/branch/main/src/main/workers/gitPull.ts)
