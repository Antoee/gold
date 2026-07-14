# Static Safety Audit Status

Generated offline. This does not launch MT5, MetaEditor, GitHub Actions, Git, or GitHub CLI.

- Overall: **PASS**
- Repository static safety audit: `STATIC_REPO_SAFETY_AUDIT_PASS`, `25` checks
- MQL compile preflight: `STATIC_MQL_COMPILE_PREFLIGHT_PASS`, `29` checks, `1802` inputs parsed
- Manual workflow trigger: `workflow_dispatch` only
- MT5 local safety audit: `PASS`, `43 / 43`
- Workflow PowerShell smoke set: `PASS`

## What Was Fixed

The manual `.github/workflows/static-safety.yml` workflow previously referenced two missing files:

- `work/static_repo_safety_audit.py`
- `work/static_mql_compile_preflight.py`

Both scripts now exist locally and pass. They are static/offline checks only:

- no MT5 launch
- no MetaEditor launch
- no Strategy Tester launch
- no GitHub Actions trigger beyond manual dispatch
- no Git or GitHub CLI dependency

## What The Checks Cover

`work/static_repo_safety_audit.py` verifies:

- the Static Safety workflow is manual-only
- required EA/source/profile/status artifacts exist
- source and mirrored source hashes match
- MT5 launch unlock files are absent
- the hard local launch lock is present
- the latest local MT5 safety audit has zero failed rows
- money-ready and live-readiness status files keep real-account trading locked/pending

`work/static_mql_compile_preflight.py` verifies:

- root and mirrored EA source hashes match
- key safety gate functions and calls exist
- real-account safety defaults remain locked
- the trade-environment guard runs before new entries
- OnInit calls the symbol, real-account, and trade-readiness gates
- MQL input declarations are parseable and unique
- MQL input identifiers are within the MetaEditor-safe length cap
- braces, brackets, and parentheses are balanced after stripping comments and strings
- initialization can fail closed with `INIT_PARAMETERS_INCORRECT`

## Latest Local Workflow Smoke Results

The following workflow-equivalent PowerShell checks passed locally:

- `REPORT_COLLECTOR_PARSER_SMOKE_PASS`
- `EXTERNAL_MT5_MICRO_DECISION_SMOKE_PASS`
- `RISK_ADJUSTED_MICRO_BATCH_SMOKE_PASS`
- `GENERATE_PROFIT_SEARCH_CONFIGS_SMOKE_PASS`
- `REPORT_IMPORT_PREFLIGHT_SMOKE_PASS`
- `OFFLINE_REFRESH_QUIET_MODE_SMOKE_PASS`
- `CI_RISK_ADJUSTED_HANDOFF_BOOTSTRAP_PASS`
- external MT5 validation package rebuilt with `20` configs
- handoff integrity audit: `20 / 20` pass
- external MT5 package audit: `26 / 26` pass
- MT5 local safety audit: `43 / 43` pass

This fixes the missing-script cause of the old Static Safety Audit failure, but it does not make the EA money-ready. The live-readiness gate still requires fresh compile proof, returned MT5 reports, trade logs, Monte Carlo evidence, forward/demo evidence, and second-broker evidence.
