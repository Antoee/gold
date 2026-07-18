# RDMC Diversified Repair Restart-Safe Model1 Package

Status: **STATIC ONLY / LOCKED / NOT PROMOTED**

This package supersedes the uncompiled v1 package before its first MT5 run. It preserves the four-lane strategy and risk settings but repairs account restart behavior. It does not establish a new best or change the registered forward candidate.

## Repair

- First non-tester registration still requires an unused, flat account at the frozen `$10,000 USD` starting balance.
- The starting-capital, funding-count, and peak-equity contracts persist under account-and-magic-scoped terminal global variables.
- Restarts after ordinary profit or loss retain the original `$10,000` baseline and lifetime peak equity instead of comparing current balance with the starting deposit.
- Deposits, withdrawals, credits, corrections, bonuses, foreign trade history, foreign open positions, missing persistence, and invalid stored peaks fail closed.
- Broker commission, charge, and interest deal types are not misclassified as new funding.
- Runtime history is refreshed before either momentum or primary entry evaluation. Position management and protective exits remain available.
- All four order-opening sites now require broker-native lot sizing, account-wide exposure approval, trading-cost approval, margin approval, explicit magic, and bounded deviation before Buy/Sell.
- The momentum lane now uses the same trading-cost and margin guards as the other three lanes.
- Isolated lanes may bypass adaptive strategy pauses, but the hard portfolio consecutive-loss and four-hour post-loss cooldown gates can no longer be bypassed.

## Frozen identity

- Source SHA-256: `7884B0890C0BAF0053DC2ED122C8F1AD9BD139017ED67FEEED2BB4B5CD499F5D`
- Profile SHA-256: `36B13286D026B5D8C365F197416E2A4D4FFF8B99AA56F78752988B875952965D`
- Predecessor source SHA-256: `4740338598E290360946FE414CC6F2FE0CF3B704006860514367DCB996A8D2B5`
- Source/profile inputs: `588 / 588`
- Queue: `outputs/RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_QUEUE.csv`

## Hard boundary

The source is tester-only, real-account trading is disabled, and all 12 annual/YTD Model1 rows remain `LOCKED_LOCAL_LAUNCH_DISABLED`. The new cost, margin, and hard-cooldown enforcement can reject historical entries, so the earlier post-hoc collision score is not attributed to this executable path. Static checks cannot prove compilation, profit, drawdown, or restart behavior inside MT5. Compilation, annual and continuous Model1, annual and continuous real-tick Model4, cost stress, Monte Carlo, broker variation, and valid forward evidence are still required.
