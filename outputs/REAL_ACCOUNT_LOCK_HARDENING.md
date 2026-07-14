# Real-Account Lock Hardening

Generated locally on `2026-07-14 06:39:22 -05:00`.

This is a source-safety change, not a new profit result. It did not launch MT5, MetaEditor, metatester, GitHub Actions, or any visible terminal process.

## Change

`RealAccountSafetyLockAllows()` now fails closed on real accounts when:

`InpUseRealAccountSafetyLock=false`

Before this hardening, disabling that input caused the real-account safety function to return `true` before checking real-account approval identity. The trade-readiness gate could still catch this when enabled, but a real account should not be able to bypass the real-account lock by turning the lock input off.

## Current Identity

| Artifact | SHA-256 |
| --- | --- |
| EA source | `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394` |
| Conservative profile | `F708C68A68016C13C4ADAECFE472A270748F4DAD9F2DF8C12F9870C2324DA13F` |
| Money-ready profile | `2A16CEEC337981A925D933C95AD42526A61DDE7CA1EB583FDD597BCC83F2E250` |
| Reproducibility bundle zip | `24F22DFBF1720276A3F0FB223F6982EE725AACC6ECAED842EAB0566C8DB403F7` |

## Verification

- `STATIC_MQL_COMPILE_PREFLIGHT_PASS checks=29 inputs=1802`
- `MONEY_READY_SAFETY_CONTRACT_PASS`
- `TRADE_READY_CONSERVATIVE_PROFILE_SMOKE_PASS`
- `TRADE_READINESS_PROFILE_SMOKE_PASS`
- Money-ready refresh remains `PENDING`: `5` pass, `10` pending, `0` failed

## Status

There is still no newly validated best profile. This change improves real-account fail-closed behavior, but the bot remains paper/demo only until current-source compile proof, first-pass reports, full validation, trade-quality logs, Monte Carlo, forward/demo, second-broker evidence, and reproducible GitHub source/profile sync are complete.