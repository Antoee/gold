# Range-Elite Risk-Shape Probe Package

Offline package builder only. This does not launch MT5.

- Source hash: `AF34F307DECFA45F53312DD53606E70141508973CEF60D30480779694396D7AC`
- Base profile hash: `AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`
- Model: `1`
- Candidates: `16`
- Windows per candidate: `5`
- Configs: `80`

## Candidate Theses

| Candidate | Thesis | Overrides |
| --- | --- | --- |
| re_base | Current range-elite baseline on the focused windows. | base |
| re_may100 | Remove the May 2.80 risk boost while keeping May trades enabled. | InpMayRiskMultiplier=1.00 |
| re_may140 | Keep a smaller May opportunity boost without letting May dominate account risk. | InpMayRiskMultiplier=1.40 |
| re_may200 | Intermediate May cap between current 2.80 and neutral 1.00. | InpMayRiskMultiplier=2.00 |
| re_maxrisk100 | Cap effective risk at 1.00%, clipping May/profit boosts without touching entries. | InpMaxEffectiveRiskPercent=1.00 |
| re_lotcap030 | Cap position size at 0.30 lots to block oversized late equity-growth losers. | InpMaxPositionLots=0.30 |
| re_ny_end16 | End New York entries before hour 16, the worst trade-log hour. | InpNewYorkEndHour=16 |
| re_ny16_may140_lot030 | Combined tail-risk cap: earlier NY end, smaller May boost, and 0.30 lot cap. | InpMaxPositionLots=0.30; InpMayRiskMultiplier=1.40; InpNewYorkEndHour=16 |
| re_dgfq_default | Enable the built-in diagnostic-fallback quality gate with default PA/SMQ/execution requirements. | InpUseDiagnosticFallbackQualityGate=true |
| re_dgfq_pa6_smq4 | Require stronger price-action and smart-money scores before diagnostic fallback can contribute. | InpDiagnosticFallbackMinPriceActionScore=6; InpDiagnosticFallbackMinSmartMoneyScore=4; InpUseDiagnosticFallbackQualityGate=true |
| re_dgfq_struct | Require nearby structure evidence for diagnostic fallback instead of candle direction alone. | InpDiagnosticFallbackRequireStructure=true; InpUseDiagnosticFallbackQualityGate=true |
| re_dgfq_struct_liq | Require both structure and liquidity evidence for diagnostic fallback. | InpDiagnosticFallbackRequireLiquidity=true; InpDiagnosticFallbackRequireStructure=true; InpUseDiagnosticFallbackQualityGate=true |
| re_may140_dgfq | Combine smaller May risk with the default diagnostic-fallback quality gate. | InpMayRiskMultiplier=1.40; InpUseDiagnosticFallbackQualityGate=true |
| re_blockliq | Block diagnostic fallback when the setup is also a liquidity-sweep setup. | InpDiagnosticFallbackBlockLiquiditySweep=true |
| re_blockliq_may140 | Block diagnostic/liquidity conflict and keep a smaller May risk boost. | InpDiagnosticFallbackBlockLiquiditySweep=true; InpMayRiskMultiplier=1.40 |
| re_blockliq_may100 | Block diagnostic/liquidity conflict and remove the May risk boost. | InpDiagnosticFallbackBlockLiquiditySweep=true; InpMayRiskMultiplier=1.00 |

## Windows

`2019_full, 2021_full, 2023_full, 2024_full, 2026_ytd`
