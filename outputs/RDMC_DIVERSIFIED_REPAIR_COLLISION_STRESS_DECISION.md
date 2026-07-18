# RDMC Diversified Repair Collision Stress Decision

**Decision: POSTHOC STRESS TRIAGE PASS. This is post-hoc triage, not executable MT5 evidence or a new best.**

- Accepted collision-adjusted trades: `368`; base net `+$2,067.64`
- Cost gate: `True`; Monte Carlo gate: `True`; light-cost 12-window gate: `True`
- Window warning: moderate cost remains `12/12` positive; severe cost falls to `10/12` because 2019 and 2022 turn slightly negative
- Next action: `RUN_FROZEN_MT5_GATE_WHEN_UNLOCKED`
- Collision ledger SHA-256: `ED51B6648E5B17F738D83CC05238828365EE621872D94AE3D981604C7433C047`
- Frozen stress-method SHA-256: `71B6929E06EDF660F704866EB2931044C799FB2CB2B85ACF8FDEEDCECC1DD33C`
- Target source SHA-256: `EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F`
- Target profile SHA-256: `746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883`

## Deterministic Added Cost

| Scenario | Added R/trade | Extra cost | Net | CAGR | PF | Closed DD | Positive windows | Older | Middle | Recent | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| base | 0.00R | $0.00 | +$2,067.64 | 1.642%/yr | 1.894 | 0.866% | 12/12 | +$687.51 | +$650.83 | +$729.30 | True |
| light | 0.02R | $105.20 | +$1,962.44 | 1.565%/yr | 1.829 | 0.926% | 12/12 | +$647.00 | +$611.59 | +$703.85 | True |
| moderate | 0.05R | $262.99 | +$1,804.65 | 1.448%/yr | 1.736 | 1.018% | 12/12 | +$586.24 | +$552.74 | +$665.67 | True |
| severe | 0.10R | $525.99 | +$1,541.65 | 1.250%/yr | 1.595 | 1.176% | 10/12 | +$484.97 | +$454.65 | +$602.03 | True |

## Bootstrap Monte Carlo

| Scenario | Trials | P05 net | Median net | Median PF | P95 closed DD | P95 loss run | Red trials | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| standard | 10000 | +$757.31 | +$1,563.57 | 1.636 | 3.247% | 14 | 0.070% | True |
| severe | 10000 | +$255.92 | +$1,032.94 | 1.393 | 4.458% | 15 | 1.490% | True |

## Hard Boundary

- The ledger combines standalone historical runs. Collision blocking can change later signals, cooldowns, limits, and equity-based sizing in the actual EA.
- Bootstrap sampling cannot recreate intratrade drawdown, broker execution, market-regime order, or future market behavior.
- Drawdown here is closed-trade only. Component reports came from different source versions and starting-balance contexts.
- The target source is uncompiled and untested while the local MT5 launch locks are active.
- Passing only earns a future frozen MT5 gate. It cannot change the registered forward candidate or approve real-account trading.
