[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,60)][int]$TimeoutMinutesPerConfig = 15,
   [switch]$UserAuthorizedFocusRisk
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if(!$UserAuthorizedFocusRisk) { throw 'Controlled rewrite Wave 1 requires explicit focus/window-risk authorization.' }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$repoLock = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'))
$outerLock = [IO.Path]::GetFullPath((Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'))
$unlockFile = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'))
$hiddenAckFile = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'))
$manifest = Join-Path $repo 'outputs\RDMC_LANE_ISOLATION_REWRITE_V2_WAVE_01_MANIFEST.csv'
$source = Join-Path $repo 'outputs\rdmc_lane_isolation_rewrite_v2_package\source\Professional_XAUUSD_EA.mq5'
$profile = Join-Path $repo 'outputs\rdmc_lane_isolation_rewrite_v2_package\profiles\rdmc_lane_isolation_rewrite_v2.set'
$reportDir = Join-Path $repo 'outputs\rdmc_lane_isolation_rewrite_v2_package\reports_here'
$decision = Join-Path $repo 'outputs\RDMC_LANE_ISOLATION_REWRITE_V2_DECISION_FIXTURE.csv'
$runner = Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$collector = Join-Path $PSScriptRoot 'collect_rdmc_lane_isolation_rewrite_v2_results.ps1'
$evaluator = Join-Path $PSScriptRoot 'evaluate_rdmc_lane_isolation_rewrite_v2.py'
$roots = @((Join-Path $sharedWork 'mt5_portable_research'))
$expectedManifestHash = '24F5B32D6F12740E763DC3BA4B14F0BBA5E892381D46EE33190C4C0F320756F7'
$expectedSourceHash = '1376E383DBB4A040DBC14337EA736DBFA4417C3B5D36DD629205665B9B81E569'
$expectedProfileHash = '6C01552D24702869C9E950846D96A74469E958B08E5D176FA34792D44D9224F0'
$expectedBinaryHash = '818A94C0CAEF9A9C438297134CD15B97DD3FCEAEAA9367C756A2A8C34A2A1868'

foreach($required in @($repoLock,$outerLock,$manifest,$source,$profile,$decision,$runner,$collector,$evaluator)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Controlled rewrite Wave 1 prerequisite is missing: $required" }
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $hiddenAckFile) -or
   $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1') {
   throw 'Controlled rewrite Wave 1 refuses a pre-existing partial unlock state.'
}
if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) { throw 'Rewrite manifest identity changed.' }
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash) { throw 'Rewrite source identity changed.' }
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedProfileHash) { throw 'Rewrite profile identity changed.' }

$decisionRow = @(Import-Csv -LiteralPath $decision)
if($decisionRow.Count -ne 1 -or $decisionRow[0].Status -ne 'AWAITING_WAVE_01_REPORTS' -or
   $decisionRow[0].ReportsPresent -ne '0' -or $decisionRow[0].TerminalRejection -ne 'False') {
   throw 'Rewrite Wave 1 is not in the pristine pending state.'
}
$manifestRows = @(Import-Csv -LiteralPath $manifest)
if($manifestRows.Count -ne 2 -or @($manifestRows | Where-Object { $_.Wave -ne '1' -or $_.Model -ne '1' }).Count -gt 0) {
   throw 'Rewrite Wave 1 no longer has exactly two frozen Model 1 rows.'
}
$reportArtifacts = @(Get-ChildItem -LiteralPath $reportDir -File -ErrorAction SilentlyContinue |
   Where-Object { $_.Extension -in @('.html','.htm','.json') })
$allowedResumeNames = @(
   'rdmc_lir2_w01_m1_critical_2019.htm',
   'rdmc_lir2_w01_m1_critical_2019.identity.json'
)
if($reportArtifacts.Count -notin @(0,2) -or
   @($reportArtifacts | Where-Object Name -notin $allowedResumeNames).Count -gt 0) {
   throw 'Rewrite Wave 1 report directory is neither pristine nor the exact resumable 2019 evidence state.'
}
foreach($root in $roots) {
   $terminal = Join-Path $root 'terminal64.exe'
   $binary = Join-Path $root 'MQL5\Experts\Professional_XAUUSD_EA.ex5'
   if(!(Test-Path -LiteralPath $terminal -PathType Leaf) -or !(Test-Path -LiteralPath $binary -PathType Leaf)) {
      throw "Portable worker is incomplete: $root"
   }
   if((Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedBinaryHash) {
      throw "Portable worker binary identity changed: $root"
   }
}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled rewrite Wave 1 requires zero pre-existing MT5-family processes.'
}

$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$runnerCompleted = $false
try {
   Get-ChildItem -Path (Join-Path $repo 'outputs\RDMC_LANE_ISOLATION_REWRITE_V2_WAVE_01_WORKER_*.csv') -File -ErrorAction SilentlyContinue |
      Remove-Item -Force
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile, "Controlled rewrite Wave 1 authorization at $startedAtUtc", [Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($hiddenAckFile, "Controlled rewrite Wave 1 focus/window acknowledgement at $startedAtUtc", [Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK = '1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = '1'

   & $runner -ManifestPath $manifest -PortableRoots $roots -UserAuthorizedFocusRisk `
      -OutputPrefix 'RDMC_LANE_ISOLATION_REWRITE_V2_WAVE_01_WORKER' -MaxCpuPercent $MaxCpuPercent `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig -ExpectedPortableBinarySha256 $expectedBinaryHash
   & $collector -Wave 1 -DecisionCsvPath $decision -ManifestPath $manifest -ReportDir $reportDir `
      -RunnerLedgerGlob 'outputs\RDMC_LANE_ISOLATION_REWRITE_V2_WAVE_01_WORKER_*.csv' `
      -ResultsPath 'outputs\RDMC_LANE_ISOLATION_REWRITE_V2_WAVE_01_RESULTS.csv' -SkipAdmissionRefresh
   & python $evaluator
   if($LASTEXITCODE -ne 0) { throw 'Rewrite Wave 1 evaluator failed.' }
   $runnerCompleted = $true
}
finally {
   Remove-Item -LiteralPath $unlockFile,$hiddenAckFile -Force -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   [IO.File]::WriteAllBytes($repoLock,$repoLockBytes)
   [IO.File]::WriteAllBytes($outerLock,$outerLockBytes)
   Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue |
      Stop-Process -Force -ErrorAction SilentlyContinue
}

if(!$runnerCompleted) { throw 'Controlled rewrite Wave 1 runner did not complete.' }
if(!(Test-Path -LiteralPath $repoLock -PathType Leaf) -or !(Test-Path -LiteralPath $outerLock -PathType Leaf)) {
   throw 'Controlled rewrite Wave 1 did not restore both launch locks.'
}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled rewrite Wave 1 left an MT5-family process running.'
}

[pscustomobject][ordered]@{
   Status = 'CONTROLLED_REWRITE_WAVE_01_COMPLETE'
   StartedAtUtc = $startedAtUtc
   CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
   Reports = 2
   MaxCpuPercent = $MaxCpuPercent
   TimeoutMinutesPerConfig = $TimeoutMinutesPerConfig
   SourceSha256 = $expectedSourceHash
   ProfileSha256 = $expectedProfileHash
   PortableBinarySha256 = $expectedBinaryHash
   LaunchLocksRestored = $true
   MT5Processes = 0
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
