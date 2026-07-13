# Repository Cleanup Note

Date: 2026-07-12

Updated: 2026-07-13

## Result

The latest cleanup pass archived generated MT5 runtime/package artifacts while keeping the current best profile, evidence summaries, research notes, active FMLR probe package, and canonical EA source visible.

Final cleanup dry run:

- Active generated cleanup candidates: `0`
- Workspace files: about `4,182`
- Workspace size: about `91.53 MB`
- `work/`: about `4.2 MB`
- `outputs/`: about `19.56 MB`
- `archive/`: about `66.83 MB`

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

The remaining expanded archive folders were compressed and removed on the 2026-07-13 refresh:

- `archive/generated_artifacts_20260712_195604.zip`
- `archive/generated_artifacts_20260712_195805.zip`

## Kept Visible

- Current promoted profile:
  - `outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`
- Current best profile status:
  - `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- Latest summarized evidence CSVs
- Active untested FMLR probe package:
  - `outputs/flat_month_liquidity_reclaim_probe_package`
- Human research notes
- Canonical EA source:
  - `Professional_XAUUSD_EA.mq5`

## Safety

After cleanup:

- MT5 local safety audit: `PASS`, `39 / 39`
- MT5 local launch lock: on
- MT5 tester processes: none detected
