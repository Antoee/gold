# Professional XAUUSD EA

This deliverable is a modular MT5 XAUUSD Expert Advisor research project. The goal is to maximize profit while keeping risk controls, start-date robustness, and no-martingale/no-grid/no-averaging-down constraints intact.

## Key Files

- `BACKTEST_RESULTS.md` - current validation notes.
- `NEXT_VALIDATION_QUEUE.md` - queued candidates and validation status.
- `NEXT_VALIDATION_RUNBOOK.md` - validation workflow.
- `PROMOTION_GATE_REPORT.md` - offline promotion readiness check.
- `PROFILE_INPUT_AUDIT.md` - `.set` input audit.
- `VALIDATION_REPORT_METRICS.md` - standard exported-report parser status.
- `PROFIT_SEARCH_REPORT_METRICS.md` - profit-search exported-report parser status.
- `work/generated_profit_search/PROFIT_SEARCH_PROFILES.csv` - generated profit-search candidate list.

## Current Promoted Defaults

The current promoted defaults prioritize start-date robustness over maximum historical profit.

Latest real-tick validation:

- Full period `2024.01.01` to `2026.07.02`: `+$866.59` from `$1,000`.
- Monthly validation: `+$744.03`, worst month `$0.00`, 0 losing months.
- Quarterly validation: `+$744.03`, worst quarter `$0.00`, 0 losing quarters.
- Split validation: `+$2,354.65`, worst split window `$0.00`, 0 losing windows.

The previous date-block benchmark made more historical profit, but it used date-specific filters and had many losing monthly windows, so it remains benchmark-only.

## Profit Search Pack

A controlled profit-search pack was generated under `work/generated_profit_search/`.

- 16 candidate `.set` profiles around the current robust no-date BOS/sweep profile.
- 128 phase-1 fast triage configs using `Model=2`.
- 55 phase-2 real-tick validation configs using `Model=4`.

Phase 1 is only for speed. A candidate still needs real-tick validation and promotion-gate approval before it can replace the promoted profile.

## Local MT5 Safety

Local MT5 launch is hard-locked because `terminal64.exe` can still flash and steal focus on this PC. Local launch requires both:

- `ALLOW_MT5_FOCUS_RISK=1`
- `work\ALLOW_MT5_LOCAL_LAUNCH.unlock`

Do not run local MT5 validation until the hidden-desktop runner has been deliberately verified.

## Validation Workflow

1. Export MT5 Strategy Tester reports.
2. Parse reports with the offline collectors.
3. Review profit, drawdown, profit factor, and recovery factor.
4. Rerun profile input audit.
5. Rerun promotion gate.
6. Promote only candidates that improve profit without bringing back losing robustness windows.
