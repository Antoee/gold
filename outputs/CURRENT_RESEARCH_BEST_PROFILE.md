# Current Research Best Profile

Profile: `Score7 Regime No-M1-Shock Dec-ISLP-Off`

- Builder: `work/build_score7_regime_no_m1shock_dec_islp_off_profile.ps1`
- Local generated set: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_NO_M1SHOCK_DEC_ISLP_OFF_PROFILE.set`
- SHA-256: `D1B665E193A5126B879E0DCA08A85CB5C8E1D1C9D2007075D6C2EA6ABBF82672`
- Primary promotion note: `research/2026-07-12-december-islp-guard-promotion-note.md`
- Monthly validation note: `research/2026-07-12-december-islp-monthly-validation-note.md`
- Quarterly validation note: `research/2026-07-12-december-islp-quarterly-validation-note.md`

## Latest Decision

Keep Dec-ISLP-Off as the current research-best.

The promoted change disables only December trades for the In-Session Liquidity Pullback lane:

- `InpISLPTradeDecember=false`

## Validation Summary

| Model | Previous No-M1-Shock | Dec-ISLP-Off | Decision |
| --- | ---: | ---: | --- |
| Model0 total | `4495.93` | `8768.34` | guard wins |
| Model1 total | `14739.08` | `15361.76` | guard wins |
| Model2 total | `17890.63` | `15361.76` | previous wins |
| Model4 sampled total | `4075.62` | `7469.00` | guard wins |
| Model4 monthly total | `3687.00` | `3779.52` | guard wins |
| Model4 quarterly total | `3404.59` | `3455.89` | guard wins |

Continuous-window rows:

| Model | Previous No-M1-Shock | Dec-ISLP-Off |
| --- | ---: | ---: |
| Model0 continuous | `1288.93` | `5386.54` |
| Model1 continuous | `9753.58` | `10127.76` |
| Model2 continuous | `12054.55` | `10127.76` |
| Model4 continuous | `1288.93` | `4507.51` |

## Monthly Model4 Gate

The monthly real-tick package ran 62 configs, covering 31 monthly windows for each profile from `2024.01.01` through `2026.07.12`.

The runner did not emit report files, but tester-log final balances were recovered for all 62 configs. This gives valid monthly net-profit comparison, but not full drawdown/trade-stat proof.

| Profile | Parsed Months | Total Net | Nonzero Months | Losing Months | Worst Month | Best Month |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `no_m1shock` | `31 / 31` | `3687.00` | `16` | `2` | `-49.40` | `1497.84` |
| `dec_islp_off` | `31 / 31` | `3779.52` | `14` | `0` | `0.00` | `1497.84` |

The only changed months were December:

| Month | No-M1-Shock | Dec-ISLP-Off | Delta |
| --- | ---: | ---: | ---: |
| `2024_12` | `-49.40` | `0.00` | `+49.40` |
| `2025_12` | `-43.12` | `0.00` | `+43.12` |

## Quarterly Model4 Gate

The quarterly real-tick package ran 22 configs, covering 11 quarterly windows for each profile from `2024_Q1` through `2026_Q3TD`.

The runner did not emit report files, but tester-log final balances were recovered for all 22 configs. This gives valid quarterly net-profit comparison, but not full drawdown/trade-stat proof.

| Profile | Parsed Quarters | Total Net | Nonzero Quarters | Losing Quarters | Worst Quarter | Best Quarter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `no_m1shock` | `11 / 11` | `3404.59` | `9` | `1` | `-4.55` | `1497.84` |
| `dec_islp_off` | `11 / 11` | `3455.89` | `9` | `0` | `0.00` | `1497.84` |

The only changed quarter was Q4 2024:

| Quarter | No-M1-Shock | Dec-ISLP-Off | Delta |
| --- | ---: | ---: | ---: |
| `2024_Q4` | `-4.55` | `46.75` | `+51.30` |

## Evidence Files

- `outputs/DEC_ISLP_GUARD_DECISION_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL1_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL2_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL0_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`
- `research/2026-07-12-december-islp-guard-promotion-note.md`
- `research/2026-07-12-december-islp-monthly-validation-note.md`
- `research/2026-07-12-december-islp-quarterly-validation-note.md`

## Caveats

- This is a research-best candidate, not a production deployment profile.
- Model2 still prefers the previous no-m1-shock profile.
- Monthly and quarterly validation currently prove net-profit comparison only because report files were missing.
- Local EA source is ahead of the GitHub source until the source-sync section in the README says otherwise.

## Standing Rules

- No martingale.
- No grid.
- No averaging down.
- Adaptive Reverse remains disabled to avoid whipsaw risk.
- Liquidity-aware structural stops remain preferred over pure ATR-only stop placement where available.
