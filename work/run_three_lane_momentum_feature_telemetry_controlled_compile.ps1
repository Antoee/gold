[CmdletBinding()]
param(
   [ValidateRange(1,100)][int]$MaxCpuPercent=80,
   [switch]$UserAuthorizedFocusRisk,
   [string]$SourceRelativePath='outputs\three_lane_momentum_feature_telemetry_model1_package\source\Professional_XAUUSD_EA.mq5',
   [string]$ExpectedSourceHash='14F40409A6865F081774AEE18FEEC3E0F22ED1833F8ECAB54DD4BD852A3AD14B',
   [string]$AuditRelativePath='outputs\THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_COMPILE_AUDIT.csv'
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk){throw 'Controlled compile requires explicit focus/window-risk authorization.'}
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork=Split-Path -Parent $repo
$source=Join-Path $repo $SourceRelativePath
$preparer=Join-Path $PSScriptRoot 'prepare_mt5_portable_shared_expert.ps1'
$repoLock=Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock=Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$unlockFile=Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'
$focusAck=Join-Path $PSScriptRoot 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'
$auditPath=Join-Path $repo $AuditRelativePath
$roots=@(
   (Join-Path $sharedWork 'mt5_portable_research'),
   (Join-Path $sharedWork 'mt5_portable_research_w2'),
   (Join-Path $sharedWork 'mt5_portable_research_w3'),
   (Join-Path $sharedWork 'mt5_portable_research_w4')
)
foreach($required in @($source,$preparer,$repoLock,$outerLock)){if(!(Test-Path -LiteralPath $required -PathType Leaf)){throw "Controlled compile prerequisite missing: $required"}}
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash){throw 'Momentum feature-telemetry source identity changed.'}
if((Test-Path -LiteralPath $unlockFile) -or (Test-Path -LiteralPath $focusAck) -or $env:ALLOW_MT5_FOCUS_RISK -eq '1' -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq '1'){throw 'Controlled compile refuses a pre-existing partial unlock state.'}
if(@(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0){throw 'Controlled compile requires all MT5-family processes stopped.'}

$repoLockBytes=[IO.File]::ReadAllBytes($repoLock);$outerLockBytes=[IO.File]::ReadAllBytes($outerLock)
$startedAtUtc=[DateTime]::UtcNow.ToString('o');$compileResult=$null
try{
   [IO.File]::Delete($repoLock);[IO.File]::Delete($outerLock)
   [IO.File]::WriteAllText($unlockFile,"Momentum feature-telemetry compile $startedAtUtc",[Text.Encoding]::ASCII)
   [IO.File]::WriteAllText($focusAck,"Momentum feature-telemetry focus acknowledgement $startedAtUtc",[Text.Encoding]::ASCII)
   $env:ALLOW_MT5_FOCUS_RISK='1';$env:ALLOW_MT5_HIDDEN_DESKTOP_ACK='1'
   $compileOutput=@(& $preparer -SourcePath $source -ExpectedSourceSha256 $expectedSourceHash -PortableRoots $roots -MaxCpuPercent $MaxCpuPercent -CompileTimeoutMinutes 5 -UserAuthorizedFocusRisk)
   $candidates=@($compileOutput|Where-Object{$_.PSObject.Properties.Name -contains 'PortableBinarySha256'})
   if($candidates.Count){$compileResult=$candidates[-1]}
}finally{
   Remove-Item -LiteralPath $unlockFile,$focusAck -Force -ErrorAction SilentlyContinue
   Remove-Item Env:ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue;Remove-Item Env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   [IO.File]::WriteAllBytes($repoLock,$repoLockBytes);[IO.File]::WriteAllBytes($outerLock,$outerLockBytes)
   Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue
}
if($null -eq $compileResult -or [string]::IsNullOrWhiteSpace([string]$compileResult.PortableBinarySha256)){throw 'Controlled compile did not produce a shared binary.'}
$binaryRows=@($roots|ForEach-Object{
   $installedSource=Join-Path $_ 'MQL5\Experts\Professional_XAUUSD_EA.mq5'
   $installedBinary=Join-Path $_ 'MQL5\Experts\Professional_XAUUSD_EA.ex5'
   $identityPath=Join-Path $_ 'MQL5\Experts\Professional_XAUUSD_EA.compiled_identity.txt'
   $identity=@(Get-Content -LiteralPath $identityPath)
   $sourceHash=(Get-FileHash -LiteralPath $installedSource -Algorithm SHA256).Hash.ToUpperInvariant()
   $binaryHash=(Get-FileHash -LiteralPath $installedBinary -Algorithm SHA256).Hash.ToUpperInvariant()
   [pscustomobject]@{SourceSha256=$sourceHash;BinarySha256=$binaryHash;IdentityReady=$identity.Count -ge 2 -and $identity[0] -eq $sourceHash -and $identity[1] -eq $binaryHash}
})
$binaryHashes=@($binaryRows|Where-Object IdentityReady|Select-Object -ExpandProperty BinarySha256 -Unique)
if($binaryRows.Count -ne 4 -or $binaryHashes.Count -ne 1){throw 'Controlled compile binary identity is not exact across all four workers.'}
if(!(Test-Path -LiteralPath $repoLock) -or !(Test-Path -LiteralPath $outerLock) -or @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -ne 0){throw 'Controlled compile did not restore hard-lock state.'}
$audit=[pscustomobject][ordered]@{Status='COMPILE_PASS';StartedAtUtc=$startedAtUtc;CompletedAtUtc=[DateTime]::UtcNow.ToString('o');SourceSha256=$expectedSourceHash;PortableBinarySha256=$binaryHashes[0];Workers=$binaryRows.Count;CompileErrors=0;CompileWarnings=0;LaunchLocksRestored=$true;MT5Processes=0;ForwardCandidateChanged=$false;RealAccountApproved=$false}
$audit|Export-Csv -LiteralPath $auditPath -NoTypeInformation -Encoding ASCII
$audit
