# Current Research Best Profile

Last updated: 2026-07-16.

## Authoritative Current-Source Candidate

The best current-source risk-first candidate is:

`outputs/CANDIDATE_MONEY_READY_PROFILE.set`

Profile SHA-256:

`D0459197F2A8CA1385F139694BD036AA9A3A596BB406F7D4474CDC8444605C79`

Maintained source SHA-256:

`A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622`

| Test | Net | Total return | Annualized | CAGR | PF | Trades | Max equity DD | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Model4 real ticks, 2019-2026 | `+$321.59` | `+3.22%` | `+0.43%/yr` | `+0.42%/yr` | `2.81` | `32` | `0.59%` | `5.32` |
| Model1, 2019-2026 | `+$397.53` | `+3.98%` | `+0.53%/yr` | `+0.52%/yr` | `2.77` | `37` | `0.66%` | `5.72` |
| Model1, 2024-2026 YTD | `+$79.21` | `+0.79%` | `+0.31%/yr` | `+0.31%/yr` | `1.64` | `12` | `0.68%` | `1.14` |

This replaces the older labels below as the authoritative current-source status. It is a trade-readiness research candidate, not a money-ready bot or a live approval.

The exact profile took zero trades in the continuous and yearly 2015-2018 Model1 diagnostics. Therefore, optimizing 2024-now cannot be expected to work automatically in the future. The strategy currently demonstrates recent-regime selectivity, not broad-regime adaptability.

Standard and severe 10,000-trial realized-R Monte Carlo tests both failed the loss-streak gate with a 95th-percentile streak of seven losses. The severe test had a `+7.95R` 5th-percentile net, but its worst trial was `-0.16R`.

An earlier independent M15 Bollinger/VWAP reversion lane was rejected: its best continuous Model1 row made `+$11.80`, PF `1.29`, on `28` trades and added no 2015-2018 activity. No new best was promoted, and the experimental code was removed from the maintained source.

The later daily Donchian channel-exit lane was profitable in all three broad eras and reproduced on continuous Model4 at `+$438.43`, PF `1.41`, `51` trades, and `3.77%` drawdown. It was still rejected because 2019-2022 was nearly flat (`+$27.75`, PF `1.07`) and combining it with this candidate reduced Model1 continuous net to `+$255.38` while creating a `-$22.74` older-era loss. See `outputs/DAILY_DONCHIAN_BREAKOUT_DECISION.md`.

A long-only follow-up improved the best broad Model1 row to `+$887.48`, PF `1.99`, and `3.64%` drawdown, with positive older, middle, and recent eras. Independent yearly validation then rejected the entire plateau: every tested 15-30 day shape had four or five losing active years, and every restarted-year aggregate score was negative. No new best was promoted. See `outputs/DAILY_DONCHIAN_LONG_ONLY_DECISION.md`.

A later DGF weak-hour and minimum-ATR follow-up also failed promotion. All `99 / 99` Model1 reports parsed and showed a smooth fast-model plateau, but all higher-return candidates retained a losing 2019 in the `12 / 12` focused Model4 gate. The best real-tick row made `+$631.54`, PF `1.70`, at `1.19%` drawdown while losing `-$9.68` in 2019. The only positive-2019 variant reduced continuous net to `+$400.15` and PF to `1.55`. Source reproduction also traced an apparent missing-trade regression to an old profile value becoming active after its spread-floor constant was exposed as an input. No new best was promoted and the experimental entry code was removed. See `outputs/DGF_VOLATILITY_FLOOR_DECISION.md`.

An exact realized-R portfolio screen then tested `900` blends of this maintained candidate, the 127-trade high-profit branch, and the broad-era daily Donchian branch. The strongest analytical near-miss reached `+$9,798.58`, `8.50%/yr`, `6.10%` CAGR, PF `2.185`, `210` trades, and a conservative `6.57%` risk-floor drawdown. It was not implemented because 2017 and 2019 remained red, `28` rolling 12-month windows were negative, and a `0.05R` cost stress produced three red years. Two targeted Donchian repair screens also failed. See `outputs/STRATEGY_PORTFOLIO_DECISION.md`.

A later H1 Bollinger/VWAP reversion family produced the strongest independent broad-history component in the current cycle. Its ADX `22` leader made `+$440.63`, `+0.38%/yr`, PF `2.36`, on `41` continuous 2015-2026 Model4 trades with `1.10%` drawdown, while two neighboring real-tick profiles also stayed profitable. It remains unpromoted because yearly Model4 lost in 2016, 2020, and 2024 and left 2019 inactive. All `700` exact realized-R blends with the maintained, high-profit, and Donchian streams failed the zero-red base/stress gate. Frozen research profile: `outputs/CANDIDATE_HTF_BAND_REVERSION_RESEARCH_PROFILE.set`, SHA-256 `A93F9D52CE8E2D7BD5AD99DDD9E089859ED390B39E63C21CA639EC171966C64E`. See `outputs/HTF_BAND_REVERSION_DECISION.md`.

A feature-diagnostic follow-up exactly reproduced that 41-trade stream, screened `86` date-independent one-factor gates, and predeclared a narrow DI-edge neighborhood. `DI >= -12` improved continuous Model4 to `+$478.86`, PF `2.77`, `36` trades, and `1.14%` drawdown; `DI >= -10` made `+$447.23`, PF `3.51`, `28` trades, and `1.06%` drawdown. Both still failed yearly Model4 with two losing active years and no 2016/2019 activity. Their separate `700`-row exact portfolio screens also returned zero eligible blends. This validates DI imbalance as a useful research feature but does not change the maintained best or live-readiness status. See `outputs/HTF_BAND_REVERSION_DI_GATE_DECISION.md`.

See `outputs/MONEY_READY_BALANCED_DECISION.md` for the complete decision and evidence map.

## Historical Recent-Regime Leader And Holdout Downgrade

The section below is retained as research chronology. It does not override the current-source candidate above.

The current-source risk-adjusted leader inside the 2019-2026 research period is:

`soo_m4_911_loss14` / adaptive liquidity DGF `09:00-10:59`

Maintained guarded profile file:

`outputs/CANDIDATE_SESSION_ADAPTIVE_9_11_STABILITY_GUARDED_PROFILE.set`

SHA-256:

`F242B6D43FE9C79901B137F2358BF55197B9E7E3C784A18071FE8D34A6B903E6`

Maintained source SHA-256:

`62C2F0B2397AE9992CA2B156ED1A2AA45D0F874DD3803CEA9F74EB15882B3DDE`

