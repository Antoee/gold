# MT5 Portable Shared Expert Plan

- Status: **SHARED_BINARY_READY**
- Action: `REUSE_EXACT_SHARED_BINARY`
- Expected source SHA-256: `A300713711328CE221447E452B889C0A2F9E449E2BF721BE7E49E0A354A4C416`
- Portable roots: `4`
- Runtime failures: `0`
- Exact-source identities ready: `4`
- Unique ready binary identities: `1`
- Current installed source identities: `1`
- Current installed binary identities: `1`
- Repository or outer launch lock present: `True`

Plan mode is read-only and never launches MetaEditor or MT5. Run mode compiles once on the first allowlisted portable root, then distributes the same source, EX5, and identity file to every worker before parallel testing.
