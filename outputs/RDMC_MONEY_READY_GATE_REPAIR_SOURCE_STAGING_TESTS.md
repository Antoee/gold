# RDMC Money-Ready Gate-Repair Source-Staging Tests

**PASS. Four scenarios preserve the exact-source, hard-lock, compiled-artifact, and no-launch boundaries.**

- Exact source staged on four workers: `PASS`
- Idempotent stage: `PASS`
- Noncanonical source rejected: `PASS`
- Nonallowlisted worker rejected: `PASS`
- Existing EX5 and identity artifacts unchanged: `PASS`
- MT5 launched: `False`

| Scenario | Expected | Actual | Pass |
|---|---|---|---:|
| already_staged_plan | ALREADY_STAGED_OFFLINE_LOCKED | ALREADY_STAGED_OFFLINE_LOCKED | True |
| idempotent_locked_stage | ALREADY_STAGED_OFFLINE_LOCKED | ALREADY_STAGED_OFFLINE_LOCKED | True |
| noncanonical_source | REJECTED | REJECTED | True |
| nonallowlisted_worker | REJECTED | REJECTED | True |
