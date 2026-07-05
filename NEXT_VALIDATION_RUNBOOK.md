# Next Validation Runbook

No MT5 process should be launched from this workspace until the hidden-desktop launcher is deliberately verified. Local launch is hard-locked in the shared launcher and all legacy MT5 runner scripts. It requires both `ALLOW_MT5_FOCUS_RISK=1` and an explicit `work\ALLOW_MT5_LOCAL_LAUNCH.unlock` file.

## Prepared Validation Pack

Generated configs live under:

- `work/generated_validation/`

The standard pack contains 196 configs: 49 windows for each queued candidate plus the current promoted baseline.

## Profit Search Pack

Additional profit-search configs live under:

- `work/generated_profit_search/`

This pack searches for more profit around the current robust no-date BOS/sweep profile while preserving the no-martingale, no-grid, no-averaging-down rules.

It contains:

- 16 candidate `.set` profiles.
- 128 phase-1 fast triage configs using `Model=2`.
- 55 phase-2 real-tick validation configs using `Model=4`.

Phase 1 is only a cheap pruning pass. Never promote from phase 1 alone. Any candidate that looks better must pass phase-2 real ticks and then the full promotion gate.

## Promotion Gate

A candidate should not replace the promoted profile unless it improves profit while preserving the no-loss robustness target:

- Full-period net profit greater than `+$866.59`.
- Split aggregate greater than `+$2,354.65`.
- Monthly/quarter aggregate greater than `+$744.03`.
- Worst monthly, quarterly, and split window at least `$0.00`.
- Zero losing monthly, quarterly, and split windows.
- Drawdown and profit factor must be reviewed from exported MT5 reports.

## After Running

1. Export MT5 report files into `outputs/`.
2. Rerun `work/collect_validation_results.ps1` for the standard validation pack.
3. Rerun the profit-search collector command locally for `work/generated_profit_search/PROFIT_SEARCH_CONFIG_MANIFEST.csv`.
4. Rerun `work/analyze_robust_candidates.ps1`.
5. Rerun `work/analyze_loss_control.ps1`.
6. Rerun `work/analyze_promotion_gate.ps1`.
7. Rerun `work/audit_profile_inputs.ps1` before trusting any changed `.set` file.
8. Promote only if all profit, no-loss, drawdown/profit-factor, promotion-gate, and profile-input checks pass.
