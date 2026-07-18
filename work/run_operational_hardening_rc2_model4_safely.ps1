param(
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [int]$TimeoutMinutes = 8
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$commonDir = Join-Path $env:APPDATA "MetaQuotes\Terminal\Common\Files"
$rvFile = "OPERATIONAL_HARDENING_RC2_RV_MODEL4_EVENTS.csv"
$moFile = "OPERATIONAL_HARDENING_RC2_MO_MODEL4_EVENTS.csv"

foreach($name in @($rvFile, $moFile)) {
   Remove-Item -LiteralPath (Join-Path $commonDir $name) -Force -ErrorAction SilentlyContinue
}

& (Join-Path $PSScriptRoot "run_single_profile_package_hidden_safely.ps1") `
   -ManifestPath "outputs\OPERATIONAL_HARDENING_RC2_MODEL4_PACKAGE_MANIFEST.csv" `
   -QueueManifestPath "outputs\OPERATIONAL_HARDENING_RC2_MODEL4_QUEUE.csv" `
   -OutStem "OPERATIONAL_HARDENING_RC2_MODEL4" `
   -InitialDeposit 10000 `
   -TimeoutMinutesPerConfig $TimeoutMinutes `
   -MaxCpuPercent $MaxCpuPercent `
   -SourcePath "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5" `
   -CompileLogPath "outputs\OPERATIONAL_HARDENING_RC2_MODEL4_COMPILE.log" `
   -CommonDiagnosticFile $rvFile `
   -DiagnosticOutputPath "outputs\OPERATIONAL_HARDENING_RC2_RV_MODEL4_EVENTS.csv" | Out-Null

$moCommon = Join-Path $commonDir $moFile
if(!(Test-Path -LiteralPath $moCommon -PathType Leaf)) { throw "MT5 did not produce momentum evidence: $moCommon" }
$moOutput = Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_MO_MODEL4_EVENTS.csv"
Copy-Item -LiteralPath $moCommon -Destination $moOutput -Force

[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath (Join-Path $repo "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5") -Algorithm SHA256).Hash
   ReversionEvidenceSha256 = (Get-FileHash -LiteralPath (Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_RV_MODEL4_EVENTS.csv") -Algorithm SHA256).Hash
   MomentumEvidenceSha256 = (Get-FileHash -LiteralPath $moOutput -Algorithm SHA256).Hash
}
