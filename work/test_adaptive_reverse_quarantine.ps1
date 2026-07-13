$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$rootSourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$canonicalSourcePath = Join-Path $repo "outputs\Professional_XAUUSD_EA.mq5"

function Assert-True {
   param([bool]$Condition, [string]$Message)
   if(!$Condition) { throw $Message }
}

Assert-True (Test-Path -LiteralPath $rootSourcePath) "Missing root EA source."
Assert-True (Test-Path -LiteralPath $canonicalSourcePath) "Missing canonical EA source."

$rootHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $rootSourcePath).Hash
$canonicalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $canonicalSourcePath).Hash
Assert-True ($rootHash -eq $canonicalHash) "Root and canonical EA sources differ."

$source = Get-Content -LiteralPath $canonicalSourcePath -Raw

Assert-True ($source.Contains("bool                  InpUseAdaptiveReverse        = false;")) "Adaptive Reverse must remain internally disabled by default."
Assert-True (!$source.Contains("input bool            InpUseAdaptiveReverse")) "Adaptive Reverse must not be optimizer-visible."

foreach($needle in @(
   "bool                  InpUseAdaptiveReverseWhipsawGuard = true;",
   "bool                  InpUseAdaptiveReverseLossCooldown = true;",
   "bool                  InpUseAdaptiveReverseRecentFlipCooldown = true;",
   "bool                  InpUseAdaptiveReversePostStopLockout = true;",
   "bool                  InpAdaptiveReverseBlockRangePhase = true;",
   "bool                  InpAdaptiveReverseRequireTrendPhase = true;",
   "bool                  InpUseAdaptiveReverseLiquidityTrapGuard = true;",
   "bool                  InpUseAdaptiveReverseLiquidityClearance = true;",
   "bool                  InpUseAdaptiveReverseFollowThroughClose = true;"
)) {
   Assert-True ($source.Contains($needle)) "Missing strict Adaptive Reverse guard default: $needle"
}

foreach($needle in @(
   "AdaptiveReverseLossCooldownActive",
   "AdaptiveReverseRecentFlipCooldownActive",
   "AdaptiveReversePostStopLockoutActive",
   "AdaptiveReverseLiquidityTrapGuardActive",
   "AdaptiveReverseLiquidityClearanceAllows",
   "AdaptiveReverseFollowThroughCloseAllows",
   "InpAdaptiveReverseBlockRangePhase",
   "InpAdaptiveReverseRequireTrendPhase",
   "!AdaptiveReverseWhipsawGuardAllows"
)) {
   Assert-True ($source.Contains($needle)) "Adaptive Reverse guard path missing: $needle"
}

"ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS"
