# Next Validation Runbook

No MT5 process should be launched from this workspace until the hidden-desktop launcher is deliberately verified. Local launch now requires both `ALLOW_MT5_FOCUS_RISK=1` and an explicit `work\ALLOW_MT5_LOCAL_LAUNCH.unlock` file.

## Prepared Validation Pack

Generated configs live under:

- `work/generated_validation/risk160_sl16_tp38`
- `work/generated_validation/risk160_sl18_tp38`
- `work/generated_validation/risk160_sl18_tp35_giveback`
- `work/generated_validation/promoted_risk160_sl18_tp35`

Manifest:

- `work/generated_validation/VALIDATION_MANIFEST.csv`

Each profile has:

- 9 split windows: yearly, half-year, 2026 YTD, and full period.
- 10 quarterly windows from 2024 Q1 through 2026 Q2.
- 30 monthly windows from 2024-01 through 2026-06.

## Validation Order

1. `risk160_sl16_tp38`
2. `risk160_sl18_tp38`
3. `risk160_sl18_tp35_giveback`
4. `promoted_risk160_sl18_tp35`

The promoted profile is included as a baseline comparison so reruns can detect history or broker-data changes.

## Promotion Gate

A candidate should not replace the promoted profile unless it improves profit while preserving the no-loss robustness target:

- Full-period net profit greater than `+$866.59`.
- Split aggregate greater than `+$2,354.65`.
- Monthly/quarter aggregate greater than `+$744.03`.
- Worst monthly, quarterly, and split window at least `$0.00`.
- Zero losing monthly, quarterly, and split windows.
- Gross loss across monthly, quarterly, and split windows must be `$0.00`.
- Any date-block or calendar-specific rule stays a benchmark only unless it is replaced by a general market-regime rule.
- Profit giveback variants must prove they reduce losses or preserve zero-loss windows without cutting too much full-period profit.

## Tester Settings

Configs use:

- XAUUSD M15.
- Real ticks, `Model=4`.
- Deposit `$1,000`.
- Leverage `1:100`.
- Visual mode off.
- Dashboard off.
- `OptimizationCriterion=6`, MetaTrader 5 custom max, using the EA `OnTester()` score.

## After Running

1. Export or parse result CSVs.
2. Rerun `work/analyze_robust_candidates.ps1`.
3. Rerun `work/analyze_loss_control.ps1`.
4. Rerun `work/analyze_promotion_gate.ps1`.
5. Rerun `work/audit_profile_inputs.ps1` before trusting any changed `.set` file.
6. Update `ROBUST_CANDIDATE_RANKING.md`, `LOSS_CONTROL_REPORT.md`, `PROMOTION_GATE_REPORT.md`, and `PROFILE_INPUT_AUDIT.md`.
7. Promote only if all profit, no-loss, promotion-gate, and profile-input checks pass.
