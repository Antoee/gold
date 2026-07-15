# R10 Activity Probe Decision

Generated after the current-source hidden local fast screen. This is research evidence only and does not approve real-money trading.

## Verdict

**Rejected for promotion. No new best.**

The current-source R10 activity probe rebuilt the package on source hash `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A` and ran `30 / 30` hidden local MT5 fast Model1 configs. All expected reports exported and parsed.

Every tested overlay tied the control result:

- Total net across the five probe windows: `+$110.19`
- Worst window: 2024 full at `-$45.14`
- Worst annualized return: `-4.52%/yr`
- Worst drawdown: `6.55%`
- Total trades: `21`
- Parsed exported reports: `30 / 30`

## Candidates Tested

- `r10_a7_current`
- `r10_a7_dfg_risk_25_45_50`
- `r10_a7_fmlr_blend`
- `r10_a7_fmlr_tight`
- `r10_a7_dfg_fmlr_blend`
- `r10_a7_dfg_fmlr_tight`

## Decision Notes

The FMLR activity overlays did not add trades, profit, or robustness on the current source. The DFG spread-risk overlay also had no measurable effect in this focused fast screen. Because the current-source package now has a red 2024 window across all variants, none of these profiles should receive Model4 real-tick follow-up or be considered money-ready.

This result weakens the R10 A7 stability branch as a route to a live profile. It remains useful as a low-drawdown research benchmark, but the next useful strategy work should target genuinely new entry/exit behavior or a different stability branch rather than layering the tested FMLR activity overlays onto R10 A7.

## Evidence

- Package: `outputs/R10_ACTIVITY_PROBE_PACKAGE.md`
- Run status: `outputs/R10_ACTIVITY_PROBE_CURRENT_SOURCE_STATUS.md`
- Metrics: `outputs/R10_ACTIVITY_PROBE_METRICS.md`
- Results CSV: `outputs/R10_ACTIVITY_PROBE_RESULTS.csv`
- Safety audit after run: `outputs/MT5_LOCAL_SAFETY_AUDIT.md`

## Safety

After the run:

- MT5 local safety audit: `PASS`, `44 / 44`
- Static MQL preflight: `PASS`, `33` checks, `328` inputs
- Static repo safety audit: `PASS`, `25` checks
- MT5 hard local launch lock restored
- No MT5/MetaEditor process remained running
