# Adaptive-Exit to Momentum Same-Side Cooldown Nomination Contract

**Status: PREREGISTERED LEDGER VALIDATION. NO EA CODE, NEW BEST, FORWARD CHANGE, OR LIVE APPROVAL EXISTS.**

- Exact leader Model 4 ledger SHA-256: `6D880F634BD792281DAB72C5ACC6BF9F2C617888184881BD9AFA2D84DCEFAC40`
- Frozen analyzer SHA-256: `04430AD6B156EEA06D893F7B53A192F68D76511E90D4CF392FB76B826B5B7953`
- 2015-2018 training CSV SHA-256: `53C16E97C6C35136515871916428118B6D67EE7F054C11E42860B2FBF811054E`
- 2015-2018 training Markdown SHA-256: `ECBA7E7532D26C9B708D617FBDA415DBBBF5B9A302EF156A00E64ADFCF116195`

## Causal Rule

Suppress only a new momentum-lane entry when the most recent adaptive-lane exit on the same symbol and position side occurred within the fixed elapsed-time cooldown. The rule may use symbol, lane magic, side, exit time, and elapsed time. It may not read the prior trade's profit, loss, exit reason, drawdown, loss streak, or account outcome state.

The market hypothesis is exhaustion: the slower H4 adaptive lane has already exited a directional move, so a same-side H1 breakout shortly afterward may be a late continuation attempt. Existing entries, initial stops, targets, requested risk, lot caps, the independent momentum same-side cooldown, account-wide `0.75%` open-risk cap, loss limits, and the real-account lock must remain unchanged.

## Frozen Nomination

- Center: `36 hours` (`2,160 minutes`).
- Sensitivity rows: `24`, `48`, and `72 hours`.
- Training window used for selection: `2015-2018` only.
- Training center: `4` affected momentum entries, `-$24.53`, PF `0.00`.
- Training support: 24 hours `-$24.53`, 48 hours `-$2.58`, and 72 hours `-$18.50`.

## One-Shot Validation Gate

Run the byte-identical analyzer on `2019-2020` once. The center must affect at least two trades, have negative affected net of at least `-$10.00`, and have affected PF below `1.00`. At least two of the three fixed sensitivity rows must also have negative affected net and PF below `1.00`. The offline center projection must improve the 2019-2020 portfolio by at least `$10.00`.

Failure closes this interaction without EA code or MT5 runs. Passing validation permits one default-off source fork and a separately frozen 2015-2020 Model 1 executable gate; it does not permit post-2020 testing, Model 4, promotion, forward substitution, or real trading.

No threshold may replace the 36-hour center after validation. No martingale, grid, averaging down, recovery sizing, capital change, or real-account trading is permitted.
