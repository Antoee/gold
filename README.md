# Professional XAUUSD EA

Risk-first MetaTrader 5 research for XAUUSD. No martingale, grid, averaging down, or recovery sizing.

## Current Verdict

| Lane | Status |
|---|---|
| Highest verified historical result | **Momentum Same-Side Exit Cooldown 60, provisional research leader.** Model 4 real ticks: `+$2,492.25`, `+24.92%`, `1.95%/yr` CAGR, PF `1.93`, `1.18%` drawdown. |
| Released stable baseline | **Three-Lane Trade-Ready RC2 ATB150**, `+$2,105.08`, `+21.05%`, `1.67%/yr` CAGR, PF `1.81`, `1.15%` drawdown. |
| Latest research result | **M15 squeeze 2.25R target rejected in one-shot post-2020 feature holdout.** It improved continuous Model 1 net from `+$1,046.44` to `+$1,131.75` (`+8.15%`), but trailed control in 2024-2026, reduced PF from `2.08` to `1.76`, and raised drawdown from `1.21%` to `1.51%`. Neither fixed sensitivity row passed, so Model 4 remained closed. **No new best.** |
| Registered forward candidate | Operational Hardening v0.2-rc2, unchanged |
| Valid forward evidence | **None**. The attached $100,000 demo violates the frozen $10,000 contract and counts as zero days/trades. |
| Real-money approval | **No. Real-account trading remains disabled.** |

The new candidate keeps the former selective reversion lot cap and adds one outcome-independent rule: after a momentum position exits, it blocks only a new momentum entry on the same symbol, magic number, and position side for 60 elapsed minutes. It never reads whether the prior trade won or lost. Entries, stops, targets, requested risk, lot caps, maximum `0.75%` portfolio open risk, loss limits, and real-account protections remain unchanged.

## Highest Historical Result

Continuous MT5 Model 4 real ticks, XAUUSD, `$10,000` restart, `2015-01-01` through `2026-07-12`:

| Metric | Result |
|---|---:|
| Net profit | **+$2,492.25** |
| Ending balance | **$12,492.25** |
| Total increase | **+24.92%** |
| CAGR | **+1.95% per year** |
| Profit factor | **1.93** |
| Trades | **400** |
| Win rate | **44.75%** |
| Maximum equity drawdown | **1.18%** |
| Recovery factor | **17.54** |
| Return / drawdown | **21.12** |

Against ATB150, the candidate adds `$387.17` (`+18.39%` more net profit), `+3.87` total-return points, and `+0.28` CAGR points per year. PF improves from `1.81` to `1.93`, recovery from `15.67` to `17.54`, and return/drawdown from `18.30` to `21.12`; drawdown rises only `0.03` point. Against the previous research leader, it adds `$63.75`, `+0.64` return point, and `+0.05` CAGR point with the same rounded drawdown. These are historical measurements, not a forecast.

## Current Leader Research

The same-side momentum exit-cooldown experiment completed on `2026-07-20` and became the new provisional historical leader. Exact ledger analysis found four momentum re-entries within 60 minutes of a same-side exit in the 2015-2020 discovery span; all four lost. The default-off implementation uses only elapsed time plus symbol, magic number, and position side. It never reads profit, loss, drawdown, loss streaks, or account outcome state.

The source passed static ownership, outcome-independence, default-off, and unchanged-trade-path checks. MetaEditor compiled it with zero errors and warnings to one EX5 identity. The frozen 60-minute center passed 15-report pre-2021 Model 1 discovery with support from both the 90- and 120-minute neighbors. It then passed paired 2021-2026 Model 1 confirmation.

Exact Model 4 real ticks improved the prior leader from `+$2,428.50` to `+$2,492.25`, CAGR from `1.90%` to `1.95%`, PF from `1.89` to `1.93`, recovery from `17.0889` to `17.5375`, and return/drawdown from `20.5763` to `21.1186`. Drawdown remained `1.18%`; trades changed from 404 to 400. The center was no worse in 2015-2018, 2019-2022, or 2023-2026.

All 12 annual Model 4 restarts were profitable and no worse than control; 2016, 2018, and 2024 improved. The exact 400-trade ledger had zero hard-risk violations and a maximum conservative portfolio initial risk of `0.5869%` against the `0.75%` cap. Severe added cost of `0.10R` per trade retained `+$1,864.19`, PF `1.616`, and `1.259%` closed-trade drawdown. All eight clustered Monte Carlo scenarios passed 10,000 trials each.

This is a historical research promotion, not live approval. A second broker/specification and a valid frozen `$10,000` forward demo are still missing; the attached `$100,000` demo counts as zero evidence, and real-account trading remains disabled.

[Read the Model 4 decision](outputs/THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_DECISION.md), [annual decision](outputs/THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_DECISION.md), [stress decision](outputs/THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_STRESS_DECISION.md), [risk audit](outputs/THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_RISK_AUDIT.md), and [release package](release/three-lane-momentum-same-side-exit-cooldown-provisional/README.md).

### Latest M15 Squeeze 2.25R Feature Holdout

The M15 squeeze `2.25R` target completed a one-shot feature-specific post-2020 holdout on `2026-07-20` and was rejected. The target was nominated only from the prior 2015-2020 training matrix, where it had improved exact-control net from `+$1,379.93` to `+$1,753.53` while retaining PF `1.87` versus `1.88`. Before opening recent outcomes, the holdout fixed the `2.25R` center, `2.00R` and `2.50R` sensitivity rows, two disabled controls, and the existing `1.50R` enabled reference.

The unchanged source compiled with zero errors and warnings to one current EX5 identity across four workers. All `18/18` Model 1 reports parsed after one preserved source-identity refusal and one unchanged single-worker recovery. The exact three-position and disabled four-position controls reproduced identically in 2021-2023, 2024-2026, and continuous 2021-2026.

The center improved continuous net from `+$1,046.44` to `+$1,131.75`, an `8.15%` gain, and beat the enabled `1.50R` reference by `4.12%`. It failed the frozen transfer gate: 2024-2026 net fell from `+$434.36` to `+$418.67`, continuous CAGR improved only `0.14` point versus `0.15` required, PF fell from `2.08` to `1.76`, and drawdown rose from `1.21%` to `1.51%` versus the paired `1.41%` limit. The `2.50R` sensitivity row improved both eras and continuous net by `6.26%`, but also failed PF, recovery, return/drawdown, and drawdown requirements. Sensitivity support was `0/2`.

The target was not moved after the holdout. No Model 4 run was opened, and the verified real-tick leader remains `+$2,492.25`, `+24.92%`, `1.95%/yr` CAGR, PF `1.93`, and `1.18%` drawdown. The frozen forward candidate remains unchanged; the attached `$100,000` demo counts as zero evidence and real-account trading remains disabled.

[Read the holdout rejection](outputs/FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_DECISION.md), [frozen contract](outputs/FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_CONTRACT.md), [exact Model 1 results](outputs/FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_MODEL1_RESULTS.csv), and [canonical run evidence](outputs/FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_RUN_ATTESTATION.csv).

### Latest Reversion Retracement-Entry Research

The default-off reversion retracement-entry experiment completed on `2026-07-20` and was rejected in frozen 2015-2020 Model 1 discovery. It retained the exact completed-H1 Band/VWAP signal, structural stop, signal-time VWAP target, requested risk, selective lot cap, other lanes, 60-minute momentum cooldown, and all portfolio protections. An accepted setup could arm an in-memory trigger toward its stop for one or two H1 bars; it created no broker pending order and reran spread, loss-limit, position, spacing, geometry, broker-valued sizing, and account-wide open-risk checks at fill.

Static checks proved that the fork added no direct buy/sell, close, modify, async, outcome-dependent, or calendar-dependent path. MetaEditor compiled the exact source with zero errors and warnings to one EX5 identity across four workers. All `15/15` reports parsed after two preserved startup identity refusals and one unchanged single-worker recovery. The disabled row exactly reproduced the current leader's pre-2021 control at `+$1,379.93`, `2.18%/yr` CAGR, PF `1.88`, 261 trades, `1.05%` drawdown, and recovery `11.6775`.

The mechanism was active but weaker. The `0.10 ATR` row was the least-damaging enabled profile at `+$1,250.30`, `1.98%/yr` CAGR, PF `1.85`, and 258 trades. The frozen `0.15 ATR` center made `+$1,067.56`, `1.71%/yr` CAGR, PF `1.75`, 252 trades, `1.04%` drawdown, and recovery `9.4759`. It filled 13 retracement entries worth `+$284.35`, versus 19 original reversion entries worth `+$533.48` in control. The center improved 2019-2020 from `+$370.60` to `+$384.19`, but cut 2015-2018 from `+$1,036.19` to `+$682.44`; the `0.20 ATR` neighbor and two-bar lifetime could not repair that loss of older winners.

The offset was not moved closer to zero after observation. Both adjacent offset gates failed, so no post-2020 holdout or Model 4 run was opened. The verified real-tick leader remains `+$2,492.25`, `+24.92%`, `1.95%/yr` CAGR, PF `1.93`, and `1.18%` drawdown; the frozen forward candidate and invalid `$100,000` account boundary remain unchanged.

[Read the retracement-entry rejection](outputs/THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_DECISION.md), [frozen contract](outputs/THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_CONTRACT.md), [exact Model 1 results](outputs/THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_MODEL1_RESULTS.csv), [entry-path evidence](outputs/THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_ENTRY_EVIDENCE.csv), and [research source](work/Professional_XAUUSD_Three_Lane_Reversion_Retracement_Entry_Research.mq5).

### Latest M15 Squeeze Feature-Telemetry Research

The behavior-neutral squeeze telemetry experiment completed on `2026-07-20` and was rejected before filter implementation. It added zero strategy inputs and zero buy, sell, partial-close, or stop-modification paths. After every existing entry gate passed, it recorded only completed-bar breakout depth, candle geometry, expansion, channel width, tick volume, ATR, ADX, direction-adjusted H1 EMA state, squeeze compression, and actual stop distance.

Static outcome-independence and unchanged-trade-path checks passed. MetaEditor compiled the exact source with zero errors and warnings to one EX5 identity across four workers. The one identity-bound Model 1 telemetry report exactly reproduced the partial-runner center at `+$1,695.16`, `+16.95%` total, `2.64%/yr` CAGR, PF `1.84`, 391 report trades, `1.10%` drawdown, and recovery `14.4626`.

The exact ledger aggregated 88 squeeze positions from 129 exit deals and 41 protected partial events. Squeeze net was `+$328.66`. The analyzer was hashed before the run and allowed feature nomination from the 55 trades in 2015-2018 only; the 33 trades in 2019-2020 were reserved for one-shot validation. Each candidate required both training halves, at least 75% trade retention, improved PF, and support from its 15%, 20%, and 25% threshold neighborhood.

Zero of 30 feature-direction families passed the complete training gate, so validation outcomes were never opened for candidate selection and no strategy filter was implemented. The closest family required a minimum breakout range/ATR: its 15% and 20% rungs improved both training halves, but the 25% neighbor retained only `41/55 = 74.55%`, below the frozen 75% floor. The retention rule and threshold were not changed after observation.

