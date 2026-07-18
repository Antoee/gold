# RDMC Strategy Rewrite Escalation Policy Tests

**PASS. Ten checks bind the candidate test budget to deterministic settings-versus-code decisions.**

- Decision checkpoints: `2,6,8,12,24` valid reports
- Hard Wave 1 performance failure: `CODE_REWRITE`
- Wave 1 activity-only exception: `ONE NEW-IDENTITY ONE-FACTOR REPAIR`
- Valid Waves 2-5 failure: `CODE_REWRITE`
- Same-identity metric rerun: `FORBIDDEN`
- Invalid-evidence rerun: `ALLOWED`
- MT5 launched: `False`

| Check | Pass | Evidence |
|---|---:|---|
| five-wave-shape | True | rows=5; waves=1,2,3,4,5 |
| cumulative-test-budget | True | cumulative=2,6,8,12,24 |
| same-identity-metric-reruns-forbidden | True | Every valid metric failure rejects the frozen identity. |
| invalid-evidence-reruns-allowed | True | Evidence defects may be repaired without misclassifying strategy performance. |
| wave-one-single-activity-exception | True | Exactly one one-factor activity-only repair is possible under a new identity. |
| later-waves-force-code-rewrite | True | Waves 2-5 do not permit settings-only rescue. |
| real-tick-substitution-forbidden | True | Model1 cannot replace Model4 evidence. |
| broad-era-deletion-forbidden | True | All broad eras remain mandatory. |
| posthoc-calendar-blocks-forbidden | True | Calendar exclusions require independent evidence, not one or two losses. |
| no-mt5-launch | True | MT5-family processes before/after: 0/0. |
