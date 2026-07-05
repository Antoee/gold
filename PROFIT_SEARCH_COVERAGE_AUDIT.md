# Profit Search Coverage Audit

Generated without launching MT5. This audits the candidate search space and risk coverage only.

- Profiles: 16
- Phase-2 seeds: 5
- Phase-1 only: 11
- Aggressive-risk profiles: 1
- Reduced-risk profiles present: True
- Baseline present: True
- Giveback variants present: True
- Breakeven variants present: True
- Trailing variants present: True

## Coverage By Family

| Family | Profiles |
|---|---:|
| baseline | 1 |
| take_profit | 3 |
| take_profit+break_even | 1 |
| take_profit+giveback | 2 |
| take_profit+risk | 2 |
| take_profit+risk_reward | 1 |
| take_profit+stop_loss | 3 |
| take_profit+stop_loss+risk | 1 |
| take_profit+trailing | 2 |

## Coverage By Risk Band

| Risk Band | Profiles |
|---|---:|
| aggressive | 1 |
| baseline | 13 |
| moderate | 1 |
| reduced | 1 |

## Candidate Details

| Priority | Profile | Phase2 | Family | Risk | SL | TP | RR | Trail | BE | Giveback | Note |
|---:|---|---:|---|---:|---:|---:|---:|---:|---|---|---|
| 1 | `baseline_promoted` | True | baseline | 1.60 | 1.80 | 3.50 | 1.50 |  | false | false | ok |
| 2 | `tp38_sl18` | True | take_profit | 1.60 | 1.80 | 3.80 | 1.50 |  | false | false | ok |
| 3 | `tp42_sl18` | True | take_profit | 1.60 | 1.80 | 4.20 | 1.50 |  | false | false | ok |
| 4 | `tp38_sl16` | True | take_profit+stop_loss | 1.60 | 1.60 | 3.80 | 1.50 |  | false | false | ok |
| 5 | `tp42_sl16` | True | take_profit+stop_loss | 1.60 | 1.60 | 4.20 | 1.50 |  | false | false | ok |
| 6 | `tp45_sl18` | False | take_profit | 1.60 | 1.80 | 4.50 | 1.50 |  | false | false | ok |
| 7 | `tp38_sl20` | False | take_profit+stop_loss | 1.60 | 2.00 | 3.80 | 1.50 |  | false | false | ok |
| 8 | `trail14_tp38` | False | take_profit+trailing | 1.60 | 1.80 | 3.80 | 1.50 | 1.40 | false | false | ok |
| 9 | `trail18_tp38` | False | take_profit+trailing | 1.60 | 1.80 | 3.80 | 1.50 | 1.80 | false | false | ok |
| 10 | `rr18_tp42` | False | take_profit+risk_reward | 1.60 | 1.80 | 4.20 | 1.80 |  | false | false | ok |
| 11 | `risk18_tp38_sl18` | False | take_profit+risk | 1.80 | 1.80 | 3.80 | 1.50 |  | false | false | ok |
| 12 | `risk20_tp38_sl18` | False | take_profit+risk | 2.00 | 1.80 | 3.80 | 1.50 |  | false | false | aggressive risk, phase1 prune only |
| 13 | `risk14_tp42_sl16` | False | take_profit+stop_loss+risk | 1.40 | 1.60 | 4.20 | 1.50 |  | false | false | ok |
| 14 | `giveback25_tp38` | False | take_profit+giveback | 1.60 | 1.80 | 3.80 | 1.50 |  | false | true | guard behavior must preserve full-period profit |
| 15 | `giveback35_tp38` | False | take_profit+giveback | 1.60 | 1.80 | 3.80 | 1.50 |  | false | true | guard behavior must preserve full-period profit |
| 16 | `be12_tp38` | False | take_profit+break_even | 1.60 | 1.80 | 3.80 | 1.50 |  | true | false | breakeven can reduce winners; validate expectancy |

## Interpretation

The current pack is intentionally centered around the validated no-date BOS/sweep baseline. It explores upside through TP/SL, trailing, RR, risk, giveback, and breakeven changes. Higher risk profiles remain phase-1 pruning candidates and should not become defaults unless they later pass complete real-tick phase-2 evidence plus promotion packets.