The original frozen evidence profile remains `outputs/CANDIDATE_SESSION_ADAPTIVE_9_11_STABILITY_PROFILE.set`, SHA-256 `40993406F0E615CC0F70012ED99253D08B5DA657C62A9ABA2BBD4CC99EF32115`.

Continuous 2019-2026 Model4 result on `$10,000`:

- Net: `+$667.94`
- Total return: `+6.68%`
- Annualized return: `0.89%/yr`
- CAGR: `0.86%`
- Profit factor: `3.63`
- Trades: `40`
- Max drawdown: `0.67%`
- Recovery factor: `9.44`

Frozen 2015-2018 holdout:

- Model4 history quality: `0% real ticks`, so no valid older real-tick pass is available from this broker
- Continuous net: `+$0.24`
- Unique trades: `1`
- 2015-2017 trades: `0`
- Model1 diagnostic: identical activity and net

Decision:

This profile is no longer described as broadly stable. It remains the best risk-adjusted recent-regime benchmark, but it failed the older minimum-activity gate and is not money-ready. See `outputs/SESSION_OLDER_OOS_PROBE_DECISION.md`.

A follow-up cost-efficient session-expansion strategy did add older activity, but every active 2015-2018 continuous variant lost money. The branch was rejected, its code was removed, and this frozen profile/source pair remains unchanged. See `outputs/SESSION_COST_EXPANSION_PROBE_DECISION.md`.

A distinct independent range-liquidity sweep/reclaim strategy was also screened on 2015-2018. Its best-looking rows made only `+$5.58` on `3` total trades, just two trades beyond the frozen control over four years, while baseline variants were slightly negative. It was rejected as statistically inactive, its code was removed, and this frozen profile/source pair remains unchanged. See `outputs/INDEPENDENT_RANGE_CONTINUOUS_PROBE_DECISION.md`.

An independent H1 EMA trend plus M15 pullback/reclaim strategy was then screened on 2015-2018. Baseline and neighboring variants lost; only an isolated strict row was positive at `+$7.71` on `8` trades while the looser `56`-trade row had PF `0.68`. It failed the activity and profitable-plateau gates, its code was removed, and this frozen profile/source pair remains unchanged. See `outputs/IHTP_CONTINUOUS_PROBE_DECISION.md`.

The exact frozen profile now also has `8 / 8` annual Model4 reports from 2019 through 2026 YTD. 2019 was inactive; every active year from 2020 onward was profitable. The annual restart score is `+$650.08`, average annual return `+0.89%`, `40` trades, and `0.57%` worst yearly drawdown. This confirms recent-regime annual stability without changing the profile, but it does not repair older-regime inactivity or make the candidate money-ready. See `outputs/SESSION_ADAPTIVE_YEARLY_PROBE_DECISION.md`.

Realized-R parsing covers all `40 / 40` continuous Model4 trades. Standard and severe 10,000-trial Monte Carlo stresses remained positive in every trial, but both failed the operational loss-streak gate with a 95th-percentile streak of seven losses. Economic stress evidence is encouraging; unattended live approval remains blocked pending forward/demo, second-broker, and live-policy proof. See `outputs/SESSION_ADAPTIVE_MONTE_CARLO_DECISION.md`.

A dedicated abnormal-loss-streak quarantine now exists independently from the ordinary post-loss cooldown. The four-loss, 30-day guarded profile reproduced the default-off Model4 control exactly: `+$667.94`, PF `3.63`, `40` trades, and `0.67%` drawdown, with identical trade hashes. The feature passed `9 / 9` synthetic state cases. Because history never reached four consecutive losses, this proves non-interference rather than protective effectiveness. Forward/demo and second-broker proof remain mandatory. See `outputs/SESSION_ABNORMAL_QUARANTINE_PROBE_DECISION.md`.

A trade-level diversification screen found near-zero correlation and only two overlapping positions between this candidate and an old high-profit trend-fallback branch. The combination still had a red 2019 and a six-loss streak, while the secondary profile contained explicit date/month fitting under an older source. It was rejected without a combined MT5 run. See `outputs/TRADE_LEVEL_DIVERSIFICATION_DECISION.md`.

A standalone Asian-range sweep and London rejection lane then returned all `28 / 28` Model1 reports across older, middle, recent, and continuous windows. Every neighboring shape had a losing broad era, and none reached the continuous PF `1.20` gate. The experiment was rejected without Model4, its code was removed, and the maintained source/profile pair remains unchanged. See `outputs/INDEPENDENT_SESSION_STRUCTURE_PROBE_DECISION.md`.

The old high-profit trend-fallback stream was then reconstructed without its March/May/August month selection, auxiliary lanes, or fitted exits. All `56 / 56` Model1 reports returned. The clean body-20 signal lost `-$1,463.76` on `1,466` trades; the best bounded body/payoff follow-up reached only `+$68.99`, PF `1.00`, with losing older and recent eras. It was rejected without Model4. The old high-profit profile is now explicitly classified as calendar-dependent historical research, not a deployable diversification candidate. See `outputs/DATE_INDEPENDENT_TREND_FALLBACK_DECISION.md`.

A distinct higher-timeframe trend plus M15 Donchian-breakout lane was then tested in `32 / 32` Model1 reports. All eight neighboring variants lost over the continuous 2015-2026 path and in both older and middle eras. The least-negative continuous row lost `-$15.89`, PF `0.74`, and its recent-only gain was `+$3.20`; the largest recent gain was `+$7.09` on a row that lost in both prior eras. It was rejected without Model4, its code was removed, and the maintained source/profile pair remains unchanged. See `outputs/INDEPENDENT_HTF_TREND_BREAKOUT_DECISION.md`.

Existing long-pause controls were then tested in `54 / 54` Model1 reports. A 30-day ordinary post-loss cooldown and a three-trade average-R pause both reduced profit without reducing drawdown; a 60-day cooldown created a red 2025. The experiment was rejected and exact source/profile behavior remains unchanged. See `outputs/SESSION_ABNORMAL_PAUSE_PROBE_DECISION.md`.

The historical sections below are retained as research chronology. Their older labels do not override this current holdout classification.

## Critical Current-Source Correction

All profit results produced before source hash `3C738B730A47A089ECE11A53EC9E726DE2E64B63E53866B9731253C5035A114C` are superseded as live-readiness evidence. The former risk calculation did not match actual XAUUSD order P/L on the tested broker specification.