This telemetry-first workflow completed in seconds instead of launching another large MT5 matrix. It found useful research structure without converting a near miss into a promoted bot. The verified real-tick leader remains `+$2,492.25`, `+24.92%`, `1.95%/yr` CAGR, PF `1.93`, and `1.18%` drawdown.

[Read the telemetry decision](outputs/FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_DECISION.md), [frozen contract](outputs/FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_CONTRACT.md), [exact 88-position ledger](outputs/FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_TRADES.csv), [full screen](outputs/FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_SCREEN.csv), and [telemetry source](work/Professional_XAUUSD_Four_Lane_M15_Squeeze_Feature_Telemetry_Research.mq5).

### Latest M15 Squeeze Partial-Runner Research

The default-off, restart-safe squeeze partial runner completed on `2026-07-20` and was rejected in frozen 2015-2020 Model 1 discovery. Eligible squeeze positions first lock the remainder at `+1.25R`, bank `80%` at the original `+1.50R` target, and let the remaining `20%` pursue `+4.00R`. Broker-volume geometry keeps unsplittable positions on the exact original target. Persisted owned-position state prevents a restart from repeating a partial close, and any protection, execution, or state ambiguity fails closed.

Static ownership, default-off, unchanged-entry, outcome-independence, restart, and protection-order checks passed. MetaEditor compiled the exact source with zero errors and warnings to one EX5 identity across four workers. All `27/27` reports were identity-valid after two unchanged report-export recoveries. The exact leader control and active `1.50R` squeeze reference reproduced their prior results, and every broad-window report was profitable.

The active reference made `+$1,575.70`, `+15.76%` total, `2.47%/yr` CAGR, PF `1.78`, 350 report trades, `1.10%` drawdown, and recovery `13.4434`. The fixed partial-runner center improved both disjoint eras and reached `+$1,695.16`, `+16.95%` total, `2.64%/yr` CAGR, PF `1.84`, 391 report trades, the same `1.10%` drawdown, and recovery `14.4626`. This was a `+$119.46` or `7.58%` net improvement over the active reference.

The center still failed the preregistered quality gate: PF `1.84` retained `97.87%` of the exact three-lane leader control's PF `1.88`, just below the frozen `98%` floor. Five of six one-factor neighbors passed, but neighbor support cannot override a failed center. No post-2020 or Model 4 test was opened, and the `90%` close or other observed neighbor was not substituted after seeing results.

The verified real-tick leader remains `+$2,492.25`, `+24.92%`, `1.95%/yr` CAGR, PF `1.93`, and `1.18%` drawdown. The frozen forward candidate remains unchanged; the attached `$100,000` demo counts as zero evidence and real-account trading remains disabled.

[Read the partial-runner rejection](outputs/FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_DECISION.md), [frozen contract](outputs/FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_CONTRACT.md), [exact Model 1 results](outputs/FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_MODEL1_RESULTS.csv), [canonical run evidence](outputs/FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_RUN_ATTESTATION.csv), and [research source](work/Professional_XAUUSD_Four_Lane_M15_Squeeze_Partial_Runner_Research.mq5).

### Latest M15 Squeeze Target Research

The settings-only eight-bar-squeeze target interaction completed on `2026-07-20` and was rejected in frozen 2015-2020 Model 1 discovery. An identity-bound hedging-ledger extraction first proved that the integrated `1.50R` squeeze lane added 88 trades, `+$209.91`, and PF `1.4954`, with positive net in both eras. A separate earlier one-factor experiment had shown that `2.00R` improved standalone squeeze PF, so their previously untested interaction was frozen with `1.75R` and `2.25R` neighbors.

The exact source and compiled EX5 were reused. Both disabled controls and the enabled `1.50R` reference reproduced exactly. All `18/18` reports parsed with exact identity after three unchanged report-export recoveries. Entries, eight-bar squeeze, H1 trend alignment, structural stop, break-even, session, `0.10%` lane risk, `0.75%` portfolio cap, loss limits, capital contract, and real-account lock remained unchanged.

The fixed `2.00R` center made `+$1,658.76`, a `20.21%` improvement over control, at `2.59%/yr` CAGR, PF `1.82`, 350 trades, `1.10%` drawdown, recovery `13.40`, and positive results in both disjoint eras. It failed because PF retained only `96.81%` of control versus the frozen `98%` floor. The `2.25R` upper edge reached `+$1,753.53`, `2.73%/yr` CAGR, PF `1.87`, `1.10%` drawdown, and passed the numeric neighbor gate, but it was not the preregistered center. Selecting that observed edge or shifting the target after seeing results would be threshold chasing.

No post-2020 or Model 4 run was opened. The verified real-tick leader remains `+$2,492.25`, the forward candidate is unchanged, and the invalid `$100,000` demo still counts as zero evidence.

[Read the target-interaction rejection](outputs/FOUR_LANE_M15_SQUEEZE_TARGET_INTERACTION_DISCOVERY_DECISION.md), [frozen contract](outputs/FOUR_LANE_M15_SQUEEZE_TARGET_INTERACTION_DISCOVERY_CONTRACT.md), [exact Model 1 results](outputs/FOUR_LANE_M15_SQUEEZE_TARGET_INTERACTION_DISCOVERY_MODEL1_RESULTS.csv), [canonical run evidence](outputs/FOUR_LANE_M15_SQUEEZE_TARGET_INTERACTION_DISCOVERY_RUN_ATTESTATION.csv), and [exact integrated ledger](outputs/FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_TRADES.csv).

### Latest M15 Squeeze-Diversifier Research

The default-off fourth-lane experiment completed on `2026-07-20` and was rejected in frozen 2015-2020 Model 1 discovery. It ports the independently nominated M15 Bollinger/Keltner squeeze breakout with H1 EMA trend alignment, structural ATR-bounded stop, `1.50R` target, break-even, and 32-bar time exit into the current three-lane leader. The lane runs last, owns one position and magic number, and remains subject to the unchanged `0.75%` broker-valued account-wide open-risk cap. No martingale, grid, averaging, recovery sizing, or real-account path was added.

Static ownership and outcome-independence checks passed. MetaEditor compiled the exact source with zero errors and warnings to one EX5 identity across four workers. All `15/15` reports parsed with exact identity after one unchanged report-export recovery. The disabled four-position capacity control exactly reproduced the three-position leader control, proving that capacity alone changed no result.

Control made `+$1,379.93`, `2.18%/yr` CAGR, PF `1.88`, 261 trades, `1.05%` drawdown, recovery `11.68`, and return/drawdown `13.14`. The fixed `0.10%` center made `+$1,575.70`, a `14.19%` net improvement, at `2.47%/yr` CAGR, 350 trades, `1.10%` drawdown, recovery `13.44`, and return/drawdown `14.33`. Both disjoint eras improved. However, PF fell to `1.78`, retaining only `94.68%` of control versus the frozen `98%` floor. The `0.075%` and `0.125%` neighbors retained only `95.21%` and `93.62%`, so support was `0/2`.

The efficiency gate was not weakened after observing the higher headline profit. No post-2020 or Model 4 run was opened, the verified real-tick leader remains `+$2,492.25`, and the invalid `$100,000` demo still counts as zero forward evidence.

[Read the squeeze rejection](outputs/FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_DECISION.md), [frozen contract](outputs/FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_CONTRACT.md), [exact Model 1 results](outputs/FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_MODEL1_RESULTS.csv), [canonical run evidence](outputs/FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_RUN_ATTESTATION.csv), and [research source](work/Professional_XAUUSD_Four_Lane_M15_Squeeze_Diversifier_Research.mq5).

### Latest Portfolio-Solo Reversion Allocation Research

The default-off portfolio-solo strong-signal lot-cap experiment completed on `2026-07-20` and was rejected in frozen 2015-2020 Model 1 discovery. It could raise only the existing strong-reversion lot ceiling when no momentum or adaptive-trend position was open. The completed-H1 signal threshold, `0.45%` reversion risk request, entries, stops, VWAP targets, exits, trade-count logic, `0.75%` portfolio cap, loss limits, capital contract, and real-account lock remained unchanged.

The research source passed static default-off, ownership, outcome-independence, and unchanged-trade-path checks. MetaEditor compiled it with zero errors and warnings to one exact EX5 identity across four workers. All `15/15` reports parsed with exact identity after one unchanged export recovery.

Control made `+$1,379.93`, `2.18%/yr` CAGR, PF `1.88`, 261 trades, `1.05%` drawdown, and recovery `11.68`. The fixed `0.18` center made `+$1,416.50`, a `2.65%` net increase, at `2.23%/yr` CAGR and PF `1.90`; however, older-era growth reached only `2.17%` versus the frozen `3%` floor, drawdown rose to `1.17%`, and recovery fell to `11.40`. The `0.17` and `0.19` neighbors also failed the preregistered growth and efficiency gates.

The cap was not moved after observation. No post-2020 or Model 4 run was opened, the verified real-tick leader remains `+$2,492.25`, and the invalid `$100,000` demo still counts as zero forward evidence.

[Read the solo-cap rejection](outputs/THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_DECISION.md), [exact Model 1 results](outputs/THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_RESULTS.csv), [canonical run evidence](outputs/THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_RUN_ATTESTATION.csv), and [research source](work/Professional_XAUUSD_Three_Lane_Reversion_Solo_Strong_Signal_Lot_Cap_Research.mq5).

### Latest Reversion Stop-Geometry Research

The exact leader's reversion structural-stop lookback was tested at 2, 3, 4, 5, and 6 completed H1 bars under a frozen 2015-2020 Model 1 contract. All `15/15` reports parsed with exact source and binary identity after one unchanged export recovery. The signal, stop buffer, VWAP target, requested risk, selective lot cap, other lanes, and every account protection remained unchanged.

The 5-bar control made `+$1,379.93`, `2.18%/yr` CAGR, PF `1.88`, 261 trades, `1.05%` drawdown, and recovery `11.68`. The fixed 3-bar center made `+$1,380.03`, only `$0.10` more; 4 and 6 bars exactly reproduced control. Two bars weakened the recent era by `$43.09` and continuous net by `$9.21`. No row provided the required broad, risk-adjusted improvement or adjacent support.

No holdout or Model 4 run was opened, and the verified historical leader remains unchanged.

[Read the stop-geometry rejection](outputs/THREE_LANE_REVERSION_STOP_GEOMETRY_DISCOVERY_DECISION.md), [exact Model 1 results](outputs/THREE_LANE_REVERSION_STOP_GEOMETRY_DISCOVERY_MODEL1_RESULTS.csv), and [canonical run evidence](outputs/THREE_LANE_REVERSION_STOP_GEOMETRY_DISCOVERY_RUN_ATTESTATION.csv).

### Latest Reversion Reward-Quality Risk Research

