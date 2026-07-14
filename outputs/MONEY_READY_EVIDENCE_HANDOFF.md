# Money-Ready Evidence Handoff

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Handoff folder: `outputs\money_ready_evidence_handoff`
- Zip: `outputs\money_ready_evidence_handoff.zip`
- First-pass configs: `4`
- First-pass parallel lanes: `4` lanes / `4` configs
- Full validation configs: `53`
- Broker-proxy configs: `10`
- Profile hash: `82530801102198E81E08E1EF772D5501B52FB88CCFD67E6651CE32EF1D055665`
- Source hash: `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`

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

Run the `4` first-pass configs, export reports into `outputs\returned_mt5_reports\first_pass_inbox`, return compile proof into `outputs\returned_mt5_reports\compile_inbox`, then run `work\refresh_money_ready_status.ps1`.
You can use `FIRST_PASS_PARALLEL_LANES.csv` to run those same first-pass checks as window-based chunks.
Required exported MT5 report stats: net profit, profit factor, expected payoff, Sharpe ratio, profit trades (% of total) / win rate, total trades, maximal consecutive losses, balance/equity drawdown maximal with percent, and recovery factor.
Screenshots, balance-only logs, and log-only profit rows are not enough for the strict trade-ready gate.
Trade-log CSVs must include broad realized-R, spread, held-bars, and MFE/MAE coverage.
Forward/demo and second-broker CSVs must include `ExpectedPayoff`, `SharpeRatio`, and `WinRatePercent`.