The strongest corrected low-drawdown baseline is now:

`sr_m4_sweep_off`

Profile file:

`outputs/CANDIDATE_BROKER_ACCURATE_STABILITY_BASELINE.set`

SHA-256:

`4D0B808BE07BF6612C70F96E4287717F3C7A8370B9089B165D71A244C3EA8E89`

Continuous 2019-2026 Model4 real ticks on `$10,000`:

- Net: `+$211.37`
- Total return: `+2.11%`
- Annualized return: `0.28%/yr`
- CAGR: `0.28%`
- Profit factor: `2.12`
- Trades: `26`
- Max equity drawdown: `0.82%`
- Recovery factor: `2.51`

Fast Model1 yearly validation had zero losing years. This is the current stability baseline only. It is not money-ready because growth and sample size are far too low. Sections below remain historical research context and must not be read as corrected current-source performance.

## 2026-07-14 Stability Lead Update

The strongest new risk-first research lead is now:

`r10_pg40_atr085_adapt7`

Profile file:

`outputs/peak_r20_regime_combo_candidate_profiles/r10_pg40_atr085_adapt7.set`

SHA-256:

`CB182D026A62AE499052949F88F514EF7FC67D8C071E9179AB069D29575C59B2`

It adds the following to the `r10_profit_guard40` base:

- `InpUseDynamicATRRegimeGuard=true`
- `InpMinATRRegimeRatio=0.85`
- `InpMaxATRRegimeRatio=1.65`
- `InpUseAdaptiveRegimeConfidenceGate=true`
- `InpAdaptiveRegimeMinScore=7`
- `InpAdaptiveRegimeMinEfficiency=0.45`

Model1 yearly validation across 2019-2026 YTD:

- Total net: `+$344.60`
- Losing years: `0`
- Worst year: `+$9.25`
- Worst DD: `7.08%`
- Trades: `28`

Model4 real-tick yearly validation across 2019-2026 YTD:

- Total net: `+$263.72`
- Losing years: `1`
- Worst year: `-$22.92` in 2020
- Worst DD: `7.09%`
- Trades: `22`
- 2026 YTD Model4 took `0` trades

Decision:

This is the current stability lead, but it is not money-ready. The blocker is the 2020 Model4 loss, which was one `Diagnostic trend fallback` sell trade on 2020-08-13 with ATR `3.82`, spread `30.0`, and profit `-$22.92`. The first diagnostic-quality follow-up did not solve it; the next branch should test a legitimate spread/volatility/risk-control guard rather than disabling a calendar year.

## 2026-07-14 High-Profit Continuous DGF Lead

The newest DGF continuous-account high-profit research lead is:

`lossblock_highprofit_peaktrail_off`

Profile file:

`outputs/CANDIDATE_RANGE_ELITE_HIGHPROFIT_PEAKTRAIL_OFF_CONTINUOUS_PROFILE.set`

SHA-256:

`0FBFA1F540422DF1B88A9410752E706B917F3111BFEF317F7EE9A03D7A4C2499`

Continuous 2019-2026 Model4 real-tick validation:

- Net profit: `+$1,915.83`
- Total return: `+191.58%`
- Average annualized return: `25.45%/yr`
- CAGR: `15.28%`
- Profit factor: `1.72`
- Recovery factor: `2.02`
- Trades: `127`
- Max equity DD: `24.58%`
- Return/DD: `7.79`

Decision:

This is not the stability lead and not money-ready. It replaces the superseded DGF peak-trail-on restart-window leads as the newest DGF high-profit research reference because those original profiles stalled after only `3` trades on the continuous account path. The next useful work is reducing drawdown without reintroducing a permanent global account freeze.

Evidence:

- `outputs/PEAK_TRAIL_UNBLOCK_CONTINUOUS_MODEL4_DECISION.md`
- `outputs/PEAK_TRAIL_UNBLOCK_CONTINUOUS_MODEL4_COMPARISON.csv`
- `research/2026-07-14-peak-trail-unblock-continuous-note.md`

## 2026-07-14 DGF Risk Follow-Up

No new best was promoted.

The EA now includes default-off diagnostic-fallback risk controls:

- `InpUseDiagnosticFallbackSpreadGuard`
- `InpUseDiagnosticFallbackSpreadRiskScaling`
- `InpUseDiagnosticFallbackPerformanceRiskScaling`

Evidence:

- Hard diagnostic-fallback spread/ATR caps were rejected because they created red Model1 yearly windows.
- `r10_a7_dfg_risk_25_45_50` partially improved Model4 yearly validation: total `+$270.66` versus `+$263.72`, worst DD `6.20%` versus `7.09%`, and the 2020 blocker improved from `-$22.92` to `-$15.28`.
- The 2020 Model4 window is still red, so `r10_a7_dfg_risk_25_45_50` is not promoted.
- DGF performance-risk throttle variants were rejected in Model1 yearly validation because every throttle variant created at least one red yearly window while the base remained all-green.

See:

- `outputs/PEAK_R20_DGF_RISK_FOLLOWUP_SUMMARY.md`
- `outputs/PEAK_R20_DFG_SPREAD_YEARLY_RESULTS.csv`
- `outputs/PEAK_R20_DFG_SPREAD_RISK_MODEL4_YEARLY_RESULTS.csv`
- `outputs/PEAK_R20_DGF_PERF_RISK_YEARLY_RESULTS.csv`

Evidence:

- `outputs/PEAK_R20_REGIME_COMBO_STABILITY_LEAD_SUMMARY.md`
- `outputs/PEAK_R20_REGIME_COMBO_OOS_YEARLY_RESULTS.csv`
- `outputs/PEAK_R20_REGIME_COMBO_MODEL4_YEARLY_RESULTS.csv`
- `outputs/PEAK_R20_DIAG_QUALITY_YEARLY_RESULTS.csv`
- `outputs/peak_r20_regime_combo_model4_diag_package/trade_logs/PXEA_R10A7_2020_m4_trades.csv`

## Profile

Previous promoted stability-best research profile:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Profile file:

`outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`

SHA-256:

`D0867E0333D3F110EF47410A2B2FF46402AAD96FC70B0DBF9506836124D633BC`

Research note:

`research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`

Stats export note:

`research/2026-07-12-lowatr-tester-stats-export-note.md`

