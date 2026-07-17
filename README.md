# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

This is not a martingale, grid, averaging-down, or recovery-system bot. Risk control stays above profit chasing. Heavy optimization and validation should run locally, hidden in the background, not in GitHub Actions.

## Latest Status

### Latest Research Update - 2026-07-16

**No new best was promoted. The frozen three-lane `0.50%` profile remains the stability benchmark, and real-account trading remains disabled.**

The high-profit DGF adverse-exit branch reached `+$15,023.66`, `+19.94%/yr`, PF `1.65`, and `14.77%` drawdown in continuous Model 1, but annual restarts exposed losses in 2021 (`-$752.15`, PF `0.42`), 2023 (`-$787.59`, PF `0.60`), and 2025 (`-$635.39`, PF `0.57`). Loss quarantine, hard liquidity isolation, and a frozen 220-row market-feature screen produced no survivor, so Model 4 was correctly skipped. See `outputs/DGF_ADVERSE_EXIT_RISK_DECISION.md`.

The exact three-lane stability source was then tested at `0.50%`, `0.65%`, `0.80%`, and `1.00%` base risk. The `0.50%` control remained best at `+$545.91`, `+0.47%/yr`, PF `2.83`, `57` trades, `0.77%` drawdown, and `6.79` recovery in continuous 2015-2026 Model 1. Higher risk did not improve growth: `0.65%` was dominated, while `0.80%` and `1.00%` triggered the account profit-trail review lock and stopped after only 8-11 continuous trades. The safeguard was not weakened to manufacture a larger result. See `outputs/THREE_LANE_GROWTH_RISK_LADDER_DECISION.md`.

A standalone London/New York opening-range breakout strategy was also built and compiled cleanly, then screened without using 2021-2026. All six variants lost in the independent 2019-2020 discovery era, with PF from `0.33` to `0.74`; every continuous candidate also crossed the `5%` drawdown review lock. The entire branch was rejected before recent holdout or Model 4 testing. See `outputs/INDEPENDENT_ORB_DISCOVERY_DECISION.md`.

A broker-accurate H4 Donchian channel-trend strategy then produced a genuine 2015-2020 discovery plateau: the strongest frozen profile made `+$328.77`, PF `2.12`, on `76` trades with `0.76%` drawdown. It decisively failed its predeclared 2021-2026 strategy-specific holdout. All `36 / 36` reports completed, but every frozen profile produced only one holdout trade, with no trades at all in 2021, 2022, 2024, 2025, or 2026 YTD. A no-trading broker-native diagnostic confirmed the cause: at `$10,000` and `0.10%` risk, only `0.42%-0.86%` of 2021+ H4 breakout signals across the tested lookbacks could safely trade the broker's `0.01`-lot minimum. For 2026 signals, minimum required equity was `$64,280` and median required equity was `$87,310`. The EA correctly refuses those trades instead of oversizing them. The family was rejected without Model 4 or post-holdout retuning, and an automatic capital-feasibility gate now blocks similarly impossible profiles before expensive testing. See `outputs/INDEPENDENT_H4_CHANNEL_TREND_DECISION.md` and `outputs/XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_GATE.md`.

A lower-timeframe M30 structure-stop channel family then solved the activity and minimum-lot problem, but **did not produce a new best**. Six neighboring profiles were positive in both 2015-2018 and 2019-2020 discovery; the lead made `+$547.52`, PF `1.49`, on `239` trades with `2.34%` drawdown. Four profiles were frozen before opening 2021-2026. All four failed: continuous holdout results ranged from `-$64.28` to `-$217.49`, PF `0.81-0.92`, with `197-276` trades, and every profile lost across 2021-2023. The family was active, so this is an expectancy/generalization failure rather than missing trades. Model 4 and holdout retuning were correctly skipped. See `outputs/INDEPENDENT_M30_STRUCTURE_CHANNEL_DECISION.md`.

A distinct M15 BOS/displacement/FVG-retest family was then screened entirely on 2015-2020 discovery data and also **did not produce a new best**. All `30 / 30` reports completed. Every one of the ten neighboring variants lost in both 2015-2018 and 2019-2020; continuous results ranged from `-$477.65` to `-$507.19`, PF `0.24-0.59`, with `102-196` trades, and all reached approximately the `5%` drawdown review lock. The family was rejected before opening 2021-2026 or spending time on Model 4, so the future boundary remains untouched. See `outputs/INDEPENDENT_M15_FVG_RETEST_DECISION.md`.

Independent scheduling for the existing H1 Band/VWAP reversion lane was tested next and also **did not produce a new best**. All `45 / 45` Model 1 discovery reports completed using only 2015-2020. The exact control made `+$252.65`, PF `4.76`, on `15` trades with `0.77%` drawdown. The best candidate headline rose to `+$286.76`, but neither disjoint broad era improved, PF fell to `3.43`, drawdown rose to `1.09%`, and the active losing years 2017 and 2019 became worse. All four independent-scheduling variants were rejected before recent implementation validation or Model 4; the switch remains default off and the frozen three-lane best is unchanged. See `outputs/REVERSION_INDEPENDENT_DISCOVERY_DECISION.md`.

Trade-level review then found that the first implementation's two-position limit also admitted five extra primary-lane entries, so a corrected V2 reserved one slot for primary strategies and one for H1 reversion. The clean V2 run returned and parsed `45 / 45` fresh reports and proved exact primary-entry compatibility: the lead added six H1 trades and zero primary trades. It still **did not produce a new best**. `ri2_m10_r30` improved continuous net from `+$252.65` to `+$279.90` and drawdown from `0.77%` to `0.72%`, but 2019-2020 fell from `+$108.33` to `+$104.88`, PF fell from `4.76` to `3.56`, 2017 worsened from `-$3.29` to `-$17.15`, and 2019 worsened from `-$3.13` to `-$12.52`. All four corrected variants failed the registered cross-era and annual gates; recent data and Model 4 remained closed. See `outputs/REVERSION_INDEPENDENT_V2_DISCOVERY_DECISION.md`.

This means the answer is still honest: the project has a low-drawdown research candidate, but not a high-return money-ready bot. The next evidence must come from frozen forward testing, more independent trades, and genuinely independent strategy activity rather than more fitting of the 2024-now period.

### Authoritative Current-Source Status - 2026-07-16

**Verdict: research-only, not money-ready, and not approved for live trading.** Real-account trading remains hard-locked.

- Maintained EA source SHA-256: `A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622`
- Best current-source risk-first candidate: `outputs/CANDIDATE_MONEY_READY_PROFILE.set`
- Candidate profile SHA-256: `D0459197F2A8CA1385F139694BD036AA9A3A596BB406F7D4474CDC8444605C79`
- Starting balance for the results below: `$10,000`

| Test | Net | Total return | Annualized | CAGR | PF | Trades | Max equity DD | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Model4 real ticks, 2019-2026 | `+$321.59` | `+3.22%` | `+0.43%/yr` | `+0.42%/yr` | `2.81` | `32` | `0.59%` | `5.32` |
| Model1, 2019-2026 | `+$397.53` | `+3.98%` | `+0.53%/yr` | `+0.52%/yr` | `2.77` | `37` | `0.66%` | `5.72` |
| Model1, 2024-2026 YTD | `+$79.21` | `+0.79%` | `+0.31%/yr` | `+0.31%/yr` | `1.64` | `12` | `0.68%` | `1.14` |

### New Provisional Three-Lane Research Best - 2026-07-16

**Verdict: higher-profit demo forward-test candidate, not money-ready. The two-lane build remains the stability benchmark.** Maintained A167 and the real-account lock are unchanged.

- Three-lane source SHA-256: `45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90`
- DDB 0.45 profile SHA-256: `2E02246D24250D71DEC59A42AD1D7DE793614EBECEB309A879FE873D8F886312`
- Compile: `0 errors, 0 warnings`

| Test | Tick quality | Net | Total return | Annualized | CAGR | PF | Trades | Max DD | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Three-lane, 2015-2026 continuous | `65% real ticks` | `+$526.20` | `+5.26%` | `+0.46%/yr` | `+0.45%/yr` | `3.26` | `51` | `0.77%` | `6.54` |
| Three-lane, 2019-2026 continuous | `99% real ticks` | `+$380.23` | `+3.80%` | `+0.51%/yr` | `+0.50%/yr` | `2.80` | `46` | `0.78%` | `4.73` |
| Two-lane matched control, 2019-2026 | `99% real ticks` | `+$347.94` | `+3.48%` | `+0.46%/yr` | `+0.46%/yr` | `2.80` | `42` | `0.59%` | `5.75` |

On the high-quality matched window, the third lane adds `$32.29` (`+9.28%`) and four trades, but drawdown rises and recovery falls. The older 2015-2018 window has `0% real ticks`, so the 11-year result is broad modeled-tick evidence, not an all-real-tick profit claim.

Neighboring Donchian allocations from `0.40x` through `0.60x` remained profitable in every broad Model1 era. Restarted yearly Model4 had 10 positive years, one flat/no-trade year, and one loss (`2017: -$3.29`), with `0.59%` worst yearly drawdown. The 10,000-trial realized-R stress stayed profitable even in its worst trial (`+19.20R`) but failed strict tail-risk gates at `6.56R` p95 drawdown and a seven-loss p95 streak.

Same-broker execution sensitivity passed `5 / 5` Model4 proxies. The high-commission guard was the harshest at `+$326.98`, `+0.43%/yr`, PF `2.54`, and `0.83%` drawdown; wide-spread and tight-slippage proxies made `+$342.84`, PF `2.60`, with `0.88%` drawdown. This strengthens the candidate but does not close the actual second-broker gate.

The frozen forward clock now starts after `2026-07-12`. Its first cumulative Model4 checkpoint (`2026-07-13` through `2026-07-16`) used `100%` real ticks across `264` bars and `1,797,592` ticks, but produced `0` trades. This is **insufficient evidence**, not a pass or a loss; source and settings remain unchanged. See `outputs/THREE_LANE_DDB045_FORWARD_REGISTRATION.md`.

Exact decision and result files: `outputs/THREE_LANE_DDB045_DECISION.md`, `outputs/THREE_LANE_DDB045_BROKER_PROXY_DECISION.md`, `outputs/THREE_LANE_DDB045_COMPARISON.csv`, `outputs/THREE_LANE_DDB045_MODEL4_VALIDATION_RESULTS.csv`, `outputs/THREE_LANE_DDB045_YEARLY_MODEL4_RESULTS.csv`, and `outputs/THREE_LANE_DDB045_MONTE_CARLO.csv`.

This is the best **current-source trade-readiness candidate**, not a new profit best. Its drawdown is low and every active Model4 year from 2020 through 2026 YTD was positive, but the evidence is much too sparse: only `32` real-tick trades in about 7.5 years, and 2025 made only `+$8.80` with PF `1.26`.

**Will fitting 2024-now work automatically in the future? No.** The exact profile took `0` trades in every 2015-2018 Model1 diagnostic window. That is a minimum-activity and regime-coverage failure. Recent data helps measure current behavior, but it cannot prove that the same rules will survive a future volatility, liquidity, spread, broker, or trend-regime change.

The realized-R Monte Carlo tests also remain failed. Both 10,000-trial stresses produced a 95th-percentile loss streak of `7`; the severe stress had a `+7.95R` 5th-percentile result but a `-0.16R` worst trial. A second broker, frozen demo-forward evidence, more independent trades, walk-forward testing, and a strategy that is active across older regimes are mandatory before any live review.

An earlier independent M15 Bollinger/VWAP reversion strategy did **not** become a new best. Its best continuous Model1 row made only `+$11.80`, PF `1.29`, on `28` trades and still took zero trades in 2015-2018. The experiment was rejected and removed from the maintained source.

The latest daily Donchian breakout experiment also produced **no new best**. Its strongest standalone channel-exit profile reproduced on continuous 2015-2026 Model4 real ticks at `+$438.43`, `+0.38%/yr`, PF `1.41`, `51` trades, and `3.77%` drawdown, with every era positive. That is useful cross-regime evidence, but 2019-2022 made only `+$27.75`, PF `1.07`. Adding the lane to the current candidate reduced continuous Model1 net from `+$397.53` to `+$255.38` and made 2015-2018 lose `-$22.74`, so the combined profile was rejected and exact maintained source was restored. See `outputs/DAILY_DONCHIAN_BREAKOUT_DECISION.md`.

The long-only Donchian follow-up was also **rejected after yearly validation**. A real broad-era plateau appeared, led by `+$887.48`, `+0.77%/yr`, PF `1.99`, `40` trades, and `3.64%` drawdown for the 20-day/EMA-150/1.25-ATR shape. However, all `60 / 60` yearly reports showed that every neighboring profile lost in four or five active years; the lead had five losing years and a `-$95.92` aggregate restart-window score. No Model4 time was spent after that failure. See `outputs/DAILY_DONCHIAN_LONG_ONLY_DECISION.md`.

The Donchian entry-feature follow-up was **rejected without opening its 2021-2026 feature holdout**. An isolated Model1 run reproduced `51` trades at `+$440.14`, PF `1.41`, and `3.77%` drawdown while logging date-independent trend, price-action, volatility, and volume features. On the frozen 2015-2020 discovery set, the only gates passing every activity/profit/PF/drawdown/year rule were no-ops; a separately declared false-breakout extension returned `0` eligible gates. Maintained source/profile remain unchanged. See `research/2026-07-16-daily-donchian-feature-gate-rejection.md`.

The liquid-hours DGF weak-hour and volatility-floor follow-up was also **rejected**. Source reproduction proved that two missing 2019 winners were caused by a source/profile contract change, not broker-history drift: a spread floor that used to be fixed at `50` began honoring the profile's `30` value. A new default-off DGF minimum-ATR gate then produced a smooth `99 / 99` Model1 plateau, led by `+$791.43`, PF `1.82`, `123` trades, and `1.19%` drawdown with zero red fast-model years. The improvement did not survive the `12 / 12` focused Model4 gate. The best real-tick row made only `+$631.54`, `0.84%/yr`, and still lost `-$9.68` in 2019; the only positive-2019 row fell to `+$400.15`, PF `1.55`. No new best was promoted and the experimental code was removed. See `outputs/DGF_VOLATILITY_FLOOR_DECISION.md`.

The first exact trade-stream portfolio screen was also **rejected before combined-EA implementation**. A realized-R simulation tested `900` risk-weight blends of the maintained candidate, the 127-trade high-profit branch, and the independent daily Donchian branch under a `3%` open-risk cap. The strongest near-miss reached `+$9,798.58`, `8.50%/yr`, `6.10%` CAGR, PF `2.185`, `210` trades, and a conservative `6.57%` risk-floor drawdown. It still had red 2017 and 2019, `28` negative rolling 12-month windows, and three red years after a `0.05R`-per-trade stress. Two Donchian repair screens returned `24 / 24` and `36 / 36` reports but no profile repaired 2017 without also failing 2023. No combined bot was promoted. See `outputs/STRATEGY_PORTFOLIO_DECISION.md`.

The new H1 Bollinger/VWAP reversion lane is the strongest independent broad-history component found so far, but it is **not a new maintained best**. A real Model1 plateau survived continuous Model4: ADX `22` made `+$440.63`, `+0.38%/yr`, PF `2.36`, on `41` trades with `1.10%` drawdown; ADX `24` and its stricter-wick neighbor made `+$332.39` and `+$315.70` with PF `1.59-1.62` and `1.27%` drawdown. The leader still lost in 2016 (`-$9.70`), 2020 (`-$32.28`), and 2024 (`-$2.65`), with 2019 inactive. A `700`-row exact realized-R portfolio screen found no blend with zero red years in both base and cost stress. The source/profile are frozen as a research component; maintained A167 and the real-account lock are unchanged. See `outputs/HTF_BAND_REVERSION_DECISION.md`.

The strongest three-stream analytical near-miss (`7.37%` CAGR, PF `2.303`, `5.98%` conservative risk-floor drawdown) is **not a combined MT5 result**. It sums separately tested high-profit, maintained, and H1-reversion trade streams. Those profiles differ in `194` input contracts, and the current open-risk guard is magic-number scoped, so the figure must not be treated as a deployable single bot or live account forecast. A shared account-wide risk governor and true interaction test are required before this portfolio can advance.

The first guarded common-executable prototype was **rejected by matched source controls**. On the same `$10,000`, 2019-2026 Model1 test, the actual `8D62...` high-profit implementation made `+$30,050.33`, PF `1.95`, on `116` trades with `20.44%` drawdown; the proposed common source made only `+$211.03`, PF `1.12`, on `124` trades. The profile's older declared `F254...` source lost `-$1,647.34`, proving that its source label was stale and that these implementations are not behaviorally interchangeable. The historical high-profit and maintained profiles also collide on magic number `26070402`. No shared bot was promoted; the next attempt must guard each exact source independently, use unique magic numbers, and reproduce guard-off behavior before combined testing. See `outputs/PORTFOLIO_COMMON_EXECUTABLE_DECISION.md`.

The isolated two-lane follow-up is a **new low-drawdown demo forward-test candidate, not a new profit best**. It keeps the maintained M15 lane and H1 Bollinger/VWAP lane on separate signal clocks and execution paths while sharing account-wide risk limits. The conservative `risk010` profile passed every broad Model4 real-tick window: continuous 2015-2026 YTD made `+$361.04`, `+0.31%/yr`, PF `2.83`, on `45` trades with `0.58%` drawdown; older, middle, and recent eras made `+$13.10`, `+$185.00`, and `+$148.64`. All `12 / 12` restarted yearly Model1 reports returned; the worst year was only `-$3.39`, but the sample remains sparse and the older era had just three trades. It is frozen for unseen demo-forward evidence after `2026-07-12`; maintained A167 and the real-account lock remain unchanged. See `outputs/TWO_LANE_ISOLATED_EXECUTION_DECISION.md`.

Current decision record: `outputs/MONEY_READY_BALANCED_DECISION.md`. Exact result tables: `outputs/MONEY_READY_BALANCED_REALTICK_RESULTS.csv`, `outputs/MONEY_READY_BALANCED_BROAD_RESULTS.csv`, and `outputs/MONEY_READY_BALANCED_YEARLY_REALTICK_RESULTS.csv`.

### Prior Research Chronology

The material below is retained to show what was tested and rejected. Older profit headlines and profile labels do not override the authoritative current-source status above.

**Current 2019-2026 recent-regime best:** maintained source hash `62C2F0B2397AE9992CA2B156ED1A2AA45D0F874DD3803CEA9F74EB15882B3DDE` exactly reproduces the date-independent DGF recent-loss-memory candidate originally established under source `F1935B74...`. It passed the 2019-2026 yearly Model1 gates and continuous Model4 testing from 2019-01-01 through 2026-07-12. A later 2015-2018 holdout showed that this is not a broad-history stability result.

| Profile | Model4 net | Total return | Annualized | CAGR | PF | Trades | Max DD | Recovery | Current role |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Liquidity DGF, 08:00-10:59 | `+$721.13` | `+7.21%` | `+0.96%/yr` | `+0.93%/yr` | `2.68` | `58` | `1.03%` | `6.70` | Higher-profit stability candidate |
| Adaptive liquidity DGF, 09:00-10:59 | `+$667.94` | `+6.68%` | `+0.89%/yr` | `+0.86%/yr` | `3.63` | `40` | `0.67%` | `9.44` | **Best risk-adjusted 2019-2026 candidate; older holdout inactive** |
| Liquidity DGF, 09:00-10:59 | `+$644.36` | `+6.44%` | `+0.86%/yr` | `+0.83%/yr` | `3.30` | `43` | `0.80%` | `7.58` | Frozen non-adaptive control |
| Liquidity + execution DGF, 08:00-10:59 | `+$425.39` | `+4.25%` | `+0.57%/yr` | `+0.56%/yr` | `2.27` | `47` | `1.17%` | Validated but dominated |

The adaptive strategy made `+$658.58` in Model1 and `+$667.94` in Model4, so model disagreement is small. The original frozen evidence profile is `outputs/CANDIDATE_SESSION_ADAPTIVE_9_11_STABILITY_PROFILE.set`, SHA-256 `40993406F0E615CC0F70012ED99253D08B5DA657C62A9ABA2BBD4CC99EF32115`. The exact current-source guarded profile is `outputs/CANDIDATE_SESSION_ADAPTIVE_9_11_STABILITY_GUARDED_PROFILE.set`, SHA-256 `F242B6D43FE9C79901B137F2358BF55197B9E7E3C784A18071FE8D34A6B903E6`. The original higher-profit profile remains `outputs/CANDIDATE_SESSION_LIQUIDITY_8_11_PROFILE.set`, SHA-256 `B63FB4F78DB123B162872481CF93C34967241F46D83B099813E4BF02CCC0439B`.

