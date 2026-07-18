[CmdletBinding()]
param(
   [string]$SourcePath = 'outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5',
   [string[]]$WorkerNames = @('mt5_portable_research','mt5_portable_research_w2','mt5_portable_research_w3','mt5_portable_research_w4'),
   [switch]$Stage,
   [string]$StatusCsvPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SOURCE_STAGING.csv',
   [string]$StatusMarkdownPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SOURCE_STAGING.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$expectedSourceHash = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
$canonicalSource = [IO.Path]::GetFullPath((Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5'))

function Resolve-RepoPath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
   return [IO.Path]::GetFullPath((Join-Path $repo ($Path -replace '/', '\')))
}

function Get-OptionalHash {
   param([Parameter(Mandatory=$true)][string]$Path)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return 'MISSING' }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Resolve-WorkerRoot {
   param([Parameter(Mandatory=$true)][string]$Name)
   if($Name -notmatch '^mt5_portable_research(?:_w\d+)?$') {
      throw "Worker name is outside the portable research allowlist: $Name"
   }
   $root = [IO.Path]::GetFullPath((Join-Path $sharedWork $Name))
   if(!(Split-Path -Parent $root).Equals($sharedWork, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Worker path escaped the shared workspace: $Name"
   }
   return $root
}

function Install-ExactSource {
   param(
      [Parameter(Mandatory=$true)][string]$From,
      [Parameter(Mandatory=$true)][string]$To
   )
   $parent = Split-Path -Parent $To
   if(!(Test-Path -LiteralPath $parent -PathType Container)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   $temporary = $To + '.source-stage.tmp.' + [guid]::NewGuid().ToString('N')
   try {
      Copy-Item -LiteralPath $From -Destination $temporary -Force
      if((Get-OptionalHash $temporary) -ne $expectedSourceHash) {
         throw "Temporary staged source identity mismatch: $To"
      }
      Move-Item -LiteralPath $temporary -Destination $To -Force
   }
   finally {
      Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
   }
}

$source = Resolve-RepoPath $SourcePath
if(!$source.Equals($canonicalSource, [StringComparison]::OrdinalIgnoreCase)) {
   throw 'Offline staging only accepts the canonical frozen successor source path.'
}
if(!(Test-Path -LiteralPath $source -PathType Leaf)) { throw 'Frozen successor source is missing.' }
$sourceHash = Get-OptionalHash $source
if($sourceHash -ne $expectedSourceHash) { throw 'Frozen successor source identity changed.' }
if($WorkerNames.Count -lt 1 -or $WorkerNames.Count -gt 4 -or
   @($WorkerNames | Sort-Object -Unique).Count -ne $WorkerNames.Count) {
   throw 'Offline staging requires one to four unique portable worker names.'
}

$repoLock = Test-Path -LiteralPath (Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock')
$outerLock = Test-Path -LiteralPath (Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock')
$unlockFile = Test-Path -LiteralPath (Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock')
$hiddenAckFile = Test-Path -LiteralPath (Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock')
$launchEnvironmentClear = $env:ALLOW_MT5_FOCUS_RISK -ne '1' -and $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ne '1'
$beforeProcesses = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
$guardReady = $repoLock -and $outerLock -and !$unlockFile -and !$hiddenAckFile -and
   $launchEnvironmentClear -and $beforeProcesses.Count -eq 0

$beforeRows = [System.Collections.Generic.List[object]]::new()
foreach($name in $WorkerNames) {
   $root = Resolve-WorkerRoot $name
   $terminal = Join-Path $root 'terminal64.exe'
   $editor = Join-Path $root 'MetaEditor64.exe'
   $experts = Join-Path $root 'MQL5\Experts'
   $portableSource = Join-Path $experts 'Professional_XAUUSD_EA.mq5'
   $portableBinary = Join-Path $experts 'Professional_XAUUSD_EA.ex5'
   $portableIdentity = Join-Path $experts 'Professional_XAUUSD_EA.compiled_identity.txt'
   $beforeRows.Add([pscustomobject][ordered]@{
      Worker = $name
      Root = $root
      RuntimeReady = (Test-Path -LiteralPath $terminal -PathType Leaf) -and (Test-Path -LiteralPath $editor -PathType Leaf)
      SourcePath = $portableSource
      BinaryPath = $portableBinary
      IdentityPath = $portableIdentity
      BeforeSourceSha256 = Get-OptionalHash $portableSource
      BeforeBinarySha256 = Get-OptionalHash $portableBinary
      BeforeIdentitySha256 = Get-OptionalHash $portableIdentity
   }) | Out-Null
}

$runtimeReady = @($beforeRows | Where-Object { !$_.RuntimeReady }).Count -eq 0
$alreadyStaged = $runtimeReady -and @($beforeRows | Where-Object BeforeSourceSha256 -ne $expectedSourceHash).Count -eq 0
if($Stage) {
   if(!$guardReady) {
      throw 'Offline source staging requires both hard locks, no unlock acknowledgements, cleared launch flags, and zero MT5-family processes.'
   }
   if(!$runtimeReady) { throw 'Offline source staging cannot write to an incomplete portable runtime set.' }
   foreach($row in $beforeRows) { Install-ExactSource -From $source -To $row.SourcePath }
}

$afterProcesses = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
$resultRows = foreach($row in $beforeRows) {
   $afterSourceHash = Get-OptionalHash $row.SourcePath
   $afterBinaryHash = Get-OptionalHash $row.BinaryPath
   $afterIdentityHash = Get-OptionalHash $row.IdentityPath
   [pscustomobject][ordered]@{
      Worker = $row.Worker
      RuntimeReady = $row.RuntimeReady
      BeforeSourceSha256 = $row.BeforeSourceSha256
      AfterSourceSha256 = $afterSourceHash
      ExactSourceReady = $afterSourceHash -eq $expectedSourceHash
      SourceChanged = $row.BeforeSourceSha256 -ne $afterSourceHash
      BeforeBinarySha256 = $row.BeforeBinarySha256
      AfterBinarySha256 = $afterBinaryHash
      BinaryUnchanged = $row.BeforeBinarySha256 -eq $afterBinaryHash
      BeforeIdentitySha256 = $row.BeforeIdentitySha256
      AfterIdentitySha256 = $afterIdentityHash
      IdentityUnchanged = $row.BeforeIdentitySha256 -eq $afterIdentityHash
      MQL5Launched = $false
   }
}

$allExact = $runtimeReady -and @($resultRows | Where-Object { !$_.ExactSourceReady }).Count -eq 0
$compiledArtifactsUnchanged = @($resultRows | Where-Object { !$_.BinaryUnchanged -or !$_.IdentityUnchanged }).Count -eq 0
if($Stage -and (!$allExact -or !$compiledArtifactsUnchanged -or $afterProcesses.Count -ne 0)) {
   throw 'Offline source staging failed its post-write source, compiled-artifact, or no-launch invariant.'
}
$status = if(!$runtimeReady) {
   'RUNTIME_BLOCKED'
} elseif(!$guardReady) {
   'OFFLINE_GUARD_BLOCKED'
} elseif($Stage -and $alreadyStaged) {
   'ALREADY_STAGED_OFFLINE_LOCKED'
} elseif($Stage) {
   'STAGED_OFFLINE_LOCKED'
} elseif($alreadyStaged) {
   'ALREADY_STAGED_OFFLINE_LOCKED'
} else {
   'READY_TO_STAGE_OFFLINE_LOCKED'
}

$statusCsv = Resolve-RepoPath $StatusCsvPath
$statusMarkdown = Resolve-RepoPath $StatusMarkdownPath
foreach($output in @($statusCsv,$statusMarkdown)) {
   $parent = Split-Path -Parent $output
   if($parent -and !(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
}
$resultRows | Export-Csv -LiteralPath $statusCsv -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Money-Ready Gate-Repair Offline Source Staging', '',
   "**Status: $status. Exact successor source ready: $allExact.**", '',
   "- Mode: ``$(if($Stage){'STAGE'}else{'PLAN'})``",
   "- Frozen source SHA-256: ``$expectedSourceHash``",
   "- Portable workers: ``$($resultRows.Count)``",
   "- Runtime workers ready: ``$(@($resultRows | Where-Object RuntimeReady).Count)/$($resultRows.Count)``",
   "- Both hard launch locks present: ``$($repoLock -and $outerLock)``",
   "- Launch authorization absent: ``$(!$unlockFile -and !$hiddenAckFile -and $launchEnvironmentClear)``",
   "- MT5-family processes before/after: ``$($beforeProcesses.Count)/$($afterProcesses.Count)``",
   "- Compiled EX5 and identity artifacts unchanged: ``$compiledArtifactsUnchanged``",
   '- Compilation performed: `False`',
   '- Backtest performed: `False`',
   '- Forward candidate changed: `False`',
   '- Real account approved: `False`', '',
   'This operation only stages the exact manifest-bound successor `.mq5` into stopped portable research runtimes. Existing EX5 and compiled-identity artifacts remain untouched and are still untrusted until the guarded compile-once executable wave runs.', '',
   '| Worker | Runtime | Exact source | Source changed | Binary unchanged | Identity unchanged |',
   '|---|---:|---:|---:|---:|---:|'
) + @($resultRows | ForEach-Object { "| $($_.Worker) | $($_.RuntimeReady) | $($_.ExactSourceReady) | $($_.SourceChanged) | $($_.BinaryUnchanged) | $($_.IdentityUnchanged) |" }) |
   Set-Content -LiteralPath $statusMarkdown -Encoding ASCII

[pscustomobject][ordered]@{
   Status = $status
   Workers = $resultRows.Count
   RuntimeWorkersReady = @($resultRows | Where-Object RuntimeReady).Count
   ExactSourceWorkersReady = @($resultRows | Where-Object ExactSourceReady).Count
   CompiledArtifactsUnchanged = $compiledArtifactsUnchanged
   LaunchLocksPresent = [bool]($repoLock -and $outerLock)
   MQL5Launched = $false
   Compiled = $false
   Backtested = $false
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
