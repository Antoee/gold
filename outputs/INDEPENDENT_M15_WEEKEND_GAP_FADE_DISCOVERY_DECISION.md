# Independent M15 Weekend-Gap Fade Decision

Decision date: 2026-07-17

**Verdict: rejected during frozen Model 1 discovery. No 2021-2026 holdout was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Test Contract

- Source: `work/Independent_XAUUSD_M15_Weekend_Gap_Fade.mq5`
- Source SHA-256: `0B0DB2770C3CF7170C248A94B829932166F9ADA42ACB3956B7FC4450993C8121`
- Compiled binary SHA-256: `BCC66BFFFA22A6F096006104CCC03EA0FB66032AF7DF1505F69FBE33C23F4F3E`
- Compile: `0 errors, 0 warnings`
- Discovery data only: 2015-01-01 through 2020-12-31
- Identity-valid reports parsed: `21 / 21`
- Candidate variants: `7`
- Risk per trade: `0.10%`
- 2021-2026 holdout configurations run: `0`
- Model 4 configurations run: `0`

Two initial portable rows hit startup identity races. Only their exact frozen configurations were rerun; both passed source identity on retry, and the canonical run evidence contains one identity-valid result per queue rank.

## Discovery Evidence

The frozen gate required both disjoint eras to be profitable, continuous PF at least 1.20, at least 40 trades, DD no greater than 2.50%, positive expected payoff, return/DD at least 1.00, and an adjacent passing profile. No row passed the base gate.

| Candidate | 2015-2018 | 2019-2020 | Continuous | PF | Payoff | Trades | DD | Return/DD | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `wgf_maxgap065` | `+$0.00` | `-$8.04` | `-$8.04` | `0.00` | `-2.68` | `3` | `0.19%` | `-0.42` | rejected |
| `wgf_confirm030` | `+$0.00` | `-$8.04` | `-$8.04` | `0.00` | `-8.04` | `1` | `0.09%` | `-0.89` | rejected |
| `wgf_maxgap035` | `+$0.00` | `-$8.04` | `-$8.04` | `0.00` | `-2.68` | `3` | `0.19%` | `-0.42` | rejected |
| `wgf_center` | `+$0.00` | `-$8.04` | `-$8.04` | `0.00` | `-2.68` | `3` | `0.19%` | `-0.42` | rejected |
| `wgf_gap005` | `+$0.00` | `-$8.04` | `-$8.04` | `0.00` | `-2.68` | `3` | `0.19%` | `-0.42` | rejected |
| `wgf_gap012` | `+$0.00` | `-$8.04` | `-$8.04` | `0.00` | `-2.68` | `3` | `0.19%` | `-0.42` | rejected |
| `wgf_confirm000` | `+$8.54` | `-$22.00` | `-$13.46` | `0.74` | `-0.90` | `15` | `0.36%` | `-0.37` | rejected |

The center traded only three times across 2015-2020 and lost $8.04. Relaxing confirmation to zero increased activity to 15 trades, but that row lost $13.46 continuously and $22.00 in 2019-2020. The family is both too sparse and unprofitable at the frozen geometry.

## Decision

- Reject this weekend-gap fade neighborhood; do not tune it on recent data.
- Skip holdout and Model 4 because the broad pre-2021 gate failed.
- Do not merge the engine into the frozen forward candidate.
- Preserve the registered source/profile/binary identity, evidence logs, and hard real-account lock unchanged.

## Evidence

- `outputs/INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_CONTRACT.md`
- `outputs/INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_RUN.csv`
- `outputs/INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_DECISION.csv`
