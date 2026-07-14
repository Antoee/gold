# Money-Ready Evidence Handoff

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Handoff folder: `outputs\money_ready_evidence_handoff`
- Zip: `outputs\money_ready_evidence_handoff.zip`
- First-pass configs: `0`
- First-pass parallel lanes: `0` lanes / `0` configs
- Full validation configs: `53`
- Broker-proxy configs: `10`
- Profile hash: `F708C68A68016C13C4ADAECFE472A270748F4DAD9F2DF8C12F9870C2324DA13F`
- Source hash: `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`

## Contents

- `README.md`
- `FIRST_PASS_RUN_LIST.csv`
- `FIRST_PASS_PARALLEL_LANES.csv`
- `FIRST_PASS_PARALLEL_RUN_LIST.csv`
- `FULL_VALIDATION_RUN_LIST.csv`
- `COMPILE_EVIDENCE_FILES.csv`
- `LIVE_EVIDENCE_FILES.csv`
- `templates/TRADE_READY_CONSERVATIVE_TRADE_LOG_TEMPLATE.csv`
- `templates/TRADE_READY_CONSERVATIVE_FORWARD_TEST_EVIDENCE_TEMPLATE.csv`
- `templates/TRADE_READY_CONSERVATIVE_SECOND_BROKER_EVIDENCE_TEMPLATE.csv`

## Next Step

Run the `0` first-pass configs, export reports into `outputs\returned_mt5_reports\first_pass_inbox`, then run `work\advance_first_pass_after_report.ps1` and open `outputs\FIRST_PASS_ADVANCE_STATUS.md`.
Return compile proof into `outputs\returned_mt5_reports\compile_inbox`; `work\refresh_money_ready_status.ps1` remains the broader all-gates refresh.
You can use `FIRST_PASS_PARALLEL_LANES.csv` to run those same first-pass checks as window-based chunks.
For local hidden execution, use `work\run_first_pass_package_hidden.ps1` in plan mode first; `-Run` is guarded by the workspace MT5 unlock policy.
First-pass efficiency floors: fast Model1 continuous must clear annualized return >= 8% and return/DD >= 1.5; exact real-tick continuous must clear annualized return >= 12%, CAGR >= 10%, return/DD >= 3.0, worst parsed DD <= 6%, PF >= 1.20, and recovery >= 1.25.
Required exported MT5 report stats: net profit, profit factor, expected payoff, Sharpe ratio, profit trades (% of total) / win rate, total trades, maximal consecutive losses, balance/equity drawdown maximal with percent, and recovery factor.
Screenshots, balance-only logs, and log-only profit rows are not enough for the strict trade-ready gate.
Trade-log CSVs must include broad realized-R, spread, held-bars, and MFE/MAE coverage.
Forward/demo and second-broker CSVs must include `ExpectedPayoff`, `SharpeRatio`, and `WinRatePercent`.
