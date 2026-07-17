# Low-Activity Diversifier Holdout Contract

Frozen on 2026-07-17 before any selected profile was run on post-2020 data.

## Purpose

Three independent M15 profiles were rejected as standalone candidates because their otherwise coherent pre-2021 neighborhoods did not meet activity floors. This test asks a different question: can any unchanged low-activity profile contribute a positive, low-overlap return stream to the released portfolio?

This is explicitly a holdout-informed diversification study. A passing result may permit trade-level portfolio analysis; it cannot retroactively make the standalone strategy eligible or constitute pristine out-of-sample evidence.

## Frozen profiles

- `fbt_b16_fixed_r200`: 16-bar failed-breakout trap, `0.10%` risk.
- `m15sq_break8`: volatility-squeeze continuation with an 8-bar breakout, `0.10%` risk.
- `m15vcr_vol130`: volume-climax VWAP reversal with 1.30x volume threshold, `0.10%` risk.

Source and signal parameters are unchanged from their published pre-2021 decisions. Only the evidence run label is updated. Real-account trading remains disabled.

## Holdout windows

- 2021-01-01 through 2022-12-31.
- 2023-01-01 through 2026-07-16.
- Continuous 2021-01-01 through 2026-07-16.
- Model 1, `$10,000` starting deposit.

## Frozen lane gate

Every condition is required before trade extraction or portfolio analysis:

- Positive net profit in both disjoint holdout eras.
- Positive continuous holdout net profit.
- Continuous holdout profit factor at least `1.15`.
- At least `35` continuous holdout trades.
- Continuous holdout maximum relative equity drawdown no more than `2.00%`.
- The profile's original pre-2021 evidence remains positive in both disjoint eras.

Any losing broad window rejects the profile. If no profile passes, no correlation screen, portfolio allocation, Model 4 run, or implementation is permitted.

## Safety invariants

- Requested risk remains `0.10%` per trade.
- Broker-native `OrderCalcProfit` sizing and minimum-lot refusal remain unchanged.
- Account-wide exposure, daily-loss, drawdown, spread, cooldown, and real-account locks remain enabled.
- No martingale, grid, averaging down, or recovery sizing.
