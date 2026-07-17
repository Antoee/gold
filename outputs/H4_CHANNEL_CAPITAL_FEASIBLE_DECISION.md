# H4 Channel Capital-Feasible Decision

Date: 2026-07-17

Decision: **reject every profile; no new best, no Model4 escalation, and no live approval.**

## Purpose

The original H4 channel-trend experiment was largely unable to trade newer gold prices at a `$10,000` balance and `0.10%` risk because its two-ATR stop made the broker's `0.01`-lot minimum exceed the risk budget. This bounded follow-up kept the four previously frozen channel/trailing shapes and changed only requested risk to the project's existing `0.50%` hard per-trade cap. It never forced a minimum lot.

This was a holdout-informed capital-feasibility experiment, not pristine out-of-sample evidence. Its gate was frozen before the run: discovery and validation both positive, continuous PF at least `1.30`, at least `100` continuous trades, maximum drawdown no higher than `5%`, and at least two neighboring passes.

## Result

All `12 / 12` full Model1 reports returned and parsed. Raising the budget restored trade activity, but all four profiles lost the entire 2021-2026 validation era.

| Profile | 2015-2020 net | CAGR | PF | Trades | DD | 2021-2026 net | CAGR | PF | Trades | DD | 2015-2026 net | Annualized | CAGR | PF | Trades | DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `h4cf_40_20_l20_a25` | `+$1,888.65` | `+2.93%/yr` | `1.45` | `231` | `4.54%` | `-$477.88` | `-0.88%/yr` | `0.47` | `46` | `5.65%` | `+$1,341.97` | `+1.16%/yr` | `+1.10%/yr` | `1.27` | `266` | `5.61%` |
| `h4cf_55_20_l20_a25` | `+$2,139.70` | `+3.29%/yr` | `1.64` | `190` | `4.15%` | `-$473.37` | `-0.87%/yr` | `0.41` | `41` | `5.76%` | `+$1,580.63` | `+1.37%/yr` | `+1.28%/yr` | `1.37` | `229` | `5.59%` |
| `h4cf_55_20_l20_a30` | `+$2,423.58` | `+3.68%/yr` | `1.69` | `168` | `3.81%` | `-$501.70` | `-0.93%/yr` | `0.25` | `31` | `5.95%` | `+$1,842.75` | `+1.60%/yr` | `+1.48%/yr` | `1.43` | `196` | `5.82%` |
| `h4cf_80_40_l20_a30` | `+$2,459.78` | `+3.73%/yr` | `1.93` | `135` | `3.59%` | `-$490.21` | `-0.91%/yr` | `0.20` | `29` | `5.70%` | `+$1,850.19` | `+1.61%/yr` | `+1.48%/yr` | `1.56` | `160` | `5.85%` |

The positive continuous headlines are entirely supported by the strong pre-2021 discovery period. They do not describe a strategy that generalized into the newer regime. Every profile also exceeded the `5%` continuous drawdown gate, and the broadest shape's loss streak reached ten.

## Decision

1. Reject the capital-feasible H4 channel family.
2. Do not select a profile from its positive full-history headline.
3. Do not spend Model4 time on a family with PF `0.20-0.47` in the validation era.
4. Do not reduce risk after seeing these results and relabel the same negative expectancy as stable.
5. Preserve the result as evidence that the original failure was both a sizing problem and a post-2020 strategy-regime failure.

## Identity And Safety

- Source: `work/Independent_XAUUSD_H4_Channel_Trend.mq5`
- Source SHA-256: `C27025A3605EEBBA54C5B88D564CE641D00634E2C42C8BAC6D127751ABF58F4A`
- Git-normalized checkout SHA-256: `E8EB53728A83042598460A691784E800512DFC43DC2B503B49427870B032A4FA` (line-ending-only identity)
- Frozen base-profile SHA-256: `940CB5B7C2E6C9786473460ED4C65274430C4CDC3665DDDBAF5EADDA870760DE`
- Compile: `0 errors, 0 warnings`
- Results SHA-256: `11D63BD8E18E6A5081A7BEE5CA8904F9334B04559DE856587E2393C8285EE60C`
- Reports: `12 / 12` parsed from exported files
- Installed frozen source restored: `45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90`
- Installed frozen EX5 restored: `47C13DDD1A97E4CFE9E27DD7E46D3A21587F25D940D48B391B88FC640C9CE8BA`
- MT5-family processes after restore: `0`
- Local launch hard lock: present
- Real-account trading: disabled

Evidence:

- `outputs/H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_RESULTS.csv`
- `outputs/H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_QUEUE.csv`
- `outputs/H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_PACKAGE_MANIFEST.csv`
- `outputs/H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_COMPILE.log`
- `outputs/H4_CHANNEL_CAPITAL_FEASIBLE_BASE_PROFILE.set`
- `outputs/H4_CHANNEL_CAPITAL_FEASIBLE_DECISION.csv`
