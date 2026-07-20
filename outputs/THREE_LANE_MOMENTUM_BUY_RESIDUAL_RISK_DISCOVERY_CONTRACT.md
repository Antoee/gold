# Three-Lane Momentum Buy Residual-Risk Discovery Contract

**Status: FROZEN BEFORE SOURCE COMPILATION OR TEST RESULTS. RESEARCH ONLY.**

## Evidence And Hypothesis

The exact provisional leader's 2015-2026 Model 4 ledger contains 205 momentum buys at `+$496.04`, PF `1.40`, versus 109 momentum sells at `+$167.73`, PF `1.25`. Momentum buys were profitable in all three broad eras (`+$314.43`, `+$75.51`, and `+$106.10`). This is architecture-selection evidence, not pristine out-of-sample evidence.

The hypothesis is that momentum buys which already qualify for the leader's original minimum lot at `0.15%` may safely use a small amount of otherwise unused account-wide risk capacity. Momentum sells and every non-momentum lane remain unchanged.

## Frozen Mechanism

- Use the exact strong-signal selective reversion lot-cap leader as the control.
- Add one default-off buy residual-risk switch and one fixed buy risk input.
- Before residual sizing, require the buy to produce a valid lot at the original `0.15%` momentum risk. This preserves base-lot eligibility and prevents the feature from creating new minimum-lot signals.
- When enabled for a base-eligible buy, use the fixed buy risk consistently for broker-valued sizing and post-fill reconciliation.
- Keep momentum sells at the original `0.15%` risk.
- Keep the exact leader profile values: reversion `0.45%`, momentum base `0.15%`, adaptive trend breakout `0.15%`, and maximum portfolio open risk `0.75%`.
- Preserve the original declared base-risk sum validation. The existing broker-valued account-wide exposure check remains authoritative for every order and rejects a residual request when current open risk leaves insufficient capacity.
- No new entry, changed stop or target geometry, changed exit, martingale, grid, averaging, recovery sizing, outcome-conditioned sizing, funding change, forward substitution, or real-account trading.

## Frozen Model 1 Ladder

| Profile | Residual switch | Buy risk | Sell risk | Role |
|---|---|---:|---:|---|
| Control | off | base `0.15%` | base `0.15%` | exact leader |
| Buy 0.16 | on | `0.16%` | base `0.15%` | lower boundary |
| Buy 0.17 | on | `0.17%` | base `0.15%` | conservative support |
| Buy 0.18 | on | `0.18%` | base `0.15%` | middle support |
| Buy 0.19 | on | `0.19%` | base `0.15%` | upper support |
| Buy 0.20 | on | `0.20%` | base `0.15%` | frozen center |

Each profile is tested on disjoint 2015-2018 and 2019-2020 eras plus continuous 2015-2020 data. The 2021-2026 period remains closed unless discovery passes.

## Frozen Escalation Gates

- All 18 reports must match one clean compiled EX5 and return complete metrics with zero tester errors.
- Every profile must remain profitable in both disjoint eras.
- The center must retain at least 98% of control net in each disjoint era.
- Center continuous net must be at least 4% above control and CAGR at least `0.06` percentage points above control.
- Center PF, recovery, and return/drawdown must each retain at least 97% of control.
- Center drawdown must be no more than the lower of `1.20%` or control plus `0.10` percentage points.
- The center must preserve the control trade count, while changed sizing or net profit must prove the feature was active.
- At least three of the four lower rungs must retain 98% of both era controls, improve continuous net by at least 2%, retain 97% of PF/recovery/return-drawdown, meet the same drawdown ceiling, and preserve trade count.
- Any losing era, safety failure, identity mismatch, inactive feature, weak center, or unsupported ladder rejects the family before post-2020 or Model 4 testing.

Only a passing center may advance to architecture-seen 2021-2026 confirmation and then Model 4 real-tick validation. The registered forward candidate remains unchanged regardless of discovery results.
