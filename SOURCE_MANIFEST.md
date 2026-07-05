# Source Manifest

Generated without launching MT5.

## GitHub EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Version: `1.08`
- Status: committed to GitHub as a risk-first, no-martingale/no-grid XAUUSD EA source.
- Compile status: not locally compiled in this remote-only pass.
- Purpose: provides the repository with an actual EA source file matching the documented tester input surface and handoff configs.

## Source Features Present In GitHub Version

- No martingale, grid, averaging down, or recovery-system logic.
- Promoted default inputs include `InpRiskPercent=1.60`, `InpStopATRMultiplier=1.80`, `InpTakeProfitATRMultiplier=3.50`, `InpUseMTFTrendFilter=false`, `InpUseStructureTrailing=false`, `InpUseATRSpreadGuard=false`, and `InpUseTimeExit=false`.
- Candidate override support includes TP `3.80`, equity drawdown guard `4.00`, H1 MTF trend probes, structure-trailing probes, ATR-relative spread guard probes, and time-exit probes.
- BOS and liquidity-sweep confirmations.
- Optional EMA cross, momentum candle, engulfing candle, ADX, ATR, adaptive trend-bias, higher-timeframe EMA trend filter, break-even, ATR trailing, structure trailing, time exit, session/day filter, Friday-evening cutoff, ATR-relative spread guard, and profit giveback guard modules.
- Risk protections include native `OrderCalcProfit`, `OrderCalcMargin`, minimum-lot over-risk skip, period loss guards, equity drawdown guard, consecutive-loss guard, fixed spread/slippage controls, optional ATR-relative spread controls, cooldown, optional stale-trade close, and one-symbol position management.
- Time exit controls: `InpUseTimeExit`, `InpMaxTradeMinutes`.
- ATR spread guard controls: `InpUseATRSpreadGuard`, `InpMaxSpreadATRPercent`.
- Structure trailing controls: `InpUseStructureTrailing`, `InpStructureTrailingLookback`, `InpStructureTrailingBufferATR`, `InpStructureTrailingTriggerATR`.
- MTF trend controls: `InpUseMTFTrendFilter`, `InpMTFTrendTimeframe`, `InpMTFTrendEMA`.
- Custom Strategy Tester scoring through `double OnTester()`.

## Static Safety Automation

- Script: `work/static_repo_safety_audit.py`
- Workflow: `.github/workflows/static-safety.yml`
- Checks source risk/research inputs, forbidden recovery terms, native risk sizing markers, time exit, ATR spread guard, MTF/structure trailing implementation markers, profile input pins, local MT5 launch lock, and non-visual handoff config safety.
- Meaning: this is a safety/readiness gate only. It does not compile the EA and does not prove profit.

## Validation Pack State

- Stress micro handoff configs committed: `8`
- Recent out-of-sample handoff configs committed: `8`
- ATR spread guard probe handoff configs committed: `4`
- Time exit probe handoff configs committed: `4`
- MTF trend probe handoff configs committed: `4`
- Structure trailing probe handoff configs committed: `4`
- Session variant handoff configs committed: `6`
- Date range covered by prepared fast checks: `2024.01.01` through `2026.07.02`
- Full promotion still requires parsed MT5 reports; no new profit evidence is implied by source/config commits.

## Previous Local EA Source Record

A fuller local source was previously verified but not uploaded during the local run:

- Local file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `1706`
- Size: `55572` bytes
- SHA-256: `9243BFB13A89473424EDEA0291C69AFE4E6907B88217261C6545195E4EC4E360`
- Last verified locally: `2026-07-04`

The current GitHub source should be compiled and tested before live or promotion use. If the older 1,706-line local source is still preferred, upload it over `Professional_XAUUSD_EA.mq5` and confirm the SHA-256 above after download.

## Safety Note

MT5 was not launched during this update. Local tester execution remains locked while normal PC use must not be interrupted.
