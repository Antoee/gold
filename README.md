# Professional XAUUSD EA

Risk-first MetaTrader 5 research for XAUUSD. No martingale, grid, averaging down, or recovery sizing.

## Current Verdict

| Lane | Status |
|---|---|
| Best historical/trade-ready candidate | **Three-Lane Trade-Ready RC2 ATB150** |
| Latest research result | **A price-normalized stop rewrite repaired the M15 dual-regime strategy's recent geometry, improving 2024-2026 from -$66.41/PF 0.76 to -$7.93/PF 0.98 and continuous net from +$364.60 to +$430.93. The recent era remained negative, so it failed before Model 4. No new best.** ATB150 remains the best. |
| Registered forward candidate | Operational Hardening v0.2-rc2, unchanged |
| Valid forward evidence | **None**. The attached $100,000 demo violates the frozen $10,000 contract and counts as zero days/trades. |
| Real-money approval | **No. Real-account trading remains disabled.** |

Three-Lane Trade-Ready RC2 ATB150 uses the exact hardened RC2 source and raises only the adaptive-trend lane risk from `0.10%` to `0.15%`. Reversion, momentum, total open risk, and every portfolio loss limit remain unchanged. It is the strongest exact historical profile, but it is not a promise of future profit and is not the registered forward bot.

## Best Result

Continuous MT5 Model 4 real ticks, XAUUSD, `$10,000` restart, `2015-01-01` through `2026-07-12`:

| Metric | Result |
|---|---:|
| Net profit | **+$2,105.08** |
| Ending balance | **$12,105.08** |
| Total increase | **+21.05%** |
| CAGR | **+1.67% per year** |
| Profit factor | **1.81** |
| Trades | **404** |
| Win rate | **44.31%** |
| Maximum equity drawdown | **$134.35 / 1.15%** |
| Recovery factor | **15.67** |

The previous RC2 center profile independently supports the same source at `+$1,994.62`, PF `1.82`, 367 trades, and no losing broad era. ATB150 adds `$110.46`, reduces money drawdown by `$4.76`, and improves recovery by `9.28%`. Every promoted number above comes from Model 4 real ticks.

## Latest Research Update

The independent M15 dual-regime normalized-stop experiment completed on `2026-07-19`. The original strategy had passed sealed 2015-2020 discovery and then failed its 2021-2026 holdout while using an absolute `$6` secondary stop-distance ceiling. Because that unit does not scale with gold's price, a new default-off code path replaced only that ceiling with a percentage of entry price. Signals, ATR stop bounds, targets, exits, sessions, `0.10%` risk, broker-valued sizing, minimum-lot refusal, exposure guards, and every loss limit remained unchanged.

The frozen historical repair compared exact `$6`, ATR-only, and `0.25%`/`0.30%`/`0.35%` price caps across four disjoint eras and continuous 2015-2026. All `25/25` Model 1 reports parsed on one exact source and EX5 identity after three identity-only retries. The `0.30%` center raised recent trades from 54 to 71, improved recent PF from `0.76` to `0.98`, reduced the 2024-2026 loss from `-$66.41` to `-$7.93`, raised continuous net from `+$364.60` to `+$430.93`, and reduced drawdown from `1.07%` to `1.01%`. It still lost money in the recent era, missed the `1.05` recent-PF floor and `+25%` continuous-net hurdle, and had no passing percentage neighbor. Model 4 and portfolio integration were not opened. The fixed-dollar ceiling was a real geometry weakness, but it was not the root cause of the signal decay.

[Read the normalized-stop rejection](outputs/INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_DECISION.md) and [the compact five-profile results](outputs/INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_SUMMARY.csv).

The noncompounding risk-budget experiment completed on `2026-07-19`. This was a shared risk-manager code change motivated by exact trade attribution: higher reversion profits had pushed several later momentum trades across broker lot-step boundaries during the maximum-drawdown sequence. When enabled, the new default-off feature sizes every lane from `min(current equity, frozen initial capital)`. It can reduce size after losses but cannot increase the sizing budget after profits. It changes no signal, entry, stop, target, exit, ownership rule, lot cap, open-risk cap, or loss limit.