The default-off reward-quality risk interaction completed on `2026-07-20` and was rejected in frozen 2015-2020 Model 1 discovery. It allowed higher requested reversion risk only when the existing completed-H1 strong-body test and a fixed spread-adjusted reward/risk threshold both passed. The proven body-based `0.15`-lot ceiling, entries, stops, VWAP targets, exits, broker-valued sizing, `0.75%` portfolio cap, minimum-lot refusal, and real-account lock remained unchanged.

The exact source passed static ownership, outcome-independence, default-off, and unchanged-trade-path checks. MetaEditor compiled it with zero errors and warnings to one EX5 identity across four workers. All `21/21` reports parsed with exact source and binary identity after two unchanged report-export recoveries.

Control made `+$1,379.93`, `+13.80%` total, `2.18%/yr` CAGR, PF `1.88`, 261 trades, `1.05%` drawdown, and recovery `11.6775`. The frozen RR-`1.50` / risk-`0.70%` center and every fixed reward/risk neighbor made `+$1,369.88`, `+13.70%` total, `2.16%/yr` CAGR, PF `1.87`, the same 261 trades, `1.06%` drawdown, and recovery `11.5925`. Recent-era profit retention was only `95.76%`, and no neighbor passed the growth or efficiency gates.

The interaction supplied no stable gain, so no 2021-2026 holdout or Model 4 run was opened. The verified real-tick leader remains `+$2,492.25`, `+24.92%`, and `1.95%/yr` CAGR; the forward candidate remains unchanged and invalid for evidence on the attached `$100,000` demo.

[Read the reward-quality rejection](outputs/THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_DECISION.md), [exact Model 1 results](outputs/THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_MODEL1_RESULTS.csv), [canonical run evidence](outputs/THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_RUN_ATTESTATION.csv), and [research source](work/Professional_XAUUSD_Three_Lane_Reversion_Reward_Quality_Risk_Research.mq5).

### Latest Reversion Timeframe-Transfer Research

The exact leader's reversion lane was also tested on adjacent M30 and H2 signal timeframes under a frozen pre-2021 contract. Seven timeframe/horizon variants ran across 2015-2018, 2019-2020, and continuous 2015-2020. All `21/21` reports parsed with exact source and binary identity after two unchanged report-export recoveries; no strategy source change was required.

The isolated H1 control made `+$568.70` at `0.93%/yr` CAGR, PF `3.19`, and 19 trades. H2 local made `+$326.93` at `0.54%/yr` from only seven trades, while its two horizon neighbors made `+$41.80` and `-$47.78`. Every M30 row lost continuously, from `-$51.60` to `-$302.31`. No adjacent family provided both broad-era profitability and enough independent support, so holdout and Model 4 remained closed.

[Read the timeframe-transfer rejection](outputs/THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_DECISION.md), [exact Model 1 results](outputs/THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_MODEL1_RESULTS.csv), and [canonical run evidence](outputs/THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_RUN_ATTESTATION.csv).

### Latest Independent NR7 Breakout Research

The standalone D1 narrow-range / H1 breakout strategy completed on `2026-07-20` and was rejected in frozen 2015-2020 Model 1 discovery. It used only completed D1 and H1 bars: a configurable narrowest-range setup, fresh H1 structural break, D1 EMA trend, candle-body and tick-volume confirmation, broker-valued structural risk, fixed-R target, and optional chandelier protection. It shared no entry logic with the current three-lane leader.

The source passed 20 static safety checks. MetaEditor compiled it with zero errors and warnings to one EX5 identity across four isolated workers. All `54/54` reports were parsed with exact source and binary identity after four unchanged report-export recoveries.

The frozen center lost `$17.30` continuously at PF `0.43`, `-0.03%/yr` CAGR, and only 10 trades; both disjoint eras lost. The highest continuous result, the no-EMA variant, made only `+$10.34` at PF `1.28` and `0.02%/yr` CAGR with 14 trades, but lost `$14.75` in 2019-2020. No variant reached the minimum 80 trades or passed both-era profitability, so the entire neighborhood failed before recent data was opened.

No 2021-2026 holdout or Model 4 run was allowed, the engine was not merged into the forward candidate, and the verified historical leader remains `+$2,492.25` at `1.95%/yr` CAGR. The invalid `$100,000` demo still counts as zero forward evidence, and real-account trading remains disabled.

[Read the NR7 rejection](outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_DECISION.md), [exact Model 1 results](outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RESULTS.csv), [canonical run evidence](outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RUN.csv), and [research source](work/Independent_XAUUSD_D1_NR7_H1_Breakout.mq5).

### Latest Momentum Partial-Runner Research

The default-off momentum partial runner completed on `2026-07-20` and was rejected. Split-capable positions could bank a fixed portion at the existing `2R` target only after first protecting the remainder, then let that remainder pursue a farther target. Unsplittable `0.01`-lot positions kept the exact baseline exit. Restart-safe terminal state prevented duplicate partial closes, and consecutive-loss controls aggregated all scale-outs by position so an early profitable exit could not hide a losing remainder.

Static ownership and state checks passed. MetaEditor compiled the exact source with zero errors and warnings to one EX5 identity across four workers. The disabled control exactly reproduced the prior 2015-2018 and 2019-2020 leader results. All `24/24` pre-2021 Model 1 reports were profitable and identity-valid after two unchanged identity recoveries; the partial path was active.

The frozen `60%` close / `4R` target / `+1.25R` lock center reduced continuous 2015-2020 net from `+$1,379.93` to `+$1,373.21`. It missed the older-era floor and the recovery and return/drawdown floors. Only `2/6` fixed neighbors passed versus `4/6` required, so the discovery was rejected.

A separately preregistered interaction combined the two positive training components, `70%` close and `5R` target, and tested only post-2020 windows. All `12/12` holdout reports were profitable and identity-valid after two unchanged recoveries. The interaction produced `+$1,050.90` versus `+$1,046.44` control over 2021-2026, a gain of only `$4.46` or `0.43%`; the `5R` component alone gained `0.73%`. Neither met the frozen growth threshold. No Model 4 run, promotion, or forward substitution was allowed.

[Read the discovery rejection](outputs/THREE_LANE_MOMENTUM_PARTIAL_RUNNER_DISCOVERY_DECISION.md), [post-2020 holdout rejection](outputs/THREE_LANE_MOMENTUM_PARTIAL_RUNNER_INTERACTION_HOLDOUT_DECISION.md), [discovery summary](outputs/THREE_LANE_MOMENTUM_PARTIAL_RUNNER_DISCOVERY_SUMMARY.csv), [holdout summary](outputs/THREE_LANE_MOMENTUM_PARTIAL_RUNNER_INTERACTION_HOLDOUT_SUMMARY.csv), and [research source](work/Professional_XAUUSD_Three_Lane_Momentum_Partial_Runner_Research.mq5).

### Latest Reversion Band-Expansion Research

The one-factor reversion band-deviation expansion completed on `2026-07-20` and was rejected across four disjoint eras plus continuous 2015-2026 Model 1. All `20/20` reports were profitable and identity-valid after one unchanged recovery. Only `InpRVBollingerDeviation` changed from the exact leader.

Lowering the band from `2.00` produced monotonic deterioration: continuous net fell from `+$2,660.57` control to `+$2,270.43` at `1.90`, `+$1,915.92` at the frozen `1.80` center, and `+$1,260.43` at `1.70`. Drawdown rose from `1.15%` to as high as `1.80%`. The looser thresholds entered earlier but displaced stronger later reversion trades; none passed the frozen gate. Model 4 remained closed and the verified leader is unchanged.

[Read the band-expansion rejection](outputs/THREE_LANE_REVERSION_BAND_DEVIATION_EXPANSION_DISCOVERY_DECISION.md), [compact summary](outputs/THREE_LANE_REVERSION_BAND_DEVIATION_EXPANSION_DISCOVERY_SUMMARY.csv), [lane evidence](outputs/THREE_LANE_REVERSION_BAND_DEVIATION_EXPANSION_DISCOVERY_LANE_EVIDENCE.csv), and [displacement evidence](outputs/THREE_LANE_REVERSION_BAND_DEVIATION_EXPANSION_DISCOVERY_DISPLACEMENT_EVIDENCE.csv).

### Latest Capital-Efficiency Research

The proportional capital-efficiency ladder completed on `2026-07-20` and was rejected in a frozen full-history Model 1 discovery. It reused the exact verified leader source and tested `1.00x`, `1.25x`, `1.50x`, and `1.75x` requested lane risk across 2015-2018, 2019-2020, 2021-2023, 2024-2026, and continuous 2015-2026. The `5%` equity drawdown lock and all daily, weekly, monthly, cooldown, entry, exit, and real-account protections remained unchanged.

All `20/20` reports parsed with exact source, EX5, config, report, and sidecar identity after one unchanged isolated identity retry. Every row was profitable. Model 1 control made `+$2,660.57`, `2.07%/yr` CAGR, PF `1.98`, 411 trades, `1.15%` drawdown, recovery `18.9068`, and return/drawdown `23.14`.

The frozen `1.50x` center increased net to `+$3,145.43` and CAGR to `2.40%/yr`, but missed the required 20% net increase and weakened PF to `1.69`, drawdown to `2.26%`, recovery to `11.7279`, and return/drawdown to `13.92`. The `1.25x` neighbor earned only `+$2,177.34`; the `1.75x` row had the highest headline at `+$3,347.90`, but drawdown rose to `3.43%`, recovery fell to `8.4381`, and return/drawdown fell to `9.76`. Neither neighbor passed.

The gate was not relaxed after observing the higher headline profit. Model 4 remained closed, the verified real-tick leader remains `+$2,492.25` at `1.95%/yr` CAGR and `1.18%` drawdown, and no forward or real-account setting changed.

[Read the capital-efficiency rejection](outputs/THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_DECISION.md), [compact summary](outputs/THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_SUMMARY.csv), [exact Model 1 results](outputs/THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_MODEL1_RESULTS.csv), and [run attestation](outputs/THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_RUN_ATTESTATION.csv).

### Previous D1 EMA-Slope Research

The code-level D1 EMA-slope overextension guard completed on `2026-07-20` and was rejected in its frozen Model 1 neighborhood. It was nominated only after a behavior-neutral full-history Model 4 telemetry fork exactly reproduced the historical leader at `+$2,492.25`, 400 trades, PF `1.93`, and `1.18%` drawdown. The 310 momentum trades were then screened across 2015-2018, 2019-2020, 2021-2023, and 2024-2026.

None of 94 original causal entry-feature thresholds passed the broad-era and neighborhood gates. An expanded telemetry fork added completed-bar D1/H4/H1 ADX, D1 50/200 EMA state, directional efficiency, daily range position, and H1 compression without adding a strategy input or trade path. It again reproduced the leader exactly. A maximum direction-adjusted 50-day EMA slope of `1.00 D1 ATR` had a coherent offline `0.75/1.00/1.25` neighborhood, so a default-off strategy implementation was allowed into fresh MT5 testing.