**Exact annual Model4 confirmation: passed inside the recent research regime; no new bot or profit best.** All `8 / 8` frozen yearly reports parsed using the exact promoted source/profile hashes. 2019 had no trades; every active year from 2020 through 2026 YTD was profitable. Restarted annual score: `+$650.08`; average annual return: `+0.89%`; `40` trades; worst yearly DD: `0.57%`. The continuous account-path result remains `+$667.94`, `+0.89%/yr`, PF `3.63`, and `0.67%` DD. This removes the hidden-red-recent-year concern, but not the older-regime inactivity, small sample, forward, or second-broker gaps. See `outputs/SESSION_ADAPTIVE_YEARLY_PROBE_DECISION.md`.

**Realized-R Monte Carlo: economically strong, operational gate failed.** The exact continuous report now has `40 / 40` trades matched to their original stops and normalized to realized R: base `+27.92R`, PF `3.64`, max DD `1.82R`. In two 10,000-trial tests, even the severe worst trial stayed positive at `+5.75R`; severe 5th-percentile net was `+14.75R`, median PF `2.56`, and 95th-percentile DD `5.80R`. Both tests nevertheless failed because the 95th-percentile consecutive-loss streak was `7`, above caps of `5` and `6`. The candidate therefore remains research-only and needs an abnormal-loss quarantine plus forward/second-broker proof. See `outputs/SESSION_ADAPTIVE_MONTE_CARLO_DECISION.md`.

**Dedicated abnormal-loss quarantine: implemented and source-reproduced; not a profit best.** A new default-off guard is independent from the ordinary post-loss cooldown. Its nine synthetic state cases passed. Four Model1 reports and two Model4 reports returned, and the enabled four-loss/30-day profile exactly matched the default-off Model4 control at `+$667.94`, PF `3.63`, `40` trades, and `0.67%` drawdown; both trade CSVs have the same hash. Historical data reached only three consecutive losses, so the guard never activated at its promoted threshold. It is retained as a forward safety overlay, not evidence of higher profit or money readiness. See `outputs/SESSION_ABNORMAL_QUARANTINE_PROBE_DECISION.md`.

**Trade-level diversification screen: low overlap found, promotion rejected.** A fixed-R analyzer compared the current 40-trade candidate with the old 127-trade high-profit branch. The streams had near-zero monthly correlation, zero exact duplicate entries, and only two overlapping positions. At quarter secondary risk, analytical net rose from `27.92R` to `38.30R` with `1.98R` drawdown, but 2019 remained red and the combined loss streak reached six. More importantly, the secondary profile came from older source `8D62D907...` and contains explicit date/month fitting. A same-family control correctly showed 40 duplicates and `0.9945` correlation. No combined bot or new best was promoted. See `outputs/TRADE_LEVEL_DIVERSIFICATION_DECISION.md`.

**Independent Asian-sweep/London-rejection lane: rejected; no new best.** All `28 / 28` Model1 reports parsed for seven standalone, date-independent session-structure variants across continuous 2015-2026, older 2015-2018, middle 2019-2022, and recent 2023-2026 windows. Every variant had a losing broad era and no continuous PF reached the `1.20` gate. The best recent row made `+$39.24` but lost `-$38.76` in 2019-2022; volume and H1 trend filters were worse. No Model4 time was spent. Experimental code was removed, maintained source hash `62C2F0B2...` was restored, and the hidden compile passed with `0 errors, 0 warnings`. See `outputs/INDEPENDENT_SESSION_STRUCTURE_PROBE_DECISION.md`.

**Old high-profit trend-fallback reconstruction: rejected as calendar-dependent; no new best.** Trade parsing showed that `94` fallback trades supplied `+41.51R` in the old high-profit report, but they occurred only in March, May, and August because the profile filtered every other month. The signal was rebuilt on maintained source `62C2F0B2...` with calendar gates and auxiliary lanes off, low broker-aware risk, and standardized exits. All `56 / 56` Model1 reports parsed. The broad body-20 row lost `-$1,463.76` on `1,466` trades; the best bounded follow-up made only `+$68.99`, PF `1.00`, while losing older and recent eras. No row cleared all broad eras or PF `1.20`, so Model4 was skipped and temporary harness modes were removed. The old `+$1,915.83` headline remains historical research, not a deployable second strategy. See `outputs/DATE_INDEPENDENT_TREND_FALLBACK_DECISION.md`.

**Independent H4/H1 trend plus M15 breakout lane: rejected; recent-only gains did not qualify.** All `32 / 32` Model1 reports parsed for eight standalone higher-timeframe EMA/ADX trend and fresh Donchian-breakout variants across continuous 2015-2026, older 2015-2018, middle 2019-2022, and recent 2023-2026 windows. Every continuous, older, and middle row lost money. The least-negative continuous row was volume-confirmed at `-$15.89`, PF `0.74`, on `15` trades; its recent window made only `+$3.20`, PF `1.15`. The 20-bar row made `+$7.09` recently but lost `-$28.82` older and `-$23.19` in the middle era. No Model4 time was spent. Experimental code was removed and maintained source hash `62C2F0B2...` was restored. See `outputs/INDEPENDENT_HTF_TREND_BREAKOUT_DECISION.md`.

**Long automatic-pause follow-up: rejected; no source/profile change.** All `54 / 54` Model1 reports parsed. A 30-day ordinary post-loss cooldown cut continuous net from `+$658.58` to `+$589.29` without reducing drawdown; a 60-day version created a red 2025. The least damaging three-trade average-R pause made `+$619.22`, PF `3.49`, on `39` trades, but drawdown remained `0.67%`. Code review also confirmed the ordinary cooldown applies after every loss, so it is not a dedicated abnormal-streak quarantine. No Model4 time was spent. Experimental input exposure was removed and exact source hash `F1935B74...` was restored with all safety checks passing. See `outputs/SESSION_ABNORMAL_PAUSE_PROBE_DECISION.md`.

The adaptive rule blocks DGF entries for up to 14 days after a non-positive latest DGF realized R. It removed the second January 2025 loss without a calendar exception, raised 2025 Model4 net from `+$3.51` to `+$28.11`, and kept all other active years positive. See `outputs/SESSION_ADAPTIVE_RISK_PROBE_DECISION.md` and `outputs/SESSION_ADAPTIVE_REALTICK_911_LOSS14_SEGMENTS.md`.

**Older holdout correction: failed minimum activity; real-tick proof unavailable.** The frozen adaptive profile was tested without parameter changes on continuous and yearly 2015-2018 windows. The requested Model4 report contained `93,747` bars and `105,757,347` ticks but reported `0% real ticks`, so this broker cannot supply a valid older real-tick pass. Both Model4 and the separate Model1 diagnostic produced the same result: one unique trade in four years, `+$0.24`, with zero trades in 2015, 2016, and 2017. This is not a profitable holdout failure, but it is a decisive minimum-activity failure. The profile is retained only as a recent-regime benchmark and is not stable enough for real money. See `outputs/SESSION_OLDER_OOS_PROBE_DECISION.md`.

**Older-regime session-expansion follow-up: rejected; no new best.** Per-bar diagnostics found `3,671` signals outside the frozen 09:00-10:59 session and `467` in-session signals blocked by the `18%` spread/ATR cost cap. A cost-efficient BOS expansion was implemented on an experimental source, required spread at or below the existing cap, used half risk, and was tested with price-action thresholds from `16` through `24`. The active continuous 2015-2018 variants all lost money: from `-$411.82` / PF `0.72` for 11:00-21:59 to `-$84.37` / PF `0.33` for the sparsest PA-24 variant. Quality-3 variants added no trades. No Model4 time was spent after the Model1 rejection. The experimental code was removed and the exact promoted source hash `F1935B74...` was restored and recompiled with `0 errors, 0 warnings`. See `outputs/SESSION_COST_EXPANSION_PROBE_DECISION.md`.

**Independent range/liquidity follow-up: rejected as inactive; no new best.** A trend-independent range-edge sweep/reclaim lane was implemented with low-ADX/slope, wick, VWAP, volume, spread/ATR, structural-stop, RR, and quarter-risk controls. All `7 / 7` hidden local 2015-2018 Model1 reports returned. The best-looking shapes made only `+$5.58`, PF `2.22`, on `3` total trades versus the one-trade control: just two additional trades in four years and roughly `0.01%` per year on the `$10,000` test account. Baseline 24- and 48-bar shapes were slightly negative. That is not enough statistical evidence for yearly or Model4 testing. The experimental logic was removed; exact source hash `F1935B74...` was restored and recompiled with `0 errors, 0 warnings`. See `outputs/INDEPENDENT_RANGE_CONTINUOUS_PROBE_DECISION.md`.

**Independent H1 trend/M15 pullback follow-up: rejected; no new best.** A date-independent H1 EMA-50/200 trend plus M15 EMA-20 pullback/reclaim lane was tested across `7 / 7` hidden local 2015-2018 Model1 reports. Baseline, H4-aligned, higher-RR, liquid-hours, and looser-activity shapes all lost money. The looser row produced `56` trades but lost `-$43.79`, PF `0.68`. The only positive row was an isolated strict shape at `+$7.71`, PF `1.55`, on `8` trades, roughly `0.02%` per year. With every neighboring shape negative, it failed the plateau and sample-size gates. No Model4 time was spent. Experimental code was removed; exact source hash `F1935B74...` was restored and recompiled with `0 errors, 0 warnings`. See `outputs/IHTP_CONTINUOUS_PROBE_DECISION.md`.

**Confluence follow-up: no new best.** A `72 / 72` Model1 matrix tested two- and three-family DGF confirmation across adjacent London windows. The best two-family survivor made `+$509.69`, below the frozen `+$715.26` candidate; other variants had red 2024, 2025, or 2026 windows, and every three-family variant produced zero trades. The experimental gate was removed and the promoted source hash restored. See `outputs/SESSION_CONFLUENCE_PROBE_DECISION.md`.

**New York activity follow-up: no new best.** All `54 / 54` Model1 reports completed for six standalone New York DGF windows from 2019 through 2026 YTD. Every variant had at least one losing active year. The highest aggregate result, `sny_14_17` at `+$153.66`, still lost in 2019, 2020, 2021, and 2025, so all six variants are rejected without Model4 or London-combination follow-up. See `outputs/SESSION_NEW_YORK_PROBE_DECISION.md`.

**Adaptive regime activity follow-up: promising diagnostic lead, no new best.** All `54 / 54` Model1 reports completed. `raa_s7_exec_l14` raised continuous activity to `152` trades and made `+$830.09`, `+1.10%/yr`, PF `1.64`, with `2.33%` drawdown, but independent yearly checks lost `-$17.16` in 2019 and `-$62.49` in 2025. Score-8 gates removed nearly all trades. The lead remains unpromoted while date-independent exhaustion/overextension guards are tested. See `outputs/REGIME_ADAPTIVE_ACTIVITY_PROBE_DECISION.md`.

**Failure-guard follow-up: entry shock improved stability, still no new best.** All `72 / 72` Model1 reports completed. The default entry-shock guard kept continuous performance at `+$796.04`, `+1.06%/yr`, PF `1.63`, `147` trades, and `2.03%` drawdown; it flipped 2025 from `-$62.49` to `+$14.28`, but 2019 remained `-$13.08`. Impulse, consecutive-candle, and daily-range guards had no effect, session-range was negligible, and VWAP distance made performance worse. See `outputs/REGIME_FAILURE_GUARD_PROBE_DECISION.md`.

**Liquid-hours real-tick follow-up: no new best.** Model1 found neighboring zero-red-year `05:00-17:59` and `06:00-17:59` windows, and their continuous Model4 checks were genuinely profitable (`+$745.82` and `+$681.14`) with `1.72%` drawdown. However, independent Model4 yearly checks rejected both: 2019 was `-$26.94`, PF `0.27`, for the `05:00` profile and `-$32.52`, PF `0.02`, for the `06:00` profile. The frozen adaptive `09:00-10:59` profile remains the best risk-adjusted candidate only inside the 2019-2026 research period. See `outputs/REGIME_LIQUID_HOURS_PROBE_DECISION.md`.

**Execution-cost follow-up:** the original controls' 2025 margins turn negative under modest added cost. The adaptive profile stays positive in every active year across all ten deterministic scenarios; even `30` adverse points per side plus `$14/lot` round-trip commission leaves `+$440.02`, PF `2.22`, and a `+$8.32` worst active year. This is analytical stress, not second-broker proof. See `outputs/SESSION_CANDIDATE_COST_STRESS_DECISION.md`.

**Risk-ladder follow-up: no higher-risk promotion.** A `63 / 63` Model1 matrix tested `0.10%` through `0.75%` base risk under a `1.00%` effective cap. The `0.40%` row added only `+$44.06` while nearly doubling drawdown and cutting recovery from `9.33` to `5.12`; `0.50%` and `0.75%` made 2025 negative. The frozen `0.10%` adaptive profile remains the stability best. See `outputs/SESSION_RISK_LADDER_PROBE_DECISION.md`.

This is a real 2019-2026 risk-adjusted improvement over the corrected `+$211.37` baseline, but it is **not money-ready**: annualized growth remains below `1%`, 2019 had no trades, there are only `40` Model4 trades, and the 2015-2018 holdout failed minimum activity with only one trade. It still needs multi-regime strategy work, untouched forward evidence, and another broker before real-money review.

**Critical 2026-07-14 risk correction: all earlier profit headlines are superseded as live-readiness evidence.** The old lot-sizing path did not match actual XAUUSD entry-to-stop P/L on the tested broker. One legacy DGF stop lost `-$495.90` from a balance near `$3,411.73` despite intended effective risk near `1.40%`. Broker-aware `OrderCalcProfit` sizing was introduced at source hash `3C738B73...` and remains in current source `62C2F0B2...`, which compiles with `0 errors, 0 warnings`.

Current corrected stability baseline: `sr_m4_sweep_off`, profile `outputs/CANDIDATE_BROKER_ACCURATE_STABILITY_BASELINE.set`, SHA-256 `4D0B808BE07BF6612C70F96E4287717F3C7A8370B9089B165D71A244C3EA8E89`. On a `$10,000` continuous 2019-2026 Model4 real-tick test it made `+$211.37`, `+2.11%` total, `0.28%/yr`, PF `2.12`, `26` trades, and `0.82%` max drawdown. Fast Model1 yearly checks were green in all eight windows, but growth is far below the money-ready target. **This is a low-drawdown research baseline, not a real-money-ready bot.**

Corrected DGF activity result: best continuous candidate made `+$62.38` on `$1,000`, `+6.24%` total, `0.83%/yr`, PF `1.38`, `109` trades, and `3.60%` drawdown, but lost in 2019, 2022, and 2025. It is rejected. Standalone liquidity sweeps were also rejected after contributing `-$39.09` in the corrected control.

Future-data answer: 2024 through now is research-seen data, not a guarantee. The frozen older test confirmed the concern: the current candidate became almost completely inactive before 2019. No profile is expected to work forever without monitoring or periodic evidence review. A release still requires a frozen multi-regime strategy, walk-forward checks, spread/slippage stress, broker variation, and forward demo monitoring with automatic disable rules. Live settings must not be re-optimized after every loss; changes should happen only on a fixed review schedule or after a predefined safety/failure trigger.

See `outputs/BROKER_RISK_SIZING_PROBE_DECISION.md`, `outputs/DGF_ACTIVITY_PROBE_DECISION.md`, and `outputs/CORRECTED_RISK_STABILITY_BASELINE_DECISION.md`.

### Superseded Historical Notes

The results below are retained for research history. Dollar-profit claims generated before source hash `3C738B73...` must not be treated as current risk-corrected performance.

Latest 2026-07-14 DGF high-profit risk-shape follow-up: **no new best; simple risk shaping rejected**. The current-source package ran `11 / 11` hidden local continuous Model4 reports on source hash `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A`. The control reproduced `+$1,915.83`, `25.45%/yr`, PF `1.72`, `127` trades, and `24.58%` drawdown. Lower base-risk variants from `0.50%` to `0.80%` turned into losing curves with about `31-33%` drawdown; `dgf_hp_risk080_loss_scale` was the only non-control profitable shape at `+$238.06`, but drawdown was still `20.13%` with recovery `0.76`; `20%/70%` peak-trail made only `+$75.90` with `22.26%` drawdown; `35%/70%` peak-trail had no effect versus control. Decision: keep `lossblock_highprofit_peaktrail_off` as high-profit research-only, and stop spending Model4 time on simple risk-scaling/profit-lock variants. See `outputs/DGF_HIGHPROFIT_RISK_SHAPE_DECISION.md`.

Latest 2026-07-14 current-source R10 activity probe: **no new best; all tested R10/FMLR overlays rejected**. The package was rebuilt on current source hash `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A` and ran `30 / 30` hidden local fast Model1 configs with exported reports parsed. Candidates `r10_a7_current`, `r10_a7_dfg_risk_25_45_50`, `r10_a7_fmlr_blend`, `r10_a7_fmlr_tight`, `r10_a7_dfg_fmlr_blend`, and `r10_a7_dfg_fmlr_tight` all tied at `+$110.19` across the focused 2020/2022/2024/2025/2026YTD probe windows, with a red 2024 window at `-$45.14`, worst annualized return `-4.52%/yr`, worst DD `6.55%`, and `21` trades. FMLR activity did not add trades or profit on the current source, so this path is not worth Model4 follow-up. Post-run safety checks passed: MT5 safety `44 / 44`, static MQL preflight `33` checks / `328` inputs, and static repo safety `25` checks. See `outputs/R10_ACTIVITY_PROBE_DECISION.md`.

Latest 2026-07-14 peak-trail continuous follow-up: **one DGF continuous high-profit research lead found, no money-ready profile**. Current source hash is `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A`, hidden compile proof `outputs/MT5_HIDDEN_COMPILE_PEAK_TRAIL_UNBLOCK.log` shows `0 errors, 0 warnings`, and local MT5 safety audit passed `44 / 44`. The earlier DGF loss-block broad-window totals were restart-window comparison scores; continuous 2019-2026 Model4 showed the original peak-trail-on profiles stalled after only `3` trades (`-$7.36` high-profit, `+$0.68` stability). The only useful follow-up is `lossblock_highprofit_peaktrail_off`: continuous Model4 net `+$1,915.83`, total return `+191.58%`, average annualized return `25.45%/yr`, CAGR `15.28%`, PF `1.72`, `127` trades, recovery `2.02`, max equity DD `24.58%`, return/DD `7.79`. It is a high-profit research lead only, not trade-ready. The stability unblock variants lost `-$199.80` with `37.22%` DD, and the `8%/50%` peak-trail variant made only `+$108.48` with `19.90%` DD. See `outputs/PEAK_TRAIL_UNBLOCK_CONTINUOUS_MODEL4_DECISION.md`.

Newest continuous DGF research alias: `outputs/CANDIDATE_RANGE_ELITE_HIGHPROFIT_PEAKTRAIL_OFF_CONTINUOUS_PROFILE.set`, SHA-256 `0FBFA1F540422DF1B88A9410752E706B917F3111BFEF317F7EE9A03D7A4C2499`. Do not confuse this with the older peak-trail-on DGF loss-block aliases below; those are now kept as restart-window research references, not sequential-account best profiles.

Earlier 2026-07-14 DGF no-cushion loss-block validation: **superseded by the continuous follow-up above**. Current source hash was `F254FDF07B932FD8009E1ABFD761D1C9195568596A559F0DCB73A8CD29157D8F`, root/mirror sync was clean, static preflight passed with `327 / 1000` exposed tester inputs, and hidden MetaEditor compile proof `outputs/MT5_HIDDEN_COMPILE_DGF_LOSS_BLOCK.log` showed `0 errors, 0 warnings`. The high-profit range-elite restart-window lead was `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock`: Model4 broad-window total `+$2,800.21`, worst window `-$7.36`, average annualized return `52.09%/yr`, worst DD `20.84%`, `32` trades. The broad-window stability lead was `re_may140_late15_dgf_liq_reject1_cush35_dgflossblock`: Model4 broad-window total `+$2,323.11`, worst window `+$0.68`, average annualized return `39.02%/yr`, worst DD `20.76%`, `31` trades, and no red broad windows. These yearly-window totals are not achievable account-return claims because the continuous account path stalled. See `outputs/RANGE_ELITE_DGF_LOSSBLOCK_MODEL4_DECISION.md`.

