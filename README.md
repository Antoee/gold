# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

This is not a martingale, grid, averaging-down, or recovery-system bot. Risk control stays above profit chasing. Heavy optimization and validation should run locally, hidden in the background, not in GitHub Actions.

## Latest Status

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

**New York activity follow-up: no new best.** All `54 / 54` Model1 reports completed for six standalone New York DGF windows from 2019 through 2026 YTD. Every variant had at least one losing active year. The highest aggregate result, `sny_14_17` at `+$153.66`, still lost in 2019, 2020, 2021, and 2025, so all six …28536 tokens truncated…026-07-13-fmlr-sweep-runner-profile-note.md`
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

