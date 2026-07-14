# 2026-07-14 Range-Elite Risk-Shape Rejection Note

The latest local run did not produce a new best profile.

What improved:

- The current EA source now compiles and runs again under MT5's tester input ceiling.
- Exposed inputs were reduced from `1826` to `308`.
- Static preflight now fails if the EA grows past the tester input guard.
- The range-elite risk-shape package builder now prunes stale `.set` keys and rejects non-exposed candidate overrides.
- The aligned 80-config Model1 run returned and parsed `80 / 80` exported MT5 reports.

What failed:

- `re_blockliq` had no measurable effect versus `re_base`.
- `re_may140` and `re_blockliq_may140` improved total net and reduced worst DD versus base, but still lost money in 2019, 2021, and 2023.
- Diagnostic-fallback quality-gate variants mostly destroyed the 2024/2026 profit engine and did not solve robustness.

Conclusion:

Keep the source/tester infrastructure fix. Reject the strategy variants. The next strategy-code change should target the older-year entry/regime failure pattern directly, not just lower or reshape risk.