Latest 2026-07-14 DGF cushion-risk follow-up: no profile was promoted, but a safer range-elite risk shape was found. Current source hash is `C23144DDE1F26C29135489FC9DF065FC5B5575C0B3F1B388BECC01E70E5965B4`, root/mirror sync is clean, static preflight passed with `316 / 1000` exposed tester inputs, and hidden MetaEditor compile proof `outputs/MT5_HIDDEN_COMPILE_DGF_CUSHION_RISK.log` shows `0 errors, 0 warnings`. The best cushion variant, `re_may140_late15_dgf_liq_reject1_cush50`, made `+$2,770.74` across six Model4 broad windows, reduced worst DD from `24.72%` to `20.84%`, and flipped 2021/2025 green, but 2019 is still red at `-$38.49`, so it is not money-ready. August-off variants were rejected because they created a new red 2025 window. See `outputs/RANGE_ELITE_DGF_CUSHION_MODEL4_DECISION.md`.

Latest 2026-07-14 DGF-liquidity signal follow-up: a better range-elite research shape was found, but it is still not trade-ready and it does not replace the stability lead. Current source hash is `69478904BB4073F48F8F963ED13D789BFE378456D4C054CAB16A8368F4065D92`, root/mirror sync is clean, static preflight passed with `313 / 1000` exposed tester inputs, and hidden MetaEditor compile proof `outputs/MT5_HIDDEN_COMPILE_DGF_LIQ_SIGNAL_REJECT.log` shows `0 errors, 0 warnings`. Focused Model4 real-tick testing parsed `30 / 30` exported reports. Best package result was `re_may140_late15_dgf_liq_reject1` at `+$3,218.26`, worst window `-$40.20`, `30` trades, and `24.72%` worst DD; it is rejected for live/stability because 2019, 2021, and 2025 are still red. See `outputs/RANGE_ELITE_DGF_LIQ_SIGNAL_MODEL4_DECISION.md`.

Latest 2026-07-14 late-session DGF follow-up: no new best was promoted. Current source hash is `129A489FECFE46470E5417FAD8C98B83E14A691D1370CA493F52A5E59B1E022B`, root/mirror sync is clean, static preflight passed with `311 / 1000` exposed tester inputs, and hidden MetaEditor compile proof `outputs/MT5_HIDDEN_COMPILE_DGF_LATE_SESSION_GUARD.log` shows `0 errors, 0 warnings`. Focused Model4 real-tick packages parsed `60 / 60` exported reports across 2019, 2021, 2023, 2024, 2025, and 2026 YTD. `re_may140_late15_pure` reduced the worst losing window to `-$62.11` and turned 2023 green, but 2019 and 2021 stayed red and 2026 YTD dropped to `+$472.36`, so it is rejected. See `outputs/RANGE_ELITE_LATE_DGF_MODEL4_DECISION.md`.

Latest 2026-07-14 input-limit/risk-shape follow-up: no new best was promoted. The current EA source now compiles and runs locally again after reducing exposed MT5 tester inputs from `1826` to `308`; compile proof is `outputs/MT5_HIDDEN_COMPILE_INPUT_DIET.log` with `0 errors, 0 warnings`, source hash `AF34F307DECFA45F53312DD53606E70141508973CEF60D30480779694396D7AC`. The aligned `range_elite_risk_shape_probe` Model1 fast screen returned and parsed `80 / 80` exported reports. Best fast-screen shape was `re_may140` / `re_blockliq_may140` at `+$3,015.75`, worst DD `20.75%`, and `39` trades, but it still lost in 2019 `-$86.19`, 2021 `-$60.96`, and 2023 `-$138.37`, so it is rejected. `re_blockliq` had no effect versus base. See `outputs/RANGE_ELITE_RISK_SHAPE_PROBE_DECISION.md`.

Latest 2026-07-14 range-elite current-source retest: the older high-profit `range_elite_micro` branch is profitable but still not trade-ready. Current-source Model4 yearly validation returned and parsed `8 / 8` full reports with `0` log-only rows. Profile `CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE`, source hash `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`, profile hash `3690755F9F97B3556222E8FACA784294A6BADF41BEDCAB5CC5CEB4EE7B12F836`. Total validation-window net was `+$2,953.27`, average annualized return `45.31%/yr`, total trades `61`, but 2019 `-$83.32`, 2021 `-$62.11`, and 2023 `-$131.33` were red, and worst DD reached `27.87%` in 2026 YTD. Decision: keep as a research lead, reject as trade-ready. See `outputs/RANGE_ELITE_MODEL4_CURRENT_SOURCE_DECISION.md` and `research/2026-07-14-range-elite-current-source-rejection-note.md`.

Latest 2026-07-14 report-export fix: MT5 full tester reports now export and parse correctly in local hidden runs. The root cause was absolute `Report=` paths; current configs now use plain report filenames, the hidden runner collects reports from the terminal data root, the router accepts this MT5 build's `Maximum consecutive losses ($)` label, and the importer parses exported `.htm/.html/.xml` reports before falling back to logs. Current-source Model4 yearly reproduction for `r10_pg40_atr085_adapt7` returned and parsed `8 / 8` full reports with `0` log-only rows. Source hash: `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`; current-source yearly profile hash: `3E6B806E2941A993579756C8E503B7886E06891F077A104D39428704E48545BC`; MT5 build: `MetaQuotes-Demo (Build 5989)`. Result did not create a new best: total validation-window net score is still `+$263.72`, worst window is 2020 at `-$22.92` / `-2.29%/yr`, worst DD is `7.09%`, and 2026 YTD still has `0` real-tick trades. See `outputs/MT5_REPORT_EXPORT_FIX_SUMMARY.md` and `outputs/PEAK_R20_REGIME_COMBO_MODEL4_CURRENT_SOURCE_REPORT_METRICS.md`.

Latest 2026-07-14 DGF risk follow-up: no new money-ready or clean stability-best profile was promoted. The EA now has default-off diagnostic-fallback spread guard, diagnostic-fallback spread risk scaling, and diagnostic-fallback performance risk scaling inputs. Hard spread/ATR filtering was rejected because it created red yearly windows. The best spread-risk variant, `r10_a7_dfg_risk_25_45_50`, improved Model4 yearly total from `+$263.72` to `+$270.66`, lowered worst DD from `7.09%` to `6.20%`, and reduced the 2020 blocker from `-$22.92` to `-$15.28`, but 2020 is still red, so it is not promoted. The newer DGF performance-risk throttle variants were rejected in fast Model1 yearly validation because every throttle variant created a red year while the untouched base stayed green. See `outputs/PEAK_R20_DGF_RISK_FOLLOWUP_SUMMARY.md`.

Latest 2026-07-14 local update: the best new risk-first research lead is `r10_pg40_atr085_adapt7`, not the earlier raw R10 branch. It adds a dynamic ATR regime guard (`0.85-1.65`) plus adaptive regime confidence score `7` / efficiency `0.45` to the `r10_profit_guard40` base. Fast Model1 yearly validation across 2019-2026 YTD was green in every year: total `+$344.60`, worst year `+$9.25`, worst DD `7.08%`, `28` trades. Model4 real-tick yearly validation was mostly green but not clean: total `+$263.72`, worst DD `7.09%`, `22` trades, one red year in 2020 at `-$22.92`, and zero 2026 YTD real-tick trades. Decision: this is the current stability lead, but it is not money-ready until the 2020 Model4 diagnostic-fallback loss is solved without calendar overfitting and validated with exported reports/stress/broker/forward evidence. See `outputs/PEAK_R20_REGIME_COMBO_STABILITY_LEAD_SUMMARY.md`.

Previous status snapshot (2026-07-14 UTC): hidden local MT5 first-pass testing of `trade_ready_conservative`, `money_ready`, locked LowATR risk-shape candidates, a 33-variant R20 opportunity sweep, yearly splits, a 22-variant R10 drawdown-reduction sweep, a 5-profile Model4 real-tick shortlist, an 8-year Model1 OOS yearly pass for the R10 branches, the DGF peak-trail continuous follow-up, a current-source R10 activity/FMLR probe, and a DGF high-profit risk-shape probe. There is still no newly validated trade-ready best profile. The strict/stability branch remains `lowatr_exit_peak_r20` style evidence: `+$464.86`, `18.40%/yr`, PF `6.7890`, recovery `5.1411`, and `5.81%` drawdown on the fast continuous screen, but it is too sparse and weak in 2025. The current DGF high-profit continuous research lead is still `lossblock_highprofit_peaktrail_off`: Model4 `+$1,915.83`, `25.45%/yr`, PF `1.72`, recovery `2.02`, and `24.58%` max equity drawdown. The DGF high-profit risk-shape probe rejected lower-risk, loss-scaling, drawdown-cap, and late-profit-lock variants; no risk-shaped DGF profile is promoted. The more efficient older R10 high-profit branch remains lower drawdown at Model4 `+$1,564.01` with `10.64%` drawdown. The current-source R10 activity/FMLR overlay probe is rejected because all six variants tied at `+$110.19` and had a red 2024 window at `-$45.14`. The drawdown fallback is `r10_profit_guard40`: Model4 `+$1,000.97`, `39.61%/yr`, PF `3.4058`, recovery `8.5240`, and `7.76%` drawdown. The OOS yearly pass rejected all R10 branches as money-ready because 2019/2021 and other older windows went red and yearly drawdown reached `12-14%`.

Use this README as the status board. If you want to know what changed without asking Codex, start here.

## Read This First

Quick answer:

