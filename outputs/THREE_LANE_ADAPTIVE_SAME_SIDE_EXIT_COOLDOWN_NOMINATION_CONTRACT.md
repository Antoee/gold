# Adaptive Same-Side Exit Cooldown Nomination Contract

**Status: PREREGISTERED LEDGER VALIDATION. NO EA CODE, NEW BEST, FORWARD CHANGE, OR LIVE APPROVAL EXISTS.**

- Exact leader Model 4 ledger SHA-256: `6D880F634BD792281DAB72C5ACC6BF9F2C617888184881BD9AFA2D84DCEFAC40`
- Frozen analyzer SHA-256: `83C5A5EC6E103E3CA37FA82F4A99ED4819F0C1B3E3C22E0DA06D3B45F86A2C72`
- 2015-2018 training CSV SHA-256: `203EA7C1FA219E21E813BF422CE5FE81159F21FF88835C733437F54585CF068B`
- 2015-2018 training Markdown SHA-256: `15D4B0079A54AE73AD192894FD586FC71206139B38B9CDDFEF03F33B57B4593A`

## Causal Rule

Suppress only a new adaptive-trend entry when the most recent adaptive-trend exit on the same symbol and position side occurred within the fixed elapsed-time cooldown. The rule may use symbol, adaptive magic, side, exit time, and elapsed time. It may not read the prior trade's profit, loss, exit reason, drawdown, loss streak, or account outcome state.

The market hypothesis is H4 channel whipsaw: a same-side adaptive breakout shortly after that lane has already exited may be a repeated attempt inside an unresolved range. Existing entries, stops, targets, requested risk, lot caps, momentum cooldown, account-wide `0.75%` open-risk cap, loss limits, and the real-account lock must remain unchanged.

## Frozen Nomination

- Center: `72 hours` (`4,320 minutes`).
- Sensitivity rows: `48`, `96`, and `120 hours`.
- Training window used for selection: `2015-2018` only.
- Training center: `4` affected adaptive entries, `-$26.57`, PF `0.00`.
- Training support: 48 hours `-$24.19`; 96 and 120 hours each `-$26.57`. Every fixed row had PF `0.00`.

## One-Shot Validation Gate

Run the byte-identical analyzer on `2019-2020` once. The center must affect at least two trades, have negative affected net of at least `-$10.00`, and have affected PF below `1.00`. At least two of the three fixed sensitivity rows must also have negative affected net and PF below `1.00`. The offline center projection must improve the 2019-2020 portfolio by at least `$10.00`.

Failure closes this interaction without EA code or MT5 runs. Passing validation permits one default-off source fork and a separately frozen 2015-2020 Model 1 executable gate; it does not permit post-2020 testing, Model 4, promotion, forward substitution, or real trading.

No threshold may replace the 72-hour center after validation. No martingale, grid, averaging down, recovery sizing, capital change, or real-account trading is permitted.
