[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig = 15,
   [switch]$UserAuthorizedFocusRisk
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk) { throw 'Controlled partial-runner testing requires explicit focus/window-risk authorization.' }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$repoLock = Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock = Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$unlockFile = Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'
$focusAck = Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'
$runner = Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$manifest = Join-Path $repo 'outputs\THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_MODEL1_MANIFEST.csv'
$source = Join-Path $repo 'outputs\three_lane_reversion_partial_runner_discovery_model1_package\source\Professional_XAUUSD_EA.mq5'
$expectedManifestHash = '66E6E01AE5A802E1E3423C51B4E5A015B480E369424EA8D84539312304512D40'
$expectedSourceHash = '614DCF5B0C55DF25DABDCF903C3193A0CE248AA2671788A400B5C39A4209F719'
$expectedBinaryHash = '37F90A3C23CEF638AEE689807E01F7EC220EF01EC999CA6D41D6F8BE6906A810'
$roots = @(
   (Join-Path $sharedWork 'mt5_portable_research'),
   (Join-Path $sharedWork 'mt5_portable_research_w2'),
   (Join-Path $sharedWork 'mt5_portable_research_w3'),
   (Join-Path $sharedWork 'mt5_portable_research_w4')
)

foreach($required in @($repoLock,$outerLock,$runner,$manifest,$source) + $roots) {
   if(!(Test-Path -LiteralPath $required)) { throw "Controlled partial-runner prerequisite missing: $required" }
}
if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) {
   throw 'Partial-runner manifest identity changed.'
}
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash) {
   throw 'Partial-runner package source identity changed.'
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
   throw 'Controlled partial-runner testing refuses a pre-existing partial unlock state.'
}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled partial-runner testing requires zero pre-existing MT5-family processes.'
}

$repoLockBytes = [IO.File]::ReadAllBytes($repoLock)
$outerLockBytes = [IO.File]::ReadAllBytes($outerLock)
$startedAtUtc = [DateTime]::UtcNow.ToString('o')
$completed = $false
try {
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile, "Partial-runner discovery $startedAtUtc", [Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($focusAck, "Partial-runner focus acknowledgement $startedAtUtc", [Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK = '1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = '1'
   & $runner -ManifestPath $manifest -PortableRoots $roots -UserAuthorizedFocusRisk `
      -OutputPrefix 'THREE_LANE_RV_PARTIAL_RUNNER_DISCOVERY_WORKER' `
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
if(!$completed) { throw 'Controlled partial-runner discovery did not complete.' }
if(!(Test-Path -LiteralPath $repoLock) -or !(Test-Path -LiteralPath $outerLock) -or
   @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw 'Controlled partial-runner discovery did not restore hard-lock state.'
}
[pscustomobject][ordered]@{
   Status = 'CONTROLLED_DISCOVERY_COMPLETE'
   StartedAtUtc = $startedAtUtc
   CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
   Configurations = 24
   Workers = 4
   MaxCpuPercent = $MaxCpuPercent
   LaunchLocksRestored = $true
   MT5Processes = 0
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