All `20/20` Model 1 reports parsed across four disjoint eras and the continuous 2015-2026 period. The `1.00 ATR` center improved continuous net from `+$2,660.57` to `+$2,746.31`, CAGR from `2.07%/yr` to `2.13%/yr`, PF from `1.98` to `2.61`, drawdown from `1.15%` to `1.10%`, and recovery from `18.9068` to `20.5332`; all four broad eras remained profitable. However, the `0.75 ATR` and `1.25 ATR` neighbors fell to `+$2,612.36` and `+$2,629.03`, both below control. The isolated center peak failed the frozen support requirement, so no strategy Model 4 confirmation, promotion, or forward substitution was allowed.

The verified real-tick leader remains the 60-minute same-side cooldown at `+$2,492.25`, `+24.92%`, `1.95%/yr` CAGR, PF `1.93`, and `1.18%` drawdown. The attached `$100,000` demo remains invalid against the frozen `$10,000` contract, and real-account trading remains disabled.

[Read the D1 EMA-slope rejection](outputs/THREE_LANE_MOMENTUM_D1_EMA_SLOPE_GUARD_DISCOVERY_DECISION.md), [exact Model 1 results](outputs/THREE_LANE_MOMENTUM_D1_EMA_SLOPE_GUARD_DISCOVERY_MODEL1_RESULTS.csv), [market-phase screen](outputs/THREE_LANE_MOMENTUM_MARKET_PHASE_TELEMETRY_MODEL4_FULL_SCREEN.md), [exact expanded ledger](outputs/THREE_LANE_MOMENTUM_MARKET_PHASE_TELEMETRY_MODEL4_FULL_TRADES.csv), and [research source](work/Professional_XAUUSD_Three_Lane_Momentum_D1_Ema_Slope_Guard_Research.mq5).

### Latest Risk-Allocation Research

The settings-only momentum/adaptive risk-reallocation experiment completed on `2026-07-20` and was rejected in frozen pre-2021 discovery. The exact published leader source and same-side cooldown remained unchanged. Reversion risk stayed `0.45%`, and each row kept the declared lane-risk sum plus the broker-valued portfolio open-risk cap fixed at `0.75%`; only `0.01` to `0.05` percentage points moved from the adaptive lane to momentum.

All `15/15` Model 1 reports passed exact source, EX5, config, report, and sidecar identity checks after three first-pass identity refusals were rerun unchanged. Control exactly reproduced `+$1,379.93`, `2.18%/yr` CAGR, PF `1.88`, 261 trades, `1.05%` drawdown, recovery `11.6775`, and return/drawdown `13.1429` over 2015-2020.

The frozen `0.20%` momentum / `0.10%` adaptive center reached `+$1,519.85` and `2.39%/yr`, but 2019-2020 profit fell from `+$370.60` to `+$313.36`. PF fell to `1.80`, drawdown rose to `1.40%` against the frozen `1.25%` ceiling, recovery fell to `9.6849`, return/drawdown fell to `10.8571`, and trades fell to 228 against the required minimum 256.

Zero of three lower allocations passed the complete support gate. The higher continuous net is therefore a rejected in-sample headline, not a new best. Newer data and Model 4 remained closed, and the verified real-tick leader remains the 60-minute same-side cooldown at `+$2,492.25`, `1.95%/yr` CAGR, PF `1.93`, and `1.18%` drawdown.

[Read the risk-reallocation rejection](outputs/THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_DECISION.md), [frozen contract](outputs/THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_CONTRACT.md), [compact summary](outputs/THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_SUMMARY.csv), and [exact Model 1 results](outputs/THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_MODEL1_RESULTS.csv).

### Earlier Momentum Market-Phase Research

A maximum H1 breakout-channel width normalized by ATR was nominated from 2015-2018 training telemetry and rejected on the frozen 2019-2020 feature rows. The `6.0`, `6.5`, and `7.0 ATR` thresholds had all improved training momentum net and PF in both training halves, so `6.5 ATR` was frozen as the center before their validation outcomes were calculated.

The pattern did not transfer. Validation momentum net fell from `+$147.65` to `+$71.42` at the center, PF fell from `1.3858` to `1.1925`, and the projected full-period portfolio net fell by `$19.85` to `+$1,360.08`. The `6.0` and `7.0 ATR` neighbors projected `+$1,271.32` and `+$1,331.36`; support was `0/3` versus `2/3` required.

Because the telemetry gate failed, no strategy code was implemented and no MT5 rerun, post-2020 test, or Model 4 test was allowed. This is a useful speed improvement in the research loop: recorded completed-bar features can reject a weak idea before consuming tester time. The historical leader and every live-safety boundary remain unchanged.

[Read the channel-width rejection](outputs/THREE_LANE_MOMENTUM_CHANNEL_WIDTH_DECISION.md), [frozen nomination](outputs/THREE_LANE_MOMENTUM_CHANNEL_WIDTH_NOMINATION.md), and [exact validation table](outputs/THREE_LANE_MOMENTUM_CHANNEL_WIDTH_VALIDATION.csv).

### Latest Momentum Profit-Ratchet Research

The default-off completed-H1 profit ratchet completed on `2026-07-20` and was rejected in frozen pre-2021 discovery. It added a second stop-protection step after the existing `1.0R` break-even rule: the frozen center could lock `0.75R` only after favorable movement reached `1.50R`. Entry signals, initial stops, the `2.0R` take-profit, requested risk, lot caps, portfolio exposure limits, and every safety lock remained unchanged.

Static checks confirmed exactly three new inputs and no new entry, close, or stop-modification path. MetaEditor compiled the exact source with zero errors and warnings to one EX5 identity across four workers. All `24/24` Model 1 reports and identity sidecars passed after two unchanged report-export retries.

The disabled control exactly reproduced `+$1,379.93`, `2.18%/yr` CAGR, PF `1.88`, 261 trades, `1.05%` drawdown, recovery `11.6775`, and return/drawdown `13.1429`. The center reached `+$1,382.26`, an increase of only `$2.33` or `0.17%`; CAGR stayed `2.18%/yr`, drawdown rose to `1.06%`, and return/drawdown fell to `13.0377`. It also lost `$6.19` versus control in 2015-2018.

Zero of six trigger/lock neighbors passed the complete gate. The aggressive `1.25R` trigger / `1.00R` lock reduced continuous net by `4.58%`, while two conservative rows were behaviorally inactive. The thresholds were not moved after observation, reserved 2021-2022 data was not opened, and no Model 4 run or promotion was allowed. The same-side cooldown profile remains the historical leader.

[Read the profit-ratchet rejection](outputs/THREE_LANE_MOMENTUM_PROFIT_RATCHET_DISCOVERY_DECISION.md), [compact summary](outputs/THREE_LANE_MOMENTUM_PROFIT_RATCHET_DISCOVERY_SUMMARY.csv), [exact Model 1 results](outputs/THREE_LANE_MOMENTUM_PROFIT_RATCHET_DISCOVERY_MODEL1_RESULTS.csv), and [research source](work/Professional_XAUUSD_Three_Lane_Momentum_Profit_Ratchet_Research.mq5).

### Latest Strong-Breakout Target Research

The default-off strong-breakout target extension completed on `2026-07-20` and was rejected in frozen pre-2021 discovery. It kept every entry, initial stop, requested risk, lot cap, portfolio exposure limit, and safety path unchanged. Only completed H1 momentum breakouts with body ratio at least `0.50` and directional close location at least `0.75` received the frozen `3.0R` target instead of `2.0R`.

The source passed static checks with four new inputs, zero new entry/close/modify paths, completed-bar-only reads, unchanged `0.15%` momentum risk, and the `0.75%` account-wide exposure cap. MetaEditor compiled it with zero errors and warnings to one EX5 identity across four workers. All `24/24` Model 1 reports and identity sidecars passed after three unchanged export retries.

The disabled control exactly reproduced `+$1,379.93`, `2.18%/yr` CAGR, PF `1.88`, 261 trades, and `1.05%` drawdown. The center improved 2019-2020 from `+$370.60` to `+$410.71`, but reduced 2015-2018 from `+$1,036.19` to `+$914.53`. Continuous net fell to `+$1,293.17`, CAGR to `2.05%/yr`, and recovery to `8.3285`, while drawdown rose to `1.48%`.

Every enabled target/body/close-location neighbor also reduced continuous profit by `3.50%` to `6.97%`; support was `0/6` versus `3/6` required. The thresholds were not moved, reserved 2021-2022 data was not opened, and no Model 4 run or promotion was allowed.

[Read the target-extension rejection](outputs/THREE_LANE_MOMENTUM_STRONG_BREAKOUT_TARGET_EXTENSION_DISCOVERY_DECISION.md), [frozen contract](outputs/THREE_LANE_MOMENTUM_STRONG_BREAKOUT_TARGET_EXTENSION_DISCOVERY_CONTRACT.md), [compact summary](outputs/THREE_LANE_MOMENTUM_STRONG_BREAKOUT_TARGET_EXTENSION_DISCOVERY_SUMMARY.csv), and [exact Model 1 results](outputs/THREE_LANE_MOMENTUM_STRONG_BREAKOUT_TARGET_EXTENSION_DISCOVERY_MODEL1_RESULTS.csv).

### Earlier Momentum Telemetry Research

A behavior-neutral telemetry pass completed on `2026-07-20`. The fork added no strategy input or trade path and recorded only completed-bar D1 return, breakout geometry, candle structure, ATR, channel width, tick-volume ratio, and actual stop/ATR after an existing momentum fill. It exactly reproduced the leader's pre-2021 Model 1 control at `+$1,379.93`, `+13.80%` total, `2.18%/yr` CAGR, PF `1.88`, 261 portfolio trades, and `1.05%` drawdown.

Training on 133 momentum trades from 2015-2018 nominated a new channel-normalized breakout-penetration feature. Minimum ratios of `0.015`, `0.020`, and `0.025` all improved training momentum net and PF and removed net losers independently in both training halves. The `0.020` center increased training momentum net from `+$478.60` to `+$531.97` and PF from `1.66` to `1.97`.

The frozen pattern failed on the 61 reserved 2019-2020 momentum trades. The center reduced validation net from `+$147.65` to `+$73.06`, PF from `1.3858` to `1.1985`, and projected full-period portfolio net from `+$1,379.93` to `+$1,358.71`. Both neighbors also reduced validation and full-period net because they removed large 2020 winners. Support was `0/3` versus `2/3` required. No filter code was implemented, thresholds were not moved, and post-2020 data remained unopened.

[Read the telemetry rejection](outputs/THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_DECISION.md), [frozen nomination contract](outputs/THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_NOMINATION.md), [reserved validation](outputs/THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_VALIDATION.csv), [exact trade-feature ledger](outputs/THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_TRADES.csv), and [run attestation](outputs/THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_RUN_ATTESTATION.csv).

### Earlier D1 Extreme-Guard Research

The D1 extreme-momentum guard completed on `2026-07-20` and was rejected as a frozen near-miss. The default-off code tested maximum absolute 126-bar D1 close returns of `12%`, `18%`, `24%`, and `30%` before the momentum lane could accept its existing fresh H1 breakout. It added no entry, close, or stop-modification path; risk, targets, the `0.75%` account-wide exposure cap, and the real-account lock stayed unchanged.

