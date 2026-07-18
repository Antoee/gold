# RDMC Strategy Rewrite Escalation Policy

**This policy decides when to stop testing settings and change strategy code. It does not create profitability evidence.**

## Decision Budget

The frozen executable queue spends evidence in cumulative checkpoints of `2`, `6`, `8`, `12`, and `24` valid reports. A completed wave that fails its frozen metrics stops every later wave.

- Wave 1 uses two fast Model1 critical-year reports. A hard failure in net profit, profit factor, or drawdown makes the strategy family unfit and requires an entry/regime code rewrite.
- One exception exists: if both critical years pass net profit, profit factor, and drawdown and the **only** failure is minimum activity, one preregistered one-factor activity repair may create a new identity. That repaired identity restarts at Wave 1. A second activity-only failure requires code change.
- Any valid metric failure in Waves 2-5 requires code change. Settings-only rescue is not allowed after broad, real-tick, continuous, or annual robustness failure.
- Missing, corrupt, stale, or identity-mismatched evidence is not a strategy failure. It may be rerun under the same identity after the evidence defect is repaired.

## Rewrite Boundaries

Every settings repair or code rewrite creates a new source/profile/manifest identity and inherits zero reports. It must restart at Wave 1 and pass the same risk-first thresholds.

Post-hoc date, month, weekday, direction, or regime exclusions are forbidden when inferred from one or two losing observations. No losing broad era may be dropped, no Model1 result may substitute for Model4 real ticks, and no threshold may be weakened merely to admit a failed candidate.

| Wave | Valid reports | Cumulative | Valid metric failure | Required response |
|---:|---:|---:|---|---|
| 1 | 2 | 2 | Critical-year failure | Code rewrite, except one activity-only repair under the strict condition above |
| 2 | 4 | 6 | Broad Model1 failure | Rewrite cross-regime architecture |
| 3 | 2 | 8 | Critical real-tick failure | Rewrite tick-sensitive entry, exit, or execution logic |
| 4 | 4 | 12 | Broad/continuous real-tick failure | Rewrite robustness, portfolio interaction, or risk architecture |
| 5 | 12 | 24 | Annual real-tick failure | Rewrite seasonal robustness without calendar curve fitting |

Passing all five waves still does not make the EA money-ready. Executable-ledger cost stress, order-aware Monte Carlo, distinct-broker validation, and valid forward-demo evidence remain mandatory.
