# Range-Elite Failure Trade Diagnostic Package

Offline package builder only. This does not launch MT5.

- Source hash: `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`
- Base profile hash: `AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`
- Model: `4`
- Configs: `8`
- Package dir: `outputs\range_elite_failure_trade_diag_package`

## Diagnostic Windows

| Window | Role | From | To | Trade log |
| --- | --- | --- | --- | --- |
| 2019_full | red_year | 2019.01.01 | 2019.12.31 | PXEA_RANGE_ELITE_2019_m4_trades.csv |
| 2020_full | green_low_sample | 2020.01.01 | 2020.12.31 | PXEA_RANGE_ELITE_2020_m4_trades.csv |
| 2021_full | red_year | 2021.01.01 | 2021.12.31 | PXEA_RANGE_ELITE_2021_m4_trades.csv |
| 2022_full | near_flat_high_dd | 2022.01.01 | 2022.12.31 | PXEA_RANGE_ELITE_2022_m4_trades.csv |
| 2023_full | red_year | 2023.01.01 | 2023.12.31 | PXEA_RANGE_ELITE_2023_m4_trades.csv |
| 2024_full | profit_control | 2024.01.01 | 2024.12.31 | PXEA_RANGE_ELITE_2024_m4_trades.csv |
| 2025_full | green_low_sample | 2025.01.01 | 2025.12.31 | PXEA_RANGE_ELITE_2025_m4_trades.csv |
| 2026_ytd | high_dd_recent | 2026.01.01 | 2026.07.12 | PXEA_RANGE_ELITE_2026ytd_m4_trades.csv |

After the hidden run finishes, copy MT5 Common Files trade logs into `outputs\range_elite_failure_trade_diag_package\trade_logs` and run `work\summarize_range_elite_trade_diag_logs.ps1`.
