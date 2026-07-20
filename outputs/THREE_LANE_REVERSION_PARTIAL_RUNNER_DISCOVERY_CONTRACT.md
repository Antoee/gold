# Three-Lane Reversion Partial Runner Discovery Contract

**Status: FROZEN BEFORE COMPILATION OR RESULTS. RESEARCH ONLY.**

## Mechanism

- Keep every entry signal, initial stop, requested risk, lot cap, session, portfolio guard, and account lock unchanged.
- Apply the runner only to completed-bar reversion signals whose body ratio meets the existing `0.25` strong-signal threshold and whose broker-normalized volume can leave both a valid partial close and a valid remainder.
- Replace the original VWAP take-profit with a farther fixed target. When executable bid/ask first reaches the original VWAP target, tighten the full position to a profitable stop before closing the configured fraction.
- Persist original risk, trigger, filled volume, and completion state in terminal globals so a restart cannot repeat the partial close.
- If the profitable stop cannot be confirmed, close the full position. If state cannot be confirmed after a partial close, close the protected remainder.
- Keep the feature disabled by default. No martingale, grid, averaging, recovery sizing, added entry, or increased initial risk is allowed.

## Frozen Model 1 Matrix

| Profile | Close | Extended target | Stop lock |
|---|---:|---:|---:|
| Control | off | original VWAP | unchanged |
| Center | 80% | 2.00x original distance | +0.50R |
| Close neighbor low | 75% | 2.00x | +0.50R |
| Close neighbor high | 85% | 2.00x | +0.50R |
| Target neighbor low | 80% | 1.75x | +0.50R |
| Target neighbor high | 80% | 2.25x | +0.50R |
| Lock neighbor low | 80% | 2.00x | +0.25R |
| Lock neighbor high | 80% | 2.00x | +0.75R |

Each row is tested on disjoint 2015-2018 and 2019-2020 eras plus continuous 2015-2020 data. The 2021-2026 period is not opened unless the preregistered discovery gate passes.

## Frozen Escalation Gates

- All reports must match one compiled EX5 and return valid complete metrics with zero tester errors.
- Both disjoint eras must remain profitable and cannot trail their same-era control by more than 2%.
- The center must improve continuous net profit by at least 4% and CAGR by at least 0.06 percentage points.
- Center PF must be at least the control PF; drawdown must be no more than the lower of 1.20% or control plus 0.10 percentage points.
- Center recovery and return/drawdown must each be at least 97% of control.
- At least four of six one-variable neighbors must remain profitable in both eras, improve continuous net by at least 2%, and satisfy the same PF, drawdown, and 97% efficiency floors.
- The mechanism must produce confirmed partial-exit evidence; unchanged behavior is a rejection.
- Any losing broad era, safety failure, identity mismatch, weak neighborhood, or missed center gate rejects the family before Model 4.

Only a gate-passing center may advance to recent holdout and Model 4 real-tick validation. The registered forward candidate remains unchanged regardless of this discovery result.
