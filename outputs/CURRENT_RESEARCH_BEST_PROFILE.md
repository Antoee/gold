# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_score7_regime_profile.ps1`
- SHA-256: `7BD4019104BCDF117A7D729289D6821D5F4BF6FB6FF9FE2D543BCF91717DC204`
- Research note: `research/2026-07-12-score7-regime-guard-promotion-note.md`

## Evidence

- Fast-model continuous from the previous gate: `9512.09` over `2024.01.01` to `2026.07.12`
- Higher-fidelity `Model=1` continuous: `9753.58` versus previous Score7 best `7970.70` over `2024.01.01` to `2026.07.12`
- `Model=1` full 2024: `3201.96` versus previous Score7 best `2507.85`
- `Model=1` full 2025: unchanged at `214.18`
- `Model=1` 2026 YTD: unchanged at `1375.04`
- `Model=1` quarter gate: `3638.18` versus previous Score7 best `3638.18`; same worst quarter `-0.50`; same losing quarter count `1`
- `Model=0` confirmation: Regime and previous Score7 were exactly equal across all tested windows; continuous `1288.93` versus `1288.93`, worst window `-4.55` versus `-4.55`
- `Model=2` confirmation is incomplete and not usable as confirmation yet: Score7 parsed `6 / 6` windows with continuous `9862.76`, but Regime parsed only `3 / 6` windows because MT5 returned missing rate/report data for continuous 2024-2026, full 2024, and Q4 2024.
- Validation files: `outputs/MODEL1_SCORE7_COST_STRESS_LOG_RESULTS.csv` and `outputs/MODEL1_SCORE7_REGIME_QTR_LOG_RESULTS.csv`
- Confirmation files: `outputs/MODEL0_SCORE7_REGIME_CONFIRM_LOG_RESULTS.csv` and `research/2026-07-12-score7-regime-model0-confirmation-note.md`
- Partial Model=2 files: `outputs/MODEL2_SCORE7_REGIME_CONFIRM_LOG_RESULTS.csv` and `outputs/MODEL2_SCORE7_REGIME_CONFIRM_LOG_SUMMARY.csv`
- Trade diagnosis files: `outputs/MODEL1_SCORE7_REGIME_TRADE_DIAG_SUMMARY.csv` and `research/2026-07-12-score7-regime-trade-diagnosis-note.md`
- Spread-regime guard and M1 spread-shock guard are enabled after improving continuous `Model=1` validation without worsening broad, quarter, or Model=0 confirmation windows.
- The `9753.58` result should be treated as a Model=1 research edge, not a fully cross-model-confirmed production number.
- Trade-log diagnosis reproduced the `1782.88` Model=1 delta with `63` entries in both profiles; the edge came from timing/path changes beginning around August 2024 rather than a lower trade count.
- The higher-profit `risk045_tp150` variant reached `8112.91` on continuous `Model=1`, but reduced full 2024 from `2507.85` to `2209.66`, so it was rejected.
- Adaptive Reverse remains explicitly disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement remains enabled as a tightly gated, low-risk opportunity lane.
- MFE profit-lock stop remains enabled only in August.
- Flat Month Micro Reversion is promoted only for July and October with risk multiplier `0.35`, after a clean rerun confirmed the broad windows and H2/Q3/Q4 validation set.
- Range Elite Micro Reversion is enabled as a strict, low-frequency range-opportunity lane after it added a small clean 2024 edge without harming 2025 or 2026 YTD.
- MFE Failure Exit is enabled only in March after the all-month version was rejected and the month-gated version improved continuous and 2026 YTD performance with zero losing quarter windows.
- In-Session Liquidity Pullback is enabled only in June, October, November, and December after broad validation improved the continuous equity path without reducing 2025, 2026 YTD, or quarter-window results.
- In-Session Liquidity Pullback minimum score is raised from `6` to `7` after `Model=1` validation improved continuous profit without worsening any broad or quarter validation window.
- TP150/Risk050 was rejected after a higher-fidelity `Model=1` check reduced continuous validation from `7210.30` on the previous profile to `1974.32`.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing and longer walk-forward confirmation.