All `15/15` Model 1 reports and identity sidecars passed exact checks after two unchanged report-export retries. The `18%` center improved continuous 2015-2020 net from `+$1,379.93` to `+$1,416.00`, total return from `13.80%` to `14.16%`, CAGR from `2.18%` to `2.23%/yr`, PF from `1.88` to `1.95`, and recovery from `11.6775` to `12.0809`.

It still failed the preregistered robustness gate: 2015-2018 was `$1.61` worse, drawdown rose from `1.05%` to `1.11%`, and return/drawdown fell from `13.1429` to `12.7568`. The `12%` neighbor also weakened return/drawdown, while the `24%` and `30%` rows improved net only `0.62%`; support was `0/3` versus `2/3` required. The threshold was not moved after observation. Recent data and Model 4 remained closed, and the historical leader remains unchanged.

[Read the extreme-guard rejection](outputs/THREE_LANE_MOMENTUM_D1_EXTREME_GUARD_DISCOVERY_DECISION.md), [compact summary](outputs/THREE_LANE_MOMENTUM_D1_EXTREME_GUARD_DISCOVERY_SUMMARY.csv), [exact Model 1 results](outputs/THREE_LANE_MOMENTUM_D1_EXTREME_GUARD_DISCOVERY_MODEL1_RESULTS.csv), and [run attestation](outputs/THREE_LANE_MOMENTUM_D1_EXTREME_GUARD_DISCOVERY_RUN_ATTESTATION.csv).

### Earlier D1 Momentum-Strength Research

The D1 momentum-strength gate completed on `2026-07-20` and was rejected in frozen pre-2021 discovery. The default-off code tested whether the momentum lane should require a meaningful absolute 126-bar D1 close return before accepting its existing fresh H1 breakout. It added no entry, close, or stop-modification path; momentum risk remained `0.15%`, the account-wide open-risk cap remained `0.75%`, and real-account trading remained disabled.

All `12/12` Model 1 reports and identity sidecars passed exact source, EX5, config, and report checks after one unchanged report-export retry. The disabled control made `+$1,379.93`, `+13.80%` total, `2.18%/yr` CAGR, PF `1.88`, 261 trades, `1.05%` drawdown, and recovery `11.6775` in continuous 2015-2020.

Every enabled threshold was weaker. Minimum D1 strength of `2%`, `4%`, and `6%` reduced continuous net to `+$1,227.66`, `+$1,131.34`, and `+$1,005.57`; CAGR fell to `1.95%`, `1.80%`, and `1.61%/yr`. Recovery and Sharpe also declined at every threshold, and 2015-2018 weakened monotonically. The family therefore has no robust plateau. Recent data and Model 4 remained closed, the current same-side cooldown leader remains unchanged, and no live approval was granted.

[Read the D1-strength rejection](outputs/THREE_LANE_MOMENTUM_D1_STRENGTH_GATE_DISCOVERY_DECISION.md), [compact summary](outputs/THREE_LANE_MOMENTUM_D1_STRENGTH_GATE_DISCOVERY_SUMMARY.csv), [exact Model 1 results](outputs/THREE_LANE_MOMENTUM_D1_STRENGTH_GATE_DISCOVERY_MODEL1_RESULTS.csv), and [run attestation](outputs/THREE_LANE_MOMENTUM_D1_STRENGTH_GATE_DISCOVERY_RUN_ATTESTATION.csv).

### Earlier Momentum-Buy Payoff Research

The momentum-buy payoff experiment was rejected in frozen pre-2021 discovery. Its `2.50R` center improved net from `+$1,353.74` to `+$1,412.34`, but returned 261 trades versus the preregistered minimum 263 and had `0/3` passing neighbors. The gate was not relaxed, so newer data and Model 4 remained closed.

[Read the buy-payoff rejection](outputs/THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_DECISION.md).

### Earlier Residual-Risk Research

The momentum-buy residual-risk experiment completed on `2026-07-20` and was rejected in frozen pre-2021 discovery. Exact Model 4 leader attribution had shown that 205 momentum buys made `+$496.04` at PF `1.40` and were profitable in all three broad eras, so the code tested whether already-base-eligible buys could use a small amount of unused portfolio capacity. Momentum sells stayed at `0.15%`, the original `0.15%` buy lot had to exist before residual sizing, and the broker-valued account-wide open-risk cap remained `0.75%`. No entry, stop, target, exit, martingale, grid, averaging, recovery-sizing, or live-account path was added.

The exact source passed its default-off, base-lot, outcome-independence, ownership, and unchanged-trade-path audit. MetaEditor compiled it with zero errors and warnings to one EX5 identity. All `18/18` Model 1 reports were accepted with exact source, EX5, config, report, and sidecar identity after one report-export identity refusal was rerun unchanged on a healthy worker.

Control made `+$1,353.74`, `2.14%/yr` CAGR, PF `1.85`, 265 trades, `1.06%` drawdown, recovery `11.4559`, and return/drawdown `12.7736`. The frozen `0.20%` buy center made `+$1,524.39`, `2.39%/yr`, and passed the headline growth gates, but PF fell to `1.78`, drawdown rose to `1.30%`, recovery fell to `10.3976`, return/drawdown fell to `11.7231`, and trades increased to 266. It failed the frozen efficiency, drawdown, and control-trade-count gates.

None of the four lower rungs passed the complete support gate. The `0.18%` and `0.19%` rows improved net, but drawdown rose to `1.33%`; the lower allocations also weakened PF, recovery, or broad-era retention. Selecting only the attractive headline after observation would accept a fragile risk/lot-step neighborhood, so 2021-2026 and Model 4 remained closed. The provisional strong-signal selective reversion lot-cap leader remains unchanged.

[Read the residual-risk rejection](outputs/THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_DECISION.md), [the frozen contract](outputs/THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_CONTRACT.md), [the compact summary](outputs/THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_SUMMARY.csv), [the exact report ledger](outputs/THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_MODEL1_RESULTS.csv), and [the direction attribution](outputs/THREE_LANE_MOMENTUM_DIRECTION_ATTRIBUTION.md).

### Earlier Partial-Runner Research

The strong-signal reversion partial-runner experiment completed on `2026-07-20` and was rejected in frozen pre-2021 discovery. Its default-off code left entries, initial stops, requested risk, lot caps, and portfolio guards unchanged. On completed-H1 body-`0.25` reversion signals with splittable volume, it moved the TP beyond the original VWAP, confirmed a profitable stop before closing most of the position at VWAP, and persisted filled volume plus completion state so a restart could not repeat the partial close.

Static ownership, volume, restart, and fail-closed checks passed. MetaEditor compiled the exact source with zero errors and zero warnings, one EX5 identity was installed on four portable workers, and `24/24` reports were accepted after five unchanged retries for MT5 agent-port/report-export failures. Active profiles produced 270 continuous report trades versus 265 for control, confirming that the partial path executed.

Control made `+$1,353.74`, `2.14%/yr` CAGR, PF `1.85`, `1.06%` drawdown, and recovery `11.4559`. The frozen 80%-close / 2.00x-target / +0.50R-lock center made `+$1,325.39`, `2.10%/yr`, PF `1.84`, the same rounded drawdown, and recovery `11.2160`. It reduced continuous net by `$28.35` and reduced 2019-2020 by `$21.63`, missing the 98% independent-era retention floor as well as the growth and efficiency gates.

The 1.75x-target row reached the best headline at `+$1,392.02`, but it was not the preregistered center and its 2019-2020 result was only `+$348.78` versus control `+$370.41`, below the frozen era floor. Selecting it after observation would be threshold chasing. The family was rejected with `0/6` passing neighbors, so 2021-2026 and Model 4 remained unopened.

[Read the partial-runner rejection](outputs/THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_DECISION.md), [the frozen contract](outputs/THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_CONTRACT.md), [the compact summary](outputs/THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_SUMMARY.csv), and [the exact evidence ledger](outputs/THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_EVIDENCE.csv).

### Earlier Agreement Allocation Research

The momentum/adaptive agreement allocation was rejected on `2026-07-20`. Its `0.25%` center added only `$12.01` continuously, lost `$31.83` in 2015-2018, weakened PF/recovery/return-to-drawdown, exceeded its drawdown ceiling, and had `0/3` passing neighbors. The best `0.225%` headline missed its frozen growth and recovery floors, so no recent-data or Model 4 run was opened.

[Read the agreement-allocation rejection](outputs/THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_DECISION.md), [the compact summary](outputs/THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_SUMMARY.csv), [the exact evidence ledger](outputs/THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_EVIDENCE.csv), and [the retrospective attribution](outputs/THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_ATTRIBUTION.md).

### Earlier Momentum Exit Research

The momentum-exit ablation diagnostic completed on `2026-07-20` and was rejected in sealed pre-2021 discovery. It reused the exact published leader source and compared the existing H1 channel, D1 momentum-failure, and 120-H1-bar time exits in all meaningful enabled/disabled combinations. Entry rules, initial stops, targets, risk, sizing, account protections, and the real-account lock remained unchanged.

All `24/24` Model 1 reports were accepted with exact source, EX5, config, report, and sidecar identity after three unchanged identity retries. The full control made `+$1,353.74`, `+13.54%` total, `2.14%/yr` CAGR, PF `1.85`, `1.06%` drawdown, recovery `11.4559`, and return/drawdown `12.7736` in continuous 2015-2020.

The H1 channel exit was the only mechanism that changed behavior in this sample. Removing it improved 2019-2020 from `+$370.41` to `+$428.75`, but reduced 2015-2018 from `+$1,001.72` to `+$879.08` and continuous net to `+$1,302.73`. PF fell to `1.73`, drawdown rose to `1.24%`, recovery fell to `9.5368`, and return/drawdown fell to `10.5081`. The momentum-failure and time exits were inactive whenever the channel exit remained enabled. No alternative was no worse in both disjoint eras, so the frozen gate returned `0` passing ablations and no code follow-up, recent-data run, or Model 4 run was opened.

[Read the momentum-exit rejection](outputs/THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_DECISION.md), [the compact summary](outputs/THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_SUMMARY.csv), and [the exact evidence ledger](outputs/THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_EVIDENCE.csv).

### Earlier Joint Strong-Signal Allocation Research

The joint strong-signal allocation experiment completed on `2026-07-20` and was rejected in sealed pre-2021 discovery. It reused the exact published leader source and combined the proven completed-H1 body-`0.25` / `0.15`-lot ceiling with requested reversion risk `0.65%`. Broker-valued sizing, minimum-lot refusal, post-fill reconciliation, and the unchanged `0.75%` account-wide open-risk cap remained authoritative; no entry, stop, target, exit, or live-account protection changed.

All `21/21` Model 1 reports were accepted with exact source, EX5, config, report, and sidecar identity after two unchanged identity retries. The exact leader control made `+$1,353.74`, `2.14%/yr` CAGR, PF `1.85`, `1.06%` drawdown, recovery `11.4559`, and return/drawdown `12.7736` in continuous 2015-2020. The frozen risk-`0.65%` center made only `+$1,327.11`, `2.10%/yr` CAGR, PF `1.83`, recovery `11.2305`, and return/drawdown `12.5189`.

