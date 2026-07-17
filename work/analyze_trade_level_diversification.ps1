param(
   [Parameter(Mandatory = $true)][string]$PrimaryTrades,
   [Parameter(Mandatory = $true)][string]$SecondaryTrades,
   [string]$PrimaryLabel = "primary",
   [string]$SecondaryLabel = "secondary",
   [ValidateRange(0.0001,1000.0)][double]$PrimaryRiskWeight = 1.0,
   [ValidateRange(0.0001,1000.0)][double]$SecondaryRiskWeight = 1.0,
   [ValidateRange(0.0,10.0)][double]$StressRPerTrade = 0.0,
   [string]$SecondaryEntrySubtype = "",
   [ValidateRange(0,1440)][int]$DuplicateToleranceMinutes = 0,
   [switch]$ExcludeSecondaryDuplicates,
   [string]$OutTrades = "outputs\TRADE_DIVERSIFICATION_EVENTS.csv",
   [string]$OutMonthly = "outputs\TRADE_DIVERSIFICATION_MONTHLY.csv",
   [string]$OutAnnual = "outputs\TRADE_DIVERSIFICATION_ANNUAL.csv",
   [string]$OutSummary = "outputs\TRADE_DIVERSIFICATION_SUMMARY.csv",
   [string]$OutMarkdown = "outputs\TRADE_DIVERSIFICATION_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Ensure-ParentDir {
   param([string]$Path)
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

function Get-FirstField {
   param([object]$Row, [string[]]$Names)
   foreach($name in $Names) {
      $property = $Row.PSObject.Properties[$name]
      if($null -ne $property -and ![string]::IsNullOrWhiteSpace([string]$property.Value)) {
         return [string]$property.Value
      }
   }
   return ""
}

function Convert-ToDouble {
   param([string]$Value, [string]$FieldName)
   $number = 0.0
   $normalized = ([string]$Value).Replace(",", "").Trim()
   if(![double]::TryParse($normalized, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
      throw "Could not parse $FieldName value '$Value'."
   }
   return $number
}

function Import-NormalizedTrades {
   param(
      [string]$Path,
      [string]$Label,
      [double]$Weight,
      [double]$StressR,
      [string]$SubtypeFilter = ""
   )

   $resolved = Resolve-RepoPath $Path
   if(!(Test-Path -LiteralPath $resolved)) { throw "Trade CSV not found: $resolved" }
   $sourceRows = @(Import-Csv -LiteralPath $resolved)
   $normalized = [System.Collections.Generic.List[object]]::new()
   $index = 0

   foreach($row in $sourceRows) {
      $subtype = Get-FirstField $row @("EntrySubtype", "Lane")
      if(![string]::IsNullOrWhiteSpace($SubtypeFilter) -and $subtype -ne $SubtypeFilter) { continue }

      $entryText = Get-FirstField $row @("EntryTime")
      $exitText = Get-FirstField $row @("ExitTime", "CloseTime")
      $riskText = Get-FirstField $row @("RiskR", "RealizedR")
      if([string]::IsNullOrWhiteSpace($entryText) -or [string]::IsNullOrWhiteSpace($exitText) -or [string]::IsNullOrWhiteSpace($riskText)) {
         throw "Trade row in '$Path' is missing EntryTime, ExitTime/CloseTime, or RiskR/RealizedR."
      }

      $entry = [datetime]::Parse($entryText, [Globalization.CultureInfo]::InvariantCulture)
      $exit = [datetime]::Parse($exitText, [Globalization.CultureInfo]::InvariantCulture)
      $riskR = Convert-ToDouble $riskText "realized R"
      $profitText = Get-FirstField $row @("Profit")
      $profit = if([string]::IsNullOrWhiteSpace($profitText)) { 0.0 } else { Convert-ToDouble $profitText "profit" }
      $side = (Get-FirstField $row @("Side", "Bias")).ToLowerInvariant()
      $index++

      $normalized.Add([pscustomobject]@{
         Id = "${Label}:$index"
         Strategy = $Label
         EntryTime = $entry
         ExitTime = $exit
         EntryYear = $entry.Year
         EntryMonth = $entry.ToString("yyyy-MM")
         Side = $side
         EntrySubtype = $subtype
         RiskR = [math]::Round($riskR, 6)
         RiskWeight = $Weight
         WeightedR = [math]::Round(($riskR - $StressR) * $Weight, 6)
         Profit = [math]::Round($profit, 2)
      }) | Out-Null
   }

   if($normalized.Count -eq 0) { throw "No trades remained after loading '$Path'." }
   return @($normalized)
}

function Get-PearsonCorrelation {
   param([double[]]$X, [double[]]$Y)
   if($X.Count -ne $Y.Count -or $X.Count -lt 2) { return 0.0 }
   $meanX = ($X | Measure-Object -Average).Average
   $meanY = ($Y | Measure-Object -Average).Average
   $numerator = 0.0
   $sumX = 0.0
   $sumY = 0.0
   for($i = 0; $i -lt $X.Count; $i++) {
      $dx = $X[$i] - $meanX
      $dy = $Y[$i] - $meanY
      $numerator += $dx * $dy
      $sumX += $dx * $dx
      $sumY += $dy * $dy
   }
   if($sumX -le 0.0 -or $sumY -le 0.0) { return 0.0 }
   return $numerator / [math]::Sqrt($sumX * $sumY)
}

function Get-WeightedRSum {
   param([object[]]$Rows)
   $items = @($Rows)
   if($items.Count -eq 0) { return 0.0 }
   return [double](($items | Measure-Object -Property WeightedR -Sum).Sum)
}

$primary = @(Import-NormalizedTrades -Path $PrimaryTrades -Label $PrimaryLabel -Weight $PrimaryRiskWeight -StressR $StressRPerTrade)
$secondary = @(Import-NormalizedTrades -Path $SecondaryTrades -Label $SecondaryLabel -Weight $SecondaryRiskWeight -StressR $StressRPerTrade -SubtypeFilter $SecondaryEntrySubtype)

$duplicateRows = [System.Collections.Generic.List[object]]::new()
$duplicateSecondaryIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($p in $primary) {
   foreach($s in $secondary) {
      $minutes = [math]::Abs(($p.EntryTime - $s.EntryTime).TotalMinutes)
      if($p.Side -eq $s.Side -and $minutes -le $DuplicateToleranceMinutes) {
         $duplicateSecondaryIds.Add($s.Id) | Out-Null
         $duplicateRows.Add([pscustomobject]@{
            PrimaryId = $p.Id
            SecondaryId = $s.Id
            PrimaryEntry = $p.EntryTime.ToString("s")
            SecondaryEntry = $s.EntryTime.ToString("s")
            Side = $p.Side
            MinutesApart = [math]::Round($minutes, 2)
         }) | Out-Null
      }
   }
}

$acceptedSecondary = @(if($ExcludeSecondaryDuplicates) {
   $secondary | Where-Object { !$duplicateSecondaryIds.Contains($_.Id) }
} else {
   $secondary
})

$overlapPairs = 0
$overlappingPrimaryIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$overlappingSecondaryIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($p in $primary) {
   foreach($s in $acceptedSecondary) {
      if($p.EntryTime -le $s.ExitTime -and $s.EntryTime -le $p.ExitTime) {
         $overlapPairs++
         $overlappingPrimaryIds.Add($p.Id) | Out-Null
         $overlappingSecondaryIds.Add($s.Id) | Out-Null
      }
   }
}

$allTrades = @($primary + $acceptedSecondary | Sort-Object ExitTime, Strategy, Id)
$equity = 0.0
$peak = 0.0
$maxDrawdown = 0.0
$maxLossStreak = 0
$lossStreak = 0
$grossWin = 0.0
$grossLoss = 0.0
$eventRows = [System.Collections.Generic.List[object]]::new()

foreach($trade in $allTrades) {
   $equity += $trade.WeightedR
   if($equity -gt $peak) { $peak = $equity }
   $drawdown = $peak - $equity
   if($drawdown -gt $maxDrawdown) { $maxDrawdown = $drawdown }
   if($trade.WeightedR -gt 0.0) {
      $grossWin += $trade.WeightedR
      $lossStreak = 0
   }
   elseif($trade.WeightedR -lt 0.0) {
      $grossLoss += [math]::Abs($trade.WeightedR)
      $lossStreak++
      if($lossStreak -gt $maxLossStreak) { $maxLossStreak = $lossStreak }
   }

   $eventRows.Add([pscustomobject]@{
      Id = $trade.Id
      Strategy = $trade.Strategy
      EntryTime = $trade.EntryTime.ToString("s")
      ExitTime = $trade.ExitTime.ToString("s")
      Side = $trade.Side
      EntrySubtype = $trade.EntrySubtype
      RiskR = $trade.RiskR
      RiskWeight = $trade.RiskWeight
      WeightedR = $trade.WeightedR
      CombinedEquityR = [math]::Round($equity, 6)
      CombinedDrawdownR = [math]::Round($drawdown, 6)
   }) | Out-Null
}

$exposureEvents = [System.Collections.Generic.List[object]]::new()
foreach($trade in $allTrades) {
   $exposureEvents.Add([pscustomobject]@{ Time = $trade.EntryTime; Order = 1; CountDelta = 1; RiskDelta = $trade.RiskWeight }) | Out-Null
   $exposureEvents.Add([pscustomobject]@{ Time = $trade.ExitTime; Order = 0; CountDelta = -1; RiskDelta = -$trade.RiskWeight }) | Out-Null
}
$openCount = 0
$openRisk = 0.0
$maxOpenCount = 0
$maxOpenRisk = 0.0
foreach($event in ($exposureEvents | Sort-Object Time, Order)) {
   $openCount += $event.CountDelta
   $openRisk += $event.RiskDelta
   if($openCount -gt $maxOpenCount) { $maxOpenCount = $openCount }
   if($openRisk -gt $maxOpenRisk) { $maxOpenRisk = $openRisk }
}

$firstMonth = ($allTrades | Sort-Object EntryTime | Select-Object -First 1).EntryTime
$lastMonth = ($allTrades | Sort-Object EntryTime | Select-Object -Last 1).EntryTime
$cursor = [datetime]::new($firstMonth.Year, $firstMonth.Month, 1)
$lastCursor = [datetime]::new($lastMonth.Year, $lastMonth.Month, 1)
$monthlyRows = [System.Collections.Generic.List[object]]::new()
while($cursor -le $lastCursor) {
   $next = $cursor.AddMonths(1)
   $primaryR = Get-WeightedRSum @($primary | Where-Object { $_.EntryTime -ge $cursor -and $_.EntryTime -lt $next })
   $secondaryR = Get-WeightedRSum @($acceptedSecondary | Where-Object { $_.EntryTime -ge $cursor -and $_.EntryTime -lt $next })
   $monthlyRows.Add([pscustomobject]@{
      Month = $cursor.ToString("yyyy-MM")
      PrimaryWeightedR = [math]::Round($primaryR, 6)
      SecondaryWeightedR = [math]::Round($secondaryR, 6)
      CombinedWeightedR = [math]::Round($primaryR + $secondaryR, 6)
   }) | Out-Null
   $cursor = $next
}

$monthlyCorrelation = Get-PearsonCorrelation `
   -X @($monthlyRows | ForEach-Object { [double]$_.PrimaryWeightedR }) `
   -Y @($monthlyRows | ForEach-Object { [double]$_.SecondaryWeightedR })

$years = @($allTrades.EntryYear | Sort-Object -Unique)
$annualRows = [System.Collections.Generic.List[object]]::new()
foreach($year in $years) {
   $primaryR = Get-WeightedRSum @($primary | Where-Object EntryYear -eq $year)
   $secondaryR = Get-WeightedRSum @($acceptedSecondary | Where-Object EntryYear -eq $year)
   $annualRows.Add([pscustomobject]@{
      Year = $year
      PrimaryWeightedR = [math]::Round($primaryR, 6)
      SecondaryWeightedR = [math]::Round($secondaryR, 6)
      CombinedWeightedR = [math]::Round($primaryR + $secondaryR, 6)
   }) | Out-Null
}

$netPrimaryR = Get-WeightedRSum $primary
$netSecondaryR = Get-WeightedRSum $acceptedSecondary
$secondaryExclusiveR = Get-WeightedRSum @($secondary | Where-Object { !$duplicateSecondaryIds.Contains($_.Id) })
$profitFactor = if($grossLoss -gt 0.0) { $grossWin / $grossLoss } elseif($grossWin -gt 0.0) { [double]::PositiveInfinity } else { 0.0 }
$redYears = @($annualRows | Where-Object { [double]$_.CombinedWeightedR -lt 0.0 }).Count

$summary = [pscustomobject]@{
   Primary = $PrimaryLabel
   Secondary = $SecondaryLabel
   SecondarySubtypeFilter = $SecondaryEntrySubtype
   PrimaryTrades = $primary.Count
   SecondaryInputTrades = $secondary.Count
   SecondaryTrades = $acceptedSecondary.Count
   DuplicateExclusionEnabled = [bool]$ExcludeSecondaryDuplicates
   ExcludedSecondaryTrades = $secondary.Count - $acceptedSecondary.Count
   PrimaryRiskWeight = $PrimaryRiskWeight
   SecondaryRiskWeight = $SecondaryRiskWeight
   StressRPerTrade = $StressRPerTrade
   PrimaryNetWeightedR = [math]::Round($netPrimaryR, 6)
   SecondaryNetWeightedR = [math]::Round($netSecondaryR, 6)
   CombinedNetWeightedR = [math]::Round($netPrimaryR + $netSecondaryR, 6)
   CombinedProfitFactor = [math]::Round($profitFactor, 4)
   CombinedMaxDrawdownR = [math]::Round($maxDrawdown, 6)
   CombinedMaxLossStreak = $maxLossStreak
   ExactDuplicatePairs = $duplicateRows.Count
   SecondaryExclusiveWeightedR = [math]::Round($secondaryExclusiveR, 6)
   OverlappingPositionPairs = $overlapPairs
   PrimaryTradesWithOverlap = $overlappingPrimaryIds.Count
   SecondaryTradesWithOverlap = $overlappingSecondaryIds.Count
   MonthlyCorrelation = [math]::Round($monthlyCorrelation, 4)
   MaxConcurrentTrades = $maxOpenCount
   MaxConcurrentRiskUnits = [math]::Round($maxOpenRisk, 4)
   RedCombinedYears = $redYears
   Verdict = "SCREEN_ONLY_NOT_COMBINED_MT5_PROOF"
}

$outTradesPath = Resolve-RepoPath $OutTrades
$outMonthlyPath = Resolve-RepoPath $OutMonthly
$outAnnualPath = Resolve-RepoPath $OutAnnual
$outSummaryPath = Resolve-RepoPath $OutSummary
$outMarkdownPath = Resolve-RepoPath $OutMarkdown
foreach($path in @($outTradesPath, $outMonthlyPath, $outAnnualPath, $outSummaryPath, $outMarkdownPath)) { Ensure-ParentDir $path }

$eventRows | Export-Csv -LiteralPath $outTradesPath -NoTypeInformation -Encoding ASCII
$monthlyRows | Export-Csv -LiteralPath $outMonthlyPath -NoTypeInformation -Encoding ASCII
$annualRows | Export-Csv -LiteralPath $outAnnualPath -NoTypeInformation -Encoding ASCII
$summary | Export-Csv -LiteralPath $outSummaryPath -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Trade-Level Diversification Screen")
$md.Add("")
$md.Add("This is a fixed-R analytical merge of existing trade histories. It is not a combined MT5 backtest and cannot be treated as an achievable account return.")
$md.Add("")
$md.Add(('- Primary: `{0}` ({1} trades, weight {2})' -f $PrimaryLabel, $primary.Count, $PrimaryRiskWeight))
$md.Add(('- Secondary: `{0}` ({1} accepted of {2} input trades, weight {3})' -f $SecondaryLabel, $acceptedSecondary.Count, $secondary.Count, $SecondaryRiskWeight))
$md.Add(("- Secondary subtype filter: {0}" -f $(if([string]::IsNullOrWhiteSpace($SecondaryEntrySubtype)) { "none" } else { $SecondaryEntrySubtype })))
$md.Add(('- Duplicate exclusion: `{0}` ({1} secondary trades excluded within {2} minutes)' -f ([bool]$ExcludeSecondaryDuplicates), ($secondary.Count - $acceptedSecondary.Count), $DuplicateToleranceMinutes))
$md.Add(('- Per-trade execution stress: `{0:N4}R` before risk weighting' -f $StressRPerTrade))
$md.Add(('- Combined net: `{0:N4}R`' -f ($netPrimaryR + $netSecondaryR)))
$md.Add(('- Combined PF: `{0:N4}`' -f $profitFactor))
$md.Add(('- Combined max drawdown: `{0:N4}R`' -f $maxDrawdown))
$md.Add(('- Combined maximum loss streak: `{0}`' -f $maxLossStreak))
$md.Add(('- Red combined years: `{0}`' -f $redYears))
$md.Add(('- Monthly R correlation: `{0:N4}`' -f $monthlyCorrelation))
$md.Add(('- Exact duplicate entry pairs: `{0}`' -f $duplicateRows.Count))
$md.Add(('- Overlapping position pairs: `{0}`' -f $overlapPairs))
$md.Add(('- Maximum concurrent trades / risk units: `{0}` / `{1:N2}`' -f $maxOpenCount, $maxOpenRisk))
$md.Add("")
$md.Add("## Annual Weighted R")
$md.Add("")
$md.Add("| Year | Primary | Secondary | Combined |")
$md.Add("| ---: | ---: | ---: | ---: |")
foreach($row in $annualRows) {
   $md.Add(("| {0} | {1:N4} | {2:N4} | {3:N4} |" -f $row.Year, $row.PrimaryWeightedR, $row.SecondaryWeightedR, $row.CombinedWeightedR))
}
$md.Add("")
$md.Add("## Interpretation")
$md.Add("")
$md.Add("A useful partner must add independent positive R without creating red broad years or excessive simultaneous exposure. Low correlation alone is not enough. Any surviving screen still requires one combined-EA MT5 test, cost stress, annual gates, forward evidence, and another broker.")
$md | Set-Content -LiteralPath $outMarkdownPath -Encoding ASCII

$summary
