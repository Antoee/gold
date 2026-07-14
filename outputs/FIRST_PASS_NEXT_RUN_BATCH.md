# First-Pass Next Run Batch

Offline selector only. This does not launch MT5.

- Queue manifest: `outputs\FIRST_PASS_VALIDATION_QUEUE.csv`
- Results source: `outputs\FIRST_PASS_VALIDATION_QUEUE_RESULTS.csv`
- Selected configs: `0`
- Rule: run one stage at a time and re-import reports before advancing; within fast Model1, run the continuous check before the yearly fast checks.
- Early stop: parsed rows must include PF, expected payoff, Sharpe, win rate, trades, max consecutive losses, drawdown %, and recovery factor. Fast Model1 continuous must clear annualized return >= 8% and return/DD >= 1.5; exact real-tick continuous must clear annualized return >= 12%, CAGR >= 10%, return/DD >= 3, worst parsed DD <= 6%, PF >= 1.2, and recovery >= 1.25.

## Candidate Status

| Candidate | State | Parsed/Expected | Next Phase | Batch Rows | Reason |
| --- | --- | ---: | --- | ---: | --- |
| `lowatr_locked_risk18pure` | STOP_FAILED | 1/22 |  | 0 | rank 1 DD 7.33% above 6% |

## Selected Configs

No configs selected. Either first-pass is complete or all remaining candidates hit an early-stop failure.

After the selected reports are exported, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File work\import_first_pass_validation_queue_reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File work\select_first_pass_next_run_batch.ps1
```
