# MT5 Portable Shared Expert Plan

- Status: **SHARED_BINARY_READY**
- Action: `REUSE_EXACT_SHARED_BINARY`
- Expected source SHA-256: `B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E`
- Portable roots: `4`
- Runtime failures: `0`
- Exact-source identities ready: `4`
- Unique ready binary identities: `1`
- Current installed source identities: `1`
- Current installed binary identities: `1`
- Repository or outer launch lock present: `True`

Plan mode is read-only and never launches MetaEditor or MT5. Run mode compiles once on the first allowlisted portable root, then distributes the same source, EX5, and identity file to every worker before parallel testing.
