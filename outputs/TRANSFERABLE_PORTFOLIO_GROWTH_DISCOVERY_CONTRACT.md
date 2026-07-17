# Transferable Portfolio Growth Allocation Discovery Contract

Frozen on 2026-07-17 before any combined-EA growth-ladder report was generated.

## Hypothesis

The exact released two-lane EA may support a higher reversion allocation while retaining the same `0.75%` shared open-risk cap. This is an allocation-efficiency test, not a new entry strategy. Source, schedules, signals, exits, stop rules, minimum-lot refusal, and account safety controls remain byte-identical to Transferable Portfolio v0.1.

## Profiles

The fixed neighborhood uses reversion risk `0.45%` through `0.60%` and momentum risk `0.10%` or `0.15%`. No profile may request more than `0.75%` combined lane risk or raise the shared portfolio cap.

The released `0.45% + 0.15%` profile is the control. A growth profile must outperform that control in the same reports; historical profit from a different engine or test cannot satisfy the gate.

## Model 1 discovery windows

- 2015-01-01 through 2018-12-31
- 2019-01-01 through 2022-12-31
- 2023-01-01 through 2026-07-16
- Continuous 2015-01-01 through 2026-07-16
- Starting deposit: `$10,000`

## Frozen escalation gate

All conditions are required:

- Positive net profit in every broad era.
- Continuous net profit at least `15%` above the same-source control.
- Continuous profit factor at least `1.50`.
- At least `330` continuous trades.
- Continuous maximum relative equity drawdown no more than `4.00%`.
- Continuous recovery factor at least `4.00`.
- At least two adjacent growth allocations pass every gate.
- No profile may depend on one isolated maximum-risk edge.

Passing Model 1 only permits exact Model 4, cost-stress, and Monte Carlo validation. Promotion additionally requires Model 4 net at least `15%` above the released executable, PF at least `1.50`, drawdown no more than `4.00%`, every broad era positive, and a passing neighboring allocation. It does not replace the frozen forward candidate or authorize real-money trading.

## Safety invariants

- Real-account trading stays disabled by default.
- Shared open-risk cap remains `0.75%`.
- Maximum equity drawdown guard remains `5.00%`.
- Broker-native `OrderCalcProfit` sizing remains unchanged.
- Broker minimum volume is never forced when it exceeds requested risk.
- No martingale, grid, averaging down, or recovery sizing.
