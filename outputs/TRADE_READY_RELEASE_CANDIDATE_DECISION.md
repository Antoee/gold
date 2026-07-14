# Trade-Ready Release Candidate Decision

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Verdict: **NOT_RELEASEABLE_PENDING_EVIDENCE**
- Passing rows: `2`
- Pending rows: `4`
- Failed rows: `0`
- Profile hash: `621F54A4BFE61761577D87DB212CF024163F25066209C205090E72227FE584A6`
- Source hash: `44D9EBA868C86EB6C57DF82C3B94D83ACFE994B1A665917EC05AB8313188A5F7`

## Current Output

Only the locked conservative profile exists:

`outputs/TRADE_READY_RELEASE_PROFILE_LOCKED.set`

No manual live-review profile should be written until every live-readiness and money-ready scorecard gate passes and an explicit approval identity matches the evidence profile/source identity.

## Why It Is Blocked

- Money-ready scorecard is still `NOT_READY_PENDING_EVIDENCE`.
- Live-readiness is still `PENDING`.
- Validation reports are missing.
- Trade-quality, Monte Carlo, forward/demo, and second-broker evidence are missing.

## Bottom Line

Not releaseable. Do not trade this profile with real money yet.
