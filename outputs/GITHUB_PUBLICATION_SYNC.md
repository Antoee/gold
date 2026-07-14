# GitHub Publication Sync

Generated offline without launching MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Overall: **PENDING**
- Repository: `Antoee/gold`
- Branch: `main`
- Required passing: `5`
- Required pending: `2`
- Required failed: `0`

At least one required artifact is missing, stale, or inaccessible through the raw-file audit. The live-readiness GitHub sync gate must remain pending.

## Artifacts

| Role | Required | Status | Detail | Local SHA-256 | Local Git Blob | Remote Git Blob | Note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| root-ea-source | True | PENDING | CONNECTOR_BLOB_MISMATCH | 44D9EBA868C8 | ac0b7d071394 | 483667b91ca9 | Exact root EA source required for reproducible publication. |
| mirrored-ea-source | True | PENDING | CONNECTOR_REMOTE_MISSING | 44D9EBA868C8 | ac0b7d071394 |  | Mirrored output EA source required for hash identity. |
| trade-ready-conservative-profile | True | PASS | CONNECTOR_BLOB_MATCH | 621F54A4BFE6 | 856f81051891 | 856f81051891 | Conservative profile used by live-readiness gates. |
| money-ready-profile | True | PASS | CONNECTOR_BLOB_MATCH | 0CF800571C22 | 94ba77b28633 | 94ba77b28633 | Money-ready demo/forward-test candidate profile. |
| trade-readiness-alias-profile | True | PASS | CONNECTOR_BLOB_MATCH | 0CF800571C22 | 94ba77b28633 | 94ba77b28633 | Alias profile expected to match money-ready profile. |
| source-manifest | True | PASS | CONNECTOR_BLOB_MATCH | 18E4161618CE | 8aa18509464c | 8aa18509464c | Source hash/status manifest. |
| current-research-best | True | PASS | CONNECTOR_BLOB_MATCH | D36557E328BE | 76e5272c86a7 | 76e5272c86a7 | Current promoted research profile status. |
| readme-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | 4FA9E700705C | 7a205951ed05 |  | Human-facing repository dashboard. |
| github-status-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | B465C228FDA4 | b4808d1659b6 |  | Compact GitHub-facing status board. |
| money-ready-refresh | False | INFO | OPTIONAL_NOT_VERIFIED | 223DBA93593F | bc276b687c77 |  | Latest one-command refresh status. |
| money-ready-scorecard | False | INFO | OPTIONAL_NOT_VERIFIED | BFAF39E1A70E | a430c78d1192 |  | Money-ready scorecard. |
| live-readiness-decision | False | INFO | OPTIONAL_NOT_VERIFIED | BE95BA432A63 | 447b01f71cc5 |  | Final conservative live-readiness gate. |
| release-candidate-decision | False | INFO | OPTIONAL_NOT_VERIFIED | 953FD949A224 | 42eacb6100f5 |  | Release-candidate gate. |
| first-pass-parallel-lanes | False | INFO | OPTIONAL_NOT_VERIFIED | 706EBFCA5C5F | 4a6d0cf2eac4 |  | Fast first-pass lane split. |
| evidence-handoff | False | INFO | OPTIONAL_NOT_VERIFIED | 51B57307B82F | cebb7629fc4c |  | Evidence handoff summary. |
