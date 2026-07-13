$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tempRoot = Join-Path $repo ("work\fmlr_probe_builder_test_{0}" -f $PID)
$packageDir = Join-Path $tempRoot "package"
$conservativeSet = Join-Path $tempRoot "CANDIDATE_FMLR_CONSERVATIVE_PROFILE.set"
$balancedSet = Join-Path $tempRoot "CANDIDATE_FMLR_BALANCED_PROFILE.set"
$vwapSet = Join-Path $tempRoot "CANDIDATE_FMLR_VWAP_DISCOVERY_PROFILE.set"
$manifestPath = Join-Path $repo "outputs\FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_MANIFEST.csv"
$manifestBackup = $null

function Assert-True {
   param([bool]$Condition, [string]$Message)
   if(!$Condition) { throw $Message }
}

try {
   if(Test-Path -LiteralPath $manifestPath) {
      $manifestBackup = Get-Content -LiteralPath $manifestPath -Raw
   }
   New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\build_flat_month_liquidity_reclaim_probe_package.ps1") `
      -PackageDir $packageDir `
      -ConservativeSetPath $conservativeSet `
      -BalancedSetPath $balancedSet `
      -VwapDiscoverySetPath $vwapSet `
      -Model 4 | Out-Null

   $expectedPath = Join-Path $packageDir "EXPECTED_REPORTS.csv"
   Assert-True (Test-Path -LiteralPath $expectedPath) "Missing EXPECTED_REPORTS.csv"
   $expected = @(Import-Csv -LiteralPath $expectedPath)
   Assert-True ($expected.Count -eq 48) "Expected 48 FMLR configs, got $($expected.Count)"

   $profiles = @($expected | Select-Object -ExpandProperty Profile -Unique | Sort-Object)
   foreach($profile in @("fmlr_balanced", "fmlr_conservative", "fmlr_vwap_discovery", "lowatr_current")) {
      Assert-True ($profiles -contains $profile) "Missing profile $profile"
   }

   $balancedText = Get-Content -LiteralPath $balancedSet -Raw
   Assert-True ($balancedText.Contains("InpUseFlatMonthLiquidityReclaimLane=true||true||0||0||N")) "Balanced set does not enable FMLR lane"
   Assert-True ($balancedText.Contains("InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter=true||true||0||0||N")) "Balanced set does not enable FMLR month-filter bypass"
   Assert-True ($balancedText.Contains("InpUseAdaptiveReverse=false||false||0||0||N")) "Balanced set must keep Adaptive Reverse disabled"

   $vwapText = Get-Content -LiteralPath $vwapSet -Raw
   Assert-True ($vwapText.Contains("InpFlatMonthLiquidityReclaimRiskMultiplier=0.12||0.12||0||0||N")) "VWAP discovery risk multiplier changed"
   Assert-True ($vwapText.Contains("InpFlatMonthLiquidityReclaimRequireVWAPReclaim=true||true||0||0||N")) "VWAP discovery must require VWAP reclaim"

   $sampleConfig = Get-ChildItem -LiteralPath (Join-Path $packageDir "configs") -Filter "*fmlr_balanced*.ini" | Select-Object -First 1
   Assert-True ($null -ne $sampleConfig) "Missing fmlr_balanced config"
   $sampleText = Get-Content -LiteralPath $sampleConfig.FullName -Raw
   Assert-True ($sampleText.Contains("Model=4")) "Generated config is not Model4"
   Assert-True ($sampleText.Contains("InpFlatMonthLiquidityReclaimMinRR=0.90||0.90||0||0||N")) "Generated config missing balanced min RR"

   "FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS"
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
   if($null -ne $manifestBackup) {
      Set-Content -LiteralPath $manifestPath -Value $manifestBackup -Encoding ASCII
   }
   else {
      Remove-Item -LiteralPath $manifestPath -Force -ErrorAction SilentlyContinue
   }
}
