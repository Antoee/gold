# Range-Elite Risk-Shape Probe Decision

Date: 2026-07-14

Verdict: **REJECTED, NO NEW BEST**

This run fixed a local testing blocker and produced useful rejection evidence, but it did not create a trade-ready or more stable best profile.

## Infrastructure Result

- Current EA source hash: `AF34F307DECFA45F53312DD53606E70141508973CEF60D30480779694396D7AC`
- Exposed MT5 tester inputs after source diet: `308`
- Baseline rebuilt profile hash after stale input pruning: `4038793A4B0677EA5D3CED74A57B4366C3EDFFFB54CE61A50022EF6F2026A65B`
- Example generated config tester inputs: `297`
- Compile proof: `outputs/MT5_HIDDEN_COMPILE_INPUT_DIET.log`
- Compile result: `0 errors, 0 warnings`

Root cause fixed: MT5 rejected the previous compiled EA with `too many input parameters (1826)`. Old research controls were moved out of the MT5 input surface, and the package builder now prunes stale base-profile keys while failing on non-exposed candidate overrides.

## Test Evidence

- Package: `outputs/RANGE_ELITE_RISK_SHAPE_PROBE_PACKAGE.md`
- Run CSV: `outputs/RANGE_ELITE_RISK_SHAPE_PROBE_RUN.csv`
- Parsed results: `outputs/RANGE_ELITE_RISK_SHAPE_PROBE_RESULTS.csv`
- Metrics summary: `outputs/RANGE_ELITE_RISK_SHAPE_PROBE_REPORT_METRICS.md`
- Model: `1` fast screen
- Windows: `2019`, `2021`, `2023`, `2024`, `2026 YTD`
- Reports returned: `80 / 80`
- Exported reports parsed: `80 / 80`
- Log-only rows: `0`

## Key Findings

The diagnostic-fallback/liquidity-sweep block did not change the baseline result:

| Candidate | Total Net | Worst Window | Worst DD % | Trades | Decision |
| --- | ---: | ---: | ---: | ---: | --- |
| `re_base` | `+$2,994.93` | `-$129.87` | `24.36` | `54` | Baseline only |
| `re_blockliq` | `+$2,994.93` | `-$129.87` | `24.36` | `54` | No effect |
| `re_may140` | `+$3,015.75` | `-$138.37` | `20.75` | `39` | Rejected: still red in 2019/2021/2023 |
| `re_blockliq_may140` | `+$3,015.75` | `-$138.37` | `20.75` | `39` | Same as `re_may140`, rejected |
| `re_dgfq_default` | `+$58.14` | `-$183.18` | `30.95` | `31` | Rejected: killed profit and raised DD |

Best fast-screen shape was `re_may140` / `re_blockliq_may140`, but it still failed the broad-window gate:

| Window | Net | Annualized Return % | PF | Trades | DD % |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2019 | `-$86.19` | `-8.65` | `0.00` | `3` | `11.90` |
| 2021 | `-$60.96` | `-6.12` | `0.41` | `2` | `20.75` |
| 2023 | `-$138.37` | `-13.88` | `0.44` | `15` | `17.20` |
| 2024 | `+$2,343.15` | `234.48` | `5.65` | `7` | `14.50` |
| 2026 YTD | `+$958.12` | `182.27` | `3.79` | `12` | `19.71` |

## Decision

No candidate is promoted. The fast screen confirms that risk shaping can reduce drawdown versus baseline, but it does not solve the older-year failure pattern. A Model4 real-tick run is not justified for these variants because the fast Model1 gate still has three red broad windows.

Next useful strategy work should target entry/regime logic for 2019, 2021, and 2023 instead of adding more risk caps or calendar-only exclusions.
