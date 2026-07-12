# December ISLP Guard Promotion

Date: 2026-07-12

## Change

Promote a narrow month-lane guard on top of the previous `Score7 Regime No-M1-Shock` profile:

- `InpISLPTradeDecember=false`

New profile:

- `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_NO_M1SHOCK_DEC_ISLP_OFF_PROFILE.set`
- Builder: `work/build_score7_regime_no_m1shock_dec_islp_off_profile.ps1`
- SHA-256: `D1B665E193A5126B879E0DCA08A85CB5C8E1D1C9D2007075D6C2EA6ABBF82672`

## Why

Trade diagnostics showed the Q4 2024 red window was two trades:

- 2024-10-08 Flat Month Micro Reversion buy: `+46.75`
- 2024-12-06 In-Session Liquidity Pullback sell: `-51.30`

The losing trade was a December ISLP trade. Q4 2025 gains came from October/November ISLP trades, not December.

## Validation Summary

| Model | Profile | Parsed | Total Net | Continuous | Full 2024 | Full 2025 | 2026 YTD | Q4 2024 | Q4 2025 | Worst | Losing Windows |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Model0 | no_m1shock | 6 | `4495.93` | `1288.93` | `1425.73` | `214.30` | `1375.36` | `-4.55` | `196.16` | `-4.55` | 1 |
| Model0 | dec_islp_off | 6 | `8768.34` | `5386.54` | `1549.23` | `214.30` | `1375.36` | `46.75` | `196.16` | `46.75` | 0 |
| Model1 | no_m1shock | 6 | `14739.08` | `9753.58` | `3201.96` | `214.18` | `1375.04` | `-0.50` | `194.82` | `-0.50` | 1 |
| Model1 | dec_islp_off | 6 | `15361.76` | `10127.76` | `3403.21` | `214.18` | `1375.04` | `46.75` | `194.82` | `46.75` | 0 |
| Model2 | no_m1shock | 6 | `17890.63` | `12054.55` | `3890.81` | `214.18` | `1375.04` | `161.23` | `194.82` | `161.23` | 0 |
| Model2 | dec_islp_off | 6 | `15361.76` | `10127.76` | `3403.21` | `214.18` | `1375.04` | `46.75` | `194.82` | `46.75` | 0 |
| Model4 | no_m1shock | 6 | `4075.62` | `1288.93` | `1425.73` | `214.30` | `955.21` | `-4.55` | `196.00` | `-4.55` | 1 |
| Model4 | dec_islp_off | 6 | `7469.00` | `4507.51` | `1549.23` | `214.30` | `955.21` | `46.75` | `196.00` | `46.75` | 0 |

## Decision

Promote `dec_islp_off` as the new research-best candidate because Model0, Model1, and Model4 real ticks improved while the Q4 2024 losing window was removed and Q4 2025 was preserved.

## Caveat

Model2 prefers the previous no-m1-shock profile. This is still clean and profitable, but the edge is model-sensitive. The next gate should be wider real-tick monthly/quarterly validation before raising risk.
