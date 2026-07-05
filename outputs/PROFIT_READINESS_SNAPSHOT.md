# Profit Readiness Snapshot

Offline snapshot only. No MT5 process was launched.

| Area | Status | Evidence | Next Action |
|---|---|---|---|
| Promoted profile | KEEP_CURRENT | Current promoted profile remains risk1p6_sl18_tp35: full-period +866.59, split aggregate +2354.65, monthly/quarter aggregate +744.03, zero losing validation windows in existing evidence. | Do not replace until a candidate passes phase-2 real ticks plus the full promotion gate. |
| Static safety automation | CONFIGURED | GitHub Actions workflow `.github/workflows/static-safety.yml` runs `work/static_repo_safety_audit.py` on push, pull request, and manual dispatch. | Use the Actions result as a repository safety gate before spending tester time; it does not prove profit. |
| Profit search evidence | WAITING_FOR_REPORTS | Current candidate evidence is incomplete; imported report metrics are still missing. | Import/export the missing reports, then rerun collector, ranking, decision matrix, and promotion packet scripts. |
| Micro decision | WAITING_FOR_REPORTS | WAITING_FOR_REPORTS=4 | Complete paired stress micro report import before running recent-OOS and full handoff tests. |
| Recent OOS handoff | WAITING_FOR_REPORTS | Recent out-of-sample pack prepared for 2025_Q4, 2026_Q1, 2026_Q2, and 2026_YTD candidate-vs-baseline checks. | Run only after stress micro passes; reject the candidate if it loses any recent-OOS paired window. |
| Session variant probe | WAITING_FOR_REPORTS | Session variant pack prepared for London, New York, and overlap windows on 2026_YTD. | Treat as a probe only; expand a session candidate only if it beats its paired baseline and stays profitable. |
| Promotion gate | MISSING_REPORT | No promotion gate evidence for the current candidate has passed. | Only promote a new candidate if its gate status passes all full, split, quarter, and month evidence checks. |
| Optimization guardrails | TRACKED | Candidate tp38_sl18 is tracked with equity drawdown guard active and promotion review required. | Use guardrail status before spending tester time or building promotion packets. |
| Handoff integrity | PASS | Full handoff, stress micro handoff, recent-OOS handoff, and session variant handoff are statically prepared for controlled tester use. | Use handoff packs only during a controlled non-interrupting tester window. |
| Local PC safety | PASS | Local MT5 launch remains locked unless explicit unlock flags and unlock files are set. | Keep MT5 local launch disabled while the PC is in normal use. |
| Replacement readiness | NOT_READY | No candidate has enough imported evidence to replace the current promoted profile. | Gather paired stress micro reports first, then recent-OOS reports, then full validation if both fast gates pass. |

## Bottom Line

Keep the current promoted profile. The repository now has a remote static safety workflow plus a small session-filter probe, but the next profit improvement is still blocked by missing exported MT5 reports. Fastest safe order: static safety, stress micro, recent out-of-sample through 2026, optional session probe, then full validation.
