# Money-Ready Evidence Handoff

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Handoff folder: `outputs\money_ready_evidence_handoff`
- Zip: `outputs\money_ready_evidence_handoff.zip`
- First-pass configs: `8`
- First-pass parallel lanes: `4` lanes / `8` configs
- Full validation configs: `53`
- Broker-proxy configs: `10`
- Conservative profile hash: `621F54A4BFE61761577D87DB212CF024163F25066209C205090E72227FE584A6`
- Source hash: `44D9EBA868C86EB6C57DF82C3B94D83ACFE994B1A665917EC05AB8313188A5F7`

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

Run the `8` first-pass configs, export reports into `outputs\returned_mt5_reports\first_pass_inbox`, return compile proof into `outputs\returned_mt5_reports\compile_inbox`, then run `work\refresh_money_ready_status.ps1` locally.

Screenshots, balance-only logs, and log-only profit rows are not enough for the strict trade-ready gate.

Trade-log CSVs must include broad realized-R, spread, held-bars, and MFE/MAE coverage. Forward/demo and second-broker CSVs must include `ExpectedPayoff`, `SharpeRatio`, and `WinRatePercent`.
