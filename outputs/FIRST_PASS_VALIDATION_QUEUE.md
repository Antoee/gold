# First-Pass Validation Queue

Offline queue only. This does not launch MT5.

- EA source hash: `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`
- Total configs: `22`
- Per candidate: `22`
- Active candidates: `trade_ready_conservative`
- Available candidates: `trade_ready_conservative, money_ready`

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
| 1 | trade_ready_conservative | validation | phase0_fast_model1 | continuous_2024_2026 | 1 | `trade_ready_conservative\configs\001_trade_ready_conservative_validation_continuous_2024_2026.ini` | Stop this candidate if fast Model1 is red or produces too few trades. |
| 2 | trade_ready_conservative | validation | phase0_fast_model1 | 2024_full | 1 | `trade_ready_conservative\configs\002_trade_ready_conservative_validation_2024_full.ini` | Stop this candidate if fast Model1 is red or produces too few trades. |
| 3 | trade_ready_conservative | validation | phase0_fast_model1 | 2025_full | 1 | `trade_ready_conservative\configs\003_trade_ready_conservative_validation_2025_full.ini` | Stop this candidate if fast Model1 is red or produces too few trades. |
| 4 | trade_ready_conservative | validation | phase0_fast_model1 | 2026_ytd | 1 | `trade_ready_conservative\configs\004_trade_ready_conservative_validation_2026_ytd.ini` | Stop this candidate if fast Model1 is red or produces too few trades. |
| 5 | trade_ready_conservative | validation | phase1_exact_realtick | continuous_2024_2026 | 4 | `trade_ready_conservative\configs\005_trade_ready_conservative_validation_continuous_2024_2026.ini` | Stop this candidate if exact real-tick full/OOS/recent windows are red or drawdown/PF is unacceptable. |
| 6 | trade_ready_conservative | validation | phase1_exact_realtick | 2024_full | 4 | `trade_ready_conservative\configs\006_trade_ready_conservative_validation_2024_full.ini` | Stop this candidate if exact real-tick full/OOS/recent windows are red or drawdown/PF is unacceptable. |
| 7 | trade_ready_conservative | validation | phase1_exact_realtick | 2025_full | 4 | `trade_ready_conservative\configs\007_trade_ready_conservative_validation_2025_full.ini` | Stop this candidate if exact real-tick full/OOS/recent windows are red or drawdown/PF is unacceptable. |
| 8 | trade_ready_conservative | validation | phase1_exact_realtick | 2026_ytd | 4 | `trade_ready_conservative\configs\008_trade_ready_conservative_validation_2026_ytd.ini` | Stop this candidate if exact real-tick full/OOS/recent windows are red or drawdown/PF is unacceptable. |
| 9 | trade_ready_conservative | validation | phase2_realtick_quarterly | 2024_Q4 | 4 | `trade_ready_conservative\configs\009_trade_ready_conservative_validation_2024_Q4.ini` | Stop this candidate if fragile seasonal windows fail. |
| 10 | trade_ready_conservative | validation | phase2_realtick_quarterly | 2025_Q4 | 4 | `trade_ready_conservative\configs\010_trade_ready_conservative_validation_2025_Q4.ini` | Stop this candidate if fragile seasonal windows fail. |
| 11 | trade_ready_conservative | validation | phase2_realtick_quarterly | 2026_Q2 | 4 | `trade_ready_conservative\configs\011_trade_ready_conservative_validation_2026_Q2.ini` | Stop this candidate if fragile seasonal windows fail. |
| 12 | trade_ready_conservative | validation | phase3_realtick_monthly | 2024_12 | 4 | `trade_ready_conservative\configs\012_trade_ready_conservative_validation_2024_12.ini` | Stop this candidate if fragile seasonal windows fail. |
| 13 | trade_ready_conservative | validation | phase3_realtick_monthly | 2025_12 | 4 | `trade_ready_conservative\configs\013_trade_ready_conservative_validation_2025_12.ini` | Stop this candidate if fragile seasonal windows fail. |
| 14 | trade_ready_conservative | validation | phase4_stress_realtick | continuous_2024_2026 | 4 | `trade_ready_conservative\configs\014_trade_ready_conservative_validation_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 15 | trade_ready_conservative | validation | phase4_stress_realtick | continuous_2024_2026 | 4 | `trade_ready_conservative\configs\015_trade_ready_conservative_validation_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 16 | trade_ready_conservative | validation | phase4_stress_realtick | continuous_2024_2026 | 4 | `trade_ready_conservative\configs\016_trade_ready_conservative_validation_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 17 | trade_ready_conservative | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `trade_ready_conservative\configs\017_trade_ready_conservative_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 18 | trade_ready_conservative | broker_proxy | phase5_broker_proxy_realtick | 2026_ytd | 4 | `trade_ready_conservative\configs\018_trade_ready_conservative_broker_proxy_2026_ytd.ini` | Stop this candidate if stress/broker proxy turns red. |
| 19 | trade_ready_conservative | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `trade_ready_conservative\configs\019_trade_ready_conservative_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 20 | trade_ready_conservative | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `trade_ready_conservative\configs\020_trade_ready_conservative_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 21 | trade_ready_conservative | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `trade_ready_conservative\configs\021_trade_ready_conservative_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
| 22 | trade_ready_conservative | broker_proxy | phase5_broker_proxy_realtick | continuous_2024_2026 | 4 | `trade_ready_conservative\configs\022_trade_ready_conservative_broker_proxy_continuous_2024_2026.ini` | Stop this candidate if stress/broker proxy turns red. |
