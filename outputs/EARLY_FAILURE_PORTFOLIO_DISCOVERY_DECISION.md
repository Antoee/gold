# Early Failure Portfolio Discovery Decision

**Decision: rejected in pre-2021 discovery; holdout, Model 4, and promotion remain closed.**

The exact released entries, initial stops, targets, and risk were retained. New closed-H1-bar exits could only close positions that failed to make the configured R progress after the configured number of bars.

- Source SHA-256: `2613BDF5BFCE4DB9220961540F851E2444F14AF17B690CAAE0AC4BE59C8C1342`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `24 / 24`
- Fixed-risk control efficiency: `2.5054` return/DD
- Eligible early-failure profiles: `0 / 7`

| Candidate | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Return/DD | Quality | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|
| `efp_relaxed` | +$878.67 | -$59.20 | +$801.22 | 8.01% | 1.29% | 1.54 | 226 | 2.3% | 3.4826 | True | False | REJECT_BEFORE_HOLDOUT |
| `efp_rv_only` | +$752.33 | -$31.65 | +$715.24 | 7.15% | 1.16% | 1.46 | 225 | 2.2% | 3.25 | True | False | REJECT_BEFORE_HOLDOUT |
| `efp_slow` | +$790.73 | -$64.96 | +$709.67 | 7.1% | 1.15% | 1.48 | 227 | 2.37% | 2.9958 | True | False | REJECT_BEFORE_HOLDOUT |
| `efp_fixed_control` | +$814.70 | -$105.45 | +$694.13 | 6.94% | 1.13% | 1.42 | 225 | 2.77% | 2.5054 | False | False | CONTROL_ONLY |
| `efp_center` | +$770.78 | -$75.07 | +$680.60 | 6.81% | 1.1% | 1.54 | 224 | 2.21% | 3.0814 | True | False | REJECT_BEFORE_HOLDOUT |
| `efp_mo_only` | +$814.14 | -$147.90 | +$643.73 | 6.44% | 1.05% | 1.48 | 224 | 2.79% | 2.3082 | False | False | REJECT_BEFORE_HOLDOUT |
| `efp_strict` | +$546.90 | -$99.96 | +$436.28 | 4.36% | 0.71% | 1.36 | 232 | 2.26% | 1.9292 | False | False | REJECT_BEFORE_HOLDOUT |
| `efp_fast` | +$512.77 | -$78.90 | +$428.47 | 4.28% | 0.7% | 1.35 | 228 | 1.91% | 2.2408 | False | False | REJECT_BEFORE_HOLDOUT |
