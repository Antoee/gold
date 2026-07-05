# Next Test Priority Queue

Offline planning artifact. No MT5 process was launched.

The goal is to spend the least tester time necessary before making the next decision. Do not run a larger batch if a smaller gate already rejects the candidate.

For the consolidated gate rules, use `outputs/FAST_EXPERIMENT_MATRIX.md` and `outputs/FAST_EXPERIMENT_MATRIX.csv`.

## Order

| Priority | Gate | Batch | Rows | Pass Action | Fail Action |
|---:|---|---|---:|---|---|
| 1 | STATIC_SAFETY | Static repository audit | 1 | Proceed to stress micro if static safety passes. | Fix source/config safety before tester work. |
| 2 | STRESS_MICRO | `tp38_sl18` vs baseline stress windows | 8 | Proceed to recent-OOS only if all paired stress windows pass. | Reject or deprioritize `tp38_sl18`. |
| 3 | RECENT_OOS | `tp38_sl18` vs baseline recent freshness | 8 | Proceed to full handoff only if all recent-OOS windows pass. | Reject or deprioritize `tp38_sl18`. |
| 4 | CONFIRMATION_PROBE | Confirmation-3 strictness probe | 4 | Expand only passing confirmation candidates into stress/recent-OOS validation. | Stop spending tester time on failed confirmation variants. |
| 5 | BREAKEVEN_PROBE | Break-even risk-control probe | 4 | Expand only passing or risk-improving break-even candidates into stress/recent-OOS validation. | Keep break-even disabled for failed variants. |
| 6 | ADX_FILTER_PROBE | ADX 18 trend-strength filter probe | 4 | Expand only passing ADX candidates into stress/recent-OOS validation. | Stop spending tester time on failed ADX variants. |
| 7 | SPREAD_GUARD_PROBE | ATR-relative spread guard probe | 4 | Expand only passing spread-guard candidates into stress/recent-OOS validation. | Stop spending tester time on failed spread-guard variants. |
| 8 | TIME_EXIT_PROBE | 240-minute stale-trade exit probe | 4 | Expand only passing time-exit candidates into stress/recent-OOS validation. | Stop spending tester time on failed time-exit variants. |
| 9 | MTF_TREND_PROBE | H1 200 EMA trend filter probe | 4 | Expand only passing MTF candidates into stress/recent-OOS validation. | Stop spending tester time on failed MTF variants. |
| 10 | STRUCTURE_TRAIL_PROBE | Structure trailing stop probe | 4 | Expand only passing structure-trailing candidates into stress/recent-OOS validation. | Stop spending tester time on failed structure-trailing variants. |
| 11 | SESSION_PROBE | `tp38_sl18` session variants vs unfiltered baseline | 6 | Expand only passing session candidates into stress/recent-OOS validation. | Stop spending tester time on failed session variants. |
| 12 | FULL_HANDOFF | Full candidate validation | 24 | Build promotion packet only if all gates pass. | Keep current promoted baseline. |

## Commands After Reports Exist

All available report packs can be imported with the wrapper:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_all_available_reports.ps1
```

Break-even reports can also be imported directly with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_breakeven_probe_reports.ps1
```

Pack-specific commands remain in their handoff READMEs.

## Bottom Line

Keep the current promoted profile until a candidate survives the small gates and the full promotion evidence. Fast-pack evidence can justify more testing, but it cannot justify promotion.
