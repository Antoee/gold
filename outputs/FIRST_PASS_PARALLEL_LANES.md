# First-Pass Parallel Lanes

Offline package only. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Lane folder: `outputs\first_pass_parallel_lanes`
- Lanes: `4`
- Configs: `8`
- Source package manifest: `outputs\FIRST_PASS_NEXT_RUN_PACKAGE_MANIFEST.csv`

Each lane groups both candidate configs for one window. Different lanes can be run independently later, while returned reports still flow into the normal first-pass inbox and importer.

| Lane | Window | Configs | Candidates | Return Inbox |
| --- | --- | ---: | --- | --- |
| lane_01_2024_full | 2024_full | 2 | money_ready;trade_ready_conservative | outputs\returned_mt5_reports\first_pass_inbox |
| lane_02_2025_full | 2025_full | 2 | money_ready;trade_ready_conservative | outputs\returned_mt5_reports\first_pass_inbox |
| lane_03_2026_ytd | 2026_ytd | 2 | money_ready;trade_ready_conservative | outputs\returned_mt5_reports\first_pass_inbox |
| lane_04_continuous_2024_2026 | continuous_2024_2026 | 2 | money_ready;trade_ready_conservative | outputs\returned_mt5_reports\first_pass_inbox |
