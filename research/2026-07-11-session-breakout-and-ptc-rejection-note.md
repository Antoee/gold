# Session Breakout and PTC Rejection Note

Date: 2026-07-11

## Decision

Do not promote Session Impulse, Breakout Continuation, or Power Trend Continuation variants.

The current research-best remains:

```text
outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set
```

## Initial Probe

Source: `outputs/CURRENT_BEST_SESSION_BREAKOUT_MODEL0_PROBE_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: |
| `ptc_house_strict` | `8 / 8` | `11168.03` | `7809.39` | `0.00` | `0` |
| `base` | `8 / 8` | `9580.99` | `6222.35` | `0.00` | `0` |
| `sil_flat_strict` | `8 / 8` | `4598.65` | `1266.65` | `-9.32` | `1` |
| `sil_engine_only` | `8 / 8` | `4423.70` | `1086.89` | `0.00` | `0` |
| `bcq_follow_strict` | `8 / 8` | `3142.20` | `693.78` | `-23.26` | `1` |

Session Impulse and Breakout Continuation were immediate rejects. PTC looked promising enough to require broader validation.

## Broad PTC Validation

Source: `outputs/CURRENT_BEST_PTC_MODEL0_VALIDATION_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `ptc_house_strict` | `34 / 34` | `13956.72` | `7809.39` | `49.99` | `214.30` | `2354.20` | `-24.90` | `6` |
| `base` | `34 / 34` | `13561.72` | `6222.35` | `1107.93` | `214.30` | `2390.20` | `0.00` | `0` |

PTC improved the continuous run, but failed robustness:

```text
2026 YTD base:             1107.93
2026 YTD ptc_house_strict:   49.99
```

Negative PTC months:

```text
2024_12: -17.76
2025_06:  -3.56
2025_10: -24.85
2025_12: -23.20
2026_02: -24.90
2026_06: -22.35
```

## Salvage Probe

Source: `outputs/CURRENT_BEST_PTC_SALVAGE_MODEL0_PROBE_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `ptc_no_bypass_house` | `13 / 13` | `9587.04` | `6676.03` | `49.99` | `214.30` | `2675.88` | `-24.90` | `5` |
| `ptc_low_risk_nohouse` | `13 / 13` | `9248.04` | `6622.20` | `49.99` | `214.30` | `2433.12` | `-24.90` | `6` |
| `base` | `13 / 13` | `9962.58` | `6222.35` | `1107.93` | `214.30` | `2390.20` | `0.00` | `0` |
| `ptc_micro_strict_nohouse` | `13 / 13` | `4310.98` | `2223.20` | `49.99` | `214.30` | `1915.52` | `-24.90` | `6` |

Risk reduction and no-bypass variants did not repair the recent-period failure.

## Interpretation

PTC is a tempting but unsafe improvement: it raises continuous profit while breaking the no-losing-window constraint and damaging recent 2026 performance. Promoting it would chase historical profit at the cost of robustness.

The next useful direction should avoid broad continuation lanes and instead focus on either:

- explicit month/session-specific opportunity discovery with out-of-sample confirmation,
- code-level guardrails that prevent a new lane from damaging YTD/full-year validation,
- or a separate low-frequency edge that can prove itself on monthly attribution before it is allowed into the continuous profile.
