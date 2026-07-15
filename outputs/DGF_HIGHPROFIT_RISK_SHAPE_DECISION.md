# DGF High-Profit Risk-Shape Decision

Generated after a current-source hidden local Model4 continuous screen. This is research evidence only and does not approve real-money trading.

## Verdict

**Rejected for promotion. No new money-ready or stability-best profile.**

The profitable DGF continuous branch was worth testing because `lossblock_highprofit_peaktrail_off` made `+$1,915.83` on continuous 2019-2026 Model4, but its `24.58%` drawdown was too high. This probe tested whether simple risk shaping could keep the edge while cutting drawdown.

The answer was no.

## Results

| Candidate | Net | Ann. %/yr | CAGR % | PF | Trades | DD % | Recovery | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `dgf_hp_control` | `+$1,915.83` | `25.45` | `15.28` | `1.72` | `127` | `24.58` | `2.02` | Keep as high-profit research reference only. |
| `dgf_hp_peaktrail_35p70gb` | `+$1,915.83` | `25.45` | `15.28` | `1.72` | `127` | `24.58` | `2.02` | No effect versus control. |
| `dgf_hp_risk080_loss_scale` | `+$238.06` | `3.16` | `2.88` | `1.24` | `101` | `20.13` | `0.76` | Rejected: too little profit for too much drawdown. |
| `dgf_hp_peaktrail_20p70gb` | `+$75.90` | `1.01` | `0.98` | `1.14` | `35` | `22.26` | `0.25` | Rejected: profit lock kills profit but not drawdown. |
| `dgf_hp_risk080` | `-$63.91` | `-0.85` | `-0.87` | `0.92` | `84` | `32.47` | `-0.18` | Rejected. |
| `dgf_hp_risk080_peaktrail_20p70gb` | `-$63.91` | `-0.85` | `-0.87` | `0.92` | `84` | `32.47` | `-0.18` | Rejected. |
| `dgf_hp_risk070` | `-$96.99` | `-1.29` | `-1.35` | `0.87` | `84` | `32.73` | `-0.28` | Rejected. |
| `dgf_hp_risk080_dd12` | `-$96.91` | `-1.29` | `-1.35` | `0.57` | `20` | `15.49` | `-0.59` | Rejected: drawdown cap truncates into loss. |
| `dgf_hp_risk060` | `-$117.89` | `-1.57` | `-1.65` | `0.84` | `91` | `32.18` | `-0.34` | Rejected. |
| `dgf_hp_risk060_loss_scale` | `-$124.07` | `-1.65` | `-1.74` | `0.82` | `93` | `27.50` | `-0.44` | Rejected. |
| `dgf_hp_risk050` | `-$158.03` | `-2.10` | `-2.26` | `0.78` | `92` | `31.26` | `-0.48` | Rejected. |

## Interpretation

Simple risk reduction did not scale the control curve down; it changed the trade path into losing or weak variants. The late `35%/70%` profit lock had no effect, while the `20%/70%` profit lock reduced profit to almost nothing without solving drawdown. The only non-control profitable risk-shaped variant, `dgf_hp_risk080_loss_scale`, made just `+$238.06` with `20.13%` drawdown and recovery `0.76`, so it fails the efficiency goal.

This means the DGF high-profit branch should remain a high-profit research reference only. It is not a good route to a money-ready profile through simple risk scaling, loss scaling, drawdown caps, or late global profit locks.

## Evidence

- Package: `outputs/DGF_HIGHPROFIT_RISK_SHAPE_PACKAGE.md`
- Run status: `outputs/DGF_HIGHPROFIT_RISK_SHAPE_CURRENT_SOURCE_STATUS.md`
- Metrics: `outputs/DGF_HIGHPROFIT_RISK_SHAPE_METRICS.md`
- Results CSV: `outputs/DGF_HIGHPROFIT_RISK_SHAPE_RESULTS.csv`
- Source hash: `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A`

## Safety

After the run:

- MT5 local safety audit: `PASS`, `44 / 44`
- MT5 hard local launch lock restored
- No MT5/MetaEditor process remained running

## Next

Do not spend more Model4 time on simple risk-shaping variants of this profile. The next useful work should be new strategy behavior: entry selectivity, exit quality, or a different lower-drawdown branch that already survives older out-of-sample windows.
