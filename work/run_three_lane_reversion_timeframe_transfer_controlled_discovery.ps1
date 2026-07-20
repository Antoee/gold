[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent=80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig=8,
   [switch]$UserAuthorizedFocusRisk,
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$OutputPrefix='THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_WORKER'
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk){throw 'Controlled timeframe-transfer discovery requires explicit focus/window-risk authorization.'}
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork=Split-Path -Parent $repo
$repoLock=Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock=Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$unlockFile=Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'
$focusAck=Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'
$runner=Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$manifestCandidate=if([IO.Path]::IsPathRooted($ManifestPath)){$ManifestPath}else{Join-Path $repo $ManifestPath}
$manifest=(Resolve-Path -LiteralPath $manifestCandidate).Path
$source=Join-Path $repo 'outputs\three_lane_reversion_timeframe_transfer_discovery_model1_package\source\Professional_XAUUSD_EA.mq5'
$expectedMainManifestHash='F691742DDFC5AA980F0395D8D9B41B77B3F676977CD3C6B99E6648672A206F10'
$expectedSourceHash='B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedBinaryHash='D9B60597A7D44D142FD9283147B1C32BED61B7A4A7FD4EA2462D6E59439719B4'
$roots=@(
   (Join-Path $sharedWork 'mt5_portable_research'),
   (Join-Path $sharedWork 'mt5_portable_research_w2'),
   (Join-Path $sharedWork 'mt5_portable_research_w3'),
   (Join-Path $sharedWork 'mt5_portable_research_w4')
)
$mainManifest=(Resolve-Path -LiteralPath (Join-Path $repo 'outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_MODEL1_MANIFEST.csv')).Path
$isMain=$manifest.Equals($mainManifest,[StringComparison]::OrdinalIgnoreCase)
if($isMain){
   if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedMainManifestHash){throw 'Timeframe-transfer manifest identity changed.'}
}else{
   $roots=@($roots[0])
   $rows=@(Import-Csv -LiteralPath $manifest)
   $mainRows=@(Import-Csv -LiteralPath $mainManifest)
   if($rows.Count -lt 1){throw 'Recovery manifest is empty.'}
   foreach($row in $rows){
      $match=@($mainRows|Where-Object QueueRank -eq $row.QueueRank)
      if($match.Count -ne 1 -or $row.ConfigSha256 -ne $match[0].ConfigSha256 -or $row.SourceSha256 -ne $expectedSourceHash){throw "Recovery manifest changed frozen rank $($row.QueueRank)."}
   }
}
foreach($required in @($repoLock,$outerLock,$runner,$manifest,$source)+$roots){if(!(Test-Path -LiteralPath $required)){throw "Controlled timeframe-transfer prerequisite missing: $required"}}
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash){throw 'Timeframe-transfer package source identity changed.'}
foreach($root in $roots){
   $binary=Join-Path $root 'MQL5\Experts\Professional_XAUUSD_EA.ex5'
   if(!(Test-Path -LiteralPath $binary -PathType Leaf) -or (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedBinaryHash){throw "Portable binary identity mismatch: $root"}
}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $focusAck) -or $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1'){throw 'Controlled timeframe-transfer discovery refuses a pre-existing partial unlock state.'}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0){throw 'Controlled timeframe-transfer discovery requires zero pre-existing MT5-family processes.'}

$repoLockBytes=[IO.File]::ReadAllBytes($repoLock)
$outerLockBytes=[IO.File]::ReadAllBytes($outerLock)
$startedAtUtc=[DateTime]::UtcNow.ToString('o')
$completed=$false
try{
   [IO.File]::Delete($repoLock)
   [IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile,"Timeframe-transfer discovery $startedAtUtc",[Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($focusAck,"Timeframe-transfer focus acknowledgement $startedAtUtc",[Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK='1'
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK='1'
   & $runner -ManifestPath $manifest -PortableRoots $roots -UserAuthorizedFocusRisk `
      -OutputPrefix $OutputPrefix -MaxCpuPercent $MaxCpuPercent `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
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
if(!$completed){throw 'Controlled timeframe-transfer discovery did not complete.'}
if(!(Test-Path -LiteralPath $repoLock) -or !(Test-Path -LiteralPath $outerLock) -or @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0){throw 'Controlled timeframe-transfer discovery did not restore hard-lock state.'}
[pscustomobject][ordered]@{Status='CONTROLLED_DISCOVERY_COMPLETE';StartedAtUtc=$startedAtUtc;CompletedAtUtc=[DateTime]::UtcNow.ToString('o');Configurations=@(Import-Csv -LiteralPath $manifest).Count;Workers=$roots.Count;MaxCpuPercent=$MaxCpuPercent;LaunchLocksRestored=$true;MT5Processes=0;ForwardCandidateChanged=$false;RealAccountApproved=$false}
