[CmdletBinding()]
param(
   [ValidateRange(1,2)][int]$Wave = 1,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,60)][int]$TimeoutMinutesPerConfig = 15,
   [switch]$UserAuthorizedFocusRisk
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if(!$UserAuthorizedFocusRisk) { throw 'Controlled breakout-retest wave requires explicit focus/window-risk authorization.' }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$repoLock = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'))
$outerLock = [IO.Path]::GetFullPath((Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'))
$unlockFile = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'))
$hiddenAckFile = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'))
$manifest = Join-Path $repo 'outputs\RDMC_MOMENTUM_BREAKOUT_RETEST_V5_GATE_MANIFEST.csv'
$source = Join-Path $repo 'outputs\rdmc_momentum_breakout_retest_v5_package\source\Professional_XAUUSD_EA.mq5'
$profile = Join-Path $repo 'outputs\rdmc_momentum_breakout_retest_v5_package\profiles\rdmc_momentum_breakout_retest_v5.set'
$reportDir = Join-Path $repo 'outputs\rdmc_momentum_breakout_retest_v5_package\reports_here'
$decision = Join-Path $repo 'outputs\RDMC_MOMENTUM_BREAKOUT_RETEST_V5_DECISION_FIXTURE.csv'
$runner = Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$collector = Join-Path $PSScriptRoot 'collect_rdmc_momentum_breakout_retest_v5_results.ps1'
$evaluator = Join-Path $PSScriptRoot 'evaluate_rdmc_momentum_breakout_retest_v5.py'
$availableRoots = @(
   (Join-Path $sharedWork 'mt5_portable_research'),
   (Join-Path $sharedWork 'mt5_portable_research_w2')
)
$expectedManifestHash = '7A0A35D6CA3E360C3F700D39DA3EFA92AE2283766E1D56F760BE4D4762D6A3BC'
$expectedSourceHash = '98578500821366CE7E89B0691BF47695733A492283E32FDC4B38CC5F216F974C'
$expectedProfileHash = '7DE7BEC73E5A4E34311D3ED0959F4E610B46AB8D6CC3E29D13B22AC34C1DAA2C'
$expectedBinaryHash = '448F7813869D7B1D4DE7EB4AA3A0BB5CEE99E81BF687E833EF097274F4982FF4'

foreach($required in @($repoLock,$outerLock,$manifest,$source,$profile,$decision,$runner,$collector,$evaluator)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Controlled breakout-retest prerequisite is missing: $required" }
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $hiddenAckFile) -or
   $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1') {
   throw 'Controlled breakout-retest wave refuses a pre-existing partial unlock state.'
}
if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) { throw 'Rewrite manifest identity changed.' }
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash) { throw 'Rewrite source identity changed.' }
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedProfileHash) { throw 'Rewrite profile identity changed.' }

$decisionRow = @(Import-Csv -LiteralPath $decision)
$expectedStatus = if($Wave -eq 1) { 'AWAITING_WAVE_01_REPORTS' } else { 'AWAITING_WAVE_02_REPORTS' }
$expectedPriorReports = if($Wave -eq 1) { 0 } else { 1 }
if($decisionRow.Count -ne 1 -or $decisionRow[0].Status -ne $expectedStatus -or
   [int]$decisionRow[0].CurrentWave -ne $Wave -or
   [int]$decisionRow[0].ReportsPresent -ne $expectedPriorReports -or
   $decisionRow[0].TerminalRejection -ne 'False') {
   throw "Breakout-retest Wave $Wave is not in its exact admitted state."
}
$manifestRows = @(Import-Csv -LiteralPath $manifest)
if($manifestRows.Count -ne 3 -or ($manifestRows.Window -join ',') -ne '2015_2018,2019,2022' -or
   ($manifestRows.Wave -join ',') -ne '1,2,2' -or
   @($manifestRows | Where-Object Model -ne '1').Count -gt 0) {
   throw 'Breakout-retest staged manifest shape changed.'
}
$waveRows = @($manifestRows | Where-Object Wave -eq ([string]$Wave) | Sort-Object { [int]$_.QueueRank })
$expectedWaveRows = if($Wave -eq 1) { 1 } else { 2 }
if($waveRows.Count -ne $expectedWaveRows) { throw "Breakout-retest Wave $Wave row count changed." }
$workerCount = [Math]::Min([int]$waveRows[0].MaxParallelism, $availableRoots.Count)
$roots = @($availableRoots | Select-Object -First $workerCount)

