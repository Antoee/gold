# GitHub Publication Sync

Generated offline without launching MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Overall: **PASS**
- Repository: `Antoee/gold`
- Branch: `main`
- Required passing: `7`
- Required pending: `0`
- Required failed: `0`

Required source/profile/status artifacts match GitHub by SHA-256.

## Artifacts

| Role | Required | Status | Detail | Local SHA-256 | Local Raw Blob | Local Text Blob | Remote Git Blob | Note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| root-ea-source | True | PASS | CONNECTOR_TEXT_BLOB_MATCH | A167CDB787E0 | eb6b66d01249 | f04f12ea3b4a | f04f12ea3b4a | Exact root EA source required for reproducible publication. |
| mirrored-ea-source | True | PASS | CONNECTOR_TEXT_BLOB_MATCH | A167CDB787E0 | eb6b66d01249 | f04f12ea3b4a | f04f12ea3b4a | Mirrored output EA source required for hash identity. |
| trade-ready-conservative-profile | True | PASS | CONNECTOR_TEXT_BLOB_MATCH | 7AA4135B6FBA | 0815570cd1a1 | e2fb15a07701 | e2fb15a07701 | Conservative profile used by live-readiness gates. |
| money-ready-profile | True | PASS | CONNECTOR_TEXT_BLOB_MATCH | D0459197F2A8 | 4d08c8fb1f0d | 3fe8299255f9 | 3fe8299255f9 | Money-ready demo/forward-test candidate profile. |
| trade-readiness-alias-profile | True | PASS | CONNECTOR_TEXT_BLOB_MATCH | D0459197F2A8 | 4d08c8fb1f0d | 3fe8299255f9 | 3fe8299255f9 | Alias profile expected to match money-ready profile. |
| source-manifest | True | PASS | CONNECTOR_BLOB_MATCH | FCCD57903C96 | 7e923527303b | 7e923527303b | 7e923527303b | Source hash/status manifest. |
| current-research-best | True | PASS | CONNECTOR_BLOB_MATCH | 0244A5806C4A | 92d56427b1f6 | 92d56427b1f6 | 92d56427b1f6 | Current promoted research profile status. |
| readme-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | AE7EBA2BB247 | 8ebb471215f2 | 8ebb471215f2 |  | Human-facing repository dashboard. |
| github-status-dashboard | False | INFO | OPTIONAL_NOT_VERIFIED | 3F853CABD1F5 | ce5f72a562b3 | ce5f72a562b3 |  | Compact GitHub-facing status board. |
| money-ready-refresh | False | INFO | OPTIONAL_NOT_VERIFIED | 2DAD72C4D24D | f50b460e8293 | 3df08a616b06 |  | Latest one-command refresh status. |
| money-ready-scorecard | False | INFO | OPTIONAL_NOT_VERIFIED | 9845BF532247 | 866bb295416b | c2d1427f8ef5 |  | Money-ready scorecard. |
| live-readiness-decision | False | INFO | OPTIONAL_NOT_VERIFIED | DAFDF5BC18DD | e4c5610c7266 | fa976156be61 |  | Final conservative live-readiness gate. |
| release-candidate-decision | False | INFO | OPTIONAL_NOT_VERIFIED | 25A9F0E2C67E | 8c6be65e1854 | 9f9d3573250b |  | Release-candidate gate. |
| first-pass-parallel-lanes | False | INFO | OPTIONAL_NOT_VERIFIED | AD0C3AB76D8B | eeb7d20cbcd3 | baf11654937e |  | Fast first-pass lane split. |
| github-required-artifact-sync-package | False | INFO | OPTIONAL_NOT_VERIFIED | 1FEC231F76E2 | 797e0f6adbc7 | 1d34e8e78c97 |  | Exact upload package for remaining required source/profile blockers. |
| evidence-handoff | False | INFO | OPTIONAL_NOT_VERIFIED | AB3806A3FE1C | 5972e86c1264 | f7cdf63dffa7 |  | Evidence handoff summary. |
