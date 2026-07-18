[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,60)][int]$TimeoutMinutesPerConfig = 15,
   [switch]$UserAuthorizedFocusRisk
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if(!$UserAuthorizedFocusRisk) { throw 'Controlled Wave 1 requires explicit focus/window-risk authorization.' }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$repoLock = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'))
$outerLock = [IO.Path]::GetFullPath((Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'))
$unlockFile = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'))
$hiddenAckFile = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'))
$runner = Join-Path $PSScriptRoot 'run_rdmc_money_ready_gate_repair_executable_wave.ps1'
$readinessBuilder = Join-Path $PSScriptRoot 'build_rdmc_money_ready_gate_repair_wave_01_readiness.ps1'
$statusPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_WAVE_01_READINESS.csv'

if((Split-Path -Parent $repoLock) -ne $PSScriptRoot -or (Split-Path -Parent $outerLock) -ne $sharedWork) {
   throw 'Controlled Wave 1 lock paths escaped the intended workspace.'
}
foreach($required in @($repoLock,$outerLock,$runner,$readinessBuilder)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Controlled Wave 1 prerequisite is missing: $required" }
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $hiddenAckFile) -or
   $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1') {
   throw 'Controlled Wave 1 refuses a pre-existing partial unlock state.'
}

& $readinessBuilder | Out-Null
$readiness = @(Import-Csv -LiteralPath $statusPath)
if($readiness.Count -ne 1 -or $readiness[0].Status -notin @('HARD_LOCKED_SOURCE_STAGED_COMPILE_ONCE_REQUIRED','HARD_LOCKED_SHARED_BINARY_READY') -or
   $readiness[0].InfrastructureReady -ne 'True' -or $readiness[0].ReportsPresent -ne '0' -or
   $readiness[0].MQL5Launched -ne 'False') {
   throw 'Controlled Wave 1 readiness boundary is not satisfied.'
}

$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$runnerCompleted = $false
try {
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile, "Controlled Wave 1 authorization at $startedAtUtc", [Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($hiddenAckFile, "Controlled Wave 1 focus/window acknowledgement at $startedAtUtc", [Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK = '1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = '1'

   & $runner -Wave 1 -MaxCpuPercent $MaxCpuPercent -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -Run -UserAuthorizedFocusRisk
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

if(!$runnerCompleted) { throw 'Controlled Wave 1 runner did not complete.' }
if(!(Test-Path -LiteralPath $repoLock -PathType Leaf) -or !(Test-Path -LiteralPath $outerLock -PathType Leaf)) {
   throw 'Controlled Wave 1 did not restore both launch locks.'
}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled Wave 1 left an MT5-family process running.'
}

[pscustomobject][ordered]@{
   Status = 'CONTROLLED_WAVE_01_COMPLETE'
   StartedAtUtc = $startedAtUtc
   CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
   MaxCpuPercent = $MaxCpuPercent
   TimeoutMinutesPerConfig = $TimeoutMinutesPerConfig
   LaunchLocksRestored = $true
   UnlockAcknowledgementsRemoved = $true
   MT5Processes = 0
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
