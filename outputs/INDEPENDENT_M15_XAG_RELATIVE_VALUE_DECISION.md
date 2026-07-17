# Independent M15 XAG Relative-Value Decision

## Decision

**Rejected. No new best, no continuous test, no recent-data test, and no Model4 promotion.**

The broker-data hypothesis was feasible, but the trading hypothesis was not: every one of the 16 nearby shapes lost money in both disjoint three-year eras. Most profiles eventually reached the 5% research drawdown guard, and no profile reached PF 1.10 in both eras.

## Evidence Contract

- Source SHA-256: `F79BED792F6F2D961181C9A8B0BC9297F5EC41039A816B492CA4CAF442749657`
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
| `xmrv_move32` | -$454.82 | -1.52% | 0.66 | 244 | -$478.06 | -1.59% | 0.76 | 380 | -$478.06 | `REJECTED_BROAD_ERAS` |
| `xmrv_move8` | -$489.81 | -1.63% | 0.65 | 270 | -$393.96 | -1.31% | 0.75 | 276 | -$489.81 | `REJECTED_BROAD_ERAS` |
| `xmrv_move12` | -$429.41 | -1.43% | 0.51 | 156 | -$489.90 | -1.63% | 0.63 | 233 | -$489.90 | `REJECTED_BROAD_ERAS` |
| `xmrv_tp200` | -$454.12 | -1.51% | 0.73 | 330 | -$491.16 | -1.64% | 0.71 | 305 | -$491.16 | `REJECTED_BROAD_ERAS` |
| `xmrv_xau040` | -$483.43 | -1.61% | 0.73 | 363 | -$495.53 | -1.65% | 0.69 | 293 | -$495.53 | `REJECTED_BROAD_ERAS` |
| `xmrv_turn010` | -$493.58 | -1.65% | 0.72 | 346 | -$497.68 | -1.66% | 0.70 | 302 | -$497.68 | `REJECTED_BROAD_ERAS` |
| `xmrv_corr050` | -$498.17 | -1.66% | 0.72 | 358 | -$496.68 | -1.66% | 0.70 | 296 | -$498.17 | `REJECTED_BROAD_ERAS` |
| `xmrv_base` | -$500.03 | -1.67% | 0.73 | 367 | -$496.24 | -1.66% | 0.70 | 298 | -$500.03 | `REJECTED_BROAD_ERAS` |
| `xmrv_xau000` | -$500.70 | -1.67% | 0.74 | 378 | -$488.19 | -1.63% | 0.71 | 305 | -$500.70 | `REJECTED_BROAD_ERAS` |
| `xmrv_div150` | -$477.96 | -1.59% | 0.68 | 286 | -$501.92 | -1.67% | 0.64 | 241 | -$501.92 | `REJECTED_BROAD_ERAS` |
| `xmrv_tp125` | -$500.26 | -1.67% | 0.73 | 368 | -$502.36 | -1.68% | 0.69 | 296 | -$502.36 | `REJECTED_BROAD_ERAS` |
| `xmrv_no_turn` | -$503.10 | -1.68% | 0.45 | 152 | -$492.42 | -1.64% | 0.74 | 348 | -$503.10 | `REJECTED_BROAD_ERAS` |
| `xmrv_div075` | -$475.89 | -1.59% | 0.63 | 240 | -$504.59 | -1.68% | 0.63 | 241 | -$504.59 | `REJECTED_BROAD_ERAS` |
| `xmrv_move24` | -$403.00 | -1.34% | 0.58 | 167 | -$505.79 | -1.69% | 0.70 | 305 | -$505.79 | `REJECTED_BROAD_ERAS` |
| `xmrv_corr020` | -$506.44 | -1.69% | 0.73 | 377 | -$494.61 | -1.65% | 0.70 | 298 | -$506.44 | `REJECTED_BROAD_ERAS` |
| `xmrv_div125` | -$507.08 | -1.69% | 0.69 | 324 | -$497.93 | -1.66% | 0.66 | 260 | -$507.08 | `REJECTED_BROAD_ERAS` |

The aggregate column in the CSV is a validation score only; the two windows restart from the same deposit and are not an achievable sequential account return.

## Interpretation

The result rejects this specific **fade-the-XAU/XAG-divergence** implementation. It does not prove cross-metal data is useless; it shows that buying XAU underperformance and selling XAU outperformance after a one-bar reversal had negative expectancy across both development eras under the frozen stop and risk contract.

A future cross-metal continuation hypothesis must be treated as a new family with a new frozen contract. These results may motivate it, but they cannot be relabeled as support for an inverted strategy.