The frozen four-way design separated champion control, budget only, strong risk only, and strong risk plus budget across three disjoint eras and continuous 2015-2026. All `16/16` Model 1 reports parsed on one exact source and EX5 identity after one identity-only retry. The combined profile improved PF from `1.83` to `1.93`, drawdown from `1.17%` to `1.05%`, recovery from `15.8168` to `17.1048`, and return/drawdown from `18.7692` to `20.7905`. It did not preserve growth: net fell from `+$2,195.53` to `+$2,182.92`, CAGR slipped from `1.74%` to `1.73%`, older and middle eras were below control, and trades fell from 415 to 402. The preregistered net, CAGR, and every-era comparison gates failed, so Model 4 was not opened. The result is retained as conservative risk-control research, not a new best.

[Read the noncompounding risk-budget rejection](outputs/THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_DECISION.md) and [the compact four-way results](outputs/THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_SUMMARY.csv).

The completed-H1 strong-reversion risk experiment and its separately frozen strict-body ladder completed on `2026-07-19`. The code could raise requested risk only for an already-valid reversion entry whose completed directional candle body met a fixed ratio. It changed no entry eligibility, initial stop, VWAP target, exit, trend lane, lot cap, account-wide `0.75%` exposure cap, or loss limit; it was disabled by default and used no current-bar, future, calendar, account-profit, or prior-outcome data.

The broad `28/28` Model 1 discovery rejected its highest-growth row: `+$2,438.12`, `1.91%` CAGR, and PF `1.91` came with `1.54%` drawdown and retained only `80.52%` of control recovery. Its strict `0.25` body row instead improved efficiency, so a new contract froze a narrow risk ladder before rerunning. All `32/32` ladder reports parsed on the same exact EX5. The top `0.70%` row made `+$2,391.89`, `1.88%` CAGR, PF `1.89`, and only `1.21%` drawdown; recovery and return/drawdown improved to `104.71%` and `105.32%` of control, with support from risk and body neighbors. The frozen Model 1 CAGR requirement was `1.89%`, however, so the row missed by `0.01` point. That rejection remains unchanged and no `0.71-0.74%` threshold chase was allowed.

A separate contract then froze the already-selected `0.25` / `0.70%` profile for an exact Model 4 control comparison without changing its threshold or risk. All `8/8` source- and binary-identity-valid real-tick reports completed across 2015-2018, 2019-2022, 2023-2026, and continuous 2015-2026. The candidate matched or beat control net in every era and raised continuous net from `+$2,105.08` to `+$2,284.81`, CAGR from `1.67%` to `1.80%`, and PF from `1.81` to `1.87`. Drawdown stayed within the frozen ceiling at `1.23%`, and return/drawdown improved from `18.3043` to `18.5772`. Recovery factor slipped from `15.6686` to `15.6666`, however, failing the preregistered no-worse-than-control requirement by `0.0020`. That difference was not rounded away after observation, so annual, cost, and Monte Carlo expansion remains closed and ATB150 stays unchanged.

[Read the broad strong-signal rejection](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_RISK_DISCOVERY_DECISION.md), [the strict-ladder near-miss](outputs/THREE_LANE_REVERSION_STRICT_BODY_RISK_LADDER_DECISION.md), [the exact Model 4 rejection](outputs/THREE_LANE_REVERSION_STRICT_BODY_MODEL4_VALIDATION_DECISION.md), and [the compact Model 4 results](outputs/THREE_LANE_REVERSION_STRICT_BODY_MODEL4_VALIDATION_SUMMARY.csv).

