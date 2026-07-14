# Range-Elite Failure Trade Diagnostic Analysis

Generated from MT5 Common Files trade logs copied into the package 	rade_logs folder. No MT5 process was launched by this analyzer.

- Package dir: `outputs\range_elite_failure_trade_diag_package`
- Expected logs: `8`
- Missing logs: `0`
- Closed trades parsed: `61`

## Window Summary

| Window | Role | Trades | Net | PF | Wins | Losses | Avg Spread | Trade Path DD |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2019_full | red_year | 3 | -83.32 | 0.00 | 0 | 3 | 28.00 | 83.32 |
| 2020_full | green_low_sample | 2 | 88.75 | 2.92 | 1 | 1 | 19.50 | 46.25 |
| 2021_full | red_year | 2 | -62.11 | 0.40 | 1 | 1 | 8.50 | 104.34 |
| 2022_full | near_flat_high_dd | 2 | 9.59 | 1.13 | 1 | 1 | 5.00 | 71.75 |
| 2023_full | red_year | 17 | -131.33 | 0.56 | 5 | 12 | 7.47 | 146.30 |
| 2024_full | profit_control | 21 | 2174.47 | 5.01 | 13 | 8 | 27.86 | 171.07 |
| 2025_full | green_low_sample | 3 | 214.30 | 4.96 | 2 | 1 | 14.33 | 54.05 |
| 2026_ytd | high_dd_recent | 11 | 742.92 | 1.93 | 8 | 3 | 10.82 | 673.40 |

## Lane Summary

| Window | Lane | Trades | Net | Wins | Losses | Avg Spread | Avg R |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2019_full | diagnostic_fallback | 3 | -83.32 | 0 | 3 | 28.00 | -7.17 |
| 2020_full | diagnostic_fallback | 2 | 88.75 | 1 | 1 | 19.50 | 4.70 |
| 2021_full | liquidity_sweep | 1 | 42.23 | 1 | 0 | 5.00 | 4.23 |
| 2021_full | sweep_plus_diagnostic | 1 | -104.34 | 0 | 1 | 12.00 | -10.06 |
| 2022_full | diagnostic_fallback | 2 | 9.59 | 1 | 1 | 5.00 | 0.78 |
| 2023_full | diagnostic_fallback | 13 | 7.33 | 5 | 8 | 7.31 | 2.11 |
| 2023_full | liquidity_sweep | 1 | -31.92 | 0 | 1 | 8.00 | -10.09 |
| 2023_full | sweep_plus_diagnostic | 3 | -106.74 | 0 | 3 | 8.00 | -7.78 |
| 2024_full | diagnostic_fallback | 15 | 2047.32 | 10 | 5 | 28.07 | 12.18 |
| 2024_full | liquidity_sweep | 2 | 213.75 | 1 | 1 | 24.00 | 7.91 |
| 2024_full | range_reversion_fmr | 1 | -104.14 | 0 | 1 | 15.00 | -8.06 |
| 2024_full | sweep_plus_diagnostic | 3 | 17.54 | 2 | 1 | 33.67 | 3.49 |
| 2025_full | diagnostic_fallback | 2 | -14.95 | 1 | 1 | 14.00 | -0.13 |
| 2025_full | sweep_plus_diagnostic | 1 | 229.25 | 1 | 0 | 15.00 | 22.25 |
| 2026_ytd | diagnostic_fallback | 11 | 742.92 | 8 | 3 | 10.82 | 8.99 |

## Worst Closed Trades

| Window | Time | Bias | Profit | R | Spread | Lane | Entry Reason | Close |
| --- | --- | --- | ---: | ---: | ---: | --- | --- | --- |
| 2026_ytd | 05/05/2026 16:00:00 | sell | -673.40 | -10.06 | 8.00 | diagnostic_fallback | Diagnostic trend fallback; | sl 4577.38 |
| 2024_full | 08/28/2024 08:00:00 | buy | -113.96 | -10.03 | 33.00 | sweep_plus_diagnostic | Liquidity sweep;Diagnostic trend fallback; | sl 2509.19 |
| 2026_ytd | 03/10/2026 07:30:00 | sell | -112.75 | -5.87 | 9.00 | diagnostic_fallback | Diagnostic trend fallback; | sl 5181.97 |
| 2021_full | 03/04/2021 07:15:00 | sell | -104.34 | -10.06 | 12.00 | sweep_plus_diagnostic | Liquidity sweep;Diagnostic trend fallback; | sl 1717.44 |
| 2024_full | 10/31/2024 14:00:00 | buy | -104.14 | -8.06 | 15.00 | range_reversion_fmr | Flat month micro reversion score 7;FMR liquidity;FMR rejection;FMR location extreme;FMR VWAP;Flat month micro reversion;Diagnostic trend fallback;Range reversion stop/target;Range reversion trade RR 0.97;Flat month opportunity x1.15; | sl 2777.06 |
| 2024_full | 05/08/2024 16:15:00 | sell | -88.27 | -1.27 | 10.00 | diagnostic_fallback | Diagnostic trend fallback; | sl 2313.66 |
| 2023_full | 05/03/2023 08:15:00 | buy | -79.38 | -10.13 | 8.00 | sweep_plus_diagnostic | Liquidity sweep;Diagnostic trend fallback; | sl 2014.64 |
| 2022_full | 03/04/2022 08:15:00 | buy | -71.75 | -6.68 | 5.00 | diagnostic_fallback | Diagnostic trend fallback; | sl 1934.89 |
| 2023_full | 03/03/2023 15:30:00 | buy | -66.92 | -6.90 | 8.00 | diagnostic_fallback | Diagnostic trend fallback; | sl 1844.40 |
| 2024_full | 08/21/2024 07:00:00 | buy | -58.95 | -5.74 | 33.00 | diagnostic_fallback | Diagnostic trend fallback; | sl 2513.69 |
| 2024_full | 08/06/2024 08:15:00 | buy | -54.90 | -10.02 | 33.00 | diagnostic_fallback | Diagnostic trend fallback; | sl 2404.80 |
| 2025_full | 03/05/2025 13:15:00 | buy | -54.05 | -4.38 | 13.00 | diagnostic_fallback | Diagnostic trend fallback; | sl 2912.12 |
