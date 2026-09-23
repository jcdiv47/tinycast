---
name: update-with-patch
description: Update this Tinycast fork to the latest upstream stable release, preserve personal patches, verify, build, and install in /Applications. Use when asked to "update with patches" or update the patched app.
---

# Update with patches

Follow **published upstream stable releases** until the user explicitly changes that policy.
The result is the latest stable release plus our patches, installed in `/Applications/Tinycast.app`.

## Source and patches

- Upstream: `https://github.com/abue-ammar/tinycast.git` (`upstream`).
- Fork: `https://github.com/jcdiv47/tinycast` (`origin`); patch branch: `personal`.
- Base record: `.agents/tinycast-release.json` contains the upstream tag and commit.
- Patch inventory: `PATCHES.md` lists active patches, tooling, and update history.
- Read `AGENTS.md`, `docs/{development,testing,release}.md`, and affected feature docs.

1. Inspect status, remotes, and commits above the recorded base. Verify that base is an
   ancestor of `personal` and the range contains only our patches and workflow tooling.
   Preserve unfinished work; leave unrelated untracked files alone. Keep functional patches
   in focused commits with their tests/docs, and workflow changes in separate commits.
2. Query `https://api.github.com/repos/abue-ammar/tinycast/releases/latest`. Require
   `draft == false`, `prerelease == false`, and a `vMAJOR.MINOR.PATCH` tag. Fetch that exact
   tag from `upstream` and resolve its commit. Never substitute a main branch or beta.
3. With a clean tracked tree, create a unique backup branch, then run
   `git rebase --onto <new-tag> <old-base-commit> personal`. Skip if the base is unchanged.
   Preserve patch intent through conflicts; drop a patch only after verifying upstream
   implements it. If a product decision is unclear, stop and ask with the backup intact.
4. Review the full diff against the new tag and
   `git range-diff <old-base>..<backup> <new-tag>..personal`. Update and commit the base record
   and `PATCHES.md`, recording preserved, adapted, and retired patches with upstream evidence.
   Do not push unless requested;
   an authorized rewritten remote branch requires an explicit expected-SHA force-with-lease.

## Verify and install

1. Discover installed Xcode. Set `DEVELOPER_DIR` per command, including lint; prefer the
   required stable toolchain and disclose beta use. Do not change global Xcode selection.
2. Run `./Scripts/run-tests.sh`, `./Scripts/lint.sh`, the model import purity check, and a
   Debug build as specified in `docs/testing.md`. Fix patch regressions; identify upstream
   or toolchain warnings. If SQLite links an Intel library on Apple silicon, set `SDKROOT`
   from `xcrun --sdk macosx --show-sdk-path` and `LIBRARY_PATH="$SDKROOT/usr/lib"` for tests.
3. Commit tracked changes, then run `Scripts/install-personal.sh`, which performs steps 3–5
   through `Scripts/build-personal.sh`. It stamps the stable
   version and source revisions before signing. Keep `com.tinycast.app` and the existing
   `Tinycast Self-Signed` identity. Do not alter `project.yml` or invent version suffixes.
4. After checks pass, gracefully quit the installed app, back up its bundle, and replace it
   through a verified staging bundle. Restore the backup if replacement fails. Before a
   downgrade, also back up Application Support and preferences; never wipe user data.
5. Verify the installed signature, signing identity, version, source revisions, executable
   hash against the build, and successful relaunch. Save artifact/backup paths and check
   results in a local receipt under `build/`.

To publish, only when asked, push `personal` and the next `v<version>-personal.<n>` tag; the
release workflow waits for Personal CI. Report the release tag and URL.

Report the stable version, personal revision, preserved/redundant patches, checks, installed
path, receipt, and limitations. The built-in updater installs unpatched binaries: do not use
it for this workflow or disable its notifications. This skill does not schedule updates.
