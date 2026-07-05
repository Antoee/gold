# Next Fast Batch Selection

Offline selector only. No MT5 process was launched.

| Recommendation | Gate | Priority | Rows | Status | Manifest | Reason | Next Action |
|---|---|---:|---:|---|---|---|---|
| RUN_NEXT_FAST_BATCH | STRESS_MICRO | 1 | 8 | WAITING_FOR_REPORTS | `outputs\micro_test_handoff\HANDOFF_MANIFEST.csv` | This is the first pending gate in priority order. Running it avoids spending time on lower-priority batches too early. | Run/import stress micro reports first. |

## Bottom Line

Run only this next batch in a non-interrupting MT5 environment, export the reports, then rerun `work/import_all_available_reports.ps1` before choosing another batch.
