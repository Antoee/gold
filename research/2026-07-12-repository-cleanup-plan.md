# Repository Cleanup Plan

Date: 2026-07-12

Status: completed for generated logs and temporary runtime artifacts.

## Goal

Make the repository easier to read without losing evidence needed to understand the current LowATR OrderFlow research result.

## Keep Front And Center

- `README.md`
- `Professional_XAUUSD_EA.mq5`
- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- current promoted `.set` profile files
- current LowATR OrderFlow evidence CSVs
- current stats summary/results CSVs
- research notes that explain promoted/rejected decisions
- safety and hidden-run scripts

## Archive Or Deprioritize

- old generated MT5 package folders
- old compact `.mq5` snapshots that are not tied to the current best
- old run logs and compile logs - completed for active generated logs
- old diagnostic CSVs that are already summarized by research notes
- `outputs/offline_refresh_logs/` - archived

## Do Not Delete Blindly

- any file named in `README.md`
- any file named in `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- any file referenced by a promotion/rejection research note
- safety lock/audit scripts
- builder scripts for current validation packages

## Cleanup Order

1. Finish the LowATR monthly and quarterly tester-stat reruns - done.
2. Sync the new stats evidence to GitHub - done.
3. Create archive folders for generated artifacts - done.
4. Move old logs and temporary local runtime files into archive folders - done.
5. Keep top-level `outputs/` focused on current best, current evidence, and summary CSVs - partial; generated packages remain for reproducibility.
6. Update README evidence links after cleanup - done.

## Starting Inventory Snapshot

- `outputs/`: about `139.72 MB`, mostly generated packages and compact EA snapshots.
- `work/`: about `146.98 MB`, mostly generated local MT5 configs/packages.
- `outputs/offline_refresh_logs/`: `26,528` files, about `22.35 MB`.
- `.log` files: about `26,946` files, about `28.77 MB`.

## Cleanup Result

Completed on 2026-07-12:

- Archived generated runtime artifacts into `archive/generated_artifacts_20260712_171712`, `archive/generated_artifacts_20260712_171802`, and `archive/generated_artifacts_20260712_171857`.
- Archived `26,949` files totaling about `28.85 MB`.
- Removed active `outputs/offline_refresh_logs/`.
- Reduced active generated cleanup candidates to `0`.
- Left only `outputs/MT5_HIDDEN_COMPILE_ISLP_LOWATR_TESTER_STATS.log` as the intentional active compile evidence log.
- MT5 local safety audit after cleanup: `PASS`, `39 / 39`.

Remaining size is mostly generated MT5 package/config folders kept for reproducibility, not runtime log noise.

## Recommended Cleanup Style

Prefer moving to an archive folder first. Delete only after the README/current-best evidence links still work and the safety audit passes.
