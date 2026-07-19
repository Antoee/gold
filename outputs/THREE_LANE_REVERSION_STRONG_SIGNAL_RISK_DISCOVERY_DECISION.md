# Reversion Strong-Signal Risk Discovery Decision

**Decision: REJECT BEFORE MODEL 4. NO NEW BEST.**

This code experiment allowed an optional higher requested risk only for an already-valid reversion entry whose completed H1 directional body ratio met a frozen threshold. It changed no entry eligibility, stop, VWAP target, exit, trend lane, lot cap, account-wide exposure cap, or loss limit. The feature was disabled by default and used no current-bar, future, calendar, account-profit, or prior-outcome data.

- Source SHA-256: `36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF`
- Exact shared portable EX5 SHA-256: `975976F6FEB7659B75B073B93B69D3964A09A82EDF077A87F1CF2348A26A4E1B`
- Compile: `0 errors, 0 warnings`; one binary distributed byte-identically to four workers
- Model: `1`, `$10,000`, three disjoint eras plus continuous 2015-2026
- Evidence: `28 / 28` final reports parsed; one initial identity refusal was rerun successfully on one prepared worker
- Gate: all eras positive; continuous CAGR at least control `+0.15` points; PF at least `1.85`; DD at most `1.35%` and control `+0.20` points; recovery and return/DD at least `95%` of control; at least 400 trades; no era materially worse; two supporting neighbors

| Profile | Net | Increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$2,195.53 | +21.96% | +1.74%/yr | 1.83 | 415 | 1.17% | 15.82 | 18.77 | Control |
| Body 0.10, risk 0.60% | +$2,383.01 | +23.83% | +1.87%/yr | 1.89 | 415 | 1.55% | 12.45 | 15.37 | Reject |
| Body 0.15, risk 0.55% | +$2,372.14 | +23.72% | +1.86%/yr | 1.89 | 415 | 1.55% | 12.39 | 15.30 | Reject |
| Body 0.15, risk 0.60% | +$2,383.01 | +23.83% | +1.87%/yr | 1.89 | 415 | 1.55% | 12.45 | 15.37 | Reject |
| Body 0.15, risk 0.65% | +$2,438.12 | +24.38% | +1.91%/yr | 1.91 | 415 | 1.54% | 12.74 | 15.83 | Reject |
| Body 0.20, risk 0.60% | +$2,383.01 | +23.83% | +1.87%/yr | 1.89 | 415 | 1.55% | 12.45 | 15.37 | Reject |
| Body 0.25, risk 0.60% | +$2,314.68 | +23.15% | +1.82%/yr | 1.87 | 415 | 1.21% | 16.03 | 19.13 | Reject |

The highest-growth `0.15 / 0.65%` row cleared the growth and PF floors, but drawdown exceeded the cap by `0.19` points. It retained only `80.52%` of control recovery and `84.35%` of control return/drawdown, far below the frozen `95%` floor. It is rejected even though it made `$242.59` more than control.

The strict `0.25 / 0.60%` row was the only candidate to improve both efficiency measures: recovery retained `101.33%`, return/drawdown retained `101.93%`, and maximum drawdown was only `1.21%`. Its CAGR gain was just `0.08` points, below the required `0.15`, so it also cannot advance under this contract.

No candidate qualifies for Model 4. A separate strict-body risk-ladder contract may test whether the efficient `0.25` threshold has risk-neighbor support, but that is a new data-informed experiment and cannot reverse this rejection. ATB150 and the frozen forward registration remain unchanged. This is historical research, not real-money approval.