Latest stats summaries:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_SUMMARY.csv`

## Change

The current best keeps the Dec-ISLP-Off profile and adds a smarter low-volatility ISLP guard:

- `InpInSessionLiquidityPullbackMinATR=0.00`
- `InpInSessionLiquidityPullbackLowATRRequireOrderFlow=true`
- `InpInSessionLiquidityPullbackLowATRThreshold=5.00`

Meaning:

Low-ATR ISLP trades are still allowed, but only when order flow confirms.

## Why It Replaced Dec-ISLP-Off

The blunt MinATR5 guard was rejected because it removed the October 2024 loser but also deleted a larger June 2024 winner.

The LowATR OrderFlow guard fixed that tradeoff:

- It kept the June 2024 low-ATR ISLP winner because order flow confirmed.
- It blocked the October 2024 low-ATR ISLP loser because order flow did not confirm.

## Model4 Evidence

Sampled probe:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7` | `+271.42` | `1` | `-44.64` |
| `islp_lowatr_of` | `7` | `+316.06` | `0` | `0.00` |

Monthly validation:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31` | `+3,637.53` | `1` | `-44.64` |
| `islp_lowatr_of` | `31` | `+3,682.17` | `0` | `0.00` |

Monthly tester-stat rerun:

| Profile | Stats Parsed | Total Net | Trades | Worst Equity DD % | Nonzero PF Samples | Min Nonzero PF |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31 / 31` | `+3,637.53` | `39` | `30.9408` | `7` | `1.4914` |
| `islp_lowatr_of` | `31 / 31` | `+3,682.17` | `38` | `30.9408` | `7` | `1.4914` |

Quarterly validation:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11` | `+3,421.49` | `1` | `-44.64` |
| `islp_lowatr_of` | `11` | `+3,435.65` | `1` | `-30.48` |

Quarterly tester-stat rerun:

| Profile | Stats Parsed | Total Net | Trades | Worst Equity DD % | Min Recovery Factor | Avg Sharpe |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11 / 11` | `+3,421.49` | `34` | `30.9408` | `-0.9789` | `3.2935` |
| `islp_lowatr_of` | `11 / 11` | `+3,435.65` | `34` | `30.9408` | `-0.5184` | `3.2828` |

Most recent reproduced continuous check before the trade-environment guard source update:

Return math uses a `$1,000` starting balance and CAGR over `2024.01.01` to `2026.07.12` (`2.53` years).

| Profile | Continuous | Total Return | CAGR/yr | 2024 Full | 2025 Full | 2026 YTD | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `+1,195.04` | `+119.50%` | `+36.49%/yr` | `+1,340.55` | `+214.30` | `+955.21` | `28.2997` |
| `islp_lowatr_of` | `+1,195.69` | `+119.57%` | `+36.51%/yr` | `+1,353.53` | `+214.30` | `+955.21` | `28.2785` |

The older `+4,507.51` Dec-ISLP-Off Model4 continuous result equals `+450.75%` total and about `+96.43%/yr` CAGR from a `$1,000` start, but it is now treated as historical/stale until it is reproduced on the current local source and compact tester path.

Decision:

Promoted as the current stability-best research profile.

## Aggressive Research Frontier

On 2026-07-14, a separate R20 opportunity sweep found `peak_r20_no_peaktrail_r10`.

This profile is not promoted as the stability-best and is not trade-ready, but it is the current high-profit research frontier:

| Profile | Model | Window | Net | Ann. Return | CAGR | PF | Recovery | Trades | Max DD |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `peak_r20_no_peaktrail_r10` | 1 | 2024-01-01 to 2026-07-12 | `+$1,716.76` | `67.94%` | `48.51%` | `2.8655` | `7.5227` | `76` | `10.62%` |
| `peak_r20_no_peaktrail_r10` | 4 | 2024-01-01 to 2026-07-12 | `+$1,564.01` | `61.89%` | `45.15%` | `2.6874` | `7.1007` | `74` | `10.64%` |

Model1 yearly splits stayed green: 2024 `+$814.43`, 2025 `+$186.95`, and 2026 YTD `+$246.96`.

Reason not promoted: drawdown is above the strict safety band and full exported MT5 reports are still missing. See `outputs/LOWATR_R20_OPPORTUNITY_SWEEP_SUMMARY.md`.

## R10 Drawdown Follow-Up

On 2026-07-14, a 22-variant drawdown-reduction sweep tested risk floors, loss-risk scaling, equity/realized giveback quality gates, profit guards, and daily equity trailing around the aggressive R10 branch.

No new trade-ready profile was promoted.

Model4 shortlist:

| Candidate | Net | Ann. Return | CAGR | PF | Recovery | Sharpe | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_dailytrail35` | `+$1,577.25` | `62.42%` | `45.45%` | `2.7264` | `7.1609` | `39.7757` | `73` | `10.64%` |
| `r10_base` | `+$1,564.01` | `61.89%` | `45.15%` | `2.6874` | `7.1007` | `38.3838` | `74` | `10.64%` |
| `r10_loss_scale_25` | `+$1,396.22` | `55.25%` | `41.31%` | `2.6496` | `7.2448` | `38.5606` | `75` | `9.32%` |
| `r10_loss_scale_15` | `+$1,281.41` | `50.71%` | `38.60%` | `2.7634` | `7.2787` | `40.9187` | `68` | `8.53%` |
| `r10_profit_guard40` | `+$1,000.97` | `39.61%` | `31.59%` | `3.4058` | `8.5240` | `42.3443` | `46` | `7.76%` |

Decision:

- `r10_dailytrail35` is not promoted because it adds only `+$13.24` over the Model4 R10 baseline and leaves drawdown unchanged.
- `r10_profit_guard40` is the best lower-drawdown fallback, but it gives up too much profit to replace the aggressive frontier outright.
- Both remain research-only until exported full reports, split validation, stress testing, broker variation, and forward/demo evidence exist.

See `outputs/PEAK_R20_DRAWDOWN_SWEEP_SUMMARY.md`.

## R10 Older-Year/OOS Rejection

The R10 branch was then tested on 2019 through 2026 YTD yearly Model1 windows because 2024-2026 is now research-seen data.

Result: all tested R10 candidates are rejected as money-ready.

| Candidate | Total Net | Losing Years | Worst Year | Worst DD | Decision |
| --- | ---: | ---: | ---: | ---: | --- |
| `r10_base` | `+$1,371.43` | `3` | `-$66.26` | `12.44%` | Rejected for red older years and high yearly DD |
| `r10_loss_scale_15` | `+$956.26` | `4` | `-$90.25` | `14.21%` | Rejected for too many red years and high DD |
| `r10_profit_guard40` | `+$848.09` | `2` | `-$61.65` | `12.78%` | Rejected as money-ready despite being the best recent lower-drawdown fallback |

This means the R10 branch is recent-regime research, not a robust live candidate. The next useful work is diagnosing the older-year failures rather than raising risk.

See `outputs/PEAK_R20_OOS_YEARLY_SUMMARY.md`.

## Evidence Files

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_CONTINUOUS_CHECK_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_CONTINUOUS_CHECK_SUMMARY.csv`
- `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`
- `research/2026-07-12-lowatr-tester-stats-export-note.md`
- `research/2026-07-12-block-diagnostics-and-risk-shape-note.md`

