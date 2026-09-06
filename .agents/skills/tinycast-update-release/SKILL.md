---
name: tinycast-update-release
description: Update this Tinycast fork to the latest published stable release while preserving personal patches, then verify, build, and install it. Use for requests to update this project's patched app.
---

# Update Tinycast with personal patches

The intended installed app is the latest published stable upstream release plus the user's
patch commits. Follow release tags, not either remote's main branch or beta releases.

## Repository state

- `upstream`: https://github.com/abue-ammar/tinycast.git, the release source.
- `origin`: https://github.com/jcdiv47/tinycast, the user's fork.
- `personal`: the maintained patch branch. Keep each functional patch in a focused commit,
  including its tests and documentation; keep workflow tooling in a separate commit.
- `.agents/tinycast-release.json`: records the exact upstream base tag and commit.
- Leave unrelated untracked research files alone. Never fold them into a patch implicitly.

## Updating

1. Read root AGENTS.md and the development, testing, release, and affected feature docs.
   Inspect status and remotes; preserve unfinished changes before switching bases. Commit
   task-relevant patches, and make a uniquely named backup branch before rewriting history.
2. Query GitHub's upstream releases API for the latest published stable release. Verify it
   is neither draft nor prerelease and its tag is `vMAJOR.MINOR.PATCH`. Fetch the exact tag
   from upstream and resolve its commit; never assume the fork has current release tags.
3. Read the recorded old base and verify it is an ancestor of `personal`. Inspect the commits
   above it to ensure the range contains only personal patches and workflow files. For first
   adoption, identify the actual original patch boundary rather than replaying unreleased
   upstream commits accidentally.
4. With a clean tracked working tree, run
   `git rebase --onto <new-tag> <old-base-commit> personal`. Skip rebasing when the base is
   unchanged. Resolve conflicts by preserving each patch's intent against the new release.
   Drop a patch only when upstream demonstrably implements it, and verify that behavior.
   If a conflict requires an unknown product decision, retain the backup and ask for that decision.
5. Update the base record and commit it. Review the complete diff against the release tag.
   Use `git range-diff` against the backup to check patch preservation. Do not push, publish,
   or force-push unless the user requests remote publication. If authorized to replace a
   previously published personal branch, use an explicit expected-old-SHA force-with-lease.

## Verification and installation

- Run the entire repository test suite, lint, model import purity check, and Debug build.
  Fix patch regressions; distinguish pre-existing/toolchain warnings from new warnings.
- Discover installed Xcode rather than assuming `/Applications/Xcode.app` exists. Set
  DEVELOPER_DIR per command without changing the machine's global selection. Prefer the
  project's required stable toolchain when installed; disclose use of a beta toolchain.
- If harness linking selects an Intel `/usr/local/lib/libsqlite3.dylib` on Apple silicon,
  set SDKROOT to `xcrun --sdk macosx --show-sdk-path` and LIBRARY_PATH to its `usr/lib`
  for the test process. Do not move system libraries or edit shipped models to fix this.
- Build Release with `Scripts/build-personal.sh`. It derives MARKETING_VERSION from the
  recorded release tag and embeds the base and patch revision in the signed bundle.
  Do not permanently change project.yml just to stamp one release; do not append an
  unsupported custom suffix to AppVersion or invent a high version to suppress updates.
- Keep the existing stable bundle ID and Tinycast Self-Signed identity so the installed app
  retains its data and grants. Let the user approve a Keychain prompt if signing needs it.
- Only after verification succeeds, gracefully terminate the installed app, back up its bundle,
  and install the verified build in `/Applications/Tinycast.app` through a staged replacement.
  Back up its Application Support and preferences before moving from newer unreleased code
  to an older stable base. Never wipe or migrate user data speculatively.
- Verify installed signature, embedded version and revisions, executable hash, and successful
  relaunch. Record the installed artifact and backup paths in a local build receipt.
- The built-in updater installs unpatched upstream binaries. Do not use it for this workflow;
  retain release notifications and update through this skill instead. Changing the app's
  updater UI or implementing automated rebuilds is a separate feature task.

Report the upstream version, personal commit, preserved patches, checks, installed path, and
any real limitations. Creating this skill does not itself schedule automatic updates.
