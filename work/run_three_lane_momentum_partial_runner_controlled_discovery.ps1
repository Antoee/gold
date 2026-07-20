[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig = 15,
   [switch]$UserAuthorizedFocusRisk
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk) { throw 'Controlled momentum partial-runner testing requires explicit focus/window-risk authorization.' }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$repoLock = Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock = Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$unlockFile = Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'
$focusAck = Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'
$runner = Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$manifest = Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_PARTIAL_RUNNER_DISCOVERY_MODEL1_MANIFEST.csv'
$source = Join-Path $repo 'outputs\three_lane_momentum_partial_runner_discovery_model1_package\source\Professional_XAUUSD_EA.mq5'
$expectedManifestHash = '81D2138F43F8B4B7B24BDD75036CA4B87AD27A9ADF2495E9AEDBA014D121505A'
$expectedSourceHash = '1092D9AD0036C6C4E7A0F61CB7318B31CDCE75F9311762388CF256AFFB6BFEA9'
$expectedBinaryHash = '8B72A5B1457BCBF79118381AA5F2F8B1D709DA703611BE60778C4DB518DCD130'
$roots = @(
   (Join-Path $sharedWork 'mt5_portable_research'),
   (Join-Path $sharedWork 'mt5_portable_research_w2'),
   (Join-Path $sharedWork 'mt5_portable_research_w3'),
   (Join-Path $sharedWork 'mt5_portable_research_w4')
)

foreach($required in @($repoLock,$outerLock,$runner,$manifest,$source) + $roots) {
   if(!(Test-Path -LiteralPath $required)) { throw "Controlled momentum partial-runner prerequisite missing: $required" }
}
if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) {
   throw 'Momentum partial-runner manifest identity changed.'
}
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash) {
   throw 'Momentum partial-runner package source identity changed.'
}
foreach($root in $roots) {
   $binary = Join-Path $root 'MQL5\Experts\Professional_XAUUSD_EA.ex5'
   if(!(Test-Path -LiteralPath $binary -PathType Leaf) -or
      (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedBinaryHash) {
      throw "Portable binary identity mismatch: $root"
   }
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $focusAck) -or
   $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1') {
   throw 'Controlled momentum partial-runner testing refuses a pre-existing partial unlock state.'
}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled momentum partial-runner testing requires zero pre-existing MT5-family processes.'
}

$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$completed = $false
try {
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile, "Momentum partial-runner discovery $startedAtUtc", [Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($focusAck, "Momentum partial-runner focus acknowledgement $startedAtUtc", [Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK = '1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = '1'
   & $runner -ManifestPath $manifest -PortableRoots $roots -UserAuthorizedFocusRisk `
      -OutputPrefix 'THREE_LANE_MOMENTUM_PARTIAL_RUNNER_DISCOVERY_WORKER' `
      -MaxCpuPercent $MaxCpuPercent -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -ExpectedPortableBinarySha256 $expectedBinaryHash -ProgressIntervalSeconds 10
   $completed = $true
}
finally {
   Remove-Item -LiteralPath $unlockFile,$focusAck -Force -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   [IO.File]::WriteAllBytes($repoLock,$repoLockBytes)
   [IO.File]::WriteAllBytes($outerLock,$outerLockBytes)
   Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue |
      Stop-Process -Force -ErrorAction SilentlyContinue
}
if(!$completed) { throw 'Controlled momentum partial-runner discovery did not complete.' }
if(!(Test-Path -LiteralPath $repoLock) -or !(Test-Path -LiteralPath $outerLock) -or
   @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled momentum partial-runner discovery did not restore hard-lock state.'
}
[pscustomobject][ordered]@{
   Status = 'CONTROLLED_DISCOVERY_COMPLETE';StartedAtUtc = $startedAtUtc
   CompletedAtUtc = [DateTime]::UtcNow.ToString('o');Configurations = 24;Workers = 4
   MaxCpuPercent = $MaxCpuPercent;LaunchLocksRestored = $true;MT5Processes = 0
   ForwardCandidateChanged = $false;RealAccountApproved = $false
}
