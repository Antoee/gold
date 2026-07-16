# Daily Donchian Breakout Decision

## Feature-Gate Follow-Up

The 2026-07-16 entry-feature study was also rejected. A 51-trade diagnostic reproduction logged date-independent trend, price-action, volatility, and volume features, but no meaningful primary gate passed the frozen 2015-2020 discovery rules. A separately declared false-breakout extension also returned zero eligible gates. The 2021-2026 feature holdout was intentionally left unopened. See `research/2026-07-16-daily-donchian-feature-gate-rejection.md`.

Date: 2026-07-16

## Verdict

**Rejected as a maintained or combined candidate. No new best.**

The standalone daily breakout with a five-day opposite-channel exit was profitable in every broad era and reproduced almost exactly on real ticks. However, the edge was weak in 2019-2022, the full-period return was too low for its drawdown, and adding the lane to the current money-ready candidate reduced profit and created a losing older window.

The exact maintained source/profile pair remains unchanged:

- Source SHA-256: `A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622`
- Profile: `outputs/CANDIDATE_MONEY_READY_PROFILE.set`
- Profile SHA-256: `D0459197F2A8CA1385F139694BD036AA9A3A596BB406F7D4474CDC8444605C79`

## Standalone Real-Tick Evidence

Experimental source SHA-256: `D387779DC3BABD6A8294C46E5827D1029AA536EA29F91C06C357D66D2B098153`

Profile: `ddb_ch_lb20e150_x5`, using a 20-day Donchian entry, EMA-150 trend filter, and five-day opposite-channel exit.

| Window | Net | Total return | Annualized | PF | Trades | Max equity DD | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2015-2026 continuous | `+$438.43` | `+4.38%` | `+0.38%/yr` | `1.41` | `51` | `3.77%` | `1.12` |
| 2015-2018 | `+$210.65` | `+2.11%` | `+0.53%/yr` | `1.53` | `17` | `3.77%` | `0.54` |
| 2019-2022 | `+$27.75` | `+0.28%` | `+0.07%/yr` | `1.07` | `18` | `3.12%` | `0.09` |
| 2023-2026 YTD | `+$291.47` | `+2.91%` | `+0.83%/yr` | `4.17` | `7` | `1.64%` | `1.73` |

This is a valid cross-era research result, but the 2019-2022 segment is effectively flat and the continuous return/drawdown ratio is not competitive with the maintained risk-first candidate.

## Combined A/B Evidence

The source was extended so the daily lane could use a channel exit while the main strategy retained its fixed take-profit behavior. It compiled with `0 errors, 0 warnings` and passed `39 / 39` static checks. The exact control and combined profile were then compared on Model 1.

| Profile | Continuous net | PF | Trades | Max DD | Older net | Middle net | Recent net |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Exact money-ready control | `+$397.53` | `2.77` | `37` | `0.66%` | `$0.00` | `+$294.29` | `+$104.56` |
| Control plus daily breakout | `+$255.38` | `1.84` | `61` | `0.67%` | `-$22.74` | `+$181.29` | `+$88.27` |

The added lane increased activity but reduced continuous net by `$142.15`, reduced PF, weakened both active recent eras, and violated the no-losing-broad-window rule.

## Decision

1. Do not promote the standalone daily breakout as the best bot.
2. Do not combine it with the current candidate.
3. Preserve the reports and packages as research evidence.
4. Restore the exact maintained source and keep real-account trading hard-locked.
5. Future work should seek genuinely complementary logic whose combined account path improves return and robustness without creating a red era.

Evidence:

- `outputs/DAILY_DONCHIAN_CHANNEL_EXIT_RESULTS.csv`
- `outputs/DAILY_DONCHIAN_CHANNEL_EXIT_REALTICK_RESULTS.csv`
- `outputs/DAILY_DONCHIAN_COMBINED_RESULTS.csv`
- `outputs/DAILY_DONCHIAN_COMBINED_COMPILE.log`

