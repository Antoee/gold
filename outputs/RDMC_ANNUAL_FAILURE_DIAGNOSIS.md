# RDMC Annual Failure Diagnosis

The D1-cap stability candidate passed broad continuous validation but failed its no-red-year money-readiness gate in 2019 and 2022.

## Exact Model 4 Ledgers

- 2019: 32 trades, -$3.77, PF 0.98. Every trade came from the multiscale momentum lane.
- 2022: 35 trades, -$92.78, PF 0.57. Momentum contributed 34 trades and -$71.78; one reversion trade lost $21.00.
- Both buy and sell momentum trades were weak in 2022, so a direction-only repair is unsupported.

## Rejected Calendar Explanation

The failed years contained 14 Wednesday trades and all 14 lost, but Wednesday is the strongest weekday over the complete annual ledger: 76 trades, +$427.11, PF 1.99. Removing Wednesday would leave 2022 at -$30.98 and turn 2024 negative at -$8.13.

**Decision: reject weekday and calendar filtering.** The pattern is concentrated failure-year noise, not a stable mechanism.

## Selected Mechanism

The 2015-2018 behavior-preserving momentum telemetry matched all 135 exact annual Model 4 momentum trades by entry time and side. Rounded completed-candle minimum range thresholds of 1.00, 1.25, and 1.50 ATR remained profitable in every selection year. The 1.25 ATR midpoint is frozen as center with both neighbors.

This is selection evidence, not proof of repair. The family must make both 2019 and 2022 profitable with adjacent-threshold support before any broad or stress validation is allowed.
