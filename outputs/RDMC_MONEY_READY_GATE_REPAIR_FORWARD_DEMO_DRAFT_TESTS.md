# RDMC Money-Ready Gate-Repair Forward-Demo Draft Tests

**PASS.** Four deterministic activation scenarios were refused for the intended reasons, and the draft changed zero strategy/risk inputs.

- Frozen profile inputs: `589`
- Allowed operational/evidence differences: `6`
- Strategy/risk differences: `0`
- Static readiness blockers: `none`
- Manifest artifacts verified: `9`

| Scenario | Ready | Expected | Required refusal | Pass |
|---|---:|---:|---|---:|
| clean_10000_but_prerequisites_pending | False | False | executable/stress/broker/binaries | True |
| wrong_100000_capital | False | False | starting-balance;starting-equity | True |
| wrong_candidate_identity | False | False | heartbeat-identity | True |
| stale_sentinel_heartbeat | False | False | heartbeat-fresh | True |

The clean `$10,000` fixture remains refused because executable, binary, stress, and broker prerequisites are incomplete. The `$100,000` fixture also fails both capital gates. No registration, funding baseline, account identifier, forward day, or forward trade was created.
