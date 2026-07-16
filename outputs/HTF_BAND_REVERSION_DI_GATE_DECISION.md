# H1 Band/VWAP DI Gate Decision

Date: 2026-07-16

Decision: **retain the DI-edge gate as a validated research refinement, but do not promote it into the maintained EA or any money-ready profile.**

The filter improved the independent H1 reversion lane under both fast and real-tick modeling, but both surviving thresholds still had two losing active years. Exact four-stream portfolio screens also returned zero eligible rows. The maintained A167 source and maintained money-ready profile remain unchanged.

## Hypothesis

An exact 41-trade feature reproduction logged 17 date-independent setup features. It reproduced the original Model4 result at `+$440.63`, PF `2.36`, `41` trades, and `1.10%` drawdown with an identical trade CSV hash.

The one-factor analyzer screened `86` fixed gates. No offline gate passed every diagnostic requirement. Directional imbalance was selected for a predeclared MT5 neighborhood because it had an economic interpretation: reject a countertrend reversion when `+DI/-DI` imbalance is still excessively adverse to the intended reversal.

Predeclared thresholds: gate off, `DI edge >= -12`, `>= -10`, and `>= -8`. No calendar, year, month, or hour condition was introduced.

## Frozen Experiment

Experimental source:

`outputs/htf_band_reversion_di_gate_model4_package/source/Professional_XAUUSD_EA.mq5`

Source SHA-256:

`14EE0C5D87597435CD709E4D8831D506705C105B148CAAD42D442BB8F1B9DF56`

Continuous Model4 `DI >= -12` profile SHA-256:

`AAF4AA067850F8510B47EAA3FA2E7B25DFE88E4A02FD69811A1B58D68911442E`

Continuous Model4 `DI >= -10` profile SHA-256:

`038DA9446A2761E1595F6479BB9430CFA09C9F3222C303D7C8EA38A9D8FE449F`

The new inputs are independently controlled and default off:

- `InpBandVWAPReversionUseDIEdgeGate=false`
- `InpBandVWAPReversionMinDIEdge=-10.0`

## Broad Model1 Screen

All `16 / 16` exported reports parsed.

| Candidate | Continuous net | PF | Trades | DD | Older | Middle | Recent |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Gate off | `+$391.76` | `2.05` | `45` | `1.25%` | `+$66.99` | `+$144.38` | `+$184.66` |
| `DI >= -12` | `+$456.90` | `2.57` | `38` | `1.12%` | `+$87.59` | `+$171.00` | `+$202.58` |
| `DI >= -10` | `+$424.82` | `3.13` | `30` | `1.06%` | `+$96.39` | `+$201.12` | `+$131.58` |
| `DI >= -8` | `+$286.65` | `2.86` | `23` | `1.08%` | `+$38.62` | `+$120.72` | `+$131.58` |

`-12` and `-10` formed the useful neighboring plateau. `-8` was rejected before Model4 because it lost too much activity and net profit.

## Continuous Model4

All `3 / 3` exported real-tick reports parsed. The gate-off control exactly reproduced the prior result.

| Candidate | Net | Total return | Annualized | CAGR | PF | Trades | DD | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Gate off | `+$440.63` | `4.41%` | `0.38%/yr` | `0.37%` | `2.36` | `41` | `1.10%` | `3.95` |
| `DI >= -12` | `+$478.86` | `4.79%` | `0.42%/yr` | `0.41%` | `2.77` | `36` | `1.14%` | `4.15` |
| `DI >= -10` | `+$447.23` | `4.47%` | `0.39%/yr` | `0.38%` | `3.51` | `28` | `1.06%` | `4.03` |

Both gates improved quality, but the absolute return remained too small for a standalone money-ready strategy.

## Yearly Model4 Gate

All `24 / 24` exported real-tick reports parsed.