Risk `0.60%`, `0.65%`, and `0.70%` collapsed to the same broker lot decisions and all lost `$26.63` versus control. The body-`0.225` neighbor reached `+$1,369.84`, but its `1.19%` gain missed the frozen `1.5%` neighbor floor and drawdown rose to `1.21%`; selecting it after observation would be threshold chasing. The family was rejected with `0/4` passing neighbors, so 2021-2026 and Model 4 remained unopened.

[Read the joint-allocation rejection](outputs/THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_DISCOVERY_DECISION.md), [the compact summary](outputs/THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_DISCOVERY_SUMMARY.csv), and [the exact evidence ledger](outputs/THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_DISCOVERY_EVIDENCE.csv).

### Earlier High-Reward Lot-Cap Research

The high-reward strong-signal lot-cap experiment completed on `2026-07-20` and was rejected in sealed pre-2021 discovery. The default-off code preserved the proven completed-H1 body-`0.25` / `0.15`-lot rule, then allowed a `0.20` ceiling only when the same entry's spread-adjusted reward/risk was at least `2.50`. Requested reversion risk stayed `0.45%`, account-wide open risk stayed capped at `0.75%`, and no entry, close, stop-modification, martingale, grid, averaging-down, or recovery-sizing path was added.

All `21/21` Model 1 reports were accepted with exact source, EX5, config, report, and sidecar identity after one unchanged identity retry. The exact control made `+$1,353.74`, `2.14%/yr` CAGR, PF `1.85`, and `1.06%` drawdown in continuous 2015-2020. The frozen RR-`2.50` / cap-`0.20` center made `+$1,380.68`, `2.18%/yr` CAGR, PF `1.87`, and the same `1.06%` drawdown.

The `$26.94` gain was only `1.99%`, below the preregistered `4%` growth requirement, and CAGR improved by `0.04` point versus the required `0.06`. The center retained `54.59%` of the broad cap-`0.20` reference's incremental net and improved its efficiency, but none of the four RR/cap neighbors reached the frozen `2.5%` growth floor. The family was therefore rejected without moving a threshold, and 2021-2026 plus Model 4 remained unopened.

[Read the high-reward lot-cap rejection](outputs/THREE_LANE_REVERSION_HIGH_REWARD_LOT_CAP_DISCOVERY_DECISION.md), [the compact summary](outputs/THREE_LANE_REVERSION_HIGH_REWARD_LOT_CAP_DISCOVERY_SUMMARY.csv), and [the exact evidence ledger](outputs/THREE_LANE_REVERSION_HIGH_REWARD_LOT_CAP_DISCOVERY_EVIDENCE.csv).

### Earlier Tiered Lot-Cap Research

The tiered very-strong-signal lot-cap experiment completed on `2026-07-20` and was rejected in sealed pre-2021 discovery. The default-off strategy-code change preserved the proven completed-H1 body-`0.25` / `0.15`-lot rule, then allowed only an additional body-`0.40` tier to use a `0.20`-lot ceiling. Requested reversion risk stayed `0.45%`, account-wide open risk stayed capped at `0.75%`, and no entry, close, stop-modification, martingale, grid, averaging-down, or recovery-sizing path was added.

All `21/21` Model 1 reports were accepted with exact source, EX5, config, report, and sidecar identity after three unchanged identity retries. The exact control made `+$1,353.74`, `2.14%/yr` CAGR, PF `1.85`, and `1.06%` drawdown in continuous 2015-2020. The frozen body-`0.40` / cap-`0.20` center made `+$1,369.37`, `2.16%/yr` CAGR, PF `1.86`, and the same `1.06%` drawdown.

The `$15.63` gain was only `1.15%`, below the preregistered `1.5%` growth requirement, and CAGR improved by `0.02` point versus the required `0.03`. The center retained only `31.67%` of the broad body-`0.25` / cap-`0.20` reference's incremental net, below the frozen `40%` requirement. Three of four orthogonal neighbors passed, but the body-`0.45` neighbor was inactive. The family was therefore rejected without moving a threshold, and 2021-2026 plus Model 4 remained unopened.

[Read the tiered lot-cap rejection](outputs/THREE_LANE_REVERSION_TIERED_STRONG_SIGNAL_LOT_CAP_DISCOVERY_DECISION.md), [the compact summary](outputs/THREE_LANE_REVERSION_TIERED_STRONG_SIGNAL_LOT_CAP_DISCOVERY_SUMMARY.csv), and [the exact evidence ledger](outputs/THREE_LANE_REVERSION_TIERED_STRONG_SIGNAL_LOT_CAP_DISCOVERY_EVIDENCE.csv).

### Current Leader Validation

The strong-signal selective lot-cap experiment completed on `2026-07-20`. It was a strategy-code change: only already-valid reversion entries with a completed-H1 body ratio of at least `0.25` may use a `0.15`-lot ceiling; all other reversion entries retain `0.10`. The feature is default-off in source, uses no current/future bar or prior trade outcome, adds no entry or exit path, and never raises requested risk above `0.45%`.

Sealed 2015-2020 Model 1 discovery passed all growth, risk, efficiency, and neighbor gates. The `0.15` selective center reached `+$1,353.74`, `2.14%/yr` CAGR, PF `1.85`, `1.06%` drawdown, recovery `11.4559`, and return/drawdown `12.7736` versus control at `+$1,191.69`, `1.89%/yr`, PF `1.77`, `1.02%` drawdown, recovery `10.5778`, and return/drawdown `11.6863`.

The exact center then passed feature-level 2021-2026 validation: continuous net improved from `+$944.62` to `+$1,045.26`, CAGR from `1.64%` to `1.81%`, PF from `2.01` to `2.07`, and recovery from `7.3380` to `8.1198`, while drawdown fell from `1.23%` to `1.21%`. Every paired recent window was positive and no worse than control.

Exact Model 4 real ticks confirmed the result across 2015-2018, 2019-2022, 2023-2026, and continuous 2015-2026. Continuous net rose from `+$2,105.08` to `+$2,428.50`, CAGR from `1.67%` to `1.90%`, PF from `1.81` to `1.89`, recovery from `15.6686` to `17.0889`, and return/drawdown from `18.3043` to `20.5763`; all three disjoint eras remained profitable and no worse than control.

All 12 annual center restarts were profitable. The summed annual robustness score increased from `+$1,999.97` to `+$2,260.63` with the same 392 trades, 11 of 12 years were no worse than control, and worst annual drawdown stayed `1.24%`. Under severe added execution cost of `0.10R` per trade, net remained `+$1,798.19`, PF `1.59`, closed-trade drawdown `1.26%`, and every broad era stayed positive. All eight clustered 10,000-trial Monte Carlo scenarios passed; the weakest severe P05 net was still `+$379.29`, with `0.65%` red trials and `4.26%` P95 closed-trade drawdown.

The exact hard-risk audit found maximum reversion initial risk `0.4448%`, maximum portfolio initial risk `0.5892%` against the `0.75%` cap, maximum volume `0.15` lots, and zero lane or portfolio violations. A second broker/specification test and a valid frozen `$10,000` forward demo are still missing, so this is the provisional historical research leader, not a released live bot. The registered forward candidate and invalid-account boundary remain unchanged.

[Open the exact provisional source/profile package](release/three-lane-reversion-strong-signal-lot-cap-provisional/README.md), [Model 4 decision](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_DECISION.md), [annual decision](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_DECISION.md), [stress decision](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_STRESS_DECISION.md), and [risk audit](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_RISK_AUDIT.md).

### Earlier Unconditional Lot-Cap Research

The reversion lot-cap experiment completed on `2026-07-19`. Exact ATB150 trade-ledger evidence showed that 29 of 38 real-tick reversion trades reached the existing `0.10`-lot ceiling, leaving average deployed initial risk near `0.28%` even though the lane requested `0.45%`. The contract therefore froze a settings-only `0.10 / 0.12 / 0.15 / 0.18 / 0.20` lot-cap ladder. The EA source stayed byte-identical to ATB150; requested reversion risk stayed `0.45%`; portfolio open risk stayed capped at `0.75%`; and all entries, stops, targets, exits, post-fill checks, loss limits, capital locks, and real-account protections remained unchanged.

All `15/15` Model 1 reports completed in `145` seconds with zero errors or retries and exact source, EX5, config, report, and sidecar identity. Every row was profitable in both disjoint discovery eras. Control returned `+$1,191.69`, `+11.92%` total, `+1.89% per year`, PF `1.77`, `1.02%` drawdown, recovery `10.5778`, and return/drawdown `11.6863`. The `0.12` lower row reached `+$1,286.73` and `2.04%` per year with `1.12%` drawdown and higher `10.8722` recovery.

The frozen `0.15` center increased net to `+$1,419.25`, total return to `+14.19%`, CAGR to `2.24%`, and PF to `1.85`, but drawdown rose to `1.30%`, recovery fell to `10.3136`, and return/drawdown fell to `10.9154`. It failed the preregistered efficiency and drawdown gates. The `0.18` and `0.20` rows raised net further but weakened recovery and return/drawdown again while drawdown reached `1.47%` and `1.59%`. The attractive `0.12` row cannot be selected after observation because it was frozen as a neighbor, not the center.

The family was rejected without choosing a different cap or opening 2021-2026 and Model 4. These results show that the old fixed lot ceiling suppresses return, but simply lifting it converts that suppression into progressively worse drawdown efficiency. ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the lot-cap rejection](outputs/THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_DECISION.md), [the compact results](outputs/THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_SUMMARY.csv), and [the exact run attestation](outputs/THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_RUN_ATTESTATION.csv).

### Earlier Strong-Signal High-Water Risk Research

The strong-reversion high-water risk-throttle experiment completed on `2026-07-19`. It targeted the closest prior real-tick near-pass: completed-H1 body ratio `0.25` / requested reversion risk `0.70%` had raised historical Model 4 CAGR from `1.67%` to `1.80%` but missed the frozen recovery gate by `0.0020`. The new default-off code allowed that extra risk only while current equity remained within a fixed percentage of the portfolio's existing high-water mark; otherwise it fell back to the champion's `0.45%` base reversion risk. It could only reduce risk during drawdown and added no entry, exit, stop-modification, lot-cap, martingale, or recovery-sizing path.

The contract froze champion control, an unconditional body-`0.25` / `0.70%` reference, a `0.30%` drawdown center, and `0.15%` / `0.45%` threshold neighbors across 2015-2018, 2019-2020, and continuous 2015-2020. All `15/15` Model 1 reports parsed with exact source, EX5, config, and report identity. One stale first-launch report was refused and rerun unchanged, leaving 15 accepted reports from 16 attempts. Static safety and compilation passed with zero errors or warnings.

