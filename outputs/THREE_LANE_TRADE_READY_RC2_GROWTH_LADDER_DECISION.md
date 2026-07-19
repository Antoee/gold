# Trade-Ready RC2 Growth Ladder Decision

**Decision: REJECT PROMOTION. Three-Lane Trade-Ready RC2 remains the stable historical best.**

The exact RC2 source was tested with adjacent lane-risk scales while signal, exit, calendar, execution, daily/weekly/monthly loss, and 5% portfolio equity-drawdown logic remained unchanged. No martingale, grid, averaging down, or recovery sizing was used.

## Model 4 Comparison

Continuous Model 4 real ticks, XAUUSD, `$10,000`, `2015-01-01` through `2026-07-12`:

| Profile | Net | Increase | CAGR | PF | Trades | Max equity DD | Recovery | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Stable RC2 `1.00x` | +$1,994.62 | +19.95% | +1.59%/yr | 1.82 | 367 | $139.11 / 1.19% | 14.34 | Keep stable best |
| Growth `1.25x` | +$2,317.95 | +23.18% | +1.83%/yr | 1.73 | 383 | $181.86 / 1.48% | 12.75 | Research only |
| Growth `1.50x` | +$2,702.79 | +27.03% | +2.10%/yr | 1.69 | 405 | $242.48 / 1.91% | 11.15 | Reject |

The `1.25x` profile increased continuous profit by `$323.33` or `16.21%`, but maximum equity drawdown increased by `$42.75` or `30.73%`. PF and recovery both declined. It missed the preregistered requirement for at least 20% more profit and materially stronger risk-adjusted evidence.

The `1.50x` profile increased profit by `35.50%`, but drawdown increased by `74.31%`, and its 2019-2022 Model 4 PF was only `1.45`, below the `1.50` gate. The Model 1 `2.00x` diagnostic was rejected earlier because its 2019-2022 PF was `1.38`.

## Broad And Annual Evidence

The `1.25x` Model 4 broad windows were all profitable: older `+$880.54`, middle `+$608.55`, and recent `+$734.80`. All 12 annual/YTD restarts were positive, but two years were nearly flat:

| Year | Net | Increase | PF | Trades |
|---|---:|---:|---:|---:|
| 2015 | +$186.76 | +1.87% | 2.03 | 24 |
| 2016 | +$208.22 | +2.08% | 1.76 | 38 |
| 2017 | +$160.19 | +1.60% | 1.36 | 54 |
| 2018 | +$314.99 | +3.15% | 1.92 | 60 |
| 2019 | +$5.33 | +0.05% | 1.02 | 35 |
| 2020 | +$203.26 | +2.03% | 1.82 | 28 |
| 2021 | +$379.32 | +3.79% | 2.35 | 30 |
| 2022 | +$27.49 | +0.27% | 1.10 | 36 |
| 2023 | +$196.63 | +1.97% | 1.60 | 41 |
| 2024 | +$281.69 | +2.82% | 2.16 | 29 |
| 2025 | +$35.57 | +0.36% | 2.91 | 3 |
| 2026 YTD | +$209.18 | +2.09% | no losing trades | 2 |

## Risk And Stress

- Hard-risk audit: `383/383` entries passed; maximum reconstructed portfolio initial risk was `0.5507%` against the `0.9375%` allowance.
- Severe deterministic cost: `0.10R` added per trade retained `+$1,603.48`, PF `1.448`, and all three broad eras positive.
- All eight 10,000-trial Monte Carlo rows passed the analyzer's absolute gates.
- Severe moving-block P95 drawdown rose to `5.05%-5.87%`, with `3.85%-4.53%` red trials. Stable RC2's worst comparable results were `4.35%` and `1.74%`.
- The weakest severe growth path retained only `+$20.86` at P05, versus stable RC2's `+$197.56`.

The growth neighbor is not unsafe by the tested hard limits, but it is less efficient and materially less robust under adverse execution/order paths. More backtest profit alone is not enough to replace the stable candidate.

## Exact Evidence

- Source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`
- Growth `1.25x` profile SHA-256: `8502A0D4FE736FFB5B219CCE20C2FD97AF4CB2EA4BFC2BA1FEC0788E18B4D32F`
- Portable binary SHA-256: `E24203F2E7AF184B6B6BB3902F7C8711DD887B0E0346C22ED87E8F07EB1AC7B8`
- Continuous report SHA-256: `6949A842D944465ECE24B8325557E207D4B52D1C51050B048B2DC5D0F8D98A37`
- Continuous ledger SHA-256: `75140BF59A50F1AE67640131A66455AF382E65D0FAAF3DA3A5FA07BC78431AC9`

This decision changes neither the Trade-Ready RC2 release nor the frozen forward-demo registration. Real-account trading remains disabled.
