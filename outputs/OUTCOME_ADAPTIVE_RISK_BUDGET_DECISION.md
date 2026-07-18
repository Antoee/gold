# Outcome-Adaptive Risk-Budget Decision

**Decision: REJECT BEFORE MQL IMPLEMENTATION.**

This analytical screen used only previously closed same-lane outcomes at each entry. It changed no signal, exit, stop, date, month, or account risk cap. It is not an MT5 implementation or live approval.

## Full Results

| Variant | Full net | Discovery net | Later net | PF | Risk-floor DD | 0.05R net |
|---|---:|---:|---:|---:|---:|---:|
| `fixed_control` | $1,615.36 | $723.36 | $831.83 | 1.584 | 2.921% | $1,314.39 |
| `oarb_center_n12_h15_c50_dd25` | $1,346.40 | $577.75 | $734.47 | 1.574 | 2.344% | $1,009.47 |
| `oarb_n08_h15_c50_dd25` | $1,205.76 | $495.10 | $735.50 | 1.516 | 2.674% | $880.63 |
| `oarb_n16_h15_c50_dd25` | $1,344.18 | $570.13 | $751.87 | 1.572 | 2.322% | $958.66 |
| `oarb_n12_h10_c50_dd25` | $1,364.16 | $594.31 | $734.47 | 1.579 | 2.374% | $992.73 |
| `oarb_n12_h20_c50_dd25` | $1,366.37 | $596.37 | $734.47 | 1.586 | 2.344% | $1,019.13 |
| `oarb_n12_h15_c75_dd25` | $1,482.10 | $622.28 | $777.78 | 1.558 | 2.740% | $1,156.83 |
| `oarb_n12_h15_c50_dd20` | $1,261.63 | $476.12 | $757.64 | 1.562 | 2.366% | $976.81 |
| `oarb_n12_h15_c50_dd30` | $1,328.62 | $564.44 | $731.15 | 1.563 | 2.344% | $1,065.96 |

## Frozen Gates

| Gate | Pass | Evidence |
|---|---:|---|
| control-reproduction | True | net=1615.36;trades=362 |
| discovery-improvement | False | improvement=-20.129% |
| later-improvement | False | improvement=-11.704% |
| continuous-improvement | False | improvement=-16.650% |
| cost-improvement | False | improvement=-23.199% |
| broad-restarts-positive | True | older_2015_2018=681.32;middle_2019_2022=322.33;recent_2023_2026=459.20 |
| profit-factor | True | center=1.5741;control=1.5843 |
| risk-floor-drawdown | True | center=2.3444%;control=2.9209% |
| red-years | False | center=4;control=2 |
| state-activity | True | hot=21.55%;cold=48.34% |
| neighbor-support | False | passes=0/7 |

Fixed-control reproduction: `$1,615.36` across `362` trades. Center full improvement: `-16.650%`; discovery: `-20.129%`; later chronological: `-11.704%`; 0.05R stress: `-23.199%`.

The operational RC2 candidate, forward profile, registration drafts, and real-account lock remain unchanged.