Every profile produced exactly the same result on a `$10,000` restart: `+$1,191.69`, `+11.92%` total, `+1.89% per year`, PF `1.77`, 265 trades, `1.02%` maximum drawdown, recovery `10.5778`, and return/drawdown `11.6863`. Even the unconditional higher-risk reference was inactive in these sealed eras. The differing requested-risk settings therefore did not change an executable trade, consistent with the existing broker lot step and reversion lot cap; this is an inference from the identical complete metrics, not a claim of a profitable throttle effect.

An inactive mechanism cannot establish growth, incremental-net retention, or neighbor support. The family was rejected without moving its threshold or opening 2021-2026 and Model 4. ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the high-water risk rejection](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_HIGH_WATER_RISK_DISCOVERY_DECISION.md), [the compact results](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_HIGH_WATER_RISK_DISCOVERY_MODEL1_SUMMARY.csv), and [the exact run attestation](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_HIGH_WATER_RISK_DISCOVERY_MODEL1_RUN_ATTESTATION.csv).

### Earlier Momentum Breakout-Failure Research

The momentum breakout-failure exit experiment completed on `2026-07-19`. This was a strategy-code change, not a risk increase or settings-only pass. The default-off feature stored each momentum entry's pre-break H1 channel and entry ATR, then closed only that exact owned position if one of the first completed H1 closes returned inside the channel by a frozen ATR buffer. Entries, initial stops, targets, requested risk, position limits, account protections, and the real-account lock remained unchanged. Static safety checks and compilation passed with zero errors or warnings.

The contract froze a disabled control, a 3-bar / `0.05`-ATR center, 2-bar and 4-bar timing neighbors, and `0.00` / `0.10`-ATR buffer neighbors across 2015-2018, 2019-2020, and continuous 2015-2020. All `18/18` Model 1 reports parsed with exact source, EX5, config, and report identity. Two stale first-launch reports were refused and rerun unchanged, leaving 18 accepted reports from 20 attempts.

On a `$10,000` restart, control earned `+$1,191.69`, or `+11.92%` total and `+1.89% per year`, at PF `1.77`, 265 trades, and `1.02%` maximum drawdown. The frozen center fell to `+$943.30`, or `+9.43%` total and `+1.51% per year`, at PF `1.74`, 261 trades, and `1.31%` drawdown. That is `-$248.39` (`-20.84%`) versus control. The best enabled neighbor, 2 bars / `0.05` ATR, reached only `+$1,003.40`, `+10.03%` total, and `+1.61% per year`, with worse `1.36%` drawdown. Every enabled profile cut recoverable momentum trades too early and earned less than control.

The family was rejected without changing timing or buffer after observation. The 2021-2026 holdout and Model 4 remained unopened, ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the momentum breakout-failure rejection](outputs/THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_DECISION.md), [the compact results](outputs/THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_SUMMARY.csv), and [the exact run attestation](outputs/THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_RUN_ATTESTATION.csv).

### Earlier Momentum Ridge-Quality Research

The momentum ridge-quality screen completed on `2026-07-19`. It joined 246 pre-2023 momentum entries carrying 11 already-logged, date-independent price-action, trend, volatility, volume, and stop-geometry features to the exact ATB150 Model 4 trade ledger. Before scoring, the contract froze a standardized ridge model with penalty `25.0`, chronological train/test folds ending in 2018, 2020, and 2022, a center that retained scores above the training 25th percentile, and fixed 20th/30th-percentile neighbors. The score could only suppress an existing momentum entry; it could not add trades or alter risk, stops, targets, or exits.

The lower 20th-percentile neighbor was the only complete pass, raising 2017-2022 portfolio net from `+$1,050.31` to `+$1,109.54` (`+5.64%`) and PF from `1.6487` to `1.8003`. The frozen 25th-percentile center reached only `+$1,056.29` (`+0.57%`) and incorrectly ranked its removed 2021-2022 momentum trades above the retained trades; its fold net fell `-$4.26` versus control. The 30th-percentile neighbor reached `+$1,087.85` (`+3.57%`) but failed the same ranking requirement. One isolated threshold is not a robust neighborhood, so the family was rejected without a different model, penalty, feature, percentile, or split search.

No MQL implementation was created, 2023-2026 remained unopened for this score, and no MT5 or Model 4 time was spent. ATB150 and the invalid forward registration remain unchanged.

[Read the momentum ridge-quality rejection](outputs/THREE_LANE_MOMENTUM_RIDGE_QUALITY_OFFLINE_DECISION.md), [the compact summary](outputs/THREE_LANE_MOMENTUM_RIDGE_QUALITY_OFFLINE_SUMMARY.csv), and [the frozen contract](outputs/THREE_LANE_MOMENTUM_RIDGE_QUALITY_OFFLINE_CONTRACT.md).

### Earlier Protected Winner Add-On Research

The protected reversion winner add-on experiment completed on `2026-07-19`. The new default-off code could add once to a profitable strong-signal reversion position only after locking the primary stop, proving broker-valued locked-profit coverage, retaining at least `1.20R` of reward, and passing account-wide exposure checks before and after the fill. It added no martingale, grid, averaging down, recovery sizing, or new close path; real-account trading remained disabled. Static and compiler audits passed with zero errors or warnings.

The frozen discovery contract tested a disabled control, trigger neighbors at `0.75R / 1.00R / 1.25R`, and add-on risk neighbors at `0.10% / 0.15% / 0.20%` across 2015-2018, 2019-2020, and continuous 2015-2020. All `18/18` Model 1 reports parsed from one exact source and EX5 after one unchanged identity retry. Control returned `+$1,191.69`, `+11.92%` total, `1.89%` CAGR, PF `1.77`, 265 trades, `1.02%` drawdown, recovery `10.5778`, and return/drawdown `11.6863`.

The center, `0.75R` trigger, and `0.20%` risk rows produced zero add-ons and exactly reproduced control. The active `1.25R` trigger row opened four continuous add-ons but fell to `+$1,088.37`, `1.74%` CAGR, PF `1.69`, and recovery `9.6607`. The active `0.10%` risk row opened five and fell further to `+$979.05`, `1.57%` CAGR, PF `1.64`, and recovery `8.6903`. The active variants materially weakened payoff, so the family was rejected without post-result retuning. The 2021-2026 holdout and Model 4 were not opened, ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the protected winner add-on rejection](outputs/THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_DECISION.md), [the compact results](outputs/THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_SUMMARY.csv), and [the exact run attestation](outputs/THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_RUN_ATTESTATION.csv).

### Earlier Session-Shaped Research

The strong-reversion / adaptive-trend session experiment completed on `2026-07-19`. Exact ATB150 trade attribution had suggested that adaptive-trend breakouts around the 16:00-00:00 server session were more productive, so a new data-informed contract froze a strong-reversion control plus `12-1`, `16-1`, and `16-9` adaptive-trend entry windows. Strong-reversion body/risk stayed at `0.25 / 0.70%`, adaptive-trend risk stayed at `0.15%`, tick protection stayed disabled, and no entry, stop, target, exit, exposure cap, or loss limit changed.

All `20/20` Model 1 reports parsed from one exact source and EX5 after one unchanged identity retry. The `16-1` center reduced continuous net from strong control at `+$2,391.89` to `+$2,344.44`, CAGR from `1.88%` to `1.84%`, and trades from 415 to 384; its 2015-2018 net fell from `+$860.86` to `+$799.29`. The `12-1` neighbor was weaker. The best `16-9` row reached `+$2,398.19`, PF `1.90`, and recovery `16.6057`, but added only `$6.30`, left CAGR unchanged at `1.88%`, and failed its frozen growth gate. The ledger-hour pattern did not transfer into a stable portfolio improvement. Model 4 did not open, no further hour search is permitted, and ATB150 remains unchanged.

[Read the ATB session rejection](outputs/THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_DECISION.md) and [the compact results](outputs/THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_SUMMARY.csv).

### Earlier Risk-Balance Research

The strong-reversion / adaptive-trend risk-balance experiment completed on `2026-07-19`. It changed no entry, stop, target, or exit rule: completed-H1 body ratio stayed at `0.25`, requested strong-reversion risk stayed at `0.70%`, the rejected tick-protection feature stayed disabled, and only adaptive-trend risk was varied. The audited source, exact EX5, `0.75%` account-wide open-risk cap, portfolio loss limits, and real-account lock remained unchanged.

The broad contract tested adaptive-trend risk `0.13% / 0.14% / 0.15%` beside a disabled-feature control. All `16/16` Model 1 reports parsed from one exact source and binary after one unchanged identity retry. The `0.14%` center improved continuous net from `+$2,195.53` to `+$2,367.32`, total return from `21.96%` to `23.67%`, CAGR from `1.74%` to `1.86%`, PF from `1.83` to `1.90`, and recovery from `15.8168` to `16.3919`, with `1.21%` drawdown. It nevertheless fell below control in 2015-2018 (`+$846.12` versus `+$860.86`). The `0.13%` lower neighbor also failed its older-era, recovery, return/drawdown, and 400-trade requirements, so the broad neighborhood was rejected.

A separately frozen narrow plateau then tested only `0.135% / 0.140% / 0.145%`. All `16/16` reports completed in `2m42s` with zero retries or errors. The `0.145%` upper neighbor was the strongest Model 1 row at `+$2,445.32`, `+24.45%` total, `1.92%` CAGR, PF `1.92`, 411 trades, `1.22%` drawdown, recovery `16.7110`, and return/drawdown `20.0410`; it beat control in every era. It is not promoted because the center again missed the older-era gate and the `0.135%` lower neighbor missed the older-era, drawdown, recovery, and return/drawdown gates. This is an isolated upper result rather than a stable plateau. Per the frozen contract, no Model 4 run or further adjacent ATB threshold search is allowed, ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the broad risk-balance rejection](outputs/THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_MODEL1_DECISION.md), [the narrow-plateau rejection](outputs/THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_PLATEAU_MODEL1_DECISION.md), and [the compact plateau results](outputs/THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_PLATEAU_MODEL1_SUMMARY.csv).

### Earlier Tick-Protection Research

The strong-reversion every-tick protection experiment and its separately frozen lock ladder completed on `2026-07-19`. The prior completed-H1 manager had been a proven no-op because strong trades often exited before the next H1 evaluation. The new default-off code moved only owned-position protection ahead of the new-bar guard, so it could evaluate executable bid/ask on every tick while entry eligibility remained completed-H1 only. It retained the body `0.25` / requested risk `0.70%` strong allocation, exact stored initial risk, initial stops, VWAP targets, both trend lanes, `0.75%` portfolio open-risk cap, portfolio loss limits, and real-account lock. Static and compiler audits confirmed zero new entry or close paths, exactly one tightening-only stop path, and zero warnings.

The first contract froze disabled control, strong-only control, and `1.00R / 0.05R`, `1.00R / 0.10R`, and `1.25R / 0.10R` protection rows. All `20/20` Model 1 reports parsed on one exact source and EX5 identity after one identity-only refusal was rerun unchanged. Strong-only returned `+$2,391.89`, `+23.92%` total, `1.88%` CAGR, PF `1.89`, 415 trades, `1.21%` drawdown, recovery `16.5620`, and return/drawdown `19.7686`. The `1.00R / 0.10R` center changed behavior and improved drawdown to `1.15%`, recovery to `17.1198`, and return/drawdown to `19.9130`, but net fell to `+$2,289.77`, CAGR to `1.80%`, and trades to 414. It produced only `+4.29%` more net than disabled control, below the frozen `+5%` floor, retained less than `97%` of strong-only net, and the `1.25R` neighbor failed independently. Model 4 did not open.

