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
| readme-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | 4EA3E98AEA76 | 76b0f1ad4f12 |  | Human-facing repository dashboard. |
| github-status-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | 4D9D5FC52D6D | cf702e5184e9 |  | Compact GitHub-facing status board. |
| money-ready-refresh | False | INFO | OPTIONAL_NOT_VERIFIED | A4F69904E73B | c67ee6b024d4 |  | Latest one-command refresh status. |
| money-ready-scorecard | False | INFO | OPTIONAL_NOT_VERIFIED | 99599840A4C1 | 00a387e936aa |  | Money-ready scorecard. |
| live-readiness-decision | False | INFO | OPTIONAL_NOT_VERIFIED | B573D9A68758 | c9c7eb780616 |  | Final conservative live-readiness gate. |
| release-candidate-decision | False | INFO | OPTIONAL_NOT_VERIFIED | BDC7E355C28F | 1d772796edb6 |  | Release-candidate gate. |
| first-pass-parallel-lanes | False | INFO | OPTIONAL_NOT_VERIFIED | E57EA9229A0C | 226617f22a1e |  | Fast first-pass lane split. |
| evidence-handoff | False | INFO | OPTIONAL_NOT_VERIFIED | B4BFBD6AD2A9 | 8fa95cec2e5d |  | Evidence handoff summary. |
