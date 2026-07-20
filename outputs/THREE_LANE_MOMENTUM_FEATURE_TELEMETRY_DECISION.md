# Momentum Feature Telemetry Decision

**Decision: REJECTED IN RESERVED 2019-2020 VALIDATION. No strategy implementation, post-2020 test, Model 4 run, promotion, forward change, or live approval is permitted.**

## Integrity

- Telemetry source SHA-256: `14F40409A6865F081774AEE18FEEC3E0F22ED1833F8ECAB54DD4BD852A3AD14B`
- Telemetry EX5 SHA-256: `A50D24418921D92A478EDA1EC38BD1BDE6D0E5A941BA5A5236C42BF530F014CB`
- Report SHA-256: `BD12FEFCA757889F5B0276717FEE90B0A5998EFBA052814E03A51EB9F7AA3060`
- Trade-feature ledger SHA-256: `B3913BD8667C8552937D921197E4949DCA5822075A943F5F8C0032DE77542A3F`
- Exact behavior-equivalent Model 1 control: `+$1,379.93`, 261 portfolio trades, PF `1.88`, `2.18%/yr` CAGR, `1.05%` drawdown
- Static source audit: completed bars only, no new input, entry, close, modify, sizing, risk, or real-account path

## Frozen Candidate

Training on 2015-2018 nominated:

`breakout_fraction = breakout distance beyond the completed H1 channel / completed H1 channel width`

The center required `breakout_fraction >= 0.020`, with frozen `0.015` and `0.025` neighbors. All three improved training momentum net and PF, retained at least 75% of trades, and removed net losers independently in 2015-2016 and 2017-2018.

## Reserved Validation

| Threshold | Trades | Momentum net | PF | Removed 2019 | Removed 2020 | Full-period improvement | Projected portfolio net | Gate |
|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | 61 | **+$147.65** | **1.3858** | - | - | - | **+$1,379.93** | CONTROL |
| Minimum 0.015 | 56 | +$63.09 | 1.1669 | -$3.55 | **+$88.11** | -$24.11 | +$1,355.82 | FAIL |
| **Minimum 0.020 center** | 54 | +$73.06 | 1.1985 | -$4.96 | **+$79.55** | -$21.22 | +$1,358.71 | **FAIL** |
| Minimum 0.025 | 50 | +$111.76 | 1.3394 | -$21.62 | **+$57.51** | -$9.83 | +$1,370.10 | FAIL |

## Interpretation

The training plateau did not transfer. Each threshold removed a small net loser in 2019 but also removed a much larger set of winners in 2020. Validation net and PF fell at every threshold, and all three reduced projected full-period portfolio profit. Passing thresholds were `0/3` versus `2/3` required.

This is exactly why the 2019-2020 feature rows were reserved. The attractive training result is not converted into code, the threshold is not moved after observation, and post-2020 data remains untouched for a different hypothesis. The current same-side cooldown historical leader and registered forward candidate remain unchanged. Real-account trading remains disabled.