## Caveats

This is not a live-ready production profile.

Remaining gaps:

- MT5 report export still returns `NO_REPORT`; results are parsed from tester logs.
- Monthly and quarterly tester-stat reruns are complete, but they show a high worst equity drawdown reading of `30.9408%`.
- The most recent reproduced continuous Model4 check is only `+1,195.69` (`+119.57%` total, `+36.51%/yr` CAGR); the historical `+4,507.51` continuous headline needs reproduction before it should be used as the current headline.
- After that continuous check, the local source changed again to add the trade-environment guard, make the real-account lock non-bypassable on real accounts, and update candidate profile hashes. No new backtest has promoted source hash `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394` yet.
- Hold-time stats still need richer extraction.
- Model1 and Model2 have not yet been rerun on this LowATR OrderFlow candidate.
- Local `Professional_XAUUSD_EA.mq5` is ahead of the GitHub source and contains newer default-off flat-month probe/wake-up infrastructure.
- The local workspace is not currently a valid Git checkout because `.git` exists but is empty.

Adaptive Reverse remains disabled and is now source-quarantined against accidental stop-and-reverse research reuse. If it is manually re-enabled for a future experiment, the default guard chain now also blocks alternating guarded reverse-loss whipsaws and requires a deferred displacement break followed by a controlled retest/hold of the broken level.

## Latest Default-Off Research Code

On 2026-07-13, the EA source gained a new default-off Flat Month Liquidity Reclaim lane tagged `FMLR;`.

Status:

