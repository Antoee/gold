param(
   [string]$RawPath = "outputs\BLOCK_REASON_DIAGNOSTICS_RAW.csv",
   [string]$OutReasonSummary = "outputs\BLOCK_REASON_DIAGNOSTICS_REASON_SUMMARY.csv",
   [string]$OutLaneReasonSummary = "outputs\BLOCK_REASON_DIAGNOSTICS_LANE_REASON_SUMMARY.csv",
   [string]$OutWindowSummary = "outputs\BLOCK_REASON_DIAGNOSTICS_WINDOW_SUMMARY.csv",
   [string]$OutTopSignals = "outputs\BLOCK_REASON_DIAGNOSTICS_TOP_SIGNAL_REASONS.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if(!(Test-Path -LiteralPath $RawPath)) {
   throw "Missing raw block diagnostics: $RawPath"
}

$firstLine = Get-Content -LiteralPath $RawPath -TotalCount 1
$delimiter = if($firstLine -match "`t") { "`t" } else { "," }
$headers = @(
   "time",
   "symbol",
   "month",
   "day",
   "hour",
   "reason",
   "trend_bias",
   "signal_bias",
   "confirmations",
   "quality_score",
   "price_action_score",
   "lanes",
   "spread_points",
   "atr",
   "signal_reasons"
)
$rows = Import-Csv -LiteralPath $RawPath -Delimiter $delimiter -Header $headers |
   Where-Object { $_.time -and $_.time -ne "time" }

function Diagnostic-Window {
   param([string]$TimeText)
   if($TimeText -match '^(\d{4})[.\-/](\d{2})[.\-/](\d{2})') {
      return "{0}_{1}" -f $Matches[1], $Matches[2]
   }
   return "unknown"
}

function Normalize-Text {
   param([string]$Text)
   if([string]::IsNullOrWhiteSpace($Text)) { return "(blank)" }
   return $Text.Trim()
}

function To-IntOrZero {
   param($Value)
   $out = 0
   if([int]::TryParse(([string]$Value), [ref]$out)) { return $out }
   return 0
}

function To-DoubleOrZero {
   param($Value)
   $out = 0.0
   if([double]::TryParse(([string]$Value), [ref]$out)) { return $out }
   return 0.0
}

$enriched = foreach($row in $rows) {
   $reason = Normalize-Text $row.reason
   $lanes = Normalize-Text $row.lanes
   $signalBias = Normalize-Text $row.signal_bias
   $window = Diagnostic-Window $row.time
   $entered = $reason -like "entered*"
   $hasSignal = $signalBias -ne "none"
   [pscustomobject]@{
      Window = $window
      Reason = $reason
      Lanes = $lanes
      SignalBias = $signalBias
      HasSignal = $hasSignal
      Entered = $entered
      Confirmations = To-IntOrZero $row.confirmations
      QualityScore = To-IntOrZero $row.quality_score
      PriceActionScore = To-IntOrZero $row.price_action_score
      SpreadPoints = To-DoubleOrZero $row.spread_points
      ATR = To-DoubleOrZero $row.atr
      SignalReasons = Normalize-Text $row.signal_reasons
   }
}

$totalRows = [Math]::Max(1, @($enriched).Count)

$reasonSummary = $enriched |
   Group-Object Reason |
   ForEach-Object {
      $groupRows = @($_.Group)
      [pscustomobject]@{
         Reason = $_.Name
         Count = $groupRows.Count
         Percent = [math]::Round(100.0 * $groupRows.Count / $totalRows, 2)
         SignalRows = @($groupRows | Where-Object HasSignal).Count
         EnteredRows = @($groupRows | Where-Object Entered).Count
         AvgConfirmations = [math]::Round(($groupRows | Measure-Object Confirmations -Average).Average, 2)
         AvgQualityScore = [math]::Round(($groupRows | Measure-Object QualityScore -Average).Average, 2)
         AvgPriceActionScore = [math]::Round(($groupRows | Measure-Object PriceActionScore -Average).Average, 2)
         AvgSpreadPoints = [math]::Round(($groupRows | Measure-Object SpreadPoints -Average).Average, 2)
      }
   } |
   Sort-Object Count -Descending

$laneReasonSummary = $enriched |
   Group-Object Lanes, Reason |
   ForEach-Object {
      $groupRows = @($_.Group)
      [pscustomobject]@{
         Lanes = $groupRows[0].Lanes
         Reason = $groupRows[0].Reason
         Count = $groupRows.Count
         Percent = [math]::Round(100.0 * $groupRows.Count / $totalRows, 2)
         AvgQualityScore = [math]::Round(($groupRows | Measure-Object QualityScore -Average).Average, 2)
         AvgPriceActionScore = [math]::Round(($groupRows | Measure-Object PriceActionScore -Average).Average, 2)
      }
   } |
   Sort-Object Count -Descending

$windowSummary = $enriched |
   Group-Object Window |
   ForEach-Object {
      $groupRows = @($_.Group)
      $topReason = ($groupRows | Group-Object Reason | Sort-Object Count -Descending | Select-Object -First 1)
      $signalRows = @($groupRows | Where-Object HasSignal)
      [pscustomobject]@{
         Window = $_.Name
         Rows = $groupRows.Count
         SignalRows = $signalRows.Count
         EnteredRows = @($groupRows | Where-Object Entered).Count
         TopReason = $topReason.Name
         TopReasonCount = $topReason.Count
         AvgQualityScoreOnSignals = if($signalRows.Count -gt 0) { [math]::Round(($signalRows | Measure-Object QualityScore -Average).Average, 2) } else { 0 }
         AvgPriceActionScoreOnSignals = if($signalRows.Count -gt 0) { [math]::Round(($signalRows | Measure-Object PriceActionScore -Average).Average, 2) } else { 0 }
      }
   } |
   Sort-Object Window

$topSignalReasons = $enriched |
   Where-Object HasSignal |
   Group-Object SignalReasons |
   ForEach-Object {
      $groupRows = @($_.Group)
      [pscustomobject]@{
         SignalReasons = $_.Name
         Count = $groupRows.Count
         TopBlockReason = (($groupRows | Group-Object Reason | Sort-Object Count -Descending | Select-Object -First 1).Name)
         Lanes = (($groupRows | Group-Object Lanes | Sort-Object Count -Descending | Select-Object -First 1).Name)
         AvgQualityScore = [math]::Round(($groupRows | Measure-Object QualityScore -Average).Average, 2)
         AvgPriceActionScore = [math]::Round(($groupRows | Measure-Object PriceActionScore -Average).Average, 2)
      }
   } |
   Sort-Object Count -Descending |
   Select-Object -First 50

$reasonSummary | Export-Csv -LiteralPath $OutReasonSummary -NoTypeInformation
$laneReasonSummary | Export-Csv -LiteralPath $OutLaneReasonSummary -NoTypeInformation
$windowSummary | Export-Csv -LiteralPath $OutWindowSummary -NoTypeInformation
$topSignalReasons | Export-Csv -LiteralPath $OutTopSignals -NoTypeInformation

$reasonSummary | Select-Object -First 20
