# Momentum Profit Ratchet Discovery Decision

**Decision: REJECTED IN DISCOVERY. Post-2020 data, Model 4, promotion, forward substitution, and live approval remain closed.**

- Exact reports: `24 / 24`; unchanged identity retries: `2`
- Source SHA-256: `04E9A3FA2B85090A53E7B9D769BA536693D7A590794F58AD97F926D5CB2AFAF4`
- EX5 SHA-256: `6B0959FE621763A5137523127BD17B224363D84E2DB3EDBD60B76DDB1B66E321`
- Entry, initial stop, take-profit distance, position risk, exposure cap, and safety locks were unchanged; only the optional completed-bar second-stage stop ratchet changed.

| Profile | 2015-18 | 2019-20 | Continuous | Improvement | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `mpr_control` | +$1,036.19 | +$370.60 | +$1,379.93 | 0% | 2.18%/yr | 1.88 | 261 | 1.05% | 11.6775 | 13.1429 | CONTROL |
| `mpr_trigger125` | +$995.89 | +$369.40 | +$1,347.30 | -2.365% | 2.13%/yr | 1.86 | 262 | 0.99% | 12.1696 | 13.6061 | FAIL |
| `mpr_center` | +$1,030.00 | +$370.60 | +$1,382.26 | 0.169% | 2.18%/yr | 1.89 | 261 | 1.06% | 11.6972 | 13.0377 | FAIL |
| `mpr_trigger175` | +$1,036.19 | +$370.60 | +$1,379.93 | 0% | 2.18%/yr | 1.88 | 261 | 1.05% | 11.6775 | 13.1429 | FAIL |
| `mpr_lock050` | +$1,034.33 | +$370.60 | +$1,378.07 | -0.135% | 2.18%/yr | 1.88 | 261 | 1.05% | 11.6618 | 13.1238 | FAIL |
| `mpr_lock100` | +$1,035.36 | +$362.05 | +$1,362.22 | -1.283% | 2.15%/yr | 1.87 | 261 | 1.05% | 11.5276 | 12.9714 | FAIL |
| `mpr_conservative` | +$1,036.19 | +$370.60 | +$1,379.93 | 0% | 2.18%/yr | 1.88 | 261 | 1.05% | 11.6775 | 13.1429 | FAIL |
| `mpr_aggressive` | +$997.41 | +$343.72 | +$1,316.76 | -4.578% | 2.08%/yr | 1.83 | 263 | 1.08% | 10.8958 | 12.1944 | FAIL |

## Frozen Gate

- Every report profitable: `True`
- Exact control reproduced: `True`
- Center changed behavior: `True`
- Center complete gate: `False`
- Passing one-factor neighbors: `0 / 6`; required `3`; names: ``

The published historical leader, registered forward identity, invalid-account boundary, and real-account lock remain unchanged.
