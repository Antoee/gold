# Momentum Channel-Width Telemetry Decision

**Decision: REJECTED IN TELEMETRY VALIDATION. No strategy implementation, MT5 rerun, post-2020 test, Model 4 run, promotion, forward substitution, or live approval is permitted.**

- Frozen nomination SHA-256: `5618C9E77EBD9F33A46FBD4A52067D3C408F05D4D929422F3EAC15436FD36C2F`
- Exact telemetry ledger SHA-256: `B3913BD8667C8552937D921197E4949DCA5822075A943F5F8C0032DE77542A3F`
- Populations: `133` training trades and `61` reserved validation trades

| Profile | Max width | Training net | Validation trades | Validation net | Validation PF | Removed 2019 | Removed 2020 | Full improvement | Projected portfolio | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `mcw_control` | disabled | +$478.60 | 61 | +$147.65 | 1.3858 | +$0.00 | +$0.00 | +$0.00 | +$1,379.93 | CONTROL |
| `mcw_max600` | 6 | +$503.58 | 49 | +$14.06 | 1.0403 | +$50.76 | +$82.83 | -$108.61 | +$1,271.32 | FAIL |
| `mcw_center` | 6.5 | +$534.98 | 55 | +$71.42 | 1.1925 | +$46.88 | +$29.35 | -$19.85 | +$1,360.08 | FAIL |
| `mcw_max700` | 7 | +$487.35 | 58 | +$90.33 | 1.2361 | +$57.32 | +$0.00 | -$48.57 | +$1,331.36 | FAIL |

## Frozen Gate

- Center complete gate: `False`
- Passing enabled profiles: `0 / 3`; required `2`; names: ``
- Strategy implementation permitted: `False`

The published historical leader, registered forward identity, invalid-account boundary, and real-account lock remain unchanged.
