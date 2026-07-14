# Range-Elite Risk-Shape Probe Package

Offline package builder only. This does not launch MT5.

- Source hash: `129A489FECFE46470E5417FAD8C98B83E14A691D1370CA493F52A5E59B1E022B`
- Base profile hash: `AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`
- Model: `4`
- Candidates: `5`
- Windows per candidate: `6`
- Configs: `30`

## Candidate Theses

| Candidate | Thesis | Overrides |
| --- | --- | --- |
| re_base | Current range-elite baseline on the focused windows. | base |
| re_may140 | Keep a smaller May opportunity boost without letting May dominate account risk. | InpMayRiskMultiplier=1.40 |
| re_dgf_late16_pure | Block pure diagnostic-fallback entries at or after hour 16 while keeping stronger confirmed setups. | InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=16; InpUseDiagnosticFallbackLateSessionGuard=true |
| re_dgf_late15_pure | Stricter pure diagnostic-fallback late-session guard starting at hour 15. | InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpUseDiagnosticFallbackLateSessionGuard=true |
| re_may140_late16_pure | Combine smaller May risk with the hour-16 pure diagnostic-fallback guard. | InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=16; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackLateSessionGuard=true |

## Windows

`2019_full, 2021_full, 2023_full, 2024_full, 2025_full, 2026_ytd`