The reversion break-even experiment completed on `2026-07-19`. This was a tightening-only exit-management code change: after a completed H1 bar reached a frozen R trigger, the EA could move an exact-ticket owned reversion stop to break-even or a small profit lock. It added no entry or close path, never widened a stop, was disabled by default, and left initial risk, VWAP targets, trend lanes, portfolio limits, and real-account protections unchanged.

All `28/28` final Model 1 reports parsed on one exact EX5 identity across three disjoint eras and continuous 2015-2026. Every era stayed profitable, but no profile beat the control's `+$2,195.53` and `1.74%` CAGR. The strongest efficiency row, trigger `1.00R` and lock `0.10R`, made `+$2,122.79`, `1.68%` CAGR, PF `1.82`, and `1.13%` drawdown. Its small recovery and return/drawdown gains cost `$72.74`, missed the required `+0.15` CAGR improvement, and remained below the PF `1.85` floor. It was rejected before Model 4.

[Read the break-even rejection](outputs/THREE_LANE_REVERSION_BREAK_EVEN_DISCOVERY_DECISION.md) and [the compact results](outputs/THREE_LANE_REVERSION_BREAK_EVEN_DISCOVERY_SUMMARY.csv).

The reversion liquidity-sweep experiment completed on `2026-07-19`. This was an entry-engine code change, not a risk increase: an optional gate required the closed H1 signal candle to sweep an earlier local extreme and reclaim it before the existing Bollinger/VWAP reversion entry. It used no current-bar or future data, was disabled by default, added no trade path, and left all risk, exit, portfolio, and real-account protections unchanged.

All `32/32` final Model 1 reports parsed on one exact EX5 identity across three disjoint eras and continuous 2015-2026. Every candidate era stayed profitable, but the best candidate fell from control at `+$2,195.53`, `1.74%` CAGR, PF `1.83`, and `1.17%` drawdown to `+$1,084.94`, `0.90%` CAGR, PF `1.45`, and `2.31%` drawdown. Attribution showed why: the control's 38 reversion trades made `+$1,383.89`, while the least restrictive sweep gate retained 22 and only `+$375.87`. The gate removed valid band-exhaustion winners, so it was rejected before Model 4 and ATB150 remains unchanged.

[Read the liquidity-sweep rejection](outputs/THREE_LANE_REVERSION_LIQUIDITY_SWEEP_DISCOVERY_DECISION.md) and [the compact results](outputs/THREE_LANE_REVERSION_LIQUIDITY_SWEEP_DISCOVERY_SUMMARY.csv).

Three payoff-management experiments completed on `2026-07-19`. They were motivated by exact ATB150 trade-ledger evidence rather than an unrestricted parameter search. The fixed-target ladder changed only momentum and adaptive-trend targets; the selective-target code widened the adaptive target only after completed-H4 ADX and candle-quality checks; the protected-runner code paired a wider target with a second tightening-only stop milestone. All retained the same entries or could only alter payoff after an existing entry, preserved initial stops and requested risk, stayed under the `0.75%` open-risk cap, and left real trading disabled.

The fixed-target ladder completed `27/27` exact Model 1 reports. Its best row, adaptive target `3R`, reached `+$1,239.96`, `1.97%` CAGR, PF `1.81`, and `1.08%` drawdown versus control at `+$1,191.69`, `1.89%` CAGR, PF `1.77`, and `1.02%` drawdown. The `+0.08`-point CAGR gain missed the frozen `+0.25` requirement and reduced both recovery and return/drawdown.

The completed-bar selective extension completed `30/30` reports and genuinely changed 19 to 31 entries per profile. Its best row reached only `+$1,223.19` and `1.94%` CAGR, a `+0.05`-point gain, while risk efficiency again fell. The protected runner then completed `33/33` valid reports on one portable binary. Its best adaptive row reached `+$1,245.49`, `1.98%` CAGR, PF `1.82`, and `1.09%` drawdown, but the `+0.09`-point CAGR gain missed its `+0.15` gate and recovery and return/drawdown were both below control. Momentum runners were materially worse.

