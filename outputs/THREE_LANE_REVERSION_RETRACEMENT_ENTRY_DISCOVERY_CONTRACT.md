# Three-Lane Reversion Retracement-Entry Discovery Contract

**Status: FROZEN BEFORE SOURCE CREATION, COMPILATION, OR TEST RESULTS. RESEARCH ONLY.**

## Evidence And Hypothesis

The exact current leader's H1 Band/VWAP reversion lane produced only 38 continuous
Model 4 trades, but contributed `+$1,671.93` at a lane PF near `4`. Most of its
eligible strong signals reached the broker lot ceiling, so adding weak entries or
raising requested risk has repeatedly failed to improve the portfolio efficiently.

The new hypothesis changes execution timing, not signal selection. After the exact
completed-H1 reversion signal qualifies, the EA may arm a short-lived entry below
the original buy quote or above the original sell quote. A small adverse retracement
toward the already-frozen structural stop should improve entry price, adjusted RR,
and broker lot-step utilization. Signals that do not retrace are deliberately missed.

No historical period is claimed as pristine out-of-sample data because the current
leader and reversion mechanism were selected using broad 2015-2026 research.

## Frozen Mechanism

- Fork the exact same-side momentum exit-cooldown leader.
- Add one default-off reversion retracement-entry switch, one non-negative ATR
  offset, and one positive H1-bar lifetime.
- Preserve the exact completed-H1 Band/VWAP signal, RSI/ADX/DI/D1 gates, structural
  stop anchor, signal-time VWAP target, requested risk, selective lot cap, other
  lanes, same-side momentum cooldown, account contracts, and loss limits.
- When enabled, an accepted setup arms an in-memory trigger instead of submitting
  an order. It creates no pending broker order and reserves no account risk.
- A buy may trigger only when executable ask is at or below the armed price; a sell
  may trigger only when executable bid is at or above it.
- Cancel before entry when the stop or target is touched, the lifetime expires, an
  owned reversion position exists, or the trigger-time safety checks fail.
- At trigger time rerun shared/lane loss limits, position and spacing limits, spread
  limits, broker-valued sizing, account-wide open-risk protection, stop/target
  geometry, and spread-adjusted minimum RR using the executable quote.
- A terminal restart may conservatively discard an unfilled armed setup. No risk or
  position exists before fill, so no state is silently reconstructed.
- No added close or stop-modification path; no martingale, grid, averaging down,
  recovery sizing, outcome conditioning, calendar exception, funding change,
  forward-candidate substitution, or real-account trading.

## Frozen Model 1 Discovery Ladder

| Profile | Feature | Offset | Lifetime | Role |
|---|---|---:|---:|---|
| `rre_control` | off | `0.00 ATR` | `1 bar` | exact leader control |
| `rre_offset10` | on | `0.10 ATR` | `1 bar` | lower offset support |
| `rre_center15` | on | `0.15 ATR` | `1 bar` | frozen center |
| `rre_offset20` | on | `0.20 ATR` | `1 bar` | upper offset support |
| `rre_center15_bars2` | on | `0.15 ATR` | `2 bars` | lifetime robustness |

Each profile is tested on disjoint `2015-2018` and `2019-2020` eras plus continuous
`2015-2020` Model 1 data on a `$10,000` restart. Post-2020 data remains closed unless
the frozen center passes discovery.

## Frozen Discovery Gate

1. All `15/15` reports must match one exact source and EX5 identity, return complete
   metrics, and have zero tester or runner errors.
2. The disabled control must exactly reproduce the current leader's frozen Model 1
   control on all three windows.
3. Every enabled profile must remain profitable in both disjoint eras.
4. The center must be no worse than control net in each disjoint era.
5. Center continuous net must improve by at least `3%`, and CAGR must improve by at
   least `0.05` percentage points.
6. Center PF, recovery, and return/drawdown must each retain at least `97%` of
   control; drawdown may be at most control plus `0.10` percentage points; trades
   must retain at least `97%` of control.
7. The center must change executable behavior. At least one reversion fill must use
   the armed-entry comment, and enabled/control trades or net must differ.
8. Both adjacent offsets must improve continuous net, remain no worse than control
   in each era, retain at least `95%` of control PF/recovery/return-drawdown, keep
   drawdown within control plus `0.12` points, and retain at least `96%` of trades.
9. The two-bar lifetime row must remain profitable in both eras and retain at least
   `90%` of the center's net, PF, recovery, and return/drawdown without adding more
   than `0.12` drawdown points.
10. Any losing era, inactive center, identity mismatch, weak center, unsupported
    offset neighborhood, or failed lifetime check rejects the family before recent
    or Model 4 testing. Gates are not relaxed after observation.

## Conditional Validation

Only a complete discovery pass may open exact control/center/adjacent confirmation
on `2021-2023`, `2024-2026 YTD`, and continuous `2021-2026 YTD` Model 1 data. Every
candidate must remain profitable in both eras; the center must beat control in
continuous net while retaining control PF/recovery/return-drawdown, staying within
`0.10` drawdown points, and retaining at least `96%` of trades.

Only a complete recent confirmation may open Model 4 real ticks on `2015-2018`,
`2019-2022`, `2023-2026 YTD`, and continuous `2015-2026 YTD`. Promotion requires no
red broad era, higher continuous net and CAGR, at least `97%` control PF/recovery/
return-drawdown, no more than `0.10` added drawdown points, at least `96%` of control
trades, and adjacent support. Annual restarts, cost stress, Monte Carlo, hard-risk,
and second-broker evidence remain mandatory after any Model 4 pass.

The frozen forward candidate, its source/profile/binary identity, evidence logs,
invalid `$100,000` account boundary, and real-account lock remain unchanged.
