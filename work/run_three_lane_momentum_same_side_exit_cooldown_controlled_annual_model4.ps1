[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig = 15,
   [switch]$UserAuthorizedFocusRisk,
   [switch]$SingleWorkerRecovery
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk) { throw 'Controlled same-side exit-cooldown annual Model 4 validation requires explicit focus/window-risk authorization.' }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$repoLock = Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock = Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$unlockFile = Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'
$focusAck = Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'
$runner = Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$manifest = Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_MANIFEST.csv'
$source = Join-Path $repo 'outputs\three_lane_momentum_same_side_exit_cooldown_annual_model4_package\source\Professional_XAUUSD_EA.mq5'
$expectedManifestHash = '3181F0430A69E5843D07F85E905783CDED0245C6121B7A126944D0E245FF5ABC'
$expectedSourceHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedBinaryHash = 'D85336B07A8C34C4567537D5C9BD7CDC0F31D0B8ED67B73BAC1088B19E126123'
$roots = @(
   (Join-Path $sharedWork 'mt5_portable_research'),
   (Join-Path $sharedWork 'mt5_portable_research_w2'),
   (Join-Path $sharedWork 'mt5_portable_research_w3'),
   (Join-Path $sharedWork 'mt5_portable_research_w4')
)
if($SingleWorkerRecovery) { $roots = @($roots[0]) }

foreach($required in @($repoLock,$outerLock,$runner,$manifest,$source) + $roots) {
   if(!(Test-Path -LiteralPath $required)) { throw "Controlled same-side exit-cooldown prerequisite missing: $required" }
}
if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) {
   throw 'Same-side exit-cooldown manifest identity changed.'
}
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash) {
   throw 'Same-side exit-cooldown package source identity changed.'
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
   throw 'Controlled same-side exit-cooldown testing refuses a pre-existing partial unlock state.'
}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled same-side exit-cooldown testing requires zero pre-existing MT5-family processes.'
}

$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$completed = $false
try {
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile, "Same-side exit-cooldown discovery $startedAtUtc", [Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($focusAck, "Same-side exit-cooldown focus acknowledgement $startedAtUtc", [Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK = '1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = '1'
   & $runner -ManifestPath $manifest -PortableRoots $roots -UserAuthorizedFocusRisk `
      -OutputPrefix $(if($SingleWorkerRecovery) { 'THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_RECOVERY_WORKER' } else { 'THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_WORKER' }) `
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
if(!$completed) { throw 'Controlled same-side exit-cooldown discovery did not complete.' }
if(!(Test-Path -LiteralPath $repoLock) -or !(Test-Path -LiteralPath $outerLock) -or
   @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled same-side exit-cooldown discovery did not restore hard-lock state.'
}
[pscustomobject][ordered]@{
   Status = 'CONTROLLED_DISCOVERY_COMPLETE'
   StartedAtUtc = $startedAtUtc
   CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
   Configurations = 24
   Workers = $roots.Count
   MaxCpuPercent = $MaxCpuPercent
   LaunchLocksRestored = $true
   MT5Processes = 0
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