- Current corrected answer: no money-ready bot. The maintained A167/D045 risk-first candidate made `+$321.59` on `$10,000` in continuous 2019-2026 Model4 real ticks, `+3.22%` total, `0.43%/yr` annualized, PF `2.81`, `32` trades, and `0.59%` DD. It is stable but economically too weak and had no 2015-2018 activity. All older high-profit headlines are superseded as live-readiness evidence unless reproduced on the maintained source and broker-accurate sizing path.
- Newest 2026-07-16 test result: the H1 Band/VWAP DI-edge follow-up improved the independent broad-history reversion lane but did not create a new best. All `16 / 16` Model1 broad reports, `3 / 3` continuous Model4 reports, and `24 / 24` yearly Model4 reports parsed. `DI >= -12` led continuous Model4 at `+$478.86`, PF `2.77`, `36` trades, and `1.14%` DD; `DI >= -10` made `+$447.23`, PF `3.51`, `28` trades, and `1.06%` DD. Both were rejected because each retained two losing active years and no trades in 2016/2019. Two exact `700`-row portfolio screens also produced `0` eligible blends. No promotion; maintained A167/D045 is unchanged. See `outputs/HTF_BAND_REVERSION_DI_GATE_DECISION.md`.
- Newest test result: DGF high-profit risk-shape probe, rejected. `11 / 11` current-source continuous Model4 reports parsed. Control reproduced `+$1,915.83` but still had `24.58%` drawdown. Lower base-risk variants became losing curves, `dgf_hp_risk080_loss_scale` made only `+$238.06` with `20.13%` drawdown, and profit-lock variants either did nothing or killed profit. No promotion; next work should be different entry/exit behavior, not simple risk scaling. See `outputs/DGF_HIGHPROFIT_RISK_SHAPE_DECISION.md`.
- Newest test result: current-source R10 activity/FMLR probe, rejected. Source hash `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A`, `30 / 30` hidden local fast Model1 reports parsed. All six tested overlays tied at `+$110.19` across focused 2020/2022/2024/2025/2026YTD windows, with 2024 full red at `-$45.14`, worst DD `6.55%`, and `21` trades. FMLR activity did not add trades or profit; do not promote or spend Model4 time on these overlays. See `outputs/R10_ACTIVITY_PROBE_DECISION.md`.
- Newest test result: peak-trail continuous follow-up, still no money-ready profile. Source hash `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A` compiles with `0 errors, 0 warnings`. The earlier DGF loss-block yearly-window totals were restart-window comparison scores; continuous 2019-2026 Model4 showed the original peak-trail-on profiles stalled after only `3` trades. New DGF continuous high-profit research lead: `lossblock_highprofit_peaktrail_off`, net `+$1,915.83`, average annualized return `25.45%/yr`, CAGR `15.28%`, PF `1.72`, recovery `2.02`, `127` trades, max equity DD `24.58%`, return/DD `7.79`. Research-only because drawdown is too high and full yearly/monthly/quarterly/stress/broker/forward evidence is missing.
- Newest profile file: `outputs/CANDIDATE_RANGE_ELITE_HIGHPROFIT_PEAKTRAIL_OFF_CONTINUOUS_PROFILE.set`, SHA-256 `0FBFA1F540422DF1B88A9410752E706B917F3111BFEF317F7EE9A03D7A4C2499`.
- Low-drawdown benchmark: `r10_pg40_atr085_adapt7`, SHA-256 `CB182D026A62AE499052949F88F514EF7FC67D8C071E9179AB069D29575C59B2`. Model1 yearly 2019-2026 YTD: `+$344.60`, `0` losing years, worst year `+$9.25`, worst DD `7.08%`, `28` trades. Model4 yearly 2019-2026 YTD: `+$263.72`, `1` losing year (`2020`, `-$22.92`), worst DD `7.09%`, `22` trades, `2026 YTD` had `0` real-tick trades. Lower drawdown than the range-elite branch, but too small/sparse and not trade-ready.
- Highest current-source Model4 yearly profit lead tested today: `range_elite_micro` / `CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE`, profile SHA-256 `3690755F9F97B3556222E8FACA784294A6BADF41BEDCAB5CC5CEB4EE7B12F836`. It made `+$2,953.27` across 2019-2026 YTD Model4 yearly windows with `45.31%/yr` average annualized return and `61` trades, but it is rejected as trade-ready because 2019 `-8.36%/yr`, 2021 `-6.23%/yr`, and 2023 `-13.18%/yr` were red and worst DD was `27.87%`. Profitable research lead, not stable best.
- Current-source exported-report proof: `r10_pg40_atr085_adapt7` now has `8 / 8` Model4 yearly full MT5 reports parsed on source hash `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`. Current-source yearly profile hash is `3E6B806E2941A993579756C8E503B7886E06891F077A104D39428704E48545BC`. Per-year returns: 2019 `+4.45%/yr`, 2020 `-2.29%/yr`, 2021 `+7.67%/yr`, 2022 `+3.74%/yr`, 2023 `+6.42%/yr`, 2024 `+1.58%/yr`, 2025 `+4.89%/yr`, 2026 YTD `0.00%/yr`. This confirms the profile is still research-only, not a new best.
- Latest DGF risk follow-up: `r10_a7_dfg_risk_25_45_50` was a partial Model4 improvement (`+$270.66`, worst DD `6.20%`, 2020 `-$15.28`) but still failed the no-red-year gate. DGF performance-risk throttles were rejected on Model1 yearly splits. No new best.
- Current newest DGF research profile: `lossblock_highprofit_peaktrail_off` for continuous-account high profit. The older `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock` and `cush35_dgflossblock` profiles are now restart-window research references only, because their continuous peak-trail-on paths stalled after 3 trades.
- Conservative trade-ready candidate: `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`, SHA-256 `F708C68A68016C13C4ADAECFE472A270748F4DAD9F2DF8C12F9870C2324DA13F`
- Latest aggressive research frontier: `peak_r20_no_peaktrail_r10`, SHA-256 `16330F4C03B53EC4B9CF6E50A0D00038315CA5904529AEF3F284223B173CF3B9`; Model1 continuous `+$1,716.76`, `67.94%/yr`, `48.51%` CAGR, PF `2.8655`, recovery `7.5227`, `76` trades, `10.62%` drawdown. Model4 real-tick continuous `+$1,564.01`, `61.89%/yr`, `45.15%` CAGR, PF `2.6874`, recovery `7.1007`, `74` trades, `10.64%` drawdown. Model1 yearly splits stayed green: 2024 `+$814.43`, 2025 `+$186.95`, 2026 YTD `+$246.96`. This is not promoted to trade-ready because drawdown is above the strict safety band.
- Latest R10 drawdown sweep: `outputs/PEAK_R20_DRAWDOWN_SWEEP_SUMMARY.md` records a 22-variant Model1 sweep plus a 5-profile Model4 shortlist. `r10_dailytrail35` slightly improved Model4 profit to `+$1,577.25` but left drawdown unchanged at `10.64%`, so it is not promoted. `r10_profit_guard40` is the best lower-drawdown fallback: Model4 `+$1,000.97`, `39.61%/yr`, `31.59%` CAGR, PF `3.4058`, recovery `8.5240`, Sharpe `42.3443`, `46` trades, and `7.76%` drawdown. It is a fallback candidate, not trade-ready.
- Latest R10 OOS yearly check: `outputs/PEAK_R20_OOS_YEARLY_SUMMARY.md` tests `r10_base`, `r10_loss_scale_15`, and `r10_profit_guard40` from 2019 through 2026 YTD on fast Model1. All three are rejected as money-ready. `r10_base` had `3` losing years and `12.44%` worst yearly drawdown; `r10_loss_scale_15` had `4` losing years and `14.21%` worst drawdown; `r10_profit_guard40` had `2` losing years and `12.78%` worst drawdown. This is the strongest evidence so far that the R10 edge is recent-regime dependent.
- Latest first-pass result: `lowatr_locked_risk18pure` ran hidden on XAUUSD M15, `Model=1`, `2024.01.01` to `2026.07.12`; MT5 exported no report, but the tester log parsed as `PARSED_FROM_LOG` with `net=419.14`, `16.59%/yr` annualized return, `14.86%` CAGR, PF `5.0524`, Sharpe `7.6671`, recovery `3.7366`, `8` trades, and `7.33%` drawdown. It is rejected because drawdown exceeded the `6%` first-pass cap.
- Latest high-profit research-only screen: `lowatr_locked_research` made `+$8,437.54`, PF `2.8893`, Sharpe `27.9639`, recovery `2.5527`, and `59` trades on the same fast Model1 continuous window, but drawdown was `25.94%`, so it is not trade-ready and not promoted.
- Latest safer pass-through attempt: `lowatr_locked_risk20` made `+$241.12` on the continuous fast screen with `3.68%` drawdown and then stayed green on 2024, 2025, and 2026 fast yearly splits, but stopped because the 2025 split recovery factor was `1.0552`, below the `1.25` floor.
- LowATR locked fast-screen summary: `outputs/LOWATR_LOCKED_FAST_SCREEN_SUMMARY.md` and `.csv` list the raw, capped, pure-risk, money-ready, and conservative results in one place.
- Latest LowATR exit/risk sweep: `outputs/LOWATR_EXIT_SWEEP_SUMMARY.md` and `.csv` record a 32-variant hidden local Model1 sweep. Best headline result was `lowatr_exit_mfe_early` at `+$9,274.07`, but drawdown was `25.99%`, so it is research-only. Best under-6% drawdown result was `lowatr_exit_peak_r20` at `+$464.86`, `18.40%/yr`, `16.31%` CAGR, PF `6.7890`, recovery `5.1411`, and `5.81%` drawdown, but yearly splits rejected it because 2025 made only `+$21.17` with recovery `0.4178` and `4` trades. No new trade-ready best was promoted.
- Latest R20 opportunity sweep: `outputs/LOWATR_R20_OPPORTUNITY_SWEEP_SUMMARY.md` records the 33-variant hidden local Model1 sweep. Broad all-month trading was rejected; it either lowered profit or raised drawdown. Disabling equity profit peak trail created the first meaningful higher-profit branch, but the usable frontier still has about `10.6%` drawdown. The follow-up drawdown sweep is in `outputs/PEAK_R20_DRAWDOWN_SWEEP_SUMMARY.md`.
- Conservative candidate risk shape: `0.10%` risk, `0.20%` open-risk cap, `0.01` max lots, one position, max `2` trades/day, `120` minutes between trades, `0.20%` daily loss cap, `0.60%` weekly loss cap, `1.25%` monthly loss cap, `3.00%` equity drawdown cap, hard safety gate on.
- One-command offline refresh: `work/refresh_money_ready_status.ps1` rebuilds first-pass report routing, live-evidence routing, compile-evidence routing, conservative full-validation report routing, first-pass state, safety audit, live evidence analyzers, the money-ready efficiency audit, GitHub required-publication upload plan, GitHub publication sync audit, live-readiness, scorecard, release decision, proof runway, reproducibility bundle, and evidence handoff without launching MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions. Current `outputs/MONEY_READY_REFRESH_STATUS.md` is `FAIL` with `5` PASS, `8` PENDING, and `3` FAIL because the old first-pass candidate/routing/proof runway remain failed; GitHub sync and current-source compile now pass.
- First-pass advance wrapper: `work/advance_first_pass_after_report.ps1` remains available for future first-pass reports, but there are currently `0` first-pass configs selected and `0` reports expected because the active candidate hit an early-stop failure.
- Money-ready scorecard: `outputs/MONEY_READY_STATUS_SCORECARD.md` says `NOT_READY_PENDING_EVIDENCE` with `7` PASS, `13` PENDING, and `0` FAIL. No first-pass candidate is approved for real money; `trade_ready_conservative` remains the strictest paper/demo safety artifact, and real-account trading remains locked.
- Money-ready efficiency audit: `outputs/MONEY_READY_EFFICIENCY_AUDIT.md` is `PENDING` with `0` PASS, `17` PENDING, and `0` FAIL. It blocks safe-but-low-profit promotion until broad exported MT5 evidence clears the `12%` annualized return target, `10%` CAGR target, `3.0` return/DD target, `3%` max drawdown target, no-red-window rule, PF/recovery quality floors, recent-data proof, and broker/stress survival.
- Release-candidate decision: `outputs/TRADE_READY_RELEASE_CANDIDATE_DECISION.md` says `NOT_RELEASEABLE_PENDING_EVIDENCE`. It wrote only `outputs/TRADE_READY_RELEASE_PROFILE_LOCKED.set`; no manual live-review profile was written.
- Proof runway: `outputs/MONEY_READY_PROOF_RUNWAY.md` is the exact next-evidence checklist. Current next action is to rework the LowATR risk shape or make a strategy-code change before more full validation. The first-pass package is empty because the active `lowatr_locked_risk18pure` candidate hit an early-stop failure.
- Evidence handoff: `outputs/money_ready_evidence_handoff` and `outputs/money_ready_evidence_handoff.zip` are current, but the first-pass run list is empty until a new candidate is built. They still contain the 53 validation plus 10 broker-proxy full-run list, accepted live-evidence CSV names, templates for trade log/forward/demo/second-broker evidence, and the strict MT5 report-stat requirement.
- Reproducibility bundle: `outputs/TRADE_READY_REPRODUCIBILITY_BUNDLE.md` is `PASS` with `83` passing rows, `0` pending, and `0` failed. It freezes the current local source, profiles, manifests, decisions, validation package-shape evidence, static safety scripts/status, connector publication-verification input, strict report routers, first-pass advance wrapper/status, money-ready efficiency audit, annualized-return report metrics, GitHub required-publication upload plan/helper, first-pass hidden-runner plan/helper, hard-lock runner smoke test, and GitHub publication-sync audit into `outputs/trade_ready_reproducibility_bundle.zip`; the authoritative zip SHA-256 is `E02B1207BF21E3D8431A8ED56335D06E25DDADF6A709806A9115F1C3415E39A3`. This does not satisfy the live-readiness GitHub sync gate by itself.
- GitHub publication sync audit: `outputs/GITHUB_PUBLICATION_SYNC.md` is `PASS` with all `7` required rows passing, `0` pending, and `0` failed. The maintained A167 root/mirror source, three locked profile artifacts, source manifest, and current-research-best document match `Antoee/gold` `main` through connector-verified Git blob identities. The validated DI-gate research update was merged in commit `cfc7e05`; no GitHub Actions workflow was launched.
- First-pass report inbox: `outputs/FIRST_PASS_RETURNED_REPORT_ROUTING.md` currently shows `0` routed, `0` missing, `0` duplicates, `0` invalid, and `0` unmatched files because no first-pass reports are currently expected.
- Conservative full-validation report inbox: `outputs/TRADE_READY_CONSERVATIVE_RETURNED_REPORT_ROUTING.md` currently shows `0` routed, `63` missing, `0` duplicates, `0` invalid, and `0` unmatched files. This inbox is for the 53 conservative validation reports plus 10 broker-proxy reports after first-pass earns full validation.
- Live evidence inbox: `outputs/TRADE_READY_LIVE_EVIDENCE_ROUTING.md` currently shows `0` routed, `3` missing, `0` duplicates, `0` invalid, and `0` unmatched files for trade log, forward, and second-broker evidence CSVs. The router now preflights required columns, external evidence quality columns, XAUUSD symbol, and profile/source identity before copying evidence into canonical analyzer paths.
- Compile evidence inbox: `outputs/MT5_COMPILE_EVIDENCE_ROUTING.md` shows `2` routed, `0` missing, `0` duplicates, `0` invalid, `1` imported, and `0` waiting rows. The exact A167 source copy matches the compiled source, and `outputs/MT5_COMPILE_STATUS.md` records `0 errors, 0 warnings`; the current-source compile gate is `PASS`.
- First-pass proof path: `outputs/first_pass_validation_queue` currently records `22` queued rows for `lowatr_locked_risk18pure`, but the current result is `FAIL`: `1 / 22` rows parsed from tester log, `0 / 22` exported reports parsed, `21` rows still missing, next batch `EMPTY`, next package `0` configs, and parallel lanes `0` configs. Log evidence is enough to reject or continue a fast screen, but exported full reports are still required before any future candidate can be promoted.
- Conservative proof path: `53` staged validation configs plus `10` broker-proxy configs are ready. The report importer wrote `outputs/TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv` and `outputs/TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv`; both currently contain only `MISSING_REPORT` rows, so `outputs/TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.md` is `PENDING` with `2` passing prep/import gates, `23` pending result/evidence gates, and `0` failures. Trade-ready validation now requires exported MT5 reports with `Status=PARSED` plus profit factor, expected payoff, Sharpe ratio, win rate, trades, max consecutive losses, drawdown %, and recovery factor; the exact continuous real-tick run must have at least `20` trades. Log-only profit rows cannot pass this gate.
- Forward/demo proof gate: `outputs/TRADE_READY_CONSERVATIVE_FORWARD_TEST.md` is prepared and currently `PENDING` with `0` returned evidence rows.
- Second-broker proof gate: `outputs/TRADE_READY_CONSERVATIVE_SECOND_BROKER_DECISION.md` is prepared and currently `PENDING` with `0` returned evidence rows.
- Old `$866 in 2.5 years` result: outdated baseline, not the current best
- The first profit table is context, not a pure best-to-worst ranking.
- The second table's larger `total` rows are sampled validation scores. They are useful for comparing profiles, but they are not one continuous account return.
- Best current continuous research result: `+$10,127.76` on `Model=1`, `2024.01.01` to `2026.07.12`; on a `$1,000` start this is `+1012.78%` total, about `+159.47%/yr` CAGR.
- Most recent reproduced real-tick continuous result before the `FF1BCDB0...` safety source update: `+$1,195.69` on `Model=4`, `2024.01.01` to `2026.07.12`; on a `$1,000` start this is `+119.57%` total, about `+36.51%/yr` CAGR.
- Historical Dec-ISLP-Off real-tick continuous result: `+$4,507.51`; on a `$1,000` start this is `+450.75%` total, about `+96.43%/yr` CAGR, but it is stale until reproduced on the current local source/compact path.
- Best sampled real-tick validation total: `+$7,469.00` across six Model4 windows; no yearly percent because it is an aggregate validation score, not a sequential account curve.
- Latest promoted change: Low-ATR ISLP trades now require order-flow confirmation
- Latest code addition: default-off `FMLR` Flat Month Liquidity Reclaim lane plus session/Asian reclaim, equal-level reclaim, swing-sweep reclaim, previous day/week reclaim, daily-open reclaim, weekly/monthly-open reclaim, open-liquidity targets, previous-month high/low targets, forward-liquidity target, runner target stretch, FMLR-only confirmed-swing structural runner trailing with fallback lock, FMLR structural unlimited-runner execution, protected FMLR structural scale-in, protected shelf-retest entries, protected displacement-pullback entries, protected breakout-retest entries, protected engulfing-reclaim entries, protected tick-pressure reclaim entries, protected FVG structural retest entries, protected order-block retest entries, protected CHoCH retest entries, recent-retest, continuation-retest, compression-breakout, session-range breakout, opening-range reclaim, VWAP-deviation reclaim, range-failure reclaim, HTF liquidity reclaim, sweep-displacement BOS, imbalance-continuation, session/Asian target, imbalance-retest, swing-target, phase-aligned regime gate, forward-clearance, and structural stop cluster/pocket candidates; stop logic now uses proximity-limited confirmed swing stop anchors, swing-preferred stop pockets, daily/weekly/monthly open stop pockets, optional FMLR-only confirmed-swing runner trails, an optional no-fixed-TP FMLR runner path that still validates planned RR before entry and can lock a small positive stop if no swing pivot is ready, an isolated `fmlr_structural_scale_in` package profile that only permits small winner add-ons for protected/profitable FMLR runners, an isolated `fmlr_shelf_retest` profile that requires a prior shelf sweep/reclaim plus current retest, an isolated `fmlr_displacement_pullback` profile that waits for a displacement/BOS break before taking the pullback retest, an isolated `fmlr_breakout_retest` profile that waits for a compression-box break and then requires a controlled retest/hold of the broken boundary with the stop behind the box, an isolated `fmlr_engulfing_reclaim` profile that requires a liquidity sweep, opposite-body engulfing reversal candle, body/close-location quality, and a stop behind the swept/engulfed structure, an isolated `fmlr_tick_pressure_reclaim` profile that requires a sweep/reclaim plus directional tick-volume pressure and current-bar volume expansion with the stop behind the swept structure, an isolated `fmlr_fvg_retest` profile that waits for a structural FVG impulse/break then a controlled gap retest with the stop behind the gap, an isolated `fmlr_order_block_retest` profile that waits for a displacement break then a controlled order-block retest with the stop behind the block, and an isolated `fmlr_choch_retest` profile that waits for reversal context, a CHoCH break, then a controlled retest/hold with the stop behind structure; Adaptive Reverse quarantine guardrails now also require deferred displacement-break plus controlled retest confirmation and block alternating guarded reverse losses if Adaptive Reverse is ever manually re-enabled; not promoted or backtested yet
- Latest follow-up: default-off `fmlr_failed_breakout_trap` now fades a failed compression-box breakout only after a snapback/reclaim candle, optional volume expansion, range-phase gating, forward target checks, and a stop behind the failed-break wick/box structure. If the opposite side of the box is too close to qualify as a target, it can now fall forward to an existing forward-liquidity target instead of rejecting the setup outright. HTF, opening-range, VWAP-deviation, and range-failure structural targets now get the same no-new-input fallback path when their own target is too close and a valid forward-liquidity target exists. The shared FMLR forward-target selector now skips too-close liquidity targets before choosing the nearest valid target, the forward-clearance gate now uses the same minimum-candidate-distance filtering, structurally widened stops can use an existing forward-liquidity target to repair RR when it truly satisfies the configured minimum, generic forward-liquidity targets can extend accepted structural targets but no longer shrink them, runner-stretch protection now uses the shared accepted-structural-target flag so VWAP-deviation structural targets are not forgotten downstream, runner phase permission now reuses the shared structural-runner setup flag instead of a duplicated list, accepted structural targets can qualify as structural runner setups under the existing runner-stretch controls, the no-fixed-TP FMLR unlimited runner now recognizes that structural-target runner path only when required forward clearance is present, any FMLR no-fixed-TP runner now requires actual runner-stretch evidence in the signal, and confirmed-swing FMLR structure trailing now respects broker minimum stop distance. These changes are untested and not promoted.
- Latest source refinement: structural-target fallback setups that already repaired a too-close structural target with valid forward liquidity can now qualify for the protected structural runner path. The EA logs `FMLR structural fallback runner;` when this fallback path participates, but the no-fixed-TP runner still requires forward clearance and runner-stretch evidence. Untested and not promoted.
- Latest flat-month efficiency refinement: FMLR now honors the existing flat-month entry-score discount, catch-up entry-score discount, late-catch-up entry-score discount, flat-month RR discount, catch-up RR discount, and late-catch-up RR discount inside the lane itself. The EA logs `FMLR active min score ...;` and `FMLR active min RR ...;` when these existing controls lower the lane threshold. Untested and not promoted.
- Latest FMLR sizing refinement: when the existing flat-month catch-up risk ramp is enabled and passes its protected-floor/liquid-session gates, FMLR can now ramp from `InpFlatMonthLiquidityReclaimRiskMultiplier` toward the existing `InpFlatMonthProbeRiskMultiplier` cap. The EA logs `FMLR active risk x...;` when that capped ramp is active. Untested and not promoted.
- Latest package/profile refinement: added `fmlr_activity_blend` and `fmlr_activity_blend_tight` validation profiles so multiple FMLR structural triggers can be tested together against zero-trade months without promoting the blend. Active packages are now `480` full configs and `162` fast configs.
- Latest structural-stop refinement: FMLR equal-high/low stop anchors now count as liquidity-pool evidence under the existing stop-cluster buffer controls, so two-touch equal-level pools can receive extra stop buffer before RR is checked. The EA logs `FMLR equal-level stop pool;`. Source hash: `24698D8AB5D799275958AF9369EF6949D114F12DE5E2013BC423F655DDEC4ABA`. Untested in MT5 and not promoted.
- Latest flat-month cadence refinement: FMLR now computes catch-up state before enforcing its lane monthly-entry cap and spacing gate. Existing late-catch-up controls can extend the FMLR cap up to `InpFlatMonthLateCatchUpMaxMonthlyEntries`, and catch-up progress can reduce FMLR spacing by up to 50% with a 30-minute floor. The EA logs `FMLR active monthly cap ...;` and `FMLR active spacing ...m;`. Source hash: `842EB39FC61E3FC1329DB7F272F65D6B722AA556CF7C04D77DD15C6335A769BD`. Untested in MT5 and not promoted.
- Latest shared structure-stop refinement: equal-high/low liquidity stop anchors now pass confirmed equal-level evidence into the shared liquidity-cluster buffer helper, so the broader `StructureStopDistance()` path can use the existing cluster extra buffer without re-proving the same two-touch pool. Source hash: `E83C7A92A8757B100361A9A17CFB6445102CD5D6DE3E87F6C323CF61516457E3`. Untested in MT5 and not promoted.
- Latest previous-period stop-pocket refinement: the shared `LiquidityPocketStopLevel()` path now treats enabled previous-day/week/month liquidity levels as stop-pocket evidence when the existing liquidity-pocket stop shift is active, so structural stops can move beyond higher-timeframe liquidity pockets instead of sitting inside them. Source hash: `778E168D96A8185FBA8781210794A6B4547341D4D95F0470134EAC4E5F72C38F`. Untested in MT5 and not promoted.
- Latest flat-month protected-loss refinement: FMLR can now use a protected catch-up version of the flat-month gate during shallow red months, while normal flat-month lanes still honor `InpFlatMonthRequireNoMonthlyLoss`. The exception is capped by existing monthly-loss/catch-up settings, protected-floor checks, and liquid-session requirements. The EA logs `FMLR protected loss catch-up;`. Source hash: `686F80DA9CB4DE36E564C47A5C3AE4B5A6CAF62B8BF90250729E9FF751602CDF`. Untested in MT5 and not promoted.
- Latest profit-capture refinement: FMLR runner target stretch can now include clean non-structural liquidity-sweep reclaims when forward liquidity, sweep evidence, and quality confirmation exist. The EA logs `FMLR sweep runner;` only when the target actually stretches. Source hash: `10D1007CFD4CB124C8DE6EC247E1DE1611F1A7955E4E8EC2F9816B2A238DFA04`. Untested in MT5 and not promoted.
- Latest sweep-runner profit-capture refinement: FMLR no-fixed-TP runner permission now recognizes proven non-structural sweep-runner setups when forward clearance, runner-stretch evidence, and FMLR structure trailing are present. The entry log can add `FMLR sweep unlimited runner;`. Untested in MT5 and not promoted.
- Latest tick-speed reclaim refinement: FMLR can now tag `FMLR tick-speed reclaim;` when an existing sweep/reclaim context is followed by a directional tick-speed impulse through the default-off `InpUseTickSpeedImpulse` input. Source hash: `B6AA1915D2CA7483B1066C227F2506D7A85756D918820FF1100BAF66B0FBDBBE`. Untested in MT5 and not promoted.
- Latest real-account lock update: even a future live profile now needs `InpRealAccountApprovalCode=ALLOW_REAL_ACCOUNT_TRADING` plus matching `InpRealAccountApprovalProfileId/InpEvidenceProfileId`, matching `InpRealAccountApprovalSourceHash/InpEvidenceSourceHash`, a non-empty evidence run label, and the trade-readiness gate enabled. Current money-ready and conservative profiles keep those approval identity fields set to `DISABLED`.
- Latest validation integrity update: full validation package report names now include phase and tester model, preventing fast Model1 and exact Model4 runs for the same window from sharing the same report base name. The money-ready and conservative validation package smoke tests now fail if duplicate `ExpectedReportName` values appear.
- Latest faster-validation update: `work/refresh_first_pass_validation_state.ps1` now imports exported reports and hidden tester-log evidence, audits integrity, updates raw ranking, builds a trusted decision, selects the next useful stage, and clears stale packages when no configs should run. The latest hidden fast Model1 run parsed from tester log as `0` trades and `$0.00` net, so `trade_ready_conservative` is `REJECT_FIRST_PASS`; next package is `0` configs.
- Latest first-pass advance update: `work/advance_first_pass_after_report.ps1` consumes returned first-pass reports, refreshes first-pass state, refreshes money-ready status, and writes `outputs/FIRST_PASS_ADVANCE_STATUS.md/.csv` through hidden/no-window child PowerShell steps. It is idle right now because the current first-pass package is empty after the failed fast-screen result.
- Latest evidence identity update: EA trade logs now stamp `profile_id`, `source_hash`, and `run_label`. The conservative trade-quality and Monte Carlo gates expect returned logs to prove they came from `trade_ready_conservative` on source hash `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`.
- Latest money-ready candidate: `outputs/CANDIDATE_MONEY_READY_PROFILE.set`, SHA-256 `2A16CEEC337981A925D933C95AD42526A61DDE7CA1EB583FDD597BCC83F2E250`. The matching alias `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set` has the same hash. The EA now includes symbol, trade-readiness, trade-environment, non-bypassable real-account safety locks, approval identity locks, and evidence identity stamps. Audit: `outputs/MONEY_READY_PROFILE_AUDIT.md` shows the guardrail/prep checks and open proof gaps. A staged 53-config local validation package is prepared at `outputs/money_ready_validation_package`, a 10-config broker-proxy package is prepared at `outputs/money_ready_broker_proxy_package`, and `outputs/MONEY_READY_VALIDATION_DECISION.md` is `PENDING` until MT5 results are returned. This is demo/forward-test only, not real-money approved.
- Latest conservative trade-ready candidate: `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`, SHA-256 `F708C68A68016C13C4ADAECFE472A270748F4DAD9F2DF8C12F9870C2324DA13F`. This is stricter than the money-ready profile: `0.10%` trade risk, `0.20%` open-risk cap, `0.01` max lots, one position, max `2` trades/day, `120` minutes between trades, tighter spread/slippage/margin limits, trade-environment guard on, `720` minute loss cooldown, smaller daily/weekly/monthly loss caps, `3.00%` equity drawdown cap, wrong-symbol startup blocked, evidence identity stamped, approval identity locked, and real-account trading blocked by default. Audit: `outputs/TRADE_READY_CONSERVATIVE_AUDIT.md` shows guardrail/pass status plus open proof gaps. Its staged validation package, broker-proxy package, report importer, strict exported-report/stat decision gate, trade-quality gate, Monte Carlo gate, forward/demo gate, and second-broker gate are prepared. Current imported result rows are all `MISSING_REPORT`, and no conservative trade log or external evidence CSV has been returned yet, so the decision remains `PENDING`. This is the safest paper/demo candidate, not a real-money approval.
- Latest static safety result: the manual-only `.github/workflows/static-safety.yml` has both required Python checks. Local results are `STATIC_REPO_SAFETY_AUDIT_PASS` with `25` checks and `STATIC_MQL_COMPILE_PREFLIGHT_PASS` with `39` checks / `476` inputs. See `outputs/STATIC_SAFETY_AUDIT_STATUS.md`.
- Latest trade-quality evidence update: closed-deal logging now records estimated realized R and held bars when initial risk data is available, and `work/analyze_trade_ready_conservative_trade_quality.ps1` writes `outputs/TRADE_READY_CONSERVATIVE_TRADE_QUALITY.md/.csv`. The shared analyzer now requires high realized-R, spread, held-bars, and MFE/MAE coverage so sparse trade logs cannot pass. Current status is `PENDING` with `0` trade-log files found, `0` closed rows, `2` pending gates, and `0` failures.
- Latest Monte Carlo evidence update: `work/analyze_trade_ready_conservative_monte_carlo.ps1` now writes `outputs/TRADE_READY_CONSERVATIVE_MONTE_CARLO.md/.csv`. It shuffles trade order and applies seeded slippage, delay, spread-shock, missed-winner stress, and a 95th-percentile consecutive-loss cap. Current status is `PENDING` with `0` returned trade logs, `0` R trades, `3` pending gates, and `0` failures.
- Latest external evidence update: `work/analyze_trade_ready_conservative_forward_test.ps1` and `work/analyze_trade_ready_conservative_second_broker.ps1` now write explicit forward/demo and second-broker decision files. The shared analyzer now gates expected payoff, Sharpe ratio, and win rate in addition to calendar days, trade count, net profit, PF, drawdown, loss streak, no-red windows, and hash identity. Both remain `PENDING` because no returned evidence CSV has been imported yet.
- Latest live-readiness decision: `work/analyze_trade_ready_live_readiness.ps1` now records both current-source compile identity and exact GitHub publication identity. Those two gates now pass for A167/D045. The final approval gate remains `PENDING` with `7` PASS, `7` PENDING, and `0` FAIL because conservative validation, efficiency, trade quality, Monte Carlo, forward-demo, second-broker, and remaining conservative-audit proof are incomplete.
- Latest money-ready efficiency audit: `work/build_money_ready_efficiency_audit.ps1` writes `outputs/MONEY_READY_EFFICIENCY_AUDIT.md/.csv` without launching MT5, MetaEditor, Git, or GitHub. Current result is `PENDING` with `0` PASS, `17` PENDING, and `0` FAIL because the full 53 validation plus 10 broker-proxy exported MT5 reports are still missing. This audit prevents a profile from becoming money-ready just because it is safe; it must also clear growth, return/drawdown, recent-data, no-red-window, PF, recovery, and broker/stress targets.
- Latest money-ready scorecard: `work/build_money_ready_status_scorecard.ps1` writes `outputs/MONEY_READY_STATUS_SCORECARD.md/.csv` without launching MT5, MetaEditor, Git, or GitHub. Current verdict is `NOT_READY_PENDING_EVIDENCE` with `5` PASS, `15` PENDING, and `0` FAIL.
- Latest release gate: `work/build_trade_ready_release_candidate.ps1` writes `outputs/TRADE_READY_RELEASE_CANDIDATE_DECISION.md/.csv` and a locked release profile without launching MT5, MetaEditor, Git, or GitHub. Current verdict is `NOT_RELEASEABLE_PENDING_EVIDENCE`; `outputs/TRADE_READY_MANUAL_LIVE_REVIEW_PROFILE.set` was not written.
- Latest proof-runway update: `work/build_money_ready_proof_runway.ps1` writes `outputs/MONEY_READY_PROOF_RUNWAY.md/.csv` without launching MT5, MetaEditor, Git, or GitHub. Current first row is `FAILED`: replace or rework the failed first-pass candidate before running more tester work.
- Latest evidence-handoff update: `work/build_money_ready_evidence_handoff.ps1` writes `outputs/MONEY_READY_EVIDENCE_HANDOFF.md`, `outputs/money_ready_evidence_handoff`, and `outputs/money_ready_evidence_handoff.zip` without launching MT5, MetaEditor, Git, or GitHub. Current first-pass run lists are empty until a new candidate is built; live-evidence templates and full conservative validation handoff files remain prepared.
- Latest first-pass hidden-runner update: `work/run_first_pass_package_hidden.ps1` writes `outputs/FIRST_PASS_HIDDEN_RUN_PLAN.md/.csv` in plan mode without launching MT5. Current result is `EMPTY` with `0` current first-pass configs, the MT5 hard lock present, and `0` MT5 processes launched.
- Latest reproducibility-bundle update: `work/build_trade_ready_reproducibility_bundle.ps1` writes `outputs/TRADE_READY_REPRODUCIBILITY_BUNDLE.md`, `outputs/TRADE_READY_REPRODUCIBILITY_BUNDLE_MANIFEST.csv`, `outputs/trade_ready_reproducibility_bundle`, and `outputs/trade_ready_reproducibility_bundle.zip` without launching MT5, MetaEditor, Git, or GitHub. Current result is `PASS` with `83` passing rows; the authoritative zip SHA-256 is recorded in `outputs/TRADE_READY_REPRODUCIBILITY_BUNDLE.md`. It is a local hash freeze only and does not satisfy the live-readiness GitHub sync gate by itself.
- Latest GitHub publication-sync update: `work/audit_github_publication_sync.ps1` writes `outputs/GITHUB_PUBLICATION_SYNC.md/.csv` without launching MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions. Current result is `PENDING` with `0` required source/profile/status artifacts passing, `7` pending, and `0` failed. `work/upload_github_required_source_artifacts.ps1 -PlanOnly` writes `outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md/.csv`; current plan is `READY` with all seven required artifacts marked for update/create once a noninteractive token is available.
- Latest returned-report routing update: `work/route_first_pass_returned_reports.ps1` writes `outputs/FIRST_PASS_RETURNED_REPORT_ROUTING.md/.csv` without launching MT5, MetaEditor, Git, or GitHub. It routes exact-name `.htm/.html/.xml` reports from `outputs/returned_mt5_reports/first_pass_inbox` into the trusted `reports_here` folders, refuses duplicate ambiguity, and now refuses files as `INVALID_REPORT` unless they contain the full required MT5 tester-stat labels: net profit, profit factor, expected payoff, Sharpe ratio, total trades, win rate/profit trades, max consecutive losses, balance/equity drawdown, and recovery factor.
- Latest live-evidence routing update: `work/route_trade_ready_live_evidence.ps1` writes `outputs/TRADE_READY_LIVE_EVIDENCE_ROUTING.md/.csv` without launching MT5, MetaEditor, Git, or GitHub. It routes trade log, forward evidence, and second-broker evidence CSVs from `outputs/returned_mt5_reports/live_evidence_inbox` into the canonical evidence files consumed by the live-readiness analyzers, but now refuses invalid CSVs before copy if required columns, external quality columns, XAUUSD symbol, or expected profile/source identity are missing or wrong.
- Latest compile-evidence routing update: `work/route_mt5_compile_evidence.ps1` writes `outputs/MT5_COMPILE_EVIDENCE_ROUTING.md/.csv` without launching MT5, MetaEditor, Git, or GitHub. It only imports `outputs/MT5_COMPILE_STATUS.csv` after a returned compile log has a standard MetaEditor result line and the returned compiled `.mq5` source copy hashes to the current source.
- Latest one-command refresh update: `work/refresh_money_ready_status.ps1` runs the offline status pipeline end-to-end through hidden/no-window child PowerShell steps and writes `outputs/MONEY_READY_REFRESH_STATUS.md/.csv`. Current result is `FAIL` with `4` passing areas, `10` pending areas, and `2` failed areas because first-pass rejected the active candidate.
- Latest local source manifest: `outputs/SOURCE_MANIFEST.md` records the current `.mq5` size, line count, SHA-256, package counts, and smoke-test status.
- Latest validation decision: the 33-variant R20 opportunity sweep found no new strict under-6% drawdown best. `peak_r20_no_peaktrail_r10` remains the aggressive research frontier after surviving a Model4 continuous check, but it is not promoted because drawdown is about `10.6%`. The follow-up 22-variant R10 drawdown sweep found `r10_profit_guard40` as the best lower-drawdown fallback at Model4 `+$1,000.97` with `7.76%` drawdown, but it is still not trade-ready.
- Live trading status: research only, not live-ready
- GitHub Actions status: keep manual-only to protect monthly Actions usage
- Source status: local folder is not a valid Git checkout right now; `.git` exists but is empty

