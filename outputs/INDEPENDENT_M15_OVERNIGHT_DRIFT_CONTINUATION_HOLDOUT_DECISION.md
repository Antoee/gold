# Independent M15 Overnight-Drift Continuation Holdout Decision

**Decision: REJECTED IN POST-2020 HOLDOUT. No Model 4 escalation, new best, or live approval was opened.**

The center and two orthogonal one-factor discovery survivors were frozen before opening post-2020 data. Each row retains the exact source and profile identity, a `$10,000` initial-balance contract, broker-native risk sizing, minimum-lot refusal, account-wide exposure limits, drawdown locks, and disabled real-account trading.

- Source SHA-256: `B74E61CC7B473C03FCA79E1D8DC0C73C4512FCCF9596E439971E1D7C82149684`
- Compile: `0 errors, 0 warnings`
- Risk per accepted trade: `0.10%` on a `$10,000` test deposit
- Exported Model 1 reports: `12 / 12`
- Frozen holdout windows: `2021-2022`, `2023-2024`, `2025-2026 YTD`, and continuous `2021-2026 YTD`
- Holdout survivors: `0 / 3`

| Candidate | 2021-22 | PF | 2023-24 | PF | 2025-26 | PF | Continuous | CAGR | PF | Trades | DD | Return/DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `odc_signal25` | +$50.81 | 1.36 | -$5.77 | 0.96 | +$15.82 | 3.75 | +$54.19 | 0.1% | 1.17 | 99 | 0.7% | 0.7723 | REJECT_BEFORE_MODEL4 |
| `odc_entry8` | -$17.99 | 0.89 | +$62.67 | 1.52 | -$1.38 | 0.89 | +$36.13 | 0.07% | 1.12 | 99 | 0.78% | 0.4628 | REJECT_BEFORE_MODEL4 |
| `odc_center` | +$36.17 | 1.29 | -$25.53 | 0.83 | +$15.82 | 3.75 | +$19.29 | 0.03% | 1.07 | 90 | 0.89% | 0.2164 | REJECT_BEFORE_MODEL4 |

## Action

- Reject this overnight-drift continuation family without Model 4 escalation.
- Do not tune parameters against the holdout failures.
- Keep the released transferable portfolio unchanged until every escalation gate passes.
- Preserve the portable runner and exact report/source identity evidence.
