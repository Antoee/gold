# GitHub Publication Sync

Generated offline without launching MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Overall: **PENDING**
- Repository: `Antoee/gold`
- Branch: `main`
- Required passing: `0`
- Required pending: `7`
- Required failed: `0`

At least one required artifact is missing, stale, or inaccessible through the raw-file audit. The live-readiness GitHub sync gate must remain pending.

## Required Artifacts

| Role | Status | Detail | Local SHA-256 prefix | Note |
| --- | --- | --- | --- | --- |
| root-ea-source | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | `44D9EBA868C8` | Exact root EA source required for reproducible publication. |
| mirrored-ea-source | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | `44D9EBA868C8` | Mirrored output EA source required for hash identity. |
| trade-ready-conservative-profile | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | `621F54A4BFE6` | Conservative profile used by live-readiness gates. |
| money-ready-profile | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | `0CF800571C22` | Money-ready demo/forward-test candidate profile. |
| trade-readiness-alias-profile | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | `0CF800571C22` | Alias profile expected to match money-ready profile. |
| source-manifest | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | `5EDCB8CCA8AC` | Source hash/status manifest. |
| current-research-best | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | `F9724532D70C` | Current promoted research profile status. |

## Meaning

The GitHub connector can update dashboard files, but local PowerShell cannot verify the private/raw GitHub contents by SHA-256. This gate stays pending until exact source/profile artifacts can be independently hash-verified through a valid git checkout or another authenticated publication path.
