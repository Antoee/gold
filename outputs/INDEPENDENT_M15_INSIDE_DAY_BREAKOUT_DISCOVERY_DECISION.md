# Independent M15 Inside-Day Breakout Decision

Decision date: 2026-07-19

**Verdict: rejected during frozen Model 1 discovery. No 2021-2026 holdout was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Test Contract

The standalone EA used only completed D1 bars to identify an inside-day compression, then required a fresh M15 close outside that range with body and optional tick-volume confirmation. It used an H4 EMA direction/slope regime, optional H1 ADX, a recent-M15 structure stop capped at `$8`, fixed-R exits, broker-native `OrderCalcProfit` sizing, and one trade per day.

- Source: `work/Independent_XAUUSD_M15_Inside_Day_Breakout.mq5`
- Source SHA-256: `534D767F2B04A0ADB3ECC6C121CAEF6A3FB26652ACFE26C64EA45F146E67B427`
- Compile: `0 errors, 0 warnings`
- Discovery data only: 2015-01-01 through 2020-12-31
- Identity-valid reports: `42 / 42`
- Candidate variants: `14`
- Risk per accepted trade: `0.10%` on `$10,000`
- Post-2020 configurations: `0`
- Model 4 configurations: `0`

One continuous row hit a source-identity startup race and was rejected. The exact unchanged configuration reproduced on the alternate healthy runtime; the canonical run contains one valid report for every frozen queue row.

## Discovery Evidence

Every variant lost in 2019-2020. No continuous PF reached the frozen `1.20` floor and no profile reached the 60-trade activity floor.

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | PF | Trades | DD | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `idb_tp150` | `+$34.83` | `1.42` | `20` | `-$22.04` | `0.39` | `5` | `+$12.79` | `1.11` | `25` | `0.61%` | rejected |
| `idb_vol115` | `+$8.49` | `1.10` | `17` | `-$26.08` | `0.00` | `3` | `-$17.59` | `0.84` | `20` | `0.57%` | rejected |
| `idb_buffer010` | `+$0.13` | `1.00` | `19` | `-$25.34` | `0.03` | `4` | `-$25.21` | `0.79` | `23` | `0.82%` | rejected |
| `idb_vol000` | `-$18.64` | `0.87` | `27` | `-$8.93` | `0.80` | `8` | `-$27.57` | `0.86` | `35` | `1.36%` | rejected |
| `idb_noema` | `+$33.41` | `1.19` | `37` | `-$60.99` | `0.24` | `11` | `-$28.69` | `0.89` | `48` | `0.83%` | rejected |
| `idb_buffer000` | `-$1.26` | `0.99` | `19` | `-$34.94` | `0.03` | `5` | `-$36.20` | `0.72` | `24` | `0.93%` | rejected |
| `idb_ratio065` | `-$0.82` | `0.99` | `18` | `-$35.84` | `0.00` | `4` | `-$36.66` | `0.71` | `22` | `0.94%` | rejected |
| `idb_tp250` | `-$5.34` | `0.95` | `20` | `-$34.94` | `0.03` | `5` | `-$40.28` | `0.71` | `25` | `1.05%` | rejected |
| `idb_body30` | `-$25.59` | `0.78` | `22` | `-$16.57` | `0.54` | `6` | `-$42.16` | `0.73` | `28` | `1.05%` | rejected |
| `idb_center` | `-$9.89` | `0.90` | `20` | `-$34.94` | `0.03` | `5` | `-$44.83` | `0.67` | `25` | `1.02%` | rejected |
| `idb_adx16` | `-$9.89` | `0.90` | `20` | `-$34.94` | `0.03` | `5` | `-$44.83` | `0.67` | `25` | `1.02%` | rejected |
| `idb_minratio015` | `-$16.27` | `0.85` | `21` | `-$34.94` | `0.03` | `5` | `-$51.21` | `0.65` | `26` | `1.08%` | rejected |
| `idb_ratio085` | `-$9.89` | `0.90` | `20` | `-$59.40` | `0.01` | `8` | `-$69.29` | `0.57` | `28` | `1.26%` | rejected |
| `idb_body50` | `-$63.19` | `0.36` | `17` | `-$34.94` | `0.03` | `5` | `-$98.13` | `0.27` | `22` | `1.23%` | rejected |

The diagnostics show zero minimum-lot rejects, zero exposure rejects, and zero order failures. Many breakout signals were rejected because the tight `$8` structure-stop contract could not be honored, but even the no-EMA and no-volume activity neighbors had negative continuous expectancy and lost in 2019-2020. The failure therefore cannot be classified as tester or broker-minimum starvation.

## Decision

- Reject the completed-D1 inside-day breakout family before recent data.
- Do not widen stops or retune compression/body/volume thresholds against the observed losses.
- Skip Model 4, annual, cost, and Monte Carlo testing because the fast broad-era gate failed.
- Keep RC2 ATB150 unchanged as the historical best.
- Preserve the frozen forward registration, invalid-account boundary, evidence logs, and hard real-account lock.

## Evidence

- `outputs/INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_MODEL1_SUMMARY.csv`
- `outputs/INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_MODEL1_RUN.csv`
- `outputs/INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_DECISION.csv`
- `outputs/INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_COMPILE.log`
