# Strategy Research Brief

Generated from existing offline reports only. No MT5 process was launched.

## Executive Read

- Keep `risk1p6_sl18_tp35` as the promoted BOS+sweep default until a candidate beats it with complete phase-2 real-tick evidence.
- The most sensible profit-improvement search remains TP expansion around `3.8` with SL `1.6` to `1.8`; it has zero-loss stress evidence but is not fully validated.
- Momentum+sweep and date-block results are useful research clues, not default replacements.
- No new profile should be promoted while profit-search reports remain missing.

## Evidence Themes

| Theme | Status | Profit | Worst | Losing | Windows | Risk Tier | Decision | Next Action |
|---|---|---:|---:|---:|---:|---|---|---|
| `Current BOS+sweep default` | Keep promoted | 2354.65 | 0 | 0 | 9 | Validated no-loss | This remains the active default because it has the strongest broad no-loss evidence. | Use as baseline in every future candidate batch. |
| `TP 3.8 neighborhood: risk160_sl16_tp38` | Promising, unpromoted | 798 | 0 | 0 | 7 | Validated no-loss | Looks better than the monthly/quarter baseline in limited windows, but lacks full phase-2 real-tick evidence. | Prioritize fast stress prune, then phase-2 real ticks only if phase 1 does not reveal losses. |
| `TP 3.8 neighborhood: risk160_sl18_tp38` | Promising, unpromoted | 798 | 0 | 0 | 7 | Validated no-loss | Looks better than the monthly/quarter baseline in limited windows, but lacks full phase-2 real-tick evidence. | Prioritize fast stress prune, then phase-2 real ticks only if phase 1 does not reveal losses. |
| `Momentum+sweep entry family` | Research only | 2113.53 | -15.49 | 1 | 9 | Low-loss research | Profit is competitive, but it violates the current zero-losing-window preference. | Use as a clue for confirmation logic, not as a default profile. |
| `Date-block buy benchmark, yearly` | Benchmark only | 2084.68 | 448.56 | 0 | 3 | Thin coverage | High profit, but calendar-specific blocking has overfitting risk. | Translate only if a general regime rule explains it. |
| `Date-block buy benchmark, walk-forward` | Benchmark only | 2053.09 | 0 | 0 | 5 | Thin coverage | Walk-forward result is strong, but the rule source is still date-specific. | Research volatility/trend/session explanations before considering any implementation. |
| `Monthly/quarter no-loss confirmation` | Supports promoted default | 744.03 | 0 | 0 | 10 | Validated no-loss | The default is not just a full-period fit; it also survives smaller windows. | Preserve these gates when searching for extra profit. |
| `Profit-search evidence gap` | Missing tester evidence | 0 | 0 | 0 | 0 | Thin coverage | 0 of 183 profit-search reports are parsed; no new profile can be promoted from this pack yet. | Run only the audited handoff batch during a controlled safe testing window. |

## Research Discipline

1. Do not promote from phase 1 or single-window evidence.
2. Any replacement must beat the current full-period profit target while preserving zero losing split/month/quarter windows.
3. Date-specific blocks should become general market-regime filters before they are eligible for promotion.
4. Profit expansion should be searched near already profitable behavior first: TP, stop width, trailing, breakeven, and giveback guard variants around the promoted BOS+sweep core.
