# Three-Lane Momentum D1 Strength Gate Discovery Decision

**Decision: REJECTED IN DISCOVERY. Recent confirmation, Model 4, promotion, forward change, and real-account approval are not permitted.**

- Exact reports and identity sidecars: `12/12`
- Source SHA-256: `F405E62145EB3353D26A6EEC9095505AD3E674CB3FB5E4C1F58F0049AE4117D8`
- EX5 SHA-256: `481AA52A07DC1600C79B2411125F4845876F5EF4615A45D3076349F4D675EECD`
- Manifest SHA-256: `CD9933E5BAEF3358BD2C3B2793EABF4A194C07B3DBACAB683076FAAB1FFE8B9C`
- Test basis: `$10,000`, XAUUSD M15, MT5 Model 1, pre-2021 discovery only
- Frozen feature: require the absolute 126-bar D1 close return to exceed `2%`, `4%`, or `6%` before the momentum lane can enter
- Frozen risk: momentum `0.15%`, account-wide open-risk cap `0.75%`, real trading disabled

| Profile | 2015-18 | 2019-20 | 2015-20 | Total return | CAGR | PF | Trades | DD | Recovery | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| **Disabled control** | +$1,036.19 | +$370.60 | **+$1,379.93** | 13.80% | **2.18%/yr** | 1.88 | 261 | 1.05% | **11.6775** | CONTROL |
| Minimum 2% | +$856.19 | +$370.60 | +$1,227.66 | 12.28% | 1.95%/yr | 1.89 | 233 | 1.13% | 10.2767 | FAIL |
| Minimum 4% center | +$758.97 | +$380.62 | +$1,131.34 | 11.31% | 1.80%/yr | 1.89 | 214 | 1.12% | 9.6522 | FAIL |
| Minimum 6% | +$707.03 | +$299.59 | +$1,005.57 | 10.06% | 1.61%/yr | 1.93 | 183 | 1.20% | 7.9725 | FAIL |

## Frozen Gate

- Every disjoint era remained profitable: `true`
- The 4% center needed at least `+2%` continuous improvement; it produced `-18.01%`: `FAIL`
- The 4% center needed at least `+0.04` CAGR point; it produced `-0.38`: `FAIL`
- Both support neighbors needed at least `+1%` continuous improvement; 2% produced `-11.03%` and 6% produced `-27.13%`: `FAIL`
- The center and both neighbors reduced recovery and trade count: `FAIL`

## Interpretation

The feature removed too many profitable breakouts. Its slightly higher continuous PF did not compensate for lower net profit, CAGR, activity, Sharpe ratio, and recovery. The older 2015-2018 era weakened at every enabled threshold, so the family has no robust plateau and is closed without exposing recent data.

The initial parallel batch preserved one report-identity refusal. An unchanged single-worker recovery then produced all 12 exact reports with zero identity failures. The current same-side cooldown historical leader and the frozen forward candidate remain unchanged. Real-account trading remains disabled.