All three families stayed profitable in both disjoint discovery eras, but none provided enough robust growth to justify opening recent data or Model 4 real ticks. Across them, `90/90` valid exact discovery reports completed with zero report errors; one earlier 33-row runner attempt was refused before testing because its portable binary identity had not yet been prepared and is not counted as evidence. ATB150 remains the most stable historical profile.

[Read the fixed-target rejection](outputs/THREE_LANE_PAYOFF_LADDER_DISCOVERY_DECISION.md), [the selective-target rejection](outputs/THREE_LANE_SELECTIVE_PAYOFF_DISCOVERY_DECISION.md), and [the protected-runner rejection](outputs/THREE_LANE_PROTECTED_RUNNER_DISCOVERY_DECISION.md).

Two residual-risk allocation code experiments completed on `2026-07-19`. Both attempted to raise APR by using otherwise idle protected risk under the unchanged `0.75%` account-wide cap. Neither used prior outcomes, martingale, grid, averaging down, or recovery sizing. Both retained initial stops, broker-valued sizing, post-fill reconciliation, all portfolio loss limits, the `$10,000` contract, and the real-account lock.

V1 reached `+$2,935.46`, `+29.35%` total, and `+2.26%` CAGR on paired continuous Model 4 real ticks versus ATB150/control at `+$2,105.08`, `+21.05%`, and `+1.67%` CAGR. It was rejected because PF fell from `1.81` to `1.68`, maximum drawdown rose from `1.15%` to `1.94%`, recovery fell from `15.67` to `12.85`, and return/drawdown fell from `18.30` to `15.13`. It also admitted 71 additional minimum-lot trades.

V2 added a base-lot eligibility gate to all three lanes, so only signals already tradable at original ATB150 risk could receive expansion. Its Model 1 center improved from `+$2,195.53`, `+1.74%` CAGR, PF `1.83`, and `1.17%` drawdown to `+$2,832.59`, `+2.19%` CAGR, PF `1.83`, and `1.50%` drawdown. It was still rejected before Model 4 because the fixed neighborhood rule required at least three adjacent momentum ceilings to remain no worse than control on both recovery and return/drawdown. Only the `0.175%` center passed; the closest `0.170%` neighbor missed return/drawdown by `0.005`. The gate was not loosened after seeing the result.

The rejected V2 center and its closest momentum-ceiling neighbors were then characterized on continuous Model 4 real ticks under a separately frozen gate. The center improved control from `+$2,105.08` and `1.67%` CAGR to `+$2,531.00` and `1.98%` CAGR with the same 404 trades, but drawdown rose from `1.15%` to `1.71%`. Recovery retained only `84.51%` of control and return/drawdown retained `80.86%`, below the required `95%`. All `4/4` exact real-tick reports completed, and the prior rejection was not reversed.

Trade-ledger attribution showed that reversion retained PF near `3.9`, while the expanded trend lanes carried the weaker payoff. A final Model 1 neighborhood therefore allocated residual risk only to already-eligible reversion entries. All 20 final reports parsed, every disjoint era remained profitable, and all profiles kept the exact control's 415 trades. The highest row reached `+$2,458.12`, `+24.58%`, `1.93%` CAGR, and PF `1.92`, but missed the required `1.99%` CAGR, exceeded the `1.50%` drawdown ceiling at `1.54%`, and weakened both efficiency measures. The conservative `0.50%` row stayed at `1.22%` drawdown but added only `0.05` CAGR points and was also slightly less efficient. No row qualified for Model 4.

Across both residual-risk versions and these follow-ups, higher historical profit is recorded as rejected research rather than a new best. ATB150 remains the most stable historical profile.

