# Operational-Hardening Portfolio Decision

## Decision

**PROMOTE AS v0.2-rc1 OPERATIONAL CANDIDATE; DO NOT DECLARE LIVE-READY.**

This is a safety-only fork of Transferable Portfolio v0.1. It is not a new higher-profit strategy and does not replace the frozen forward-demo registration. Its purpose is to close operational risk gaps while preserving the validated signal and position-management behavior exactly.

## Exact fidelity

| Model | Net profit | PF | Trades | Max DD | Recovery | Event comparison |
|---|---:|---:|---:|---:|---:|---|
| Model1 fast gate | +$1,616.49 | 1.58 | 370 | 3.24% | 4.56 | 740/740 exact; 0 mismatches |
| Model4 real ticks | +$1,615.36 | 1.58 | 362 | 2.83% | 5.22 | 724/724 exact; 0 mismatches |

The Model1 and Model4 results match v0.1 exactly. The new safeguards did not alter any lane, side, entry time, exit time, volume, price, stop, profit, or reason field in the historical evidence logs.

## Added safeguards

- Initial attachment requires a USD account and a $10,000 balance within 1%.
- The accepted starting-capital contract is persisted locally per account and portfolio identity so normal profit/loss does not break later restarts.
- Shared weekly loss limit: 1.25%.
- Shared monthly loss limit: 1.50%.
- Portfolio-wide cooldown: 48 hours after nine consecutive losses.
- Minimum margin level for new risk: 300%.
- Any managed position whose stop disappears is closed immediately on tick/timer; unrelated positions are never closed by this audit.
- Real-account trading remains disabled by default and still requires the explicit live approval contract.

The thresholds were selected before the fidelity run. In the validated Model4 history, the worst closed week was 0.605%, the worst closed month was 1.196%, and the maximum consecutive-loss streak was eight. Therefore the new limits were expected to remain dormant in the validation history while still bounding worse live behavior.

## Identity

- Source SHA-256: `015DCCDBA020796895C1A71B150C31B4F0F276A9334243BD7474293F73385EB4`
- Binary SHA-256: `4C0BF9BEF949772DA537091EB8E3464FCF9910F9AF55D2A17B7305E1E8ED4756`
- Model1 profile SHA-256: `A07186CA0A8BEF485529E53748BEB805DC1BF9CE310685946EE58D25ACC71121`
- Model4 profile SHA-256: `7E7081A9BF179BC1B93623316D8EFFFB3C0CED91ACF0FFDE91BD61ABD712F6B2`
- Compile: 0 errors, 0 warnings.

## Forward status

This candidate has no valid forward evidence. The currently attached demo has $100,000 rather than the frozen $10,000 starting capital, so it is invalid before its first trade. Its days and trades remain excluded; the registration, profile, source, binary, and account identity were not amended to make it pass.

The released v0.1 forward candidate remains frozen. v0.2-rc1 must receive its own correctly capitalized, immutable forward registration before any live-readiness claim. Real-money use is not approved.
