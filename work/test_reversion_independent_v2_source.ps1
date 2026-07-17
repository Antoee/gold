param(
   [string]$SourcePath = "work\Professional_XAUUSD_EA_REVERSION_INDEPENDENT_V2.mq5",
   [string]$V1SourcePath = "work\Professional_XAUUSD_EA_REVERSION_INDEPENDENT.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }

$sourceFull = Resolve-RepoPath $SourcePath
$v1Full = Resolve-RepoPath $V1SourcePath
$text = Get-Content -LiteralPath $sourceFull -Raw
$required = @(
   'input bool            InpBandVWAPReversionIndependentAttempt = false;',
   'int CountIndependentReversionSlotPositions(const bool bandSlot)',
   'bool IndependentReversionSlotAllows(const bool bandSlot, string &reason)',
   'StringFind(comment, "RRO;Band VWAP reversion") >= 0',
   'reason = bandSlot ? "band reversion slot occupied" : "primary strategy slot occupied";',
   'if(!IndependentReversionSlotAllows(true, blockReason))',
   'if(!IndependentReversionSlotAllows(false, blockReason))',
   'riskManager.ExposureAllows(signal.bias, entry, stopDistance, lots, exposureReason)',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Missing corrected source contract token: $token" }
}

if(([regex]::Matches($text, [regex]::Escape('if(!IndependentReversionSlotAllows(false, blockReason))'))).Count -ne 2) {
   throw "Primary slot guard must protect both isolated D1 and ordinary primary entries."
}
if($text.IndexOf('InpBandVWAPReversionIndependentAttempt = true;', [StringComparison]::Ordinal) -ge 0) {
   throw "Independent reversion scheduling must remain default off."
}

$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$v1Hash = (Get-FileHash -LiteralPath $v1Full -Algorithm SHA256).Hash
$maintainedHash = (Get-FileHash -LiteralPath (Join-Path $repo "Professional_XAUUSD_EA.mq5") -Algorithm SHA256).Hash
$frozenHash = (Get-FileHash -LiteralPath (Join-Path $repo "work\Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5") -Algorithm SHA256).Hash
if($sourceHash -ne '55E2AA9750880146B07A821CC773C8F4C71F21981F41E03EB4D1121602410363') { throw "Unexpected corrected source hash: $sourceHash" }
if($v1Hash -ne '2108099D19EBF2E8D86709FFAA37331559EDA745794E1B01A1A4DA0C6C38CEEB') { throw "Published V1 source identity changed." }
if($maintainedHash -ne 'A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622') { throw "Maintained source identity changed." }
if($frozenHash -ne '45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90') { throw "Frozen three-lane source identity changed." }

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = $sourceHash
   V1SourceIntact = $true
   PrimarySlotLimit = 1
   BandSlotLimit = 1
   RealTradingDefault = $false
}
