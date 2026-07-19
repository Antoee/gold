# Independent M15 Overnight-Drift Structure V2 Compile Evidence

- Source SHA-256: `2E98481FBE42F58B61CB824652CA58FED62C0A005FD14EEB6C5B4110D4C56AE6`
- Worker 1 compile: `0 errors, 0 warnings`; compile-log SHA-256 `A0CDA3FE7C12471F6D1FF1BFF8CB1E3DB5EB46EA171C19A30DD9FB6BC164896E`
- Worker 3 compile: `0 errors, 0 warnings`; compile-log SHA-256 `47FBA9E8DC4921423EEFB5A888F6E659D1E4DFD145D60E4AEED21121F58CAF8F`
- Worker 1 executable SHA-256: `014CBAC91645B006F255D5F33CECA664CC6DEFB4015BA41467A8BA5904C89318`
- Worker 3 executable SHA-256: `9E246182FAF1CD1E16C1CBF88EB1E50057B5434FCA246C526F87E4C5DB228CF5`
- Discovery reports: `39 / 39` source-identity-valid, zero worker errors
- Static source contract: `PASS`

MT5 compilation is not bit-reproducible across independent compile times, so both executable identities are retained. Every accepted report has a sidecar identity file binding its source, configuration, executable, and report hashes.

The experiment is rejected in pre-2021 discovery. This evidence does not authorize holdout, Model 4, or live trading.
