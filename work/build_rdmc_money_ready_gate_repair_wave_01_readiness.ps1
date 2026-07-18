[CmdletBinding()]
param(
   [string]$SourcePath = 'outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5',
   [string]$ProfilePath = 'outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_v1.set',
   [string]$ManifestPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_MANIFEST.csv',
   [string]$WaveManifestPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_01_MANIFEST.csv',
   [string[]]$WorkerNames = @('mt5_portable_research','mt5_portable_research_w2'),
   [string]$StatusCsvPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_WAVE_01_READINESS.csv',
   [string]$WorkersCsvPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_WAVE_01_WORKERS.csv',
   [string]$StatusMarkdownPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_WAVE_01_READINESS.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$expectedSourceHash = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
$expectedProfileHash = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
$expectedManifestHash = 'EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972'

function Resolve-InputPath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
   return [IO.Path]::GetFullPath((Join-Path $repo ($Path -replace '/', '\')))
}

function Get-OptionalHash {
   param([Parameter(Mandatory=$true)][string]$Path)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return 'MISSING' }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function ConvertTo-BoolStrict {
   param([object]$Value)
   return ([string]$Value).Trim().ToLowerInvariant() -eq 'true'
}

function Add-Gate {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Gate,
      [bool]$Ready,
      [string]$RequiredFor,
      [string]$Evidence
   )
   $Rows.Add([pscustomobject]@{Gate=$Gate;Ready=$Ready;RequiredFor=$RequiredFor;Evidence=$Evidence}) | Out-Null
}

$source = Resolve-InputPath $SourcePath
$profile = Resolve-InputPath $ProfilePath
$manifest = Resolve-InputPath $ManifestPath
$waveManifest = Resolve-InputPath $WaveManifestPath
$statusCsv = Resolve-InputPath $StatusCsvPath
$workersCsv = Resolve-InputPath $WorkersCsvPath
$statusMarkdown = Resolve-InputPath $StatusMarkdownPath
foreach($output in @($statusCsv,$workersCsv,$statusMarkdown)) {
   $parent = Split-Path -Parent $output
   if($parent -and !(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
}

$sourceHash = Get-OptionalHash $source
$profileHash = Get-OptionalHash $profile
$manifestHash = Get-OptionalHash $manifest
$profileInputCount = if(Test-Path -LiteralPath $profile -PathType Leaf) { (Import-SetInputs -Path $profile).Keys.Count } else { 0 }
$manifestRows = @()
if(Test-Path -LiteralPath $manifest -PathType Leaf) { $manifestRows = @(Import-Csv -LiteralPath $manifest) }
$waveRows = @()
if(Test-Path -LiteralPath $waveManifest -PathType Leaf) { $waveRows = @(Import-Csv -LiteralPath $waveManifest | Sort-Object { [int]$_.QueueRank }) }
$canonicalWaveRows = @($manifestRows | Where-Object Wave -eq '1' | Sort-Object { [int]$_.QueueRank })

$waveIdentityReady = $waveRows.Count -eq 2 -and $canonicalWaveRows.Count -eq 2
if($waveIdentityReady) {
   $fields = @('QueueRank','Wave','Window','From','To','Model','Deposit','InitialDeposit','PackageConfig','ExpectedReportName','ConfigSha256','SourceSha256','ProfileSha256')
   for($index=0; $index -lt 2; $index++) {
      foreach($field in $fields) {
         if([string]$waveRows[$index].$field -ne [string]$canonicalWaveRows[$index].$field) { $waveIdentityReady = $false }
      }
   }
}
$waveContractReady = $waveIdentityReady -and ($waveRows.Window -join ',') -eq '2019,2022' -and
   @($waveRows | Where-Object { $_.Model -ne '1' -or $_.Deposit -ne '10000' -or $_.InitialDeposit -ne '10000' }).Count -eq 0
$configIdentityReady = $waveRows.Count -eq 2
foreach($row in $waveRows) {
   $config = Resolve-InputPath ([string]$row.PackageConfig)
   if((Get-OptionalHash $config) -ne [string]$row.ConfigSha256) { $configIdentityReady = $false }
}

if($WorkerNames.Count -ne 2 -or @($WorkerNames | Sort-Object -Unique).Count -ne 2) { throw 'Wave 1 readiness requires exactly two unique worker names.' }
$workerRows = [System.Collections.Generic.List[object]]::new()
foreach($name in $WorkerNames) {
   if($name -notmatch '^mt5_portable_research(?:_w\d+)?$') { throw "Worker name is outside the portable allowlist: $name" }
   $root = [IO.Path]::GetFullPath((Join-Path $sharedWork $name))
   if((Split-Path -Parent $root) -ne $sharedWork) { throw "Worker path escaped the shared workspace: $name" }
   $terminal = Join-Path $root 'terminal64.exe'
   $editor = Join-Path $root 'MetaEditor64.exe'
   $installedSource = Join-Path $root 'MQL5\Experts\Professional_XAUUSD_EA.mq5'
   $installedBinary = Join-Path $root 'MQL5\Experts\Professional_XAUUSD_EA.ex5'
   $identityFile = Join-Path $root 'MQL5\Experts\Professional_XAUUSD_EA.compiled_identity.txt'
   $identityLines = @()
   if(Test-Path -LiteralPath $identityFile -PathType Leaf) { $identityLines = @(Get-Content -LiteralPath $identityFile) }
   $installedSourceHash = Get-OptionalHash $installedSource
   $binaryHash = Get-OptionalHash $installedBinary
   $identitySourceHash = if($identityLines.Count -ge 1) { ([string]$identityLines[0]).ToUpperInvariant() } else { 'MISSING' }
   $identityBinaryHash = if($identityLines.Count -ge 2) { ([string]$identityLines[1]).ToUpperInvariant() } else { 'MISSING' }
   $historyDirectory = Join-Path $root 'bases\MetaQuotes-Demo\history\XAUUSD'
   $tickDirectory = Join-Path $root 'bases\MetaQuotes-Demo\ticks\XAUUSD'
   $history2019 = Join-Path $historyDirectory '2019.hcc'
   $history2022 = Join-Path $historyDirectory '2022.hcc'
   $ticks2019 = if(Test-Path -LiteralPath $tickDirectory -PathType Container) { @(Get-ChildItem -LiteralPath $tickDirectory -File -Filter '2019??.tkc').Count } else { 0 }
   $ticks2022 = if(Test-Path -LiteralPath $tickDirectory -PathType Container) { @(Get-ChildItem -LiteralPath $tickDirectory -File -Filter '2022??.tkc').Count } else { 0 }
   $runtimeReady = (Test-Path -LiteralPath $terminal -PathType Leaf) -and (Test-Path -LiteralPath $editor -PathType Leaf)
   $identityReady = $runtimeReady -and $installedSourceHash -eq $expectedSourceHash -and $binaryHash -ne 'MISSING' -and
      $identitySourceHash -eq $expectedSourceHash -and $identityBinaryHash -eq $binaryHash
   $workerRows.Add([pscustomobject][ordered]@{
      Worker = $name
      RuntimeReady = $runtimeReady
      TerminalVersion = if(Test-Path -LiteralPath $terminal -PathType Leaf) { (Get-Item -LiteralPath $terminal).VersionInfo.FileVersion } else { 'MISSING' }
      EditorVersion = if(Test-Path -LiteralPath $editor -PathType Leaf) { (Get-Item -LiteralPath $editor).VersionInfo.FileVersion } else { 'MISSING' }
      InstalledSourceSha256 = $installedSourceHash
      ExactSourceReady = $installedSourceHash -eq $expectedSourceHash
      BinarySha256 = $binaryHash
      CompiledIdentityReady = $identityReady
      History2019Sha256 = Get-OptionalHash $history2019
      History2022Sha256 = Get-OptionalHash $history2022
      TickMonths2019 = $ticks2019
      TickMonths2022 = $ticks2022
   }) | Out-Null
}

$runtimeReady = @($workerRows | Where-Object { !$_.RuntimeReady }).Count -eq 0
$runtimeVersions = @($workerRows | Select-Object -ExpandProperty TerminalVersion -Unique)
$editorVersions = @($workerRows | Select-Object -ExpandProperty EditorVersion -Unique)
$runtimeBuildReady = $runtimeReady -and $runtimeVersions.Count -eq 1 -and $editorVersions.Count -eq 1 -and $runtimeVersions[0] -eq $editorVersions[0]
$history2019Hashes = @($workerRows | Select-Object -ExpandProperty History2019Sha256 -Unique)
$history2022Hashes = @($workerRows | Select-Object -ExpandProperty History2022Sha256 -Unique)
$history2019Ready = $history2019Hashes.Count -eq 1 -and $history2019Hashes[0] -ne 'MISSING'
$history2022Ready = $history2022Hashes.Count -eq 1 -and $history2022Hashes[0] -ne 'MISSING'
$model4Ticks2019Ready = @($workerRows | Where-Object TickMonths2019 -ne 12).Count -eq 0
$model4Ticks2022Ready = @($workerRows | Where-Object TickMonths2022 -ne 12).Count -eq 0
$readyBinaries = @($workerRows | Where-Object CompiledIdentityReady)
$stagedSourceReady = @($workerRows | Where-Object ExactSourceReady).Count -eq 2
$readyBinaryHashes = @($readyBinaries | Select-Object -ExpandProperty BinarySha256 -Unique)
$sharedBinaryReady = $readyBinaries.Count -eq 2 -and $readyBinaryHashes.Count -eq 1
$currentSourceIdentities = @($workerRows | Where-Object InstalledSourceSha256 -ne 'MISSING' | Select-Object -ExpandProperty InstalledSourceSha256 -Unique)
$currentBinaryIdentities = @($workerRows | Where-Object BinarySha256 -ne 'MISSING' | Select-Object -ExpandProperty BinarySha256 -Unique)

$reportDirectory = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_executable_package\reports_here'
$reportArtifacts = @()
if(Test-Path -LiteralPath $reportDirectory -PathType Container) { $reportArtifacts = @(Get-ChildItem -LiteralPath $reportDirectory -File | Where-Object Name -ne 'README.md') }
$mt5Processes = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
$repoLock = Test-Path -LiteralPath (Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock')
$outerLock = Test-Path -LiteralPath (Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock')
$unlockFile = Test-Path -LiteralPath (Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock')
$hiddenAckFile = Test-Path -LiteralPath (Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock')
$locksCleared = !$repoLock -and !$outerLock
$authorizationReady = $env:ALLOW_MT5_FOCUS_RISK -eq '1' -and $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1' -and $unlockFile -and $hiddenAckFile
$driveName = [IO.Path]::GetPathRoot($sharedWork).Substring(0,1)
$freeBytes = (Get-PSDrive -Name $driveName).Free
$diskReady = $freeBytes -ge 10GB

$gates = [System.Collections.Generic.List[object]]::new()
Add-Gate $gates 'frozen-source-identity' ($sourceHash -eq $expectedSourceHash) 'WAVE_01_RUN' "sha256=$sourceHash"
Add-Gate $gates 'frozen-profile-identity' ($profileHash -eq $expectedProfileHash -and $profileInputCount -eq 589) 'WAVE_01_RUN' "sha256=$profileHash; inputs=$profileInputCount"
Add-Gate $gates 'frozen-manifest-identity' ($manifestHash -eq $expectedManifestHash -and $manifestRows.Count -eq 24) 'WAVE_01_RUN' "sha256=$manifestHash; rows=$($manifestRows.Count)"
Add-Gate $gates 'wave-01-contract' $waveContractReady 'WAVE_01_RUN' "rows=$($waveRows.Count); windows=$($waveRows.Window -join ','); model=1"
Add-Gate $gates 'wave-01-config-identities' $configIdentityReady 'WAVE_01_RUN' 'Both config hashes match the frozen manifest.'
Add-Gate $gates 'two-portable-runtimes' $runtimeReady 'WAVE_01_RUN' "ready=$(@($workerRows | Where-Object RuntimeReady).Count)/2"
Add-Gate $gates 'uniform-runtime-build' $runtimeBuildReady 'WAVE_01_RUN' "terminal=$($runtimeVersions -join ','); editor=$($editorVersions -join ',')"
Add-Gate $gates 'model1-history-2019' $history2019Ready 'WAVE_01_RUN' "unique_hashes=$($history2019Hashes.Count)"
Add-Gate $gates 'model1-history-2022' $history2022Ready 'WAVE_01_RUN' "unique_hashes=$($history2022Hashes.Count)"
Add-Gate $gates 'empty-report-destination' ($reportArtifacts.Count -eq 0) 'WAVE_01_RUN' "artifacts=$($reportArtifacts.Count)"
Add-Gate $gates 'mt5-processes-stopped' ($mt5Processes.Count -eq 0) 'WAVE_01_RUN' "processes=$($mt5Processes.Count)"
Add-Gate $gates 'minimum-free-disk' $diskReady 'WAVE_01_RUN' 'At least 10 GB free on the workspace drive.'
Add-Gate $gates 'launch-locks-cleared' $locksCleared 'WAVE_01_RUN' "repository_lock=$repoLock; outer_lock=$outerLock"
Add-Gate $gates 'explicit-focus-risk-authorization' $authorizationReady 'WAVE_01_RUN' "env_focus=$($env:ALLOW_MT5_FOCUS_RISK -eq '1'); env_hidden=$($env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1'); unlocks=$unlockFile/$hiddenAckFile"
Add-Gate $gates 'exact-successor-source-staged' $stagedSourceReady 'COMPILE_PREP' "ready_workers=$(@($workerRows | Where-Object ExactSourceReady).Count)/2"
Add-Gate $gates 'shared-successor-binary' $sharedBinaryReady 'REUSE_ONLY' "ready_workers=$($readyBinaries.Count)/2; unique_ready_binaries=$($readyBinaryHashes.Count)"
Add-Gate $gates 'model4-ticks-2019' $model4Ticks2019Ready 'FUTURE_WAVE_03' "months_per_worker=$($workerRows.TickMonths2019 -join ',')"
Add-Gate $gates 'model4-ticks-2022' $model4Ticks2022Ready 'FUTURE_WAVE_03' "months_per_worker=$($workerRows.TickMonths2022 -join ',')"

$infrastructureBlockers = @($gates | Where-Object { $_.RequiredFor -eq 'WAVE_01_RUN' -and $_.Gate -notin @('launch-locks-cleared','explicit-focus-risk-authorization') -and !$_.Ready })
$infrastructureReady = $infrastructureBlockers.Count -eq 0
$safeToLaunchNow = $infrastructureReady -and $locksCleared -and $authorizationReady
$status = if(!$infrastructureReady) {
   'INFRASTRUCTURE_BLOCKED'
} elseif(!$locksCleared) {
   if($sharedBinaryReady) { 'HARD_LOCKED_SHARED_BINARY_READY' } elseif($stagedSourceReady) { 'HARD_LOCKED_SOURCE_STAGED_COMPILE_ONCE_REQUIRED' } else { 'HARD_LOCKED_COMPILE_ONCE_REQUIRED' }
} elseif(!$authorizationReady) {
   'AWAITING_EXPLICIT_FOCUS_RISK_AUTHORIZATION'
} elseif($sharedBinaryReady) {
   'READY_TO_RUN_WAVE_01'
} else {
   'READY_TO_COMPILE_ONCE_AND_RUN_WAVE_01'
}
$nextAction = switch($status) {
   'INFRASTRUCTURE_BLOCKED' { 'REPAIR_WAVE_01_INFRASTRUCTURE' }
   'HARD_LOCKED_SHARED_BINARY_READY' { 'DELIBERATE_LOCK_REVIEW_REQUIRED' }
   'HARD_LOCKED_SOURCE_STAGED_COMPILE_ONCE_REQUIRED' { 'DELIBERATE_LOCK_REVIEW_THEN_COMPILE_ONCE_AND_RUN_WAVE_01' }
   'HARD_LOCKED_COMPILE_ONCE_REQUIRED' { 'DELIBERATE_LOCK_REVIEW_THEN_COMPILE_ONCE_AND_RUN_WAVE_01' }
   'AWAITING_EXPLICIT_FOCUS_RISK_AUTHORIZATION' { 'COMPLETE_EXPLICIT_FOCUS_RISK_AUTHORIZATION' }
   'READY_TO_RUN_WAVE_01' { 'RUN_WAVE_01_ONLY' }
   default { 'COMPILE_ONCE_AND_RUN_WAVE_01_ONLY' }
}

$summary = [pscustomobject][ordered]@{
   Status = $status
   NextAction = $nextAction
   InfrastructureReady = $infrastructureReady
   SafeToLaunchNow = $safeToLaunchNow
   LaunchLocksPresent = [bool]($repoLock -or $outerLock)
   ExplicitAuthorizationReady = $authorizationReady
   RuntimeWorkersReady = @($workerRows | Where-Object RuntimeReady).Count
   RuntimeBuild = if($runtimeBuildReady) { $runtimeVersions[0] } else { 'MIXED_OR_MISSING' }
   WaveRows = $waveRows.Count
   Model1History2019Ready = $history2019Ready
   Model1History2022Ready = $history2022Ready
   StagedSourceReady = $stagedSourceReady
   SharedBinaryReady = $sharedBinaryReady
   CompilationNeeded = !$sharedBinaryReady
   CurrentSourceIdentities = $currentSourceIdentities.Count
   CurrentBinaryIdentities = $currentBinaryIdentities.Count
   ReportsPresent = $reportArtifacts.Count
   Model4TickMonths2019PerWorker = $workerRows.TickMonths2019 -join ','
   Model4TickMonths2022PerWorker = $workerRows.TickMonths2022 -join ','
   Model4Ticks2022Ready = $model4Ticks2022Ready
   MQL5Launched = $false
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
   SourceSha256 = $expectedSourceHash
   ProfileSha256 = $expectedProfileHash
   ManifestSha256 = $expectedManifestHash
}
$summary | Export-Csv -LiteralPath $statusCsv -NoTypeInformation -Encoding ASCII
$workerRows | Export-Csv -LiteralPath $workersCsv -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Money-Ready Gate-Repair Wave 1 Readiness', '',
   "**Status: $status. Safe to launch now: $safeToLaunchNow.**", '',
   "- Next action: ``$nextAction``",
   "- Infrastructure ready: ``$infrastructureReady``",
   "- Portable workers ready: ``$($summary.RuntimeWorkersReady)/2`` on build ``$($summary.RuntimeBuild)``",
   "- Frozen Wave 1 rows: ``$($waveRows.Count)`` (`2019`, `2022`, Model1)",
   "- Model1 history ready: 2019=``$history2019Ready``; 2022=``$history2022Ready``",
   "- Exact successor source staged: ``$stagedSourceReady``",
   "- Existing successor shared binary ready: ``$sharedBinaryReady``",
   "- Compile-once action required: ``$(!$sharedBinaryReady)``",
   "- Report artifacts present: ``$($reportArtifacts.Count)``",
   "- Hard launch lock present: ``$($repoLock -or $outerLock)``",
   "- Explicit focus-risk authorization ready: ``$authorizationReady``",
   "- Future Model4 tick cache: 2019=``$model4Ticks2019Ready``; 2022=``$model4Ticks2022Ready``", '',
   'The exact successor source may be staged while both launch locks remain present. Existing EX5 and compiled-identity artifacts remain untrusted and untouched; the guarded runner must still compile the exact successor once on one leader, then distribute one byte-identical source, EX5, and identity file to both workers.', '',
   'The missing 2022 TKC months do not block Wave 1 because Wave 1 is Model1 one-minute OHLC. They are a future Wave 3 Model4 data-download requirement. This report performs no compilation, terminal launch, test, account action, or evidence promotion.', '',
   '| Gate | Ready | Required for | Evidence |', '|---|---:|---|---|'
) + @($gates | ForEach-Object { "| $($_.Gate) | $($_.Ready) | $($_.RequiredFor) | $($_.Evidence) |" }) |
   Set-Content -LiteralPath $statusMarkdown -Encoding ASCII

$summary
