# Reversion Break-Even Discovery Decision

**Decision: REJECT BEFORE MODEL 4. NO NEW BEST.**

This code experiment added an optional completed-H1-bar break-even manager to the ATB150 reversion lane. It could only tighten an exact-ticket owned stop to break-even or a small positive lock after a frozen R threshold. Entries, initial stops, VWAP targets, requested risk, both trend lanes, portfolio limits, and real-account protections were unchanged.

- Source SHA-256: `49A8561A5A6D9F52D5F6F00DE838EBB4B0207BE437FF0B4EB115586912C23F90`
- Exact shared portable EX5 SHA-256: `A5D244227B045D5A4A7EAF91F6765FE9B666D298CD39B42C782BEAB56DBDD167`
- Compile: `0 errors, 0 warnings`; one binary distributed byte-identically to four workers
- Model: `1`, `$10,000`, three disjoint eras plus continuous 2015-2026
- Evidence: `28 / 28` final reports parsed; one initial identity refusal was rerun successfully on one prepared worker
- Gate: every era positive, continuous CAGR at least `0.15` points above control, PF at least `1.85`, DD no worse than control, no loss of recovery or return/drawdown, at least 400 continuous trades, and adjacent support

| Profile | Net | Increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$2,195.53 | +21.96% | +1.74%/yr | 1.83 | 415 | 1.17% | 15.82 | 18.77 | Control |
| Trigger 0.50R, lock 0.00R | +$1,774.78 | +17.75% | +1.43%/yr | 1.72 | 412 | 1.36% | 11.56 | 13.05 | Reject |
| Trigger 0.75R, lock 0.00R | +$1,950.50 | +19.51% | +1.56%/yr | 1.78 | 412 | 1.07% | 15.28 | 18.22 | Reject |
| Trigger 1.00R, lock 0.00R | +$2,114.39 | +21.14% | +1.68%/yr | 1.82 | 415 | 1.13% | 15.90 | 18.71 | Reject |
| Trigger 1.25R, lock 0.00R | +$2,114.39 | +21.14% | +1.68%/yr | 1.82 | 415 | 1.13% | 15.90 | 18.71 | Reject |
| Trigger 0.75R, lock 0.10R | +$1,964.99 | +19.65% | +1.57%/yr | 1.79 | 414 | 1.07% | 15.40 | 18.36 | Reject |
| Trigger 1.00R, lock 0.10R | +$2,122.79 | +21.23% | +1.68%/yr | 1.82 | 415 | 1.13% | 15.96 | 18.79 | Reject |

All disjoint eras stayed profitable, but every candidate lost net profit and CAGR versus the disabled control. The `1.00R / 0.10R` row was the strongest efficiency result: maximum drawdown improved by `0.04` points, recovery improved by about `0.93%`, and return/drawdown improved by about `0.10%`. Those small efficiency gains cost `$72.74`, reduced CAGR by `0.06` points, and left PF below the frozen `1.85` floor. The required growth improvement was `+0.15` points, not a reduction.

Lower triggers protected earlier but clipped profitable reversion paths and produced materially weaker growth and efficiency. The identical `1.00R` and `1.25R` zero-lock rows also show no broad payoff plateau capable of supporting promotion.

No candidate qualifies for Model 4. The feature remains disabled research code, ATB150 remains the historical champion, and the frozen forward registration is unchanged. This is historical research, not real-money approval.