Current decision: keep the new DGF loss-block profiles as range-elite research leads, while keeping `r10_pg40_atr085_adapt7` as the older low-drawdown benchmark. None are approved for live money.

Return math note: yearly percentages below use a `$1,000` starting balance and CAGR over `2024.01.01` to `2026.07.12` (`2.53` years). Sampled totals are marked score-only because they are not one sequential account curve.

| Item | Current State |
| --- | --- |
| Current research-best | High-profit: `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock`; broad-window stability: `re_may140_late15_dgf_liq_reject1_cush35_dgflossblock`; low-drawdown benchmark: `r10_pg40_atr085_adapt7` |
| What changed | Added default-off DGF no-cushion loss block and validated it on Model1 fast screen plus Model4 real-tick broad windows |
| Best continuous result | `+$10,127.76` on `Model=1`, `2024.01.01` to `2026.07.12`; `+1012.78%` total, `+159.47%/yr` CAGR |
| Most recent reproduced real-tick result | `+$1,195.69` continuous on `Model=4`, `2024.01.01` to `2026.07.12`; `+119.57%` total, `+36.51%/yr` CAGR; produced before the `FF1BCDB0...` safety source update |
| Historical real-tick result | `+$4,507.51` continuous on `Model=4`; `+450.75%` total, `+96.43%/yr` CAGR, but stale until reproduced on current source/compact path |
| Full sampled real-tick total | `+$7,469.00` across the six Model4 validation windows; score-only, not annualized |
| Monthly real-tick gate | LowATR OrderFlow beat Dec-ISLP-Off `+$3,682.17` vs `+$3,637.53`, with `0` losing months vs `1` |
| Quarterly real-tick gate | LowATR OrderFlow beat Dec-ISLP-Off `+$3,435.65` vs `+$3,421.49`, with worst quarter improved from `-$44.64` to `-$30.48` |
| Monthly tester stats | LowATR OrderFlow parsed `31 / 31`, total trades `38`, worst equity DD `30.9408%` |
| Quarterly tester stats | LowATR OrderFlow parsed `11 / 11`, total trades `34`, worst equity DD `30.9408%` |
| Latest code probe | Default-off `FMLR` liquidity-reclaim lane plus isolated `fmlr_tick_speed_reclaim`, `fmlr_activity_blend`, and `fmlr_activity_blend_tight`; tick-speed reclaim lets an existing sweep/reclaim context score as a named path when `InpUseTickSpeedImpulse=true`, while the activity blends combine multiple already-protected structural FMLR triggers at tiny risk. Offline probe package builder now prepares 480 configs; fast screen prepares 162 configs; compact-source prep remains exactly at/below the 600 kept-input cap; MT5 compile/backtest pending because local MT5 launch lock remains on |
| Latest source refinement | FMLR structural-target fallback setups can now participate in the protected structural runner path after a valid forward-liquidity fallback. This is designed to let structurally valid flat-month setups pursue larger moves without loosening entry filters; still code-only, untested, and not promoted |
| Latest flat-month efficiency refinement | FMLR now uses the existing flat-month/catch-up/late-catch-up score and RR discounts inside the FMLR lane, instead of only at the outer signal gate. This should create a controlled way to reduce flat-month inactivity without adding optimizer inputs; still code-only, untested, and not promoted |
| Latest FMLR sizing refinement | FMLR can now use the existing flat-month catch-up risk ramp, capped by the existing flat-month probe risk multiplier, so behind-pace structural FMLR trades are not stuck permanently at tiny size. Code-only, untested, and not promoted |
| Latest package profiles | `fmlr_activity_blend` and `fmlr_activity_blend_tight` are now present in the full and fast FMLR packages as low-risk A/B tests for increasing flat-month participation; no MT5 profit result yet |
| Money-ready candidate | `outputs/CANDIDATE_MONEY_READY_PROFILE.set` is generated for demo/forward testing only with `0.50%` risk, a `0.75%` open-risk cap, `0.05` max lots, one position, Adaptive Reverse off, FMLR research lane off, symbol safety on, trade-environment guard on, real-account trading disabled, trading-cost/spread/margin/loss/profit-giveback guards on, explicit break-even/ATR-trailing/MFE protection, evidence identity stamps, disabled live approval identity fields, and profile hash `2A16CEEC337981A925D933C95AD42526A61DDE7CA1EB583FDD597BCC83F2E250`; `outputs/MONEY_READY_PROFILE_AUDIT.md` currently reports guardrail/prep checks plus open proof gaps |
| Conservative trade-ready candidate | `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set` is generated for paper/demo or tiny-size evaluation with `0.10%` risk, a `0.20%` open-risk cap, `0.01` max lots, one position, max `2` trades/day, `120` minutes between trades, `0.20%` daily loss cap, `0.60%` weekly loss cap, `1.25%` monthly loss cap, `3.00%` equity drawdown cap, hard safety gate on, symbol safety on, trade-environment guard on, real-account trading disabled, Adaptive Reverse/FMLR/tick-speed research modes off, tighter spread/slippage/margin filters, evidence identity stamps, disabled live approval identity fields, and profile hash `F708C68A68016C13C4ADAECFE472A270748F4DAD9F2DF8C12F9870C2324DA13F`; `outputs/TRADE_READY_CONSERVATIVE_AUDIT.md` currently reports open proof gaps and no live approval |
| Money-ready validation package | `outputs/money_ready_validation_package` contains `53` staged configs: `4` fast Model1 checks, `4` exact real-tick continuous/year-split checks, `11` real-tick quarterly checks, `31` real-tick monthly checks, and `3` real-tick stress variants. Run order is fast first, exact Model4 second, quarterly/monthly third, stress last |
| Money-ready broker-proxy package | `outputs/money_ready_broker_proxy_package` contains `10` Model4 broker-condition proxy configs across base, wide-spread, high-commission, tight-slippage, and margin-pressure variants. This approximates broker variation but does not replace testing on another broker's actual XAUUSD contract |
| Money-ready decision gate | `outputs/MONEY_READY_VALIDATION_DECISION.md` is `PENDING` with `1` passing prep gate, `16` pending result gates, and `0` failures because `outputs/MONEY_READY_VALIDATION_RESULTS.csv` and `outputs/MONEY_READY_BROKER_PROXY_RESULTS.csv` have not been returned yet |
| Conservative validation package | `outputs/trade_ready_conservative_validation_package` contains `53` staged configs using the conservative profile: `4` fast Model1 checks, `4` exact real-tick continuous/year-split checks, `11` quarterly Model4 checks, `31` monthly Model4 checks, and `3` stress Model4 variants |
| Conservative broker-proxy package | `outputs/trade_ready_conservative_broker_proxy_package` contains `10` Model4 configs across base, wide-spread, high-commission, tight-slippage, and margin-pressure variants using the conservative profile |
| First-pass validation queue | `outputs/first_pass_validation_queue` contains `22` queued rows for `trade_ready_conservative`, but the current first-pass result is `FAIL`: `1` tester-log row parsed, `0` exported reports parsed, raw decision `8` PASS / `19` PENDING / `2` FAIL, and `0` next-run configs. The old two-candidate comparison can still be rebuilt explicitly, but no stale configs should be run from the cleared package |
| Conservative report importer | `work/import_trade_ready_conservative_validation_reports.ps1` imports exported MT5 `.htm`, `.html`, or `.xml` reports from the conservative package report folders, writes `outputs/TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv` and `outputs/TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv`, reruns the decision gate, and refreshes the audit without launching MT5 |
| Conservative decision gate | `outputs/TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.md` is `PENDING` with `2` passing prep/import gates, `23` pending result/evidence gates, and `0` failures. Current imported rows are `53` validation `MISSING_REPORT` rows and `10` broker-proxy `MISSING_REPORT` rows. Strict trade-ready validation requires exported MT5 reports plus PF/expected-payoff/Sharpe/win-rate/trades/loss-streak/drawdown/recovery stats and `20+` continuous real-tick trades; log-only rows are rejected |
| Conservative trade-quality gate | `outputs/TRADE_READY_CONSERVATIVE_TRADE_QUALITY.md` is `PENDING` because no conservative trade/deal log has been returned yet. The analyzer checks closed trades, profit factor, expectancy, max consecutive losses, realized R, spread, MFE/MAE, held bars, evidence identity, and telemetry coverage |
| Conservative Monte Carlo gate | `outputs/TRADE_READY_CONSERVATIVE_MONTE_CARLO.md` is `PENDING` because no conservative trade/deal log with realized R has been returned yet. The analyzer shuffles trade order and stresses slippage, delay, spread shocks, missed winning trades, drawdown, PF, net R, failure rate, and 95th-percentile loss streaks |
| Conservative forward/demo gate | `outputs/TRADE_READY_CONSERVATIVE_FORWARD_TEST.md` is `PENDING` because no paper/demo evidence CSV has been returned yet. The analyzer requires enough calendar days, enough trades, non-red net profit, PF floor, expected-payoff floor, Sharpe floor, win-rate floor, drawdown cap, loss-streak cap, and matching source/profile hashes when provided |
| Conservative second-broker gate | `outputs/TRADE_READY_CONSERVATIVE_SECOND_BROKER_DECISION.md` is `PENDING` because no second-broker evidence CSV has been returned yet. The analyzer requires non-primary broker identity plus the same profit, PF, expected-payoff, Sharpe, win-rate, drawdown, loss-streak, and hash checks |
| Conservative live-readiness gate | `outputs/TRADE_READY_LIVE_READINESS_DECISION.md` is the final approval gate and is `PENDING` with `5` PASS, `9` PENDING, `0` FAIL. Local reproducibility freeze passes, but GitHub/source-publication sync remains pending through `outputs/GITHUB_PUBLICATION_SYNC.md`. It still requires current-source compile proof, validation pass, money-ready efficiency audit pass, trade-quality pass, Monte Carlo pass, forward/demo evidence, second-broker evidence, local safety, source/profile reproducibility, and real-account lock safety |
| One-command offline refresh | `outputs/MONEY_READY_REFRESH_STATUS.md` is the one-file output from `work/refresh_money_ready_status.ps1`. Current result is `FAIL` with `4` PASS, `10` PENDING, and `2` FAIL because the active first-pass candidate failed |
| First-pass advance wrapper | `outputs/FIRST_PASS_ADVANCE_STATUS.md` remains available for future returned reports, but the current first-pass package is empty with `0` expected reports |
| Money-ready efficiency audit | `outputs/MONEY_READY_EFFICIENCY_AUDIT.md` is the one-file answer for "is the bot profitable enough for the risk?" Current result is `PENDING` with `0` PASS, `17` PENDING, and `0` FAIL because full validation and broker-proxy exported reports are still missing. It requires `12%` annualized return, `10%` CAGR, return/DD >= `3.0`, max DD <= `3%`, no red broad windows, PF/recovery quality, recent-data proof, and broker/stress survival |
| Money-ready status scorecard | `outputs/MONEY_READY_STATUS_SCORECARD.md` is the fastest one-file answer for "is this ready for money?" Current verdict is `NOT_READY_PENDING_EVIDENCE` with `5` PASS, `15` PENDING, and `0` FAIL |
| Release-candidate gate | `outputs/TRADE_READY_RELEASE_CANDIDATE_DECISION.md` is the final artifact gate before any manual live-review profile can exist. Current verdict is `NOT_RELEASEABLE_PENDING_EVIDENCE`; only the locked profile `outputs/TRADE_READY_RELEASE_PROFILE_LOCKED.set` was written |
| Money-ready proof runway | `outputs/MONEY_READY_PROOF_RUNWAY.md` is the exact next-evidence checklist. Current next action is replacing or reworking the failed first-pass candidate; the next-run package has `0` configs |
| Evidence handoff package | `outputs/money_ready_evidence_handoff` and `outputs/money_ready_evidence_handoff.zip` are current. The first-pass run lists are empty until a new candidate is built; full validation, compile, live-evidence files, and CSV templates remain prepared |
| First-pass hidden runner | `work/run_first_pass_package_hidden.ps1` now writes `outputs/FIRST_PASS_HIDDEN_RUN_PLAN.md/.csv` in plan mode. Current state is `EMPTY` with `0` configs and `0` MT5 processes launched; `-Run` remains guarded by the MT5 hard-lock/unlock policy |
| Reproducibility bundle | `outputs/TRADE_READY_REPRODUCIBILITY_BUNDLE.md` is `PASS` with `83` passing rows. It packages the current source, mirrored source, locked profiles, manifests, status decisions, validation package-shape evidence, safety evidence, strict report routers, first-pass advance wrapper/status, money-ready efficiency audit, annualized-return report metrics, connector publication-verification input, required-publication upload plan/helper, first-pass hidden-runner plan/helper/lock test, and GitHub publication-sync audit into a hashed local zip, but it does not clear the live GitHub/source-publication sync gate |
| GitHub publication sync audit | `outputs/GITHUB_PUBLICATION_SYNC.md` is `PASS` with all `7` required artifacts passing, `0` pending, and `0` failed. The maintained A167 source/profile/status freeze matches `Antoee/gold` `main` through connector-verified blob identities |
| First-pass returned-report inbox | `outputs/FIRST_PASS_RETURNED_REPORT_ROUTING.md` shows whether returned `.htm/.html/.xml` reports in `outputs/returned_mt5_reports/first_pass_inbox` were routed into trusted `reports_here` folders. Current state is `0` routed, `0` missing, `0` invalid because no first-pass reports are expected |
| Conservative full-validation report inbox | `outputs/TRADE_READY_CONSERVATIVE_RETURNED_REPORT_ROUTING.md` shows whether returned `.htm/.html/.xml` reports in `outputs/returned_mt5_reports/trade_ready_conservative_validation_inbox` were routed into the conservative validation and broker-proxy `reports_here` folders. Current state is `0` routed, `63` missing, `0` duplicate, `0` invalid, `0` unmatched |
| Live evidence inbox | `outputs/TRADE_READY_LIVE_EVIDENCE_ROUTING.md` shows whether trade log, forward evidence, and second-broker evidence CSVs in `outputs/returned_mt5_reports/live_evidence_inbox` were routed into canonical analyzer inputs. Current state is `0` routed, `3` missing, `0` invalid |
| Compile evidence inbox | `outputs/MT5_COMPILE_EVIDENCE_ROUTING.md` shows `2` routed, `0` missing, `0` invalid, and `1` clean import. `outputs/MT5_COMPILE_STATUS.csv` is current for A167 with `0 errors, 0 warnings` |
| Latest structural-stop refinement | FMLR equal-level structural stops now use the existing stop-cluster extra buffer when the stop anchor itself is an equal-high/low liquidity pool; code-only, untested, and not promoted |
| Latest flat-month cadence refinement | FMLR catch-up/late-catch-up state now affects lane monthly cap and spacing before entries are rejected; code-only, untested, and not promoted |
| Latest shared structure-stop refinement | Previous-day/week/month liquidity levels can now act as shared stop-pocket evidence when the existing liquidity-pocket stop shift is active; code-only, untested, and not promoted |
| Latest protected-loss catch-up refinement | FMLR can use a narrow protected catch-up exception in shallow red months; other flat-month lanes still keep the no-monthly-loss gate |
| Latest profit-capture refinement | FMLR sweep reclaims with forward liquidity and quality evidence can use the existing runner-target stretch path; code-only, untested, and not promoted |
| Old `$866` result | Outdated baseline, no longer the current research-best |
| Live-ready? | No for meaningful real money. Conservative profile is only a paper/demo or tiny-size trade-readiness candidate until MT5 and forward evidence closes the open gaps |
| GitHub Actions | Manual-only; do not use for heavy tester runs |
| Local MT5 safety | Latest audit passed `44 / 44` checks |
| Repository cleanup | Generated logs/temp artifacts archived; active FMLR package kept visible; active cleanup candidates now `0` |

