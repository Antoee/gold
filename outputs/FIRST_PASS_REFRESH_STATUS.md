# First-Pass Refresh Status

Offline refresh only. This does not launch MT5.

- Overall first-pass decision: **PENDING**
- Parsed reports: `0 / 22`
- Missing reports: `22`
- Unparsed reports: `0`
- Evidence integrity: **PENDING**
- Trusted decision: **PENDING**
- Next selected configs: `4`
- Packaged configs: `4`
- Parallel lanes: `4`
- Parallel lane configs: `4`

## Candidate Recommendations

| Candidate | Evidence | Raw Recommendation | Trusted Recommendation | Parsed | Fail Gates | Pending Gates |
| --- | --- | --- | --- | ---: | ---: | ---: |
| `trade_ready_conservative` | PENDING | WAIT_FOR_REPORTS | WAIT_FOR_TRUSTED_EVIDENCE | 0/22 | 0 | 21 |

## Next Batch

| Candidate | State | Parsed/Expected | Next Phase | Batch Rows |
| --- | --- | ---: | --- | ---: |
| `trade_ready_conservative` | RUN_NEXT_STAGE | 0/22 | Fast Model1 sanity | 4 |

## Files

- Decision: `outputs\FIRST_PASS_VALIDATION_QUEUE_DECISION.md`
- Candidate ranking: `outputs\FIRST_PASS_VALIDATION_QUEUE_CANDIDATE_RANKING.csv`
- Evidence integrity: `outputs\FIRST_PASS_EVIDENCE_INTEGRITY.md`
- Trusted decision: `outputs\FIRST_PASS_TRUSTED_DECISION.md`
- Next batch: `outputs\FIRST_PASS_NEXT_RUN_BATCH.md`
- Next package: `outputs\FIRST_PASS_NEXT_RUN_PACKAGE.md`
