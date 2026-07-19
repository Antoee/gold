# Independent M15 Overnight-Drift Continuation Compile Evidence

- Source SHA-256: `B74E61CC7B473C03FCA79E1D8DC0C73C4512FCCF9596E439971E1D7C82149684`
- Worker 1 compile: `0 errors, 0 warnings`; compile-log SHA-256 `EA7A51F6937DE1D604A5E2FC8FA261FDEE859B4427B151C40C8E88FD143FAF8E`
- Worker 3 compile: `0 errors, 0 warnings`; compile-log SHA-256 `49BC5EB9CD922A8FE62C3B295B95F982D42B655B882C6AE7CC41E84AF0F05045`
- Worker 1 executable SHA-256: `5518A5686754C3486B6034DF62BC5249932F9704333B2C52E30117723BF83118`
- Worker 3 executable SHA-256: `800611E60DBEB51715314C97C7D9A84077708328059927C3FBB90E7D4601B3C2`
- Discovery reports: `45 / 45` source-identity-valid, zero worker errors
- Holdout reports: `12 / 12` source-identity-valid, zero worker errors
- Static source contract: `PASS`

MT5 compilation is not bit-reproducible across independent compile times, so both executable identities are retained. Every accepted report has a sidecar identity file binding its source, configuration, executable, and report hashes.

The experiment is rejected by the post-2020 holdout. This evidence does not authorize Model 4 escalation or live trading.