- Not part of the current research-best profile.
- Not promoted.
- Not backtested yet.
- Added to both `Professional_XAUUSD_EA.mq5` and `outputs/Professional_XAUUSD_EA.mq5`.
- Offline package builder: `work/build_flat_month_liquidity_reclaim_probe_package.ps1`.
- Fast screen builder: `work/build_flat_month_liquidity_reclaim_fast_probe_package.ps1`, which prepares `162` Model4 configs before spending time on the full `480`-config package.
- Superseded default-off addition: optional FMLR failed-breakout trap was added as isolated profile `fmlr_failed_breakout_trap`, alongside the existing FMLR liquidity-reclaim, structural-retest, runner, and stop-pocket profiles. It fades a failed compression-box break only after snapback/reclaim confirmation, optional volume expansion, range-phase gating, forward target checks, and a stop behind the failed-break wick/box structure. Adaptive Reverse remains quarantined. Current FMLR packages now prepare `480` full configs and `162` fast configs after the later tick-speed and activity-blend package additions.
- No-new-input target refinement: failed-breakout traps now return the opposite side of the failed-break box as a structural range target and log `FMLR failed breakout target` / `FMLR failed breakout range target` when used.
- No-new-input target-priority refinement: generic FMLR liquidity targets no longer overwrite an accepted failed-breakout box target; the EA logs `FMLR liquidity target preserved` when that priority rule is active.
- No-new-input target-fallback refinement: if the failed-breakout box target is too close to satisfy the range-target minimum, the setup can use the existing forward-liquidity target instead of being rejected immediately. The EA logs `FMLR failed breakout target fallback` when this path is used.
- No-new-input forward-target selector refinement: `FlatMonthLiquidityReclaimForwardLiquidityDistance` now applies `minTargetDistance` before selecting the nearest target candidate, so a too-close liquidity level does not block a farther valid target.
- No-new-input forward-clearance selector refinement: the same helper now accepts `minimumCandidateDistance`, and the FMLR clearance gate passes its minimum clearance distance through it so a too-close level does not block a farther valid clearance level.
- No-new-input forward-RR target refinement: if structural stop widening makes an FMLR setup fail minimum RR, the EA can use an existing forward-liquidity target to repair RR only when that target still satisfies `InpFlatMonthLiquidityReclaimMinRR`; the EA logs `FMLR forward RR target`.
- No-new-input structural-target fallback refinement: if an HTF, opening-range, VWAP-deviation, or range-failure structural target is invalid or too close, the setup can use an existing valid forward-liquidity target instead of rejecting immediately. If no valid fallback exists, the original structural-target rejection remains; the EA logs `FMLR structural target fallback`.
- No-new-input structural-target priority refinement: if an HTF, opening-range, VWAP-deviation, or range-failure structural target is accepted, a generic forward-liquidity target can extend it when farther but cannot shrink it when closer; the EA logs `FMLR structural target preserved` or `FMLR structural target extended`.
- No-new-input protected-runner target-path refinement: FMLR runner-stretch protection now uses the shared `structuralTargetAccepted` flag instead of a duplicated structural-target list, so accepted VWAP-deviation structural targets count as protected runner paths.
- No-new-input runner-phase consistency refinement: FMLR runner phase permission now reuses the shared `structuralRunnerSetup` flag instead of a duplicated setup list, so session-range and compression breakout runner setups are not excluded by stale phase-gate logic.
- No-new-input structural-target runner eligibility refinement: accepted HTF, opening-range, VWAP-deviation, range-failure, and failed-breakout structural targets now qualify as `structuralTargetRunnerSetup` under the existing runner-stretch controls; the EA logs `FMLR structural target runner`.
- No-new-input structural-target unlimited-runner refinement: `FlatMonthLiquidityReclaimUnlimitedRunnerAllows` keeps the original strict sweep runner path and adds a structural-target runner path that requires both `FMLR structural target runner` and `FMLR forward clearance` evidence before allowing the no-fixed-TP FMLR runner.
- No-new-input unlimited-runner stretch-evidence refinement: FMLR no-fixed-TP runner permission now requires `runnerStretchEvidence`, meaning either `FMLR runner target stretch` or `FMLR runner liquidity stretch` must be present in the signal before the unlimited runner can open.
- No-new-input structure-trail broker-distance refinement: confirmed-swing FMLR structure trails now use `structureTrailMinDistance = MinimumBrokerStopDistance()` before accepting a trail stop, matching fallback-lock broker-distance realism.
- No-new-input structural-fallback runner refinement: structural-target fallback setups that use a valid forward-liquidity target can now qualify as protected structural runner setups; the EA logs `FMLR structural fallback runner` before the shared structural-runner marker when this path participates.
- No-new-input FMLR catch-up threshold refinement: `activeFmlrMinScore` and the active FMLR minimum RR now use the existing flat-month, catch-up, and late-catch-up discounts inside the FMLR lane itself; the EA logs `FMLR active min score` and `FMLR active min RR` when the lane threshold is relaxed.
- No-new-input FMLR catch-up risk refinement: `ActiveFlatMonthLiquidityReclaimRiskMultiplier()` lets FMLR ramp from `InpFlatMonthLiquidityReclaimRiskMultiplier` toward the existing `InpFlatMonthProbeRiskMultiplier` cap only when the existing catch-up risk ramp/protected-floor/liquid-session gates allow it; the EA logs `FMLR active risk x`. The isolated `fmlr_catch_up_risk` package profile now tests this path in the 480-config full package and the 162-config fast screen.
- No-new-input FMLR equal-level stop-pool refinement: if an equal-high/low structural stop anchor is selected and the existing FMLR stop-cluster buffer is enabled, the EA treats that two-touch level as liquidity-pool evidence and can add the existing extra stop buffer before RR is checked; the EA logs `FMLR equal-level stop pool`. Source hash: `24698D8AB5D799275958AF9369EF6949D114F12DE5E2013BC423F655DDEC4ABA`.
- No-new-input FMLR catch-up cadence refinement: FMLR now computes catch-up/late-catch-up state before checking lane cap and spacing. Existing late-catch-up controls can raise the active FMLR monthly cap, and catch-up progress can reduce active FMLR spacing by up to 50% with a 30-minute floor; the EA logs `FMLR active monthly cap` and `FMLR active spacing`. Source hash: `842EB39FC61E3FC1329DB7F272F65D6B722AA556CF7C04D77DD15C6335A769BD`.
- No-new-input shared structure-stop refinement: equal-high/low liquidity stop anchors now pass confirmed equal-level evidence into the shared `LiquidityClusterAdjustedBuffer()` helper, so the broader `StructureStopDistance()` path can use the existing cluster extra buffer without re-proving the same two-touch pool. Source hash: `E83C7A92A8757B100361A9A17CFB6445102CD5D6DE3E87F6C323CF61516457E3`.
- No-new-input shared previous-period stop-pocket refinement: `LiquidityPocketStopLevel()` now also checks enabled previous-day/week/month liquidity stop levels when the existing liquidity-pocket stop shift is active. This lets shared structural stops move beyond higher-timeframe liquidity pockets instead of sitting inside them. Source hash: `778E168D96A8185FBA8781210794A6B4547341D4D95F0470134EAC4E5F72C38F`.
- No-new-input FMLR protected-loss catch-up refinement: FMLR can request a protected catch-up version of the flat-month opportunity gate during shallow red months, while normal flat-month lanes still honor `InpFlatMonthRequireNoMonthlyLoss`. The exception is capped by existing monthly-loss/catch-up settings and still respects protected-floor and liquid-session requirements; the EA logs `FMLR protected loss catch-up`. Source hash: `686F80DA9CB4DE36E564C47A5C3AE4B5A6CAF62B8BF90250729E9FF751602CDF`.
- No-new-input FMLR sweep-runner target refinement: non-structural liquidity-sweep reclaims can now use the existing runner-target stretch path when forward liquidity, sweep evidence, and quality confirmation exist; the EA logs `FMLR sweep runner` only when the target actually stretches. Source hash: `10D1007CFD4CB124C8DE6EC247E1DE1611F1A7955E4E8EC2F9816B2A238DFA04`.
- No-new-input FMLR sweep-runner package refinement: added isolated `fmlr_sweep_runner` validation profile to exercise the non-structural sweep-runner payoff path without requiring sweep-displacement BOS. Superseded package size after the sweep-unlimited runner addition: full package `444` Model4 configs / `37` profiles; fast screen `144` Model4 configs / `24` profiles.
- No-new-input FMLR sweep unlimited runner refinement: no-fixed-TP FMLR runner permission now recognizes proven non-structural sweep-runner setups when forward clearance, runner-stretch evidence, and FMLR structure trailing are present. The entry log can add `FMLR sweep unlimited runner`. Added isolated `fmlr_sweep_unlimited_runner` package profile.
- Default-off FMLR tick-speed reclaim refinement: FMLR can now tag `FMLR tick-speed reclaim` when an existing sweep/reclaim context is followed by a directional tick-speed impulse through `InpUseTickSpeedImpulse`. Added isolated `fmlr_tick_speed_reclaim` package profile. Source hash: `B6AA1915D2CA7483B1066C227F2506D7A85756D918820FF1100BAF66B0FBDBBE`.
- FMLR flat-month activity-blend package refinement: added `fmlr_activity_blend` and `fmlr_activity_blend_tight` package profiles. They combine already-protected FMLR structural triggers at tiny risk, require order flow, forward clearance, liquidity targets, stop-pocket/cluster structural stops, and keep Adaptive Reverse disabled. No MT5 profit result yet.
  - `outputs/CANDIDATE_FMLR_ACTIVITY_BLEND_PROFILE.set`: `149481621EC3194A08CF2B291033FEA38AE7D40B1EDA677820780A51F9A9DBDB`
  - `outputs/CANDIDATE_FMLR_ACTIVITY_BLEND_TIGHT_PROFILE.set`: `50F2000B153458B5DB494DD6AA873BDD6256F2C8B3AE11BABE5E4C615E2BC67A`
