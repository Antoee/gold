# Three-Lane Trade-Ready RC2 ATB150 Decision

**Decision: PROMOTE as the best historical/trade-ready profile. Not forward-approved and not real-money approved.**

ATB150 uses the exact Trade-Ready RC2 source and changes one tested profile input: adaptive-trend lane risk increases from `0.10%` to `0.15%`. Reversion remains `0.45%`, momentum remains `0.15%`, total open risk remains capped at `0.75%`, and all daily/weekly/monthly/5% equity protection stays unchanged.

## Continuous Model 4

MT5 real ticks, XAUUSD, `$10,000`, `2015-01-01` through `2026-07-12`:

| Metric | Previous RC2 | ATB150 | Change |
|---|---:|---:|---:|
| Net profit | +$1,994.62 | **+$2,105.08** | +$110.46 / +5.54% |
| Total increase | +19.95% | **+21.05%** | +1.10 points |
| CAGR | +1.59%/yr | **+1.67%/yr** | +0.08 points |
| Profit factor | 1.82 | **1.81** | -0.01 |
| Trades | 367 | **404** | +37 |
| Win rate | 44.14% | **44.31%** | +0.17 points |
| Maximum equity drawdown | $139.11 / 1.19% | **$134.35 / 1.15%** | -$4.76 / -3.42% money DD |
| Recovery factor | 14.34 | **15.67** | +9.28% |

The improvement is modest, but it is supported by lower drawdown, higher recovery, a larger trade sample, and stronger adverse-path stress rather than profit alone.

## Broad And Annual Evidence

- Older 2015-2018: `+$856.18`, PF `1.79`, 187 trades.
- Middle 2019-2022: `+$572.09`, PF `1.68`, 131 trades.
- Recent 2023-2026: `+$602.11`, PF `2.28`, 76 trades.
- Annual/YTD restarts: `12/12` positive.

| Window | Net | Increase | PF | Trades | Max DD |
|---|---:|---:|---:|---:|---:|
| 2015 | +$170.78 | +1.71% | 2.06 | 26 | 0.87% |
| 2016 | +$256.58 | +2.57% | 2.19 | 42 | 0.52% |
| 2017 | +$111.65 | +1.12% | 1.29 | 55 | 1.08% |
| 2018 | +$281.65 | +2.82% | 1.96 | 63 | 0.51% |
| 2019 | +$13.01 | +0.13% | 1.07 | 36 | 1.08% |
| 2020 | +$194.64 | +1.95% | 1.99 | 29 | 0.65% |
| 2021 | +$313.13 | +3.13% | 2.36 | 30 | 1.16% |
| 2022 | +$16.22 | +0.16% | 1.07 | 36 | 0.96% |
| 2023 | +$181.54 | +1.82% | 1.75 | 41 | 1.24% |
| 2024 | +$233.81 | +2.34% | 2.44 | 29 | 1.08% |
| 2025 | +$17.78 | +0.18% | 2.91 | 3 | 0.12% |
| 2026 YTD | +$209.18 | +2.09% | no losing trades | 2 | 1.19% |

Recent sparsity remains unresolved: 2025 and 2026 have the same three and two trades as the previous profile. ATB150 is a risk-adjusted historical improvement, not evidence that the bot will trade frequently in the future.

## Risk And Stress

- Hard-risk audit: `404/404` entries passed; maximum conservative portfolio initial risk was `0.4448%` against the unchanged `0.75%` cap.
- Severe deterministic cost: `0.10R` added per trade retained `+$1,506.55`, PF `1.515`, and all broad eras positive.
- Monte Carlo: `8/8` seeded 10,000-trial rows passed.
- Weakest severe block P05 net: `+$238.64`, improved from `+$197.56`.
- Worst severe block P95 closed drawdown: `4.225%`, improved from `4.352%`.
- Worst severe block red trials: `1.35%`, improved from `1.74%`.
- Dedicated ATB150 promotion safety: `60/60`; unchanged base RC2 static safety: `79/79`.

## Exact Identity

- Source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`
- Profile SHA-256: `705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E`
- Continuous report SHA-256: `31A383253B7BF7611D6209E296317105E4C5756A8A12D883C0872245866B1B4D`
- Continuous ledger SHA-256: `D784E3F4289E989DDA2E6C686C80A20086825A6586355AFA8556021486373E69`
- Continuous-run binary SHA-256: `E24203F2E7AF184B6B6BB3902F7C8711DD887B0E0346C22ED87E8F07EB1AC7B8`

The frozen forward candidate remains Operational Hardening v0.2-rc2. The invalid `$100,000` demo still counts as zero forward days and zero trades. This historical promotion does not authorize changing that registration, silently switching accounts, or enabling real-account trading.
