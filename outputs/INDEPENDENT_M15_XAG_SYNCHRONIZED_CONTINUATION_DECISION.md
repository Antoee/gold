# Independent M15 XAG Synchronized-Continuation Decision

## Decision

**Rejected. No new best, no continuous test, no recent-data test, and no Model4 promotion.**

The broker-data hypothesis was feasible, but the trading hypothesis was not: every one of the 16 nearby shapes lost money in both disjoint three-year eras. Drawdown remained below the 5% research ceiling because risk was small, but no profile reached PF 1.10 in both eras.

## Evidence Contract

- Source SHA-256: `53D4864FDBA2365193AA9D7AC1185B1B9CD2BFA3CC34453D18AF3A8DD8552D88`
- Compile: `0 errors, 0 warnings`
- Model1 reports: `32/32` parsed
- Windows: `2015-2017` and `2018-2020`
- Post-2020 strategy rows: `0`
- Model4 rows: `0`
- XAGUSD synchronized-history minimum alignment, 2015-2020: `99.9101%`
- XAGUSD 32-bar-lookback readiness minimum, 2015-2020: `100%`
- Risk per accepted trade: `0.10%`; minimum-lot overflow is rejected; real-account trading defaults off.

## Gate Result

- Profitable in both eras: `0/16`
- PF at least 1.10 in both eras: `0/16`
- Full discovery gate passes: `0/16`

| Candidate | 2015-2017 net | Annualized | PF | Trades | 2018-2020 net | Annualized | PF | Trades | Worst era | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `xmsc_move24` | -$120.51 | -0.40% | 0.78 | 119 | -$136.94 | -0.46% | 0.85 | 206 | -$136.94 | `REJECTED_BROAD_ERAS` |
| `xmsc_move32` | -$172.95 | -0.58% | 0.67 | 111 | -$158.71 | -0.53% | 0.82 | 192 | -$172.95 | `REJECTED_BROAD_ERAS` |
| `xmsc_buffer000` | -$176.49 | -0.59% | 0.76 | 161 | -$179.90 | -0.60% | 0.84 | 246 | -$179.90 | `REJECTED_BROAD_ERAS` |
| `xmsc_buffer010` | -$125.88 | -0.42% | 0.77 | 124 | -$194.47 | -0.65% | 0.79 | 192 | -$194.47 | `REJECTED_BROAD_ERAS` |
| `xmsc_tp200` | -$162.03 | -0.54% | 0.75 | 141 | -$202.37 | -0.68% | 0.80 | 212 | -$202.37 | `REJECTED_BROAD_ERAS` |
| `xmsc_move075` | -$159.85 | -0.53% | 0.74 | 134 | -$206.16 | -0.69% | 0.79 | 206 | -$206.16 | `REJECTED_BROAD_ERAS` |
| `xmsc_breakout40` | -$108.30 | -0.36% | 0.72 | 85 | -$212.40 | -0.71% | 0.71 | 152 | -$212.40 | `REJECTED_BROAD_ERAS` |
| `xmsc_breakout28` | -$106.09 | -0.35% | 0.77 | 106 | -$213.77 | -0.71% | 0.75 | 184 | -$213.77 | `REJECTED_BROAD_ERAS` |
| `xmsc_move8` | -$218.81 | -0.73% | 0.57 | 105 | -$192.34 | -0.64% | 0.78 | 184 | -$218.81 | `REJECTED_BROAD_ERAS` |
| `xmsc_corr050` | -$191.40 | -0.64% | 0.69 | 135 | -$220.33 | -0.73% | 0.77 | 204 | -$220.33 | `REJECTED_BROAD_ERAS` |
| `xmsc_breakout16` | -$226.69 | -0.76% | 0.73 | 181 | -$65.71 | -0.22% | 0.94 | 260 | -$226.69 | `REJECTED_BROAD_ERAS` |
| `xmsc_base` | -$182.87 | -0.61% | 0.72 | 141 | -$231.39 | -0.77% | 0.77 | 212 | -$231.39 | `REJECTED_BROAD_ERAS` |
| `xmsc_corr020` | -$148.90 | -0.50% | 0.77 | 144 | -$244.54 | -0.82% | 0.76 | 215 | -$244.54 | `REJECTED_BROAD_ERAS` |
| `xmsc_move025` | -$206.48 | -0.69% | 0.69 | 144 | -$254.15 | -0.85% | 0.75 | 218 | -$254.15 | `REJECTED_BROAD_ERAS` |
| `xmsc_breakout12` | -$270.27 | -0.90% | 0.73 | 215 | -$66.23 | -0.22% | 0.95 | 281 | -$270.27 | `REJECTED_BROAD_ERAS` |
| `xmsc_tp125` | -$154.49 | -0.52% | 0.76 | 141 | -$275.81 | -0.92% | 0.72 | 212 | -$275.81 | `REJECTED_BROAD_ERAS` |

The aggregate column in the CSV is a validation score only; the two windows restart from the same deposit and are not an achievable sequential account return.

## Interpretation

The result rejects this specific **same-direction XAU/XAG move plus fresh XAU channel breakout** implementation. It does not prove cross-metal data is useless; it shows that this synchronized continuation condition had negative expectancy across both development eras under the frozen stop and risk contract.

Any future cross-metal hypothesis must be treated as a new family with a new frozen contract. These losses cannot be converted into evidence for an inverted or selectively retuned strategy.
