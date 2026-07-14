# Source Manifest

Generated from the local EA source without launching MT5.

## Local EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Mirrored file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `19508`
- Size: `919094` bytes
- SHA-256: `46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E`
- Last verified locally: `2026-07-14`
- Root/mirror sync: `PASS`
- Current-source compile: `PASS`, `0` errors / `0` warnings

The latest compile proof was imported through `outputs/MT5_COMPILE_EVIDENCE_ROUTING.md`, and the compiled source hash matched the mirrored source hash.

## Current Research Best

Current stability-best research profile:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Fresh current-source real-tick continuous result:

- Model: `4`
- Period: `2024.01.01` to `2026.07.12`
- Net: `+$1,195.69`
- Total return from `$1,000`: `+119.57%`
- CAGR: about `+36.51%/yr`

The historical `+$4,507.51` Model4 result remains stale until reproduced on the current source.

## Candidate Profiles

Conservative trade-ready candidate:

- File: `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`
- SHA-256: `0A97B46D7E3A3C3566EF4E787BCB63E2138D114C2F0F898F9A8B1A10F842BF90`
- Evidence profile id: `trade_ready_conservative`
- Evidence source hash: `46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E`
- Real-account trading: locked/disabled

Money-ready/demo candidate:

- File: `outputs/CANDIDATE_MONEY_READY_PROFILE.set`
- SHA-256: `2F2B757768AA14CC864F5A161305E1A4E05C1B4228B880BEBA6CD5C50D8D6231`
- Alias: `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set`
- Alias SHA-256: `2F2B757768AA14CC864F5A161305E1A4E05C1B4228B880BEBA6CD5C50D8D6231`
- Evidence profile id: `money_ready`
- Evidence source hash: `46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E`
- Real-account trading: locked/disabled

## Live-Readiness Snapshot

- Overall: `PENDING`
- Passing gates: `6`
- Pending gates: `7`
- Failed gates: `0`
- Reproducibility bundle: `PASS`, `49` pass / `0` pending / `0` fail
- Money-ready refresh: `PENDING`, `5` pass / `9` pending / `0` fail

Remaining proof blockers:

- first-pass MT5 reports
- full conservative validation reports
- broker-proxy reports
- conservative trade/deal logs with realized R
- Monte Carlo trade-stress pass
- forward/demo evidence
- second-broker evidence
- GitHub source/profile publication sync

## Source Notes

The 2026-07-14 source change shortened six overlong FMLR input identifiers so MetaEditor can compile the current EA source:

- `InpFMLRDispPBBreakLookbackBars`
- `InpFMLRDispPBBreakBufferPoints`
- `InpFMLRDispPBMinCloseLocation`
- `InpFMLRDispPBMinBreakRangeATR`
- `InpFMLRDispPBMinBreakBodyPercent`
- `InpFMLROBRetestMinImpulseBodyPercent`

This was a compile/readiness fix, not a new profitable strategy promotion.