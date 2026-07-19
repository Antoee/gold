# Three-Lane Trade-Ready RC2 ATB150

**Classification: best historically validated trade-ready profile. Not registered for forward trading and not approved for real money.**

## Files

- `Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5`: exact tested RC2 source.
- `THREE_LANE_TRADE_READY_RC2_ATB150.set`: exact tested ATB150 profile.

## Identity

| Artifact | SHA-256 |
|---|---|
| Source | `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158` |
| Profile | `705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E` |
| Continuous report | `31A383253B7BF7611D6209E296317105E4C5756A8A12D883C0872245866B1B4D` |
| Continuous-run binary | `E24203F2E7AF184B6B6BB3902F7C8711DD887B0E0346C22ED87E8F07EB1AC7B8` |

MetaEditor output was 0 errors and 0 warnings. Builds are not bit-reproducible across isolated MT5 runtimes, so the binary hash identifies the exact executable that produced the continuous report. This package distributes source and profile, not an unverified `.ex5`.

## Validated Result

MT5 Model 4 real ticks, XAUUSD, `$10,000`, 2015-01-01 through 2026-07-12:

| Metric | Value |
|---|---:|
| Net / return | `+$2,105.08 / +21.05%` |
| CAGR | `+1.67%` |
| Profit factor | `1.81` |
| Trades | `404` |
| Win rate | `44.31%` |
| Maximum equity drawdown | `$134.35 / 1.15%` |
| Recovery factor | `15.67` |

Compared with the previous RC2 center profile, net profit improved by `5.54%`, money drawdown declined by `3.42%`, recovery improved by `9.28%`, and the trade sample increased by 37. All three broad eras and all 12 annual/YTD restarts remained profitable.

## Exact Change

Only one strategy-risk input changed from the prior profile:

- `InpATBRiskPercent`: `0.10` to `0.15`.

Reversion remains `0.45%`, momentum remains `0.15%`, total open risk remains `0.75%`, maximum equity drawdown remains `5%`, and daily/weekly/monthly limits remain unchanged. The profile's evidence run label is retained exactly as tested.

## Safety And Stress

- Base RC2 source safety: `79/79` checks passed.
- ATB150 promotion safety: `60/60` checks passed.
- Hard-risk audit: `404/404` entries passed.
- Severe added cost: `+$1,506.55`, PF `1.515`, all broad eras positive.
- Monte Carlo: `8/8` 10,000-trial rows passed; weakest severe block P05 was `+$238.64`, worst P95 drawdown `4.225%`, and worst red trials `1.35%`.

## Remaining Boundary

This is the strongest exact historical profile in the repository, but it has no valid forward evidence. Recent activity is still sparse, with only three trades in 2025 and two in 2026 YTD restarts. It requires broker-specification variation and a new preregistered untouched `$10,000` demo sample. The current `$100,000` attachment remains invalid and counts as zero days and zero trades. Real-account trading remains disabled.
