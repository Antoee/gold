# 2026-07-14 DGF Loss-Block Research Note

The no-cushion DGF loss block is the first range-elite follow-up today that survived a Model4 real-tick check with a meaningful stability improvement.

## What Improved

- `cush50_dgflossblock` improved Model4 broad-window total from `+$2,770.74` to `+$2,800.21`.
- Its worst broad-window loss improved from `-$38.49` to `-$7.36`.
- `cush35_dgflossblock` made all six broad windows green, with worst window `+$0.68`.

## Why It Is Not Trade Ready

- Worst drawdown is still about `20.8%`.
- Trade counts are very small in several yearly windows.
- The all-green variant has tiny margins in 2019, 2025, and 2026 YTD.
- There is no Monte Carlo, broker-variation, forward/demo, or second-broker evidence for these profiles yet.

## Next Useful Work

Test drawdown reduction around the new loss-block lead, then require full exported report stats, trade/deal logs, stress testing, broker-proxy evidence, and forward evidence before considering any live-money pathway.
