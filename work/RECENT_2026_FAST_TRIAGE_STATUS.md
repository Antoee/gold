# Recent 2026 Fast-Triage Status

Generated locally without launching MT5.

## Local Change Summary

- Added `InpMaxStopATRMultiplier` to the canonical EA source locally and set the default to `3.00`.
- Added a pre-entry max-stop ATR guard locally: after final structure/broker stop sizing, the EA rejects entries where `stopDistance > signal.atr * InpMaxStopATRMultiplier` and records `max stop ATR` as the block reason.
- Added `InpMaxTradesPerDay` to the canonical EA source locally and set the default/base profile value to `4`.
- Added a risk-manager daily trade-frequency circuit breaker locally: the EA counts current-day entry deals for the same symbol/magic and rejects new entries with `daily trade limit` after the configured cap.
- Added `InpMaxDailyLossCount` to the canonical EA source locally and set the default/base profile value to `2`.
- Added a risk-manager daily loss-count circuit breaker locally: the EA counts current-day losing exit deals for the same symbol/magic and rejects new entries with `daily loss count limit` after the configured cap.
- Pinned `InpMaxStopATRMultiplier=3.00`, `InpMaxTradesPerDay=4`, and `InpMaxDailyLossCount=2` in the base profile and regenerated package configs so external tests do not rely on MT5 defaults.
- Added two phase-1-only profit-search variants: `maxstop25_dd4` with `InpMaxStopATRMultiplier=2.50`, and `maxstop20_dd4` with `InpMaxStopATRMultiplier=2.00`.
- Added `work/build_max_stop_probe_batch.ps1` locally to create a short external handoff batch focused on the max-stop variants.
- Added `work/test_max_stop_probe_batch.ps1` locally to smoke-test the probe rows, phase/model settings, guard values, config paths, and estimated runtime.
- Added `work/test_daily_trade_limit_guard.ps1` locally to verify the EA and base profile pin the daily trade-frequency circuit breaker.
- Added `work/test_daily_loss_count_guard.ps1` locally to verify the EA and base profile pin the daily loss-count circuit breaker.
- Added `work/audit_mt5_autostart_sources.ps1` locally to read-only check Windows Startup folders, Registry Run/RunOnce keys, Scheduled Tasks, and Services for MT5/MetaEditor autostart sources.
- Added `work/test_mt5_autostart_source_audit.ps1` locally to verify the autostart audit covers all four source areas and does not launch MT5.
- Updated `work/audit_handoff_config_integrity.ps1` locally so handoff integrity checks require `InpMaxStopATRMultiplier` in packaged configs.
- Wired the daily trade limit smoke, daily loss-count smoke, max-stop probe handoff, autostart audit, integrity audit, report-import preflight, and local pipeline manifest into the offline refresh.
- Kept local MT5 launch hard-locked. Quiet no-resident-helper mode is active: the stop marker is present and no watchdog process should be running.

## Current Local Evidence

- Canonical EA source SHA-256: `8D46F98E9855727AB8B97FED35D08A5B3C62D62FEFBF30F6E40EB6F9D30469E7`.
- Root EA source SHA-256: `8D46F98E9855727AB8B97FED35D08A5B3C62D62FEFBF30F6E40EB6F9D30469E7`.
- Packaged EA source SHA-256: `8D46F98E9855727AB8B97FED35D08A5B3C62D62FEFBF30F6E40EB6F9D30469E7`.
- Generated handoff `.ini` configs checked for `InpMaxTradesPerDay`: 56 files, 0 missing.
- Generated handoff `.ini` configs checked for `InpMaxDailyLossCount`: 56 files, 0 missing.
- Main profit-search profiles: 22.
- Main profit-search manifest: 297 configs total.
- Phase-1 fast-triage configs: 198.
- Phase-2 real-tick configs: 99.
- Max-stop profiles: `maxstop25_dd4` score 93 at max stop 2.50 ATR; `maxstop20_dd4` score 93 at max stop 2.00 ATR.
- Main micro batch: 20 runs.
- Max-stop probe handoff: 16 runs across `baseline_promoted`, `baseline_dd4`, `maxstop25_dd4`, and `maxstop20_dd4` on `2026_Q2`, `2026_ytd`, `2024_Q1`, and `2025_Q2`.
- Max-stop probe estimated runtime: 5.27 tester minutes before platform overhead.
- Max-stop probe integrity: 16 checked, 16 passed, 0 failed.
- Fully pinned research retest package: 3 profiles, 18 configs.
- Research retest metrics: 18 expected rows, 0 parsed, 18 missing, 0 unparsed.
- Research retest decision rows: 12 candidate windows, all `WAITING_FOR_REPORTS`.
- Parallel micro lanes: 4 lanes, 20 configs total, estimated 6.58 tester minutes before platform overhead.
- Parallel micro lane decisions: 16 candidate lane decisions, all `WAITING_FOR_REPORTS`.
- MT5 autostart source audit: PASS, 4 source areas checked, 0 MT5/MetaEditor matches.
- Local pipeline manifest: 51 tracked artifacts, 0 missing.
- Quiet stop marker present: `work/STOP_MT5_FOCUS_WATCHDOG`.
- Resident watchdog state: intentionally stopped; no resident helper should be active.
- External MT5 validation package zip SHA-256: `F267F7309153392A6F324998AB0E71B1F8C468E37A12D2220F89091F1786D9E4`.
- Risk-adjusted micro handoff zip SHA-256: `FD18B153B22C5833F64E4FE7DE6BD2F4FF345BD5C30D256FEAE194FEB553FA8D`.
- Max-stop probe handoff zip SHA-256: `5C9AAC254A451B78276424E14607D92612521AB39F136BDF14DAB807D435657F`.
- Parallel micro lanes zip SHA-256: `5AF9C9C823DA1F6327B8C009E86A97B5BB326911D60EA9AA03B3C44F71C4FF00`.
- Research retest zip SHA-256: `E5AB410F46D580769CD7D674F6D5C5299BB644AB8A00502117481ACD89A0A826`.
- Daily trade limit guard smoke SHA-256: `8F163BC67BC44DF8B37CD9537BADE4E10C6CC6CE28D50F333804924F9BEDA3C2`.
- Daily loss-count guard smoke SHA-256: `E0A0CF29C4D655D88A30499B3E985B9D400B3D5B1714F6BA2CAA44B5FE826D2B`.

