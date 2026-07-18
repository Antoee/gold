Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$hardLock = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$unlock = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenAck = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"
$worker = Join-Path $PSScriptRoot "run_mt5_portable_package_worker.ps1"
$launcher = Join-Path $PSScriptRoot "run_mt5_portable_config_hidden.ps1"

if(!(Test-Path -LiteralPath $hardLock -PathType Leaf)) { throw "MT5 hard lock is missing." }
Remove-Item -LiteralPath $unlock,$hiddenAck -Force -ErrorAction SilentlyContinue
$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

$workerBlocked = $false
try {
   & $worker -ManifestPath "missing.csv" -PortableRoot "missing" -WorkerIndex 1 -WorkerCount 1 `
      -UserAuthorizedFocusRisk | Out-Null
}
catch {
   $workerBlocked = $_.Exception.Message -match "hard-locked"
}

$launcherBlocked = $false
try {
   & $launcher -PortableRoot "missing" -ConfigPath "missing.ini" -UserAuthorizedFocusRisk | Out-Null
}
catch {
   $launcherBlocked = $_.Exception.Message -match "hard-locked"
}

$after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if(!$workerBlocked) { throw "Direct portable worker did not honor the MT5 hard lock." }
if(!$launcherBlocked) { throw "Direct portable config launcher did not honor the MT5 hard lock." }
if($after.Count -gt $before.Count) { throw "A direct portable runner created an MT5-family process while locked." }

$workerText = Get-Content -LiteralPath $worker -Raw
$launcherText = Get-Content -LiteralPath $launcher -Raw
if($workerText -notmatch 'assert_mt5_launch_allowed\.ps1') { throw "Worker launch guard is missing." }
if($launcherText -notmatch 'assert_mt5_launch_allowed\.ps1') { throw "Config launcher guard is missing." }
$guardText = Get-Content -LiteralPath (Join-Path $PSScriptRoot "assert_mt5_launch_allowed.ps1") -Raw
if($guardText -notmatch 'outerHardLockFile' -or $guardText -notmatch 'Split-Path -Parent \$repoRoot') { throw "Shared guard does not enforce the outer workspace hard lock." }
foreach($token in @("ConfigSha256", "SourceSha256", "PackageConfigSha256", "Package source identity mismatch")) {
   if($workerText -notmatch [regex]::Escape($token)) { throw "Worker identity attestation is missing: $token" }
}
foreach($token in @("mt5_report_identity_helpers.ps1", "Read-MT5ReportIdentityEvidence", "Write-MT5ReportIdentityEvidence", "ReportSha256", "ReportIdentityReused")) {
   if($workerText -notmatch [regex]::Escape($token)) { throw "Worker resumable report identity is missing: $token" }
}
foreach($token in @("sharedResearchPortable", "mt5_portable_research", "portableParent.Equals")) {
   if($launcherText -notmatch [regex]::Escape($token)) { throw "Shared portable allowlist is missing: $token" }
}
foreach($token in @("ExpectedPortableBinarySha256", "independent worker compilation is prohibited")) {
   if($launcherText -notmatch [regex]::Escape($token)) { throw "Direct launcher shared-binary enforcement is missing: $token" }
}
foreach($token in @("ExpectedPortableBinarySha256", "differs from the prepared shared binary")) {
   if($workerText -notmatch [regex]::Escape($token)) { throw "Worker shared-binary enforcement is missing: $token" }
}
foreach($token in @("Get-MatchingPortableReports", "LastWriteTimeUtc", "did not exit cleanly", "ambiguous report set", "still changing after terminal exit")) {
   if($launcherText -notmatch [regex]::Escape($token)) { throw "Fresh completed-report enforcement is missing: $token" }
}

[pscustomobject]@{
   Status = "PASS"
   WorkerHardLockRejected = $workerBlocked
   LauncherHardLockRejected = $launcherBlocked
   MQL5Launched = $false
}
