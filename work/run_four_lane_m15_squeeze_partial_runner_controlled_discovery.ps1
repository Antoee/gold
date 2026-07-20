[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent=80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig=8,
   [switch]$UserAuthorizedFocusRisk,
   [string]$ManifestPath='outputs\FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$OutputPrefix='FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_WORKER'
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk){throw 'Controlled squeeze partial-runner discovery requires explicit focus/window-risk authorization.'}
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path;$sharedWork=Split-Path -Parent $repo
$repoLock=Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock';$outerLock=Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock';$unlockFile=Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock';$focusAck=Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock';$runner=Join-Path $PSScriptRoot 'run_mt5_portable_parallel_manifest.ps1'
$candidate=if([IO.Path]::IsPathRooted($ManifestPath)){$ManifestPath}else{Join-Path $repo $ManifestPath};$manifest=(Resolve-Path -LiteralPath $candidate).Path;$main=(Resolve-Path -LiteralPath (Join-Path $repo 'outputs\FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_MODEL1_MANIFEST.csv')).Path
$source=Join-Path $repo 'outputs\four_lane_m15_squeeze_partial_runner_discovery_model1_package\source\Professional_XAUUSD_EA.mq5';$expectedManifestHash='A6BA5855A67F090B20CC9E895EC81070402DE75F3E01D6011FE32663F6FD266E';$expectedSourceHash='1E05D5E8A9283EC34EC9F8116E21C363E4D100BE782065E87DDDC90CCC3E6005';$expectedBinaryHash='405665BCE71400E067AD6DE80CFA4CAEE4C937C2F916F05A1545327DAAE2E4B1'
$roots=@((Join-Path $sharedWork 'mt5_portable_research'),(Join-Path $sharedWork 'mt5_portable_research_w2'),(Join-Path $sharedWork 'mt5_portable_research_w3'),(Join-Path $sharedWork 'mt5_portable_research_w4'))
if($manifest.Equals($main,[StringComparison]::OrdinalIgnoreCase)){if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash){throw 'Main manifest identity changed.'}}
else{$roots=@($roots[0]);$rows=@(Import-Csv -LiteralPath $manifest);$mainRows=@(Import-Csv -LiteralPath $main);if($rows.Count -lt 1){throw 'Recovery manifest is empty.'};foreach($row in $rows){$match=@($mainRows|Where-Object QueueRank -eq $row.QueueRank);if($match.Count -ne 1 -or $row.ConfigSha256 -ne $match[0].ConfigSha256 -or $row.SourceSha256 -ne $expectedSourceHash){throw "Recovery changed rank $($row.QueueRank)."}}}
foreach($required in @($repoLock,$outerLock,$runner,$manifest,$source)+$roots){if(!(Test-Path -LiteralPath $required)){throw "Discovery prerequisite missing: $required"}}
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash){throw 'Package source identity changed.'}
foreach($root in $roots){$binary=Join-Path $root 'MQL5\Experts\Professional_XAUUSD_EA.ex5';if(!(Test-Path -LiteralPath $binary -PathType Leaf) -or (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedBinaryHash){throw "Portable binary mismatch: $root"}}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $focusAck) -or $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1'){throw 'Discovery refuses a pre-existing partial unlock state.'}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0){throw 'Discovery requires zero pre-existing MT5 processes.'}
$repoLockBytes=[IO.File]::ReadAllBytes($repoLock);$outerLockBytes=[IO.File]::ReadAllBytes($outerLock);$started=[DateTime]::UtcNow.ToString('o');$complete=$false
try{
   [IO.File]::Delete($repoLock);[IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile,"Squeeze partial-runner discovery $started",[Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($focusAck,"Squeeze partial-runner focus acknowledgement $started",[Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK='1';$env:ALLOW_MT5_HIDDEN_DESKTOP_ACK='1'
   & $runner -ManifestPath $manifest -PortableRoots $roots -UserAuthorizedFocusRisk -OutputPrefix $OutputPrefix -MaxCpuPercent $MaxCpuPercent -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig -ExpectedPortableBinarySha256 $expectedBinaryHash -ProgressIntervalSeconds 10
   $complete=$true
}
finally{
   Remove-Item -LiteralPath $unlockFile,$focusAck -Force -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue;Remove-Item Env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   [IO.File]::WriteAllBytes($repoLock,$repoLockBytes);[IO.File]::WriteAllBytes($outerLock,$outerLockBytes)
   Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue
}
if(!$complete){throw 'Controlled squeeze partial-runner discovery did not complete.'}
if(!(Test-Path -LiteralPath $repoLock) -or !(Test-Path -LiteralPath $outerLock) -or @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0){throw 'Discovery did not restore hard-lock state.'}
[pscustomobject][ordered]@{Status='CONTROLLED_DISCOVERY_COMPLETE';StartedAtUtc=$started;CompletedAtUtc=[DateTime]::UtcNow.ToString('o');Configurations=@(Import-Csv -LiteralPath $manifest).Count;Workers=$roots.Count;MaxCpuPercent=$MaxCpuPercent;LaunchLocksRestored=$true;MT5Processes=0;ForwardCandidateChanged=$false;RealAccountApproved=$false}
