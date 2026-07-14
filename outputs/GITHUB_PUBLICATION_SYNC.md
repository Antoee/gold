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
| source-manifest | True | PASS | CONNECTOR_BLOB_MATCH | 6E559A964B36 | 1b55778fd310 | 1b55778fd310 | Source hash/status manifest. |
| current-research-best | True | PASS | CONNECTOR_BLOB_MATCH | 396DD04027D7 | 4d1c7b813e3e | 4d1c7b813e3e | Current promoted research profile status. |
| readme-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | 22FE2045874E | 49d3fdea33c4 |  | Human-facing repository dashboard. |
| github-status-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | AB304F5DB89A | 70a2f5afb7ee |  | Compact GitHub-facing status board. |
| money-ready-refresh | False | INFO | OPTIONAL_NOT_VERIFIED | EC6B7D6722AB | 099272999f72 |  | Latest one-command refresh status. |
| money-ready-scorecard | False | INFO | OPTIONAL_NOT_VERIFIED | 849ECAA35A8F | 7e143168f2eb |  | Money-ready scorecard. |
| live-readiness-decision | False | INFO | OPTIONAL_NOT_VERIFIED | BF2A86A547A0 | 7513daf1e282 |  | Final conservative live-readiness gate. |
| release-candidate-decision | False | INFO | OPTIONAL_NOT_VERIFIED | BDC7E355C28F | 1d772796edb6 |  | Release-candidate gate. |
| first-pass-parallel-lanes | False | INFO | OPTIONAL_NOT_VERIFIED | 706EBFCA5C5F | 4a6d0cf2eac4 |  | Fast first-pass lane split. |
| evidence-handoff | False | INFO | OPTIONAL_NOT_VERIFIED | CFA93C33EADB | 31921ae45fee |  | Evidence handoff summary. |