- Money-ready demo/forward-test candidate: `outputs/CANDIDATE_MONEY_READY_PROFILE.set`, SHA-256 `2A16CEEC337981A925D933C95AD42526A61DDE7CA1EB583FDD597BCC83F2E250`. The alias `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set` has the same hash. This candidate enables the EA symbol, trade-readiness, real-account, and trade-environment safety gates, caps risk at `0.50%`, caps open risk at `0.75%`, caps lots at `0.05`, allows one position, blocks real-account trading by default, keeps Adaptive Reverse/FMLR/tick-speed experiments off, stamps evidence identity, keeps live approval identity disabled, and requires spread, trading-cost, margin, loss, profit-giveback, break-even, ATR trailing, MFE protection, sane symbol specs, fresh quotes, and available tick value. This is demo/forward-test only and does not replace the current research-best profile.
- Conservative trade-ready candidate: `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`, SHA-256 `F708C68A68016C13C4ADAECFE472A270748F4DAD9F2DF8C12F9870C2324DA13F`. The first-pass validation queue, next-run package, and parallel lanes were rebuilt on 2026-07-14 from this current profile hash.
- Source-level trade-readiness safety gate: `InpUseTradeReadinessSafetyGate` refuses initialization when enabled if the profile is loosened past configured risk/spread/margin/exit caps. `TradeEnvironmentAllows()` blocks new entries when enabled if quotes, history, symbol specs, trade mode, broker stop/freeze levels, or tick value are unsafe. `SymbolSafetyLockAllows()` blocks wrong-symbol initialization, and `RealAccountSafetyLockAllows()` blocks real-account initialization unless the lock remains enabled plus explicit approval code, approval profile id, approval source hash, evidence profile id/source hash, evidence run label, and trade-readiness gate requirements are all satisfied. Current source hash: `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`.
- Evidence identity refinement: trade logs now include `profile_id`, `source_hash`, and `run_label`; conservative returned logs are expected to prove `profile_id=trade_ready_conservative` and `source_hash=FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394` before trade-quality or Monte Carlo evidence is trusted.
- Money-ready audit: `outputs/MONEY_READY_PROFILE_AUDIT.md` reports `79` guardrail/prep checks passing, `0` critical failures, and `4` open proof gaps: exact Model4 real-tick backtest, forward test, Monte Carlo execution stress, and broker-variation testing.
- Money-ready validation package: `outputs/money_ready_validation_package` is prepared with `53` staged configs: `4` fast Model1 checks, `4` exact Model4 continuous/year-split checks, `11` real-tick quarterly checks, `31` real-tick monthly checks, and `3` real-tick stress variants. This package is not run yet because the local MT5 launch lock remains active.
- Money-ready broker-proxy package: `outputs/money_ready_broker_proxy_package` is prepared with `10` Model4 configs across base, wide-spread, high-commission, tight-slippage, and margin-pressure proxies. This approximates broker variation through EA cost/spread/margin inputs but still does not replace testing on another broker's actual XAUUSD contract.
- Money-ready decision gate: `outputs/MONEY_READY_VALIDATION_DECISION.md` is currently `PENDING` with `1` passing prep gate, `16` pending result gates, and `0` failures because `outputs/MONEY_READY_VALIDATION_RESULTS.csv` and `outputs/MONEY_READY_BROKER_PROXY_RESULTS.csv` have not been returned yet. The gate will fail automatically on red exact Model4 splits, red quarterly/monthly windows, stress losses, broker-proxy losses, drawdown above `10%`, weak PF/recovery, or too few continuous trades.
- Conservative trade-ready Monte Carlo gate: `outputs/TRADE_READY_CONSERVATIVE_MONTE_CARLO.md` is prepared and currently `PENDING` with `1000` seeded trials, `0` returned trade-log files, `0` R trades, `3` pending gates, and `0` failures. It will stress returned conservative logs by shuffling trade order and applying slippage, delay, spread-shock, and missed-winner degradation.
- Conservative trade-ready external evidence gates: `outputs/TRADE_READY_CONSERVATIVE_FORWARD_TEST.md` and `outputs/TRADE_READY_CONSERVATIVE_SECOND_BROKER_DECISION.md` are prepared and currently `PENDING` with `0` returned evidence rows. They evaluate returned CSV evidence only and do not launch MT5.
- Conservative trade-ready live-readiness gate: `outputs/TRADE_READY_LIVE_READINESS_DECISION.md` is the final approval gate for the conservative candidate and is currently `PENDING` with `7` passing gates, `7` pending gates, and `0` failures. Current-source compile and GitHub publication now pass for A167/D045. It does not unlock real-account trading; full conservative validation, efficiency, trade quality, Monte Carlo, forward/demo, second-broker, and remaining conservative-audit proof are still required.
- Compact-source prep: `work/prepare_flat_month_liquidity_reclaim_compact_source.ps1`.
- Source smoke: `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`.
- Source/artifact sync smoke: `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`.
- Package-builder smoke: `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`.
- Fast package-builder smoke: `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`.
- Compact-source smoke: `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`.
- Adaptive Reverse quarantine smoke: `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`.
- Monte Carlo trade-stress smoke: `MONTE_CARLO_TRADE_STRESS_SMOKE_PASS`.
- External evidence smoke: `TRADE_READY_EXTERNAL_EVIDENCE_SMOKE_PASS`.
- Trade-ready live-readiness smoke: `TRADE_READY_LIVE_READINESS_SMOKE_PASS`.
- Hidden-launcher lock smoke: `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`.
- MT5 local safety audit: `PASS 44 / 44`.
- Compile/backtest: pending while `work/MT5_LOCAL_LAUNCH_DISABLED.lock` remains active.

Research note:

`research/2026-07-13-flat-month-liquidity-reclaim-lane-note.md`

Additional source-refinement note:

`research/2026-07-13-fmlr-structure-trail-broker-distance-note.md`

`research/2026-07-13-fmlr-structural-fallback-runner-note.md`

`research/2026-07-13-fmlr-catch-up-threshold-note.md`

`research/2026-07-13-fmlr-catch-up-risk-note.md`

Structural-stop note:

`research/2026-07-13-fmlr-structural-stop-pocket-note.md`

Session/Asian reclaim note:

`research/2026-07-13-fmlr-session-asian-reclaim-note.md`

Equal-level reclaim note:

`research/2026-07-13-fmlr-equal-level-reclaim-note.md`

Swing-sweep reclaim note:

`research/2026-07-13-fmlr-swing-sweep-reclaim-note.md`

Previous-period reclaim note:

`research/2026-07-13-fmlr-previous-period-reclaim-note.md`

Daily-open reclaim note:

`research/2026-07-13-fmlr-daily-open-reclaim-note.md`

Higher-open reclaim note:

`research/2026-07-13-fmlr-higher-open-reclaim-note.md`

Open stop-pocket note:

`research/2026-07-13-fmlr-open-stop-pocket-note.md`

Open liquidity target note:

`research/2026-07-13-fmlr-open-liquidity-target-note.md`

Continuation-retest note:

`research/2026-07-13-fmlr-continuation-retest-note.md`

