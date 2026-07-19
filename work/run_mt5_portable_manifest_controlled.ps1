[CmdletBinding()]
param(
   [Parameter(Mandatory=$true)][string]$ManifestPath,
   [ValidateRange(1,4)][int]$MaxWorkers = 1,
   [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_.-]*$')][string]$OutputPrefix = 'MT5_CONTROLLED_WORKER',
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig = 15,
   [string]$ExpectedPortableBinarySha256 = '',
   [switch]$UserAuthorizedFocusRisk
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if(!$UserAuthorizedFocusRisk) {
   throw 'Controlled portable-manifest testing requires explicit focus/window-risk authorization.'
}

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$manifestCandidate = if([IO.Path]::IsPathRooted($ManifestPath)) { $ManifestPath } else { Join-Path $repo $ManifestPath }
$manifest = (Resolve-Path -LiteralPath $manifestCandidate).Path
$runner = Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$repoLock = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'))
$outerLock = [IO.Path]::GetFullPath((Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'))
$unlockFile = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'))
$hiddenAckFile = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'))
$availableRoots = @(
   (Join-Path $sharedWork 'mt5_portable_research'),
   (Join-Path $sharedWork 'mt5_portable_research_w2'),
   (Join-Path $sharedWork 'mt5_portable_research_w3'),
   (Join-Path $sharedWork 'mt5_portable_research_w4')
) | Where-Object {
   (Test-Path -LiteralPath (Join-Path $_ 'terminal64.exe') -PathType Leaf) -and
   (Test-Path -LiteralPath (Join-Path $_ 'MetaEditor64.exe') -PathType Leaf)
}

foreach($required in @($manifest,$runner,$repoLock,$outerLock)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) {
      throw "Controlled portable-manifest prerequisite is missing: $required"
   }
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $hiddenAckFile) -or
   $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1') {
   throw 'Controlled portable-manifest testing refuses a pre-existing partial unlock state.'
}
$manifestRows = @(Import-Csv -LiteralPath $manifest)
if($manifestRows.Count -lt 1) { throw 'Controlled portable manifest has no rows.' }
$workerCount = [Math]::Min([Math]::Min($MaxWorkers,$availableRoots.Count),$manifestRows.Count)
if($workerCount -lt 1) { throw 'No portable research runtime is available.' }
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled portable-manifest testing requires zero pre-existing MT5-family processes.'
}

$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$runnerCompleted = $false
try {
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile,
      "Controlled portable manifest authorization at $startedAtUtc",
      [Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($hiddenAckFile,
      "Controlled portable manifest focus/window acknowledgement at $startedAtUtc",
      [Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK = '1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = '1'

   $runnerArgs = @{
      ManifestPath = $manifest
      PortableRoots = @($availableRoots | Select-Object -First $workerCount)
      UserAuthorizedFocusRisk = $true
      OutputPrefix = $OutputPrefix
      MaxCpuPercent = $MaxCpuPercent
      TimeoutMinutesPerConfig = $TimeoutMinutesPerConfig
   }
   if(![string]::IsNullOrWhiteSpace($ExpectedPortableBinarySha256)) {
      $runnerArgs.ExpectedPortableBinarySha256 = $ExpectedPortableBinarySha256
   }
   & $runner @runnerArgs
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

if(!$runnerCompleted) { throw 'Controlled portable-manifest runner did not complete.' }
if(!(Test-Path -LiteralPath $repoLock -PathType Leaf) -or !(Test-Path -LiteralPath $outerLock -PathType Leaf)) {
   throw 'Controlled portable-manifest runner did not restore both launch locks.'
}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled portable-manifest runner left an MT5-family process running.'
}

[pscustomobject][ordered]@{
   Status = 'CONTROLLED_PORTABLE_MANIFEST_COMPLETE'
   Manifest = $manifest
   Rows = $manifestRows.Count
   Workers = $workerCount
   StartedAtUtc = $startedAtUtc
   CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
   LaunchLocksRestored = $true
   MT5Processes = 0
}