| Year | `DI >= -12` | Trades | `DI >= -10` | Trades |
| --- | ---: | ---: | ---: | ---: |
| 2015 | `+$31.05` | `2` | `+$31.05` | `2` |
| 2016 | `$0.00` | `0` | `$0.00` | `0` |
| 2017 | `+$12.19` | `3` | `+$12.19` | `3` |
| 2018 | `+$41.95` | `4` | `+$50.80` | `3` |
| 2019 | `$0.00` | `0` | `$0.00` | `0` |
| 2020 | `-$49.23` | `6` | `+$23.47` | `2` |
| 2021 | `+$200.32` | `7` | `+$213.07` | `6` |
| 2022 | `+$44.00` | `2` | `-$10.50` | `1` |
| 2023 | `+$90.00` | `3` | `+$90.00` | `3` |
| 2024 | `-$2.65` | `5` | `-$5.23` | `5` |
| 2025 | `+$28.07` | `1` | `+$28.07` | `1` |
| 2026 YTD | `+$35.73` | `1` | `+$35.73` | `1` |

`DI >= -12` had two red active years (`2020`, `2024`) and two inactive years (`2016`, `2019`). Its annual restart sum was `+$431.43` on `34` trades versus `+$478.86` continuous.

`DI >= -10` had two red active years (`2022`, `2024`) and two inactive years (`2016`, `2019`). Its annual restart sum was `+$468.65` on `27` trades versus `+$447.23` continuous.

Both fail the no-losing-active-year rule.

## Portfolio Screen

Exact trade streams:

- `DI >= -12`: `36` trades, SHA-256 `2F91E8545B58E5E8BE9A7F6FDB8C6DC9C4CAF59D1EF8C8E43D108362403222FC`
- `DI >= -10`: `28` trades, SHA-256 `BFB67869B79F70BD105944E7D3919D8873A3D2D9011B44C1D3F7D4BF970B9468`

Each stream was screened in `700` exact realized-R combinations with the maintained, high-profit, and Donchian streams under a `3%` open-risk cap and `0.05R` per-trade stress. Both screens returned `0` eligible rows.

Best `DI >= -12` near-miss:

- profile `hp1.00_mr1.50_dd0.00_rv0.50`
- net `+$12,690.63`
- CAGR `7.37%`
- PF `2.303`
- conservative risk-floor drawdown `5.98%`
- recovery `14.90`
- red year `2019` at `-$55.11`
- inactive year `2016`
- stress red years `1`

The `DI >= -10` leader was slightly weaker at `+$12,592.78`, `7.33%` CAGR, PF `2.318`, and the same `5.98%` conservative drawdown; it also retained red 2019 and inactive 2016.

## Disposition

- Do not promote either gate into maintained A167.
- Do not call either filtered lane money-ready, trade-ready, or live-ready.
- Preserve the default-off source and exact reports as evidence that DI imbalance is a useful reversion-quality feature.
- Do not tune another DI threshold from these same trades.
- Future work should add genuinely independent activity for 2016/2019 or a new strategy family, then repeat broad Model4/yearly/stress validation.

Evidence:

- `outputs/HTF_BAND_REVERSION_FEATURE_ANALYSIS.md`
- `outputs/HTF_BAND_REVERSION_FEATURE_GATES.csv`
- `outputs/HTF_BAND_REVERSION_DI_GATE_MODEL1_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_DI_GATE_MODEL4_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_DI_GATE_YEARLY_MODEL4_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_DI_M12_MODEL4_TRADES.csv`
- `outputs/HTF_BAND_REVERSION_DI_M10_MODEL4_TRADES.csv`
- `outputs/STRATEGY_PORTFOLIO_WITH_REVERSION_DI_M12_SCREEN.md`
- `outputs/STRATEGY_PORTFOLIO_WITH_REVERSION_DI_M10_SCREEN.md`

## Safety State

The maintained source/profile pair remains A167/D045. Real-account trading remains hard-locked.

- maintained root/mirror source SHA-256: `A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622`
- maintained money-ready profile SHA-256: `D0459197F2A8CA1385F139694BD036AA9A3A596BB406F7D4474CDC8444605C79`
- restored maintained compile: `0 errors, 0 warnings`
- feature and portfolio Python analyzer AST checks: pass
- three new PowerShell package-builder parser checks: `0` errors
- evidence rows parsed: Model1 `16 / 16`, continuous Model4 `3 / 3`, yearly Model4 `24 / 24`
- exact portfolio grids: `700 + 700` rows, `0 + 0` eligible
- MT5 local safety audit: `44 / 44` pass
- static MQL preflight: `39 / 39` pass with `476` inputs
- static repository safety audit: `25 / 25` pass
- local launch hard lock: present
- local, hidden-desktop, and external unlocks: absent
- MT5 / MetaEditor / tester processes after restore: `0`
