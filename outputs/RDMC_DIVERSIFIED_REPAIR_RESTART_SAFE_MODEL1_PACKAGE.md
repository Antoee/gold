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
- Entry, margin-cap, and partial-close volumes are rounded down with the broker-provided `SYMBOL_VOLUME_STEP`; precision is derived from the step instead of being hardcoded to two decimals.
- Live account-history validation is invalidated by deal and generic trade events, with a fixed 60-second watchdog for missed or delayed events. Active positions and orders remain uncached and are checked on every entry evaluation.
- Initialization requires `ACCOUNT_MARGIN_MODE_RETAIL_HEDGING` before capital registration, indicator allocation, or executor setup. Netting, exchange, and unknown accounting modes fail closed because ticket ownership and partial-close behavior depend on hedging semantics.
- Every new entry requires live terminal, EA, and account trading permission plus a compatible symbol direction with market-order and protective-stop support.
- Entry-permission checks stay inside shared exposure approval, so permission loss blocks new exposure without removing the protective management and close paths.
- Both trade executors run MT5 `OrderCheck` on the exact side, volume, price, SL, TP, deviation, filling policy, magic, and comment before any Buy/Sell request.
- A failed broker preflight blocks the send and preserves the check retcode and broker comment in failure evidence; protective close paths do not depend on entry preflight.
- After a successful send, the exact broker result order or deal-linked immutable position identifier is reconciled to one unique expert-owned position; newest-position guessing is not used.
- The broker-attached open price, volume, stop loss, and requested take-profit state are verified before an entry is accepted or its initial risk is registered.
- Planned cash risk is compared with actual fill-to-stop cash risk. Actual risk may exceed planned risk by at most `5%`, and can never exceed the tighter per-entry or account-wide cash-risk cap.
- Reconciliation failures mark and force-close the exact filled ticket through the verified close wrapper. The marker is scoped to account, EA magic, and ticket; a failed emergency close remains marked for lightweight per-tick retry until the position is confirmed gone.
- Initial-risk state is stored against the exact filled position ticket using its actual fill-to-stop distance for every entry lane.

## Frozen identity

- Source SHA-256: `8420E5D3393133674035C0001FA3B0BAF6F543D2A14472BA2CDEF63199C21BB3`
- Profile SHA-256: `9344CACABBA0E5B86C0B0C5BCA2EDC3F2D9C095618B75AB6A58A5657D40D1E25`
- Predecessor source SHA-256: `4740338598E290360946FE414CC6F2FE0CF3B704006860514367DCB996A8D2B5`
- Source/profile inputs: `589 / 589`
- Queue: `outputs/RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_QUEUE.csv`

## Hard boundary

The source is tester-only, real-account trading is disabled, and all 12 annual/YTD Model1 rows remain `LOCKED_LOCAL_LAUNCH_DISABLED`. The new cost, margin, hard-cooldown, intrabar emergency, and broker-result safeguards can change entries and exits. The active-order reconciliation can change entries and exits. Broker-volume reconciliation can change entries and exits. Post-fill risk reconciliation can change entries and exits too, so the earlier post-hoc collision score is not attributed to this executable path. Static checks cannot prove compilation, profit, drawdown, or restart behavior inside MT5. Compilation, annual and continuous Model1, annual and continuous real-tick Model4, cost stress, Monte Carlo, broker variation, and valid forward evidence are still required.
