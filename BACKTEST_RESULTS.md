# Backtest Results

EA: `Professional_XAUUSD_EA`

Symbol/timeframe: `XAUUSD`, `M15`

Main validation period: `2024.01.01` to `2026.07.02`

Deposit: `$1,000`

Leverage: `1:100`

## Current Promoted Robust No-Date Results

The promoted default is the no-date BOS + liquidity-sweep profile at `1.60%` risk with a `1.80` ATR stop and `3.50` ATR take-profit:

- `InpRiskPercent=1.60`
- `InpStopATRMultiplier=1.80`
- `InpTakeProfitATRMultiplier=3.50`
- `InpMinRiskReward=1.50`
- `InpUseDateBuyBlock=false`
- `InpUseDateBuyBlock2=false`
- `InpUseDateSellBlock=false`
- `InpUseEMACrossEntry=false`
- `InpUseMomentumCandle=false`
- `InpUseEngulfing=false`
- `InpUseBOS=true`
- `InpUseLiquiditySweep=true`
- `InpMinimumConfirmations=2`

Full real-tick period `2024.01.01` to `2026.07.02`:

- Final balance: `$1,866.59`
- Net profit: `+$866.59`

Yearly windows:

- `2024`: `+$483.59`
- `2025`: `+$260.44`
- `2026 YTD`: `$0.00`

Half-year windows:

- `2024 H1`: `$0.00`
- `2024 H2`: `+$483.59`
- `2025 H1`: `$0.00`
- `2025 H2`: `+$260.44`
- `2026 H1`: `$0.00`

Quarterly windows:

- Quarterly total: `+$744.03`
- Worst quarter: `$0.00`
- Profitable quarters: `2`
- Flat quarters: `8`
- Losing quarters: `0`

Monthly windows:

- Monthly total: `+$744.03`
- Worst month: `$0.00`
- Profitable months: `2`
- Flat months: `28`
- Losing months: `0`

Split-window aggregate:

- Total across yearly/half/full windows: `+$2,354.65`
- Worst split window: `$0.00`
- Best split window: `+$866.59`
- Profitable split windows: `5`
- Flat split windows: `4`
- Losing split windows: `0`

Conclusion: increasing risk from `1.50%` to `1.60%` improved full-period profit from `+$521.12` to `+$866.59`, improved monthly/quarter aggregate from `+$540.51` to `+$744.03`, and improved the tested worst monthly/quarter/split window from `-$148.99` to `$0.00`.

## Latest Risk16 Neighborhood Stress Sweep

These are stress-window probes only. They are queued for full validation and are not promoted yet.

Top candidates:

- `risk160_sl18_tp38`: 7 stress windows, total `+$798.00`, worst `$0.00`, best `+$526.51`, 2 profitable, 5 flat, 0 losing.
- `risk160_sl16_tp38`: 7 stress windows, total `+$798.00`, worst `$0.00`, best `+$526.51`, 2 profitable, 5 flat, 0 losing.
- `risk170_sl18_tp35`: 7 stress windows, total `+$785.49`, worst `$0.00`, best `+$509.73`, 2 profitable, 5 flat, 0 losing.
- `risk165_sl18_tp35`: 7 stress windows, total `+$757.10`, worst `$0.00`, best `+$496.66`, 2 profitable, 5 flat, 0 losing.
- Current promoted baseline `risk160_sl18_tp35`: 7 stress windows, total `+$744.03`, worst `$0.00`, best `+$483.59`, 2 profitable, 5 flat, 0 losing.

Decision: queue the two `TP 3.80` candidates for full monthly, quarterly, yearly, half-year, and full-period validation. Do not promote them based on stress-window improvement alone.

## Promotion Gate Status

The offline promotion gate requires full, split, quarterly, and monthly evidence before a profile can replace the promoted default. Each set must be profitable, have no losing windows, and have a worst window of at least `$0.00`.

Current gate result:

- `promoted_risk160_sl18_tp35`: `PASS`, 4/4 evidence sets, worst observed window `$0.00`.
- `risk160_sl18_tp38`: `MISSING_EVIDENCE`, missing full/split/quarter/month validation.
- `risk160_sl16_tp38`: `MISSING_EVIDENCE`, missing full/split/quarter/month validation.
- `risk160_sl18_tp35_giveback`: `MISSING_EVIDENCE`, missing full/split/quarter/month validation.

Use `work/analyze_promotion_gate.ps1` after every validation run and do not promote any candidate that fails this gate.

## Optimization Fitness Update

The local EA source now includes an `OnTester()` custom optimization score so future MT5 optimization can rank robust candidates instead of sorting only by raw net profit.

Default scoring mode:

- `InpTesterFitnessMode=FITNESS_ROBUST_PROFIT`
- Rewards net profit and profit factor.
- Penalizes results below `InpTesterMinTrades`.
- Penalizes results below `InpTesterMinProfitFactor`.
- Penalizes equity drawdown above `InpTesterMaxDrawdownPercent`.

Alternate modes:

- `FITNESS_NET_PROFIT`: raw net profit for benchmark comparisons.
- `FITNESS_RECOVERY_SHARPE`: net profit weighted by recovery factor and Sharpe ratio, then penalized by the same robustness gates.

No new MT5 test was run for this change because local terminal launches are currently blocked to avoid desktop focus issues.

## Aggressive Date-Block Benchmark

Previous aggressive date-block validation:

- Full period net profit: `+$4,153.12`
- Quarterly total: `+$1,661.98`
- Monthly total: `+$1,903.98`
- Monthly losing windows: `17` out of `30`
- Worst quarter: `-$206.77`
- Worst month: `-$83.61`

Conclusion: the date-block profile remains the highest-profit historical benchmark, but it is not the promoted default because it relies on hard-coded date filters and has poor monthly start-window robustness.

## Other Research

- BOS+sweep at `1.50%` risk with `1.80` stop ATR: full period `+$521.12`, monthly `+$540.51`, 1 losing month; previous default.
- BOS+sweep at `1.50%` risk with `2.20` stop ATR: full period `+$452.75`, monthly `+$487.46`, 1 losing month; older default.
- BOS+sweep at `2.00%` risk: full period `+$321.72`, zero losing monthly/quarterly/split windows; safer but lower profit than `1.60%`.
- Momentum+sweep no-date profile: full period `+$664.59`, but still had 17 losing months, so it was not promoted.
- BOS/sweep variants with `MinimumConfirmations=1`, BOS-only, or sweep-only made more in stress windows but brought back larger losses.
- No-trail reduced the worst quarter but cut total quarterly net too much.
- Monthly ADX filters reduced profit without improving losing-month count.

## Local MT5 Safety Note

No new local MT5 validation should run while normal PC use is the priority. Local MT5 launch is gated behind both `ALLOW_MT5_FOCUS_RISK=1` and `work/ALLOW_MT5_LOCAL_LAUNCH.unlock` because `terminal64.exe` can still flash and steal focus on this machine.

The local runner has been patched to attempt a separate hidden Windows desktop launch, but that must be verified in a controlled test before unattended local validation resumes.

## Next Target

Increase profit from the robust BOS+sweep profile without bringing back losing monthly windows.

1. Validate `risk160_sl18_tp38`, `risk160_sl16_tp38`, and `risk160_sl18_tp35_giveback` across monthly, quarterly, yearly, half-year, and full-period windows.
2. Keep local MT5 tests blocked until the hidden-desktop runner has been deliberately verified.
3. Add drawdown/profit-factor extraction from reports, not only final balance.
