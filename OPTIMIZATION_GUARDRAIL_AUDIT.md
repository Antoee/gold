# Optimization Guardrail Audit

Offline audit only. No MT5 process was launched.

- Profiles audited: 16
- Config manifest rows: 183
- Guardrail rule: promotion candidates should avoid date blocks, keep risk near or below the promoted 1.60%, preserve BOS+sweep confirmations, and pass phase-2 real-tick evidence before replacement.

## Status Counts

| Status | Profiles |
|---|---:|
| REVIEW_REQUIRED | 16 |

## Top Test-Eligible Candidates

| Profile | Status | Score | Risk % | SL ATR | TP ATR | Giveback | Phase1 | Phase2 | Next Action |
|---|---|---:|---:|---:|---:|---|---:|---:|---|
| `giveback25_tp38` | REVIEW_REQUIRED | 87 | 1.6 | 1.8 | 3.8 | True | 8 | 0 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `giveback35_tp38` | REVIEW_REQUIRED | 87 | 1.6 | 1.8 | 3.8 | True | 8 | 0 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `baseline_promoted` | REVIEW_REQUIRED | 82 | 1.6 | 1.8 | 3.5 | False | 8 | 11 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `tp38_sl18` | REVIEW_REQUIRED | 82 | 1.6 | 1.8 | 3.8 | False | 8 | 11 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `trail18_tp38` | REVIEW_REQUIRED | 82 | 1.6 | 1.8 | 3.8 | False | 8 | 0 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `trail14_tp38` | REVIEW_REQUIRED | 82 | 1.6 | 1.8 | 3.8 | False | 8 | 0 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `tp38_sl20` | REVIEW_REQUIRED | 82 | 1.6 | 2 | 3.8 | False | 8 | 0 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `be12_tp38` | REVIEW_REQUIRED | 82 | 1.6 | 1.8 | 3.8 | False | 8 | 0 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `risk18_tp38_sl18` | REVIEW_REQUIRED | 82 | 1.8 | 1.8 | 3.8 | False | 8 | 0 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `risk20_tp38_sl18` | REVIEW_REQUIRED | 82 | 2 | 1.8 | 3.8 | False | 8 | 0 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `tp38_sl16` | REVIEW_REQUIRED | 72 | 1.6 | 1.6 | 3.8 | False | 8 | 11 | Eligible for testing, but require stricter promotion review before replacing the default. |
| `tp42_sl18` | REVIEW_REQUIRED | 72 | 1.6 | 1.8 | 4.2 | False | 8 | 11 | Eligible for testing, but require stricter promotion review before replacing the default. |

## Review Queue

| Profile | Score | Risk Flags | Overfit Flags | Structure Flags | Next Action |
|---|---:|---|---|---|---|
| `giveback35_tp38` | 87 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `giveback25_tp38` | 87 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `trail18_tp38` | 82 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `tp38_sl18` | 82 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `tp38_sl20` | 82 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `trail14_tp38` | 82 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `baseline_promoted` | 82 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `be12_tp38` | 82 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `risk18_tp38_sl18` | 82 | equity_drawdown_guard_disabled;risk_percent_above_promoted | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `risk20_tp38_sl18` | 82 | equity_drawdown_guard_disabled;risk_percent_above_promoted | adaptive_reverse_requires_walk_forward |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `tp45_sl18` | 72 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward;far_tp_extension |  | Eligible for testing, but require stricter promotion review before replacing the default. |
| `tp38_sl16` | 72 | equity_drawdown_guard_disabled | adaptive_reverse_requires_walk_forward;tighter_stop_variant |  | Eligible for testing, but require stricter promotion review before replacing the default. |

## Bottom Line

Use this audit to prevent high-profit-looking variants from bypassing risk discipline. PASS means eligible for testing, not eligible for promotion. Promotion still requires the full no-losing-window gate.
