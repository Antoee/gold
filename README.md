# Professional XAUUSD EA

Research project for a professional-grade MetaTrader 5 Expert Advisor focused on XAUUSD / Gold.

This is not a martingale, grid, averaging-down, or recovery-system bot. The goal is to keep risk control first while iteratively improving profit through local MT5 Strategy Tester validation, out-of-sample checks, and walk-forward style gates.

## Latest Status

Last updated: 2026-07-12.

## Start Here

This README is the project status dashboard. If you want updates without asking Codex, read these sections in order:

1. `Latest Status` tells you the current best profile and the headline numbers.
2. `Latest Validation` shows what is proven, what is only partial, and what still needs another test.
3. `Evidence Files` points to the exact CSV and research-note files behind the numbers.
4. `Next Research Gates` shows what should happen next before any new profile is trusted.

Short version: the current research-best is much better than the old `$866` result, but the near-`$10k` result is still a research result, not a live-trading promise.

Current research-best profile:

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_NO_M1SHOCK_PROFILE.set`
- Builder: `work/build_score7_regime_no_m1shock_profile.ps1`
- SHA-256: `0961BBC9C17C122A5DD67498F8BAE2D12241CFCCC8AD3910F6C8BEE2B2FB960A`
- Research note: `research/2026-07-12-score7-regime-no-m1shock-promotion-note.md`

Important clarification: the current best has a near `$10k` Model=1 research result, but it is not fully cross-model confirmed yet.

- Higher-fidelity `Model=1` continuous result: `+$9,753.58`
- Model=0 confirmation result: `+$1,288.93`, exactly equal to the prior Score7 profile on the tested windows
- Test window: `2024.01.01` to `2026.07.12`
- That is about 2.5 years, not exactly 2 years.
- Previous Score7 best on the same `Model=1` gate: `+$7,970.70`
- Previous robust pre-Score7 best on the same gate: `+$7,210.30`
- Fast-model result from the previous gate: `+$9,512.09`, but `Model=1` is the number to trust more.
- Latest `Model=2` check is clean only after disabling the M1 spread-shock guard: no-M1-shock parsed `6 / 6` windows and beat Score7 on continuous and full 2024.
- Initial `Model=4` real-tick probe was neutral: no-m1-shock matched Score7 exactly on full 2024, full 2025, and 2026 YTD, with no losing sampled windows.

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

Cross-model confirmation:

| Model | Status | Key Result |
| --- | --- | --- |
| `Model=1` | Best current evidence | No-M1-shock Regime improved continuous 2024-2026 from `+$7,970.70` to `+$9,753.58` |
| `Model=0` | Neutral confirmation | Regime and Score7 were exactly equal on all tested windows |
| `Model=2` | Clean no-M1-shock confirmation | No-M1-shock parsed 6/6 windows and improved continuous from `+$9,862.76` to `+$12,054.55` |
| `Model=4` | Initial real-tick probe | No-M1-shock and Score7 were equal on full 2024, full 2025, and 2026 YTD |

Latest `Model=2` no-M1-shock rows:

| Profile | Parsed Windows | Continuous 2024-2026 | Full 2024 | Worst Parsed Window |
| --- | ---: | ---: | ---: | ---: |
| Score7 | `6 / 6` | `+$9,862.76` | `+$3,082.89` | `+$161.23` |
| No-M1-Shock Regime | `6 / 6` | `+$12,054.55` | `+$3,890.81` | `+$161.23` |

The previous strict Regime profile failed some Model=2 windows because MT5 Open Prices mode does not allow the M1 data request used by the M1 spread-shock guard. The promoted no-M1-shock profile removes that validation problem without reducing Model=1 profit.

Initial `Model=4` real-tick probe:

| Window | Score7 | No-M1-Shock Regime | Delta |
| --- | ---: | ---: | ---: |
| Full 2024 | `+$1,425.73` | `+$1,425.73` | `0.00` |
| Full 2025 | `+$214.30` | `+$214.30` | `0.00` |
| 2026 YTD | `+$955.21` | `+$955.21` | `0.00` |

This is not proof of the extra edge, but it is a no-damage higher-fidelity check.

## Evidence Files

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `outputs/MODEL1_SCORE7_COST_STRESS_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_QTR_LOG_RESULTS.csv`
- `outputs/MODEL0_SCORE7_REGIME_CONFIRM_LOG_RESULTS.csv`
- `outputs/MODEL2_SCORE7_REGIME_CONFIRM_LOG_RESULTS.csv`
- `outputs/MODEL2_SCORE7_REGIME_CONFIRM_LOG_SUMMARY.csv`
- `outputs/MODEL2_SCORE7_REGIME_NO_M1SHOCK_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_NO_M1SHOCK_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_NO_M1SHOCK_QTR_LOG_RESULTS.csv`
- `outputs/MODEL4_SCORE7_VS_NO_M1SHOCK_PROBE_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_TRADE_DIAG_SUMMARY.csv`
- `research/2026-07-12-score7-regime-guard-promotion-note.md`
- `research/2026-07-12-score7-regime-no-m1shock-promotion-note.md`
- `research/2026-07-12-score7-regime-no-m1shock-realtick-probe-note.md`
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

The current promoted profile then disables only the M1 spread-shock guard. This kept the same `Model=1` broad and quarter results, while allowing a clean `Model=2` validation that improved continuous profit from `+$9,862.76` to `+$12,054.55` versus Score7.

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
- Spread-regime guard is enabled in the current research-best; M1 spread-shock guard is disabled because it created Model=2 validation incompatibility without adding Model=1 profit.
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
5. Treat `Model=1` results as more trustworthy, but still not a production guarantee.
6. If a result says partial, missing, or `NO_REPORT`, do not treat it as a real confirmation.

## Current Confidence

Current profile confidence: research-best candidate.

What is strong:

- The `Model=1` improvement is real inside that test model.
- The trade-log diagnostic reproduced the `+$1,782.88` delta with the same `63` entries.
- Quarter validation did not get worse.
- Model=0 did not show damage.

What is not strong enough yet:

- Model=0 did not confirm the extra near-`$10k` edge.
- Strict Regime did not complete cleanly in Model=2, but the promoted no-M1-shock Regime profile did.
- Initial real-tick probe did not confirm extra edge; it only showed no damage on the sampled windows.
- The local EA source is ahead of the GitHub EA source; GitHub currently has the research status, not necessarily every local code change.

Bottom line: keep testing before raising risk or treating this as production-ready.

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

1. Expand real-tick validation beyond the first three-window probe before raising risk.
2. Inspect trade-level logs to understand why the spread-regime guard improves the Model=1 continuous path but is neutral in Model=0 and Model=4.
3. Continue looking for profit lanes that add trades without creating losing windows.
4. Keep rejected high-profit variants documented so they are not accidentally re-promoted.
5. Eventually sync the full local EA source to GitHub once normal git authentication is available; the local EA source is ahead of the GitHub source.
