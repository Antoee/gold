# Reversion Liquidity-Sweep Discovery Decision

**Decision: REJECT BEFORE MODEL 4. NO NEW BEST.**

This code experiment added an optional completed-H1 liquidity-sweep-and-reclaim confirmation to the ATB150 reversion lane. The signal bar had to trade beyond a prior local extreme and close back through it. Entry risk, exits, stops, trend lanes, portfolio exposure limits, and real-account protections were unchanged.

- Source SHA-256: `C5AB825B9F8BB701D02E4144E0062E79CC5A64FCECE04C6057C0A24755AD1A65`
- Exact shared portable EX5 SHA-256: `9191CA09F5A170E08ED982FB085005CED2A46DB142CB1ECCE69D449A84F8D0B2`
- Compile: `0 errors, 0 warnings`; one binary distributed byte-identically to four workers
- Model: `1`, `$10,000`, three disjoint eras plus continuous 2015-2026
- Evidence: `32 / 32` final reports parsed; two initial identity refusals were rerun successfully on one prepared worker
- Gate: every era positive, continuous CAGR at least `0.15` points above control, PF at least `1.85`, DD at most `1.20%`, no loss of recovery or return/drawdown, at least 390 continuous trades, and neighboring support

| Profile | Net | Increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$2,195.53 | +21.96% | +1.74%/yr | 1.83 | 415 | 1.17% | 15.82 | 18.77 | Control |
| Lookback 3, minimum 0.00 ATR | +$1,084.94 | +10.85% | +0.90%/yr | 1.45 | 390 | 2.31% | 4.34 | 4.70 | Reject |
| Lookback 5, minimum 0.00 ATR | +$1,044.78 | +10.45% | +0.87%/yr | 1.44 | 388 | 2.09% | 4.64 | 5.00 | Reject |
| Lookback 8, minimum 0.00 ATR | +$1,044.78 | +10.45% | +0.87%/yr | 1.44 | 388 | 2.09% | 4.64 | 5.00 | Reject |
| Lookback 3, minimum 0.03 ATR | +$1,084.94 | +10.85% | +0.90%/yr | 1.45 | 390 | 2.31% | 4.34 | 4.70 | Reject |
| Lookback 5, minimum 0.03 ATR | +$1,044.78 | +10.45% | +0.87%/yr | 1.44 | 388 | 2.09% | 4.64 | 5.00 | Reject |
| Lookback 8, minimum 0.03 ATR | +$1,044.78 | +10.45% | +0.87%/yr | 1.44 | 388 | 2.09% | 4.64 | 5.00 | Reject |
| Lookback 5, minimum 0.05 ATR | +$1,060.44 | +10.60% | +0.88%/yr | 1.45 | 387 | 2.09% | 4.71 | 5.07 | Reject |

All candidate eras remained above zero, but every profile failed the growth, PF, drawdown, recovery, and return/drawdown gates. The closest activity row merely met the 390-trade floor and still lost more than half the control's profit.

Trade attribution explains the failure. The disabled control's 38 reversion trades contributed `+$1,383.89`; the least restrictive three-bar gate retained 22 reversion trades and only `+$375.87`. A Bollinger/VWAP exhaustion entry does not generally need to create a new short-term swing extreme, so the extra structural condition removed the lane's largest valid mean-reversion winners. Shared portfolio sequencing also changed some later trend entries, reinforcing rather than repairing the weaker path.

No candidate qualifies for Model 4. The feature remains disabled research code, ATB150 remains the historical champion, and the frozen forward registration is unchanged. This is historical research, not real-money approval.
