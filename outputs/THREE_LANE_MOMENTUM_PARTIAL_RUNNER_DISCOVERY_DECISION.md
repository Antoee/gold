# Momentum Partial-Runner Discovery Decision

**Decision: REJECTED IN DISCOVERY. No Model 4 run, promotion, forward change, or real trading is permitted. NO NEW BEST.**

- Exact accepted Model 1 reports: `24/24`; preserved identity refusals: `2`; successful exact recoveries: `2`
- Source SHA-256: `1092D9AD0036C6C4E7A0F61CB7318B31CDCE75F9311762388CF256AFFB6BFEA9`
- EX5 SHA-256: `8B72A5B1457BCBF79118381AA5F2F8B1D709DA703611BE60778C4DB518DCD130`
- Manifest SHA-256: `81D2138F43F8B4B7B24BDD75036CA4B87AD27A9ADF2495E9AEDBA014D121505A`
- Test contract: XAUUSD M15, `$10,000`, Model 1, frozen pre-2021 discovery.
- Initial entries and risk were unchanged. Unsplittable positions retained the exact 2R baseline exit.

| Candidate | Close | Target | Lock | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | 60% | 4R | 1.25R | +$1,036.19 | +$370.60 | +$1,379.93 | 2.18%/yr | 1.88 | 261 | 1.05% | 11.6775 | 13.1429 | CONTROL |
| **60% / 4R / +1.25R center** | 60% | 4R | 1.25R | +$990.43 | +$421.64 | +$1,373.21 | 2.17%/yr | 1.89 | 313 | 1.11% | 11.0609 | 12.3694 | False |
| mopr_close50 | 50% | 4R | 1.25R | +$988.15 | +$419.57 | +$1,369.24 | 2.16%/yr | 1.88 | 313 | 1.11% | 11.0289 | 12.3333 | False |
| mopr_close70 | 70% | 4R | 1.25R | +$1,029.93 | +$431.72 | +$1,418.87 | 2.24%/yr | 1.91 | 313 | 1.08% | 11.7866 | 13.1389 | True |
| mopr_target300 | 60% | 3R | 1.25R | +$953.81 | +$397.81 | +$1,321.28 | 2.09%/yr | 1.85 | 314 | 1.12% | 10.6426 | 11.7946 | False |
| mopr_target500 | 60% | 5R | 1.25R | +$1,020.02 | +$457.17 | +$1,426.64 | 2.25%/yr | 1.91 | 314 | 1.11% | 11.4913 | 12.8559 | True |
| mopr_lock100 | 60% | 4R | 1R | +$960.29 | +$434.59 | +$1,362.76 | 2.15%/yr | 1.89 | 313 | 1.14% | 10.766 | 11.9561 | False |
| mopr_lock150 | 60% | 4R | 1.5R | +$1,013.20 | +$431.98 | +$1,410.33 | 2.22%/yr | 1.91 | 313 | 1.09% | 11.561 | 12.9358 | False |

## Frozen Gate

- Disabled control reproduced the exact prior 2015-18 and 2019-20 results: `True`
- Every report profitable: `True`
- Center partial path active: `True`
- Center gate pass: `False`
- Passing neighbors: `2/6`; required: `4/6`

## Interpretation

The frozen center reduced continuous net from `+$1,379.93` to `+$1,373.21`. It also missed the older-era floor and the 95% recovery and return/drawdown floors. The increased report-trade count (`261` to `313`) confirms that the partial-close path executed.

Only the 70% close and 5R target neighbors passed their training gates. They are not promoted or called a new best. Any interaction follow-up must be separately frozen and judged on post-2020 holdout data without changing this rejection.

The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo is not forward evidence, the registered candidate is unchanged, and real-account trading remains disabled.
