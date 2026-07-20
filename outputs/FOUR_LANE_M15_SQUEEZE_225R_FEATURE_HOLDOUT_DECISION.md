# Four-Lane M15 Squeeze 2.25R Feature Holdout Decision

**Decision: REJECTED IN FEATURE HOLDOUT. No Model 4 run, promotion, forward change, or real trading is permitted. NO NEW BEST.**

- Exact accepted Model 1 reports: `18/18`
- Source SHA-256: `5D756F58DDAB31D2DC909B8DD800C8D888582691A7208FFD7FD1E3F597D3A5C6`
- EX5 SHA-256: `7CAF1699EEA00561F2C0559F835679D96BACD957C88B27E33E1ED921FBF8E078`
- Manifest SHA-256: `FECF81EDF7514F4BF525CD061823BFDEEBA41D80E2A154E45B3F8ABC022897DA`
- Results SHA-256: `D6E2820E06423D39E1DF20FBDD964B7FE00FB47CF54F3028D5E588C4606D7E05`
- Run attestation SHA-256: `AAF2BBB20D1F357A6AE790322A9830747DF471B63E7EFE2DDFB6EF73D1F9740E`
- Disabled controls reproduced exactly: `True`
- Every report profitable: `True`

| Candidate | Target | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | DD | Growth vs control | PF retained | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| sqh_reference150 | 1.5R | +$707.76 | +$394.87 | +$1086.95 | 1.89%/yr | 1.73 | 244 | 1.58% | 3.8712% | 83.1731% | False |
| sqh_lower200 | 2R | +$680.21 | +$411.17 | +$1077.27 | 1.87%/yr | 1.72 | 244 | 1.54% | 2.9462% | 82.6923% | False |
| sqh_center225 | 2.25R | +$712.97 | +$418.67 | +$1131.75 | 1.96%/yr | 1.76 | 242 | 1.51% | 8.1524% | 84.6154% | False |
| sqh_upper250 | 2.5R | +$684.72 | +$437.38 | +$1111.97 | 1.93%/yr | 1.75 | 242 | 1.51% | 6.2622% | 84.1346% | False |

## Frozen Gate

- Fixed 2.25R center pass: `False`
- Passing fixed sensitivity rows: `0/2`; required: `1/2`

## Interpretation

The fixed 2.25R center improved continuous post-2020 net from `+$1,046.44` to `+$1,131.75`, an `8.15%` gain, and beat the enabled 1.50R reference by `4.12%`. It did not reach the frozen 10% growth floor and its CAGR gain was `0.14` point versus `0.15` required.
More importantly, the center trailed exact control in 2024-2026 (`+$418.67` versus `+$434.36`), reduced continuous PF from `2.08` to `1.76`, and raised drawdown from `1.21%` to `1.51%`, above the paired `1.41%` limit. Neither sensitivity row passed the complete quality and drawdown gate.
The stronger pre-2021 2.25R result therefore did not transfer with enough risk-adjusted support. The target family is closed without spending Model 4 time. The verified three-lane same-side exit-cooldown leader remains unchanged.
The frozen forward candidate is unchanged. The attached `$100,000` demo violates the `$10,000` capital contract and remains zero forward evidence; real-account trading remains disabled.
