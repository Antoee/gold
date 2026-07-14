# Money-Ready Proof Runway

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Release status: `PENDING`
- Money-ready scorecard status: `PENDING`
- Live-readiness status: `PENDING`
- First-pass next package rows: `0`
- First-pass parallel lanes: `0` lanes / `0` configs
- First-pass hidden runner: `empty` (`0` rows)

## Next Action

The current first-pass candidate failed the fast Model1 screen. Do not run the stale first-pass package; it has been cleared. The next useful tester work is building a new candidate/profile or relaxing/reworking the strategy logic, then rebuilding the first-pass queue.

## Runway

| Priority | Step | Status | Evidence Needed | Package/Input | Expected Return Path | Consumer Script | Unlocks | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Replace failed first-pass candidate | FAILED | The current first-pass candidate failed the fast Model1 screen; create or select a new candidate profile before spending more tester time. Current parsed status: parsedReports=0; parsedLogs=1; missing=21; unparsed=0; expected=22; parallel lanes: 0 lanes / 0 configs | outputs\first_pass_next_run_package or outputs\first_pass_parallel_lanes; optional plan/run helper: work\run_first_pass_package_hidden.ps1; after export use work\advance_first_pass_after_report.ps1 | outputs\returned_mt5_reports\first_pass_inbox\<ExpectedReportName>.htm/.html/.xml, then routed to outputs\first_pass_validation_queue\<candidate>\reports_here\ | work\run_first_pass_package_hidden.ps1; work\advance_first_pass_after_report.ps1; work\route_first_pass_returned_reports.ps1; work\refresh_first_pass_validation_state.ps1 | Trusted first-pass promotion or rejection before spending full Model4 time | Next package manifest rows=0; candidates=; parallelLanesReady=False; hiddenRunner=empty; hiddenRunnerRows=0 |
| 2 | Import fresh current-source compile proof | PENDING | MetaEditor compile proof for current source hash with 0 errors and 0 warnings | Professional_XAUUSD_EA.mq5 + outputs\Professional_XAUUSD_EA.mq5 | outputs\MT5_COMPILE_STATUS.csv | work\import_mt5_compile_log.ps1; work\analyze_trade_ready_live_readiness.ps1 | Clears live:current-source-compile | Current live-readiness compile proof is stale until the compile hash equals the current source hash. |
| 3 | Run conservative full validation only after first-pass passes | WAITING_ON_FIRST_PASS | 53 conservative validation reports plus 10 broker-proxy reports with full parsed tester stats. Exported MT5 reports must include net profit, profit factor, expected payoff, Sharpe ratio, profit trades (% of total) / win rate, total trades, maximal consecutive losses, balance/equity drawdown maximal with percent, and recovery factor. The exact continuous real-tick conservative run must have at least 20 trades. | outputs\trade_ready_conservative_validation_package + outputs\trade_ready_conservative_broker_proxy_package | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | work\import_trade_ready_conservative_validation_reports.ps1 | Clears model4-validation and quality return/drawdown/PF/recovery gates | Conservative validation decision rows=28; pass=3; pending=25; fail=0 |
| 4 | Return conservative closed-trade/deal logs | PENDING | Closed trade logs with profile_id, source_hash, run_label, realized R, held bars, spread/MFE/MAE when available | EA trade/deal log export from conservative profile runs | outputs\trade_ready_conservative_trade_logs\*.csv | work\analyze_trade_ready_conservative_trade_quality.ps1; work\analyze_trade_ready_conservative_monte_carlo.ps1 | Clears trade-quality and Monte Carlo stress gates | Monte Carlo cannot be meaningful until realized-R trade rows exist. |
| 5 | Return forward paper/demo evidence | PENDING | Forward/demo performance evidence with enough calendar days, trades, non-red net profit, PF floor, expected-payoff floor, Sharpe floor, win-rate floor, drawdown cap, loss-streak cap, and matching hashes | Paper/demo account export | outputs\TRADE_READY_CONSERVATIVE_FORWARD_TEST_EVIDENCE.csv | work\analyze_trade_ready_conservative_forward_test.ps1 | Clears forward-paper-demo gate | This is separate from backtesting and should remain unseen by optimization. |
| 6 | Return second-broker XAUUSD evidence | PENDING | Evidence from a non-primary broker/symbol specification with acceptable profit, PF, expected payoff, Sharpe, win rate, drawdown, loss-streak, and identity checks | Second broker tester/demo export | outputs\TRADE_READY_CONSERVATIVE_SECOND_BROKER_EVIDENCE.csv | work\analyze_trade_ready_conservative_second_broker.ps1 | Clears second-broker-validation gate | Gold contract specs vary a lot; this gate is intentionally separate. |
| 7 | Restore reproducible source sync | PENDING | Valid source/profile reproducibility path with matching hashes; local .git is currently not valid, so connector/raw publication audit must prove exact source/profile hashes | .git or connector-based source publication plus outputs\GITHUB_PUBLICATION_SYNC.md | outputs\GITHUB_PUBLICATION_SYNC.csv; outputs\SOURCE_MANIFEST.md plus release/source hashes | work\analyze_trade_ready_live_readiness.ps1; work\build_trade_ready_release_candidate.ps1 | Clears reproducible-github-sync and release review reproducibility | Do not use GitHub Actions for heavy tester work; keep runs local. If raw GitHub files are inaccessible, keep this gate pending until connector-published source/profile hashes are independently verified. |
| 8 | Regenerate final gates after evidence import | WAITING_ON_EVIDENCE | Release=PENDING; scorecard=PENDING; live=PENDING | All returned evidence above | outputs\MONEY_READY_STATUS_SCORECARD.md; outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.md | work\build_money_ready_status_scorecard.ps1; work\build_trade_ready_release_candidate.ps1 | Allows manual live-review profile only if all gates pass and explicit approval identity matches | A live-review profile should not exist while this row is waiting. |

## First-Pass Configs To Run

No next-run manifest rows found.
