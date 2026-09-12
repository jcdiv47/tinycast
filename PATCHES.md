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
