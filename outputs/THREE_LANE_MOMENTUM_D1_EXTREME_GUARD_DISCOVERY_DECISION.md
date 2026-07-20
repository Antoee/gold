# Three-Lane Momentum D1 Extreme Guard Discovery Decision

**Decision: REJECTED NEAR-MISS IN DISCOVERY. Recent confirmation, Model 4, promotion, forward change, and real-account approval are not permitted.**

- Exact reports and identity sidecars: `15/15`
- Source SHA-256: `6493A292B8126FD03596A0062BBC065144AEE949D63E55E7B4F10D8469989A11`
- EX5 SHA-256: `FA394FDB8767BD7E4549FA5D05920EF0A548EE7A39E65A1119873E4711977C63`
- Manifest SHA-256: `0FB09416715B50FE58FEEEFB5CB1B8A6E5B00F6B4EFB3EDE03968EF327E21886`
- Test basis: `$10,000`, XAUUSD M15, MT5 Model 1, pre-2021 discovery only
- Frozen feature: block a momentum entry when the absolute 126-bar D1 close return exceeds `12%`, `18%`, `24%`, or `30%`
- Frozen risk: momentum `0.15%`, account-wide open-risk cap `0.75%`, real trading disabled

| Profile | 2015-18 | 2019-20 | 2015-20 | Total return | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| **Disabled control** | **+$1,036.19** | +$370.60 | +$1,379.93 | 13.80% | 2.18%/yr | 1.88 | 261 | **1.05%** | 11.6775 | **13.1429** | CONTROL |
| Maximum 12% | +$1,037.27 | +$362.03 | +$1,400.64 | 14.01% | 2.21%/yr | 2.06 | 220 | 1.11% | 11.9498 | 12.6216 | FAIL |
| Maximum 18% center | +$1,034.58 | **+$400.36** | **+$1,416.00** | **14.16%** | **2.23%/yr** | 1.95 | 252 | 1.11% | **12.0809** | 12.7568 | FAIL |
| Maximum 24% | +$1,036.19 | +$379.16 | +$1,388.49 | 13.88% | 2.19%/yr | 1.89 | 260 | 1.05% | 11.7499 | 13.2190 | FAIL |
| Maximum 30% | +$1,036.19 | +$379.16 | +$1,388.49 | 13.88% | 2.19%/yr | 1.89 | 260 | 1.05% | 11.7499 | 13.2190 | FAIL |

## Frozen Gate

- Every disjoint era remained profitable: `true`
- Center continuous net improved by `2.61%` versus the required `2%`: `PASS`
- Center CAGR improved by `0.05` point versus the required `0.04`: `PASS`
- Center was no worse in both disjoint eras: `FAIL` (`-$1.61` in 2015-2018)
- Center PF/recovery/return-DD were all required to be no worse: `FAIL` (return/DD fell from `13.1429` to `12.7568`)
- Center drawdown could rise at most `0.05` point: `FAIL` (`+0.06`, from `1.05%` to `1.11%`)
- Passing neighbors: `0/3`; required: `2/3`

## Interpretation

The `18%` guard improved the headline and the weaker 2019-2020 era, but the result is not a stable plateau. The `12%` neighbor sacrificed too much activity and return/drawdown, while the `24%` and `30%` rows improved continuous net by only `0.62%`, below the frozen `1%` support floor. The center also missed the older-era, drawdown, and return-efficiency gates.

The first parallel batch preserved two report-identity refusals. An unchanged single-worker recovery then produced all 15 exact reports with zero identity failures. The threshold is not moved after observation, newer data stays unopened, and the current same-side cooldown historical leader remains unchanged. Real-account trading remains disabled.