$reportArtifacts = @(Get-ChildItem -LiteralPath $reportDir -File -ErrorAction SilentlyContinue |
   Where-Object { $_.Extension -in @('.html','.htm','.json') })
$priorRows = @($manifestRows | Where-Object { [int]$_.Wave -lt $Wave } | Sort-Object { [int]$_.QueueRank })
$admittedRows = @($priorRows + $waveRows)
$allowedNames = @($admittedRows | ForEach-Object { $_.ExpectedReportName + '.htm'; $_.ExpectedReportName + '.identity.json' })
if(@($reportArtifacts | Where-Object Name -notin $allowedNames).Count -gt 0) {
   throw "Breakout-retest Wave $Wave report directory contains future or foreign evidence."
}
$artifactNames = @($reportArtifacts | Select-Object -ExpandProperty Name)
foreach($row in $priorRows) {
   if(($row.ExpectedReportName + '.htm') -notin $artifactNames -or
      ($row.ExpectedReportName + '.identity.json') -notin $artifactNames) {
      throw "Breakout-retest Wave $Wave is missing required prior-wave evidence."
   }
}
$seenGap = $false
foreach($row in $waveRows) {
   $hasReport = ($row.ExpectedReportName + '.htm') -in $artifactNames
   $hasIdentity = ($row.ExpectedReportName + '.identity.json') -in $artifactNames
   if($hasReport -ne $hasIdentity) { throw "Breakout-retest Wave $Wave has a partial report/identity pair." }
   if(!$hasReport) { $seenGap = $true }
   elseif($seenGap) { throw "Breakout-retest Wave $Wave resume evidence is not a leading prefix." }
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
   throw 'Controlled breakout-retest wave requires zero pre-existing MT5-family processes.'
}

$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$runnerCompleted = $false
$waveManifest = Join-Path $env:TEMP ('rdmc_mbr5_wave_{0:D2}_{1}.csv' -f $Wave,[guid]::NewGuid().ToString('N'))
$workerPrefix = 'RDMC_MOMENTUM_BREAKOUT_RETEST_V5_WAVE_{0:D2}_WORKER' -f $Wave
try {
   $waveRows | Export-Csv -LiteralPath $waveManifest -NoTypeInformation -Encoding ASCII
   Get-ChildItem -Path (Join-Path $repo ("outputs\{0}_*.csv" -f $workerPrefix)) -File -ErrorAction SilentlyContinue |
      Remove-Item -Force
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile, "Controlled breakout-retest Wave $Wave authorization at $startedAtUtc", [Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($hiddenAckFile, "Controlled breakout-retest Wave $Wave focus/window acknowledgement at $startedAtUtc", [Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK = '1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = '1'

   & $runner -ManifestPath $waveManifest -PortableRoots $roots -UserAuthorizedFocusRisk `
      -OutputPrefix $workerPrefix -MaxCpuPercent $MaxCpuPercent `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig -ExpectedPortableBinarySha256 $expectedBinaryHash
   & $collector -Wave $Wave -DecisionCsvPath $decision -ManifestPath $manifest -ReportDir $reportDir `
      -RunnerLedgerGlob ("outputs\{0}_*.csv" -f $workerPrefix) `
      -ResultsPath 'outputs\RDMC_MOMENTUM_BREAKOUT_RETEST_V5_GATE_RESULTS.csv' -SkipAdmissionRefresh
   & python $evaluator
   if($LASTEXITCODE -ne 0) { throw 'Rewrite Wave 1 evaluator failed.' }
   $runnerCompleted = $true
}
finally {
   Remove-Item -LiteralPath $waveManifest -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath $unlockFile,$hiddenAckFile -Force -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   [IO.File]::WriteAllBytes($repoLock,$repoLockBytes)
   [IO.File]::WriteAllBytes($outerLock,$outerLockBytes)
   Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue |
      Stop-Process -Force -ErrorAction SilentlyContinue
}

if(!$runnerCompleted) { throw "Controlled breakout-retest Wave $Wave runner did not complete." }
if(!(Test-Path -LiteralPath $repoLock -PathType Leaf) -or !(Test-Path -LiteralPath $outerLock -PathType Leaf)) {
   throw "Controlled breakout-retest Wave $Wave did not restore both launch locks."
}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw "Controlled breakout-retest Wave $Wave left an MT5-family process running."
}

[pscustomobject][ordered]@{
   Status = 'CONTROLLED_BREAKOUT_RETEST_WAVE_{0:D2}_COMPLETE' -f $Wave
   Wave = $Wave
   StartedAtUtc = $startedAtUtc
   CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
   Reports = $waveRows.Count
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
