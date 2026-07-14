# GitHub Required Artifact Sync Package

Generated offline. This does not launch MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Package folder: `outputs\github_required_artifact_sync_package`
- Zip: `outputs\github_required_artifact_sync_package.zip`
- Required artifacts: `5`
- Source artifacts hash-match: `True`
- Trade-readiness alias matches money-ready profile: `True`
- Unsafe profile rows: `0`

## Purpose

This package contains the exact local source/profile artifacts that still block the live-readiness GitHub publication-sync gate. Upload these exact files to their listed remote paths, then run `work\audit_github_publication_sync.ps1` and `work\refresh_money_ready_status.ps1`. Passing this package alone does not approve live trading.

## Required Uploads

| Role | Remote Path | Bytes | SHA-256 | Git Blob SHA-1 | Evidence Profile | Evidence Source | Live Trading |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| root-ea-source | `Professional_XAUUSD_EA.mq5` | 923267 | `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412` | `71475f3665b2ea849c0f1b8c7dfc3b1f22f89899` |  |  |  |
| mirrored-ea-source | `outputs/Professional_XAUUSD_EA.mq5` | 923267 | `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412` | `71475f3665b2ea849c0f1b8c7dfc3b1f22f89899` |  |  |  |
| trade-ready-conservative-profile | `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set` | 24041 | `82530801102198E81E08E1EF772D5501B52FB88CCFD67E6651CE32EF1D055665` | `8c4a3eb4df10803a3a53f2abbced9b5ca1b837ac` | trade_ready_conservative | 5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412 | false||false||0||0||N |
| money-ready-profile | `outputs/CANDIDATE_MONEY_READY_PROFILE.set` | 23941 | `553A967B5FCE72AF31126A78CFDCDA035A953BF55D9DBEB8F56D64D723C3AE3E` | `d8389ca533a7fffbcae404da14b3e6594c86ed78` | money_ready | 5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412 | false||false||0||0||N |
| trade-readiness-alias-profile | `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set` | 23941 | `553A967B5FCE72AF31126A78CFDCDA035A953BF55D9DBEB8F56D64D723C3AE3E` | `d8389ca533a7fffbcae404da14b3e6594c86ed78` | money_ready | 5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412 | false||false||0||0||N |

## Safety Notes

- These files preserve the real-account lock. They do not create a live profile.
- The conservative candidate remains pending compile, full validation, trade quality, Monte Carlo, forward/demo, and second-broker evidence.
- The exact EA source is large enough that connector text updates may be awkward; this package is the local source of truth for a normal git push or another exact file-upload path.