[Read the V1 real-tick rejection](outputs/THREE_LANE_RESIDUAL_RISK_V1_DECISION.md), [the V2 neighborhood rejection](outputs/THREE_LANE_RESIDUAL_RISK_V2_DECISION.md), [the V2 real-tick characterization](outputs/THREE_LANE_RESIDUAL_RISK_V2_MODEL4_CHARACTERIZATION_DECISION.md), [the reversion-only rejection](outputs/THREE_LANE_RESIDUAL_RISK_V2_REVERSION_FOCUS_DECISION.md), and [the static safety summary](outputs/THREE_LANE_RESIDUAL_RISK_STATIC_SAFETY.md).

### Rejected Higher-APR Comparison

Continuous 2015-2026 figures use a sequential `$10,000` account path. V1 figures are Model 4 real ticks; V2 was stopped at Model 1 and is not directly promotable.

| Profile | Test model | Net | Total increase | CAGR | PF | Max DD | Recovery | Return/DD | Status |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| **ATB150** | Model 4 real ticks | **+$2,105.08** | **+21.05%** | **+1.67%/yr** | **1.81** | **1.15%** | **15.67** | **18.30** | **Current best** |
| Strong-reversion body 0.25 / risk 0.70% | Model 4 real ticks | +$2,284.81 | +22.85% | +1.80%/yr | 1.87 | 1.23% | 15.6666 | 18.58 | Rejected by frozen recovery gate |
| Residual-risk V1 | Model 4 real ticks | +$2,935.46 | +29.35% | +2.26%/yr | 1.68 | 1.94% | 12.85 | 15.13 | Rejected |
| Base-eligible V2 center | Model 1 only | +$2,832.59 | +28.33% | +2.19%/yr | 1.83 | 1.50% | 16.33 | 18.89 | Rejected before Model 4 |
| Base-eligible V2 center | Model 4 real ticks | +$2,531.00 | +25.31% | +1.98%/yr | 1.77 | 1.71% | 13.24 | 14.80 | Characterization failed |
| V2 reversion-only 0.65% | Model 1 only | +$2,458.12 | +24.58% | +1.93%/yr | 1.92 | 1.54% | 12.84 | 15.96 | Rejected before Model 4 |

The protected momentum winner add-on experiment completed on `2026-07-19`. This was a strategy-code change to ATB150, not a simple risk increase: it allowed one separately owned continuation entry only after the primary momentum trade reached a configurable profit threshold, its stop was locked in profit, and broker-valued locked profit covered the add-on's full risk. The `0.75%` portfolio open-risk cap, minimum-lot refusal, post-fill reconciliation, `$10,000` contract, and real-account lock remained unchanged.

The feature passed sealed 2015-2020 discovery on one exact binary. The frozen `pwa_trigger100` survivor made `+$1,248.56`, CAGR `1.98%`, PF `1.80`, 272 trades, and `1.02%` maximum drawdown versus the disabled-feature control at `+$1,191.69`, CAGR `1.89%`, PF `1.77`, 265 trades, and the same drawdown. It recorded nine protected add-on entries and had adjacent support.

The feature then failed its frozen feature-level 2021-2026 holdout. All candidate windows stayed profitable, but the selected profile made only `+$929.40`, CAGR `1.62%`, PF `1.99`, and `1.23%` drawdown versus control at `+$944.62`, CAGR `1.64%`, PF `2.01`, and the same drawdown. No holdout report contained a completed add-on. Results still changed because v1.51 can tighten the primary stop during an attempted add-on before exact coverage validation later refuses the entry; that safety-biased side effect is an additional rejection reason. All 30 discovery and eight holdout reports were tied to one source and EX5 identity with zero exact-run errors. No Model 4 run was opened, and ATB150 remains unchanged.

[Read the discovery decision](outputs/THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_DECISION.md), [the holdout rejection](outputs/THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_DECISION.md), and [the 20-check safety audit](outputs/THREE_LANE_PROTECTED_WINNER_ADDON_STATIC_SAFETY.md).

