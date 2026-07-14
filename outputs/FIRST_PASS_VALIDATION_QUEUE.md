# First-Pass Validation Queue

Offline queue only. This does not launch MT5.

- EA source hash: `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`
- Total configs: `22`
- Per candidate: `22`
- Active candidates: `lowatr_locked_risk18pure`
- Available candidates: `trade_ready_conservative, money_ready, lowatr_locked_research, lowatr_locked_risk20, lowatr_locked_risk23, lowatr_locked_risk23pure, lowatr_locked_risk20pure, lowatr_locked_risk18pure`

## Purpose

Run this queue before the full 53-config validation packages. It is designed to reject weak candidates faster without weakening the full live-readiness gate. By default it focuses on the current scorecard candidate; pass `-ActiveCandidates trade_ready_conservative,money_ready` only when a deliberate comparison run is worth the extra tester time.

## Run Order

1. Fast Model1 sanity: ranks 1-4 from the full package.
2. Exact real-tick proof: continuous, 2024 train, 2025 OOS, and 2026 YTD.
3. Fragile seasonal checks: Q4 2024, Q4 2025, Q2 2026, December 2024, and December 2025.
4. Stress checks: spread, cost, and tight-execution full-period stress.
5. Broker proxy checks: base full/recent plus wide-spread, high-commission, tight-slippage, and margin-pressure full-period proxies.

## Rule

Passing this queue is not live approval. It only earns the right to spend time on the full validation packages.

## Report Import And Decision

