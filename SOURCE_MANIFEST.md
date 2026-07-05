# Source Manifest

Generated without launching MT5.

## GitHub EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Version: `1.09`
- Status: committed to GitHub as a risk-first, no-martingale/no-grid XAUUSD EA source.
- Compile status: not locally compiled in this remote-only pass.
- Purpose: provides the repository with an actual EA source file matching the documented tester input surface and handoff configs.

## Source Features Present In GitHub Version

- No martingale, grid, averaging down, or recovery-system logic.
- Promoted default inputs include `InpRiskPercent=1.60`, `InpStopATRMultiplier=1.80`, `InpTakeProfitATRMultiplier=3.50`, `InpMinimumConfirmations=2`, `InpMinADX=0.0`, `InpUseMTFTrendFilter=false`, `InpUseStructureTrailing=false`, `InpUseATRSpreadGuard=false`, `InpUseBreakEven=false`, `InpUseTimeExit=false`, and `InpUseNewsTimeFilter=false`.
- Candidate override support includes TP `3.80`, equity drawdown guard `4.00`, confirmation-3 probes, break-even probes, ADX 18 probes, H1 MTF trend probes, structure-trailing probes, ATR-relative spread guard probes, time-exit probes, and optional news-time blackout probes.
- BOS and liquidity-sweep confirmations.
- Optional EMA cross, momentum candle, engulfing candle, ADX, ATR, adaptive trend-bias, higher-timeframe EMA trend filter, break-even, ATR trailing, structure trailing, time exit, session/day filter, Friday-evening cutoff, manual/NFP news-time blackout filter, ATR-relative spread guard, and profit giveback guard modules.
- Risk protections include native `OrderCalcProfit`, `OrderCalcMargin`, minimum-lot over-risk skip, period loss guards, equity drawdown guard, consecutive-loss guard, fixed spread/slippage controls, optional ATR-relative spread controls, optional scheduled news blackout controls, cooldown, optional stale-trade close, and one-symbol position management.
- Custom Strategy Tester scoring through `double OnTester()`.

## Static Safety Automation

- Script: `work/static_repo_safety_audit.py`
- Break-even pack audit: `work/static_breakeven_probe_audit.py`
- Workflow: `.github/workflows/static-safety.yml`
- Meaning: this is a safety/readiness gate only. It does not compile the EA and does not prove profit.

## Validation Pack State

- Stress smoke handoff configs committed: `2`
- Stress micro handoff configs committed: `8`
- Recent out-of-sample handoff configs committed: `8`
- Confirmation strictness probe handoff configs committed: `4`
- Break-even probe handoff configs committed: `4`
- ADX filter probe handoff configs committed: `4`
- ATR spread guard probe handoff configs committed: `4`
- Time exit probe handoff configs committed: `4`
- News filter probe handoff configs committed: `4`
- MTF trend probe handoff configs committed: `4`
- Structure trailing probe handoff configs committed: `4`
- Session variant handoff configs committed: `6`
- Fast-probe readiness builder committed: `work/build_fast_probe_readiness_snapshot.ps1`
- Next fast batch selector committed: `work/build_next_fast_batch_selector.ps1`
- Current next fast batch: `STRESS_SMOKE` (`2` rows) until exported reports change readiness.
- Date range covered by prepared fast checks: `2024.01.01` through `2026.07.02`
- Full promotion still requires parsed MT5 reports; no new profit evidence is implied by source/config/report-script commits.

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