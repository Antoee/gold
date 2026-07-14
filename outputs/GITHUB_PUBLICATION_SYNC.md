# GitHub Publication Sync

Generated offline without launching MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Overall: **PENDING**
- Repository: `Antoee/gold`
- Branch: `main`
- Required passing: `2`
- Required pending: `5`
- Required failed: `0`

At least one required artifact is missing, stale, or inaccessible through the raw-file audit. The live-readiness GitHub sync gate must remain pending.

## Artifacts

| Role | Required | Status | Detail | Local SHA-256 | Local Git Blob | Remote Git Blob | Note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| root-ea-source | True | PENDING | CONNECTOR_BLOB_MISMATCH | 5D148DAE2335 | 71475f3665b2 | 483667b91ca9 | Exact root EA source required for reproducible publication. |
| mirrored-ea-source | True | PENDING | CONNECTOR_REMOTE_MISSING | 5D148DAE2335 | 71475f3665b2 |  | Mirrored output EA source required for hash identity. |
| trade-ready-conservative-profile | True | PENDING | CONNECTOR_BLOB_MISMATCH | 825308011021 | 8c4a3eb4df10 | 856f81051891 | Conservative profile used by live-readiness gates. |
| money-ready-profile | True | PENDING | CONNECTOR_BLOB_MISMATCH | 553A967B5FCE | d8389ca533a7 | 94ba77b28633 | Money-ready demo/forward-test candidate profile. |
| trade-readiness-alias-profile | True | PENDING | CONNECTOR_BLOB_MISMATCH | 553A967B5FCE | d8389ca533a7 | 94ba77b28633 | Alias profile expected to match money-ready profile. |
| source-manifest | True | PASS | CONNECTOR_BLOB_MATCH | 0B62F721D9FB | 793c586ceddc | 793c586ceddc | Source hash/status manifest. |
| current-research-best | True | PASS | CONNECTOR_BLOB_MATCH | 396DD04027D7 | 4d1c7b813e3e | 4d1c7b813e3e | Current promoted research profile status. |
| readme-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | C72E15DA886A | 53a1a36cfd5d |  | Human-facing repository dashboard. |
| github-status-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | B7D73F156166 | b76618fda981 |  | Compact GitHub-facing status board. |
| money-ready-refresh | False | INFO | OPTIONAL_NOT_VERIFIED | CF3EFF000B17 | ac76bb33bdc8 |  | Latest one-command refresh status. |
| money-ready-scorecard | False | INFO | OPTIONAL_NOT_VERIFIED | 3DD360756589 | 85c7e0a00ff0 |  | Money-ready scorecard. |
| live-readiness-decision | False | INFO | OPTIONAL_NOT_VERIFIED | 07F472C8C57D | 25553d226758 |  | Final conservative live-readiness gate. |
| release-candidate-decision | False | INFO | OPTIONAL_NOT_VERIFIED | BDC7E355C28F | 1d772796edb6 |  | Release-candidate gate. |
| first-pass-parallel-lanes | False | INFO | OPTIONAL_NOT_VERIFIED | 706EBFCA5C5F | 4a6d0cf2eac4 |  | Fast first-pass lane split. |
| evidence-handoff | False | INFO | OPTIONAL_NOT_VERIFIED | CFA93C33EADB | 31921ae45fee |  | Evidence handoff summary. |
