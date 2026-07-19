[CmdletBinding()]
param(
   [ValidateRange(1,3)][int]$Wave = 1,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,120)][int]$TimeoutMinutesPerConfig = 30,
   [switch]$UserAuthorizedFocusRisk
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk) { throw 'Controlled broad wave requires explicit focus/window-risk authorization.' }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$repoLock = Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock = Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$unlockFile = Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'
$focusAck = Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'
$manifest = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_GATE_MANIFEST.csv'
$source = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_broad_package\source\Professional_XAUUSD_EA.mq5'
$profile = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_broad_package\profiles\rdmc_tiered_momentum_v7.set'
$reportDir = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_broad_package\reports_here'
$decision = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_DECISION_FIXTURE.csv'
$runner = Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$collector = Join-Path $PSScriptRoot 'collect_rdmc_tiered_momentum_v7_results.ps1'
$evaluator = Join-Path $PSScriptRoot 'evaluate_rdmc_tiered_momentum_v7_broad.py'
$portableRoot = Join-Path $sharedWork 'mt5_portable_research'
$expectedManifestHash = '2FF02C9BFCA016AB43D059878B7CB16C118A859451B939F6A3D4CB8240E2F3AF'
$expectedSourceHash = '27CAD37CD903032335DA570CDEC75AC39C2EA6BEF04CA264D1586EDC866F6AF6'
$expectedProfileHash = '6E2EF7B031FF30216876E0232A8CE9D6BFC9F7913A863103DC9B12C1A04A100C'
$expectedBinaryHash = '28C2388BF3C4AF8746734619DDED89D23BABA5DB1D746FFC3FBBC9F6E4D0E65E'
$waveCounts = @{ 1=4; 2=2; 3=4 }

foreach($required in @($repoLock,$outerLock,$manifest,$source,$profile,$decision,$runner,$collector,$evaluator)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Controlled broad prerequisite missing: $required" }
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $focusAck) -or
   $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1') {
   throw 'Controlled broad wave refuses a pre-existing partial unlock state.'
}
if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) { throw 'Broad manifest identity changed.' }
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash) { throw 'Broad source identity changed.' }
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedProfileHash) { throw 'Broad profile identity changed.' }

$decisionRow = @(Import-Csv -LiteralPath $decision)
if($decisionRow.Count -ne 1 -or $decisionRow[0].Status -ne ('AWAITING_WAVE_{0:D2}_REPORTS' -f $Wave) -or
   [int]$decisionRow[0].CurrentWave -ne $Wave -or $decisionRow[0].TerminalRejection -ne 'False') {
   throw "Broad Wave $Wave is not in its exact admitted state."
}
$manifestRows = @(Import-Csv -LiteralPath $manifest | Sort-Object { [int]$_.QueueRank })
if($manifestRows.Count -ne 10 -or ($manifestRows.Wave -join ',') -ne '1,1,1,1,2,2,3,3,3,3') {
   throw 'Broad staged manifest shape changed.'
}
$waveRows = @($manifestRows | Where-Object Wave -eq ([string]$Wave) | Sort-Object { [int]$_.QueueRank })
if($waveRows.Count -ne $waveCounts[$Wave]) { throw "Broad Wave $Wave row count changed." }

$reportArtifacts = @(Get-ChildItem -LiteralPath $reportDir -File -ErrorAction SilentlyContinue |
   Where-Object { $_.Extension -in @('.html','.htm','.json') })
$admittedRows = @($manifestRows | Where-Object { [int]$_.Wave -le $Wave })
$allowedNames = @($admittedRows | ForEach-Object { $_.ExpectedReportName + '.htm'; $_.ExpectedReportName + '.identity.json' })
if(@($reportArtifacts | Where-Object Name -notin $allowedNames).Count -gt 0) { throw 'Broad report directory contains future or foreign evidence.' }
foreach($row in @($manifestRows | Where-Object { [int]$_.Wave -lt $Wave })) {
   if(!(Test-Path -LiteralPath (Join-Path $reportDir ($row.ExpectedReportName + '.htm'))) -or
      !(Test-Path -LiteralPath (Join-Path $reportDir ($row.ExpectedReportName + '.identity.json')))) {
      throw "Broad Wave $Wave is missing prior-wave evidence."
   }
}

