# Three-Lane Residual-Risk V2 Decision

**Decision: REJECTED IN THE MODEL 1 PARAMETER NEIGHBORHOOD. MODEL 4 WAS NOT OPENED. NO NEW BEST.**

V2 repaired V1's most important behavioral problem. Every entry first had to produce a nonzero lot size at the original ATB150 base lane risk; only an already-tradable signal could receive residual-risk expansion. This prevents sizing from directly admitting previously unaffordable minimum-lot signals.

- Source SHA-256: `D468B984972E84FE2F0E368035EB74841D8B1856AEA56A893FB819DFE4C482E4`
- Exact portable EX5 SHA-256: `3648FA7B27F39CD6A4398D938C83C285164CBF95EEE300B98B522E7A857828CD`
- Compile: `0 errors, 0 warnings`
- Static safety: three base-lot eligibility gates, zero new buy/sell paths, feature disabled by default, outcome-independent sizing, post-fill reconciliation retained
- Controlled evidence: `48 / 48` reports, one worker per matrix, one pinned binary, zero report errors

## Initial Screen

Model 1, `$10,000`, continuous 2015-2026:

| Profile | Momentum max | Adaptive max | Net | Total increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Control | 0.15% | 0.15% | +$2,195.53 | +21.96% | +1.74%/yr | 1.83 | 415 | 1.17% | 15.82 | 18.77 |
| AT250 | 0.15% | 0.25% | +$2,314.72 | +23.15% | +1.82%/yr | 1.82 | 415 | 1.28% | 16.33 | 18.09 |
| AT300 | 0.15% | 0.30% | +$2,538.11 | +25.38% | +1.98%/yr | 1.85 | 415 | 1.36% | 16.74 | 18.66 |
| Pair low | 0.175% | 0.25% | +$2,480.88 | +24.81% | +1.94%/yr | 1.77 | 415 | 1.49% | 14.92 | 16.65 |
| Pair center | 0.175% | 0.30% | +$2,832.59 | +28.33% | +2.19%/yr | 1.83 | 416 | 1.50% | 16.33 | 18.89 |
| Pair high | 0.20% | 0.30% | +$2,886.28 | +28.86% | +2.22%/yr | 1.75 | 416 | 1.76% | 14.05 | 16.40 |

`Pair center` passed the initial screen: all three disjoint eras were profitable, CAGR improved by `0.45` percentage points, PF was unchanged, drawdown remained below `2.25%`, and both recovery and return/drawdown exceeded control. The one-trade difference can arise indirectly from the changed balance/loss-limit path; V2 still refused every entry that was not base-lot eligible at its own decision time.

## Neighborhood Rejection

The preregistered gate required at least three adjacent momentum ceilings to remain no worse than control on both return/drawdown and recovery. Adaptive maximum stayed fixed at `0.30%`.

| Momentum max | Net | Total increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD | Gate |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 0.160% | +$2,621.40 | +26.21% | +2.04%/yr | 1.84 | 415 | 1.41% | 16.29 | 18.59 | Return/DD below control |
| 0.165% | +$2,657.50 | +26.58% | +2.07%/yr | 1.82 | 415 | 1.49% | 15.62 | Both below control |
| 0.170% | +$2,776.71 | +27.77% | +2.15%/yr | 1.84 | 416 | 1.48% | 16.32 | 18.764 | Return/DD below control `18.769` |
| **0.175% center** | **+$2,832.59** | **+28.33%** | **+2.19%/yr** | **1.83** | **416** | **1.50%** | **16.33** | **18.89** | Initial pass only |
| 0.180% | +$2,810.82 | +28.11% | +2.17%/yr | 1.81 | 416 | 1.58% | 15.82 | 17.79 | Return/DD below control |
| 0.185% | +$2,784.55 | +27.85% | +2.15%/yr | 1.78 | 416 | 1.62% | 14.86 | 17.19 | Both below control |
| 0.190% | +$2,807.44 | +28.07% | +2.17%/yr | 1.77 | 416 | 1.62% | 14.99 | 17.33 | Both below control |

The closest lower neighbor missed by only `0.005`, but the rule was frozen before the run and was not loosened afterward. The center is therefore treated as a lot-step-sensitive single point, not a robust allocation plateau. Model 4, annual, stress, release, forward-registration, and real-account gates remain closed.

ATB150 remains the most stable historical bot. The frozen forward candidate, account contract, source/profile/binary identity, evidence logs, and real-account lock are unchanged.
