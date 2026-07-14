# Range-Elite Risk-Shape Probe Package

Offline package builder only. This does not launch MT5.

- Source hash: `69478904BB4073F48F8F963ED13D789BFE378456D4C054CAB16A8368F4065D92`
- Base profile hash: `AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`
- Model: `4`
- Candidates: `5`
- Windows per candidate: `6`
- Configs: `30`

## Candidate Theses

| Candidate | Thesis | Overrides |
| --- | --- | --- |
| re_may140 | Keep a smaller May opportunity boost without letting May dominate account risk. | InpMayRiskMultiplier=1.40 |
| re_dgf_liq_reject1 | Reject DGF plus liquidity-sweep entries when liquidity sweep is the only pre-DGF confirmation. | InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackRejectLiquiditySweepSignal=true |
| re_may140_dgf_liq_reject1 | Combine smaller May risk with true rejection of weak DGF plus liquidity-sweep entries. | InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40 |
| re_may140_late15_dgf_liq_reject1 | Combine May risk cap, late pure-DGF guard, and true rejection of weak DGF plus liquidity-sweep entries. | InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackLateSessionGuard=true |
| re_may140_late15_pure | Combine smaller May risk with the stricter hour-15 pure diagnostic-fallback guard. | InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackLateSessionGuard=true |

## Windows

`2019_full, 2021_full, 2023_full, 2024_full, 2025_full, 2026_ytd`
