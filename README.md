# Professional XAUUSD EA

Research project for a professional-grade MetaTrader 5 Expert Advisor focused on XAUUSD / Gold.

This is not a martingale, grid, averaging-down, or recovery-system bot. The goal is to keep risk control first while iteratively improving profit through local MT5 Strategy Tester validation, out-of-sample checks, and walk-forward style gates.

## Latest Status

Last updated: 2026-07-12.

Current research-best profile:

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_score7_regime_profile.ps1`
- SHA-256: `7BD4019104BCDF117A7D729289D6821D5F4BF6FB6FF9FE2D543BCF91717DC204`
- Research note: `research/2026-07-12-score7-regime-guard-promotion-note.md`

Important clarification: the current best has a near `$10k` Model=1 research result, but it is not fully cross-model confirmed yet.

- Higher-fidelity `Model=1` continuous result: `+$9,753.58`
- Model=0 confirmation result: `+$1,288.93`, exactly equal to the prior Score7 profile on the tested windows
- Test window: `2024.01.01` to `2026.07.12`
- That is about 2.5 years, not exactly 2 years.
- Previous Score7 best on the same `Model=1` gate: `+$7,970.70`
- Previous robust pre-Score7 best on the same gate: `+$7,210.30`
- Fast-model result from the previous gate: `+$9,512.09`, but `Model=1` is only one validation view, not a production guarantee.

## Latest Validation

Broad `Model=1` validation:

| Window | Previous Score7 Best | Current Regime Best |
| --- | ---: | ---: |
| Full 2024 | `+$2,507.85` | `+$3,201.96` |
| Full 2025 | `+$214.18` | `+$214.18` |
| 2026 YTD | `+$1,375.04` | `+$1,375.04` |
| Continuous 2024-2026 | `+$7,970.70` | `+$9,753.58` |

Quarter `Model=1` gate:

| Metric | Previous Score7 Best | Current Regime Best |
| --- | ---: | ---: |
| Quarter total | `+$3,638.18` | `+$3,638.18` |
| Worst quarter | `-$0.50` | `-$0.50` |
| Losing quarters | `1` | `1` |
| Main improvement | none in reset quarters | continuous equity path improved |

Model=0 confirmation:

| Window | Previous Score7 Best | Current Regime Best |
| --- | ---: | ---: |
| Continuous 2024-2026 | `+$1,288.93` | `+$1,288.93` |
| Full 2024 | `+$1,425.73` | `+$1,425.73` |
| Full 2025 | `+$214.30` | `+$214.30` |
| 2026 YTD | `+$1,375.36` | `+$1,375.36` |
| 2025 Q4 | `+$196.16` | `+$196.16` |
| 2024 Q4 | `-$4.55` | `-$4.55` |

Trade-log diagnosis:

- Score7 entries: `63`
- Regime entries: `63`
- Score7 closed profit: `7970.70`
- Regime closed profit: `9753.58`
- Delta: `1782.88`
- First material divergence: August 2024
- Interpretation: the Regime guard changed trade timing/path, not trade count. The edge is real inside Model=1 but still model-sensitive because Model=0 stayed neutral.

Evidence files:

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `outputs/MODEL1_SCORE7_COST_STRESS_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_QTR_LOG_RESULTS.csv`
- `outputs/MODEL0_SCORE7_REGIME_CONFIRM_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_TRADE_DIAG_SUMMARY.csv`
- `research/2026-07-12-score7-regime-guard-promotion-note.md`
- `research/2026-07-12-score7-regime-model0-confirmation-note.md`
- `research/2026-07-12-score7-regime-trade-diagnosis-note.md`

## What Changed Recently

The promoted change raises the In-Session Liquidity Pullback lane minimum score:

- Old: `InpInSessionLiquidityPullbackMinScore=6`
- New: `InpInSessionLiquidityPullbackMinScore=7`

This made the ISLP lane more selective. It improved the continuous `Model=1` result without hurting full 2024, full 2025, 2026 YTD, or any quarter in the quarter gate.

The higher-profit `risk045_tp150` variant reached `+$8,112.91` on continuous `Model=1`, but it reduced full 2024 from `+$2,507.85` to `+$2,209.66`, so it was rejected instead of promoted.

The newest promoted change enables strict spread-regime and M1 spread-shock guards:

- `InpUseSpreadRegimeGuard=true`
- `InpMaxSpreadRegimeRatio=1.35`
- `InpMinSpreadRegimePoints=30.0`
- `InpUseM1SpreadShockGuard=true`
- `InpM1SpreadShockMaxRatio=1.60`
- `InpM1SpreadShockMinPoints=35.0`

This improved continuous `Model=1` validation from `+$7,970.70` to `+$9,753.58` without changing the quarter gate.

A follow-up Model=0 confirmation was neutral: the Regime profile and prior Score7 profile were exactly equal on continuous, full-year, YTD, and Q4 windows. That means the Regime change has not shown extra cross-model damage, but the near-`$10k` edge should still be treated as Model=1-specific research evidence.

A trade-log diagnostic confirmed the Model=1 delta is real inside that test model: both profiles took `63` entries, but the Regime profile changed timing around August 2024 and improved the continuous result by `+$1,782.88`. The edge is still model-sensitive because Model=0 stayed neutral.

## Strategy Direction

Current architecture direction:

- Adaptive Reverse remains disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement stays enabled as a tightly gated, low-risk opportunity lane.
- Flat Month Micro Reversion is active only in July and October at reduced risk.
- Range Elite Micro Reversion stays as a low-frequency range-opportunity lane.
- MFE Failure Exit is active only in March after the all-month version was rejected.
- In-Session Liquidity Pullback is active only in June, October, November, and December.
- Spread-regime and M1 spread-shock guards are enabled in the current research-best.
- Liquidity-aware structural stops are preferred over pure ATR-only stop placement where possible.

## Risk Rules

Hard rules for this project:

- No martingale.
- No grid.
- No averaging down.
- No unrealistic recovery systems.
- Do not promote a change just because one backtest makes more money.
- Prefer changes that improve profit without increasing drawdown, weak windows, or hidden fragility.
- Keep every major feature configurable and independently testable.

## How To Read Updates

To see the current state without asking Codex:

1. Open `outputs/CURRENT_RESEARCH_BEST_PROFILE.md` for the latest promoted research-best.
2. Open the latest `research/YYYY-MM-DD-*.md` note for why it was promoted or rejected.
3. Check `outputs/*LOG_RESULTS.csv` for the actual parsed MT5 tester results.
4. Treat fast-model numbers as rough scouting only.
5. Treat `Model=1` results as useful research evidence, but not a production guarantee.

## GitHub Actions

GitHub Actions should not be used for heavy optimization right now because the monthly Actions quota is limited.

The workflow should remain manual-only. Heavy MT5 testing is intended to run locally or on a separate machine/VPS, not through GitHub Actions.

## Background Testing Safety

Local MT5 testing should use the hidden/background launch path only. Do not run tester sessions that pop windows, steal focus, or interfere with normal PC use.

After any local MT5 run, the safety lock should be restored:

- `work/MT5_LOCAL_LAUNCH_DISABLED.lock`

The latest local safety audit passed:

- Checks: `39`
- Passed: `39`
- Failed: `0`

## Next Research Gates

Next useful work:

1. Run another independent source/model validation before raising risk.
2. Try a controlled spread-timing variant only if independent validation confirms the August-style timing advantage.
3. Continue looking for profit lanes that add trades without creating losing windows.
4. Keep rejected high-profit variants documented so they are not accidentally re-promoted.
5. Eventually sync the full local EA source to GitHub once normal git authentication is available; the local EA source is ahead of the GitHub source.
