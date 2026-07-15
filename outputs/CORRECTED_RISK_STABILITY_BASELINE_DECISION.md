# Corrected-Risk Stability Baseline Decision

## Verdict

**Accepted as the current low-drawdown research baseline. Not money-ready.**

Profile: `outputs/CANDIDATE_BROKER_ACCURATE_STABILITY_BASELINE.set`

Profile SHA-256: `4D0B808BE07BF6612C70F96E4287717F3C7A8370B9089B165D71A244C3EA8E89`

Source SHA-256: `3C738B730A47A089ECE11A53EC9E726DE2E64B63E53866B9731253C5035A114C`

## Evidence

Model1 on `$10,000`:

- Continuous net: `+$328.58`
- Total return: `+3.29%`
- Annualized return: `0.44%/yr`
- Profit factor: `2.81`
- Trades: `28`
- Max drawdown: `0.82%`
- Losing yearly windows: `0 / 8`

Model4 real ticks on `$10,000`:

- Continuous net: `+$211.37`
- Total return: `+2.11%`
- Annualized return: `0.28%/yr`
- CAGR: `0.28%`
- Profit factor: `2.12`
- Expected payoff: `$8.13`
- Win rate: `50.00%`
- Trades: `26`
- Max drawdown: `0.82%`
- Recovery factor: `2.51`

## Interpretation

This is the first current-source profile to combine broker-accurate risk sizing, no losing fast yearly windows, positive continuous Model4 real-tick performance, and sub-`1%` drawdown. It is also much too sparse and slow-growing for real-money release. A `0.28%/yr` historical return does not justify execution, model, and future-regime risk.

Do not raise risk merely to manufacture a larger dollar headline. Future work must add a robust source of trade opportunity or improve expectancy while preserving older-year stability. Any change must repeat the broad-window gate before Model4.

Evidence: `outputs/STABILITY_REBASE_PROBE_RESULTS.csv`, `outputs/STABILITY_REBASE_PROBE_SUMMARY.csv`, `outputs/STABILITY_REBASE_PROBE_METRICS.md`, and `outputs/STABILITY_REALTICK_PROBE_RESULTS.csv`.
