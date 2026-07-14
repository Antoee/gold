# Peak R20 R10 Drawdown Sweep Package

Offline package builder only. This does not launch MT5.

- Base profile: `outputs\lowatr_r20_opportunity_sweep_package\profiles\peak_r20_no_peaktrail_r10.set`
- Source hash: `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`
- Base profile hash: `16330F4C03B53EC4B9CF6E50A0D00038315CA5904529AEF3F284223B173CF3B9`
- Model: `1`
- Variants: `22`

## Hypotheses

- `r10_base`: Baseline aggressive R10 frontier for direct same-package comparison.
- `r10_minfloor02`: Test the intended low-risk month multipliers by lowering the hidden minimum reduced risk floor.
- `r10_minfloor05`: Moderate minimum risk-floor correction, especially for August and risk-reduced states.
- `r10_minfloor10`: Keep global risk near the named R10 setting while allowing month and loss reductions to work.
- `r10_eqgb_q15_12_18`: Soft equity-peak giveback quality gate after a 15 percent giveback from peak profit.
- `r10_eqgb_q20_12_18`: Less sensitive equity-peak giveback quality gate for drawdown control without early choking.
- `r10_eqgb_q10_10_16`: Earlier but lighter equity-peak giveback quality gate.
- `r10_realgb_q15_12_18`: Realized-profit giveback quality gate so the EA must earn higher quality after giving back closed profit.
- `r10_realgb_q20_12_18`: Less sensitive realized-profit giveback quality gate.
- `r10_bothgb_q15`: Combine equity-peak and realized-profit soft gates at the same thresholds.
- `r10_loss_scale_25`: Enable daily, weekly, and monthly loss scaling with earlier throttling.
- `r10_loss_scale_15`: More aggressive loss scaling to determine whether drawdown can be cut without stopping trade flow.
- `r10_floor10_loss25`: Risk-floor correction plus moderate loss scaling.
- `r10_floor05_loss25`: Lower risk floor plus moderate loss scaling, checking whether this becomes too defensive.
- `r10_floor10_eqgb`: Risk-floor correction plus equity-peak soft gate.
- `r10_floor05_eqgb`: Lower risk floor plus equity-peak soft gate.
- `r10_may260_floor10`: Trim May risk slightly while fixing the hidden risk floor.
- `r10_may240_floor10`: Trim May risk more noticeably while fixing the hidden risk floor.
- `r10_aug25_floor05`: Use a corrected low risk floor but restore some August participation.
- `r10_profit_guard40`: Harder period profit giveback guard as a drawdown-control benchmark.
- `r10_eqlock4_50`: Account-level profit lock benchmark, likely conservative but useful as a safety bound.
- `r10_dailytrail35`: Daily equity trail guard benchmark for intraday giveback control.

## Files

- Queue manifest: `outputs\PEAK_R20_DRAWDOWN_SWEEP_QUEUE.csv`
- Runner manifest: `outputs\PEAK_R20_DRAWDOWN_SWEEP_PACKAGE_MANIFEST.csv`
- Package dir: `outputs\peak_r20_drawdown_sweep_package`
