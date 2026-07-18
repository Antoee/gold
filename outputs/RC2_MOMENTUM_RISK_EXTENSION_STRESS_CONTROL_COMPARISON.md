# RC2 Momentum-Risk Stress Control Comparison

Diagnostic comparison using the already frozen bootstrap method and seeds. This is not a new selection gate.

- Control ledger SHA-256: `2F7A8A8854F8F33325498AE0F194202E7BB15F28F2644FC4F9B08DE8B740413B`
- Center ledger SHA-256: `80E2E741EA508DCC2D048661FF266A72F6708812F4F75EBB96DCB1136247CE59`

| Profile | Scenario | P05 net | Median net | Median PF | P95 DD | P95 loss run | Red trials | Gate |
|---|---|---:|---:|---:|---:|---:|---:|---|
| control_mo015 | standard | +$236.26 | +$1,078.93 | 1.368 | 5.180% | 15 | 1.710% | False |
| control_mo015 | severe | -$313.31 | +$542.14 | 1.172 | 7.385% | 16 | 14.930% | False |
| center_mo020 | standard | +$158.22 | +$1,132.10 | 1.293 | 6.383% | 15 | 2.770% | False |
| center_mo020 | severe | -$539.32 | +$435.84 | 1.105 | 9.629% | 16 | 23.330% | False |

Because the two profiles share signals but have different realized lot steps, this comparison isolates whether the increased momentum allocation improves or weakens the same stress method.
