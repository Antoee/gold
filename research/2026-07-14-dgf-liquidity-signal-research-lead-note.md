# 2026-07-14 DGF Liquidity-Signal Research Lead Note

The new DGF liquidity-signal rejection switch improved the range-elite research shape, but it did not make the bot trade-ready.

What improved:

- `re_may140_late15_dgf_liq_reject1` made `+$3,218.26` across six Model4 yearly/YTD windows.
- Worst broad-window loss improved to `-$40.20`.
- 2021 improved from `-$62.11` to `-$16.27`.
- 2023 improved from `+$157.60` on the late15-only variant to `+$441.77`.
- The run parsed `30 / 30` exported MT5 reports with no log-only rows.

What still fails:

- 2019, 2021, and 2025 are still red.
- Worst drawdown is still `24.72%`.
- 2026 YTD stays much lower than plain `re_may140` because the late15 pure-DGF guard removes a large winner.
- The remaining losing trades are mostly pure DGF failures, not the DGF plus liquidity-sweep hybrid that this switch was meant to filter.

Conclusion:

This is a useful research lead, not a stability lead. Keep the code switch default-off and continue with pure-DGF quality/risk diagnostics before any promotion attempt.
