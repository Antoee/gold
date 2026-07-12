param(
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_PROFILE.set",
   [string]$OutSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE.set"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$inputs = Import-SetInputs $BaseSetPath
$overrides = @{
   InpUseRangeReversionOpportunity = "true"
   InpRangeReversionMinScore = "9"
   InpWeightRangeReversionOpportunity = "2"
   InpRangeReversionStandaloneEntry = "true"
   InpRangeReversionMaxADX = "20.0"
   InpRangeReversionMinWickPercent = "42.0"
   InpRangeReversionMinCloseLocation = "0.66"
   InpRangeReversionMinRangeATR = "0.42"
   InpRangeReversionRequireVWAPMagnet = "true"
   InpRangeReversionMaxVWAPDistanceATR = "1.05"
   InpRangeReversionRequireOrderFlow = "true"
   InpRangeReversionUseStructuralStop = "true"
   InpRangeReversionStopBufferATR = "0.08"
   InpRangeReversionStopBufferPoints = "18.0"
   InpRangeReversionUseMeanTarget = "true"
   InpRangeReversionFallbackTPATR = "0.85"
   InpRangeReversionMinRR = "0.85"
   InpRangeReversionUseCustomEliteGate = "true"
   InpRangeReversionEliteMinConfirmations = "3"
   InpRangeReversionEliteMinQualityScore = "7"
}

foreach($entry in $overrides.GetEnumerator()) {
   Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
}

$lines = foreach($key in ($inputs.Keys | Sort-Object)) {
   $inputs[$key]
}

Set-Content -LiteralPath $OutSetPath -Value $lines -Encoding ASCII
Get-FileHash -LiteralPath $OutSetPath -Algorithm SHA256
