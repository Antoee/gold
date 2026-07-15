# Range-Elite Risk-Shape Probe Package

Offline package builder only. This does not launch MT5.

- Source hash: `6B68DA99F7882F94B41802EE862EEA957244A39B16B8D6FAE594E74F9C351240`
- Base profile hash: `AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`
- Model: `1`
- Candidates: `5`
- Windows per candidate: `6`
- Configs: `30`

## Candidate Theses

| Candidate | Thesis | Overrides |
| --- | --- | --- |
| re_may140_late15_dgf_liq_reject1_cush50 | Throttle DGF to 50% risk until the account has a 5% closed-profit cushion. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.50; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true |
| re_may140_late15_dgf_liq_reject1_cush50_dgfperf35 | Throttle DGF to 50% risk until cushion, then cut DGF risk after any weak DGF performance sample. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.50; InpDiagnosticFallbackPerformanceLookbackTrades=3; InpDiagnosticFallbackPerformanceMinTrades=1; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpDiagnosticFallbackStrongAverageR=0.35; InpDiagnosticFallbackWeakAverageR=0.00; InpMayRiskMultiplier=1.40; InpMinDiagnosticFallbackPerformanceRiskMultiplier=0.35; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true; InpUseDiagnosticFallbackPerformanceRiskScaling=true |
| re_may140_late15_dgf_liq_reject1_cush50_starterec35 | Throttle DGF before cushion and reduce all risk while equity is below starting balance. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.50; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpMinStartingEquityRecoveryRiskMultiplier=0.35; InpStartingEquityRecoveryRiskFullDrawdownPercent=1.50; InpStartingEquityRecoveryRiskStartDrawdownPercent=0.10; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true; InpUseStartingEquityRecoveryRiskScaling=true |
| re_may140_late15_dgf_liq_reject1_cush50_recovery_perf | Combine DGF cushion throttle, DGF performance risk scaling, and starting-equity recovery risk scaling. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackNoCushionRiskMultiplier=0.50; InpDiagnosticFallbackPerformanceLookbackTrades=3; InpDiagnosticFallbackPerformanceMinTrades=1; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpDiagnosticFallbackStrongAverageR=0.35; InpDiagnosticFallbackWeakAverageR=0.00; InpMayRiskMultiplier=1.40; InpMinDiagnosticFallbackPerformanceRiskMultiplier=0.35; InpMinStartingEquityRecoveryRiskMultiplier=0.35; InpStartingEquityRecoveryRiskFullDrawdownPercent=1.50; InpStartingEquityRecoveryRiskStartDrawdownPercent=0.10; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true; InpUseDiagnosticFallbackPerformanceRiskScaling=true; InpUseStartingEquityRecoveryRiskScaling=true |
| re_may140_late15_dgf_liq_reject1_cush50_dgfq_pa6 | Keep cushion throttle but require stronger price-action and smart-money evidence for DGF entries. | InpDiagnosticFallbackCushionProfitPercent=5.00; InpDiagnosticFallbackLateSessionPureOnly=true; InpDiagnosticFallbackLateSessionStartHour=15; InpDiagnosticFallbackLiquidityRejectMaxConfirmations=1; InpDiagnosticFallbackMinPriceActionScore=6; InpDiagnosticFallbackMinSmartMoneyScore=4; InpDiagnosticFallbackNoCushionRiskMultiplier=0.50; InpDiagnosticFallbackRejectLiquiditySweepSignal=true; InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackCushionRiskThrottle=true; InpUseDiagnosticFallbackLateSessionGuard=true; InpUseDiagnosticFallbackQualityGate=true |

## Windows

`2019_full, 2021_full, 2023_full, 2024_full, 2025_full, 2026_ytd`
