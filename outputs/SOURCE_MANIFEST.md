# Source Manifest

Generated from the local EA source without launching MT5.

## Local EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Mirrored file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `19781`
- Size: `945552` bytes
- SHA-256: `C23144DDE1F26C29135489FC9DF065FC5B5575C0B3F1B388BECC01E70E5965B4`
- Exposed MT5 tester inputs: `316`
- Last verified locally: `2026-07-14`
- Root/mirror sync: `PASS`
- Current-source compile: `PASS` locally via `outputs/MT5_HIDDEN_COMPILE_DGF_CUSHION_RISK.log`, `0 errors, 0 warnings`

The latest source update changed the mirrored source hash to `C23144DDE1F26C29135489FC9DF065FC5B5575C0B3F1B388BECC01E70E5965B4`. Root and mirrored source hashes match. The source now stays below the MT5 tester input-limit guard after demoting stale research controls from `input` variables to internal defaults, and adds default-off DGF cushion-risk throttle controls for research. The live-readiness compile-evidence router may still require a returned compile proof package before a final live gate can pass, but the local hidden MetaEditor compile for this exact source is clean.

## Current Research Best

Current stability-best research profile:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Most recent reproduced real-tick continuous result before the trade-environment guard source update:

- Model: `4`
- Period: `2024.01.01` to `2026.07.12`
- Net: `+$1,195.69`
- Total return from `$1,000`: `+119.57%`
- CAGR: about `+36.51%/yr`

The historical `+$4,507.51` Model4 result remains stale until reproduced on the current source.

## Candidate Profiles

Conservative trade-ready candidate:

- File: `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`
- SHA-256: `F708C68A68016C13C4ADAECFE472A270748F4DAD9F2DF8C12F9870C2324DA13F`
- Evidence profile id: `trade_ready_conservative`
- Evidence source hash: `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`
- Real-account trading: locked/disabled

Money-ready/demo candidate:

- File: `outputs/CANDIDATE_MONEY_READY_PROFILE.set`
- SHA-256: `2A16CEEC337981A925D933C95AD42526A61DDE7CA1EB583FDD597BCC83F2E250`
- Alias: `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set`
- Alias SHA-256: `2A16CEEC337981A925D933C95AD42526A61DDE7CA1EB583FDD597BCC83F2E250`
- Evidence profile id: `money_ready`
- Evidence source hash: `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`
- Real-account trading: locked/disabled

## Live-Readiness Snapshot

- Overall: `PENDING`
- Passing gates: `5`
- Pending gates: `8`
- Failed gates: `0`
- Reproducibility bundle: `PASS`, `75` pass / `0` pending / `0` fail
- Money-ready refresh: `PENDING`, `4` pass / `11` pending / `0` fail

Remaining proof blockers:

- current-source compile proof
- first-pass MT5 reports
- full conservative validation reports
- broker-proxy reports
- conservative trade/deal logs with realized R
- Monte Carlo trade-stress pass
- forward/demo evidence
- second-broker evidence
- GitHub source/profile publication sync

## Source Notes

The 2026-07-14 source changes include a trade-environment guard for test/live candidate profiles. When enabled, it blocks new entries on bad or stale quotes, insufficient signal bars, invalid symbol specs, disabled/close-only trade mode, excessive broker stop/freeze levels, or missing tick value. The conservative and money-ready profiles enable this guard.

The latest 2026-07-14 source hardening also makes `RealAccountSafetyLockAllows()` fail closed on real accounts when `InpUseRealAccountSafetyLock=false`. Real-account initialization now requires the safety lock to remain enabled plus the explicit approval code, matching evidence profile id, matching evidence source hash, non-empty evidence run label, and enabled trade-readiness gate.

The returned-report routers now reject non-empty but incomplete `.htm`, `.html`, or `.xml` files unless they contain the expected full MT5 tester-stat labels: net profit, profit factor, expected payoff, Sharpe ratio, total trades, win rate/profit trades, maximum/maximal consecutive losses, and balance/equity drawdown. This prevents screenshots, balance-only exports, or log snippets from being routed into first-pass or conservative validation folders.

An earlier 2026-07-14 source change also shortened six overlong FMLR input identifiers so MetaEditor can compile the EA source:

- `InpFMLRDispPBBreakLookbackBars`
- `InpFMLRDispPBBreakBufferPoints`
- `InpFMLRDispPBMinCloseLocation`
- `InpFMLRDispPBMinBreakRangeATR`
- `InpFMLRDispPBMinBreakBodyPercent`
- `InpFMLROBRetestMinImpulseBodyPercent`

The latest 2026-07-14 source change keeps the exposed MT5 tester input surface under the guard at `316`, adds the default-off `InpUseDiagnosticFallbackCushionRiskThrottle` controls, keeps the default-off `InpDiagnosticFallbackRejectLiquiditySweepSignal` controls, keeps the default-off `InpUseDiagnosticFallbackLateSessionGuard` controls, keeps the default-off `InpDiagnosticFallbackBlockLiquiditySweep` guard, and keeps the earlier default-off diagnostic-fallback spread guard, spread risk scaling, and performance risk scaling controls. Follow-up testing found `re_may140_late15_dgf_liq_reject1_cush50`, a safer range-elite risk shape at `+$2,770.74` with `20.84%` worst DD, but it still has a red 2019 window and is not trade-ready.

These were safety/readiness and research-infrastructure fixes plus a safer range-elite risk-shape probe, not a live/stability promotion. No backtest has made the `C23144DDE1F26C29135489FC9DF065FC5B5575C0B3F1B388BECC01E70E5965B4` source hash money-ready yet.
