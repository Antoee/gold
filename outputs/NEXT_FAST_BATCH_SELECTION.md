# Next Fast Batch Selection

Offline selector only. No MT5 process was launched.

| Recommendation | Gate | Priority | Rows | Status | Manifest | Reason | Next Action |
|---|---|---:|---:|---|---|---|---|
| RUN_NEXT_FAST_BATCH | STRESS_SMOKE | 1 | 2 | WAITING_FOR_REPORTS | `outputs\stress_smoke_handoff\HANDOFF_MANIFEST.csv` | This is the first pending gate in priority order. Running it avoids spending time on lower-priority batches too early. | Run/import the 2-row stress smoke reports first. |

## Bottom Line

Run only this next batch in a non-interrupting MT5 environment, export the reports, then rerun `work/import_all_available_reports.ps1` before choosing another batch.
