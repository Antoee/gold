# Score7 Regime No-M1-Shock Promotion Note

Date: 2026-07-12

## Decision

Promote `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_NO_M1SHOCK_PROFILE.set` as the current research-best candidate.

This profile keeps the M15 spread-regime guard and disables the M1 spread-shock guard:

- `InpUseSpreadRegimeGuard=true`
- `InpMaxSpreadRegimeRatio=1.35`
- `InpMinSpreadRegimePoints=30.0`
- `InpUseM1SpreadShockGuard=false`

SHA-256:

- `0961BBC9C17C122A5DD67498F8BAE2D12241CFCCC8AD3910F6C8BEE2B2FB960A`

## Why

The prior strict Regime profile used an M1 spread-shock guard. That made `Model=2` validation unreliable because MT5 Open Prices mode rejects the M1 data request from the M15 EA:

- `XAUUSD,M1: wrong timeframe request in Open Prices testing mode`
- `XAUUSD: rates base receive error`

The no-M1-shock profile removes that model-incompatible dependency while preserving the profitable M15 spread-regime guard.

## Model=1 Broad Gate

File: `outputs/MODEL1_SCORE7_REGIME_NO_M1SHOCK_LOG_RESULTS.csv`

| Window | Score7 | Strict Regime | No-M1-Shock |
| --- | ---: | ---: | ---: |
| Continuous 2024-2026 | `7970.70` | `9753.58` | `9753.58` |
| Full 2024 | `2507.85` | `3201.96` | `3201.96` |
| Full 2025 | `214.18` | `214.18` | `214.18` |
| 2026 YTD | `1375.04` | `1375.04` | `1375.04` |
| Q4 2025 | `194.82` | `194.82` | `194.82` |
| Q4 2024 | `-0.50` | `-0.50` | `-0.50` |

Result: identical to strict Regime and still better than Score7 on continuous and full 2024.

## Model=1 Quarter Gate

File: `outputs/MODEL1_SCORE7_REGIME_NO_M1SHOCK_QTR_LOG_RESULTS.csv`

| Metric | No-M1-Shock |
| --- | ---: |
| Parsed quarters | `10 / 10` |
| Quarter total | `3638.18` |
| Worst quarter | `-0.50` |
| Losing quarters | `1` |

Result: identical to strict Regime quarter behavior.

## Model=2 Compatibility Gate

File: `outputs/MODEL2_SCORE7_REGIME_NO_M1SHOCK_LOG_RESULTS.csv`

| Window | Score7 | No-M1-Shock | Delta |
| --- | ---: | ---: | ---: |
| Continuous 2024-2026 | `9862.76` | `12054.55` | `+2191.79` |
| Full 2024 | `3082.89` | `3890.81` | `+807.92` |
| Full 2025 | `214.18` | `214.18` | `0.00` |
| 2026 YTD | `1375.04` | `1375.04` | `0.00` |
| Q4 2025 | `194.82` | `194.82` | `0.00` |
| Q4 2024 | `161.23` | `161.23` | `0.00` |

Result: clean `6 / 6` parse with no Model=2 M1 timeframe failure.

## Interpretation

The M1 spread-shock guard was not contributing measurable Model=1 profit on the tested windows, but it did create a validation compatibility problem. Removing it improves research robustness without giving up the current Model=1 edge.

This is still a research-best candidate, not a production guarantee. The next useful gate is real-tick or another independent higher-fidelity source/model check before increasing risk.
