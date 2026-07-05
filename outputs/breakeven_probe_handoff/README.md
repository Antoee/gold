# Break-Even Probe Handoff

Offline handoff pack. No MT5 process was launched to create this file.

## Purpose

This 4-run probe checks whether enabling `InpUseBreakEven=true` improves 2026 YTD robustness compared with the promoted break-even-off behavior. Break-even can reduce tail loss after favorable movement, but it can also cut trades too early, so it must be tested as a paired candidate rather than assumed safer.

## Runs

| Config | Profile | Break-even | Trigger ATR | Offset ATR | Window |
|---|---|---:|---:|---:|---|
| `001_baseline_promoted_2026_ytd.ini` | `baseline_promoted` | `false` | `1.00` | `0.05` | `2026.01.01` to `2026.07.02` |
| `002_baseline_promoted_be_2026_ytd.ini` | `baseline_promoted_be` | `true` | `1.00` | `0.05` | `2026.01.01` to `2026.07.02` |
| `003_tp38_sl18_2026_ytd.ini` | `tp38_sl18` | `false` | `1.00` | `0.05` | `2026.01.01` to `2026.07.02` |
| `004_tp38_sl18_be_2026_ytd.ini` | `tp38_sl18_be` | `true` | `1.00` | `0.05` | `2026.01.01` to `2026.07.02` |

## Decision Gate

Pass only if each break-even candidate:

- has a parsed report,
- has non-negative net profit,
- has net profit greater than or equal to its paired break-even-off baseline, or materially reduces drawdown with only a small profit tradeoff,
- has drawdown reviewed before expansion.

After reports exist, import them with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_all_available_reports.ps1
```

This wrapper imports exported reports only and does not launch MT5.
