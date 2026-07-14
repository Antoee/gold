# LowATR Exit Sweep Summary

Generated after hidden local MT5 Model1 fast screens on 2026-07-14. MT5 did not export full HTML reports, so results were imported from tester logs. Log evidence is enough to reject or continue a fast screen, but exported full reports are still required before promotion.

## Decision

No new trade-ready best was promoted.

The best headline-profit exit tweak was `lowatr_exit_mfe_early`, which made `+$9,274.07` from 2024-01-01 to 2026-07-12 on a `$1,000` start. That is stronger than the raw locked LowATR screen, but drawdown stayed at `25.99%`, so it remains research-only.

The best under-6% drawdown candidate was `lowatr_exit_peak_r20`, which made `+$464.86` with `5.81%` drawdown, PF `6.789`, recovery `5.1411`, Sharpe `6.7419`, and `7` trades on the continuous fast Model1 screen. It then stayed green on the yearly Model1 splits, but the 2025 split was too weak: `+$21.17`, recovery `0.4178`, and only `4` trades. Because of that weak broad-window quality, it is not promoted.

## Key Results

| Candidate | Window | Net | Ann. Return % | CAGR % | PF | DD % | Trades | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `lowatr_exit_mfe_early` | continuous_2024_2026 | `9274.07` | `366.99` | `151.40` | `2.9140` | `25.99` | `64` | Reject for trade-ready: drawdown too high |
| `lowatr_exit_loss_scale` | continuous_2024_2026 | `8998.14` | `356.07` | `148.71` | `2.9164` | `25.91` | `65` | Reject for trade-ready: drawdown too high |
| `lowatr_exit_peak_guard` | continuous_2024_2026 | `3412.46` | `135.04` | `79.93` | `4.8249` | `22.63` | `25` | Reject for trade-ready: drawdown too high |
| `lowatr_exit_peak_r50` | continuous_2024_2026 | `1152.51` | `45.61` | `35.44` | `4.5478` | `14.53` | `7` | Reject: drawdown too high and sparse |
| `lowatr_exit_peak_r30` | continuous_2024_2026 | `630.58` | `24.95` | `21.35` | `5.5464` | `8.74` | `7` | Reject: drawdown above 6% and sparse |
| `lowatr_exit_peak_r25` | continuous_2024_2026 | `517.03` | `20.46` | `17.93` | `5.8846` | `7.28` | `7` | Reject: drawdown above 6% and sparse |
| `lowatr_exit_peak_r20` | continuous_2024_2026 | `464.86` | `18.40` | `16.31` | `6.7890` | `5.81` | `7` | Advanced to yearly split check, then rejected for weak 2025 quality |

## Yearly Check For `lowatr_exit_peak_r20`

| Window | Net | Ann. Return % | CAGR % | PF | DD % | Recovery | Trades | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `2024_full` | `464.86` | `46.52` | `46.52` | `6.7890` | `5.81` | `5.1411` | `7` | Pass fast screen |
| `2025_full` | `21.17` | `2.12` | `2.12` | `1.6271` | `4.90` | `0.4178` | `4` | Reject: weak recovery and too sparse |
| `2026_ytd` | `192.28` | `36.58` | `39.73` | `5.4284` | `4.88` | `3.3135` | `14` | Pass fast screen |

## Readout

The exit/risk sweep improved the efficiency frontier, but not enough for real-money readiness:

- High-profit variants still carry roughly `22%` to `26%` drawdown.
- Hard drawdown caps protect the account but reduce the strategy to about one trade and tiny profit.
- The only under-6% continuous candidate is profitable but sparse and has a weak 2025 split.

Next useful work is strategy-level trade quality, not more blind risk scaling. The bot needs a way to add/keep good trades in weak years without reintroducing the high-drawdown path.
