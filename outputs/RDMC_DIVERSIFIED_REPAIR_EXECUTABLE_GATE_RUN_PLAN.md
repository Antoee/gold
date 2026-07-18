# RDMC Diversified Repair Executable Gate Run Plan

- Status: **LOCKED**
- Admitted wave: `1`
- Rows: `2`
- Available workers: `2` of `2` allowed
- CPU ceiling per worker: `80%`
- Shared binary status: `LOCKED_COMPILE_ONCE_REQUIRED`
- Shared binary action: `COMPILE_ON_LEADER_AND_DISTRIBUTE`
- Repository hard lock: `True`
- Outer workspace hard lock: `True`
- Action: `WAIT_FOR_DELIBERATE_LOCK_REVIEW`

Plan mode never launches MT5. Run mode requires explicit focus-risk authorization, both hard locks absent, both unlock acknowledgements, and the launch-guard environment flags. Only the currently admitted wave manifest is passed to the generic parallel runner.

Before workers start, run mode compiles the exact candidate once on one allowlisted leader and distributes that byte-identical source, EX5, and identity file to every portable root. Workers receive the prepared binary hash and are prohibited from recompiling independently.

Interrupted work is resumable only through identity sidecars generated after a complete terminal exit. A cached report without matching report, config, source, and compiled-binary hashes is ignored and rerun.
