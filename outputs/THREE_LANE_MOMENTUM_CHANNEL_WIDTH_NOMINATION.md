# Momentum Channel-Width Nomination Contract

**Status: FROZEN BEFORE CALCULATING 2019-2020 CHANNEL-WIDTH OUTCOMES. THIS IS NOT A STRATEGY PROMOTION OR LIVE APPROVAL.**

- Telemetry source SHA-256: `14F40409A6865F081774AEE18FEEC3E0F22ED1833F8ECAB54DD4BD852A3AD14B`
- Telemetry EX5 SHA-256: `A50D24418921D92A478EDA1EC38BD1BDE6D0E5A941BA5A5236C42BF530F014CB`
- Trade-feature ledger SHA-256: `B3913BD8667C8552937D921197E4949DCA5822075A943F5F8C0032DE77542A3F`
- Behavior-equivalent portfolio control: `+$1,379.93`, 261 trades, PF `1.88`, `1.05%` drawdown
- Momentum telemetry: 194 trades; 133 training trades in 2015-2018; 61 reserved validation trades in 2019-2020

## Nominated Feature

`channel_width_atr = completed 20-bar H1 breakout channel width / completed H1 ATR(20)`

Reject an otherwise valid momentum entry when `channel_width_atr` exceeds `6.50`. Frozen support neighbors are `6.00` and `7.00`. The feature uses completed bars only and is independent of trade outcomes, account state, calendar labels, and future data.

## Training Evidence

| Maximum channel width | Retained | Momentum net | Momentum PF | 2015-16 net | 2017-18 net |
|---:|---:|---:|---:|---:|---:|
| Disabled control | 133 | +$478.60 | 1.661 | +$153.20 | +$325.40 |
| 6.00 ATR | 118 | +$503.58 | 1.818 | +$161.79 | +$341.79 |
| **6.50 ATR center** | **122** | **+$534.98** | **1.841** | **+$185.88** | **+$349.10** |
| 7.00 ATR | 127 | +$487.35 | 1.712 | +$161.00 | +$326.35 |

All three thresholds retained at least 88% of training trades, improved net and PF, and remained profitable in both training halves. The threshold family describes the same broad market-phase boundary rather than a single isolated point.

## Frozen Validation Gate

Open only the already-recorded 2019-2020 feature rows for the center and its two neighbors.

1. Every enabled row must retain at least 46 of 61 validation trades and change behavior.
2. The center and at least one neighbor must remove non-positive net overall and separately in both 2019 and 2020.
3. The center and that supporting neighbor must retain at least 98% of validation momentum PF.
4. The center full-period momentum improvement must add at least 2% of the `+$1,379.93` portfolio control net.
5. At least two of the three thresholds must pass every validation condition.

A pass permits only a fresh default-off source implementation and paired pre-2021 Model 1 testing. Post-2020 data, Model 4, promotion, the registered forward candidate, and real-account trading remain closed.
