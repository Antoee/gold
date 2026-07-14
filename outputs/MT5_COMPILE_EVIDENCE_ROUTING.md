# MT5 Compile Evidence Routing

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Inbox: `outputs\returned_mt5_reports\compile_inbox`
- Routed evidence files: `0`
- Missing evidence files: `2`
- Duplicate evidence files: `0`
- Invalid evidence files: `0`
- Imported compile status: `0`
- Import warnings: `0`
- Import failures: `0`
- Waiting rows: `1`
- Stale existing compile status rows: `1`
- Ready for live-readiness compile gate: `False`

Compile evidence is not complete or not clean. Return one valid compile log and the exact compiled .mq5 source copy, then rerun this router.

## Routing Rows

| Evidence | Status | Source | Destination | Accepted Names | Action |
| --- | --- | --- | --- | --- | --- |
| compile_log | MISSING_IN_INBOX |  | outputs\returned_mt5_reports\compile_evidence\MT5_COMPILE_CURRENT.log | MT5_COMPILE_CURRENT; compile_current_mt5; Professional_XAUUSD_EA_compile | Drop one MetaEditor compile log into the compile inbox. |
| compiled_source | MISSING_IN_INBOX |  | outputs\returned_mt5_reports\compile_evidence\Professional_XAUUSD_EA_COMPILED.mq5 | Professional_XAUUSD_EA; MT5_COMPILE_SOURCE; Professional_XAUUSD_EA_COMPILED | Drop the exact .mq5 source copy that was compiled into the compile inbox. |
| compile_import | WAITING_FOR_EVIDENCE |  | outputs\MT5_COMPILE_STATUS.csv | compile_log + compiled_source | Compile log and matching compiled source are required before importing compile status. |
| existing_compile_status | STALE_FOR_CURRENT_SOURCE | outputs\MT5_COMPILE_STATUS.csv | outputs\MT5_COMPILE_STATUS.csv | current source hash | status=PASS; hashStatus=MATCH; statusSource=46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E; statusExpected=46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E; currentExpected=5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412 |
