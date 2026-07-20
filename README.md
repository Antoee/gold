# Professional XAUUSD EA

Risk-first MetaTrader 5 research for XAUUSD. No martingale, grid, averaging down, or recovery sizing.

## Current Verdict

| Lane | Status |
|---|---|
| Highest verified historical result | **Strong-Signal Selective Reversion Lot Cap, provisional research leader.** Model 4 real ticks: `+$2,428.50`, `+24.28%`, `1.90%/yr` CAGR, PF `1.89`, `1.18%` drawdown. |
| Released stable baseline | **Three-Lane Trade-Ready RC2 ATB150**, `+$2,105.08`, `+21.05%`, `1.67%/yr` CAGR, PF `1.81`, `1.15%` drawdown. |
| Latest research result | **High-reward strong-signal lot cap rejected in sealed discovery.** Its RR-`2.50` center improved 2015-2020 Model 1 net by only `$26.94`, missed the frozen growth and CAGR gates, and received no support from the four-neighbor growth gate. No recent-data or Model 4 budget was spent. |
| Registered forward candidate | Operational Hardening v0.2-rc2, unchanged |
| Valid forward evidence | **None**. The attached $100,000 demo violates the frozen $10,000 contract and counts as zero days/trades. |
| Real-money approval | **No. Real-account trading remains disabled.** |

The selective candidate raises only the lot ceiling for already-valid reversion signals whose completed H1 candle body is at least `0.25` of its range. Requested reversion risk remains `0.45%`; maximum portfolio open risk remains `0.75%`; all entries, stops, exits, loss limits, and real-account protections remain unchanged. The higher ceiling lets those strong signals size closer to their existing risk budget without martingale, grid, averaging down, or recovery sizing.

## Highest Historical Result

Continuous MT5 Model 4 real ticks, XAUUSD, `$10,000` restart, `2015-01-01` through `2026-07-18`:

| Metric | Result |
|---|---:|
| Net profit | **+$2,428.50** |
| Ending balance | **$12,428.50** |
| Total increase | **+24.28%** |
| CAGR | **+1.90% per year** |
| Profit factor | **1.89** |
| Trades | **404** |
| Win rate | **44.31%** |
| Maximum equity drawdown | **1.18%** |
| Recovery factor | **17.09** |
| Return / drawdown | **20.58** |

Against ATB150, the candidate adds `$323.42` (`+15.36%` more net profit), `+3.23` total-return points, and `+0.23` CAGR points per year. PF improves from `1.81` to `1.89`, recovery from `15.67` to `17.09`, and return/drawdown from `18.30` to `20.58`; drawdown rises only `0.03` point. These are historical measurements, not a forecast.

## Latest Research Update

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
| **Selective strong-signal lot cap 0.15** | **Model 4 real ticks** | **+$2,428.50** | **+24.28%** | **+1.90%/yr** | **1.89** | **1.18%** | **17.09** | **20.58** | **Provisional historical leader; local gates pass** |
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
