[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent=80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig=8,
   [switch]$UserAuthorizedFocusRisk,
   [switch]$SingleWorkerRecovery
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk){throw 'Controlled NR7 discovery requires explicit focus/window-risk authorization.'}
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork=Split-Path -Parent $repo
$repoLock=Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock=Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$unlockFile=Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'
$focusAck=Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'
$runner=Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$manifest=Join-Path $repo 'outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_MANIFEST.csv'
$source=Join-Path $repo 'outputs\independent_d1_nr7_h1_breakout_discovery_model1_package\source\Professional_XAUUSD_EA.mq5'
$expectedManifestHash='60AA7774A9939CEC678816747644FAAE2198BDE80FE4F597B7D78F0D256A133A'
$expectedSourceHash='BBFC4214F63658B7D2D22109AC0C536D32A23693C471179DB0E07EA70C974880'
$expectedBinaryHash='CC80BEE04EAC8B2669A1BBF44C79C57500C2BC6CF5EA8A9196ECA11778AA7D72'
$roots=@(
   (Join-Path $sharedWork 'mt5_portable_research'),
   (Join-Path $sharedWork 'mt5_portable_research_w2'),
   (Join-Path $sharedWork 'mt5_portable_research_w3'),
   (Join-Path $sharedWork 'mt5_portable_research_w4')
)
if($SingleWorkerRecovery){
   $roots=@($roots[0])
   $manifest=Join-Path $repo 'outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RECOVERY_MANIFEST.csv'
   $expectedManifestHash='C994296C116B41CED7CF17EF5B3EC526CB3BC1DA701C430A4E4EF5E363A4E268'
}
foreach($required in @($repoLock,$outerLock,$runner,$manifest,$source)+$roots){if(!(Test-Path -LiteralPath $required)){throw "Controlled NR7 prerequisite missing: $required"}}
if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash){throw 'NR7 manifest identity changed.'}
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash){throw 'NR7 package source identity changed.'}
foreach($root in $roots){
   $binary=Join-Path $root 'MQL5\Experts\Professional_XAUUSD_EA.ex5'
   if(!(Test-Path -LiteralPath $binary -PathType Leaf) -or (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedBinaryHash){throw "Portable binary identity mismatch: $root"}
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $focusAck) -or $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1'){throw 'Controlled NR7 discovery refuses a pre-existing partial unlock state.'}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0){throw 'Controlled NR7 discovery requires zero pre-existing MT5-family processes.'}

$repoLockBytes=[IO.File]::ReadAllBytes($repoLock)
$outerLockBytes=[IO.File]::ReadAllBytes($outerLock)
$startedAtUtc=[DateTime]::UtcNow.ToString('o')
$completed=$false
try{
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile,"NR7 discovery $startedAtUtc",[Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($focusAck,"NR7 focus acknowledgement $startedAtUtc",[Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK='1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK='1'
   & $runner -ManifestPath $manifest -PortableRoots $roots -UserAuthorizedFocusRisk `
      -OutputPrefix $(if($SingleWorkerRecovery){'INDEPENDENT_D1_NR7_H1_BREAKOUT_RECOVERY'}else{'INDEPENDENT_D1_NR7_H1_BREAKOUT_WORKER'}) `
      -MaxCpuPercent $MaxCpuPercent -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -ExpectedPortableBinarySha256 $expectedBinaryHash -ProgressIntervalSeconds 10
   $completed=$true
}finally{
   Remove-Item -LiteralPath $unlockFile,$focusAck -Force -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   [IO.File]::WriteAllBytes($repoLock,$repoLockBytes)
   [IO.File]::WriteAllBytes($outerLock,$outerLockBytes)
   Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue
}
if(!$completed){throw 'Controlled NR7 discovery did not complete.'}
if(!(Test-Path -LiteralPath $repoLock) -or !(Test-Path -LiteralPath $outerLock) -or @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0){throw 'Controlled NR7 discovery did not restore hard-lock state.'}
[pscustomobject][ordered]@{Status='CONTROLLED_DISCOVERY_COMPLETE';StartedAtUtc=$startedAtUtc;CompletedAtUtc=[DateTime]::UtcNow.ToString('o');Configurations=@(Import-Csv -LiteralPath $manifest).Count;Workers=$roots.Count;MaxCpuPercent=$MaxCpuPercent;LaunchLocksRestored=$true;MT5Processes=0;ForwardCandidateChanged=$false;RealAccountApproved=$false}
