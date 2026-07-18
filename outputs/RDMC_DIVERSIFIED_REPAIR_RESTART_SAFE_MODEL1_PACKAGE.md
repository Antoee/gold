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
- A lightweight per-tick emergency path issues close requests for both magic families on the 5% lifetime equity-drawdown limit or a missing/invalid protective stop.
- The emergency path performs no trade-history scan, sleep, or retry loop; ordinary trailing, channel exits, and full period-risk calculations remain new-bar work.
- All four entries require a completed broker retcode and a nonzero deal ticket; a locally valid or merely placed request is not logged as an entry.
- Full closes, partial closes, and SL/TP modifications verify both the broker retcode and resulting position state before success logs or state markers are written.
- Both trade executors are explicitly synchronous and use the symbol-native filling policy; successful entry logs use broker-confirmed deal, volume, and price fields.
- Any active account order blocks new exposure, preventing a merely placed market request from being duplicated before it resolves.
- Emergency, period-risk, weekend, session-end, and manual-news flattening cancel research-owned orders with verified broker results before closing positions.
- Foreign orders are never canceled by the EA and instead fail the dedicated-account contract closed.

## Frozen identity

- Source SHA-256: `21CC9D6242594E285BA8E8D1BA8158AA5A0E66C3E5A5985CC201A87D218E1FEF`
- Profile SHA-256: `161C54EDB76FDF3468CB600E1E49788D794635E0D3573B359A59389199A3B73C`
- Predecessor source SHA-256: `4740338598E290360946FE414CC6F2FE0CF3B704006860514367DCB996A8D2B5`
- Source/profile inputs: `588 / 588`
- Queue: `outputs/RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_QUEUE.csv`

## Hard boundary

The source is tester-only, real-account trading is disabled, and all 12 annual/YTD Model1 rows remain `LOCKED_LOCAL_LAUNCH_DISABLED`. The new cost, margin, hard-cooldown, intrabar emergency, broker-result, and active-order reconciliation can change entries and exits, so the earlier post-hoc collision score is not attributed to this executable path. Static checks cannot prove compilation, profit, drawdown, or restart behavior inside MT5. Compilation, annual and continuous Model1, annual and continuous real-tick Model4, cost stress, Monte Carlo, broker variation, and valid forward evidence are still required.
