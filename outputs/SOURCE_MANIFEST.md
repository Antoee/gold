# Source Manifest

Generated from the local EA source without launching MT5.

## Local EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Mirrored file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `21940`
- Size: `923267` bytes
- SHA-256: `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`
- Last verified locally: `2026-07-14`
- Root/mirror sync: `PASS`
- Current-source compile: `PENDING`, stale previous compile proof exists for source hash `46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E`

The latest source hardening changed the mirrored source hash to `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`. The old compile proof was archived as stale; a fresh MetaEditor compile log plus the exact compiled `.mq5` source copy must be returned through `outputs/MT5_COMPILE_EVIDENCE_ROUTING.md` before the compile gate can pass again.

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
- SHA-256: `82530801102198E81E08E1EF772D5501B52FB88CCFD67E6651CE32EF1D055665`
- Evidence profile id: `trade_ready_conservative`
- Evidence source hash: `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`
- Real-account trading: locked/disabled

Money-ready/demo candidate:

- File: `outputs/CANDIDATE_MONEY_READY_PROFILE.set`
- SHA-256: `553A967B5FCE72AF31126A78CFDCDA035A953BF55D9DBEB8F56D64D723C3AE3E`
- Alias: `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set`
- Alias SHA-256: `553A967B5FCE72AF31126A78CFDCDA035A953BF55D9DBEB8F56D64D723C3AE3E`
- Evidence profile id: `money_ready`
- Evidence source hash: `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`
- Real-account trading: locked/disabled

## Live-Readiness Snapshot

- Overall: `PENDING`
- Passing gates: `5`
- Pending gates: `8`
- Failed gates: `0`
- Reproducibility bundle: `PASS`, `52` pass / `0` pending / `0` fail
- Money-ready refresh: `PENDING`, `4` pass / `10` pending / `0` fail

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

An earlier 2026-07-14 source change also shortened six overlong FMLR input identifiers so MetaEditor can compile the EA source:

- `InpFMLRDispPBBreakLookbackBars`
- `InpFMLRDispPBBreakBufferPoints`
- `InpFMLRDispPBMinCloseLocation`
- `InpFMLRDispPBMinBreakRangeATR`
- `InpFMLRDispPBMinBreakBodyPercent`
- `InpFMLROBRetestMinImpulseBodyPercent`

These were safety/readiness fixes, not new profitable strategy promotions. No new backtest has promoted the `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412` source hash yet.
