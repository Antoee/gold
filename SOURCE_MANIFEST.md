# Source Manifest

Generated without launching MT5.

## GitHub EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Status: committed to GitHub as a risk-first, no-martingale/no-grid XAUUSD EA source.
- Compile status: not locally compiled in this remote-only pass.
- Purpose: provides the repository with an actual EA source file matching the documented tester input surface and micro handoff configs.

## Previous Local EA Source Record

A fuller local source was previously verified but not uploaded during the local run:

- Local file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `1706`
- Size: `55572` bytes
- SHA-256: `9243BFB13A89473424EDEA0291C69AFE4E6907B88217261C6545195E4EC4E360`
- Last verified locally: `2026-07-04`

The current GitHub source should be compiled and tested before live or promotion use. If the older 1,706-line local source is still preferred, upload it over `Professional_XAUUSD_EA.mq5` and confirm the SHA-256 above after download.

## Source Features Present In GitHub Version

- No martingale, grid, averaging down, or recovery-system logic.
- Promoted default inputs:
  - `InpRiskPercent=1.60`
  - `InpStopATRMultiplier=1.80`
  - `InpTakeProfitATRMultiplier=3.50`
  - `InpMinRiskReward=1.50`
  - `InpUseBreakEven=false`
- Candidate override support:
  - `InpTakeProfitATRMultiplier=3.80`
  - `InpMaxEquityDrawdownPercent=4.00`
- BOS and liquidity-sweep confirmations.
- Optional EMA cross, momentum candle, engulfing candle, ADX, ATR, adaptive trend-bias, break-even, ATR trailing, and profit giveback guard modules.
- Risk protections:
  - risk-based lot sizing
  - minimum-lot over-risk protection: trades are skipped when the correctly sized lot is below broker minimum
  - daily/weekly/monthly loss guards
  - equity drawdown guard
  - maximum consecutive loss guard through `InpMaxConsecutiveLosses`
  - spread/slippage controls
  - cooldown after loss
  - one-symbol position management
- Custom Strategy Tester scoring through `double OnTester()`.

## Validation Pack State

- Micro handoff configs committed: `8`
- Micro handoff windows: `2024_Q1`, `2024_Q3`, `2025_Q2`, `2025_Q3`
- Date range covered by prepared micro configs: `2024.01.01` through `2025.09.30`
- Full promotion still requires parsed MT5 reports; no new profit evidence is implied by source/config commits.

## Safety Note

MT5 was not launched during this update. Local tester execution remains locked while normal PC use must not be interrupted.
