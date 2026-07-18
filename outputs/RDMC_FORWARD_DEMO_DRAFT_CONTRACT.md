# RDMC Forward-Demo Draft Contract

**PREPARED, NOT REGISTERED, NOT FORWARD-READY, AND NOT REAL-MONEY APPROVED.**

This package derives a demo-only profile from the exact frozen combined-candidate profile. It changes six operational or evidence fields and changes zero strategy or risk fields. It does not modify the currently registered forward candidate.

## Frozen identity

- Source SHA-256: `EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F`
- Research profile SHA-256: `746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883`
- Demo-draft profile SHA-256: `CC94B66E59CB4BC4D9C9CFE295C00452133DCFB54ED3FE8ACBF541C5FCA7889B`
- Run label: `rdmc_diversified_repair_forward_demo_draft_v1`

## Current blockers

- Static readiness: `BLOCKED`
- Failed static rules: `consecutive-loss-cap;band-vwap-reversion-disabled`
- Candidate compiled binary: pending the locked executable gate.
- Primary executable gate: not passed.
- Executable ledger cost and order-aware stress: not passed.
- Distinct-broker gate: not passed.
- Valid clean `$10,000` demo heartbeat: not supplied.

The enabled source gate currently rejects the frozen strategy because `InpMaxConsecutiveLosses=4` exceeds its limit of two and `InpUseBandVWAPReversionLane=true` is still classified as experimental. Neither value is changed here because doing so would create a new unvalidated trading path.

## Activation boundary

Registration remains impossible until the exact compiled candidate passes every executable, stress, and distinct-broker prerequisite; the static source gate reports zero blockers; and a fresh read-only heartbeat proves a clean USD `$10,000` demo hedging account with no positions, foreign trades, or prior evidence events while terminal and MQL algorithmic trading are disabled.

No account identifier is stored or published. Real-account trading remains disabled.
