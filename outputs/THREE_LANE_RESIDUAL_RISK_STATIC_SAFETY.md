# Three-Lane Residual-Risk Static Safety

**Status: PASS FOR RESEARCH EXECUTION. BOTH FEATURES DEFAULT OFF. REAL-ACCOUNT TRADING DEFAULTS OFF.**

| Check | V1 | V2 |
|---|---|---|
| Source identity pinned | PASS | PASS |
| Frozen ATB150 source identity pinned | PASS | PASS |
| Compile result | 0 errors, 0 warnings | 0 errors, 0 warnings |
| Feature defaults disabled | PASS | PASS |
| New direct buy/sell paths | 0 | 0 |
| Uses prior outcomes/drawdown/loss streaks for sizing | No | No |
| Account-wide exposure guard retained | PASS | PASS |
| Post-fill lane and portfolio reconciliation retained | PASS | PASS |
| Portfolio open-risk cap | 0.75% | 0.75% |
| Base-lot eligibility gates | Not present; reason for V1 repair | 3/3 lanes |
| Real-account trading default | Disabled | Disabled |

V1 source SHA-256: `6FCAF941E0BA5BFD30C7286CFD9037D31912232D3BF40E020F672A67433ED53E`

V2 source SHA-256: `D468B984972E84FE2F0E368035EB74841D8B1856AEA56A893FB819DFE4C482E4`

Frozen ATB150 source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`

Static safety is necessary but not evidence of profitability or live readiness. V1 failed paired Model 4 performance gates. V2 failed its Model 1 parameter-neighborhood gate and was not permitted to run Model 4.
