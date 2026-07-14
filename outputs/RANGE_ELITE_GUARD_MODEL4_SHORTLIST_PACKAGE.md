# Range-Elite Risk-Shape Probe Package

Offline package builder only. This does not launch MT5.

- Source hash: `AF34F307DECFA45F53312DD53606E70141508973CEF60D30480779694396D7AC`
- Base profile hash: `AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`
- Model: `4`
- Candidates: `4`
- Windows per candidate: `6`
- Configs: `24`

## Candidate Theses

| Candidate | Thesis | Overrides |
| --- | --- | --- |
| re_base | Current range-elite baseline on the focused windows. | base |
| re_may140 | Keep a smaller May opportunity boost without letting May dominate account risk. | InpMayRiskMultiplier=1.40 |
| re_blockliq | Block diagnostic fallback when the setup is also a liquidity-sweep setup. | InpDiagnosticFallbackBlockLiquiditySweep=true |
| re_blockliq_may140 | Block diagnostic/liquidity conflict and keep a smaller May risk boost. | InpDiagnosticFallbackBlockLiquiditySweep=true; InpMayRiskMultiplier=1.40 |

## Windows

`2019_full, 2021_full, 2023_full, 2024_full, 2025_full, 2026_ytd`
