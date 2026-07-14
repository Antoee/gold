# First-Pass Refresh Status

Offline refresh only. This does not launch MT5.

- Overall first-pass decision: **FAIL**
- Parsed exported reports: `0 / 22`
- Parsed tester-log rows: `1 / 22`
- Missing reports: `21`
- Unparsed reports: `0`
- Evidence integrity: **PENDING**
- Trusted decision: **PENDING**
- Next selected configs: `0`
- Packaged configs: `0`
- Parallel lanes: `0`
- Parallel lane configs: `0`

## Candidate Recommendations

| Candidate | Evidence | Raw Recommendation | Trusted Recommendation | Parsed | Fail Gates | Pending Gates |
| --- | --- | --- | --- | ---: | ---: | ---: |
| `lowatr_locked_risk18pure` | FAIL | REJECT_FIRST_PASS | WAIT_FOR_TRUSTED_EVIDENCE | 1/22 | 2 | 13 |

## Next Batch

| Candidate | State | Parsed/Expected | Next Phase | Batch Rows |
| --- | --- | ---: | --- | ---: |
| `lowatr_locked_risk18pure` | STOP_FAILED | 1/22 |  | 0 |

## Files

- Decision: `outputs\FIRST_PASS_VALIDATION_QUEUE_DECISION.md`
- Candidate ranking: `outputs\FIRST_PASS_VALIDATION_QUEUE_CANDIDATE_RANKING.csv`
- Evidence integrity: `outputs\FIRST_PASS_EVIDENCE_INTEGRITY.md`
- Trusted decision: `outputs\FIRST_PASS_TRUSTED_DECISION.md`
- Next batch: `outputs\FIRST_PASS_NEXT_RUN_BATCH.md`
- Next package: `outputs\FIRST_PASS_NEXT_RUN_PACKAGE.md`
