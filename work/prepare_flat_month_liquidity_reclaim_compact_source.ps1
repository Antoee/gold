param(
   [string]$PackageDir = "outputs\flat_month_liquidity_reclaim_probe_package",
   [string]$CompactSourcePath = "outputs\FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT.mq5",
   [string]$CompactAuditPath = "outputs\FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_AUDIT.csv",
   [int]$MaxKeptInputs = 450
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

function Get-AuditValue {
   param($Rows, [string]$Metric)
   $row = $Rows | Where-Object { $_.Metric -eq $Metric } | Select-Object -First 1
   if($null -eq $row) { return $null }
   return $row.Value
}

powershell -NoProfile -ExecutionPolicy Bypass -File work\build_flat_month_liquidity_reclaim_probe_package.ps1 `
   -PackageDir $PackageDir

powershell -NoProfile -ExecutionPolicy Bypass -File work\build_tester_compact_ea_source.ps1 `
   -SourcePath outputs\Professional_XAUUSD_EA.mq5 `
   -ConfigDir (Join-Path $PackageDir "configs") `
   -OutSourcePath $CompactSourcePath `
   -OutCsv $CompactAuditPath | Out-Null

if(!(Test-Path -LiteralPath $CompactSourcePath)) {
   throw "Compact source was not created: $CompactSourcePath"
}
if(!(Test-Path -LiteralPath $CompactAuditPath)) {
   throw "Compact audit was not created: $CompactAuditPath"
}

$sourceText = Get-Content -LiteralPath $CompactSourcePath -Raw
foreach($needle in @(
   "input bool            InpUseFlatMonthLiquidityReclaimLane",
   "input bool            InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter",
   "input double          InpFlatMonthLiquidityReclaimRiskMultiplier",
   "input bool            InpFlatMonthLiquidityReclaimRequireOrderFlow",
   "input bool            InpFlatMonthLiquidityReclaimRequireVWAPReclaim",
   "input double          InpFlatMonthLiquidityReclaimMinRR",
   "input bool            InpFlatMonthLiquidityReclaimUseLiquidityTarget",
   "input double          InpFlatMonthLiquidityReclaimMaxTargetATR"
)) {
   if($sourceText.IndexOf($needle, [StringComparison]::Ordinal) -lt 0) {
      throw "Compact source missing required FMLR input: $needle"
   }
}

if($sourceText.IndexOf("input bool            InpUseWinnerScaleIn", [StringComparison]::Ordinal) -ge 0) {
   throw "Compact source kept unrelated InpUseWinnerScaleIn input; compacting is too broad."
}

$auditRows = @(Import-Csv -LiteralPath $CompactAuditPath)
$kept = [int](Get-AuditValue -Rows $auditRows -Metric "KeptInputCount")
$converted = [int](Get-AuditValue -Rows $auditRows -Metric "ConvertedToGlobals")
if($kept -le 0) { throw "Compact audit kept-input count is invalid." }
if($kept -gt $MaxKeptInputs) {
   throw "Compact source kept too many tester inputs: $kept > $MaxKeptInputs"
}

[pscustomobject]@{
   PackageDir = $PackageDir
   CompactSourcePath = $CompactSourcePath
   CompactAuditPath = $CompactAuditPath
   KeptInputCount = $kept
   ConvertedToGlobals = $converted
}
