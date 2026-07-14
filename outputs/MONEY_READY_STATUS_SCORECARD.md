# Money-Ready Status Scorecard

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Verdict: **NOT_READY_PENDING_EVIDENCE**
- Best current candidate: `trade_ready_conservative`
- Profile hash: `621F54A4BFE61761577D87DB212CF024163F25066209C205090E72227FE584A6`
- Source hash: `44D9EBA868C86EB6C57DF82C3B94D83ACFE994B1A665917EC05AB8313188A5F7`
- Passing rows: `5`
- Pending rows: `14`
- Failed rows: `0`

The bot is not money-ready yet because required evidence is still missing or stale. Real-account trading remains locked.

## Passing Areas

- Conservative profile artifact exists and hash is captured.
- Real-account trading is disabled by approval lock.
- Risk shape is strict: `0.10%` risk, `0.20%` open-risk cap, `0.01` max lots, tight daily/weekly/monthly/equity drawdown caps.
- Local PC safety audit passes.
- Local reproducibility freeze passes.

## Pending Areas

- Conservative audit still has open proof gaps.
- Model4 validation results are missing.
- Exact continuous return and return/drawdown efficiency are not proven yet.
- Profit factor, recovery factor, and drawdown gates are pending returned reports.
- Current-source compile proof is stale.
- Trade-quality logs are missing.
- Monte Carlo trade stress is missing trade-log input.
- Forward/demo evidence is missing.
- Second-broker evidence is missing.
- GitHub/source-publication sync is pending.
- First-pass trusted decision is still waiting for evidence.

## Bottom Line

This is a disciplined candidate, not a live-money bot. Do not loosen risk or create a manual live-review profile until the pending gates close.
