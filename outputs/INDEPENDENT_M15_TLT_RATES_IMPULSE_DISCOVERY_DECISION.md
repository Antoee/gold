# Independent M15 TLT Rates-Impulse Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

The EA tested a date-independent cross-market premise: strength in the last provably completed TLT D1 bar acts as a falling-yields proxy for gold buys, weakness acts as a rising-yields proxy for sells, and a completed XAUUSD M15 breakout confirms entry. All profiles retained broker-native risk sizing, minimum-lot refusal, a `$10,000` contract, account-wide exposure protection, daily/equity loss caps, one trade per day, and disabled real trading.

- Source SHA-256: `409286458AF0739089CE5436E6E8DCE3E591C88EE6706742A705E2AD1A62F1D3`
- Exact report binary SHA-256: `50BE413BF9793B093269EEC0FA8C94B5F4B98FE4941513237683DD2213A4FF11`
- Controlled run: `45 / 45` reports, one worker, zero runner errors
- Risk per accepted trade: `0.10%` on a `$10,000` test deposit
- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`
- Numeric gate passes: `0 / 15`
- One-factor adjacency passes: `0 / 15`
- History feasibility: TLT D1 aligned on at least `98.062%` of yearly XAUUSD D1 bars; lookback readiness `100%`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `tltri_tp200` | -$297.88 | 0.87 | 454 | +$136.93 | 1.14 | 226 | -$151.60 | -0.25% | 0.95 | 681 | 3.75% | REJECT_BEFORE_HOLDOUT |
| `tltri_start8` | -$52.45 | 0.97 | 406 | -$93.75 | 0.89 | 197 | -$159.43 | -0.27% | 0.94 | 604 | 3.03% | REJECT_BEFORE_HOLDOUT |
| `tltri_break6` | -$269.76 | 0.85 | 377 | +$72.34 | 1.09 | 195 | -$179.32 | -0.3% | 0.93 | 572 | 2.99% | REJECT_BEFORE_HOLDOUT |
| `tltri_trend20` | -$275.60 | 0.86 | 403 | +$59.33 | 1.07 | 206 | -$217.80 | -0.37% | 0.92 | 610 | 3.48% | REJECT_BEFORE_HOLDOUT |
| `tltri_move30` | -$348.31 | 0.83 | 408 | +$110.14 | 1.12 | 210 | -$222.02 | -0.37% | 0.92 | 619 | 3.88% | REJECT_BEFORE_HOLDOUT |
| `tltri_move10` | -$314.50 | 0.87 | 495 | +$28.89 | 1.03 | 247 | -$287.38 | -0.48% | 0.92 | 743 | 4.01% | REJECT_BEFORE_HOLDOUT |
| `tltri_center` | -$391.52 | 0.82 | 454 | +$48.99 | 1.05 | 226 | -$345.49 | -0.58% | 0.89 | 681 | 4.68% | REJECT_BEFORE_HOLDOUT |
| `tltri_ref2` | -$256.08 | 0.9 | 518 | -$88.13 | 0.93 | 270 | -$349.39 | -0.59% | 0.9 | 789 | 4.64% | REJECT_BEFORE_HOLDOUT |
| `tltri_ref3` | -$300.17 | 0.89 | 573 | -$116.24 | 0.92 | 301 | -$390.31 | -0.66% | 0.9 | 874 | 4.41% | REJECT_BEFORE_HOLDOUT |
| `tltri_notrend` | -$485.09 | 0.78 | 453 | -$115.38 | 0.92 | 333 | -$485.09 | -0.83% | 0.78 | 453 | 5.01% | REJECT_BEFORE_HOLDOUT |
| `tltri_trend5` | -$485.27 | 0.8 | 481 | -$57.17 | 0.95 | 258 | -$485.27 | -0.83% | 0.8 | 481 | 5.01% | REJECT_BEFORE_HOLDOUT |
| `tltri_tp150` | -$436.79 | 0.8 | 454 | -$11.29 | 0.99 | 226 | -$487.71 | -0.83% | 0.82 | 569 | 5.01% | REJECT_BEFORE_HOLDOUT |
| `tltri_buffer00` | -$489.50 | 0.78 | 447 | +$39.59 | 1.04 | 238 | -$489.50 | -0.83% | 0.78 | 447 | 5% | REJECT_BEFORE_HOLDOUT |
| `tltri_break2` | -$495.79 | 0.78 | 460 | -$14.65 | 0.99 | 263 | -$495.79 | -0.84% | 0.78 | 460 | 5.01% | REJECT_BEFORE_HOLDOUT |
| `tltri_buffer10` | -$416.60 | 0.8 | 419 | +$31.66 | 1.03 | 218 | -$500.09 | -0.85% | 0.81 | 540 | 5.01% | REJECT_BEFORE_HOLDOUT |

## Interpretation

- Best continuous result was `tltri_tp200` at -$151.60, but no profile satisfied the complete broad-era and adjacency contract.
- Reject this family without inspecting 2021-2026 or spending real-tick time on it. Keep ATB150 as the research best.