Because raising the lock from `0.05R` to `0.10R` had improved net in that fixed-trigger comparison, one final contract froze the trigger at `1.00R` and tested only `0.15R / 0.20R / 0.25R` locks beside fresh controls and the observed `0.10R` reference. All `24/24` reports parsed on the same exact source and EX5 after three unchanged identity retries. The `0.20R` center collapsed to `+$2,005.83`, `1.60%` CAGR, PF `1.80`, 412 trades, `1.30%` drawdown, recovery `13.7678`, and return/drawdown `15.4308`; both neighbors also underperformed disabled control. The non-monotonic path response rejects the retained-profit premise. This protection family is closed without another trigger or lock search, ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the every-tick protection rejection](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_TICK_PROTECTION_MODEL1_DECISION.md), [the higher-lock rejection](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_TICK_PROTECTION_LOCK_LADDER_MODEL1_DECISION.md), and [the compact first-stage results](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_TICK_PROTECTION_MODEL1_SUMMARY.csv).

The strong-reversion protection experiment completed on `2026-07-19`. It kept the already-studied completed-H1 body `0.25` / requested risk `0.70%` allocation and added one optional exact-ticket stop-modification path. Only a qualifying strong reversion position could register its initial risk, and its stop could only tighten after frozen favorable movement; entries, initial stops, VWAP targets, closes, both trend lanes, the `0.75%` open-risk cap, portfolio loss limits, and real-account lock remained unchanged. The source audit proved zero new entry or close paths and exactly one tightening-only modify path.

The contract froze disabled control, strong-only control, and protection rows `1.00R / 0.05R`, `1.00R / 0.10R`, and `1.25R / 0.10R` before testing. All `20/20` Model 1 reports parsed on one exact source and EX5 identity after two identity-only refusals were rerun unchanged and accepted. Strong-only returned `+$2,391.89`, `+23.92%` total, `1.88%` CAGR, PF `1.89`, 415 trades, `1.21%` drawdown, recovery `16.5620`, and return/drawdown `19.7686`.

Every protected row produced exactly the same trading metrics in every window. Report files had different hashes because MT5 embeds different input settings, but entry count, net, PF, win rate, drawdown, recovery, and consecutive-loss metrics were unchanged. The formal effect detector therefore returned `False`: at completed-H1 resolution, none of the frozen stop-lock rules changed a qualifying trade before its normal exit. An identical result is not treated as validation. Model 4 did not open, no trigger was lowered after observation, ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the strong-signal protection rejection](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_PROTECTION_MODEL1_DECISION.md), [the compact results](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_PROTECTION_MODEL1_SUMMARY.csv), and [the exact run attestation](outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_PROTECTION_MODEL1_RUN_ATTESTATION.csv).

The completed-H1 rejection-wick allocation experiment completed on `2026-07-19`. Exact ATB150 trade-ledger attribution showed why reversion deserved the next distinct code test: its 38 trades made `+$1,366.48` at PF `3.94`, with positive net in 2015-2018, 2019-2022, and 2023-2026, while the two trend lanes were much less efficient. The new default-off allocator could request `0.70%` reversion risk only when an already-valid completed-H1 reversal met both the frozen `0.25` directional-body ratio and a directional rejection-wick threshold. It changed no entry, stop, target, close, or modify path and preserved all portfolio limits and the real-account lock.

The contract froze a disabled-feature control plus `20% / 25% / 30%` wick thresholds before testing. All `16/16` Model 1 reports parsed on one exact source and EX5 identity after one identity-only refusal was rerun unchanged and accepted. Control returned `+$2,195.53`, `+21.96%` total, `1.74%` CAGR, PF `1.83`, 415 trades, `1.17%` drawdown, recovery `15.8168`, and return/drawdown `18.7692`. The `25%` center improved to `+$2,321.32`, `+23.21%` total, `1.83%` CAGR, PF `1.87`, the same 415 trades, `1.22%` drawdown, recovery `16.0734`, and return/drawdown `19.0246`. Every broad era remained positive and no worse than control.

The center nevertheless missed its frozen CAGR requirement by `0.01` point: the contract required at least `1.84%`, not `1.83%`. The `20%` lower neighbor simply reproduced the earlier body-only allocation at `+$2,391.89` and `1.88%` CAGR; the `25%` and `30%` rows collapsed to the same broker lot decisions and removed part of that improvement. The gate was not rounded or relaxed after observation. Model 4 did not open, ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the rejection-wick Model 1 decision](outputs/THREE_LANE_REVERSION_REJECTION_QUALITY_MODEL1_DECISION.md), [the compact results](outputs/THREE_LANE_REVERSION_REJECTION_QUALITY_MODEL1_SUMMARY.csv), and [the exact run attestation](outputs/THREE_LANE_REVERSION_REJECTION_QUALITY_MODEL1_RUN_ATTESTATION.csv).

The strong-reward quality allocation experiment completed on `2026-07-19`. It addressed a specific weakness in the earlier completed-H1 body feature: extra reversion risk had been allowed from candle body alone even when the setup barely cleared the existing `1.20` spread-adjusted reward/risk floor. The new default-off code requires both the frozen body ratio `0.25` and a separately frozen minimum adjusted reward/risk before requesting `0.70%` risk. It changes no entry, stop, target, close, or modify path; uses no future, current-bar, outcome, account-profit, or calendar data; and preserves the `0.75%` account open-risk cap, portfolio loss limits, minimum-lot refusal, and real-account lock.

All `20/20` Model 1 reports parsed on one exact source and EX5 identity after two identity-only refusals were rerun unchanged and accepted. The `1.50` center passed every preregistered Model 1 gate at `+$2,342.63`, `+23.43%` total, `1.84%` CAGR, PF `1.88`, 415 trades, `1.21%` drawdown, recovery `16.2210`, and return/drawdown `19.3636`; every broad era remained positive and both fixed neighbors supported it. That pass opened only the preregistered Model 4 comparison.

All `16/16` Model 4 real-tick reports then completed with zero errors and exact source/binary identity. Control reproduced at `+$2,105.08`, `+21.05%` total, `1.67%` CAGR, PF `1.81`, 404 trades, `1.15%` drawdown, recovery `15.6686`, and return/drawdown `18.3043`. The `1.50` center rose to `+$2,236.41`, `+22.36%` total, and `1.77%` CAGR, but drawdown rose to `1.24%`, recovery fell to `15.3347`, and return/drawdown fell to `18.0323`. The stronger `1.35` neighbor made `+$2,284.81` at `1.80%` CAGR and return/drawdown `18.5772`, but recovery missed control by `0.0020`. The frozen gates were not relaxed after observation. Annual, cost, and Monte Carlo expansion did not open, ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the Model 1 gate pass](outputs/THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL1_DECISION.md), [the Model 4 rejection](outputs/THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL4_DECISION.md), and [the compact real-tick results](outputs/THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL4_SUMMARY.csv).

The strict-body reversion real-tick plateau completed on `2026-07-19`. This was a preregistered follow-up to the already-audited strong-signal code branch, not a new optimizer sweep. It compared a fresh disabled-feature control with the previously defined completed-H1 body ratio `0.25` at requested risk `0.65%` and `0.675%`. Entries, stops, VWAP targets, exits, both trend lanes, the `0.75%` account open-risk cap, loss limits, and real-account lock remained unchanged.

All `12/12` Model 4 reports parsed with exact source and compiled-binary identity. Four local workers completed the batch in `18m23s` with zero report errors. Control reproduced at `+$2,105.08`, `1.67%` CAGR, PF `1.81`, `1.15%` drawdown, and recovery `15.6686`. Both risk rows collapsed to the same broker lot steps and returned `+$2,271.52`, `1.79%` CAGR, PF `1.87`, 404 trades, `1.23%` drawdown, and return/drawdown `18.4715`. They improved every broad-era net and exceeded the frozen growth floor, but recovery declined to `15.5754`; the center and adjacent plateau gate therefore failed. Annual, cost, and Monte Carlo expansion did not open, ATB150 remains the historical champion, and the invalid forward registration remains unchanged.

[Read the real-tick plateau rejection](outputs/THREE_LANE_REVERSION_STRICT_BODY_REAL_TICK_PLATEAU_DECISION.md) and [the compact three-profile results](outputs/THREE_LANE_REVERSION_STRICT_BODY_REAL_TICK_PLATEAU_SUMMARY.csv).

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

### Higher-APR Comparison

Continuous 2015-2026 figures use a sequential `$10,000` account path. V1 figures are Model 4 real ticks; V2 was stopped at Model 1 and is not directly promotable.

| Profile | Test model | Net | Total increase | CAGR | PF | Max DD | Recovery | Return/DD | Status |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| **Same-side exit cooldown 60** | **Model 4 real ticks** | **+$2,492.25** | **+24.92%** | **+1.95%/yr** | **1.93** | **1.18%** | **17.54** | **21.12** | **Provisional historical leader; all local gates pass** |
| Selective strong-signal lot cap 0.15 | Model 4 real ticks | +$2,428.50 | +24.28% | +1.90%/yr | 1.89 | 1.18% | 17.09 | 20.58 | Previous historical leader; retained as control |
| **ATB150** | Model 4 real ticks | **+$2,105.08** | **+21.05%** | **+1.67%/yr** | **1.81** | **1.15%** | **15.67** | **18.30** | **Released stable baseline** |
| Strong reversion 0.70% / ATB 0.145% | Model 1 only | +$2,445.32 | +24.45% | +1.92%/yr | 1.92 | 1.22% | 16.7110 | 20.04 | Rejected before Model 4; narrow plateau failed |
| Every-tick strong protection 1.00R / 0.10R | Model 1 only | +$2,289.77 | +22.90% | +1.80%/yr | 1.88 | 1.15% | 17.1198 | 19.91 | Rejected before Model 4; growth, retention, and neighbor gates failed |
| Rejection quality body 0.25 / wick 25% / risk 0.70% | Model 1 only | +$2,321.32 | +23.21% | +1.83%/yr | 1.87 | 1.22% | 16.0734 | 19.02 | Rejected before Model 4; CAGR gate missed by 0.01 point |
| Strong-reward quality RR 1.50 / risk 0.70% | Model 4 real ticks | +$2,236.41 | +22.36% | +1.77%/yr | 1.85 | 1.24% | 15.3347 | 18.03 | Rejected by frozen recovery, return/DD, and relative-DD gates |
| Strong-reversion body 0.25 / risk 0.65%-0.675% plateau | Model 4 real ticks | +$2,271.52 | +22.72% | +1.79%/yr | 1.87 | 1.23% | 15.5754 | 18.47 | Rejected by frozen recovery/neighbor gate |
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
