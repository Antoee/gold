# Professional XAUUSD EA

Research project for a professional-grade MetaTrader 5 Expert Advisor focused on XAUUSD / Gold.

This is not a martingale, grid, averaging-down, or recovery-system bot. The goal is to keep risk control first while iteratively improving profit through local MT5 Strategy Tester validation, out-of-sample checks, and walk-forward style gates.

## Latest Status

Last updated: 2026-07-12.

Current research-best profile:

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_score7_profile.ps1`
- SHA-256: `E36378232B722A2A09C1EFD2494F04385B7020CAE1F1679DDE903E05D8BC12D0`
- Research note: `research/2026-07-12-islp-score7-promotion-note.md`

Important clarification: the current best is about `$8k`, but not exactly over two years.

- Higher-fidelity `Model=1` continuous result: `+$7,970.70`
- Test window: `2024.01.01` to `2026.07.12`
- That is about 2.5 years, not exactly 2 years.
- Previous robust best on the same `Model=1` gate: `+$7,210.30`
- Fast-model result from the previous gate: `+$9,512.09`, but `Model=1` is the number to trust more.

## Latest Validation

Broad `Model=1` validation:

| Window | Previous Robust Best | Current Score7 Best |
| --- | ---: | ---: |
| Full 2024 | `+$2,507.85` | `+$2,507.85` |
| Full 2025 | `+$214.18` | `+$214.18` |
| 2026 YTD | `+$1,375.04` | `+$1,375.04` |
| Continuous 2024-2026 | `+$7,210.30` | `+$7,970.70` |

Quarter `Model=1` gate:

| Metric | Previous Robust Best | Current Score7 Best |
| --- | ---: | ---: |
| Quarter total | `+$3,585.86` | `+$3,638.18` |
| Worst quarter | `-$0.50` | `-$0.50` |
| Losing quarters | `1` | `1` |
| Main improvement | 2025 Q4 `+$142.50` | 2025 Q4 `+$194.82` |

Evidence files:

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `outputs/MODEL1_ISLP_VARIANT_SWEEP_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_QTR_LOG_RESULTS.csv`
- `research/2026-07-12-islp-score7-promotion-note.md`

## What Changed Recently

The promoted change raises the In-Session Liquidity Pullback lane minimum score:

- Old: `InpInSessionLiquidityPullbackMinScore=6`
- New: `InpInSessionLiquidityPullbackMinScore=7`

This made the ISLP lane more selective. It improved the continuous `Model=1` result without hurting full 2024, full 2025, 2026 YTD, or any quarter in the quarter gate.

The higher-profit `risk045_tp150` variant reached `+$8,112.91` on continuous `Model=1`, but it reduced full 2024 from `+$2,507.85` to `+$2,209.66`, so it was rejected instead of promoted.

## Strategy Direction

Current architecture direction:

- Adaptive Reverse remains disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement stays enabled as a tightly gated, low-risk opportunity lane.
- Flat Month Micro Reversion is active only in July and October at reduced risk.
- Range Elite Micro Reversion stays as a low-frequency range-opportunity lane.
- MFE Failure Exit is active only in March after the all-month version was rejected.
- In-Session Liquidity Pullback is active only in June, October, November, and December.
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

1. Stress the Score7 profile with spread and slippage assumptions.
2. Run a more complete tick-model validation before raising risk.
3. Continue looking for profit lanes that add trades without creating losing windows.
4. Keep rejected high-profit variants documented so they are not accidentally re-promoted.
5. Eventually sync the full local EA source to GitHub once normal git authentication is available; the local EA source is ahead of the GitHub source.
