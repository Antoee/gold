$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tempRoot = Join-Path $repo ("work\fmlr_compact_test_{0}" -f $PID)
$packageDir = Join-Path $tempRoot "package"
$compactSource = Join-Path $tempRoot "FMLR_COMPACT.mq5"
$compactAudit = Join-Path $tempRoot "FMLR_COMPACT_AUDIT.csv"
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

   $result = powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\prepare_flat_month_liquidity_reclaim_compact_source.ps1") `
      -PackageDir $packageDir `
      -CompactSourcePath $compactSource `
      -CompactAuditPath $compactAudit `
      -MaxKeptInputs 450

   Assert-True (Test-Path -LiteralPath $compactSource) "Missing compact source."
   Assert-True (Test-Path -LiteralPath $compactAudit) "Missing compact audit."

   $audit = @(Import-Csv -LiteralPath $compactAudit)
   $kept = [int](($audit | Where-Object { $_.Metric -eq "KeptInputCount" } | Select-Object -First 1).Value)
   $converted = [int](($audit | Where-Object { $_.Metric -eq "ConvertedToGlobals" } | Select-Object -First 1).Value)
   Assert-True ($kept -gt 0 -and $kept -le 450) "Unexpected kept input count: $kept"
   Assert-True ($converted -gt 0) "Expected compact source to convert inactive inputs to globals."

   $sourceText = Get-Content -LiteralPath $compactSource -Raw
   Assert-True ($sourceText.Contains("input bool            InpUseFlatMonthLiquidityReclaimLane")) "FMLR lane input was not retained."
   Assert-True ($sourceText.Contains("input bool            InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter")) "FMLR bypass input was not retained."
   Assert-True ($sourceText.Contains("input bool            InpFlatMonthLiquidityReclaimUseLiquidityTarget")) "FMLR liquidity target input was not retained."
   Assert-True ($sourceText.Contains("input double          InpFlatMonthLiquidityReclaimMaxTargetATR")) "FMLR liquidity target max ATR input was not retained."
   Assert-True (!$sourceText.Contains("input bool            InpUseWinnerScaleIn")) "Unrelated winner scale-in input was retained."

   $expected = @(Import-Csv -LiteralPath (Join-Path $packageDir "EXPECTED_REPORTS.csv"))
   Assert-True ($expected.Count -eq 60) "Expected 60 package configs, got $($expected.Count)"

   "FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS"
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
