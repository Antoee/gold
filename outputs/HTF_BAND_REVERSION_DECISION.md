# H1 Band/VWAP Reversion Decision

Date: 2026-07-16

Decision: **retain as a promising broad-history research component, but do not promote or integrate it into the maintained EA.**

The strategy produced the strongest independent broad-history Model4 result found in this research cycle, but it failed the no-red-active-year gate and did not repair every red portfolio year. Maintained source and maintained profile remain unchanged and real-account trading remains locked.

## Strategy

The lane is date-independent and standalone:

- H1 Bollinger-band penetration and close-back-inside reclaim
- RSI `40 / 60` exhaustion
- low-ADX range regime
- directional rejection wick
- rolling VWAP target
- five-bar structural stop with ATR/point buffer
- spread-adjusted minimum RR
- `0.20%` effective setup risk with one open position
- no martingale, grid, averaging down, recovery sizing, or calendar exceptions

Experimental source SHA-256:

`17CC5E0D818E180528CC13388E09543F53C524A4CBF18E7E6A997F30B1D3F12C`

Frozen research profile:

`outputs/CANDIDATE_HTF_BAND_REVERSION_RESEARCH_PROFILE.set`

Profile SHA-256:

`A93F9D52CE8E2D7BD5AD99DDD9E089859ED390B39E63C21CA639EC171966C64E`

## Fast Broad-Era Screen

All `84 / 84` valid Model1 reports returned across 21 predeclared H1/H4 variants and four windows: continuous 2015-2026, older 2015-2018, middle 2019-2022, and recent 2023-2026 YTD.

An earlier `40 / 40` zero-trade batch was correctly invalidated after the tester log proved that the restored A167 executable, which has no experimental lane, had been used. The frozen experimental source was then compiled with `0 errors, 0 warnings` and every valid report was rerun.

The useful Model1 plateau was:

| Profile | Full net | PF | Trades | DD | Older | Middle | Recent |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ADX `22` | `+$391.76` | `2.05` | `45` | `1.25%` | `+$66.99` | `+$144.38` | `+$184.66` |
| ADX `24` | `+$252.25` | `1.39` | `66` | `2.03%` | `+$75.88` | `+$33.62` | `+$79.39` |
| ADX `24`, stricter wick | `+$253.14` | `1.45` | `60` | `1.66%` | `+$4.83` | `+$100.59` | `+$79.39` |

The lower-ADX follow-up did not improve the balance of evidence. ADX `18` made `+$211.05`, PF `3.75`, but only 11 trades; ADX `20` lost `-$34.60` in the middle era; ADX `21` lost `-$10.13` in the older era.

## Continuous Model4

All three Model1 survivors passed continuous 2015-2026 Model4 real-tick testing:

| Profile | Net | Total return | Annualized | CAGR | PF | Trades | Max DD | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ADX `22` | `+$440.63` | `+4.41%` | `+0.38%/yr` | `+0.37%/yr` | `2.36` | `41` | `1.10%` | `3.95` |
| ADX `24` | `+$332.39` | `+3.32%` | `+0.29%/yr` | `+0.28%/yr` | `1.59` | `60` | `1.27%` | `2.58` |
| ADX `24`, stricter wick | `+$315.70` | `+3.16%` | `+0.27%/yr` | `+0.27%/yr` | `1.62` | `55` | `1.27%` | `2.48` |

Model1/Model4 agreement and the neighboring real-tick plateau are encouraging. Absolute growth remains modest.

## Yearly Model4 Gate

The ADX `22` leader had nine profitable active years, one inactive year, and three losing years:

| Year | Net | Trades |
| --- | ---: | ---: |
| 2015 | `+$31.05` | `2` |
| 2016 | `-$9.70` | `1` |
| 2017 | `+$12.19` | `3` |
| 2018 | `+$30.95` | `5` |
| 2019 | `$0.00` | `0` |
| 2020 | `-$32.28` | `7` |
| 2021 | `+$200.32` | `7` |
| 2022 | `+$27.52` | `3` |
| 2023 | `+$90.00` | `3` |
| 2024 | `-$2.65` | `5` |
| 2025 | `+$10.07` | `2` |
| 2026 YTD | `+$35.73` | `1` |

Restarted yearly sum was `+$393.20` on 39 trades versus continuous `+$440.63` on 41 trades. This is reasonably consistent, but three red active years fail promotion.

ADX `24` had four red years and the stricter-wick profile had six. Neither improved annual stability.

## Portfolio Screen

The exact 41-trade Model4 stream had zero same-side duplicate entries with every prior stream and low monthly-R correlation:

- reversion / money-ready: `0.1497`
- reversion / high-profit: `-0.1518`
- reversion / Donchian: `-0.0753`

All `700` risk-normalized four-stream blends completed under a `3%` open-risk cap and `0.05R` per-trade stress. No row passed the annual and stress gates.

The strongest return near-miss made `+$12,777.09`, `7.40%` CAGR, PF `2.193`, on 251 trades with `6.06%` conservative drawdown, but 2017 and 2019 remained red. The most stable money-ready-plus-reversion family reduced the base failure to one red year, 2016, but stress produced two red years and total activity was only 73 trades.

The annual R math exposes a genuine conflict: reversion loses its only 2016 trade, while enough Donchian risk to offset 2016 necessarily makes Donchian's deeply negative 2017 worse. No calendar exception was introduced.

## Disposition

- Keep the exact source, profile, reports, and trade stream as research evidence.
- Do not add the lane to maintained A167.
- Do not label it money-ready or live-ready.
- Use it as the starting point for a future market-state diversification study, not another broad parameter sweep.
- Require a new independent component or defensible state filter that repairs 2016 without sacrificing 2017 and survives Model4 yearly testing.
- The subsequent DI-edge feature study improved continuous quality but still failed yearly and portfolio gates; see `outputs/HTF_BAND_REVERSION_DI_GATE_DECISION.md`.

Evidence:

- `outputs/HTF_BAND_REVERSION_RAW_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_PLATEAU_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_LOW_ADX_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_MODEL4_LEAD_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_MODEL4_NEIGHBORS_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_YEARLY_MODEL4_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_A24_YEARLY_MODEL4_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_W20_YEARLY_MODEL4_RESULTS.csv`
- `outputs/HTF_BAND_REVERSION_MODEL4_TRADES.csv`
- `outputs/STRATEGY_PORTFOLIO_WITH_REVERSION_SCREEN.csv`
- `outputs/STRATEGY_PORTFOLIO_WITH_REVERSION_SCREEN.md`
- `outputs/HTF_BAND_REVERSION_DI_GATE_DECISION.md`

## Final Verification

- maintained root/mirror source SHA-256: `A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622`
- maintained money-ready profile SHA-256: `D0459197F2A8CA1385F139694BD036AA9A3A596BB406F7D4474CDC8444605C79`
- restored maintained compile: `0 errors, 0 warnings`
- new Python analyzer AST: pass
- three new PowerShell package-builder AST checks: pass
- MT5 local safety audit: `44 / 44` pass
- static MQL preflight: `39 / 39` pass with `476` inputs
- static repository safety audit: `25 / 25` pass
- local launch hard lock: present
- local, hidden-desktop, and external unlocks: absent
- MT5 / MetaEditor / tester processes after restore: `0`
