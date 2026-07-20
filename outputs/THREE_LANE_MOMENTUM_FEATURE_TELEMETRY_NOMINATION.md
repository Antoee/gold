# Momentum Feature Telemetry Nomination Contract

**Status: FROZEN BEFORE OPENING 2019-2020 FEATURE OUTCOMES. THIS IS NOT A STRATEGY PROMOTION OR LIVE APPROVAL.**

- Telemetry source SHA-256: `14F40409A6865F081774AEE18FEEC3E0F22ED1833F8ECAB54DD4BD852A3AD14B`
- Telemetry EX5 SHA-256: `A50D24418921D92A478EDA1EC38BD1BDE6D0E5A941BA5A5236C42BF530F014CB`
- Model 1 report SHA-256: `BD12FEFCA757889F5B0276717FEE90B0A5998EFBA052814E03A51EB9F7AA3060`
- Raw event SHA-256: `46D80E7B9106D44553D5562BBEF979F845FBA3F3D07A1551BB3AE8D281A5528A`
- Trade-feature ledger SHA-256: `B3913BD8667C8552937D921197E4949DCA5822075A943F5F8C0032DE77542A3F`
- Behavior-equivalent control: `+$1,379.93`, 261 portfolio trades, PF `1.88`, `1.05%` drawdown
- Momentum telemetry: 194 trades; 133 training trades in 2015-2018; 61 reserved validation trades in 2019-2020

## Nominated Feature

`breakout_fraction = breakout distance beyond the completed 20-bar H1 channel / completed 20-bar H1 channel width`

Require `breakout_fraction >= 0.020`. The frozen support neighbors are `0.015` and `0.025`. This feature uses only completed bars and is independent of trade outcomes, account state, calendar labels, and future data.

## Training Evidence

| Threshold | Retained | Momentum net | Momentum PF | Removed 2015-16 | Removed 2017-18 | Training gate |
|---:|---:|---:|---:|---:|---:|---|
| Disabled control | 133 | +$478.60 | 1.66 | - | - | CONTROL |
| Minimum 0.015 | 125 | +$539.05 | 1.85 | -$13.84 | -$46.61 | PASS |
| **Minimum 0.020 center** | **113** | **+$531.97** | **1.97** | **-$2.43** | **-$50.94** | **PASS** |
| Minimum 0.025 | 107 | +$504.66 | 1.98 | -$2.43 | -$23.63 | PASS |

Every nominated threshold retained at least 75% of training trades, improved net and PF, and removed net losers independently in both training halves.

## Frozen Validation Gate

Open only the already-recorded 2019-2020 feature rows for the nominated center and its two neighbors.

1. Every row must retain at least 46 of 61 validation trades and change behavior.
2. The center and at least one neighbor must remove non-positive net overall and separately in both 2019 and 2020.
3. The center and that supporting neighbor must retain at least 98% of validation momentum PF.
4. The center full-period momentum improvement must add at least 2% of the `$1,379.93` portfolio control net.
5. At least two of the three thresholds must pass all validation conditions.

A pass permits only a fresh default-off source implementation and pre-2021 paired Model 1 testing. Post-2020 data, Model 4, promotion, the registered forward candidate, and real-account trading remain closed.
