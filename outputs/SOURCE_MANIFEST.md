# Source Manifest

Generated from the local EA source without launching MT5.

## Local EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Mirrored file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `19843`
- Size: `948690` bytes
- SHA-256: `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A`
- Exposed MT5 tester inputs: `328`
- Last verified locally: `2026-07-14`
- Root/mirror sync: `PASS`
- Static preflight: `STATIC_MQL_COMPILE_PREFLIGHT_PASS checks=33 inputs=328`
- Current-source compile: `PASS` locally via `outputs/MT5_HIDDEN_COMPILE_PEAK_TRAIL_UNBLOCK.log`, `0 errors, 0 warnings`

The latest source update changed the mirrored source hash to `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A`. Root and mirrored source hashes match. The source stays below the MT5 tester input-limit guard and adds a default-off max-age limiter for the DGF no-cushion loss-block research control. The live-readiness compile-evidence router may still require a returned compile proof package before a final live gate can pass, but the local hidden MetaEditor compile for this exact source is clean.

## Current Research Best

Current stability lead:

- `r10_pg40_atr085_adapt7`
- Model4 yearly 2019-2026 YTD: `+$263.72`, one red year (`2020`, `-$22.92`), `7.09%` worst DD, `22` trades.
- Status: research-only; low-drawdown/stability reference, not money-ready.

Current DGF high-profit continuous research lead:

- `lossblock_highprofit_peaktrail_off`
- Model4 continuous 2019-2026: `+$1,915.83`, total return `+191.58%`, average annualized return `25.45%/yr`, CAGR `15.28%`, PF `1.72`, recovery `2.02`, `127` trades, `24.58%` max equity DD.
- Status: high-profit research-only; not money-ready because drawdown is high and full yearly/monthly/quarterly/stress/broker/forward evidence is missing.

The older DGF peak-trail-on loss-block aliases are superseded as sequential-account leads. Continuous 2019-2026 Model4 testing showed they stalled after only `3` trades, so their broad-window totals are restart-window comparison scores only.

## Candidate Profiles

Newest DGF continuous high-profit alias:

- File: `outputs/CANDIDATE_RANGE_ELITE_HIGHPROFIT_PEAKTRAIL_OFF_CONTINUOUS_PROFILE.set`
- SHA-256: `0FBFA1F540422DF1B88A9410752E706B917F3111BFEF317F7EE9A03D7A4C2499`
- Status: research-only; not live-ready

Superseded DGF restart-window aliases:

- High-profit file: `outputs/CANDIDATE_RANGE_ELITE_HIGH_PROFIT_DGF_LOSSBLOCK_PROFILE.set`
- High-profit SHA-256: `1C0CF498F243ED6002FB74BBE3EA0247348B40F410B12EA74CD4720B998A9543`
- Stability file: `outputs/CANDIDATE_RANGE_ELITE_STABILITY_DGF_LOSSBLOCK_PROFILE.set`
- Stability SHA-256: `306BB06F12768F7E9439827CC8C7125E7103BFF08742CD6B2B57EAD2C2C50B86`
- Status: superseded as sequential-account leads; retained as restart-window research references

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

The latest 2026-07-14 source change keeps the exposed MT5 tester input surface under the guard at `328`, adds default-off `InpUseDiagnosticFallbackNoCushionLossBlock` controls plus `InpDiagnosticFallbackLossBlockMaxAgeDays`, keeps the default-off `InpUseDiagnosticFallbackCushionRiskThrottle` controls, keeps the default-off `InpDiagnosticFallbackRejectLiquiditySweepSignal` controls, keeps the default-off `InpUseDiagnosticFallbackLateSessionGuard` controls, keeps the default-off `InpDiagnosticFallbackBlockLiquiditySweep` guard, and keeps the earlier default-off diagnostic-fallback spread guard, spread risk scaling, and performance risk scaling controls. Follow-up testing found that the original DGF peak-trail-on loss-block profiles stalled on the continuous account path. The only profitable DGF continuous follow-up is `lossblock_highprofit_peaktrail_off` at `+$1,915.83`, PF `1.72`, `127` trades, and `24.58%` max equity DD. It is a high-profit research lead only and is not trade-ready.

These were safety/readiness and research-infrastructure fixes plus a continuous-account DGF follow-up, not a live-money promotion. No backtest has made the `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A` source hash money-ready yet.
