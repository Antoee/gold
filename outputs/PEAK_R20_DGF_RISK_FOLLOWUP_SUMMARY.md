# Peak R20 Diagnostic Fallback Risk Follow-Up

Generated: 2026-07-14.

## Decision

No new money-ready or clean stability-best profile was promoted.

The current stability lead remains `r10_pg40_atr085_adapt7`, but it is still research-only because Model4 yearly validation has one red year in 2020.

## Code Added

The EA now includes default-off diagnostic-fallback controls:

- Diagnostic fallback spread guard:
  - `InpUseDiagnosticFallbackSpreadGuard`
  - `InpDiagnosticFallbackMaxSpreadPoints`
  - `InpDiagnosticFallbackMaxSpreadATRPercent`
- Diagnostic fallback spread risk scaling:
  - `InpUseDiagnosticFallbackSpreadRiskScaling`
  - `InpDiagnosticFallbackSpreadRiskStartPoints`
  - `InpDiagnosticFallbackSpreadRiskFullPoints`
  - `InpDiagnosticFallbackMinSpreadRiskMultiplier`
- Diagnostic fallback performance risk scaling:
  - `InpUseDiagnosticFallbackPerformanceRiskScaling`
  - `InpDiagnosticFallbackPerformanceLookbackTrades`
  - `InpDiagnosticFallbackPerformanceMinTrades`
  - `InpDiagnosticFallbackWeakAverageR`
  - `InpDiagnosticFallbackStrongAverageR`
  - `InpMinDiagnosticFallbackPerformanceRiskMultiplier`

These inputs are disabled by default so prior profiles remain reproducible unless a `.set` file explicitly enables them.

## Hard Spread/ATR Guard Result

File: `outputs/PEAK_R20_DFG_SPREAD_YEARLY_RESULTS.csv`

Hard diagnostic-fallback spread and ATR caps were rejected. They removed some risk, but they also removed enough winners to create red Model1 yearly windows. This is not a robust fix.

## Spread Risk Scaling Result

Model1 yearly file: `outputs/PEAK_R20_DFG_SPREAD_RISK_YEARLY_RESULTS.csv`

Model4 yearly file: `outputs/PEAK_R20_DFG_SPREAD_RISK_MODEL4_YEARLY_RESULTS.csv`

Best tested variant:

`r10_a7_dfg_risk_25_45_50`

Settings:

- `InpUseDiagnosticFallbackSpreadRiskScaling=true`
- `InpDiagnosticFallbackSpreadRiskStartPoints=25.0`
- `InpDiagnosticFallbackSpreadRiskFullPoints=45.0`
- `InpDiagnosticFallbackMinSpreadRiskMultiplier=0.50`

Model1 yearly validation:

- Total net: `+$343.92`
- Losing years: `0`
- Worst year: `+$9.25`
- Worst DD: `6.18%`
- Trades: `28`

Model4 yearly validation:

- Total net: `+$270.66`
- Losing years: `1`
- Worst year: `-$15.28` in 2020
- Worst DD: `6.20%`
- Trades: `22`

Decision: partial improvement only. It reduced the 2020 Model4 loss from `-$22.92` to `-$15.28` and reduced drawdown, but 2020 is still red. Not promoted.

## Performance Risk Scaling Result

File: `outputs/PEAK_R20_DGF_PERF_RISK_YEARLY_RESULTS.csv`

Performance-throttle variants were rejected in fast Model1 yearly validation:

| Candidate | Total Net | Worst Year | Worst DD | Decision |
| --- | ---: | ---: | ---: | --- |
| `r10_a7_dgf_perf_base` | `+$344.60` | `+$9.25` | `7.08%` | Control remains green |
| `r10_a7_dgf_perf_4_2_50` | `+$319.92` | `-$8.96` | `6.11%` | Rejected |
| `r10_a7_dgf_perf_5_2_50` | `+$297.06` | `-$8.96` | `6.22%` | Rejected |
| `r10_a7_dgf_perf_3_2_40` | `+$292.40` | `-$13.62` | `6.22%` | Rejected |
| `r10_a7_dgf_spread_perf_4_2_50` | `+$319.24` | `-$9.64` | `6.11%` | Rejected |
| `r10_a7_dgf_spread_perf_3_2_40` | `+$288.70` | `-$17.32` | `6.22%` | Rejected |

Decision: do not send these throttle variants to Model4. They fail the faster no-red-year gate before the expensive validation step.

## Next Best Work

The 2020 Model4 diagnostic-fallback loss is smaller after spread-risk scaling, but not solved. The next useful branch should avoid another one-off filter and instead test broader, risk-first behavior such as:

- A true exported-report reproduction path so every yearly result includes full MT5 stats.
- A no-red-year Model4 candidate before any new "best" claim.
- Broker/stress variation for the current stability lead.
- A stricter diagnostic fallback entry-quality model only if it can pass Model1 yearly splits before Model4.
