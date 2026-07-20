# Strong-Breakout Target Extension Discovery Decision

**Decision: REJECTED IN DISCOVERY. Post-2020 data, Model 4, promotion, forward substitution, and live approval remain closed.**

- Exact reports: `24 / 24`; unchanged identity retries: `3`
- Source SHA-256: `C7B5D50FF1229525CDD619D4943B232C97E229BA7086513A6515EABCC6015110`
- EX5 SHA-256: `7666375D4CB495A1B08F88A28349AC3AC8FA5F14EB26AA3EDD83481FD9B54F91`
- Entry, initial stop, position risk, exposure cap, and safety locks were unchanged; only qualifying take-profit distance changed.

| Profile | 2015-18 | 2019-20 | Continuous | Improvement | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `sbte_control` | +$1,036.19 | +$370.60 | +$1,379.93 | 0% | 2.18%/yr | 1.88 | 261 | 1.05% | 11.6775 | 13.1429 | CONTROL |
| `sbte_target250` | +$956.28 | +$359.53 | +$1,283.74 | -6.971% | 2.03%/yr | 1.83 | 260 | 1.1% | 10.4864 | 11.6727 | FAIL |
| `sbte_center` | +$914.53 | +$410.71 | +$1,293.17 | -6.287% | 2.05%/yr | 1.84 | 260 | 1.48% | 8.3285 | 8.7365 | FAIL |
| `sbte_target350` | +$886.65 | +$426.09 | +$1,289.05 | -6.586% | 2.04%/yr | 1.84 | 260 | 1.48% | 8.302 | 8.7095 | FAIL |
| `sbte_body045` | +$912.76 | +$410.71 | +$1,291.40 | -6.416% | 2.05%/yr | 1.84 | 260 | 1.48% | 8.3171 | 8.723 | FAIL |
| `sbte_body055` | +$914.53 | +$410.71 | +$1,293.17 | -6.287% | 2.05%/yr | 1.84 | 260 | 1.48% | 8.3285 | 8.7365 | FAIL |
| `sbte_close070` | +$944.58 | +$424.59 | +$1,331.59 | -3.503% | 2.11%/yr | 1.86 | 260 | 1.48% | 8.576 | 9 | FAIL |
| `sbte_close080` | +$908.71 | +$442.49 | +$1,328.25 | -3.745% | 2.1%/yr | 1.86 | 260 | 1.48% | 8.5545 | 8.973 | FAIL |

## Frozen Gate

- Every report profitable: `True`
- Exact control reproduced: `True`
- Center changed behavior: `True`
- Center complete gate: `False`
- Passing one-factor neighbors: `0 / 6`; required `3`; names: ``

The published historical leader, registered forward identity, invalid-account boundary, and real-account lock remain unchanged.