The standalone M15 TLT rates-impulse experiment completed on `2026-07-19`. Broker-history probes first showed `98.062%` to `98.450%` yearly D1 alignment between XAUUSD and TLT with `100%` lookback readiness over 2015-2020. The EA then used only the last provably completed TLT D1 bar as a long-duration/rates proxy and required a completed same-direction XAUUSD M15 breakout. This was a new cross-market strategy implementation, not an ATB150 settings pass.

The strategy failed decisively before recent data was opened. All 45/45 Model 1 reports parsed from one exact source and EX5 identity, with 195 to 874 trades per tested window and zero runner errors. Every profile lost in 2015-2018. The least-bad continuous row, `tltri_tp200`, lost `-$151.60` on 681 trades at PF `0.95` with `3.75%` maximum drawdown. No 2021-2026 holdout or Model 4 run was opened, there is no new best, and ATB150 remains unchanged.

[Read the TLT rates-impulse rejection](outputs/INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_DECISION.md), [the parsed summary](outputs/INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_SUMMARY.csv), and [the TLT history-feasibility evidence](outputs/XAUUSD_TLT_D1_HISTORY_FEASIBILITY.md).

The standalone fixed-session M15 impulse-pullback experiment completed on `2026-07-19`. It measured a morning impulse through ATR magnitude, auction-path efficiency, directional-bar share, and close location, then required a bounded pullback plus a completed M15 reclaim. This was a new strategy implementation, not another settings-only pass over ATB150.

It failed before recent data was opened. All 45/45 Model 1 reports parsed and were bound to one exact source and EX5 identity, but only `sip_end8` was profitable over continuous 2015-2020: `+$33.91`, PF `1.42`, and just 18 trades. That variant separately lost `-$15.08` in 2019-2020, while 12 continuous variants lost money and two were flat. The activity gate required 80 trades. No 2021-2026 holdout or Model 4 run was opened, there is no new best, and ATB150 remains unchanged.

[Read the session impulse-pullback rejection](outputs/INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_DECISION.md), [the parsed summary](outputs/INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_SUMMARY.csv), and [the exact run attestation](outputs/INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_RUN_ATTESTATION.csv).

The standalone M15 USD-consensus lead-lag experiment tested a genuinely different cross-market premise on `2026-07-19`: completed H1 EURUSD and USDJPY moves estimated USD pressure, a gold-lag gate rejected already-extended XAUUSD moves, and a completed M15 breakout supplied the entry. Broker-history probes first confirmed at least `99.9023%` yearly alignment and `100%` lookback readiness for both proxy symbols over 2015-2020.

The strategy itself failed decisively. All 15 profiles lost money in 2015-2018, continuous PF ranged from `0.74` to `0.86`, and the least-bad continuous row, `usdcll_breakout6`, lost `-$128.09` on 173 trades at PF `0.84`. The final evidence set contains 45/45 parsed reports from one exact binary, with zero runner errors. No post-2020 holdout or Model 4 run was opened, and ATB150 remains unchanged as the research best.

[Read the USD-consensus rejection](outputs/INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_DECISION.md), [the parsed summary](outputs/INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_MODEL1_SUMMARY.csv), and [the proxy-history feasibility evidence](outputs/XAUUSD_USD_PROXY_HISTORY_FEASIBILITY.md).

The M15 overnight-drift structure-v2 repair replaced the unaffordable full-Asian-range stop with recent M15 structure. That worked mechanically: the center produced 171 trades with near-zero geometry rejects, zero minimum-lot rejects, and zero order failures. It did not preserve the edge. No profile reached the frozen PF `1.20` gate; the best row, `ods2_entry8`, made `+$136.89` on 174 trades at PF `1.19`, while the center made only `+$34.47` at PF `1.04`. All 13 profiles were rejected before post-2020 data and Model 4.

[Read the structure-v2 rejection](outputs/INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_DISCOVERY_DECISION.md) and [compile evidence](outputs/INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_COMPILE_EVIDENCE.md).

