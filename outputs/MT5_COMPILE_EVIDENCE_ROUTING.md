# MT5 Compile Evidence Routing

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Inbox: `outputs\returned_mt5_reports\compile_inbox`
- Routed evidence files: `2`
- Missing evidence files: `0`
- Duplicate evidence files: `0`
- Invalid evidence files: `0`
- Imported compile status: `1`
- Import warnings: `0`
- Import failures: `0`
- Waiting rows: `0`
- Stale existing compile status rows: `0`
- Ready for live-readiness compile gate: `True`

Compile evidence imported cleanly. Run work\refresh_money_ready_status.ps1 to refresh live-readiness.

## Routing Rows

| Evidence | Status | Source | Destination | Accepted Names | Action |
| --- | --- | --- | --- | --- | --- |
| compile_log | ROUTED | outputs\returned_mt5_reports\compile_inbox\MT5_COMPILE_CURRENT.log | outputs\returned_mt5_reports\compile_evidence\MT5_COMPILE_CURRENT.log | MT5_COMPILE_CURRENT; compile_current_mt5; Professional_XAUUSD_EA_compile | Copied compile log to canonical evidence path. |
| compiled_source | ROUTED | outputs\returned_mt5_reports\compile_inbox\Professional_XAUUSD_EA_COMPILED.mq5 | outputs\returned_mt5_reports\compile_evidence\Professional_XAUUSD_EA_COMPILED.mq5 | Professional_XAUUSD_EA; MT5_COMPILE_SOURCE; Professional_XAUUSD_EA_COMPILED | Copied compiled source copy to canonical evidence path. |
| compile_import | IMPORTED_PASS | outputs\returned_mt5_reports\compile_evidence\MT5_COMPILE_CURRENT.log | outputs\MT5_COMPILE_STATUS.csv | import_mt5_compile_log.ps1 | status=PASS; hashStatus=MATCH; errors=0; warnings=0; exitCode=0 |
| existing_compile_status | CURRENT_SOURCE_STATUS | outputs\MT5_COMPILE_STATUS.csv | outputs\MT5_COMPILE_STATUS.csv | current source hash | status=PASS; sourceHash=A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622 |
