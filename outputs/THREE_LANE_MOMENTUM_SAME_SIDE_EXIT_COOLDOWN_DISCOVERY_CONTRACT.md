# Three-Lane Momentum Same-Side Exit Cooldown Contract

**Status: FROZEN BEFORE SOURCE CREATION, COMPILATION, OR TEST RESULTS. RESEARCH ONLY.**

## Evidence And Hypothesis

The exact buy-payoff control ledger contains four momentum reentries in the same direction within 60 minutes of the previous same-side exit during 2015-2020. All four lost, totaling `-$27.47`. The exact provisional leader's full 2015-2026 Model 4 ledger also contains four same-side reentries inside 60 minutes; all four lost, totaling `-$28.41`. The rejected `2.50R` buy-payoff center naturally suppressed the four discovery-era reentries while continuing to hold the prior winner.

The hypothesis is not that prior winners predict the next trade. A short, outcome-independent same-side cooldown may reduce immediate repeat-breakout noise after any momentum exit. Architecture selection used the full leader ledger and prior experiment, so no historical period is claimed as pristine out-of-sample evidence.

## Frozen Mechanism

- Use the exact strong-signal selective reversion lot-cap leader as control.
- Add one default-off momentum same-side exit-cooldown switch and one integer cooldown-minutes input.
- Before an otherwise-valid momentum entry, find the most recent exit deal for the same symbol, exact momentum magic, and proposed position direction. Block only when elapsed time is below the fixed cooldown.
- Treat every prior exit equally. Do not inspect profit, loss, target, stop, streak, account P/L, drawdown, calendar exception, or future/current-bar data.
- Preserve all signals, initial stops, targets, requested risk, broker-valued sizing, post-fill reconciliation, exit management, lane and portfolio loss limits, and the `0.75%` account-wide open-risk cap.
- No added trade, close, or modify path; martingale; grid; averaging; recovery sizing; funding change; forward substitution; or real-account trading.

## Frozen Model 1 Discovery Ladder

| Profile | Cooldown switch | Same-side cooldown | Role |
|---|---|---:|---|
| Control | off | `0 minutes` | exact leader |
| Cooldown 30 | on | `30 minutes` | lower support |
| Cooldown 60 | on | `60 minutes` | frozen center |
| Cooldown 90 | on | `90 minutes` | upper support |
| Cooldown 120 | on | `120 minutes` | upper boundary |

Each profile is tested on disjoint 2015-2018 and 2019-2020 eras plus continuous 2015-2020 data. The 2021-2026 period remains closed unless discovery passes.

## Frozen Discovery Gates

- All 15 reports must match one clean compiled EX5 and return complete metrics with zero tester errors.
- Every profile must remain profitable in both disjoint eras.
- The center must be no worse than control in each disjoint era.
- Center continuous net must be at least 1.5% above control and CAGR at least `0.03` percentage points above control.
- Center PF, recovery, and return/drawdown must each be no worse than control.
- Center drawdown must be no worse than control and trade count must retain at least 97% of control.
- Settings or net profit must prove the center changed behavior.
- At least two of the three non-center enabled neighbors must be no worse than both era controls, improve continuous net by at least 1.0%, improve CAGR by at least `0.01` point, retain 99% of control PF/recovery/return-drawdown, have no worse drawdown, and retain at least 97% of trades.
- Any losing era, safety failure, identity mismatch, inactive center, weak center, or unsupported ladder rejects the family before post-2020 or Model 4 testing.

## Frozen Recent Confirmation

Only a passing 60-minute center may be compared with exact control on 2021-2023, 2024-2026, and continuous 2021-2026 Model 1 data.

- All six reports must be exact and complete.
- The center must be no worse than control net in both disjoint eras and strictly improve continuous net.
- Center continuous PF, recovery, and return/drawdown must be no worse than control.
- Center drawdown may be at most control plus `0.03` percentage points and trades must retain at least 98% of control.

## Frozen Model 4 Validation

Only a passing recent confirmation may open exact control-versus-center Model 4 real ticks on 2015-2018, 2019-2022, 2023-2026, and continuous 2015-2026.

- All eight reports must be exact and complete.
- The center must be no worse than control net in every disjoint era and strictly improve continuous net.
- Center continuous CAGR, PF, recovery, and return/drawdown must be no worse than control.
- Center drawdown may be at most control plus `0.03` percentage points and trades must retain at least 98% of control.

Only a full Model 4 pass may open annual restart, added-cost, Monte Carlo, and hard-risk audits. Promotion remains provisional until those audits also pass. The registered forward candidate remains unchanged unless a separately frozen forward-registration process is completed.