Compression-breakout note:

`research/2026-07-13-fmlr-compression-breakout-note.md`

Session-range breakout note:

`research/2026-07-13-fmlr-session-range-breakout-note.md`

Opening-range reclaim note:

`research/2026-07-13-fmlr-opening-range-reclaim-note.md`

VWAP-deviation reclaim note:

`research/2026-07-13-fmlr-vwap-deviation-reclaim-note.md`

Fast validation package note:

`research/2026-07-13-fmlr-fast-validation-package-note.md`

Engulfing-reclaim note:

`research/2026-07-13-fmlr-engulfing-reclaim-note.md`

Tick-pressure reclaim note:

`research/2026-07-13-fmlr-tick-pressure-reclaim-note.md`

Breakout-retest note:

`research/2026-07-13-fmlr-breakout-retest-note.md`

Failed-breakout-trap note:

`research/2026-07-13-fmlr-failed-breakout-trap-note.md`

Sweep-displacement BOS note:

`research/2026-07-13-fmlr-sweep-displacement-bos-note.md`

Range-failure reclaim note:

`research/2026-07-13-fmlr-range-failure-reclaim-note.md`

HTF liquidity reclaim note:

`research/2026-07-13-fmlr-htf-liquidity-reclaim-note.md`

Imbalance-continuation note:

`research/2026-07-13-fmlr-imbalance-continuation-note.md`

Runner-target stretch note:

`research/2026-07-13-fmlr-runner-target-stretch-note.md`

Sweep-runner package profile note:

`research/2026-07-13-fmlr-sweep-runner-profile-note.md`

Sweep unlimited runner note:

`research/2026-07-13-fmlr-sweep-unlimited-runner-note.md`

Structural-runner trail note:

`research/2026-07-13-fmlr-structural-runner-trail-note.md`

Adaptive Reverse quarantine note:

`research/2026-07-13-adaptive-reverse-quarantine-note.md`

## Latest Rejected Probes

Block diagnostics, month-filter bypass, and March/May risk-shape probes were tested on 2026-07-12 and rejected.

Summary:

| Profile | Continuous | 2026 YTD | Full 2025 | Worst Window | Losing Windows | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `current` | `+1,195.69` | `+955.21` | `+214.30` | `+214.30` | `0` | `30.9408` |
| `mar200_may220` | `+993.28` | `+1,238.40` | `+105.51` | `-196.16` | `1` | `28.6598` |
| `mar175_may280` | `+464.46` | `+1,032.92` | `-8.60` | `-8.60` | `2` | `30.9408` |
| `mar150_may280` | `+395.91` | `+901.82` | `-8.35` | `-8.35` | `2` | `30.9408` |
| `mar150_may240` | `+395.91` | `+931.99` | `-8.35` | `-8.35` | `2` | `35.9388` |
| `mar125_may280` | `+73.92` | `+691.74` | `+262.02` | `-122.22` | `1` | `30.9408` |

Month-filter bypass summary:

| Profile | Total Net | Active Windows | Losing Windows | Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: |
| `current` | `+508.07` | `3` | `0` | `6` | `30.9408` |
| `highpa_q5_pa24` | `+508.07` | `3` | `0` | `6` | `30.9408` |
| `fsd_q6_pa18` | `+434.29` | `6` | `3` | `9` | `30.9408` |
| `combo` | `+434.29` | `6` | `3` | `9` | `30.9408` |

Decision:

Do not promote. FSD bypass added losing trades; high-price-action bypass changed nothing; March/May risk scaling either reduced continuous profit or introduced losing windows.

Research note:

`research/2026-07-12-block-diagnostics-and-risk-shape-note.md`

Liquidity-stop extension variants were tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `lstop_cluster` | `12 / 12` | `3` | `9` | `+387.68` | `0` | `5` | `31.7511` |
| `lstop_cluster_pocket` | `12 / 12` | `3` | `9` | `+122.50` | `0` | `5` | `29.0642` |
| `lstop_prevday` | `12 / 12` | `2` | `10` | `-90.55` | `1` | `2` | `16.4294` |

Decision:

Do not promote. The current base liquidity-aware structure stop is already active and remains better than the extra cluster / previous-day / pocket extensions.

Research note:

`research/2026-07-12-liquidity-stop-extension-probe-note.md`

Flat-month wake-up and flat-month probe-mode reality checks were tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmw_wake_strict` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmw_wake_balanced` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmw_stale_elite` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmp_strict_low_risk` | `12 / 12` | `3` | `9` | `+453.17` | `0` | `6` | `30.9408` |
| `fmp_quality_ramp` | `12 / 12` | `3` | `9` | `+453.17` | `0` | `6` | `30.9408` |
| `fmp_tiny_discovery` | `12 / 12` | `2` | `10` | `+444.02` | `0` | `5` | `30.9408` |

Decision:

Do not promote. Wake-up tied current; probe-mode reduced existing winners and did not create useful new flat-month trades.

Research notes:

- `research/2026-07-12-flat-month-wakeup-probe-note.md`
- `research/2026-07-12-flat-month-probe-mode-reality-note.md`

Flat-month micro-reversion expansion was tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmr_expand_strict` | `12 / 12` | `4` | `8` | `+484.43` | `1` | `7` | `30.9408` |
| `fmr_expand_soft` | `12 / 12` | `5` | `7` | `+477.12` | `2` | `8` | `30.9408` |

Decision:

Do not promote. The expanded candidates increased activity, but the added trades were losers in `2025_04` and `2026_01`.

Research note:

`research/2026-07-12-flat-month-micro-reversion-expansion-probe-note.md`

Flat-month breakout structural and activation probes were tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmb_struct_conservative` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmb_struct_balanced` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmb_activation_tape` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmb_activation_loose` | `12 / 12` | `5` | `7` | `+490.65` | `2` | `8` | `30.9408` |
 
Decision:

Do not promote. Conservative and balanced FMB tied current; loose activation created extra trades but lowered total net and added losing windows.

Research notes:

- `research/2026-07-12-flat-month-breakout-structural-probe-note.md`
- `research/2026-07-12-flat-month-breakout-activation-probe-note.md`

Flat-month FSD efficiency relaxation was tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |
| `fsd_relaxed_48h` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |
| `fsd_relaxed_24h` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |

Decision:

Do not promote. The relaxation did not add active windows, reduce zero-trade windows, or improve net profit.

Research note:

`research/2026-07-12-fsd-efficiency-relaxation-probe-note.md`
