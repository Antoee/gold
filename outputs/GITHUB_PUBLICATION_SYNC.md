# GitHub Publication Sync

Generated offline without launching MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Overall: **PENDING**
- Repository: `Antoee/gold`
- Branch: `main`
- Required passing: `0`
- Required pending: `7`
- Required failed: `0`

At least one required artifact is missing, stale, or inaccessible through the raw-file audit. The live-readiness GitHub sync gate must remain pending.

## Artifacts

| Role | Required | Status | Detail | Local SHA-256 | Local Git Blob | Remote Git Blob | Note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| root-ea-source | True | PENDING | CONNECTOR_BLOB_MISMATCH | 44D9EBA868C8 | ac0b7d071394 | 483667b91ca9 | Exact root EA source required for reproducible publication. |
| mirrored-ea-source | True | PENDING | CONNECTOR_REMOTE_MISSING | 44D9EBA868C8 | ac0b7d071394 |  | Mirrored output EA source required for hash identity. |
| trade-ready-conservative-profile | True | PENDING | CONNECTOR_REMOTE_MISSING | 621F54A4BFE6 | 856f81051891 |  | Conservative profile used by live-readiness gates. |
| money-ready-profile | True | PENDING | CONNECTOR_REMOTE_MISSING | 0CF800571C22 | 94ba77b28633 |  | Money-ready demo/forward-test candidate profile. |
| trade-readiness-alias-profile | True | PENDING | CONNECTOR_REMOTE_MISSING | 0CF800571C22 | 94ba77b28633 |  | Alias profile expected to match money-ready profile. |
| source-manifest | True | PENDING | CONNECTOR_BLOB_MISMATCH | 18E4161618CE | 8aa18509464c | 99b112ede259 | Source hash/status manifest. |
| current-research-best | True | PENDING | CONNECTOR_BLOB_MISMATCH | D36557E328BE | 76e5272c86a7 | 3da2655f72d0 | Current promoted research profile status. |
| readme-dashboard | False | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | E25FB44EFE00 | f4ed252b2a49 |  | Human-facing repository dashboard. |
| github-status-dashboard | False | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | D6990AD5F232 | 31e2a5fe5e8e |  | Compact GitHub-facing status board. |
| money-ready-refresh | False | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | 86CB62CAB9B8 | b93583319c73 |  | Latest one-command refresh status. |
| money-ready-scorecard | False | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | F30AA901D347 | bf2103d65b97 |  | Money-ready scorecard. |
| live-readiness-decision | False | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | E7D9CBF325B2 | 3c67758123cf |  | Final conservative live-readiness gate. |
| release-candidate-decision | False | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | 953FD949A224 | 42eacb6100f5 |  | Release-candidate gate. |
| first-pass-parallel-lanes | False | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | 706EBFCA5C5F | 4a6d0cf2eac4 |  | Fast first-pass lane split. |
| evidence-handoff | False | PENDING | REMOTE_UNAVAILABLE_OR_MISSING | 51B57307B82F | cebb7629fc4c |  | Evidence handoff summary. |
