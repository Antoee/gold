$ErrorActionPreference = "Stop"
Set-Location "C:\Users\Ant\Documents\Codex\2026-07-03\absolutely-here-s-a-summary-you"

$env:ALLOW_MT5_FOCUS_RISK = "1"
$env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"

powershell -NoProfile -ExecutionPolicy Bypass -File work\build_flat_session_impulse_strict_broad_package.ps1 `
   -PackageDir work\local_mt5_flat_session_impulse_strict_broad_fixedrisk_realtick_package `
   -Model 4

powershell -NoProfile -ExecutionPolicy Bypass -File work\build_tester_compact_ea_source.ps1 `
   -SourcePath outputs\Professional_XAUUSD_EA.mq5 `
   -ConfigDir work\local_mt5_flat_session_impulse_strict_broad_fixedrisk_realtick_package\configs `
   -OutSourcePath outputs\FLAT_SESSION_IMPULSE_STRICT_BROAD_FIXEDRISK_REALTICK_COMPACT_SOURCE.mq5 `
   -OutCsv outputs\FLAT_SESSION_IMPULSE_STRICT_BROAD_FIXEDRISK_REALTICK_COMPACT_SOURCE_AUDIT.csv

powershell -NoProfile -ExecutionPolicy Bypass -File work\compile_mt5_expert_hidden.ps1 `
   -SourcePath outputs\FLAT_SESSION_IMPULSE_STRICT_BROAD_FIXEDRISK_REALTICK_COMPACT_SOURCE.mq5 `
   -LogPath outputs\FLAT_SESSION_IMPULSE_STRICT_BROAD_FIXEDRISK_REALTICK_COMPACT_COMPILE.log

powershell -NoProfile -ExecutionPolicy Bypass -File work\run_external_mt5_validation_package_local.ps1 `
   -PackageDir work\local_mt5_flat_session_impulse_strict_broad_fixedrisk_realtick_package `
   -TimeoutMinutesPerConfig 18 `
   -OutCsv outputs\LOCAL_MT5_FLAT_SESSION_IMPULSE_STRICT_BROAD_FIXEDRISK_REALTICK_RUN.csv

$log = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\logs\20260710.log"
powershell -NoProfile -ExecutionPolicy Bypass -File work\collect_local_mt5_log_results.ps1 `
   -RunCsv outputs\LOCAL_MT5_FLAT_SESSION_IMPULSE_STRICT_BROAD_FIXEDRISK_REALTICK_RUN.csv `
   -ManifestPath outputs\FLAT_SESSION_IMPULSE_STRICT_BROAD_MANIFEST.csv `
   -TesterLogPath $log `
   -OutResults outputs\LOCAL_MT5_FLAT_SESSION_IMPULSE_STRICT_BROAD_FIXEDRISK_REALTICK_LOG_RESULTS.csv `
   -OutSummary outputs\LOCAL_MT5_FLAT_SESSION_IMPULSE_STRICT_BROAD_FIXEDRISK_REALTICK_LOG_SUMMARY.csv
