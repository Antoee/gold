# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_NO_M1SHOCK_DEC_ISLP_OFF_PROFILE.set`
- Builder: `work/build_score7_regime_no_m1shock_dec_islp_off_profile.ps1`
- SHA-256: `D1B665E193A5126B879E0DCA08A85CB5C8E1D1C9D2007075D6C2EA6ABBF82672`
- Research note: `research/2026-07-12-december-islp-guard-promotion-note.md`

## Evidence

- Previous no-m1-shock profile fixed the Model=2 M1 spread-shock incompatibility and remained clean in validation.
- Expanded real-tick showdown showed previous no-m1-shock had one small Q4 2024 loss: `-4.55`.
- Trade diagnostics found the Q4 2024 red window came from a single December ISLP loss: `-51.30` after an October micro-reversion win of `+46.75`.
- December ISLP guard promotion: disabling only December ISLP (`InpISLPTradeDecember=false`) improved Model=4 total from `4075.62` to `7469.00`, Model=1 continuous from `9753.58` to `10127.76`, and Model=0 continuous from `1288.93` to `5386.54`, while removing the Q4 2024 losing window.
- Caveat: Model=2 preferred the previous no-m1-shock profile, with continuous `12054.55` versus Dec-ISLP-Off `10127.76`.

## Validation Summary

| Model | Previous No-M1-Shock | Dec-ISLP-Off | Decision |
| --- | ---: | ---: | --- |
| Model0 total | `4495.93` | `8768.34` | guard wins |
| Model1 total | `14739.08` | `15361.76` | guard wins |
| Model2 total | `17890.63` | `15361.76` | previous wins |
| Model4 total | `4075.62` | `7469.00` | guard wins |

## Evidence Files

- `outputs/DEC_ISLP_GUARD_DECISION_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL1_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL2_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL0_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `research/2026-07-12-december-islp-guard-promotion-note.md`

## Standing Notes

- Adaptive Reverse remains disabled to avoid stop-and-reverse whipsaw risk.
- Liquidity-aware structural stops remain preferred over pure ATR-only stop placement where available.
- This is the current research-best candidate, not a final production deployment profile.
- The next validation gate is wider real-tick monthly/quarterly validation because Model=2 still prefers the previous no-m1-shock profile.
