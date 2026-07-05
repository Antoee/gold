param(
   [string]$OutputsDir = "outputs",
   [string]$OutCsv = "outputs\LOSS_CONTROL_RANKING.csv",
   [string]$OutReport = "outputs\LOSS_CONTROL_REPORT.md",
   [int]$MinHeadlineWindows = 7
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function To-Double {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return 0.0 }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-Field {
   param([object]$Row, [string[]]$Names, [object]$Default = $null)
   foreach($name in $Names) {
      if($Row.PSObject.Properties.Name -contains $name) { return $Row.$name }
   }
   return $Default
}

function Get-ProfileName {
   param([System.IO.FileInfo]$File, [object]$Row)
   $candidate = Get-Field -Row $Row -Names @("Candidate", "Profile") -Default $null
   if(![string]::IsNullOrWhiteSpace([string]$candidate)) { return [string]$candidate }

   $name = $File.BaseName
   $name = $name -replace "_WINDOWS$", ""
   $name = $name -replace "_SPLITS$", ""
   $name = $name -replace "_QUARTERS$", ""
   $name = $name -replace "_MONTHLY$", ""
   return $name
}

function Get-WindowSet {
   param([System.IO.FileInfo]$File, [object]$Row)
   $set = Get-Field -Row $Row -Names @("Set") -Default $null
   if(![string]::IsNullOrWhiteSpace([string]$set)) { return [string]$set }
   if($File.BaseName -match "SPLIT|SPLITS") { return "split" }
   if($File.BaseName -match "QUARTER|QUARTERS") { return "quarter" }
   if($File.BaseName -match "MONTH|MONTHLY") { return "month" }
   return "window"
}

function Get-MaxSequentialDrawdown {
   param([object[]]$Rows)
   $equity = 0.0
   $peak = 0.0
   $maxDrawdown = 0.0
   foreach($row in $Rows) {
      $equity += [double]$row.NetProfit
      if($equity -gt $peak) { $peak = $equity }
      $drawdown = $peak - $equity
      if($drawdown -gt $maxDrawdown) { $maxDrawdown = $drawdown }
   }
   return [Math]::Round($maxDrawdown, 2)
}

if(!(Test-Path -LiteralPath $OutputsDir)) {
   throw "Outputs directory not found: $OutputsDir"
}

$windowRows = New-Object System.Collections.Generic.List[object]

Get-ChildItem -LiteralPath $OutputsDir -Filter "*.csv" -File |
   Where-Object { $_.Name -notmatch "SUMMARY|RANKING|PROBES|FULL_REAL_TICK_DEFAULT" } |
   ForEach-Object {
      $file = $_
      try { $rows = Import-Csv -LiteralPath $file.FullName }
      catch { return }

      foreach($row in $rows) {
         if(!($row.PSObject.Properties.Name -contains "NetProfit")) { continue }
         $profile = Get-ProfileName -File $file -Row $row
         $set = Get-WindowSet -File $file -Row $row
         $window = Get-Field -Row $row -Names @("Window", "Name") -Default $file.BaseName
         $from = [string](Get-Field -Row $row -Names @("From") -Default "")
         $to = [string](Get-Field -Row $row -Names @("To") -Default "")
         $net = To-Double (Get-Field -Row $row -Names @("NetProfit") -Default 0)

         $windowRows.Add([pscustomobject]@{
            Profile = $profile
            Set = $set
            Window = [string]$window
            From = $from
            To = $to
            NetProfit = [Math]::Round($net, 2)
            SourceFile = $file.Name
         }) | Out-Null
      }
   }

$ranked = New-Object System.Collections.Generic.List[object]

foreach($group in ($windowRows | Group-Object Profile, Set, SourceFile)) {
   $rows = @($group.Group | Sort-Object From, Window)
   if($rows.Count -eq 0) { continue }

   $profits = @($rows | ForEach-Object { [double]$_.NetProfit })
   $total = ($profits | Measure-Object -Sum).Sum
   $worst = ($profits | Measure-Object -Minimum).Minimum
   $best = ($profits | Measure-Object -Maximum).Maximum
   $losing = @($profits | Where-Object { $_ -lt 0 }).Count
   $flat = @($profits | Where-Object { $_ -eq 0 }).Count
   $winning = @($profits | Where-Object { $_ -gt 0 }).Count
   $grossLoss = [Math]::Abs(($profits | Where-Object { $_ -lt 0 } | Measure-Object -Sum).Sum)
   $maxSeqDd = Get-MaxSequentialDrawdown -Rows $rows
   $profitToLoss = if($grossLoss -gt 0) { [Math]::Round($total / $grossLoss, 2) } else { 999.0 }
   $profitToDd = if($maxSeqDd -gt 0) { [Math]::Round($total / $maxSeqDd, 2) } else { 999.0 }
   $sourceText = (($rows | Select-Object -ExpandProperty SourceFile -Unique) -join ";")
   $strategyClass = if(($rows[0].Profile -match "DATE|BLOCK|SECOND_BUY|SELL_BLOCK") -or ($sourceText -match "DATE|BLOCK|SECOND_BUY|SELL_BLOCK")) {
      "DateBlockBenchmark"
   }
   else {
      "GeneralCandidate"
   }

   $coveragePenalty = if($rows.Count -lt $MinHeadlineWindows) { ($MinHeadlineWindows - $rows.Count) * 750.0 } else { 0.0 }
   $lossPenalty = $losing * 2500.0
   $worstPenalty = if($worst -lt 0) { [Math]::Abs($worst) * 8.0 } else { 0.0 }
   $ddPenalty = $maxSeqDd * 2.0
   $flatPenalty = $flat * 4.0
   $score = $total - $lossPenalty - $worstPenalty - $ddPenalty - $flatPenalty - $coveragePenalty + ($winning * 20.0)
   $coverage = if($rows.Count -ge $MinHeadlineWindows) { "ValidatedWindowSet" } else { "ThinCoverage" }

   $ranked.Add([pscustomobject]@{
      Rank = 0
      LossControlScore = [Math]::Round($score, 2)
      Coverage = $coverage
      StrategyClass = $strategyClass
      Profile = ($rows[0].Profile)
      Set = ($rows[0].Set)
      Windows = $rows.Count
      TotalNetProfit = [Math]::Round($total, 2)
      WorstWindowNetProfit = [Math]::Round($worst, 2)
      BestWindowNetProfit = [Math]::Round($best, 2)
      WinningWindows = $winning
      FlatWindows = $flat
      LosingWindows = $losing
      GrossLoss = [Math]::Round($grossLoss, 2)
      MaxSequentialWindowDrawdown = $maxSeqDd
      ProfitToGrossLoss = $profitToLoss
      ProfitToWindowDrawdown = $profitToDd
      SourceFiles = $sourceText
   }) | Out-Null
}

$ordered = $ranked |
   Sort-Object `
      @{ Expression = "LosingWindows"; Descending = $false },
      @{ Expression = { if($_.Coverage -eq "ValidatedWindowSet") { 0 } else { 1 } }; Descending = $false },
      @{ Expression = "WorstWindowNetProfit"; Descending = $true },
      @{ Expression = "LossControlScore"; Descending = $true },
      @{ Expression = "TotalNetProfit"; Descending = $true }

$rank = 1
$ordered = foreach($row in $ordered) {
   $row.Rank = $rank
   $rank++
   $row
}

$ordered | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$topNoLoss = @($ordered | Where-Object { $_.Coverage -eq "ValidatedWindowSet" -and $_.StrategyClass -eq "GeneralCandidate" -and $_.LosingWindows -eq 0 -and $_.TotalNetProfit -gt 0 } | Select-Object -First 12)
$topResearch = @($ordered | Where-Object { $_.Coverage -eq "ValidatedWindowSet" -and $_.StrategyClass -eq "GeneralCandidate" -and $_.LosingWindows -le 1 -and $_.TotalNetProfit -gt 0 } | Select-Object -First 12)
$dateBlockBenchmarks = @($ordered | Where-Object { $_.Coverage -eq "ValidatedWindowSet" -and $_.StrategyClass -eq "DateBlockBenchmark" -and $_.LosingWindows -le 1 -and $_.TotalNetProfit -gt 0 } | Select-Object -First 8)
$thinBenchmarks = @($ordered | Where-Object { $_.Coverage -eq "ThinCoverage" -and $_.LosingWindows -eq 0 -and $_.TotalNetProfit -gt 0 } | Select-Object -First 8)

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Loss-Control Ranking") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated from existing CSV result windows only. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("This report prioritizes profiles that make money while avoiding losing windows. Headline tables require at least $MinHeadlineWindows windows, so one-off probes cannot outrank validated profiles.") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Best General No-Loss Profiles") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Profile | Set | Total | Worst | Losing | Max Seq DD | Profit/DD | Windows |") | Out-Null
$report.Add("| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |") | Out-Null
foreach($row in $topNoLoss) {
   $report.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Set) | $($row.TotalNetProfit) | $($row.WorstWindowNetProfit) | $($row.LosingWindows) | $($row.MaxSequentialWindowDrawdown) | $($row.ProfitToWindowDrawdown) | $($row.Windows) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Best Low-Loss Research Profiles") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Profile | Set | Total | Worst | Losing | Gross Loss | Profit/Loss | Windows |") | Out-Null
$report.Add("| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |") | Out-Null
foreach($row in $topResearch) {
   $report.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Set) | $($row.TotalNetProfit) | $($row.WorstWindowNetProfit) | $($row.LosingWindows) | $($row.GrossLoss) | $($row.ProfitToGrossLoss) | $($row.Windows) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Date-Block Benchmarks") | Out-Null
$report.Add("") | Out-Null
$report.Add("These can be useful profit references, but they should not be promoted unless replaced by general market-regime rules.") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Profile | Set | Total | Worst | Losing | Windows |") | Out-Null
$report.Add("| ---: | --- | --- | ---: | ---: | ---: | ---: |") | Out-Null
foreach($row in $dateBlockBenchmarks) {
   $report.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Set) | $($row.TotalNetProfit) | $($row.WorstWindowNetProfit) | $($row.LosingWindows) | $($row.Windows) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Thin-Coverage Benchmarks") | Out-Null
$report.Add("") | Out-Null
$report.Add("These are useful clues, not promotion candidates, because they have too few windows.") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Profile | Set | Total | Worst | Losing | Windows |") | Out-Null
$report.Add("| ---: | --- | --- | ---: | ---: | ---: | ---: |") | Out-Null
foreach($row in $thinBenchmarks) {
   $report.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Set) | $($row.TotalNetProfit) | $($row.WorstWindowNetProfit) | $($row.LosingWindows) | $($row.Windows) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Rule Of Thumb") | Out-Null
$report.Add("") | Out-Null
$report.Add("For the updated goal, do not promote a profile with any losing monthly, quarterly, or split windows unless it clearly beats the no-loss profile on profit and has a very small worst loss.") | Out-Null

Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8

$ordered | Select-Object -First 15
