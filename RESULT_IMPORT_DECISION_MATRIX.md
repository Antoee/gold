# Result Import Decision Matrix

Generated from normalized ranking evidence only. No MT5 process was launched.

- Ranking source: `outputs\PROFIT_SEARCH_RANKING.csv`
- Rows reviewed: 21

## Decision Counts

| Decision | Rows |
|---|---:|
| RunMissingReports | 21 |

## Immediate Queue

| Rank | Profile | Phase | Grade | Parsed | Decision | Reason |
|---:|---|---|---|---:|---|---|
| 1 | `baseline_promoted` | phase2_real_tick_validation | MissingEvidence | 0/11 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 2 | `baseline_promoted` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 3 | `tp38_sl18` | phase2_real_tick_validation | MissingEvidence | 0/11 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 4 | `tp38_sl18` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 5 | `tp42_sl18` | phase2_real_tick_validation | MissingEvidence | 0/11 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 6 | `tp42_sl18` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 7 | `tp38_sl16` | phase2_real_tick_validation | MissingEvidence | 0/11 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 8 | `tp38_sl16` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 9 | `tp42_sl16` | phase2_real_tick_validation | MissingEvidence | 0/11 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 10 | `tp42_sl16` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 11 | `tp45_sl18` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 12 | `tp38_sl20` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 13 | `trail14_tp38` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 14 | `trail18_tp38` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 15 | `rr18_tp42` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 16 | `risk18_tp38_sl18` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 17 | `risk20_tp38_sl18` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 18 | `risk14_tp42_sl16` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 19 | `giveback25_tp38` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 20 | `giveback35_tp38` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |
| 21 | `be12_tp38` | phase1_fast_triage | MissingEvidence | 0/8 | RunMissingReports | Run or import the missing reports for this profile and phase. |

## Rules

- `RunMissingReports`: evidence is missing; run/import those reports before judging.
- `RepairReport`: a report exists but did not parse; fix export format or parser coverage.
- `AdvanceToPhase2`: phase-1 evidence is complete and clean enough to justify real-tick validation.
- `BuildPromotionPacket`: phase-2 evidence passed automatic profit/no-loss gates; still requires promotion packet review.
- `RejectForLossRisk`: any losing validation window blocks promotion, even if net profit is positive.
- `KeepForResearch`: useful clue, but not a replacement for the promoted default.