The standalone M15 overnight-drift continuation was the first recent strategy-code experiment to pass discovery. Nine of 15 neighbor-supported profiles were profitable across both 2015-2018 and 2019-2020. The center plus two orthogonal one-factor survivors were frozen before post-2020 data was opened.

The holdout rejected all three. `odc_center` lost `-$25.53` in 2023-2024, `odc_entry8` lost `-$17.99` in 2021-2022 and `-$1.38` in 2025-2026 YTD, and `odc_signal25` lost `-$5.77` in 2023-2024. Each recent window produced only three trades because the frozen `$8` stop-distance cap rejected most high-price-era setups. No parameter was loosened after seeing the holdout, and no Model 4 run or promotion was opened.

[Read the discovery pass](outputs/INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_DISCOVERY_DECISION.md), [the holdout rejection](outputs/INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_HOLDOUT_DECISION.md), and [the compile evidence](outputs/INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_COMPILE_EVIDENCE.md).

The standalone M15 inside-day compression breakout finished on `2026-07-19` and was rejected before recent data. All 42 source-identity-valid Model 1 reports parsed, but every profile lost in 2019-2020. Its best continuous row made only `+$12.79` on 25 trades at PF `1.11`, so no 2021-2026 holdout or Model 4 run was opened.

[Read the inside-day rejection](outputs/INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_DECISION.md).

The preceding M15 ADR-exhaustion/VWAP-reversion experiment was also rejected before holdout: ten profiles made zero trades in 2015-2018 and its best continuous row made only `+$20.08` on six trades. [Read the ADR-exhaustion rejection](outputs/INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_DECISION.md).

The earlier source-identical lane decomposition remains the latest promotion. Portfolio-wide scaling was rejected, but ATB-only `1.50x` improved risk-adjusted results and became the historical best.

| Profile | Model 4 net | Increase | CAGR | PF | Max DD | Recovery | Result |
|---|---:|---:|---:|---:|---:|---:|---|
| Previous RC2 | +$1,994.62 | +19.95% | +1.59%/yr | 1.82 | 1.19% | 14.34 | Supported baseline |
| ATB-only `1.25x` | +$2,018.88 | +20.19% | +1.61%/yr | 1.81 | 1.19% | 14.51 | Neighbor support |
| ATB-only `1.50x` | **+$2,105.08** | **+21.05%** | **+1.67%/yr** | **1.81** | **1.15%** | **15.67** | **Promoted** |

ATB150 passed 12/12 positive annual restarts, 404/404 hard-risk rows, 4/4 cost scenarios, and 8/8 Monte Carlo scenarios. Its weakest severe block P05 improved to `+$238.64`, worst P95 drawdown improved to `4.225%`, and worst red trials improved to `1.35%`. The prior portfolio-wide growth ladder remains rejected because it weakened adverse-path robustness.

[Read the ATB150 decision](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_DECISION.md) and [the rejected portfolio-growth decision](outputs/THREE_LANE_TRADE_READY_RC2_GROWTH_LADDER_DECISION.md).

## Increase By Year

Each row is a separate `$10,000` Model 4 restart. Percentages are window returns, not a compounded account history.

| Window | Net | Increase | PF | Trades | Max DD |
|---|---:|---:|---:|---:|---:|
| 2015 | +$170.78 | +1.71% | 2.06 | 26 | 0.87% |
| 2016 | +$256.58 | +2.57% | 2.19 | 42 | 0.52% |
| 2017 | +$111.65 | +1.12% | 1.29 | 55 | 1.08% |
| 2018 | +$281.65 | +2.82% | 1.96 | 63 | 0.51% |
| 2019 | +$13.01 | +0.13% | 1.07 | 36 | 1.08% |
| 2020 | +$194.64 | +1.95% | 1.99 | 29 | 0.65% |
| 2021 | +$313.13 | +3.13% | 2.36 | 30 | 1.16% |
| 2022 | +$16.22 | +0.16% | 1.07 | 36 | 0.96% |
| 2023 | +$181.54 | +1.82% | 1.75 | 41 | 1.24% |
| 2024 | +$233.81 | +2.34% | 2.44 | 29 | 1.08% |
| 2025 | +$17.78 | +0.18% | 2.91 | 3 | 0.12% |
| 2026 YTD | +$209.18 | +2.09% | no losing trades | 2 | 1.19% |

