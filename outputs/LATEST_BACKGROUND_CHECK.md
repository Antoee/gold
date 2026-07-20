# Latest Research Check

Generated locally on `2026-07-20` after the momentum-buy residual-risk discovery cycle.

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

The new default-off mechanism allowed only an already-base-eligible momentum buy to request `0.16%` through `0.20%` risk while sells stayed at `0.15%`. Broker-valued sizing, post-fill reconciliation, and the existing `0.75%` account-wide exposure cap remained authoritative. No signal, stop, target, exit, martingale, grid, averaging, recovery-sizing, or live-account path was added.

| Profile | 2015-18 | 2019-20 | 2015-20 net | CAGR | PF | Trades | DD | Recovery | Frozen gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$1,001.72 | +$370.41 | +$1,353.74 | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | Control |
| Buy 0.16% | +$976.54 | +$361.84 | +$1,332.61 | 2.11%/yr | 1.79 | 265 | 1.11% | 11.3694 | Fail |
| Buy 0.17% | +$1,027.79 | +$364.91 | +$1,353.19 | 2.14%/yr | 1.78 | 265 | 1.24% | 9.6892 | Fail |
| Buy 0.18% | +$1,045.47 | +$352.09 | +$1,427.72 | 2.25%/yr | 1.79 | 265 | 1.33% | 9.5321 | Fail |
| Buy 0.19% | +$1,037.38 | +$323.47 | +$1,439.32 | 2.27%/yr | 1.77 | 265 | 1.33% | 9.6096 | Fail |
| Buy 0.20% center | +$1,072.03 | +$389.01 | +$1,524.39 | 2.39%/yr | 1.78 | 266 | 1.30% | 10.3976 | Fail |

All `18/18` reports parsed with exact source, EX5, config, report, and sidecar identity. The center passed net and CAGR growth but failed the preregistered PF/recovery/return-drawdown, drawdown, and control-trade-count gates. Zero of four lower rungs passed the complete neighbor gate, so post-2020 and Model 4 testing did not open.

An earlier direction-specific prototype returned zero trades because its preflight metadata used the source default adaptive risk instead of the exact leader profile value. It is classified as an invalid configuration and excluded from strategy evidence.

## Evidence

- Decision: `outputs/THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_DECISION.md`
- Frozen contract: `outputs/THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_CONTRACT.md`
- Summary: `outputs/THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_SUMMARY.csv`
- Exact report ledger: `outputs/THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_MODEL1_RESULTS.csv`
- Run attestation: `outputs/THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_RUN_ATTESTATION.csv`
- Direction attribution: `outputs/THREE_LANE_MOMENTUM_DIRECTION_ATTRIBUTION.md`

## Next Useful Step

Keep the current leader unchanged. Continue the separate research lane with a distinct entry or payoff mechanism that can improve return without merely converting unused lot capacity into worse drawdown efficiency. Forward evidence cannot begin until a dedicated `$10,000` demo satisfies the frozen account contract.
