# Independent M15 Session Impulse-Pullback Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

This standalone EA measured a fixed morning-session impulse using ATR magnitude, auction-path efficiency, directional-bar share, and close location. It then required a bounded pullback and completed M15 reclaim before entry. It retained broker-native risk sizing, minimum-lot refusal, a `$10,000` contract, account-wide exposure limits, daily/equity loss locks, one trade per day, and disabled real trading.

- Source SHA-256: `A5A4A1F8C26C7DBEDB7EAE46C599F6429626F69312A21D352883592E2D63FDD9`
- Exact report binary SHA-256: `69E76951ECE247CC928128D9E94C90622D42F39E15DA54C01D252689DB5A82F6`
- Controlled evidence: `45 / 45` Model 1 reports, one exact binary, zero report-hash failures
- Risk per accepted trade: `0.10%` on a `$10,000` test deposit
- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`
- Numeric gate passes: `0 / 15`
- Maximum continuous activity: `18` trades versus the required `80`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `sip_end8` | +$48.99 | 2.03 | 12 | -$15.08 | 0.53 | 6 | +$33.91 | 0.06% | 1.42 | 18 | 0.43% | REJECT_BEFORE_HOLDOUT |
| `sip_dir65` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `sip_end10` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `sip_eff55` | -$9.80 | 0 | 1 | +$0.00 | 0 | 0 | -$9.80 | -0.02% | 0 | 1 | 0.1% | REJECT_BEFORE_HOLDOUT |
| `sip_minret30` | -$9.80 | 0 | 1 | +$0.00 | 0 | 0 | -$9.80 | -0.02% | 0 | 1 | 0.1% | REJECT_BEFORE_HOLDOUT |
| `sip_maxret45` | -$18.35 | 0 | 2 | +$0.00 | 0 | 0 | -$18.35 | -0.03% | 0 | 2 | 0.18% | REJECT_BEFORE_HOLDOUT |
| `sip_lookback8` | -$28.15 | 0 | 3 | +$0.00 | 0 | 0 | -$28.15 | -0.05% | 0 | 3 | 0.28% | REJECT_BEFORE_HOLDOUT |
| `sip_center` | -$28.15 | 0 | 3 | +$0.00 | 0 | 0 | -$28.15 | -0.05% | 0 | 3 | 0.28% | REJECT_BEFORE_HOLDOUT |
| `sip_minret10` | -$28.15 | 0 | 3 | +$0.00 | 0 | 0 | -$28.15 | -0.05% | 0 | 3 | 0.28% | REJECT_BEFORE_HOLDOUT |
| `sip_lookback4` | -$28.15 | 0 | 3 | +$0.00 | 0 | 0 | -$28.15 | -0.05% | 0 | 3 | 0.28% | REJECT_BEFORE_HOLDOUT |
| `sip_dir45` | -$28.15 | 0 | 3 | +$0.00 | 0 | 0 | -$28.15 | -0.05% | 0 | 3 | 0.28% | REJECT_BEFORE_HOLDOUT |
| `sip_impulse40` | -$28.15 | 0 | 3 | +$0.00 | 0 | 0 | -$28.15 | -0.05% | 0 | 3 | 0.28% | REJECT_BEFORE_HOLDOUT |
| `sip_impulse80` | -$28.15 | 0 | 3 | +$0.00 | 0 | 0 | -$28.15 | -0.05% | 0 | 3 | 0.28% | REJECT_BEFORE_HOLDOUT |
| `sip_eff35` | -$6.38 | 0.86 | 9 | -$28.08 | 0 | 3 | -$34.46 | -0.06% | 0.54 | 12 | 0.59% | REJECT_BEFORE_HOLDOUT |
| `sip_maxret75` | -$27.71 | 0.02 | 4 | -$6.80 | 0 | 1 | -$34.51 | -0.06% | 0.01 | 5 | 0.46% | REJECT_BEFORE_HOLDOUT |

## Interpretation

- The only profitable continuous variant, `sip_end8`, earned `+$33.91` but lost `-$15.08` in 2019-2020 and placed only `18` trades across six years.
- Twelve continuous variants lost money and two were flat. Signal inactivity is intrinsic to this frozen rule set, not a position-sizing or minimum-lot failure.
- Reject this family without inspecting 2021-2026 or spending real-tick time on it. Keep Three-Lane Trade-Ready RC2 ATB150 as the research best.
