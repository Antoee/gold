# RDMC Executable Gate Report Integrity

Status: **IMPLEMENTED OFFLINE / MT5 LOCKED / ZERO NEW REPORTS**

This control protects the staged executable gate from partial, stale, ambiguous, or weakly cached MT5 reports. It changes execution plumbing only; source, profile, signals, risk settings, registered forward evidence, and gate admission remain unchanged.

## Fresh Completion

- The direct portable runner accepts only a leaf report name.
- Every matching `.htm`, `.html`, or `.xml` file under the admitted portable root is removed before launch.
- The runner waits for the configured terminal process to exit cleanly. A report appearing early no longer causes the terminal to be killed.
- Timeout is a failure even if a partial report exists.
- After exit, exactly one matching report must exist. It must be non-empty, created during the current run, and stable across a second size/timestamp read.
- Portable processes are stopped in a `finally` block on both success and failure.

## Safe Resume

Each freshly copied package report receives an adjacent `.identity.json` sidecar containing:

- schema version;
- expected report name;
- config SHA-256;
- source SHA-256;
- compiled binary SHA-256;
- report SHA-256 and byte count;
- UTC creation time.

A worker reuses a completed row only when the sidecar, report bytes, embedded source identity, config identity, and source identity all match. Missing, malformed, stale, or changed evidence is rerun.

## Admission

The staged collector independently verifies the runner's report hash, exact sidecar location, all sidecar fields, embedded source identity, and shared compiled-binary identity before metrics enter the canonical result set. The canonical row records whether evidence was freshly generated or resumed.

## Offline Verification

- Report identity helper: valid round-trip passes; altered report, wrong config, wrong source, and incomplete sidecar are rejected.
- Direct worker/config lock test: both paths reject the hard lock and launch no MT5-family process.
- Synthetic collector: two identity-bound reports parse; tampered config and altered report evidence are rejected.

These checks improve execution efficiency and evidence quality. They do not establish profitability, compile the EA, remove either launch lock, or make the bot money-ready.
