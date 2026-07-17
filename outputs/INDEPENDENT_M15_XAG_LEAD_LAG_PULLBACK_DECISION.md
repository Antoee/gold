# Independent M15 XAG Lead-Lag Pullback Decision

## Decision

**Rejected. The four-bar lead result reproduced, but it was an isolated parameter point. No new best, continuous test, recent-data test, or Model4 promotion was opened.**

The initial 16-shape discovery screen produced one numeric pass: `xmll_lead4`. It made `+$42.08` in 2015-2017 and `+$135.46` in 2018-2020, with PF `1.13` and `1.50` on `75` and `76` trades. A frozen 2-7 bar support test reproduced those numbers exactly, but lead 3 lost `-$45.42` across the two restart windows and lead 5 lost `-$59.30`. Neither adjacent value passed either era, so the preregistered neighborhood requirement failed.

## Evidence Contract

- Source SHA-256: `AC1B533EBCBBB42505589DEAD08A11143C88B3FB13A11C57AB4BB96F06F8F21F`
- Compile: `0 errors, 0 warnings` in both controlled runs
- Model1 reports: `44/44` parsed (`32` discovery plus `12` neighborhood)
- Windows: `2015-2017` and `2018-2020`
- Post-2020 strategy rows: `0`
- Model4 rows: `0`
- XAGUSD synchronized-history minimum alignment, 2015-2020: `99.9101%`
- XAGUSD 32-bar-lookback readiness minimum, 2015-2020: `100%`
- Risk per accepted trade: `0.10%`; minimum-lot overflow is rejected; real-account trading defaults off.

## Gate Result

- Initial numeric gate passes: `1/16`
- Adjacent lead-3/lead-5 gate passes: `0/2`
- Final promotion gate passes: `0`

| Candidate | Phase | Lead bars | 2015-2017 net | Annualized | PF | Trades | 2018-2020 net | Annualized | PF | Trades | Decision |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `xmll_lead4` | Discovery | 4 | +$42.08 | 0.14% | 1.13 | 75 | +$135.46 | 0.45% | 1.50 | 76 | `REJECTED_ISOLATED_LOOKBACK` |
| `xmll_xag125` | Discovery | 8 | +$47.05 | 0.16% | 1.18 | 59 | -$32.76 | -0.11% | 0.90 | 75 | `REJECTED_BROAD_ERAS` |
| `xmll_lead5` | Neighborhood | 5 | -$25.83 | -0.09% | 0.94 | 85 | -$33.47 | -0.11% | 0.92 | 87 | `REJECTED_BROAD_ERAS` |
| `xmll_lead3` | Neighborhood | 3 | -$9.06 | -0.03% | 0.98 | 78 | -$36.36 | -0.12% | 0.90 | 79 | `REJECTED_BROAD_ERAS` |
| `xmll_lead7` | Neighborhood | 7 | -$41.02 | -0.14% | 0.92 | 106 | -$2.62 | -0.01% | 0.99 | 99 | `REJECTED_BROAD_ERAS` |
| `xmll_tp200` | Discovery | 8 | -$61.72 | -0.21% | 0.87 | 89 | -$51.16 | -0.17% | 0.89 | 105 | `REJECTED_BROAD_ERAS` |
| `xmll_lead6` | Neighborhood | 6 | -$39.13 | -0.13% | 0.92 | 96 | -$61.94 | -0.21% | 0.85 | 93 | `REJECTED_BROAD_ERAS` |
| `xmll_no_range` | Discovery | 8 | -$40.28 | -0.13% | 0.94 | 137 | -$68.15 | -0.23% | 0.89 | 144 | `REJECTED_BROAD_ERAS` |
| `xmll_xaumax100` | Discovery | 8 | -$80.41 | -0.27% | 0.87 | 121 | -$79.03 | -0.26% | 0.87 | 134 | `REJECTED_BROAD_ERAS` |
| `xmll_lead2` | Neighborhood | 2 | -$81.72 | -0.27% | 0.75 | 64 | -$87.77 | -0.29% | 0.69 | 53 | `REJECTED_BROAD_ERAS` |
| `xmll_tol020` | Discovery | 8 | -$90.00 | -0.30% | 0.83 | 103 | -$81.63 | -0.27% | 0.85 | 119 | `REJECTED_BROAD_ERAS` |
| `xmll_tol000` | Discovery | 8 | -$90.54 | -0.30% | 0.79 | 83 | -$66.97 | -0.22% | 0.84 | 98 | `REJECTED_BROAD_ERAS` |
| `xmll_lead12` | Discovery | 12 | -$90.55 | -0.30% | 0.80 | 91 | +$44.97 | 0.15% | 1.11 | 95 | `REJECTED_BROAD_ERAS` |
| `xmll_gap050` | Discovery | 8 | -$96.26 | -0.32% | 0.78 | 84 | -$44.15 | -0.15% | 0.89 | 97 | `REJECTED_BROAD_ERAS` |
| `xmll_xaumax050` | Discovery | 8 | -$100.70 | -0.34% | 0.70 | 62 | -$30.78 | -0.10% | 0.88 | 59 | `REJECTED_BROAD_ERAS` |
| `xmll_gap020` | Discovery | 8 | -$119.52 | -0.40% | 0.75 | 89 | -$66.91 | -0.22% | 0.86 | 105 | `REJECTED_BROAD_ERAS` |
| `xmll_base` | Discovery | 8 | -$119.52 | -0.40% | 0.75 | 89 | -$66.91 | -0.22% | 0.86 | 105 | `REJECTED_BROAD_ERAS` |
| `xmll_tp125` | Discovery | 8 | -$124.88 | -0.42% | 0.73 | 89 | -$60.49 | -0.20% | 0.87 | 105 | `REJECTED_BROAD_ERAS` |
| `xmll_no_slope` | Discovery | 8 | -$159.87 | -0.53% | 0.71 | 102 | +$11.64 | 0.04% | 1.02 | 122 | `REJECTED_BROAD_ERAS` |
| `xmll_lead16` | Discovery | 16 | -$165.04 | -0.55% | 0.57 | 66 | -$36.23 | -0.12% | 0.91 | 91 | `REJECTED_BROAD_ERAS` |
| `xmll_xag075` | Discovery | 8 | -$199.97 | -0.67% | 0.68 | 117 | -$101.36 | -0.34% | 0.83 | 131 | `REJECTED_BROAD_ERAS` |

Aggregate validation scores add restart windows only for comparison; they are not sequential account returns.

## Interpretation

The delayed silver-lead idea was materially better than the earlier XAU/XAG fade and same-bar continuation families, but its edge existed only at exactly four M15 bars. A one-bar change on either side turned both eras negative. That sensitivity is classic parameter instability, so opening newer data would reward overfitting rather than test a robust hypothesis.

This completes three distinct XAG-based families without a supported promotion. Further near-term research should move away from XAG as the primary signal source.
