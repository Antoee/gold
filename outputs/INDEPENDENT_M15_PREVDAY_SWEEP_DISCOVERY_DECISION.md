# Independent M15 Previous-Day Liquidity Sweep Decision

Decision date: 2026-07-16

**Verdict: rejected during Model 1 discovery. No 2021-2026 retrospective run was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Test Contract

This standalone price-action EA trades fresh M15 sweeps and reclaims of the previous D1 high or low. The ten-variant neighborhood changes sweep depth, reclaim depth, wick shape, tick-volume confirmation, H1 trend alignment, maximum ADX, payoff, midpoint targeting, and session timing without using calendar cutoffs or recent-period optimization.

- Source: `work/Independent_XAUUSD_M15_PrevDay_Sweep.mq5`
- Source SHA-256: `DE93CFC433C0F3A9B19A6F8D58AAF32894FC8FE6DC41F98A3745FD209C787E8E`
- Compile: `0 errors, 0 warnings`
- Discovery data only: 2015-01-01 through 2020-12-31
- Clean reports returned and parsed: `30 / 30`
- Candidate variants: `10`
- Continuous risk per trade: `0.10%`
- 2021-2026 retrospective configurations run: `0`
- Model 4 configurations run: `0`

## Discovery Evidence

The predeclared gate required both disjoint eras to be profitable, continuous profit factor of at least 1.20, at least 60 continuous trades, maximum drawdown no greater than 5%, and support from nearby parameter shapes. Every tested configuration lost money in the older 2015-2018 era, so none could pass regardless of its continuous headline.

| Candidate | 2015-2018 | 2019-2020 | Continuous 2015-2020 | PF | Max DD | Trades | Win rate | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `pds_volume105` | `-$37.94` | `+$75.00` | `+$37.06` | `1.15` | `1.11%` | `46` | `39.13%` | rejected |
| `pds_wick15` | `-$95.07` | `+$48.92` | `-$46.66` | `0.83` | `1.14%` | `48` | `33.33%` | rejected |
| `pds_trend` | `-$36.92` | `-$13.89` | `-$50.81` | `0.23` | `1.17%` | `10` | `20.00%` | rejected |
| `pds_sweep10` | `-$127.47` | `+$79.23` | `-$60.89` | `0.85` | `1.93%` | `75` | `38.67%` | rejected |
| `pds_adx24` | `-$51.35` | `-$37.65` | `-$89.00` | `0.41` | `1.33%` | `28` | `39.29%` | rejected |
| `pds_reclaim05` | `-$114.65` | `+$38.15` | `-$89.15` | `0.77` | `1.85%` | `65` | `33.85%` | rejected |
| `pds_base` | `-$114.65` | `+$38.15` | `-$89.15` | `0.77` | `1.85%` | `65` | `33.85%` | rejected |
| `pds_rr20` | `-$123.53` | `+$33.59` | `-$102.59` | `0.74` | `2.00%` | `65` | `32.31%` | rejected |
| `pds_session12_22` | `-$123.33` | `+$16.41` | `-$107.52` | `0.67` | `1.76%` | `59` | `35.59%` | rejected |
| `pds_midpoint` | `-$116.28` | `-$44.97` | `-$166.76` | `0.55` | `2.41%` | `63` | `33.33%` | rejected |

The least-bad continuous row was `pds_volume105` at `+$37.06`, but it still lost `-$37.94` in the independent older era, had PF `1.15`, and produced only `46` continuous trades. The parameter neighborhood therefore provides no robust edge worth escalating.

## Decision

- Reject previous-day high/low sweep reversal at the tested M15 risk and confirmation neighborhood.
- Do not use 2021-2026 to rescue the branch; the strategy failed before recent data was opened.
- Skip Model 4 because the broad Model 1 discovery gate failed.
- Do not merge this standalone engine into the frozen EA.
- Preserve the frozen three-lane benchmark, exact installed binary, and forward boundary unchanged.

## Evidence

- `outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_SUMMARY.csv`
- `outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_METRICS.md`
- `outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_RUN.csv`
- `outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_DECISION.csv`