After MT5 exports the queued reports into each candidate's `reports_here` folder, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File work\import_first_pass_validation_queue_reports.ps1
```

Then read `outputs/FIRST_PASS_VALIDATION_QUEUE_DECISION.md` and `outputs/FIRST_PASS_VALIDATION_QUEUE_CANDIDATE_RANKING.csv`. Use `work\select_first_pass_next_run_batch.ps1` to write `outputs/FIRST_PASS_NEXT_RUN_BATCH.md` after every import, so only the next useful stage is run. A passing first-pass decision is still not live approval; it only permits the slower full validation packages.

| Rank | Candidate | Source | Phase | Window | Model | Config | Stop Rule |
| ---: | --- | --- | --- | --- | ---: | --- | --- |
| 1 | lowatr_locked_risk18pure | validation | phase0_fast_model1 | continuous_2024_2026 | 1 | `lowatr_locked_risk18pure\configs\001_lowatr_locked_risk18pure_validation_continuous_2024_2026.ini` | Stop this candidate if fast Model1 is red or produces too few trades. |
| 2 | lowatr_locked_risk18pure | validation | phase0_fast_model1 | 2024_full | 1 | `lowatr_locked_risk18pure\configs\002_lowatr_locked_risk18pure_validation_2024_full.ini` | Stop this candidate if fast Model1 is red or produces too few trades. |
| 3 | lowatr_locked_risk18pure | validation | phase0_fast_model1 | 2025_full | 1 | `lowatr_locked_risk18pure\configs\003_lowatr_locked_risk18pure_validation_2025_full.ini` | Stop this candidate if fast Model1 is red or produces too few trades. |
| 4 | lowatr_locked_risk18pure | validation | phase0_fast_model1 | 2026_ytd | 1 | `lowatr_locked_risk18pure\configs\004_lowatr_locked_risk18pure_validation_2026_ytd.ini` | Stop this candidate if fast Model1 is red or produces too few trades. |
| 5 | lowatr_locked_risk18pure | validation | phase1_exact_realtick | continuous_2024_2026 | 4 | `lowatr_locked_risk18pure\configs\005_lowatr_locked_risk18pure_validation_continuous_2024_2026.ini` | Stop this candidate if exact real-tick full/OOS/recent windows are red or drawdown/PF is unacceptable. |
| 6 | lowatr_locked_risk18pure | validation | phase1_exact_realtick | 2024_full | 4 | `lowatr_locked_risk18pure\configs\006_lowatr_locked_risk18pure_validation_2024_full.ini` | Stop this candidate if exact real-tick full/OOS/recent windows are red or drawdown/PF is unacceptable. |
| 7 | lowatr_locked_risk18pure | validation | phase1_exact_realtick | 2025_full | 4 | `lowatr_locked_risk18pure\configs\007_lowatr_locked_risk18pure_validation_2025_full.ini` | Stop this candidate if exact real-tick full/OOS/recent windows are red or drawdown/PF is unacceptable. |
| 8 | lowatr_locked_risk18pure | validation | phase1_exact_realtick | 2026_ytd | 4 | `lowatr_locked_risk18pure\configs\008_lowatr_locked_risk18pure_validation_2026_ytd.ini` | Stop this candidate if exact real-tick full/OOS/recent windows are red or drawdown/PF is unacceptable. |
| 9 | lowatr_locked_risk18pure | validation | phase2_realtick_quarterly | 2024_Q4 | 4 | `lowatr_locked_risk18pure\configs\009_lowatr_locked_risk18pure_validation_2024_Q4.ini` | Stop this candidate if fragile seasonal windows fail. |
| 10 | lowatr_locked_risk18pure | validation | phase2_realtick_quarterly | 2025_Q4 | 4 | `lowatr_locked_risk18pure\configs\010_lowatr_locked_risk18pure_validation_2025_Q4.ini` | Stop this candidate if fragile seasonal windows fail. |
| 11 | lowatr_locked_risk18pure | validation | phase2_realtick_quarterly | 2026_Q2 | 4 | `lowatr_locked_risk18pure\configs\011_lowatr_locked_risk18pure_validation_2026_Q2.ini` | Stop this candidate if fragile seasonal windows fail. |
| 12 | lowatr_locked_risk18pure | validation | phase3_realtick_monthly | 2024_12 | 4 | `lowatr_locked_risk18pure\configs\012_lowatr_locked_risk18pure_validation_2024_12.ini` | Stop this candidate if fragile seasonal windows fail. |
| 13 | lowatr_locked_risk18pure | validation | phase3_realtick_monthly | 2025_12 | 4 | `lowatr_locked_risk18pure\configs\013_lowatr_locked_risk18pure_validation_2025_12.ini` | Stop this candidate if fragile seasonal windows fail. |
| 14 | lowatr_locked_risk18pure | validation | phase4_stress_realtick | continuous_2024_2026 | 4 | `lowatr_locked_risk18pure\configs\014_lowatr_locked_risk18pure_validation_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 15 | lowatr_locked_risk18pure | validation | phase4_stress_realtick | continuous_2024_2026 | 4 | `lowatr_locked_risk18pure\configs\015_lowatr_locked_risk18pure_validation_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 16 | lowatr_locked_risk18pure | validation | phase4_stress_realtick | continuous_2024_2026 | 4 | `lowatr_locked_risk18pure\configs\016_lowatr_locked_risk18pure_validation_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 17 | lowatr_locked_risk18pure | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `lowatr_locked_risk18pure\configs\017_lowatr_locked_risk18pure_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 18 | lowatr_locked_risk18pure | broker_proxy | phase5_broker_proxy_realtick | 2026_ytd | 4 | `lowatr_locked_risk18pure\configs\018_lowatr_locked_risk18pure_broker_proxy_2026_ytd.ini` | Stop this candidate if stress/broker proxy turns red. |
| 19 | lowatr_locked_risk18pure | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `lowatr_locked_risk18pure\configs\019_lowatr_locked_risk18pure_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 20 | lowatr_locked_risk18pure | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `lowatr_locked_risk18pure\configs\020_lowatr_locked_risk18pure_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 21 | lowatr_locked_risk18pure | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `lowatr_locked_risk18pure\configs\021_lowatr_locked_risk18pure_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 22 | lowatr_locked_risk18pure | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `lowatr_locked_risk18pure\configs\022_lowatr_locked_risk18pure_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
