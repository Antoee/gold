# GitHub Publication Sync

Generated offline without launching MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Overall: **PENDING**
- Repository: `Antoee/gold`
- Branch: `main`
- Required passing: `1`
- Required pending: `6`
- Required failed: `0`

At least one required artifact is missing, stale, or inaccessible through the raw-file audit. The live-readiness GitHub sync gate must remain pending.

## Artifacts

| Role | Required | Status | Detail | Local SHA-256 | Local Raw Blob | Local Text Blob | Remote Git Blob | Note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| root-ea-source | True | PENDING | CONNECTOR_BLOB_MISMATCH | FF1BCDB06E5D | 89a515eaeb56 | 89a515eaeb56 | 483667b91ca9 | Exact root EA source required for reproducible publication. |
| mirrored-ea-source | True | PENDING | CONNECTOR_REMOTE_MISSING | FF1BCDB06E5D | 89a515eaeb56 | 89a515eaeb56 |  | Mirrored output EA source required for hash identity. |
| trade-ready-conservative-profile | True | PENDING | CONNECTOR_BLOB_MISMATCH | F708C68A6801 | 2fd7885bcaeb | 55c0aea0eeec | f8445311adc3 | Conservative profile used by live-readiness gates. |
| money-ready-profile | True | PENDING | CONNECTOR_BLOB_MISMATCH | 2A16CEEC3379 | 36f46b384b45 | 5df48199abfb | bca9b84b7d46 | Money-ready demo/forward-test candidate profile. |
| trade-readiness-alias-profile | True | PENDING | CONNECTOR_BLOB_MISMATCH | 2A16CEEC3379 | 36f46b384b45 | 5df48199abfb | bca9b84b7d46 | Alias profile expected to match money-ready profile. |
| source-manifest | True | PASS | CONNECTOR_BLOB_MATCH | B4FD8CCEBE25 | a58f61c3cbf7 | a58f61c3cbf7 | a58f61c3cbf7 | Source hash/status manifest. |
| current-research-best | True | PENDING | CONNECTOR_BLOB_MISMATCH | 39F3AB23C0EA | 541e0fcecfa9 | 541e0fcecfa9 | 4d1c7b813e3e | Current promoted research profile status. |
| readme-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | 3934942E7F1D | 5f630846e978 | 5f630846e978 |  | Human-facing repository dashboard. |
| github-status-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | BA5F789BBA49 | c41d9841f31f | c41d9841f31f |  | Compact GitHub-facing status board. |
| money-ready-refresh | False | INFO | OPTIONAL_NOT_VERIFIED | 64C4A9FF9B0E | 9a27e505381e | 58e5a10fe3a4 |  | Latest one-command refresh status. |
| money-ready-scorecard | False | INFO | OPTIONAL_NOT_VERIFIED | 75B9C126654F | a7bc9d2cd836 | 3024d9cb4cb1 |  | Money-ready scorecard. |
| live-readiness-decision | False | INFO | OPTIONAL_NOT_VERIFIED | 77F5F6F6FCA6 | cef6dfb60824 | 40f5ad9bfa38 |  | Final conservative live-readiness gate. |
| release-candidate-decision | False | INFO | OPTIONAL_NOT_VERIFIED | 2E1FE136A88A | c90ec2bab917 | 2e51d1a84dee |  | Release-candidate gate. |
| first-pass-parallel-lanes | False | INFO | OPTIONAL_NOT_VERIFIED | E57EA9229A0C | 226617f22a1e | 1089f4fc1c81 |  | Fast first-pass lane split. |
| github-required-artifact-sync-package | False | INFO | OPTIONAL_NOT_VERIFIED | D9C263DCDBD2 | 7fa37d9575bf | dfd089ab1c43 |  | Exact upload package for remaining required source/profile blockers. |
| evidence-handoff | False | INFO | OPTIONAL_NOT_VERIFIED | 481034B315FC | 8a2911e41be3 | c92802f9194e |  | Evidence handoff summary. |
