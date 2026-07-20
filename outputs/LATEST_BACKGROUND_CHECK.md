# Latest Research Check

Generated locally on `2026-07-20` after the momentum-buy payoff discovery cycle.

MT5 and MetaEditor were launched only through the controlled local research harness. GitHub Actions were not used. Testing ended with both launch locks restored and zero MT5-family processes running.

## Result

There is no newly validated best profile.

The provisional historical research leader remains `Strong-Signal Selective Reversion Lot Cap`:

- Model 4 real ticks, 2015-2026, `$10,000` start
- Net `+$2,428.50`; total `+24.28%`; CAGR `+1.90%/yr`
- PF `1.89`; 404 trades; maximum equity drawdown `1.18%`
- Recovery `17.09`; return/drawdown `20.58`

The registered forward candidate remains unchanged and has no valid forward evidence. The attached `$100,000` demo violates the frozen `$10,000` starting-capital contract and counts as zero days and zero trades. Real-account trading remains disabled.

## Latest Strategy-Code Test

The new default-off mechanism changed only the initial target of existing momentum buys. Momentum sells stayed at `2.0R`; all entries, stops, requested risk, broker-valued sizing, exit management, loss limits, the `0.75%` account-wide exposure cap, and live-account protections remained unchanged.

| Profile | 2015-18 | 2019-20 | 2015-20 net | CAGR | PF | Trades | DD | Recovery | Frozen gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$1,001.72 | +$370.41 | +$1,353.74 | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | Control |
| Buy 2.25R | +$1,034.03 | +$405.45 | +$1,406.57 | 2.22%/yr | 1.89 | 262 | 1.15% | 10.9367 | Fail |
| Buy 2.50R center | +$1,061.03 | +$396.16 | +$1,412.34 | 2.23%/yr | 1.90 | 261 | 1.10% | 11.4927 | Fail |
| Buy 2.75R | +$1,031.98 | +$410.27 | +$1,397.89 | 2.21%/yr | 1.90 | 261 | 1.19% | 10.5168 | Fail |
| Buy 3.00R | +$1,052.40 | +$449.14 | +$1,449.25 | 2.28%/yr | 1.92 | 261 | 1.16% | 11.0833 | Fail |

All `15/15` reports parsed with exact source, EX5, config, report, and sidecar identity. The `2.50R` center passed every frozen growth, broad-era, PF, recovery, return/drawdown, and drawdown gate. It produced 261 trades versus the required minimum 263, however, and zero of three non-center neighbors passed the complete support gate. Post-2020 and Model 4 testing therefore did not open.

The preceding buy residual-risk ladder was also rejected: its higher net converted unused lot capacity into worse PF, recovery, and drawdown efficiency. Neither result changes the leader.

## Evidence

- Decision: `outputs/THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_DECISION.md`
- Frozen contract: `outputs/THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_CONTRACT.md`
- Summary: `outputs/THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_SUMMARY.csv`
- Exact report ledger: `outputs/THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_MODEL1_RESULTS.csv`
- Run attestation: `outputs/THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_RUN_ATTESTATION.csv`
- Direction attribution: `outputs/THREE_LANE_MOMENTUM_DIRECTION_ATTRIBUTION.md`

## Next Useful Step

Keep the current leader unchanged. The buy-payoff result is worth retaining as architecture evidence, but its frozen discovery contract forbids opening newer data. A future distinct mechanism may target payoff selectivity without revisiting or relaxing the observed `2.50R` gate. Forward evidence cannot begin until a dedicated `$10,000` demo satisfies the frozen account contract.
