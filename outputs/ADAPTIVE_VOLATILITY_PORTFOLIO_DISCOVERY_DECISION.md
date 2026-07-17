# Adaptive Volatility Portfolio Discovery Decision

**Decision: rejected in pre-2021 discovery; holdout, Model 4, and promotion remain closed.**

The exact released Band/VWAP-reversion and E20 momentum entries/exits were retained. Only requested risk changed through a closed-bar H1 ATR/price controller bounded inside the existing 0.75% open-risk cap.

- Source SHA-256: `EE792939C2E50CED18DA0F5B2E885FB30F14ED58CA97AFB92CA553F6AC4C1229`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `24 / 24`
- Fixed-risk control efficiency: `2.5054` return/DD
- Eligible adaptive profiles: `0 / 7`

| Candidate | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Return/DD | Quality | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|
| `avp_upside_only` | +$875.02 | -$131.67 | +$715.75 | 7.16% | 1.16% | 1.38 | 225 | 3.4% | 2.1059 | False | False | REJECT_BEFORE_HOLDOUT |
| `avp_fixed_control` | +$814.70 | -$105.45 | +$694.13 | 6.94% | 1.13% | 1.42 | 225 | 2.77% | 2.5054 | False | False | CONTROL_ONLY |
| `avp_baseline63` | +$821.49 | -$212.41 | +$669.68 | 6.7% | 1.09% | 1.38 | 225 | 3.29% | 2.0365 | False | False | REJECT_BEFORE_HOLDOUT |
| `avp_bounds85_115` | +$808.26 | -$151.25 | +$636.26 | 6.36% | 1.03% | 1.36 | 225 | 3.46% | 1.8382 | False | False | REJECT_BEFORE_HOLDOUT |
| `avp_center` | +$810.02 | -$172.06 | +$628.00 | 6.28% | 1.02% | 1.35 | 225 | 3.43% | 1.8309 | False | False | REJECT_BEFORE_HOLDOUT |
| `avp_baseline252` | +$808.29 | -$210.14 | +$609.95 | 6.1% | 0.99% | 1.34 | 225 | 3.43% | 1.7784 | False | False | REJECT_BEFORE_HOLDOUT |
| `avp_downside_only` | +$747.55 | -$138.44 | +$606.77 | 6.07% | 0.99% | 1.38 | 225 | 2.8% | 2.1679 | False | False | REJECT_BEFORE_HOLDOUT |
| `avp_bounds80_120` | +$811.49 | -$177.16 | +$590.71 | 5.91% | 0.96% | 1.33 | 225 | 3.57% | 1.6555 | False | False | REJECT_BEFORE_HOLDOUT |