$terminal = Join-Path $portableRoot 'terminal64.exe'
$binary = Join-Path $portableRoot 'MQL5\Experts\Professional_XAUUSD_EA.ex5'
if(!(Test-Path -LiteralPath $terminal) -or !(Test-Path -LiteralPath $binary)) { throw 'Primary portable worker is incomplete.' }
if((Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedBinaryHash) { throw 'Primary worker binary identity changed.' }
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled broad wave requires zero pre-existing MT5-family processes.'
}

$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$waveManifest = Join-Path $env:TEMP ('rdmc_tmv7b_wave_{0:D2}_{1}.csv' -f $Wave,[guid]::NewGuid().ToString('N'))
$workerPrefix = 'RDMC_TIERED_MOMENTUM_V7_BROAD_WAVE_{0:D2}_WORKER' -f $Wave
$runnerCompleted = $false
try {
   $waveRows | Export-Csv -LiteralPath $waveManifest -NoTypeInformation -Encoding ASCII
   Get-ChildItem -Path (Join-Path $repo ("outputs\{0}_*.csv" -f $workerPrefix)) -File -ErrorAction SilentlyContinue | Remove-Item -Force
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile, "Controlled broad Wave $Wave authorization at $startedAtUtc", [Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($focusAck, "Controlled broad Wave $Wave focus acknowledgement at $startedAtUtc", [Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK = '1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = '1'

   & $runner -ManifestPath $waveManifest -PortableRoots @($portableRoot) -UserAuthorizedFocusRisk `
      -OutputPrefix $workerPrefix -MaxCpuPercent $MaxCpuPercent -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -ExpectedPortableBinarySha256 $expectedBinaryHash
   & $collector -Wave $Wave -DecisionCsvPath 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_DECISION_FIXTURE.csv' `
      -ManifestPath 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_GATE_MANIFEST.csv' `
      -ReportDir 'outputs\rdmc_tiered_momentum_v7_broad_package\reports_here' `
      -RunnerLedgerGlob ("outputs\{0}_*.csv" -f $workerPrefix) `
      -ResultsPath 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_GATE_RESULTS.csv' `
      -RunAuditPath ("outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_WAVE_{0:D2}_RUN_AUDIT.csv" -f $Wave) `
      -RawResultsPath ("outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_WAVE_{0:D2}_RAW_RESULTS.csv" -f $Wave) `
      -SummaryPath ("outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_WAVE_{0:D2}_SUMMARY.csv" -f $Wave) `
      -MetricsMarkdownPath ("outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_WAVE_{0:D2}_METRICS.md" -f $Wave) `
      -ExpectedManifestHash $expectedManifestHash -ExpectedSourceHash $expectedSourceHash `
      -ExpectedProfileHash $expectedProfileHash -SkipAdmissionRefresh
   & python $evaluator
   if($LASTEXITCODE -ne 0) { throw "Broad Wave $Wave evaluator failed." }
   $runnerCompleted = $true
}
finally {
   Remove-Item -LiteralPath $waveManifest,$unlockFile,$focusAck -Force -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   [IO.File]::WriteAllBytes($repoLock,$repoLockBytes)
   [IO.File]::WriteAllBytes($outerLock,$outerLockBytes)
   Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue |
      Stop-Process -Force -ErrorAction SilentlyContinue
}

if(!$runnerCompleted) { throw "Controlled broad Wave $Wave runner did not complete." }
& python $evaluator
if($LASTEXITCODE -ne 0) { throw "Broad Wave $Wave post-lock evaluator failed." }
if(!(Test-Path -LiteralPath $repoLock) -or !(Test-Path -LiteralPath $outerLock) -or
   @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw "Controlled broad Wave $Wave did not restore the hard-lock state."
}

[pscustomobject][ordered]@{
   Status = 'CONTROLLED_BROAD_WAVE_{0:D2}_COMPLETE' -f $Wave
   Wave = $Wave
   StartedAtUtc = $startedAtUtc
   CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
   Reports = $waveRows.Count
   SourceSha256 = $expectedSourceHash
   ProfileSha256 = $expectedProfileHash
   PortableBinarySha256 = $expectedBinaryHash
   LaunchLocksRestored = $true
   MT5Processes = 0
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