Plain English: the old `$866 in 2.5 years` number is outdated. The newest serious recent-window branch made `+$1,564.01` on a continuous Model4 real-tick screen and `+$1,716.76` on Model1, with all 2024/2025/2026 Model1 splits green. That is a real improvement over the old baseline, but it failed older-year robustness. The drawdown sweep found a lower-risk fallback, `r10_profit_guard40`, at `+$1,000.97` Model4 with `7.76%` drawdown, but its 2019-2026 yearly pass still had `2` losing years and `12.78%` worst drawdown. The current choice is basically: stricter R20 style is safer but too small/sparse; no-peak-trail R10 makes more but swings harder; profit-guard R10 is more balanced in recent data but not robust enough yet.

Future-data warning: testing 2024 through 2026 is useful because it is recent, but it does not mean the EA will keep working forever without maintenance. That period is now research-seen data. A real deployment path still needs frozen out-of-sample tests, walk-forward validation, stress testing, broker variation, and demo/forward monitoring with clear disable/revalidation rules.

## How To Check Progress Without Asking Codex

Open these files on GitHub in this order:

1. `README.md` - highest-level status, current best, latest decision, and next task.
2. `outputs\MONEY_READY_REFRESH_STATUS.md` - one-command offline refresh summary after running `work/refresh_money_ready_status.ps1`.
3. `outputs\FIRST_PASS_ADVANCE_STATUS.md` - one-command first-pass advance summary after returning a first-pass MT5 report and running `work/advance_first_pass_after_report.ps1`.
4. `outputs/MONEY_READY_EFFICIENCY_AUDIT.md` - stricter answer for whether the bot is profitable enough for the risk.
5. `outputs/MONEY_READY_STATUS_SCORECARD.md` - fastest answer for whether the bot is ready for money.
6. `outputs/TRADE_READY_RELEASE_CANDIDATE_DECISION.md` - whether a live-review profile is allowed to exist.
7. `outputs/MONEY_READY_PROOF_RUNWAY.md` - exact next evidence to run, where to return it, and what it unlocks.
8. `outputs/MONEY_READY_EVIDENCE_HANDOFF.md` - generated handoff summary for the first-pass run list and live-evidence templates.
9. `outputs/FIRST_PASS_RETURNED_REPORT_ROUTING.md` - whether returned first-pass MT5 reports were routed correctly.
10. `outputs/TRADE_READY_CONSERVATIVE_RETURNED_REPORT_ROUTING.md` - whether returned full conservative validation and broker-proxy MT5 reports were routed correctly.
11. `outputs/TRADE_READY_LIVE_EVIDENCE_ROUTING.md` - whether returned live-readiness evidence CSVs were routed correctly.
12. `outputs/MT5_COMPILE_EVIDENCE_ROUTING.md` - whether returned compile proof was routed and imported for the current source hash.
13. `outputs/CURRENT_RESEARCH_BEST_PROFILE.md` - current promoted profile and exact `.set` identity.
14. `outputs/MONEY_READY_PROFILE_AUDIT.md` - guardrail audit for the demo/forward-test candidate and the open proof gaps.
15. `outputs/TRADE_READY_CONSERVATIVE_PROFILE.md` - strictest current candidate profile and what it is allowed to do.
16. `outputs/TRADE_READY_CONSERVATIVE_AUDIT.md` - guardrail audit for the conservative profile.
17. `outputs/TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.md` - automatic pass/fail/pending gate for the conservative candidate.
18. `outputs/TRADE_READY_CONSERVATIVE_VALIDATION_REPORT_METRICS.md` - conservative report import metrics and missing/unparsed report list.
19. `outputs/TRADE_READY_CONSERVATIVE_TRADE_QUALITY.md` - trade-quality gate for returned conservative EA trade/deal logs.
20. `outputs/TRADE_READY_CONSERVATIVE_MONTE_CARLO.md` - seeded trade-order/slippage/delay/spread-shock stress gate for returned conservative trade logs.
21. `outputs/TRADE_READY_CONSERVATIVE_FORWARD_TEST.md` - forward paper/demo evidence gate.
22. `outputs/TRADE_READY_CONSERVATIVE_SECOND_BROKER_DECISION.md` - second-broker evidence gate.
23. `outputs/TRADE_READY_LIVE_READINESS_DECISION.md` - final approval gate for whether the conservative profile can be considered for live use.
24. `outputs/FIRST_PASS_VALIDATION_QUEUE_DECISION.md` - fast pass/fail/pending screen for the conservative vs money-ready candidates.
25. `outputs/FIRST_PASS_VALIDATION_QUEUE_CANDIDATE_RANKING.csv` - first-pass candidate recommendation: wait, reject, or promote to full validation.
26. `outputs/FIRST_PASS_REFRESH_STATUS.md` - one-command refresh status: parsed reports, recommendations, next batch, mini-package readiness, and parallel lane readiness.
27. `outputs/LOWATR_LOCKED_FAST_SCREEN_SUMMARY.md` - latest hidden local LowATR locked/risk-shape fast-screen comparison, including the `+$8,437.54` research-only result and rejected safer variants.
28. `outputs/FIRST_PASS_EVIDENCE_INTEGRITY.md` - verifies returned reports match expected candidate/rank/report paths before evidence is trusted.
29. `outputs/FIRST_PASS_TRUSTED_DECISION.md` - action gate that only promotes a candidate if raw ranking and evidence integrity both pass.
30. `outputs/FIRST_PASS_NEXT_RUN_BATCH.md` - shortest useful next tester batch; currently empty after the active candidate failed first-pass.
31. `outputs/FIRST_PASS_NEXT_RUN_PACKAGE.md` - mini package containing only the currently selected batch configs.
32. `outputs/FIRST_PASS_PARALLEL_LANES.md` - window-based lane folders for running the current first-pass configs in parallel chunks.
33. `outputs/FIRST_PASS_HIDDEN_RUN_PLAN.md` - no-window first-pass runner plan; currently empty because no first-pass configs are selected.
34. `outputs/FIRST_PASS_VALIDATION_QUEUE_REPORT_METRICS.md` - imported report metrics for the first-pass queue.
35. `outputs/FIRST_PASS_VALIDATION_QUEUE.md` - faster early-screen queue before spending time on every full validation config.
36. `outputs/MONEY_READY_VALIDATION_DECISION.md` - automatic pass/fail/pending gate for returned MT5 validation results.
37. `outputs/SOURCE_MANIFEST.md` - current local `.mq5` source hash, size, and smoke-test status.
38. `outputs/VALIDATION_PACKAGE_SHAPE_GATE.md` - proof that the conservative validation package has all `53` required rows before profit gates are trusted.
39. `outputs/TRADE_READY_REPRODUCIBILITY_BUNDLE.md` - local source/profile/status hash freeze for reproducing the current evidence state.
40. `outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md` - exact no-window plan for updating the seven pending required publication artifacts on GitHub while skipping already-matching rows.
41. `research/` - human-readable notes explaining why a change was promoted or rejected.
42. `outputs/*DECISION_SUMMARY.csv` - compact result tables for each validation package.
43. `outputs/*PROFILE_SUMMARY.csv` - profile totals, losing-window counts, and worst windows.

What to look for:

- `Promoted` means the change became the new research-best.
- `Rejected` means it was tested and did not beat the current best.
- `Probe only` means the result was useful, but not enough to trust yet.
- `NO_REPORT` means MT5 did not export full reports, so only parsed log results should be trusted.
- `Model=4` means real ticks, which matters most for serious validation.

## Current Work Queue

Next local work:

1. Close the GitHub source-publication blocker with `outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md`: publish the seven pending required artifacts using `work/upload_github_required_source_artifacts.ps1` when a noninteractive token is available, or refresh the GitHub connector auth and rerun the connector upload. Current session check: local `git` missing, `GH_TOKEN`/`GITHUB_TOKEN` absent, connector token expired.
2. Diagnose the older-year failures in 2019, 2021, 2022, and 2023 before any promotion attempt. The next useful change is a regime/market-phase filter or failure-specific entry filter, not more risk.
3. Rebuild a candidate only after it has a reason to avoid the older-year red windows while keeping the 2024-2026 edge. Do not simply disable individual years or increase risk to make a failed profile look profitable.
4. Run the 162-config fast FMLR screen from `work/build_flat_month_liquidity_reclaim_fast_probe_package.ps1` only if it is packaged as a first-pass candidate and still respects the no-martingale/no-grid risk rules; only run the full 480-config `FMLR` package if a candidate beats `lowatr_current` without adding red control windows. Keep Adaptive Reverse off.
5. Investigate why the historical `+$4,507.51` Dec-ISLP-Off continuous result is not reproduced by the current local source/compact path.
6. Rerun Model1, Model2, and eventually Model4 validation on a LowATR risk shape only after the fast screen clears drawdown/recovery gates.
7. Return conservative EA trade/deal logs and rerun `work/analyze_trade_ready_conservative_trade_quality.ps1` plus `work/analyze_trade_ready_conservative_monte_carlo.ps1`; these check trade quality and seeded execution/order-stress robustness.
8. Return forward/demo evidence to `outputs/TRADE_READY_CONSERVATIVE_FORWARD_TEST_EVIDENCE.csv` and second-broker evidence to `outputs/TRADE_READY_CONSERVATIVE_SECOND_BROKER_EVIDENCE.csv`, then rerun the matching evidence analyzers.
9. Run older-data, walk-forward, and true second-broker validation before considering live use.
10. Attack zero-trade periods with a different entry mechanism; FSD relaxation and FMW tied current, FMP reduced winners, FMB/FMR added losing trades, and month-filter bypass added losses.
11. Keep all heavy tests local and hidden, not on GitHub Actions.

Repository cleanup completed on 2026-07-12 and refreshed on 2026-07-13:

- Archived generated runtime/log/temp artifacts and old MT5 package folders into `archive/generated_artifacts_*`.
- Compressed old archive folders into ignored zip files.
- Removed active `outputs/offline_refresh_logs/`.
- Archived the generated FMB/FMR/FMW/FMP/liquidity-stop package folders/logs and generated compact/tester `.mq5` sources.
- Archived the latest block-diagnostics, month-filter bypass, March/May risk-shape, and continuous-check package folders/logs plus generated compact `.mq5` sources.
- Archived the bulky raw block-diagnostics dump after keeping the summarized diagnostic CSVs.
- Kept the active 480-config untested FMLR probe package visible at `outputs/flat_month_liquidity_reclaim_probe_package`.
- Kept the 162-config fast FMLR screen package visible at `outputs/flat_month_liquidity_reclaim_fast_probe_package`.
- Archived the generated FMLR compact tester source after verification; rerun compact-source prep before MT5 compile/backtest.
- Latest generated compact-source archive: `archive/generated_artifacts_20260713_failed_breakout_trap.zip`.
- Latest generated external-package archive: `archive/generated_artifacts_20260713_failed_breakout_trap_external_package.zip`.
- Latest generated target-refinement archive: `archive/generated_artifacts_20260713_failed_breakout_target.zip`.
- Latest generated target-priority archive: `archive/generated_artifacts_20260713_failed_breakout_target_priority.zip`.
- Latest generated target-fallback external-package archive: `archive/generated_artifacts_20260713_failed_breakout_target_fallback_external_package.zip`.
- Latest generated forward-target-selector external-package archive: `archive/generated_artifacts_20260713_fmlr_forward_target_selector_external_package.zip`.
- Latest generated forward-clearance-selector external-package archive: `archive/generated_artifacts_20260713_fmlr_forward_clearance_selector_external_package.zip`.
- Latest generated forward-RR-target external-package archive: `archive/generated_artifacts_20260713_fmlr_forward_rr_target_external_package.zip`.
- Latest generated structural-target-fallback external-package archive: `archive/generated_artifacts_20260713_fmlr_structural_target_fallback_external_package.zip`.
- Latest generated structural-target-priority external-package archive: `archive/generated_artifacts_20260713_fmlr_structural_target_priority_external_package.zip`.
- Latest generated protected-runner-target-path external-package archive: `archive/generated_artifacts_20260713_fmlr_protected_runner_target_path_external_package.zip`.
- Latest generated runner-phase-consistency external-package archive: `archive/generated_artifacts_20260713_fmlr_runner_phase_consistency_external_package.zip`.
- Latest generated structural-target-runner-eligibility external-package archive: `archive/generated_artifacts_20260713_fmlr_structural_target_runner_eligibility_external_package.zip`.
- Latest generated structural-target-unlimited-runner external-package archive: `archive/generated_artifacts_20260713_fmlr_structural_target_unlimited_runner_external_package.zip`.
- Latest generated unlimited-runner-stretch-evidence external-package archive: `archive/generated_artifacts_20260713_fmlr_unlimited_runner_stretch_evidence_external_package.zip`.
- Latest generated structure-trail broker-distance external-package archive: `archive/generated_artifacts_20260713_fmlr_structure_trail_broker_distance_external_package.zip`.
- Latest generated structural-fallback-runner external-package archive: `archive/generated_artifacts_20260713_fmlr_structural_fallback_runner_external_package.zip`.
- Latest generated FMLR catch-up threshold external-package archive: `archive/generated_artifacts_20260713_fmlr_catch_up_threshold_external_package.zip`.
- Latest generated FMLR catch-up risk external-package archive: `archive/generated_artifacts_20260713_fmlr_catch_up_risk_external_package.zip`.
- Latest generated FMLR catch-up cadence external-package archive: `archive/generated_artifacts_20260713_fmlr_catch_up_cadence_external_package.zip`.
- Latest generated FMLR equal-level stop-pool external-package archive: `archive/generated_artifacts_20260713_fmlr_equal_level_stop_pool_external_package.zip`.
- Latest generated shared structure-stop equal-level cluster archive: `archive/generated_artifacts_20260713_structure_stop_equal_level_cluster.zip`.
- Latest generated FMLR protected-loss catch-up archive: `archive/generated_artifacts_20260713_fmlr_protected_loss_catch_up.zip`.
- Latest generated FMLR sweep-runner target archive: `archive/generated_artifacts_20260713_fmlr_sweep_runner_target.zip`.
- Latest generated Adaptive Reverse alternating-loss external-package archive: `archive/generated_artifacts_20260713_adaptive_reverse_alternating_loss_external_package.zip`.
- Archived `1,505` loose generated MT5 `.ini` configs from `work/` into `archive/generated_artifacts_20260713_034054.zip`; manifest: `outputs/REPO_CLEANUP_LOOSE_WORK_CONFIGS_ARCHIVE_MANIFEST.csv`.
- Compressed the remaining expanded archive folders into ignored zip files.
- Active generated cleanup candidates after latest pass: `0`.
- Local file count reduced from about `46k` files to `3,255` files after the latest FMLR rebuild and cleanup verification.
- Local workspace size after latest zip cleanup: about `118.73 MB`.
- `work/` reduced from about `143 MB` to about `2.42 MB`.
- `outputs/` size after latest package rebuild: about `38.25 MB`.
- `archive/` size after latest package rebuild: about `76.66 MB`.
- `outputs/` now keeps current promoted validation package folders, the active FMLR package, root evidence CSV/source artifacts, and only one canonical `.mq5` source copy.
- Latest cleanup notes: `research/2026-07-12-repository-cleanup-note.md`; `research/2026-07-13-repository-cleanup-refresh-note.md`

Known cautions:

- The full local EA source is too input-heavy for MT5 Strategy Tester, so current validation packages use compact tester-source generation until the input surface is reduced.
- This workspace is not currently a valid Git checkout. The `.git` directory exists but is empty, so GitHub publishing needs a fresh clone/sync path or connector credentials.

## Current Best Profile

Profile name:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Generated locally by:

`work/build_realtick_islp_lowatr_orderflow_probe_package.ps1`

Local generated `.set` file:

`outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`

SHA-256:

`D0867E0333D3F110EF47410A2B2FF46402AAD96FC70B0DBF9506836124D633BC`

Important GitHub note: the status files and generated `.set` can be synced, but the full local EA source may still be ahead of GitHub. Treat GitHub as the research dashboard unless the source-sync section says otherwise.

## Latest Promoted Result

December ISLP guard validation:

These `total` rows are aggregate sampled-window validation scores. They are useful for comparing profiles, but they are not a single account curve, so yearly percent is not applicable.

| Model | Previous No-M1-Shock | Dec-ISLP-Off | Annualized % | Decision |
| --- | ---: | ---: | --- | --- |
| Model0 total | `+$4,495.93` | `+$8,768.34` | N/A, sampled score | Guard wins |
| Model1 total | `+$14,739.08` | `+$15,361.76` | N/A, sampled score | Guard wins |
| Model2 total | `+$17,890.63` | `+$15,361.76` | N/A, sampled score | Previous wins |
| Model4 real-tick total | `+$4,075.62` | `+$7,469.00` | N/A, sampled score | Guard wins |

