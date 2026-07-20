[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig = 15,
   [switch]$UserAuthorizedFocusRisk
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk) { throw 'Controlled recovery requires explicit focus/window-risk authorization.' }
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$repoLock = Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock = Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$unlockFile = Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'
$focusAck = Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'
$runner = Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$manifest = Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_PARTIAL_RUNNER_DISCOVERY_MODEL1_RECOVERY_MANIFEST.csv'
$expectedManifestHash = '1A959ECD10C42DEB6065ECE6B4955CB8A2FA11DF90F1B1CFD127C71FE4A50ED0'
$expectedBinaryHash = '8B72A5B1457BCBF79118381AA5F2F8B1D709DA703611BE60778C4DB518DCD130'
$roots = @((Join-Path $sharedWork 'mt5_portable_research'),(Join-Path $sharedWork 'mt5_portable_research_w2'))
foreach($required in @($repoLock,$outerLock,$runner,$manifest) + $roots) {
   if(!(Test-Path -LiteralPath $required)) { throw "Controlled recovery prerequisite missing: $required" }
}
if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) {
   throw 'Recovery manifest identity changed.'
}
foreach($root in $roots) {
   $binary = Join-Path $root 'MQL5\Experts\Professional_XAUUSD_EA.ex5'
   if((Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedBinaryHash) {
      throw "Portable binary identity mismatch: $root"
   }
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $focusAck) -or
   @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled recovery requires a fully locked, stopped MT5 state.'
}
$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$completed = $false
try {
   [IO.File]::Delete($repoLock); [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile,"Momentum partial-runner recovery $startedAtUtc",[Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($focusAck,"Momentum partial-runner recovery focus acknowledgement $startedAtUtc",[Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK='1'; $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK='1'
   & $runner -ManifestPath $manifest -PortableRoots $roots -UserAuthorizedFocusRisk `
      -OutputPrefix 'THREE_LANE_MOMENTUM_PARTIAL_RUNNER_DISCOVERY_RECOVERY' `
      -MaxCpuPercent $MaxCpuPercent -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -ExpectedPortableBinarySha256 $expectedBinaryHash -ProgressIntervalSeconds 10
   $completed = $true
} finally {
   Remove-Item -LiteralPath $unlockFile,$focusAck -Force -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   [IO.File]::WriteAllBytes($repoLock,$repoLockBytes); [IO.File]::WriteAllBytes($outerLock,$outerLockBytes)
   Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue |
      Stop-Process -Force -ErrorAction SilentlyContinue
}
if(!$completed) { throw 'Controlled recovery did not complete.' }
[pscustomobject][ordered]@{
   Status='CONTROLLED_RECOVERY_COMPLETE';StartedAtUtc=$startedAtUtc;CompletedAtUtc=[DateTime]::UtcNow.ToString('o')
   Configurations=2;Workers=2;LaunchLocksRestored=(Test-Path $repoLock) -and (Test-Path $outerLock)
   MT5Processes=@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count
   ForwardCandidateChanged=$false;RealAccountApproved=$false
}
