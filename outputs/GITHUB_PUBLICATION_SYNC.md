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

| Role | Required | Status | Detail | Local SHA-256 | Local Raw Blob | Local Text Blob | Remote Git Blob | Note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| root-ea-source | True | PENDING | CONNECTOR_BLOB_MISMATCH | FF1BCDB06E5D | 89a515eaeb56 | 89a515eaeb56 | 483667b91ca9 | Exact root EA source required for reproducible publication. |
| mirrored-ea-source | True | PENDING | CONNECTOR_REMOTE_MISSING | FF1BCDB06E5D | 89a515eaeb56 | 89a515eaeb56 |  | Mirrored output EA source required for hash identity. |
| trade-ready-conservative-profile | True | PENDING | CONNECTOR_BLOB_MISMATCH | F708C68A6801 | 2fd7885bcaeb | 55c0aea0eeec | f8445311adc3 | Conservative profile used by live-readiness gates. |
| money-ready-profile | True | PENDING | CONNECTOR_BLOB_MISMATCH | 2A16CEEC3379 | 36f46b384b45 | 5df48199abfb | bca9b84b7d46 | Money-ready demo/forward-test candidate profile. |
| trade-readiness-alias-profile | True | PENDING | CONNECTOR_BLOB_MISMATCH | 2A16CEEC3379 | 36f46b384b45 | 5df48199abfb | bca9b84b7d46 | Alias profile expected to match money-ready profile. |
| source-manifest | True | PENDING | CONNECTOR_BLOB_MISMATCH | B1FDB15B0F21 | 7a0b42d21fcf | 7a0b42d21fcf | a58f61c3cbf7 | Source hash/status manifest. |
| current-research-best | True | PENDING | CONNECTOR_BLOB_MISMATCH | 39F3AB23C0EA | 541e0fcecfa9 | 541e0fcecfa9 | 4d1c7b813e3e | Current promoted research profile status. |
| readme-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | FB74BA9D25BA | efcd07164c0d | efcd07164c0d |  | Human-facing repository dashboard. |
| github-status-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | 2FCCC677D472 | fbc6b3523528 | fbc6b3523528 |  | Compact GitHub-facing status board. |
| money-ready-refresh | False | INFO | OPTIONAL_NOT_VERIFIED | D2738FABCF11 | abab4feed912 | e65bfc4094ae |  | Latest one-command refresh status. |
| money-ready-scorecard | False | INFO | OPTIONAL_NOT_VERIFIED | 29649BA49145 | 679f4279db88 | 16cc89f039e6 |  | Money-ready scorecard. |
| live-readiness-decision | False | INFO | OPTIONAL_NOT_VERIFIED | B8E79FF9DAD0 | 33e32ce9de34 | b2dc41837625 |  | Final conservative live-readiness gate. |
| release-candidate-decision | False | INFO | OPTIONAL_NOT_VERIFIED | 99E130ABADC2 | 75817a370250 | 421bf4c59857 |  | Release-candidate gate. |
| first-pass-parallel-lanes | False | INFO | OPTIONAL_NOT_VERIFIED | AD0C3AB76D8B | eeb7d20cbcd3 | baf11654937e |  | Fast first-pass lane split. |
| github-required-artifact-sync-package | False | INFO | OPTIONAL_NOT_VERIFIED | 673A095DCE5C | b05026b2f432 | 2731874c7057 |  | Exact upload package for remaining required source/profile blockers. |
| evidence-handoff | False | INFO | OPTIONAL_NOT_VERIFIED | 4A1E1CD7AFA9 | 071e88ba0de2 | 15678175fb6b |  | Evidence handoff summary. |