Continuous-window comparison:

These rows are continuous account tests, so yearly percent can be calculated from the `$1,000` start over `2.53` years.

| Model | Previous No-M1-Shock | Previous CAGR/yr | Dec-ISLP-Off | Dec CAGR/yr |
| --- | ---: | ---: | ---: | ---: |
| Model0 continuous | `+$1,288.93` | `+38.78%/yr` | `+$5,386.54` | `+108.29%/yr` |
| Model1 continuous | `+$9,753.58` | `+155.98%/yr` | `+$10,127.76` | `+159.47%/yr` |
| Model2 continuous | `+$12,054.55` | `+176.39%/yr` | `+$10,127.76` | `+159.47%/yr` |
| Model4 real-tick continuous | `+$1,288.93` | `+38.78%/yr` | `+$4,507.51` | `+96.43%/yr` |

Why it was promoted:

- Diagnostics showed the Q4 2024 real-tick red window came from one December ISLP loss.
- Disabling December ISLP removed that weak window.
- Model0, Model1, and Model4 improved.
- Model2 is the caveat: it still prefers the previous no-m1-shock profile.

## Latest Monthly Real-Tick Gate

Wider monthly real-tick validation was run on 2026-07-12:

- Package: `outputs/realtick_dec_islp_monthly_validation_package`
- Runner CSV: `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_RUN.csv`
- Configs: `62`
- Report files: `62 / 62` returned `NO_REPORT`
- Log parsing: recovered `62 / 62` final-balance results
- Result: Dec-ISLP-Off beat prior no-m1-shock `+$3,779.52` vs `+$3,687.00`
- Losing months: Dec-ISLP-Off `0`, prior no-m1-shock `2`
- Decision: validation credit for monthly net-profit comparison only; no full drawdown/trade-stat credit

Current local safety after that attempt:

- `work/MT5_LOCAL_LAUNCH_DISABLED.lock` restored
- MT5 safety audit: `PASS`, `44 / 44`

## Latest Quarterly Real-Tick Gate

Quarterly real-tick validation was run on 2026-07-12:

- Package: `outputs/realtick_dec_islp_quarterly_validation_package`
- Runner CSV: `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_RUN.csv`
- Configs: `22`
- Report files: `22 / 22` returned `NO_REPORT`
- Log parsing: recovered `22 / 22` final-balance results
- Result: Dec-ISLP-Off beat prior no-m1-shock `+$3,455.89` vs `+$3,404.59`
- Losing quarters: Dec-ISLP-Off `0`, prior no-m1-shock `1`
- Decision: supports keeping Dec-ISLP-Off promoted for net-profit/quarter comparison

## Latest Code Probe

Default-off Flat Month Liquidity Reclaim (`FMLR`) lane was added on 2026-07-13:

- Intent: attack zero-trade/flat months with a different entry mechanism instead of loosening the rejected FSD/FMB/FMR lanes.
- Entry idea: require a recent liquidity sweep and reclaim, session/Asian range reclaim, equal-level reclaim, confirmed swing sweep reclaim, previous day/week reclaim, daily-open reclaim, weekly/monthly-open reclaim, wick rejection, close-location strength, optional VWAP reclaim, and optional order-flow confirmation.
- Stop/target idea: use a direct structure stop beyond the swept liquidity level, opposite side of a compression box, opposite side of an Asian/rolling session range, beyond a failed opening-range edge, beyond a VWAP-deviation local extreme, beyond a failed Asian/rolling range edge, beyond a swept previous day/week/month level, or behind an FVG/order-block/CHoCH continuation or retest structure, with optional equal-level and previous-day/week extensions, optional liquidity-cluster buffer, optional proximity-limited confirmed swing stop anchor, optional swing/open-aware pocket shift, and test forward-liquidity, daily/weekly/monthly open target, session/Asian target, swing-target, runner-target stretch toward uncapped forward liquidity, FVG-structural-retest, imbalance-retest, imbalance-continuation, CHoCH-retest, forward-clearance, phase-alignment, recent-sweep retest, continuation-retest, compression-breakout, session-range breakout, opening-range reclaim, VWAP-deviation reclaim, range-failure reclaim, and HTF liquidity reclaim variants instead of relying only on ATR take-profit distance.
- Regime idea: the new phase-aligned candidate allows trend-pullback and range-reclaim phases, blocks the unclear transition phase, requires trend EMA slope in trend mode, and requires bounded net move plus candle alternation in range mode.
- Risk: defaults to low risk through `InpFlatMonthLiquidityReclaimRiskMultiplier=0.20`.
- Status: code-only/default-off. Not promoted, not backtested, not live-ready.
- Offline package builder: `work/build_flat_month_liquidity_reclaim_probe_package.ps1`, with current, conservative, balanced, tiny-risk VWAP discovery, liquidity-target, recent-sweep retest, continuation-retest, compression-breakout, breakout-retest, failed-breakout trap, session-range breakout, opening-range reclaim, VWAP-deviation reclaim, range-failure reclaim, HTF liquidity reclaim, previous-month target, previous-month reclaim, sweep-displacement BOS, sweep-runner, sweep-unlimited-runner, displacement-pullback, engulfing reclaim, tick-pressure reclaim, tick-speed reclaim, FMLR activity blend, tight FMLR activity blend, FVG structural retest, order-block retest, CHoCH retest, imbalance-continuation, runner-target stretch, structural-runner trail, structural scale-in, catch-up risk, shelf-retest, session-target, imbalance-retest, swing-target, phase-aligned, and structural-stop variants across 12 weak/flat/control windows, now 480 configs total.
- Fast screen builder: `work/build_flat_month_liquidity_reclaim_fast_probe_package.ps1`, 162 configs total: `lowatr_current`, `fmlr_opening_range_reclaim`, `fmlr_vwap_deviation_reclaim`, `fmlr_range_failure_reclaim`, `fmlr_htf_reclaim`, `fmlr_previous_month_target`, `fmlr_previous_month_reclaim`, `fmlr_sweep_displacement_bos`, `fmlr_sweep_runner`, `fmlr_sweep_unlimited_runner`, `fmlr_displacement_pullback`, `fmlr_breakout_retest`, `fmlr_failed_breakout_trap`, `fmlr_engulfing_reclaim`, `fmlr_tick_pressure_reclaim`, `fmlr_tick_speed_reclaim`, `fmlr_activity_blend`, `fmlr_activity_blend_tight`, `fmlr_fvg_retest`, `fmlr_order_block_retest`, `fmlr_choch_retest`, `fmlr_imbalance_continuation`, `fmlr_runner_target_stretch`, `fmlr_structural_runner`, `fmlr_structural_scale_in`, `fmlr_catch_up_risk`, and `fmlr_shelf_retest` across `2024_10`, `2025_04`, `2025_06`, `2026_01`, `2026_05`, and `2026_06`.
- Compact-source prep: `work/prepare_flat_month_liquidity_reclaim_compact_source.ps1`, guarded by `work/test_flat_month_liquidity_reclaim_compact_source.ps1`; the generated compact `.mq5` source is archived during cleanup and should be rebuilt immediately before MT5 compile/backtest.
- Latest structural-runner refinement: when `InpFlatMonthLiquidityReclaimUseStructureTrail` is enabled, only positions tagged `FMLR;` can trail behind confirmed swing pivots after `InpFlatMonthLiquidityReclaimStructureTrailStartR`; this uses the existing FMLR swing and stop-pocket buffer settings, moves only to a better stop, and logs `FMLR structure trail` on successful structural trail modifications. If a no-fixed-TP FMLR runner reaches the trigger before a confirmed swing pivot is available, a no-new-input fallback can lock a small positive stop with `FMLR structure trail fallback lock` instead of leaving the runner fully exposed. The `fmlr_structural_runner` profile qualifies for `FMLR structural unlimited runner;`, and the isolated `fmlr_sweep_unlimited_runner` profile can qualify for `FMLR sweep unlimited runner;`: no fixed TP is placed, but the planned stretched target still has to pass minimum RR and spread-adjusted RR before the trade opens. Adaptive Reverse remains off.
- Latest scale-in refinement: `InpWinnerScaleInAllowFlatMonthLiquidityReclaim` is default-off and only matters when winner scale-in is already enabled; the `fmlr_structural_scale_in` profile uses it with protected stop, locked-R, quality, spacing, equity, and open-profit-cover requirements so the probe adds only small risk to already-profitable strict FMLR runners.
- Latest shelf-retest refinement: `InpFlatMonthLiquidityReclaimUseShelfRetest` and `InpFlatMonthLiquidityReclaimRequireShelfRetest` are default-off; the isolated `fmlr_shelf_retest` profile requires a recent sweep/reclaim of a structural shelf, then a current candle retest of that shelf with body and close-location confirmation, and anchors the stop behind the swept/retested shelf instead of using ATR alone.
- Latest displacement-pullback refinement: `InpFlatMonthLiquidityReclaimUseDisplacementPullback` and `InpFlatMonthLiquidityReclaimRequireDisplacementPullback` are default-off; the isolated `fmlr_displacement_pullback` profile requires a prior displacement/BOS break, then a controlled current-bar pullback retest of that break level, with the stop anchored behind the pullback and displacement candle instead of using ATR alone.
- Latest breakout-retest refinement: `InpFlatMonthLiquidityReclaimUseBreakoutRetest` and `InpFlatMonthLiquidityReclaimRequireBreakoutRetest` are default-off; the isolated `fmlr_breakout_retest` profile waits for a compression-box break with volume expansion, then requires a controlled current-bar retest/hold of the broken boundary, with the stop anchored behind the opposite side of the box instead of using ATR alone.
- Latest failed-breakout-trap refinement: `InpFlatMonthLiquidityReclaimUseFailedBreakoutTrap` and `InpFlatMonthLiquidityReclaimRequireFailedBreakoutTrap` are default-off; the isolated `fmlr_failed_breakout_trap` profile waits for a prior compression-box break to fail, then requires a current snapback/reclaim candle with optional volume expansion, range-phase gating, forward-clearance checks, and a stop behind the failed-break wick/box structure.
- Latest failed-breakout target refinement: no new inputs; the trap now returns the opposite side of its compression box as a structural range target and logs `FMLR failed breakout target;` / `FMLR failed breakout range target;` when that target path is used.
- Latest failed-breakout target-priority refinement: no new inputs; generic FMLR liquidity targets no longer overwrite the failed-breakout box target once it is accepted. The EA logs `FMLR liquidity target preserved;` when it keeps the trap's own range target while still recognizing forward liquidity context.
- Latest failed-breakout target-fallback refinement: no new inputs; when the failed-breakout box target is too close to satisfy the range-target minimum, the setup can now use the existing forward-liquidity target instead of being rejected immediately. The EA logs `FMLR failed breakout target fallback;` when this path is used.
- Latest forward-target selector refinement: no new inputs; `FlatMonthLiquidityReclaimForwardLiquidityDistance` now applies the minimum target distance while collecting candidates, so a too-close equal/open/session/swing level cannot veto a farther valid forward-liquidity target.
- Latest forward-clearance selector refinement: no new inputs; the FMLR forward-clearance gate now passes its minimum clearance distance into the same selector, so a too-close liquidity level cannot veto a farther valid clearance level.
- Latest forward-RR target refinement: no new inputs; if structural stop widening makes a valid FMLR setup fail minimum RR, the EA can use an existing forward-liquidity target to repair RR, but only when that target still satisfies `InpFlatMonthLiquidityReclaimMinRR`. The EA logs `FMLR forward RR target;` when this path is used.
- Latest structural-target fallback refinement: no new inputs; if an HTF, opening-range, VWAP-deviation, or range-failure structural target is invalid or too close, the setup can defer rejection and use an existing valid forward-liquidity target instead. If no valid fallback exists, the original structural-target rejection remains. The EA logs `FMLR structural target fallback;` when this path is used.
- Latest structural-target priority refinement: no new inputs; if an HTF, opening-range, VWAP-deviation, or range-failure structural target is accepted, a generic forward-liquidity target can extend it when farther but cannot shrink it when closer. The EA logs `FMLR structural target preserved;` or `FMLR structural target extended;` for these paths.
- Latest protected-runner target-path refinement: no new inputs; FMLR runner-stretch protection now uses the shared `structuralTargetAccepted` flag instead of a duplicated structural-target list, so accepted VWAP-deviation structural targets count as protected runner paths.
- Latest runner-phase consistency refinement: no new inputs; FMLR runner phase permission now reuses the shared `structuralRunnerSetup` flag instead of a duplicated setup list, so session-range and compression breakout runner setups are not excluded by stale phase-gate logic.
- Latest structural-target runner eligibility refinement: no new inputs; accepted HTF, opening-range, VWAP-deviation, range-failure, and failed-breakout structural targets now qualify as `structuralTargetRunnerSetup` under the existing runner-stretch controls. The EA logs `FMLR structural target runner;` when this path participates.
- Latest structural-target unlimited-runner refinement: no new inputs; `FlatMonthLiquidityReclaimUnlimitedRunnerAllows` now keeps the original strict sweep runner path and adds a structural-target runner path that requires both `FMLR structural target runner;` and `FMLR forward clearance;` evidence before allowing the no-fixed-TP FMLR runner.
- Latest unlimited-runner stretch-evidence refinement: no new inputs; FMLR no-fixed-TP runner permission now requires `runnerStretchEvidence`, meaning either `FMLR runner target stretch;` or `FMLR runner liquidity stretch;` must be present in the signal before the unlimited runner can open.
- Latest structure-trail broker-distance refinement: no new inputs; confirmed-swing FMLR structure trails now use `structureTrailMinDistance = MinimumBrokerStopDistance()` before accepting a trail stop, matching the broker-distance realism already used by the fallback lock.
- Latest structural-fallback runner refinement: no new inputs; structural-target fallback setups that use a valid forward-liquidity target can now qualify as protected structural runner setups. The EA logs `FMLR structural fallback runner;` before `FMLR structural target runner;` when this fallback path participates.
- Latest FMLR catch-up threshold refinement: no new inputs; `activeFmlrMinScore` and the active FMLR minimum RR now apply the existing flat-month, catch-up, and late-catch-up discounts inside `FlatMonthLiquidityReclaimOpportunity`. The EA logs `FMLR active min score ...;` and `FMLR active min RR ...;` when the lane threshold is relaxed.
- Latest FMLR catch-up risk refinement: no new inputs; `ActiveFlatMonthLiquidityReclaimRiskMultiplier()` lets FMLR ramp from its base risk multiplier toward `InpFlatMonthProbeRiskMultiplier` only when the existing catch-up risk ramp, protected-floor, and liquid-session gates allow it. The EA logs `FMLR active risk x...;` when this capped ramp is active. The isolated `fmlr_catch_up_risk` package profile now tests this path by keeping the strict structural-runner setup and enabling only `InpUseFlatMonthCatchUpEntryRelaxation`, `InpUseFlatMonthLateCatchUp`, and `InpUseFlatMonthCatchUpRiskRamp`.
- Latest engulfing-reclaim refinement: `InpFlatMonthLiquidityReclaimUseEngulfingReclaim` and `InpFlatMonthLiquidityReclaimRequireEngulfingReclaim` are default-off; the isolated `fmlr_engulfing_reclaim` profile requires a sweep of recent structure, an opposite-body engulfing reversal candle, body/close-location quality, and a stop anchored behind the swept/engulfed structure instead of using ATR alone.
- Latest tick-pressure reclaim refinement: `InpFlatMonthLiquidityReclaimUseTickPressureReclaim` and `InpFlatMonthLiquidityReclaimRequireTickPressureReclaim` are default-off; the isolated `fmlr_tick_pressure_reclaim` profile requires a sweep/reclaim plus directional tick-volume pressure, aligned bars, current-bar volume expansion, body/close-location quality, and a stop anchored behind the swept structure instead of using ATR alone.
- Latest FVG structural retest refinement: `InpFlatMonthLiquidityReclaimUseFvgRetest` and `InpFlatMonthLiquidityReclaimRequireFvgRetest` are default-off; the isolated `fmlr_fvg_retest` profile requires a valid fair-value gap, directional impulse, structural break, then a controlled current-bar retest/hold of the gap, with the stop anchored behind the gap and impulse structure instead of using ATR alone.
- Latest order-block retest refinement: `InpFlatMonthLiquidityReclaimUseOrderBlockRetest` and `InpFlatMonthLiquidityReclaimRequireOrderBlockRetest` are default-off; the isolated `fmlr_order_block_retest` profile requires an opposite candle order block, a later displacement break, then a controlled current-bar retest/hold of that block, with the stop anchored behind the block instead of using ATR alone.
- Latest CHoCH retest refinement: `InpFlatMonthLiquidityReclaimUseChochRetest` and `InpFlatMonthLiquidityReclaimRequireChochRetest` are default-off; the isolated `fmlr_choch_retest` profile requires a prior lower-low or higher-high context, a CHoCH break through the prior swing boundary, then a controlled retest/hold of that broken level, with the stop anchored behind the retest and break structure instead of using ATR alone.
- Latest FMLR entry surface summary: the lane now includes same-candle liquidity reclaims, structural retests, breakout retests, failed-breakout traps, imbalance continuation, runner/scale-in/catch-up-risk/sweep-runner/tick-speed research profiles, activity-blend package profiles, and structural stop-pocket controls. The newest package profiles include `fmlr_activity_blend` and `fmlr_activity_blend_tight`. Compact-source audit remains under the `600` kept-input cap.
- Local checks: `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`; `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`; `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`; `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`; `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`; `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`; `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`; `OFFLINE_REFRESH_QUIET_MODE_SMOKE_PASS`; MT5 local safety audit `PASS 44 / 44`.
- Compile/backtest status: pending because `work/MT5_LOCAL_LAUNCH_DISABLED.lock` remains active to protect against MT5/MetaEditor focus stealing.
- Expected-payoff gate note: `research/2026-07-13-expected-payoff-gate-note.md`
- Win-rate gate note: `research/2026-07-13-win-rate-validation-gate-note.md`
- Consecutive-loss gate note: `research/2026-07-13-consecutive-loss-validation-gate-note.md`
- Continuous trade-count note: `research/2026-07-13-continuous-trade-count-gate-note.md`
- Sharpe gate note: `research/2026-07-13-sharpe-validation-gate-note.md`
- Evidence-handoff strict metrics note: `research/2026-07-13-evidence-handoff-strict-metrics-note.md`
- External evidence quality gates note: `research/2026-07-13-external-evidence-quality-gates-note.md`
- First-pass quality gates note: `research/2026-07-13-first-pass-quality-gates-note.md`
- Trade-log coverage and Monte Carlo loss-run note: `research/2026-07-13-trade-log-coverage-and-monte-carlo-loss-run-note.md`
- Research note: `research/2026-07-13-flat-month-liquidity-reclaim-lane-note.md`
- Phase-gate note: `research/2026-07-13-fmlr-phase-aligned-gate-note.md`
- Structural-stop note: `research/2026-07-13-fmlr-structural-stop-pocket-note.md`
- Session/Asian reclaim note: `research/2026-07-13-fmlr-session-asian-reclaim-note.md`
- Equal-level reclaim note: `research/2026-07-13-fmlr-equal-level-reclaim-note.md`
- Swing-sweep reclaim note: `research/2026-07-13-fmlr-swing-sweep-reclaim-note.md`
- Previous-period reclaim note: `research/2026-07-13-fmlr-previous-period-reclaim-note.md`
- Daily-open reclaim note: `research/2026-07-13-fmlr-daily-open-reclaim-note.md`
- Higher-open reclaim note: `research/2026-07-13-fmlr-higher-open-reclaim-note.md`
- Open stop-pocket note: `research/2026-07-13-fmlr-open-stop-pocket-note.md`
- Open liquidity target note: `research/2026-07-13-fmlr-open-liquidity-target-note.md`
- Continuation-retest note: `research/2026-07-13-fmlr-continuation-retest-note.md`
- Compression-breakout note: `research/2026-07-13-fmlr-compression-breakout-note.md`
- Session-range breakout note: `research/2026-07-13-fmlr-session-range-breakout-note.md`
- Opening-range reclaim note: `research/2026-07-13-fmlr-opening-range-reclaim-note.md`
- VWAP-deviation reclaim note: `research/2026-07-13-fmlr-vwap-deviation-reclaim-note.md`
- Fast FMLR validation package note: `research/2026-07-13-fmlr-fast-validation-package-note.md`
- Sweep-displacement BOS note: `research/2026-07-13-fmlr-sweep-displacement-bos-note.md`
- Displacement-pullback note: `research/2026-07-13-fmlr-displacement-pullback-note.md`
- Order-block retest note: `research/2026-07-13-fmlr-order-block-retest-note.md`
- CHoCH retest note: `research/2026-07-13-fmlr-choch-retest-note.md`
- FVG structural retest note: `research/2026-07-13-fmlr-fvg-retest-note.md`
- Engulfing-reclaim note: `research/2026-07-13-fmlr-engulfing-reclaim-note.md`
- Tick-pressure reclaim note: `research/2026-07-13-fmlr-tick-pressure-reclaim-note.md`
- Breakout-retest note: `research/2026-07-13-fmlr-breakout-retest-note.md`
- Failed-breakout-trap note: `research/2026-07-13-fmlr-failed-breakout-trap-note.md`
- Imbalance-continuation note: `research/2026-07-13-fmlr-imbalance-continuation-note.md`
- Runner-target stretch note: `research/2026-07-13-fmlr-runner-target-stretch-note.md`
- Structural-runner trail note: `research/2026-07-13-fmlr-structural-runner-trail-note.md`
- Shelf-retest note: `research/2026-07-13-fmlr-shelf-retest-note.md`
- Range-failure reclaim note: `research/2026-07-13-fmlr-range-failure-reclaim-note.md`
- HTF liquidity reclaim note: `research/2026-07-13-fmlr-htf-liquidity-reclaim-note.md`
- Structural-target fallback note: `research/2026-07-13-fmlr-structural-target-fallback-note.md`
- Structural-target priority note: `research/2026-07-13-fmlr-structural-target-priority-note.md`
- Protected-runner target-path note: `research/2026-07-13-fmlr-protected-runner-target-path-note.md`
- Runner-phase consistency note: `research/2026-07-13-fmlr-runner-phase-consistency-note.md`
- Structural-target runner eligibility note: `research/2026-07-13-fmlr-structural-target-runner-eligibility-note.md`
- Structural-target unlimited-runner note: `research/2026-07-13-fmlr-structural-target-unlimited-runner-note.md`
- Unlimited-runner stretch-evidence note: `research/2026-07-13-fmlr-unlimited-runner-stretch-evidence-note.md`
- Structure-trail broker-distance note: `research/2026-07-13-fmlr-structure-trail-broker-distance-note.md`
- Structural-fallback runner note: `research/2026-07-13-fmlr-structural-fallback-runner-note.md`
- FMLR catch-up threshold note: `research/2026-07-13-fmlr-catch-up-threshold-note.md`
- FMLR catch-up risk note: `research/2026-07-13-fmlr-catch-up-risk-note.md`
- FMLR catch-up cadence note: `research/2026-07-13-fmlr-catch-up-cadence-note.md`
- FMLR equal-level stop-pool note: `research/2026-07-13-fmlr-equal-level-stop-pool-note.md`
- Shared structure-stop equal-level cluster note: `research/2026-07-13-structure-stop-equal-level-cluster-note.md`
- FMLR protected-loss catch-up note: `research/2026-07-13-fmlr-protected-loss-catch-up-note.md`
- FMLR sweep-runner target note: `research/2026-07-13-fmlr-sweep-runner-target-note.md`
- FMLR sweep-runner package profile note: `research/2026-07-13-fmlr-sweep-runner-profile-note.md`
- FMLR sweep unlimited runner note: `research/2026-07-13-fmlr-sweep-unlimited-runner-note.md`

