# Personal patches

We follow published upstream stable releases, with personal patches on the `personal` branch.
The exact base tag and commit live in [.agents/tinycast-release.json](.agents/tinycast-release.json).
This file explains what we carry; Git holds the implementation history.

## Active app patches

| ID | Patch and purpose | Implementation and verification |
| --- | --- | --- |
| P001 | **Currency shorthand.** Accept `10 usd cny`, `€20 GBP`, and `2*50 usd eur` without typing `to`. Require an explicit amount and unambiguous currency names; incomplete input stays silent. | [CalcCurrency.swift](Tinycast/Features/Calculator/Model/CalcCurrency.swift), [calculator tests](Tests/calc-test.swift), [behavior](docs/features/calculator.md#currency). |
| P002 | **Personal build label.** Show `Personal build · <revision>` in About so the installed patched build is identifiable. Ordinary builds show no extra label. | [AboutView.swift](Tinycast/Windows/About/AboutView.swift). Verify the label against the bundle's `TinycastPatchRevision`. |

## Fork tooling

| ID | Purpose | Files |
| --- | --- | --- |
| W001 | Build the recorded stable version, embed its upstream and personal revisions before signing, and reject uncommitted or changing source. Preserve the stable bundle ID and signing identity. | [build-personal.sh](Scripts/build-personal.sh), [build documentation](docs/development.md#personal-release-builds). |
| W002 | Define the stable-release update, patch review, verification, backup, and installation workflow. | [update-with-patch](.agents/skills/update-with-patch/SKILL.md), [AGENTS.md](AGENTS.md#personal-release-updates), this inventory. |

## Update history

### 2026-09-23 — v0.10.20 → v0.11.3

- Upstream rewrote its history: `v0.10.20` now points at `8ee0586b`, whose tree differs from our
  old base `036262e` only by one line in `docs/ui.md`. Rebased with
  `--onto v0.11.3 036262e`; all 9 commits applied cleanly and `git range-diff` shows each identical.
- Preserved P001, P002, W001 and W002 unchanged. Upstream's calculator changes (locale number
  format, px/rem/em, time zones) don't implement the currency shorthand, and there's still no
  personal build label.
- Pre-install checks: lint, model purity, and the Debug build passed (the only warnings are
  upstream `ClipboardView` isolated-conformance warnings under Xcode 27 beta). 74 of 76 harnesses
  pass; `codex-turn-test` and `installed-ai-test` fail identically on pristine v0.11.3 because
  `ExecutableLocator` resolves the real `codex`/`opencode` via the login shell before the stubs.
- Rebuilt and reinstalled over a backed-up v0.10.20 bundle; signature/identity/version/revision/
  hash checks and relaunch passed. Receipt: `build/personal-0.11.3-receipt.txt`.

### 2026-09-13 — v0.10.15 → v0.10.20

- Rebased `personal` onto upstream `v0.10.20` (`036262e`); all 7 commits applied cleanly
  with no conflicts, and `git range-diff` shows each patch identical before and after.
- Preserved P001, P002, W001 and W002 unchanged. Upstream implements neither the currency
  shorthand nor the personal build label (verified against the diff with the new tag).
- Pre-install checks: 70 harnesses, lint, model purity, and the Debug build passed with no
  new warnings. The suite needs `SDKROOT` from `xcrun` plus `LIBRARY_PATH="$SDKROOT/usr/lib"`
  on Apple silicon or 9 sqlite-linking harnesses fail. Built with Xcode 27 beta.
- Rebuilt and reinstalled: Release personal build signed and verified, installed over a
  backed-up v0.10.15 bundle; signature/identity/version/revision/hash checks and relaunch
  passed. Receipt: `build/personal-0.10.20-receipt.txt`.

### 2026-09-12 — v0.10.15 (no upstream change)

- Upstream's latest published stable release is still v0.10.15; v0.10.16–v0.10.19 are prereleases,
  so the base is unchanged and no rebase was needed.
- Preserved P001, P002 and W001 unchanged. Committed the W002 skill rename and this inventory.
- Rebuilt and reinstalled: 62 harnesses, lint, model purity, Debug and Release builds,
  signature/identity/version/revision/hash checks and relaunch passed. Built with Xcode 27 beta.

### 2026-09-09 — v0.10.5 → v0.10.15

- Preserved P001; adapted its test to upstream's required clock and calendar arguments.
- Preserved P002 alongside upstream's Settings search support.
- Preserved W001 and renamed/shortened the update skill to `update-with-patch` (W002).
- Retired our expired storage-relocation removal patch: upstream already removed that code
  in `e8c2916`, included in v0.10.15.
- Installed app verification: 62 harnesses, lint, model purity, Debug/Release builds,
  signature/hash checks, and relaunch passed. Built with Xcode 27 beta; upstream warnings remain.

## Keeping this accurate

Update this inventory in the same change that adds, changes, or removes a personal patch.
After each release update, reconcile it with the complete diff against the recorded base and
add a dated history entry for preserved, adapted, and retired patches. Keep IDs stable across
rebases; commit hashes change. Record why a patch was retired and the upstream evidence.
Record installation checks only after they pass; local artifact receipts live under `build/`.

To list committed patches and inspect their combined diff from the repository root:

```sh
patch_base=$(python3 -c 'import json; print(json.load(open(".agents/tinycast-release.json"))["commit"])')
git log --reverse --oneline "$patch_base"..personal
git diff --stat "$patch_base" personal
git diff "$patch_base" personal
```

These commands show committed work. Use `git status --short` to see pending changes too.