All 12 windows were profitable. Recent activity remains sparse and unchanged at three trades in 2025 and two in 2026 YTD, so forward evidence is still essential.

## Strategy

Three independent, capped lanes share one account-wide safety manager:

| Lane | Risk cap | Model 4 continuous contribution |
|---|---:|---:|
| H1 Band/VWAP reversion with DI and completed-D1 momentum gates | 0.45% | +$1,366.48, 38 trades |
| Original H1/D1 multiscale momentum | 0.15% | +$661.79, 314 trades |
| H4 Donchian breakout with D1 EMA trend and ADX/price-action quality | 0.15% | +$76.81, 52 trades |

The tested profile caps total open risk at `0.75%`, permits at most three account positions, requires initial stops, sizes through broker-valued `OrderCalcProfit`, locks symbol/currency/starting capital, rejects real accounts, and enforces daily/weekly/monthly/equity loss limits.

## Robustness

- Critical Model 4: center and DI-11 were profitable in both prior failure years, 2019 and 2022.
- Broad Model 4: older 2015-2018 `+$856.18`, middle 2019-2022 `+$572.09`, recent 2023-2026 `+$602.11`.
- Annual Model 4: 12/12 profitable annual/YTD restarts.
- Hard-risk audit: 404/404 entries passed; maximum conservative portfolio initial risk was `0.4448%`.
- Severe deterministic cost: `0.10R` added per trade retained `+$1,506.55`, PF `1.515`, and all eras positive.
- Monte Carlo: 8/8 seeded 10,000-trial block/year scenarios passed. The weakest severe block P05 was `+$238.64`; worst P95 drawdown was `4.225%`; worst red trials were `1.35%`.

## Exact Candidate

- [ATB150 release package](release/three-lane-trade-ready-rc2-atb150/README.md)
- [ATB150 decision](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_DECISION.md)
- [ATB150 broad metrics](outputs/THREE_LANE_TRADE_READY_RC2_GROWTH_DECOMP_MODEL4_METRICS.md)
- [ATB150 annual metrics](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_ANNUAL_MODEL4_METRICS.md)
- [ATB150 safety suite](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_STATIC_SAFETY.md)
- [ATB150 risk audit](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_MODEL4_RISK_AUDIT.md)
- [ATB150 cost and Monte Carlo stress](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_MODEL4_STRESS_DECISION.md)

Source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`

Profile SHA-256: `705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E`

## Forward Boundary

The current demo attachment is invalid before its first trade because its `$100,000` balance does not match the frozen `$10,000 +/- $1` contract. Its elapsed time and trades must never be counted. The registered Operational Hardening candidate, profile, source, binary identity, evidence logs, and real-account lock remain unchanged.

Three-Lane RC2 ATB150 passed its historical promotion review, but it still needs broker-specification variation and a correctly capitalized untouched demo sample before any forward substitution can be considered. Real-money funding is not recommended.

## Repository Map

| Path | Purpose |
|---|---|
| `release/` | Small, exact candidate packages |
| `outputs/` | Contracts, parsed evidence, decisions, and historical research |
| `work/` | Offline builders, analyzers, safety tests, and EA research source |
| `docs/archive/` | Preserved long-form research timeline |
| `.github/workflows/static-safety.yml` | Manual-only static checks; no scheduled or push-triggered Actions |

The old detailed landing-page timeline is preserved at [docs/archive/RESEARCH_TIMELINE_THROUGH_2026-07-18.md](docs/archive/RESEARCH_TIMELINE_THROUGH_2026-07-18.md).
