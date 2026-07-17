# Clean Model4 Three-Lane Portfolio Decision

**Decision: REJECT_SCREEN.**

This preregistered screen uses three exact MT5 Model 4 trade streams. It is an analytical implementation gate, not a combined-EA backtest, a replacement for the frozen forward demo, or live approval.

- Grid rows: `36`; row-eligible: `10`
- Center: `dd_0.10_rv_0.45_mom_0.15`; eligible: `False`
- Donchian-weight neighbors passing: `1 / 3` (required 2)
- Structural neighbors passing: `3 / 7` (required 4)
- Shared open-risk cap: `0.75%`
- Trades: Donchian `51`, reversion `48`, momentum `314`

## Center Versus Identical Two-Lane Benchmark

| Metric | Three lanes | Two lanes | Change |
|---|---:|---:|---:|
| Net profit | $2,400.22 | $2,289.01 | +4.86% |
| Profit factor | 1.582 | 1.605 | -0.023 |
| Risk-floor drawdown | 3.56% | 3.62% | -0.06 pp |
| Closed trades | 413 | 362 | +51 |
| Red years | 1 | 2 | -1 |
| 0.05R net | $1,951.59 | $1,874.49 | +4.11% |
| 0.10R net | $1,519.14 | $1,473.90 | +3.07% |
| Return / drawdown | 6.74 | 6.32 | +0.42 |

## Stream Relationships

| Left | Right | Monthly R correlation | Same-side entries | Overlaps | Opposite overlaps |
|---|---|---:|---:|---:|---:|
| donchian | momentum | 0.0347 | 0 | 84 | 10 |
| donchian | reversion | -0.0719 | 0 | 10 | 4 |
| momentum | reversion | 0.0048 | 0 | 2 | 2 |

## Frozen Neighborhood

| Profile | Eligible | Net | PF | DD | Added trades | Base / 0.05R / 0.10R increment | Red years |
|---|---|---:|---:|---:|---:|---:|---:|
| `dd_0.15_rv_0.45_mom_0.15` | True | $2,455.47 | 1.572 | 3.53% | 51 | +7.3% / +6.1% / +4.6% | 1 |
| `dd_0.10_rv_0.40_mom_0.15` | True | $2,194.23 | 1.557 | 3.21% | 51 | +5.2% / +4.5% / +3.4% | 1 |
| `dd_0.10_rv_0.45_mom_0.10` | True | $2,182.71 | 1.669 | 3.41% | 51 | +5.3% / +4.4% / +3.1% | 2 |
| `dd_0.10_rv_0.45_mom_0.20` | False | $2,620.07 | 1.524 | 3.71% | 51 | +4.5% / +3.9% / +3.5% | 1 |
| `dd_0.10_rv_0.45_mom_0.15` | False | $2,400.22 | 1.582 | 3.56% | 51 | +4.9% / +4.1% / +3.1% | 1 |
| `dd_0.10_rv_0.50_mom_0.15` | False | $2,609.05 | 1.606 | 3.90% | 51 | +4.5% / +3.8% / +2.8% | 1 |
| `dd_0.05_rv_0.45_mom_0.15` | False | $2,344.73 | 1.593 | 3.59% | 51 | +2.4% / +2.1% / +1.5% | 1 |

## Interpretation

The preregistered center or neighborhood failed. Do not implement or tune this allocation after seeing the result; retain the files as rejected diversification evidence.

Real-account trading remains disabled.