Adaptive Reverse quarantine was tightened on 2026-07-13:

- Adaptive Reverse remains internally disabled and is not optimizer-visible.
- If manually re-enabled later, its default guard layer now requires stronger anti-whipsaw behavior: recent-flip cooldown, post-stop lockout, alternating guarded reverse-loss lockout, range-phase block, trend-phase requirement, liquidity-trap guard, liquidity-clearance requirement, follow-through close, and a deferred displacement-break plus controlled-retest confirmation.
- Local check: `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`.
- Research note: `research/2026-07-13-adaptive-reverse-quarantine-note.md`

Block diagnostics, month-filter bypass, and March/May risk-shape probes were tested on 2026-07-12 and rejected:

- Block diagnostics showed the actionable blocker was mostly the month filter, not missing indicator data.
- FSD month-filter bypass increased activity but added losing trades in `2024_10`, `2025_04`, and `2025_06`.
- High-price-action month-filter bypass made no trade-set difference.
- Fresh same-source continuous check showed LowATR OrderFlow at `+$1,195.69` versus Dec-ISLP-Off at `+$1,195.04`.
- March/May risk-shape ladder did not beat current: `mar200_may220` improved 2026 YTD to `+$1,238.40`, but lowered continuous profit to `+$993.28` and added a `2025_03` loss.
- Decision: not promoted. Keep LowATR OrderFlow as the current research-best, but treat the old `+$4,507.51` real-tick continuous number as historical until reproduced.
- Research note: `research/2026-07-12-block-diagnostics-and-risk-shape-note.md`

Liquidity-stop extension variants were tested on 2026-07-12 and rejected:

- Intent: improve the already-active base liquidity-aware structure stop with cluster, previous-day, and pocket extensions.
- Compile result: `0 errors, 0 warnings` through compact tester-source generation.
- Model4 result across 12 weak/flat windows: current `+$508.07`, cluster `+$387.68`, cluster+pocket `+$122.50`, previous-day `-$90.55`.
- Previous-day liquidity produced a losing window in `2026_05`; cluster variants mostly reduced existing winners.
- Decision: not promoted. Keep the current base liquidity-aware structure stop, but reject the extra extensions.
- Research note: `research/2026-07-12-liquidity-stop-extension-probe-note.md`

Flat-month probe-mode reality was tested on 2026-07-12 and rejected:

- Intent: verify whether the old flat-month probe-mode settings could really be tested once exposed as inputs.
- Code change: made dormant flat-month probe-mode controls optimizer-visible, all default-off.
- Compile result: `0 errors, 0 warnings` through compact tester-source generation.
- Model4 result across 12 weak/flat windows: current `+$508.07`, strict low-risk `+$453.17`, quality-ramp `+$453.17`, tiny discovery `+$444.02`.
- Probe-mode did not add useful flat-month trades; it mostly reduced size on existing winners.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research note: `research/2026-07-12-flat-month-probe-mode-reality-note.md`

Flat-month wake-up / stale-entry was tested on 2026-07-12 and rejected:

- Intent: verify whether missed-move wake-up, stale-entry nudge, or elite fallback could add safe flat-month trades once exposed as inputs.
- Code change: made dormant flat-month wake-up/stale/elite controls optimizer-visible, all default-off.
- Compile result: `0 errors, 0 warnings` through compact tester-source generation.
- Model4 result across 12 weak/flat windows: current `+$508.07`, wake strict `+$508.07`, wake balanced `+$508.07`, stale elite `+$508.07`.
- Active windows stayed `3 / 12`; zero-trade windows stayed `9 / 12`.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research note: `research/2026-07-12-flat-month-wakeup-probe-note.md`

Flat-month micro-reversion expansion was tested on 2026-07-12 and rejected:

- Intent: increase flat-month participation without Adaptive Reverse, martingale, grid, averaging down, or pure ATR-only stop logic.
- Change: tested stricter and softer all-month FMR variants at lower risk.
- Compile result: `0 errors, 0 warnings` through compact tester-source generation.
- Model4 result across 12 weak/flat windows: current `+$508.07`, strict expansion `+$484.43`, soft expansion `+$477.12`.
- Strict expansion reduced zero-trade windows from `9` to `8`, but added a `2025_04` loser.
- Soft expansion reduced zero-trade windows from `9` to `7`, but added `2025_04` and `2026_01` losers.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research note: `research/2026-07-12-flat-month-micro-reversion-expansion-probe-note.md`

Flat-month breakout structural and activation probes were tested on 2026-07-12 and rejected:

- Intent: create more useful flat-month trades without Adaptive Reverse, martingale, grid, averaging down, or pure ATR-only stops.
- Code change: made the existing FMB lane optimizer-visible and added optional direct structural stop/target controls.
- Compile result: `0 errors, 0 warnings`.
- First full-source tester run failed with `too many input parameters (1484)`, so the probe was rerun through compact tester-source generation.
- Structural Model4 result across 12 weak/flat windows: current `+$508.07`, conservative FMB `+$508.07`, balanced FMB `+$508.07`.
- Activation Model4 result: current `+$508.07`, tape FMB `+$508.07`, loose FMB `+$490.65`.
- Loose activation did reduce zero-trade windows from `9` to `7`, but it added two losing windows (`2024_10` and `2025_04`) and reduced total net.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research notes:
  - `research/2026-07-12-flat-month-breakout-structural-probe-note.md`
  - `research/2026-07-12-flat-month-breakout-activation-probe-note.md`

Flat-month FSD efficiency relaxation was tested on 2026-07-12 and rejected:

- Intent: increase active months without enabling Adaptive Reverse, martingale, grid, or pure ATR-only stops.
- Change: added optional `InpUseFlatMonthStructuralDisplacementEfficiencyRelaxation` and related relaxed FSD thresholds, all defaulted off.
- Compile result: `0 errors, 0 warnings`.
- Model4 sampled result across 12 weak/flat windows: current `+$508.07`, 48h relaxation `+$508.07`, 24h relaxation `+$508.07`.
- Active windows: all three profiles had `3 / 12`; zero-trade windows stayed `9 / 12`.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research note: `research/2026-07-12-fsd-efficiency-relaxation-probe-note.md`

ISLP LowATR OrderFlow was promoted as the stability-best research profile on 2026-07-12:

- Diagnosis: the `2024_06` ISLP winner was low ATR but had `ISLP order flow`; the `2024_10` ISLP loser was low ATR without order-flow confirmation.
- Change: added optional `InpInSessionLiquidityPullbackLowATRRequireOrderFlow`.
- Candidate settings: `InpInSessionLiquidityPullbackLowATRRequireOrderFlow=true`, `InpInSessionLiquidityPullbackLowATRThreshold=5.00`, `InpInSessionLiquidityPullbackMinATR=0.00`.
- Sampled Model4 result: `+$316.06` vs `+$271.42`, with losing windows improving from `1` to `0`.
- Monthly Model4 result: `+$3,682.17` vs `+$3,637.53`, with losing months improving from `1` to `0`.
- Quarterly Model4 result: `+$3,435.65` vs `+$3,421.49`, with worst quarter improving from `-$44.64` to `-$30.48`.
- Monthly tester-stat result: `31 / 31` stats parsed; LowATR OrderFlow had `38` trades and `30.9408%` worst equity DD.
- Quarterly tester-stat result: `11 / 11` stats parsed; LowATR OrderFlow had `34` trades and `30.9408%` worst equity DD.
- Decision: promoted as stability-best research profile, not live-ready.
- Research note: `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`

ISLP MinATR5 was tested on 2026-07-12:

- Diagnosis: the current `2024_10` Model4 loss was an ISLP sell with entry ATR around `3.74`; the `2025_10` winner was the same ISLP setup type with entry ATR around `13.19`.
- Change: added optional `InpInSessionLiquidityPullbackMinATR`, default `0.0`.
- Candidate: `InpInSessionLiquidityPullbackMinATR=5.0`.
- Small probe result: sampled Model4 total improved from `+$204.86` to `+$249.50`, with losing windows improving from `1` to `0`.
- Monthly gate result: `islp_min_atr5` made `+$3,615.61` vs `+$3,637.53` for Dec-ISLP-Off.
- Monthly tradeoff: it removed the `2024_10` `-$44.64` loser but also blocked the `2024_06` `+$66.56` winner.
- Decision: not promoted as primary; keep only as a conservative risk-smoothing candidate.
- Research note: `research/2026-07-12-islp-min-atr-probe-note.md`
- Monthly note: `research/2026-07-12-islp-min-atr-monthly-validation-note.md`

Prior FMR location-extreme strict mode was tested on 2026-07-12:

- Change: when `InpFlatMonthMicroReversionRequireVWAP=true`, flat-month micro-reversion also requires a nearby liquidity/structure extreme.
- Intent: improve flat-window quality without Adaptive Reverse or pure ATR-only logic.
- Result: tied current Dec-ISLP-Off on the compact Model4 probe, `+$204.86` vs `+$204.86`.
- Decision: not promoted.
- Research note: `research/2026-07-12-fmr-location-extreme-probe-note.md`

Important tester note:

- Full local EA source is too input-heavy for MT5 Strategy Tester right now.
- Validation packages should use compact tester source generation.
- Latest FSD relaxation compact probe kept `344` tester inputs and converted `1106` inactive inputs to globals.

## Evidence Files

Primary status:

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`
- `research/2026-07-12-fsd-efficiency-relaxation-probe-note.md`
- `research/2026-07-12-december-islp-guard-promotion-note.md`
- `outputs/DEC_ISLP_GUARD_DECISION_SUMMARY.csv`

Flat-month FSD efficiency relaxation rejection:

- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_RUN.csv`
- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_MANIFEST.csv`

Flat-month breakout rejection:

- `outputs/FLAT_MONTH_BREAKOUT_STRUCTURAL_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_BREAKOUT_STRUCTURAL_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_BREAKOUT_ACTIVATION_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_BREAKOUT_ACTIVATION_PROBE_SUMMARY.csv`
- `research/2026-07-12-flat-month-breakout-structural-probe-note.md`
- `research/2026-07-12-flat-month-breakout-activation-probe-note.md`

Flat-month micro-reversion expansion rejection:

- `outputs/FLAT_MONTH_MICRO_REVERSION_EXPANSION_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_MICRO_REVERSION_EXPANSION_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_MICRO_REVERSION_EXPANSION_PROBE_RUN.csv`
- `outputs/FLAT_MONTH_MICRO_REVERSION_EXPANSION_PROBE_MANIFEST.csv`
- `research/2026-07-12-flat-month-micro-reversion-expansion-probe-note.md`

Flat-month wake-up and probe-mode rejections:

- `outputs/FLAT_MONTH_WAKEUP_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_WAKEUP_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_PROBE_MODE_REALITY_RESULTS.csv`
- `outputs/FLAT_MONTH_PROBE_MODE_REALITY_SUMMARY.csv`
- `research/2026-07-12-flat-month-wakeup-probe-note.md`
- `research/2026-07-12-flat-month-probe-mode-reality-note.md`

Liquidity-stop extension rejection:

- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_RESULTS.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_SUMMARY.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_RUN.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_MANIFEST.csv`
- `research/2026-07-12-liquidity-stop-extension-probe-note.md`

December ISLP guard validation:

- `outputs/REALTICK_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL1_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL2_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL0_DEC_ISLP_GUARD_LOG_RESULTS.csv`

Real-tick profile showdown:

- `outputs/REALTICK_PROFILE_SHOWDOWN_LOG_RESULTS.csv`
- `outputs/REALTICK_PROFILE_SHOWDOWN_DECISION_SUMMARY.csv`
- `research/2026-07-12-realtick-profile-showdown-note.md`

Earlier Score7 and regime validation:

- `outputs/MODEL1_SCORE7_REGIME_NO_M1SHOCK_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_NO_M1SHOCK_QTR_LOG_RESULTS.csv`
- `outputs/MODEL2_SCORE7_REGIME_NO_M1SHOCK_LOG_RESULTS.csv`
- `outputs/MODEL4_SCORE7_VS_NO_M1SHOCK_PROBE_LOG_RESULTS.csv`

Synced monthly parsed-log evidence:

- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `research/2026-07-12-december-islp-monthly-validation-note.md`

Synced quarterly parsed-log evidence:

- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`
- `research/2026-07-12-december-islp-quarterly-validation-note.md`

Local FMR strict-mode probe evidence:

- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_DIFF.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_DECISION_SUMMARY.csv`
- `research/2026-07-12-fmr-location-extreme-probe-note.md`

Local ISLP MinATR probe evidence:

- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_DIFF.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_DECISION_SUMMARY.csv`
- `research/2026-07-12-islp-min-atr-probe-note.md`

Local ISLP MinATR monthly validation evidence:

- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `research/2026-07-12-islp-min-atr-monthly-validation-note.md`

Local ISLP LowATR OrderFlow promotion evidence:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`
- `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`

Local-only monthly raw files:

- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_RUN.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_RUN.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_RUN.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_LOG_RESULTS.csv`

## What Changed Recently

The current promoted profile keeps the prior Score7/Regime work and adds one narrow guard:

- `InpISLPTradeDecember=false`

It does not enable martingale, grid, averaging down, or recovery logic.

Current strategy direction:

- Adaptive Reverse remains disabled to avoid stop-and-reverse whipsaw.
- Flat Month Structural Displacement remains a tightly gated opportunity lane.
- Flat Month Micro Reversion is limited to July and October at reduced risk.
- Range Elite Micro Reversion remains low-frequency and strict.
- MFE Failure Exit is enabled only in March.
- In-Session Liquidity Pullback remains enabled only for selected months, with December now disabled.
- Low-ATR ISLP entries now require order-flow confirmation in the stability-best profile.
- ISLP MinATR5 remains rejected as the primary because it blocked the June 2024 winner.
- Spread-regime guard is enabled.
- M1 spread-shock guard is disabled because it created Model2 compatibility problems without adding Model1 profit.
- Adaptive Reverse is internally locked off in local source to reduce whipsaw risk and tester input count; if manually re-enabled later, it now also requires a closed displacement break followed by a controlled retest/hold.
- Dormant flat-month probe/stale/missed-move controls were made optimizer-visible as default-off inputs; tests rejected those settings, so active current-best lanes remain unchanged.

## What The Numbers Mean

Do not read the test numbers as guaranteed live profit.

Useful interpretation:

- `+$10,127.76` is the best current Model1 continuous research result: `+1012.78%` total, about `+159.47%/yr` CAGR from a `$1,000` start.
- `+$1,195.69` is the most recent reproduced Model4 real-tick continuous result before the `FF1BCDB0...` safety source update: `+119.57%` total, about `+36.51%/yr` CAGR.
- `+$4,507.51` is a historical Dec-ISLP-Off Model4 continuous result: `+450.75%` total, about `+96.43%/yr` CAGR, but it should be treated as stale until reproduced on the current local source/compact path.
- `+$7,469.00` is the Model4 total across sampled validation windows. It is not annualized because it is not one continuous account curve.
- Monthly Model4 parsed-log validation also supports the guard: `+$3,779.52` vs `+$3,687.00`, and `0` losing months vs `2`.
- Quarterly Model4 parsed-log validation supports the same guard: `+$3,455.89` vs `+$3,404.59`, and `0` losing quarters vs `1`.
- Model2 still argues for caution because it prefers the previous no-m1-shock profile.

Bottom line: the profile is worth more testing, not live deployment yet.

## Next Research Gates

Next useful work:

1. Return exported MT5 reports, not log-only profit rows, so Model4 runs include drawdown %, trades, profit factor, expected payoff, Sharpe ratio, win rate, max consecutive losses, and recovery factor for the strict trade-ready gate; the exact continuous real-tick run now needs at least `20` trades.
2. Investigate why Model2 prefers the previous profile.
3. Use compact tester-source generation for future validation until the full EA input surface is reduced.
4. Continue looking for profit lanes that add trades without creating losing windows.
5. Only raise risk after the profile survives wider real-tick validation.

## Rules For Future Updates

When Codex changes the bot or runs meaningful tests, update this README with:

1. Current best profile, or say the old best still stands.
2. Exact tester model: `Model=0`, `Model=1`, `Model=2`, or `Model=4`.
3. Exact date window.
4. Net profit, worst window, losing-window count, and failures.
5. Evidence CSV or research note.
6. Promotion decision: promoted, rejected, or probe only.

If a run returns `NO_REPORT`, it does not count as proof.

## GitHub Actions

GitHub Actions should stay manual-only. Monthly Actions usage is already high, and heavy MT5 runs belong on the local PC, a spare machine, or a VPS.

## Source Sync Status

Local `Professional_XAUUSD_EA.mq5` is ahead of the GitHub source. The README, research notes, builders, and result CSVs are the main synced dashboard right now. Do not assume GitHub contains every local EA source change until this section says the full EA source has been synced.
