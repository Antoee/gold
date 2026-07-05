# Source Manifest

Generated without launching MT5.

## GitHub EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Version: `1.04`
- Status: committed to GitHub as a risk-first, no-martingale/no-grid XAUUSD EA source.
- Compile status: not locally compiled in this remote-only pass.
- Purpose: provides the repository with an actual EA source file matching the documented tester input surface and handoff configs.

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
- Optional EMA cross, momentum candle, engulfing candle, ADX, ATR, adaptive trend-bias, break-even, ATR trailing, session/day filter, Friday-evening cutoff, and profit giveback guard modules.
- Risk protections:
  - risk-based lot sizing
  - native `OrderCalcProfit` loss-per-lot sizing with tick-value fallback
  - native `OrderCalcMargin` free-margin check that steps lot size down or skips the trade
  - minimum-lot over-risk protection: trades are skipped when the correctly sized lot is below broker minimum
  - daily/weekly/monthly loss guards
  - equity drawdown guard
  - maximum consecutive loss guard through `InpMaxConsecutiveLosses`
  - spread/slippage controls
  - cooldown after loss
  - one-symbol position management
- Session controls:
  - `InpUseSessionFilter`
  - `InpSessionStartHour` / `InpSessionEndHour`
  - weekday toggles for Monday through Friday plus Sunday
  - `InpDisableFridayEvening` and `InpFridayCutoffHour`
- Custom Strategy Tester scoring through `double OnTester()`.

## Static Safety Automation

- Script: `work/static_repo_safety_audit.py`
- Workflow: `.github/workflows/static-safety.yml`
- Runs on GitHub Actions for push, pull request, and manual dispatch.
- Checks:
  - committed EA source exists and exposes required risk/research inputs
  - forbidden recovery-style concepts are absent from executable source after comment stripping
  - native `OrderCalcProfit` and `OrderCalcMargin` risk-sizing markers are present
  - session filter implementation and root-profile session input pins are present
  - hard local MT5 launch lock and launch guard are present
  - protected TP 3.80 candidate `.set` files use `InpMaxEquityDrawdownPercent=4.00`
  - stress micro and recent-OOS manifests have 8 rows each
  - handoff configs are non-visual, non-optimizing, shutdown after run, and target XAUUSD M15
- Meaning: this is a safety/readiness gate only. It does not compile the EA and does not prove profit.

## Validation Pack State

- Stress micro handoff configs committed: `8`
- Stress micro windows: `2024_Q1`, `2024_Q3`, `2025_Q2`, `2025_Q3`
- Recent out-of-sample handoff configs committed: `8`
- Recent out-of-sample windows: `2025_Q4`, `2026_Q1`, `2026_Q2`, `2026_YTD`
- Date range covered by prepared fast checks: `2024.01.01` through `2026.07.02`
- Full promotion still requires parsed MT5 reports; no new profit evidence is implied by source/config commits.

## Safety Note

MT5 was not launched during this update. Local tester execution remains locked while normal PC use must not be interrupted.
