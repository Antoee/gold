# GitHub Required Artifact Sync Package

Generated offline. This does not launch MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Package folder: `outputs\github_required_artifact_sync_package`
- Zip: `outputs\github_required_artifact_sync_package.zip`
- Required artifacts: `7`
- Source artifacts hash-match: `True`
- Trade-readiness alias matches money-ready profile: `True`
- Unsafe profile rows: `0`

## Purpose

This package contains the exact local source/profile/status artifacts required by the live-readiness GitHub publication-sync gate. Upload these exact files to their listed remote paths, then run `work\audit_github_publication_sync.ps1` and `work\refresh_money_ready_status.ps1`. Passing this package alone does not approve live trading.

## Required Uploads

| Role | Remote Path | Bytes | SHA-256 | Git Blob SHA-1 | Evidence Profile | Evidence Source | Live Trading |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| root-ea-source | `Professional_XAUUSD_EA.mq5` | 923394 | `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394` | `89a515eaeb56edfb89bc29674b21bdf9b4b3935c` |  |  |  |
| mirrored-ea-source | `outputs/Professional_XAUUSD_EA.mq5` | 923394 | `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394` | `89a515eaeb56edfb89bc29674b21bdf9b4b3935c` |  |  |  |
| trade-ready-conservative-profile | `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set` | 24041 | `F708C68A68016C13C4ADAECFE472A270748F4DAD9F2DF8C12F9870C2324DA13F` | `2fd7885bcaebe8cfc66e015a86a2874d8b619982` | trade_ready_conservative | FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394 | false||false||0||0||N |
| money-ready-profile | `outputs/CANDIDATE_MONEY_READY_PROFILE.set` | 23941 | `2A16CEEC337981A925D933C95AD42526A61DDE7CA1EB583FDD597BCC83F2E250` | `36f46b384b45b3ff7593f4a7f82dad03e7ae24af` | money_ready | FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394 | false||false||0||0||N |
| trade-readiness-alias-profile | `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set` | 23941 | `2A16CEEC337981A925D933C95AD42526A61DDE7CA1EB583FDD597BCC83F2E250` | `36f46b384b45b3ff7593f4a7f82dad03e7ae24af` | money_ready | FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394 | false||false||0||0||N |
| source-manifest | `outputs/SOURCE_MANIFEST.md` | 4527 | `B1FDB15B0F2146CAA52EA6FDCA93D720D2BB0FC6146F581D11845488EEBCB0B2` | `7a0b42d21fcf3b21af00fddaa6ff196af2d110d0` |  |  |  |
| current-research-best | `outputs/CURRENT_RESEARCH_BEST_PROFILE.md` | 31801 | `39F3AB23C0EA9BA336F9A56FAD7996979CDECFF71F38E451918CB9F9441F4BA8` | `541e0fcecfa94a20dac948933ec7e44d9b3382a4` |  |  |  |

## Safety Notes

- These files preserve the real-account lock. They do not create a live profile.
- The conservative candidate remains pending compile, full validation, trade quality, Monte Carlo, forward/demo, and second-broker evidence.
- The exact EA source is large enough that connector text updates may be awkward; this package is the local source of truth for a normal git push or another exact file-upload path.
- The publication gate also requires the status manifest and current-research-best document so GitHub readers see the same hashes and warnings as the local workspace.
