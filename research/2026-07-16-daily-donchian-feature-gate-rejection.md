# Daily Donchian Feature-Gate Rejection

Date: 2026-07-16

Decision: **reject the Daily Donchian feature-gate branch without opening its 2021-2026 feature holdout.** The maintained EA and promoted profiles remain unchanged.

## Purpose

The Daily Donchian channel-exit lane was profitable across three broad Model1 eras, but its yearly evidence was unstable. This experiment tested whether a date-independent market-state condition could improve the entry stream without adding year, month, or session exceptions.

The isolated diagnostic source logged only features known at entry:

- ADX and aligned directional-index edge
- normalized EMA slope and price-to-EMA distance
- normalized breakout depth and channel width
- ten-day directional efficiency
- breakout-candle body, directional close location, and range
- normalized gap, 63-day ATR regime, and 20-day tick-volume ratio

No diagnostic feature changed an entry, exit, stop, target, or risk amount.

## Reproduction

- Instrumented source SHA-256: `553017D12F177660B8F058A3919F8CEE47338D1D20F97BABA9F61B2DF249CB2D`
- Diagnostic profile SHA-256: `E009D1143261E14560A6086F41DE4E19CBDB12D37F9FB8AC2D9E13F7C5D388F8`
- Compile: `0 errors, 0 warnings`
- Model1 period: 2015-01-01 through 2026-07-12
- Starting balance: `$10,000`
- Result: `+$440.14`, PF `1.41`, `51` trades, maximum equity drawdown `3.77%`
- Runtime: approximately `34 seconds` with entry/exit logging and block-by-block diagnostics disabled

This reproduces the established lane closely enough for feature discovery.

## Frozen Split

- Discovery: 2015-2020
- Validation: 2021-2023
- Final holdout: 2024-2026 YTD

Discovery contained `27` trades, `+$253.28` net, PF `1.4017`, `$269.57` trade-close drawdown, and one losing active year.

## Primary Screen

Four predeclared one-factor families were screened: minimum DI edge, minimum ten-day efficiency, minimum candle-body percentage, and minimum directional close location.

Eligibility required all of the following in discovery:

1. Retain at least 70% of trades.
2. Do not reduce net profit or profit factor.
3. Do not increase trade-close drawdown.
4. Do not increase the number of losing active years.

Only `body_pct >= 20` and `body_pct >= 30` passed, and both retained every trade. They are no-op gates. The profitable-looking higher body thresholds either removed too much activity or increased losing-year count.

## False-Breakout Extension

A second, separately declared screen tested normalized slope, candle range, volume, ATR regime, maximum EMA extension, and maximum breakout depth. It returned `0` eligible gates.

The leading near-miss, `slope_atr >= 0.075`, retained `19 / 27` trades and improved discovery net to `+$346.06`, PF to `1.962`, and trade-close drawdown to `$133.53`. It nevertheless increased losing active years from one to two, so it failed before validation.

## Disposition

- Do not add a Donchian entry gate to the maintained EA.
- Do not inspect 2021-2026 feature-gate results for this rejected hypothesis.
- Do not tune another threshold from these same 51 trades.
- Preserve the instrumented source and exact feature rows as negative research evidence.
- Treat the existing Donchian result as research diversification evidence, not a trade-ready component.

## Evidence

- `outputs/DAILY_DONCHIAN_FEATURE_DIAGNOSTIC_RESULTS.csv`
- `outputs/DAILY_DONCHIAN_FEATURE_LOG.csv`
- `outputs/DAILY_DONCHIAN_FEATURE_TRADES.csv`
- `outputs/DAILY_DONCHIAN_FEATURE_GATE_SCREEN.csv`
- `outputs/DAILY_DONCHIAN_FEATURE_GATE_EXTENSION_SCREEN.csv`
- `outputs/daily_donchian_feature_diagnostic_package`
- `work/analyze_daily_donchian_feature_log.ps1`


