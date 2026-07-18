# RC2 Momentum-Risk Extension Money-Readiness Contract

Frozen before annual restart, deterministic execution-cost, or Monte Carlo results were opened for the promoted `0.20%` momentum-risk profile.

## Identity

- EA source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Research profile SHA-256: `06AE8127CF2719D7D3A19FEE069ECA3D50B83B3B0329C04F7B08E5F9135AFA5A`
- Exact continuous Model4 trade-ledger SHA-256: `80E2E741EA508DCC2D048661FF266A72F6708812F4F75EBB96DCB1136247CE59`
- Initial balance: `$10,000`
- Symbol/timeframe: `XAUUSD M15`
- Model: `4` real ticks
- Historical cutoff: `2026-07-16`

The registered forward candidate, account contract, binary identity, evidence logs, and real-account lock are not changed by this research lane.

## Evidence Limits

The annual restarts are robustness checks over already inspected history, not untouched out-of-sample evidence. The continuous report's calendar-year segments were known before this contract. The restart tests answer whether resetting capital at each January materially breaks the profile.

## Annual Restart Gate

Run 2015 through 2025 as full calendar years and 2026 through July 16, each from a fresh `$10,000` balance with the exact frozen source and profile.

All conditions must pass:

1. `12 / 12` reports parse and embed the expected source identity.
2. Every year has net profit at least `-$75` (`-0.75%` of starting capital).
3. At least eight of the 11 completed years are profitable.
4. No more than three completed years are negative.
5. The worst adjacent two-completed-year net sum is at least `-$100`.
6. Summed annual-restart net is at least `80%` of the `+$1,812.42` continuous result.
7. Every active year has profit factor at least `0.85` and drawdown at most `4.00%`.
8. The combined 2023-2026 YTD annual-restart net is positive.

These thresholds allow ordinary small losing years but reject a profile whose modest CAGR depends on one start date or hides a material annual loss.

## Deterministic Cost Gate

Historical real-tick spread and report costs are already embedded. Apply additional adverse cost to every exact trade as a fraction of its initial risk:

| Scenario | Added cost per trade |
|---|---:|
| Base | `0.00R` |
| Light | `0.02R` |
| Moderate | `0.05R` |
| Severe | `0.10R` |

The moderate scenario must remain net profitable, retain PF at least `1.20`, keep every broad era positive, and keep closed-trade drawdown at or below `6.00%`. The severe scenario must remain net profitable with PF at least `1.10` and drawdown at or below `8.00%`.

## Monte Carlo Gate

Use `10,000` deterministic seeded bootstrap trials per scenario over the exact 362-trade ledger. Each trial resamples trades with replacement and applies adverse slippage, delay, spread shock, and missed-winner stress in initial-risk units.

Standard scenario:

- 5th-percentile net must be positive.
- Median PF must be at least `1.25`.
- 95th-percentile closed-trade drawdown must not exceed `6.00%`.
- Red trials must not exceed `5.00%`.
- 95th-percentile maximum loss run must not exceed `14`.

Severe scenario:

- 5th-percentile net must be positive.
- Median PF must be at least `1.10`.
- 95th-percentile closed-trade drawdown must not exceed `8.00%`.
- Red trials must not exceed `5.00%`.
- 95th-percentile maximum loss run must not exceed `16`.

Passing these historical gates permits a money-readiness research promotion only. Correctly capitalized forward demo evidence and a second broker remain mandatory before real-money consideration.
