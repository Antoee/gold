# Micro Handoff Config Integrity

Offline tracking artifact. This record does not launch MT5.

- Manifest: `outputs\micro_test_handoff\HANDOFF_MANIFEST.csv`
- Configs expected: 8
- Config files committed: 8
- Passed static intent checks: 8
- Failed: 0
- Top candidate: `tp38_sl18`
- Baseline anchor: `baseline_promoted`

## Static Intent Checks

The committed configs are intended to use:

- `Expert=Professional_XAUUSD_EA.ex5`
- `Symbol=XAUUSD`
- `Period=M15`
- `Model=2`
- `Optimization=0`
- `Visual=0`
- `ReplaceReport=1`
- `ShutdownTerminal=1`
- candidate `InpTakeProfitATRMultiplier=3.80`
- candidate `InpMaxEquityDrawdownPercent=4.00`
- baseline `InpTakeProfitATRMultiplier=3.50`
- baseline `InpMaxEquityDrawdownPercent=0.00`

## Paired Stress Windows

| Rank | Profile | Window | Role |
|---:|---|---|---|
| 1 | `tp38_sl18` | 2024_Q1 | Candidate |
| 2 | `baseline_promoted` | 2024_Q1 | Baseline |
| 3 | `tp38_sl18` | 2024_Q3 | Candidate |
| 4 | `baseline_promoted` | 2024_Q3 | Baseline |
| 5 | `tp38_sl18` | 2025_Q2 | Candidate |
| 6 | `baseline_promoted` | 2025_Q2 | Baseline |
| 7 | `tp38_sl18` | 2025_Q3 | Candidate |
| 8 | `baseline_promoted` | 2025_Q3 | Baseline |

## Decision Rule

If `tp38_sl18` loses any paired stress window, keep the current promoted profile and deprioritize it. If it matches or improves every paired window, continue to the full 24-config handoff and phase-2 real ticks before promotion.
