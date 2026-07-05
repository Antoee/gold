# Handoff Config Integrity

Offline audit only. This script does not launch MT5.

- Manifest: `outputs\next_test_handoff\HANDOFF_MANIFEST.csv`
- Configs checked: 24
- Passed: 24
- Failed: 0
- Handoff zip SHA256: `8FE19B8A55A058579F9696C2C8E7B2B47F38F1521EBCA8EB1823A022FD149AE3`

## Required Safety Settings

- `Visual=0`
- `ShutdownTerminal=1`
- `Optimization=0`
- `Expert=Professional_XAUUSD_EA.ex5`
- `Symbol=XAUUSD`
- dashboard/log verbosity disabled for tester handoff

## Results

| Rank | Profile | Phase | Set | Window | Passed | SHA256 | Failed Checks |
|---:|---|---|---|---|---|---|---|
| 1 | `baseline_promoted` | phase1_fast_triage | stress | 2024_Q1 | True | `B100DEDBDED9` |  |
| 2 | `baseline_promoted` | phase1_fast_triage | stress | 2024_Q3 | True | `589FFA262BE3` |  |
| 3 | `baseline_promoted` | phase1_fast_triage | stress | 2025_Q2 | True | `FDB5476EF234` |  |
| 4 | `baseline_promoted` | phase1_fast_triage | stress | 2025_Q3 | True | `2971931F525B` |  |
| 5 | `tp38_sl18` | phase1_fast_triage | stress | 2024_Q1 | True | `9257B8B0DCC2` |  |
| 6 | `tp38_sl18` | phase1_fast_triage | stress | 2024_Q3 | True | `57652100200A` |  |
| 7 | `tp38_sl18` | phase1_fast_triage | stress | 2025_Q2 | True | `BE17C5A3FB76` |  |
| 8 | `tp38_sl18` | phase1_fast_triage | stress | 2025_Q3 | True | `7A005C32610A` |  |
| 9 | `tp42_sl18` | phase1_fast_triage | stress | 2024_Q1 | True | `88147D1C7225` |  |
| 10 | `tp42_sl18` | phase1_fast_triage | stress | 2024_Q3 | True | `C97EA3871219` |  |
| 11 | `tp42_sl18` | phase1_fast_triage | stress | 2025_Q2 | True | `C4C99DBE3544` |  |
| 12 | `tp42_sl18` | phase1_fast_triage | stress | 2025_Q3 | True | `B48A3CF113C6` |  |
| 13 | `tp38_sl16` | phase1_fast_triage | stress | 2024_Q1 | True | `AA0482A776F5` |  |
| 14 | `tp38_sl16` | phase1_fast_triage | stress | 2024_Q3 | True | `80CA0BC81AC3` |  |
| 15 | `tp38_sl16` | phase1_fast_triage | stress | 2025_Q2 | True | `AC6B4EB11A43` |  |
| 16 | `tp38_sl16` | phase1_fast_triage | stress | 2025_Q3 | True | `A9453A6866E0` |  |
| 17 | `tp42_sl16` | phase1_fast_triage | stress | 2024_Q1 | True | `F1C6EF23AB44` |  |
| 18 | `tp42_sl16` | phase1_fast_triage | stress | 2024_Q3 | True | `1E8D6E3907BE` |  |
| 19 | `tp42_sl16` | phase1_fast_triage | stress | 2025_Q2 | True | `55EEB1A523F8` |  |
| 20 | `tp42_sl16` | phase1_fast_triage | stress | 2025_Q3 | True | `E994E89D818F` |  |
| 21 | `baseline_promoted` | phase1_fast_triage | full | full | True | `2B8FA006265D` |  |
| 22 | `tp45_sl18` | phase1_fast_triage | stress | 2024_Q1 | True | `9BA0774C3E1F` |  |
| 23 | `tp45_sl18` | phase1_fast_triage | stress | 2024_Q3 | True | `768890A8678E` |  |
| 24 | `tp45_sl18` | phase1_fast_triage | stress | 2025_Q2 | True | `AF60D2871BFA` |  |
