# MT5 Portable Shared Expert Plan

- Status: **LOCKED_COMPILE_ONCE_REQUIRED**
- Action: `COMPILE_ON_LEADER_AND_DISTRIBUTE`
- Expected source SHA-256: `EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F`
- Portable roots: `4`
- Runtime failures: `0`
- Exact-source identities ready: `0`
- Unique ready binary identities: `0`
- Current installed source identities: `1`
- Current installed binary identities: `4`
- Repository or outer launch lock present: `True`

Plan mode is read-only and never launches MetaEditor or MT5. Run mode compiles once on the first allowlisted portable root, then distributes the same source, EX5, and identity file to every worker before parallel testing.
