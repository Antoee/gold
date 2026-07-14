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

| Role | Required | Status | Detail | Local SHA-256 | Local Raw Blob | Local Text Blob | Remote Git Blob | Note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| root-ea-source | True | PENDING | CONNECTOR_BLOB_MISMATCH | 5D148DAE2335 | 71475f3665b2 | 71475f3665b2 | 483667b91ca9 | Exact root EA source required for reproducible publication. |
| mirrored-ea-source | True | PENDING | CONNECTOR_REMOTE_MISSING | 5D148DAE2335 | 71475f3665b2 | 71475f3665b2 |  | Mirrored output EA source required for hash identity. |
| trade-ready-conservative-profile | True | PASS | CONNECTOR_TEXT_BLOB_MATCH | 825308011021 | 8c4a3eb4df10 | f8445311adc3 | f8445311adc3 | Conservative profile used by live-readiness gates. |
| money-ready-profile | True | PASS | CONNECTOR_TEXT_BLOB_MATCH | 553A967B5FCE | d8389ca533a7 | bca9b84b7d46 | bca9b84b7d46 | Money-ready demo/forward-test candidate profile. |
| trade-readiness-alias-profile | True | PASS | CONNECTOR_TEXT_BLOB_MATCH | 553A967B5FCE | d8389ca533a7 | bca9b84b7d46 | bca9b84b7d46 | Alias profile expected to match money-ready profile. |
| source-manifest | True | PASS | CONNECTOR_BLOB_MATCH | 6E559A964B36 | 1b55778fd310 | 1b55778fd310 | 1b55778fd310 | Source hash/status manifest. |
| current-research-best | True | PASS | CONNECTOR_BLOB_MATCH | 396DD04027D7 | 4d1c7b813e3e | 4d1c7b813e3e | 4d1c7b813e3e | Current promoted research profile status. |
| readme-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | C31F2CD1B246 | 6e04bfbc1d2f | 6e04bfbc1d2f |  | Human-facing repository dashboard. |
| github-status-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | 09CB34FB1F55 | b2d42bfd2dda | b2d42bfd2dda |  | Compact GitHub-facing status board. |
| money-ready-refresh | False | INFO | OPTIONAL_NOT_VERIFIED | 9F32CB82DE99 | 801585b33f92 | c3e49daab695 |  | Latest one-command refresh status. |
| money-ready-scorecard | False | INFO | OPTIONAL_NOT_VERIFIED | 9E23F2ADF492 | 34285e18b7d5 | de054e005a56 |  | Money-ready scorecard. |
| live-readiness-decision | False | INFO | OPTIONAL_NOT_VERIFIED | E90F8585B3E6 | d0c61a2ecfe8 | 2ac4a9efa5d7 |  | Final conservative live-readiness gate. |
| release-candidate-decision | False | INFO | OPTIONAL_NOT_VERIFIED | BDC7E355C28F | 1d772796edb6 | 867d20f4ab62 |  | Release-candidate gate. |
| first-pass-parallel-lanes | False | INFO | OPTIONAL_NOT_VERIFIED | E57EA9229A0C | 226617f22a1e | 1089f4fc1c81 |  | Fast first-pass lane split. |
| github-required-artifact-sync-package | False | INFO | OPTIONAL_NOT_VERIFIED | 4C56469DB59A | 4f98bf0dd7b2 | 3059b7102eac |  | Exact upload package for remaining required source/profile blockers. |
| evidence-handoff | False | INFO | OPTIONAL_NOT_VERIFIED | B4BFBD6AD2A9 | 8fa95cec2e5d | c42af76a4769 |  | Evidence handoff summary. |