## Verification

- `work/test_daily_loss_count_guard.ps1`: `DAILY_LOSS_COUNT_GUARD_SMOKE_PASS`.
- `work/test_daily_trade_limit_guard.ps1`: `DAILY_TRADE_LIMIT_GUARD_SMOKE_PASS`.
- `work/test_max_stop_atr_guard.ps1`: `MAX_STOP_ATR_GUARD_SMOKE_PASS`.
- `work/test_max_stop_probe_batch.ps1`: `MAX_STOP_PROBE_BATCH_SMOKE_PASS`.
- `work/test_mt5_autostart_source_audit.ps1`: `MT5_AUTOSTART_SOURCE_AUDIT_SMOKE_PASS`.
- `work/audit_mt5_autostart_sources.ps1`: PASS, 4 source areas checked, 0 MT5/MetaEditor matches.
- `work/sync_ea_source_artifacts.ps1`: PASS, 3 artifacts, hash `8D46F98E9855727AB8B97FED35D08A5B3C62D62FEFBF30F6E40EB6F9D30469E7`.
- `work/test_ea_source_artifact_sync.ps1`: `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`.
- `work/test_generate_profit_search_configs.ps1`: `GENERATE_PROFIT_SEARCH_CONFIGS_SMOKE_PASS`.
- `work/test_risk_adjusted_micro_batch_frontier.ps1`: `RISK_ADJUSTED_MICRO_BATCH_FRONTIER_SMOKE_PASS`.
- `work/test_fully_pinned_research_retest_package.ps1`: `FULLY_PINNED_RESEARCH_RETEST_PACKAGE_SMOKE_PASS`.
- `work/test_research_retest_decision.ps1`: `RESEARCH_RETEST_DECISION_SMOKE_PASS`.
- `work/test_parallel_micro_lanes.ps1`: `PARALLEL_MICRO_LANES_SMOKE_PASS`.
- `work/test_parallel_micro_lane_decision.ps1`: `PARALLEL_MICRO_LANE_DECISION_SMOKE_PASS`.
- `work/refresh_offline_validation_state.ps1`: PASS, 30 steps, 0 failed.
- `outputs/REPORT_IMPORT_PREFLIGHT.csv`: daily loss-count smoke PASS; daily trade limit smoke PASS; autostart audit smoke PASS; MT5 autostart sources PASS; max-stop probe smoke PASS; manifest PASS with 297 expected configs; imported metrics `WAITING_FOR_REPORTS`; max-stop probe handoff PASS; optimization guardrails TRACKED; local pipeline manifest PASS; local safety PASS; external micro decision `COMPILE_REQUIRED`.
- `outputs/MT5_AUTOSTART_SOURCE_AUDIT.csv`: Startup folders false, Registry Run keys false, Scheduled tasks false, Services false.
- `outputs/MAX_STOP_PROBE_BATCH.csv`: 16 rows.
- `outputs/MAX_STOP_PROBE_HANDOFF_INTEGRITY.csv`: 16 rows, 0 failures.
- `outputs/LOCAL_PIPELINE_MANIFEST.csv`: PASS, 51 artifacts, 0 missing.
- `outputs/parallel_micro_lanes/LANE_MANIFEST.csv`: 4 lanes.
- `outputs/parallel_micro_lanes/LANE_RUN_MANIFEST.csv`: 20 runs.
- `outputs/PARALLEL_MICRO_LANE_DECISION.csv`: 16 rows, `WAITING_FOR_REPORTS=16`.
- `outputs/RESEARCH_RETEST_REPORT_METRICS.csv`: 18 rows, 0 parsed, 18 missing, 0 unparsed.
- `outputs/RESEARCH_RETEST_DECISION.csv`: 12 rows, `WAITING_FOR_REPORTS=12`.
- `work/audit_mt5_local_safety.ps1`: PASS, 39 checks, 0 failed.
- Final local process scan before this status update: `NO_MT5_OR_METAEDITOR_PROCESSES_FOUND`.

## Important Caveat

The local generated scripts and outputs are updated in the workspace. This status note records the change on GitHub; the larger source/script files still need a normal git push or connector full-file update to fully synchronize the repository.

Compile proof is stale because the canonical EA source changed. Before trusting new MT5 reports, compile the exact packaged source with hash `8D46F98E9855727AB8B97FED35D08A5B3C62D62FEFBF30F6E40EB6F9D30469E7` and import the compile log.

No profit is proven by this update. The micro, max-stop probe, max-stop variant, and research retest reports are still missing, so the current promoted profile remains unchanged until fresh external MT5 reports are returned and pass the gates.

The autostart audit did not find a standard Windows autostart source for the reported pop-up. If a window still appears, it is likely from a manual shortcut, broker updater, already-running external app, or a non-standard launcher path outside the audited sources.
