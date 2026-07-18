# RDMC Diversified Repair Executable Gate Run Plan

- Status: **LOCKED**
- Admitted wave: `1`
- Rows: `2`
- Available workers: `2` of `2` allowed
- CPU ceiling per worker: `80%`
- Repository hard lock: `True`
- Outer workspace hard lock: `True`
- Action: `WAIT_FOR_DELIBERATE_LOCK_REVIEW`

Plan mode never launches MT5. Run mode requires explicit focus-risk authorization, both hard locks absent, both unlock acknowledgements, and the launch-guard environment flags. Only the currently admitted wave manifest is passed to the generic parallel runner.

Interrupted work is resumable only through identity sidecars generated after a complete terminal exit. A cached report without matching report, config, source, and compiled-binary hashes is ignored and rerun.
