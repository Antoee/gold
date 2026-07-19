# Reversion Strict-Body Risk Ladder Decision

**Decision: REJECT BEFORE MODEL 4. PROMISING NEAR-MISS, BUT NO NEW BEST.**

This separately preregistered follow-up kept the prior strong-signal research source and exact EX5 unchanged. It tested the efficient `0.25` directional-body threshold across a narrow requested-risk ladder plus two body-threshold neighbors. The prior broad discovery rejection remains final; this contract did not amend its gates.

- Source SHA-256: `36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF`
- Exact shared portable EX5 SHA-256: `975976F6FEB7659B75B073B93B69D3964A09A82EDF077A87F1CF2348A26A4E1B`
- Model: `1`, `$10,000`, three disjoint eras plus continuous 2015-2026
- Evidence: `32 / 32` final reports parsed; two initial identity refusals were rerun successfully on one prepared worker
- Main gate: all eras positive; CAGR at least control `+0.15` points; PF at least `1.87`; DD at most `1.35%`; recovery and return/DD no worse than control; at least 400 trades; no materially worse era
- Support gate: two adjacent risk rows and one adjacent body row at CAGR at least control `+0.10`, PF at least `1.85`, DD at most `1.35%`, and at least `95%` of control efficiency

| Profile | Net | Increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$2,195.53 | +21.96% | +1.74%/yr | 1.83 | 415 | 1.17% | 15.82 | 18.77 | Control |
| Body 0.250, risk 0.600% | +$2,314.68 | +23.15% | +1.82%/yr | 1.87 | 415 | 1.21% | 16.03 | 19.13 | Reject |
| Body 0.250, risk 0.625% | +$2,323.19 | +23.23% | +1.83%/yr | 1.87 | 415 | 1.21% | 16.09 | 19.20 | Reject |
| Body 0.250, risk 0.650% | +$2,369.79 | +23.70% | +1.86%/yr | 1.89 | 415 | 1.21% | 16.41 | 19.59 | Reject |
| Body 0.250, risk 0.675% | +$2,369.79 | +23.70% | +1.86%/yr | 1.89 | 415 | 1.21% | 16.41 | 19.59 | Reject |
| Body 0.250, risk 0.700% | +$2,391.89 | +23.92% | +1.88%/yr | 1.89 | 415 | 1.21% | 16.56 | 19.77 | Reject |
| Body 0.225, risk 0.650% | +$2,369.79 | +23.70% | +1.86%/yr | 1.89 | 415 | 1.21% | 16.41 | 19.59 | Reject |
| Body 0.275, risk 0.650% | +$2,369.79 | +23.70% | +1.86%/yr | 1.89 | 415 | 1.21% | 16.41 | 19.59 | Reject |

The `0.700%` row was positive in every era and improved continuous control by `$196.36`. Its drawdown rose only `0.04` points, recovery retained `104.71%`, and return/drawdown retained `105.32%`. Risk neighbors and both body neighbors formed a broad support plateau.

It nevertheless reached only `1.88%` CAGR. The frozen requirement was `1.89%`, calculated as control `1.74% + 0.15` points. Missing by `0.01` point is still a miss. Testing new `0.71-0.74%` settings after seeing this boundary would be threshold chasing, so the gate is not relaxed and no Model 4 run is opened.

This family is recorded as a promising, risk-efficient near-miss for future genuinely new evidence, not as a promotion. ATB150 remains the historical champion, the frozen forward registration is unchanged, and real-account trading remains disabled.
