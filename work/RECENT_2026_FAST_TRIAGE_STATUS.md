# Recent 2026 Fast-Triage Status

Generated locally without launching MT5.

## Local Change Summary

- Added `InpMaxStopATRMultiplier` to the canonical EA source locally and set the default to `3.00`.
- Added a pre-entry max-stop ATR guard locally: after final structure/broker stop sizing, the EA rejects entries where `stopDistance > signal.atr * InpMaxStopATRMultiplier` and records `max stop ATR` as the block reason.
- Pinned `InpMaxStopATRMultiplier=3.00` in the base profile and regenerated package configs so external tests do not rely on MT5 defaults.
- Added `work/test_max_stop_atr_guard.ps1` locally and wired it into report-import preflight/local pipeline manifest.
- Added `work/build_fully_pinned_research_retest_package.ps1` locally to generate a clean research retest package for old profitable clues without relying on cached MT5 inputs.
- Added `work/test_fully_pinned_research_retest_package.ps1` locally to verify the retest configs are non-visual, non-optimization, shutdown-after-run, fully pinned, and research-only where appropriate.
- Added `work/build_research_retest_decision.ps1` locally to compare fully pinned research retest reports against the current baseline profile.
- Added `work/test_research_retest_decision.ps1` locally to cover waiting, candidate loss, baseline underperformance, drawdown review, and advance cases.
- Added `work/build_parallel_micro_lanes.ps1` locally to split the 20-run risk-adjusted micro batch into independent recent-first lanes for faster feedback.
- Added `work/test_parallel_micro_lanes.ps1` locally to verify lane count, 20-run coverage, required profiles/windows, ordering, duplicate protection, and runtime bound.
- Added `work/build_parallel_micro_lane_decision.ps1` locally to make early pass/reject/wait decisions from partial lane report returns.
- Added `work/test_parallel_micro_lane_decision.ps1` locally to cover lane pass, candidate loss reject, same-window baseline underperformance reject, and waiting cases.
- Wired the research retest package, report collector, decision gate, parallel micro lanes, lane decision gate, max-stop ATR smoke coverage, report-import preflight, and local pipeline manifest into the offline refresh.
- Kept local MT5 launch hard-locked. The hidden quiet-shield watchdog remains cleanup-only and does not launch MT5.

## Current Local Evidence

- Canonical EA source SHA-256: `EE33CFE52D09B8C2932DC6F7B824977116C29CFC8B367E0E44218CD171DBB338`.
- Main profit-search profiles: 20.
- Main profit-search manifest: 279 configs total.
- Main micro batch: 20 runs.
- Parallel micro lanes: 4 lanes, 20 configs total, estimated 6.58 tester minutes before platform overhead.
- Parallel micro lane order: `2026_Q2=5`, `2026_ytd=5`, `2024_Q1=5`, `2025_Q2=5`.
- Parallel micro lane decisions: 16 candidate lane decisions, all `WAITING_FOR_REPORTS`.
- Parallel micro lanes zip SHA-256: `78AF9104F693847BEA98157D32BE71964E93323B55D3F7DD5D575B3D19BA64C5`.
- Fully pinned research retest package: 3 profiles, 18 configs.
- Research retest profiles: `baseline_promoted`, `buyblock2_dd4`, `sweep_only_dd4`.
- Research retest metrics: 18 expected rows, 0 parsed, 18 missing, 0 unparsed.
- Research retest decision rows: 12 candidate windows, all `WAITING_FOR_REPORTS`.
- Research retest zip SHA-256: `66B3676D69BAB992A93286CCB47C9FF3B49273C32F743BA613CFC5DD9B54E451`.
- Local pipeline manifest: 41 tracked artifacts, 0 missing.
- Legacy evidence pin audit: 4 evidence sets checked, 4 pin-incomplete.
- External MT5 validation package zip SHA-256: `5233E149D515FB2171781C05CFE56B6200EC1357BC7379ED66D2A1C78C2AFC8A`.
- Risk-adjusted micro handoff zip SHA-256: `1496459CC876738DDC0B9C83E9E5BD84ADB890CD82F6C540D5C5865109F38C35`.

## Verification

- `work/test_max_stop_atr_guard.ps1`: `MAX_STOP_ATR_GUARD_SMOKE_PASS`.
- `work/test_ea_source_artifact_sync.ps1`: `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`.
- `work/test_generate_profit_search_configs.ps1`: `GENERATE_PROFIT_SEARCH_CONFIGS_SMOKE_PASS`.
- `work/test_fully_pinned_research_retest_package.ps1`: `FULLY_PINNED_RESEARCH_RETEST_PACKAGE_SMOKE_PASS`.
- `work/test_research_retest_decision.ps1`: `RESEARCH_RETEST_DECISION_SMOKE_PASS`.
- `work/test_parallel_micro_lanes.ps1`: `PARALLEL_MICRO_LANES_SMOKE_PASS`.
- `work/test_parallel_micro_lane_decision.ps1`: `PARALLEL_MICRO_LANE_DECISION_SMOKE_PASS`.
- `work/refresh_offline_validation_state.ps1`: PASS, 26 steps, 0 failed.
- `outputs/REPORT_IMPORT_PREFLIGHT.csv`: max stop ATR guard smoke PASS; parallel micro lane decision smoke PASS; parallel micro lane decision `WAITING_FOR_REPORTS`; parallel micro lanes PASS; research retest decision smoke PASS; fully pinned research retest `READY_RESEARCH`; research retest metrics `WAITING_FOR_REPORTS`; research retest decision `WAITING_FOR_REPORTS`; local pipeline manifest PASS; local safety PASS; external micro decision `COMPILE_REQUIRED`.
- `outputs/LOCAL_PIPELINE_MANIFEST.csv`: PASS, 41 artifacts, 0 missing.
- `outputs/parallel_micro_lanes/LANE_MANIFEST.csv`: 4 lanes.
- `outputs/parallel_micro_lanes/LANE_RUN_MANIFEST.csv`: 20 runs.
- `outputs/PARALLEL_MICRO_LANE_DECISION.csv`: 16 rows, `WAITING_FOR_REPORTS=16`.
- `outputs/RESEARCH_RETEST_REPORT_METRICS.csv`: 18 rows, 0 parsed, 18 missing, 0 unparsed.
- `outputs/RESEARCH_RETEST_DECISION.csv`: 12 rows, `WAITING_FOR_REPORTS=12`.
- Final local process scan: `NO_MT5_OR_METAEDITOR_PROCESSES_FOUND`.

## Important Caveat

The local generated scripts and outputs are updated in the workspace. This status note records the change on GitHub; the larger source/script files still need a normal git push or connector full-file update to fully synchronize the repository.

Compile proof is now stale because the canonical EA source changed. Before trusting new MT5 reports, compile the exact packaged source with hash `EE33CFE52D09B8C2932DC6F7B824977116C29CFC8B367E0E44218CD171DBB338` and import the compile log.

No profit is proven by this update. The micro and research retest reports are still missing, so the current promoted profile remains unchanged until fresh external MT5 reports are returned and pass the gates.
