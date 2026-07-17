param(
   [string]$SourcePath = "work\Professional_XAUUSD_EA_REVERSION_INDEPENDENT.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
$text = Get-Content -LiteralPath $sourceFull -Raw

$required = @(
   'input bool            InpBandVWAPReversionIndependentAttempt = false;',
   'bool bandIndependentAttempt = InpUseBandVWAPReversionLane &&',
   '!bandIndependentAttempt && bandReversionSignal.bias != BIAS_NONE',
   'bool bandIndependentSessionAllowed = bandIndependentAttempt &&',
   'if(bandIndependentSessionAllowed)',
   'bool bandOpened = OpenIsolatedBandVWAPReversionSignal(bandReversionSignal);',
   'openedPosition = openedPosition || bandOpened;',
   'riskManager.LotsForRisk(signal.bias, entry, stopDistance, riskMultiplier)',
   'riskManager.ExposureAllows(signal.bias, entry, stopDistance, lots, exposureReason)',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Missing source contract token: $token" }
}

if($text.IndexOf('InpBandVWAPReversionIndependentAttempt = true;', [StringComparison]::Ordinal) -ge 0) {
   throw "Independent reversion scheduling must remain default off."
}

$maintainedHash = (Get-FileHash -LiteralPath (Join-Path $repo "Professional_XAUUSD_EA.mq5") -Algorithm SHA256).Hash
$frozenHash = (Get-FileHash -LiteralPath (Join-Path $repo "work\Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5") -Algorithm SHA256).Hash
if($maintainedHash -ne 'A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622') { throw "Maintained source identity changed." }
if($frozenHash -ne '45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90') { throw "Frozen three-lane source identity changed." }

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
   IndependentAttemptDefault = $false
   MaintainedSourceIntact = $true
   FrozenSourceIntact = $true
   RealTradingDefault = $false
}
