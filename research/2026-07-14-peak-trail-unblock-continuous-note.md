# 2026-07-14 Peak-Trail Unblock Continuous Note

The DGF loss-block restart-window scores looked promising, but continuous 2019-2026 Model4 testing exposed an account-state issue: the original global equity profit peak trail can freeze the profile after a small early peak/giveback sequence.

## Key Evidence

- Original high-profit loss-block, peak trail on: `-$7.36`, `3` trades.
- Original stability loss-block, peak trail on: `+$0.68`, `3` trades.
- Stability, peak trail off or loosened: `-$199.80`, PF `0.73`, `37.22%` max equity DD.
- High-profit, peak trail off: `+$1,915.83`, PF `1.72`, `127` trades, `24.58%` max equity DD.
- High-profit, peak trail `8%` trigger / `50%` giveback: `+$108.48`, PF `1.22`, `32` trades, `19.90%` max equity DD.

## Decision

Keep `lossblock_highprofit_peaktrail_off` as a high-profit continuous-account research lead only. Do not call it stable or money-ready. The drawdown is too high, and the next work should reduce risk without reintroducing a permanent account freeze.

Primary artifact: `outputs/PEAK_TRAIL_UNBLOCK_CONTINUOUS_MODEL4_DECISION.md`.
