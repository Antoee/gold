# Range-Elite Risk-Shape Probe Package

Offline package builder only. This does not launch MT5.

- Source hash: `C23144DDE1F26C29135489FC9DF065FC5B5575C0B3F1B388BECC01E70E5965B4`
- Base profile hash: `AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`
- Model: `4`
- Candidates: `4`
- Windows per candidate: `6`
- Configs: `24`

## Candidate Theses

| Candidate | Thesis | Overrides |
| --- | --- | --- |
| re_may140_late15_dgf_liq_reject1 | Combine May risk cap, late pure-DGF guard, and true rejection of weak DGF plus liquidity-sweep entries. | InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackLateSessionGuard=true |
| re_may140_late15_dgf_liq_reject1_cush50 | Throttle DGF to 50% risk until the account has a 5% closed-profit cushion. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.50; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true |
| re_may140_late15_dgf_liq_reject1_cush35 | Throttle DGF to 35% risk until the account has a 5% closed-profit cushion. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.35; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true |
| re_may140_late15_dgf_liq_reject1_cush25 | Throttle DGF to 25% risk until the account has a 5% closed-profit cushion. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.25; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true |

## Windows

`2019_full, 2021_full, 2023_full, 2024_full, 2025_full, 2026_ytd`
