# Three-Lane Momentum Buy Payoff Discovery Contract

**Status: FROZEN BEFORE SOURCE CREATION, COMPILATION, OR TEST RESULTS. RESEARCH ONLY.**

## Evidence And Hypothesis

The exact provisional leader's 2015-2026 Model 4 ledger contains 205 momentum buys at `+$496.04`, PF `1.40`, versus 109 sells at `+$167.73`, PF `1.25`. Buy target exits contributed 58 trades and `+$1,618.27`; buy logic exits and stop exits lost `-$1,122.23` combined. Buys remained profitable in all three broad eras.

An earlier settings-only ladder widened the take profit for both momentum directions and was rejected. The narrower hypothesis is that preserving the original `2.0R` sell target while widening only existing momentum-buy targets may improve payoff without raising initial risk. This architecture was selected after inspecting the full leader ledger and prior research, so no historical window is claimed as pristine out-of-sample evidence.

## Frozen Mechanism

- Use the exact strong-signal selective reversion lot-cap leader as control.
- Add one default-off buy-only take-profit switch and one fixed buy take-profit R input.
- When enabled for an otherwise-valid momentum buy, calculate only its initial take profit from the fixed buy R value.
- Keep momentum sells at the original `2.0R` target.
- Preserve every entry condition, initial stop, requested risk, broker-valued lot sizing, post-fill reconciliation, exit-management rule, lane and portfolio loss limit, and the `0.75%` account-wide open-risk cap.
- No added entry or close path, martingale, grid, averaging, recovery sizing, outcome-conditioned behavior, funding change, forward substitution, or real-account trading.

## Frozen Model 1 Ladder

| Profile | Buy payoff switch | Buy target | Sell target | Role |
|---|---|---:|---:|---|
| Control | off | base `2.0R` | base `2.0R` | exact leader |
| Buy 2.25R | on | `2.25R` | base `2.0R` | lower support |
| Buy 2.50R | on | `2.50R` | base `2.0R` | frozen center |
| Buy 2.75R | on | `2.75R` | base `2.0R` | upper support |
| Buy 3.00R | on | `3.00R` | base `2.0R` | upper boundary |

Each profile is tested on disjoint 2015-2018 and 2019-2020 eras plus continuous 2015-2020 data. The 2021-2026 period remains closed unless discovery passes.

## Frozen Escalation Gates

- All 15 reports must match one clean compiled EX5 and return complete metrics with zero tester errors.
- Every profile must remain profitable in both disjoint eras.
- The center must retain at least 98% of control net in each disjoint era.
- Center continuous net must be at least 3% above control and CAGR at least `0.05` percentage points above control.
- Center PF, recovery, and return/drawdown must each be no worse than control.
- Center drawdown must be no more than the lower of `1.20%` or control plus `0.08` percentage points.
- Center trade count must be at least control minus two; target settings or net profit must prove the feature was active.
- At least two of the three non-center enabled neighbors must retain 98% of both era controls, improve continuous net by at least 1.5%, improve CAGR by at least `0.02` point, retain 98% of PF/recovery/return-drawdown, meet the same drawdown ceiling, and retain at least control minus three trades.
- Any losing era, safety failure, identity mismatch, inactive feature, weak center, or unsupported ladder rejects the family before post-2020 or Model 4 testing.

Only a passing center may advance to architecture-seen 2021-2026 confirmation and then Model 4 real-tick validation. The historical leader and registered forward candidate remain unchanged unless every later gate also passes.
