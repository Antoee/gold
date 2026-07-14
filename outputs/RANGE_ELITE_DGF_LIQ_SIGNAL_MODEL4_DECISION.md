# Range-Elite DGF Liquidity-Signal Model4 Decision

Date: 2026-07-14

Verdict: **RESEARCH LEAD ONLY, NOT TRADE-READY**

This run tested a strategy-code change that is materially different from the earlier `re_blockliq` probe. The old probe only removed the diagnostic-fallback confirmation when a liquidity sweep was already present; it did not reject the trade if liquidity sweep alone could still pass the confirmation threshold. The new default-off switch can reject the whole weak DGF plus liquidity-sweep signal when liquidity sweep is the only pre-DGF confirmation.

## Source And Compile Evidence

- EA source hash: `69478904BB4073F48F8F963ED13D789BFE378456D4C054CAB16A8368F4065D92`
- Root/mirror source sync: `PASS`
- Exposed MT5 tester inputs: `313 / 1000`
- Static preflight: `STATIC_MQL_COMPILE_PREFLIGHT_PASS checks=33 inputs=313`
- Hidden compile proof: `outputs/MT5_HIDDEN_COMPILE_DGF_LIQ_SIGNAL_REJECT.log`
- Compile result: `0 errors, 0 warnings`

The source adds these default-off inputs:

- `InpDiagnosticFallbackRejectLiquiditySweepSignal`
- `InpDiagnosticFallbackLiquidityRejectMaxConfirmations`

When enabled, the guard rejects a DGF plus liquidity-sweep setup only if the existing pre-DGF confirmation count is at or below the configured cap. This is intended to filter weak single-confirmation sweep/fallback hybrids while preserving stronger confluence setups.

## Model4 Evidence

- Package: `outputs/RANGE_ELITE_DGF_LIQ_SIGNAL_MODEL4_PACKAGE.md`
- Queue: `outputs/RANGE_ELITE_DGF_LIQ_SIGNAL_MODEL4_QUEUE.csv`
- Run CSV: `outputs/RANGE_ELITE_DGF_LIQ_SIGNAL_MODEL4_RUN.csv`
- Results: `outputs/RANGE_ELITE_DGF_LIQ_SIGNAL_MODEL4_RESULTS.csv`
- Metrics: `outputs/RANGE_ELITE_DGF_LIQ_SIGNAL_MODEL4_REPORT_METRICS.md`
- Trade diagnostic: `outputs/RANGE_ELITE_DGF_LIQ_SIGNAL_TRADE_DIAGNOSTIC.csv`
- Model: `4` real ticks
- Windows: `2019`, `2021`, `2023`, `2024`, `2025`, `2026 YTD`
- Exported reports parsed: `30 / 30`
- Log-only rows: `0`

## Candidate Summary

| Candidate | Total Net | Worst Window | Worst DD % | Trades | Decision |
| --- | ---: | ---: | ---: | ---: | --- |
| `re_may140` | `+$3,166.19` | `-$140.18` | `24.28` | `41` | Prior risk-shape baseline, rejected |
| `re_may140_late15_pure` | `+$3,108.10` | `-$62.11` | `24.72` | `26` | Rejected: lower total, still red |
| `re_dgf_liq_reject1` | `+$3,165.42` | `-$112.47` | `27.87` | `56` | Rejected: DD worse, still red |
| `re_may140_dgf_liq_reject1` | `+$3,049.74` | `-$83.32` | `24.28` | `47` | Rejected: lower total, still red |
| `re_may140_late15_dgf_liq_reject1` | `+$3,218.26` | `-$40.20` | `24.72` | `30` | Best research shape in this package, not stable enough |

## Best Variant Detail

`re_may140_late15_dgf_liq_reject1` is the best research result from this run. It improved total net versus `re_may140`, reduced the worst broad-window loss from `-$140.18` to `-$40.20`, and turned 2023 strongly positive. It still fails the stability gate because 2019, 2021, and 2025 remain red, and worst drawdown is still high at `24.72%`.

| Window | Net | Annualized Return % | PF | Trades | DD % |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2019 | `-$40.20` | `-4.03` | `0.00` | `1` | `4.02` |
| 2021 | `-$16.27` | `-1.63` | `0.72` | `2` | `16.98` |
| 2023 | `+$441.77` | `44.33` | `4.36` | `8` | `20.78` |
| 2024 | `+$2,366.15` | `236.78` | `5.66` | `7` | `14.51` |
| 2025 | `-$5.55` | `-0.56` | `0.88` | `2` | `13.03` |
| 2026 YTD | `+$472.36` | `89.86` | `2.32` | `10` | `24.72` |

## Trade Diagnostic

The new guard did what it was designed to do: it removed the weak DGF plus liquidity-sweep hybrid pattern that was damaging 2021 and 2023. The remaining losses are different:

- 2019: one pure DGF August short loss.
- 2021: one pure DGF March short loss after one PXEA liquidity-sweep winner.
- 2025: one small pure DGF March buy loss after one small DGF winner.
- 2026 YTD: still includes one large late PXEA liquidity-sweep loss, outside the DGF guard's scope.

That means the next useful work is not another DGF-liquidity switch. The remaining blocker is pure DGF quality and high drawdown, especially protecting against isolated DGF candle failures without deleting the profitable March/May 2024-2026 engine.

## Decision

Keep the default-off code switch and the package evidence. Do not mark this money-ready and do not replace the stability lead. This is a better range-elite research shape, but it still fails the broad-window no-red-year rule and drawdown is far above the trade-ready target.
