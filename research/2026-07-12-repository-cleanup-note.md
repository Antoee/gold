# Repository Cleanup Note

Date: 2026-07-12

## Result

The latest cleanup pass archived generated MT5 runtime/package artifacts while keeping the current best profile, evidence summaries, research notes, and canonical EA source visible.

Final cleanup dry run:

- Active generated cleanup candidates: `0`
- Workspace items: about `4,286`
- Workspace size: about `91.66 MB`
- `work/`: about `4.16 MB`
- `outputs/`: about `17.21 MB`
- `archive/`: about `69.38 MB`

## Archived

- Latest generated MT5 package folders:
  - block-reason diagnostics
  - month-filter bypass probe
  - March/May risk-shape Model4 probe
  - LowATR OrderFlow continuous check
- Latest generated MT5 compile logs
- Latest generated compact tester `.mq5` sources
- Bulky raw block-reason diagnostics CSV

The latest expanded archive folder was compressed to:

`archive/generated_artifacts_20260712_212028.zip`

## Kept Visible

- Current promoted profile:
  - `outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`
- Current best profile status:
  - `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- Latest summarized evidence CSVs
- Human research notes
- Canonical EA source:
  - `Professional_XAUUSD_EA.mq5`

## Safety

After cleanup:

- MT5 local safety audit: `PASS`, `39 / 39`
- MT5 local launch lock: on
- MT5 tester processes: none detected
