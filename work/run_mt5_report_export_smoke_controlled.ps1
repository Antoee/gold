[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,30)][int]$TimeoutMinutesPerConfig = 3,
   [switch]$UserAuthorizedFocusRisk
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk) { throw 'Controlled smoke testing requires explicit focus/window-risk authorization.' }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$smoke = Join-Path $PSScriptRoot 'test_mt5_report_export_smoke.ps1'
$repoLock = Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock = Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$unlockFile = Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'
$focusAck = Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'
$processNames = @('terminal','terminal64','metatester','metatester64','MetaEditor','metaeditor64')

foreach($required in @($smoke,$repoLock,$outerLock)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Controlled smoke prerequisite missing: $required" }
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $focusAck) -or
   $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1') {
   throw 'Controlled smoke refuses a pre-existing partial unlock state.'
}
if(@(Get-Process -Name $processNames -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled smoke requires all MT5-family processes stopped.'
}

$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$completed = $false
try {
   [IO.File]::Delete($outerLock)
   & $smoke -MaxCpuPercent $MaxCpuPercent -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig
   $completed = $true
}
finally {
   Get-Process -Name $processNames -ErrorAction SilentlyContinue |
      Stop-Process -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath $unlockFile,$focusAck -Force -ErrorAction SilentlyContinue
   Remove-Item Env:\ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:\ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   [IO.File]::WriteAllBytes($repoLock,$repoLockBytes)
   [IO.File]::WriteAllBytes($outerLock,$outerLockBytes)
}

if(!$completed) { throw 'Controlled report-export smoke did not complete.' }
if(!(Test-Path -LiteralPath $repoLock -PathType Leaf) -or !(Test-Path -LiteralPath $outerLock -PathType Leaf) -or
   @(Get-Process -Name $processNames -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled report-export smoke did not restore the idle safety boundary.'
}

[pscustomobject][ordered]@{
   Status = 'CONTROLLED_SMOKE_COMPLETE'
   StartedAtUtc = $startedAtUtc
   CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
   LaunchLocksRestored = $true
   MT5Processes = 0
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
