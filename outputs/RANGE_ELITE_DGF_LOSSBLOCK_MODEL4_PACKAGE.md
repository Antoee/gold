# Range-Elite Risk-Shape Probe Package

Offline package builder only. This does not launch MT5.

- Source hash: `F254FDF07B932FD8009E1ABFD761D1C9195568596A559F0DCB73A8CD29157D8F`
- Base profile hash: `AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`
- Model: `4`
- Candidates: `3`
- Windows per candidate: `6`
- Configs: `18`

## Candidate Theses

| Candidate | Thesis | Overrides |
| --- | --- | --- |
| re_may140_late15_dgf_liq_reject1_cush50 | Throttle DGF to 50% risk until the account has a 5% closed-profit cushion. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.50; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true |
| re_may140_late15_dgf_liq_reject1_cush50_dgflossblock | Throttle DGF before cushion and block new DGF entries when recent no-cushion DGF average R is not positive. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackLossBlockCushionPercent=5.00; InpDiagnosticFallbackLossBlockLookbackTrades=3; InpDiagnosticFallbackLossBlockMaxAverageR=0.00; InpDiagnosticFallbackLossBlockMinTrades=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.50; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true; InpUseDiagnosticFallbackNoCushionLossBlock=true |
| re_may140_late15_dgf_liq_reject1_cush35_dgflossblock | More defensive initial DGF risk plus the no-cushion DGF loss block. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackLossBlockCushionPercent=5.00; InpDiagnosticFallbackLossBlockLookbackTrades=3; InpDiagnosticFallbackLossBlockMaxAverageR=0.00; InpDiagnosticFallbackLossBlockMinTrades=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.35; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true; InpUseDiagnosticFallbackNoCushionLossBlock=true |

## Windows

`2019_full, 2021_full, 2023_full, 2024_full, 2025_full, 2026_ytd`
