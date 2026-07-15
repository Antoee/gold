# Source Manifest

Generated from the local EA source without launching MT5.

## Local EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Mirrored file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `22195`
- Size: `948230` bytes
- SHA-256: `F254FDF07B932FD8009E1ABFD761D1C9195568596A559F0DCB73A8CD29157D8F`
- Exposed MT5 tester inputs: `327`
- Last verified locally: `2026-07-14`
- Root/mirror sync: `PASS`
- Current-source compile: `PASS` locally via `outputs/MT5_HIDDEN_COMPILE_DGF_LOSS_BLOCK.log`, `0 errors, 0 warnings`

The latest source update changed the mirrored source hash to `F254FDF07B932FD8009E1ABFD761D1C9195568596A559F0DCB73A8CD29157D8F`. Root and mirrored source hashes match. The source stays below the MT5 tester input-limit guard and adds default-off DGF no-cushion loss-block controls for research. The live-readiness compile-evidence router may still require a returned compile proof package before a final live gate can pass, but the local hidden MetaEditor compile for this exact source is clean.

## Current Research Best

Current newest range-elite research leads:

- High-profit: `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock`
- Broad-window stability: `re_may140_late15_dgf_liq_reject1_cush35_dgflossblock`

Most recent focused Model4 broad-window result on the current source:

- Model: `4`
- Windows: `2019`, `2021`, `2023`, `2024`, `2025`, `2026 YTD`
- High-profit net: `+$2,800.21`
- High-profit average annualized return: `52.09%/yr`
- High-profit worst window: `-$7.36`
- Stability net: `+$2,323.11`
- Stability average annualized return: `39.02%/yr`
- Stability worst window: `+$0.68`
- Worst drawdown: about `20.8%`

Both profiles are research-only because drawdown remains high, trade counts are thin, and stress/broker/forward evidence is missing.

## Candidate Profiles

Newest range-elite research aliases:

- High-profit file: `outputs/CANDIDATE_RANGE_ELITE_HIGH_PROFIT_DGF_LOSSBLOCK_PROFILE.set`
- High-profit SHA-256: `1C0CF498F243ED6002FB74BBE3EA0247348B40F410B12EA74CD4720B998A9543`
- Stability file: `outputs/CANDIDATE_RANGE_ELITE_STABILITY_DGF_LOSSBLOCK_PROFILE.set`
- Stability SHA-256: `306BB06F12768F7E9439827CC8C7125E7103BFF08742CD6B2B57EAD2C2C50B86`
- Status: research-only; not live-ready

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

The latest 2026-07-14 source change keeps the exposed MT5 tester input surface under the guard at `327`, adds the default-off `InpUseDiagnosticFallbackNoCushionLossBlock` controls, keeps the default-off `InpUseDiagnosticFallbackCushionRiskThrottle` controls, keeps the default-off `InpDiagnosticFallbackRejectLiquiditySweepSignal` controls, keeps the default-off `InpUseDiagnosticFallbackLateSessionGuard` controls, keeps the default-off `InpDiagnosticFallbackBlockLiquiditySweep` guard, and keeps the earlier default-off diagnostic-fallback spread guard, spread risk scaling, and performance risk scaling controls. Follow-up testing found `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock`, a higher-profit range-elite research lead at `+$2,800.21` with worst window `-$7.36`, and `re_may140_late15_dgf_liq_reject1_cush35_dgflossblock`, an all-green broad-window stability lead at `+$2,323.11`. Both still have about `20.8%` worst DD and are not trade-ready.

These were safety/readiness and research-infrastructure fixes plus a safer range-elite risk-shape probe, not a live-money promotion. No backtest has made the `F254FDF07B932FD8009E1ABFD761D1C9195568596A559F0DCB73A8CD29157D8F` source hash money-ready yet.
