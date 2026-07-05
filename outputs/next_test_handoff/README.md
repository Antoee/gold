# Next Test Handoff

Generated without launching MT5. This folder is a handoff package for the next safe testing window.

- Source batch: `outputs\NEXT_PROFIT_SEARCH_BATCH.csv`
- Config count: 24
- Config folder: `configs/`
- Manifest: `HANDOFF_MANIFEST.csv`

## Safety

Do not run these locally while MT5 is locked for PC usability. Local MT5 launch requires ALLOW_MT5_FOCUS_RISK=1 and work\ALLOW_MT5_LOCAL_LAUNCH.unlock, and should only be enabled after a controlled hidden-desktop test.

## Run Order

| Rank | Profile | Phase | Set | Window | Model | Config | Expected Report |
|---:|---|---|---|---|---:|---|---|
| 1 | `baseline_promoted` | phase1_fast_triage | stress | 2024_Q1 | 2 | `configs/001_baseline_promoted_stress_2024_Q1_phase1_fast_triage.ini` | `profit_search_phase1_baseline_promoted_stress_2024_Q1` |
| 2 | `baseline_promoted` | phase1_fast_triage | stress | 2024_Q3 | 2 | `configs/002_baseline_promoted_stress_2024_Q3_phase1_fast_triage.ini` | `profit_search_phase1_baseline_promoted_stress_2024_Q3` |
| 3 | `baseline_promoted` | phase1_fast_triage | stress | 2025_Q2 | 2 | `configs/003_baseline_promoted_stress_2025_Q2_phase1_fast_triage.ini` | `profit_search_phase1_baseline_promoted_stress_2025_Q2` |
| 4 | `baseline_promoted` | phase1_fast_triage | stress | 2025_Q3 | 2 | `configs/004_baseline_promoted_stress_2025_Q3_phase1_fast_triage.ini` | `profit_search_phase1_baseline_promoted_stress_2025_Q3` |
| 5 | `tp38_sl18` | phase1_fast_triage | stress | 2024_Q1 | 2 | `configs/005_tp38_sl18_stress_2024_Q1_phase1_fast_triage.ini` | `profit_search_phase1_tp38_sl18_stress_2024_Q1` |
| 6 | `tp38_sl18` | phase1_fast_triage | stress | 2024_Q3 | 2 | `configs/006_tp38_sl18_stress_2024_Q3_phase1_fast_triage.ini` | `profit_search_phase1_tp38_sl18_stress_2024_Q3` |
| 7 | `tp38_sl18` | phase1_fast_triage | stress | 2025_Q2 | 2 | `configs/007_tp38_sl18_stress_2025_Q2_phase1_fast_triage.ini` | `profit_search_phase1_tp38_sl18_stress_2025_Q2` |
| 8 | `tp38_sl18` | phase1_fast_triage | stress | 2025_Q3 | 2 | `configs/008_tp38_sl18_stress_2025_Q3_phase1_fast_triage.ini` | `profit_search_phase1_tp38_sl18_stress_2025_Q3` |
| 9 | `tp42_sl18` | phase1_fast_triage | stress | 2024_Q1 | 2 | `configs/009_tp42_sl18_stress_2024_Q1_phase1_fast_triage.ini` | `profit_search_phase1_tp42_sl18_stress_2024_Q1` |
| 10 | `tp42_sl18` | phase1_fast_triage | stress | 2024_Q3 | 2 | `configs/010_tp42_sl18_stress_2024_Q3_phase1_fast_triage.ini` | `profit_search_phase1_tp42_sl18_stress_2024_Q3` |
| 11 | `tp42_sl18` | phase1_fast_triage | stress | 2025_Q2 | 2 | `configs/011_tp42_sl18_stress_2025_Q2_phase1_fast_triage.ini` | `profit_search_phase1_tp42_sl18_stress_2025_Q2` |
| 12 | `tp42_sl18` | phase1_fast_triage | stress | 2025_Q3 | 2 | `configs/012_tp42_sl18_stress_2025_Q3_phase1_fast_triage.ini` | `profit_search_phase1_tp42_sl18_stress_2025_Q3` |
| 13 | `tp38_sl16` | phase1_fast_triage | stress | 2024_Q1 | 2 | `configs/013_tp38_sl16_stress_2024_Q1_phase1_fast_triage.ini` | `profit_search_phase1_tp38_sl16_stress_2024_Q1` |
| 14 | `tp38_sl16` | phase1_fast_triage | stress | 2024_Q3 | 2 | `configs/014_tp38_sl16_stress_2024_Q3_phase1_fast_triage.ini` | `profit_search_phase1_tp38_sl16_stress_2024_Q3` |
| 15 | `tp38_sl16` | phase1_fast_triage | stress | 2025_Q2 | 2 | `configs/015_tp38_sl16_stress_2025_Q2_phase1_fast_triage.ini` | `profit_search_phase1_tp38_sl16_stress_2025_Q2` |
| 16 | `tp38_sl16` | phase1_fast_triage | stress | 2025_Q3 | 2 | `configs/016_tp38_sl16_stress_2025_Q3_phase1_fast_triage.ini` | `profit_search_phase1_tp38_sl16_stress_2025_Q3` |
| 17 | `tp42_sl16` | phase1_fast_triage | stress | 2024_Q1 | 2 | `configs/017_tp42_sl16_stress_2024_Q1_phase1_fast_triage.ini` | `profit_search_phase1_tp42_sl16_stress_2024_Q1` |
| 18 | `tp42_sl16` | phase1_fast_triage | stress | 2024_Q3 | 2 | `configs/018_tp42_sl16_stress_2024_Q3_phase1_fast_triage.ini` | `profit_search_phase1_tp42_sl16_stress_2024_Q3` |
| 19 | `tp42_sl16` | phase1_fast_triage | stress | 2025_Q2 | 2 | `configs/019_tp42_sl16_stress_2025_Q2_phase1_fast_triage.ini` | `profit_search_phase1_tp42_sl16_stress_2025_Q2` |
| 20 | `tp42_sl16` | phase1_fast_triage | stress | 2025_Q3 | 2 | `configs/020_tp42_sl16_stress_2025_Q3_phase1_fast_triage.ini` | `profit_search_phase1_tp42_sl16_stress_2025_Q3` |
| 21 | `baseline_promoted` | phase1_fast_triage | full | full | 2 | `configs/021_baseline_promoted_full_full_phase1_fast_triage.ini` | `profit_search_phase1_baseline_promoted_full_full` |
| 22 | `tp45_sl18` | phase1_fast_triage | stress | 2024_Q1 | 2 | `configs/022_tp45_sl18_stress_2024_Q1_phase1_fast_triage.ini` | `profit_search_phase1_tp45_sl18_stress_2024_Q1` |
| 23 | `tp45_sl18` | phase1_fast_triage | stress | 2024_Q3 | 2 | `configs/023_tp45_sl18_stress_2024_Q3_phase1_fast_triage.ini` | `profit_search_phase1_tp45_sl18_stress_2024_Q3` |
| 24 | `tp45_sl18` | phase1_fast_triage | stress | 2025_Q2 | 2 | `configs/024_tp45_sl18_stress_2025_Q2_phase1_fast_triage.ini` | `profit_search_phase1_tp45_sl18_stress_2025_Q2` |

## After Reports Exist

1. Export reports into outputs/.
2. Run the profit-search collector command from NEXT_VALIDATION_RUNBOOK.md.
3. Rerun work/analyze_profit_search.ps1.
4. Rerun work/build_next_profit_search_batch.ps1.
5. For any promising profile, run work/build_profit_promotion_packet.ps1 -Profile <profile_name>.
