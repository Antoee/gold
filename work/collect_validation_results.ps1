param(
   [string]$RepoRoot = (Resolve-Path ".").Path,
   [string]$ManifestPath = "work\generated_validation\VALIDATION_MANIFEST.csv",
   [string]$ReportDir = "outputs",
   [string]$ReportNameTemplate = "validation_{Profile}_{Set}_{Window}",
   [string]$OutResults = "outputs\VALIDATION_REPORT_METRICS.csv",
   [string]$OutSummary = "outputs\VALIDATION_REPORT_SUMMARY.csv",
   [string]$OutMarkdown = "outputs\VALIDATION_REPORT_METRICS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-ToNumber {
   param([AllowNull()][string]$Value)

   if([string]::IsNullOrWhiteSpace($Value)) { return $null }
   $clean = $Value -replace '&nbsp;', ' '
   $clean = $clean -replace '<[^>]+>', ''
   $clean = [System.Net.WebUtility]::HtmlDecode($clean)
   $clean = $clean -replace '[,$%]', ''
   $clean = $clean -replace '\s+', ' '
   $clean = $clean.Trim()
   $match = [regex]::Match($clean, '[-+]?\d+(?:\.\d+)?')
   if(!$match.Success) { return $null }
   return [double]::Parse($match.Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Normalize-ReportText {
   param([string]$Path)

   $raw = Get-Content -LiteralPath $Path -Raw
   $text = [System.Net.WebUtility]::HtmlDecode($raw)
   $text = $text -replace '(?is)<script.*?</script>', ' '
   $text = $text -replace '(?is)<style.*?</style>', ' '
   $text = $text -replace '(?i)</t[dh]>\s*<t[dh][^>]*>', "`t"
   $text = $text -replace '(?i)</tr\s*>', "`n"
   $text = $text -replace '<[^>]+>', ' '
   $text = $text -replace '&nbsp;', ' '
   $text = $text -replace '\r', "`n"
   $text = $text -replace '[ \t]+', ' '
   $text = $text -replace '\n+', "`n"
   return $text
}

function Read-Metric {
   param(
      [string]$Text,
      [string[]]$Labels
   )

   foreach($label in $Labels) {
      $escaped = [regex]::Escape($label)
      $patterns = @(
         "$escaped\s*[:\t ]+\s*([-+]?\d[\d,]*(?:\.\d+)?%?)",
         "$escaped.*?([-+]?\d[\d,]*(?:\.\d+)?%?)"
      )

      foreach($pattern in $patterns) {
         $match = [regex]::Match($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
         if($match.Success) {
            $value = Convert-ToNumber $match.Groups[1].Value
            if($null -ne $value) { return $value }
         }
      }
   }

   return $null
}

function Read-MetricPercent {
   param(
      [string]$Text,
      [string[]]$Labels
   )

   foreach($label in $Labels) {
      $escaped = [regex]::Escape($label)
      $patterns = @(
         "$escaped\s*(?:\(\s*%\s*\))?\s*[:\t ]+\s*[-+]?\d[\d,]*(?:\.\d+)?\s*\(\s*([-+]?\d[\d,]*(?:\.\d+)?)\s*%\s*\)",
         "$escaped\s*(?:\(\s*%\s*\))?\s*[:\t ]+\s*([-+]?\d[\d,]*(?:\.\d+)?)\s*%",
         "$escaped.*?\(\s*([-+]?\d[\d,]*(?:\.\d+)?)\s*%\s*\)"
      )

      foreach($pattern in $patterns) {
         $match = [regex]::Match($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
         if($match.Success) {
            $value = Convert-ToNumber $match.Groups[1].Value
            if($null -ne $value) { return $value }
         }
      }
   }

   return $null
}

function Convert-ManifestDate {
   param([AllowNull()][string]$Value)

   if([string]::IsNullOrWhiteSpace($Value)) { return $null }
   $clean = ([string]$Value).Trim()
   $formats = @("yyyy.MM.dd", "yyyy-MM-dd", "yyyy/MM/dd", "yyyyMMdd")
   $culture = [Globalization.CultureInfo]::InvariantCulture
   $styles = [Globalization.DateTimeStyles]::AssumeLocal
   $parsed = [DateTime]::MinValue
   foreach($format in $formats) {
      if([DateTime]::TryParseExact($clean, $format, $culture, $styles, [ref]$parsed)) {
         return $parsed.Date
      }
   }
   if([DateTime]::TryParse($clean, $culture, $styles, [ref]$parsed)) {
      return $parsed.Date
   }
   return $null
}

function Get-CalendarDays {
   param([AllowNull()][string]$From, [AllowNull()][string]$To)

   $fromDate = Convert-ManifestDate $From
   $toDate = Convert-ManifestDate $To
   if($null -eq $fromDate -or $null -eq $toDate) { return $null }
   $days = ($toDate - $fromDate).TotalDays
   if($days -lt 0) { return $null }
   if($days -eq 0) { return 1 }
   return [int][Math]::Round($days, 0)
}

function Get-ReturnMetrics {
   param(
      [AllowNull()][object]$NetProfit,
      [AllowNull()][object]$Balance,
      [double]$InitialDeposit,
      [AllowNull()][object]$CalendarDays
   )

   $years = $null
   if($null -ne $CalendarDays -and [double]$CalendarDays -gt 0) {
      $years = [double]$CalendarDays / 365.25
   }

   $totalReturnPercent = $null
   if($null -ne $NetProfit -and $InitialDeposit -gt 0) {
      $totalReturnPercent = ([double]$NetProfit / $InitialDeposit) * 100.0
   }

   $annualizedReturnPercent = $null
   if($null -ne $totalReturnPercent -and $null -ne $years -and $years -gt 0) {
      $annualizedReturnPercent = $totalReturnPercent / $years
   }

   $cagrPercent = $null
   if($null -ne $Balance -and $InitialDeposit -gt 0 -and $null -ne $years -and $years -gt 0) {
      $balanceDouble = [double]$Balance
      if($balanceDouble -gt 0) {
         $cagrPercent = ([Math]::Pow(($balanceDouble / $InitialDeposit), (1.0 / $years)) - 1.0) * 100.0
      } elseif($balanceDouble -eq 0) {
         $cagrPercent = -100.0
      }
   }

   return [pscustomobject]@{
      Years = $years
      TotalReturnPercent = $totalReturnPercent
      AnnualizedReturnPercent = $annualizedReturnPercent
      CagrPercent = $cagrPercent
   }
}

function Get-ReportStem {
   param(
      [string]$Template,
      [object]$ManifestRow
   )

   $phase = Get-RowValue -Row $ManifestRow -Name "Phase"
   $phaseShort = if($phase -like "phase1*") { "phase1" } elseif($phase -like "phase2*") { "phase2" } else { $phase }
   $profile = Get-RowValue -Row $ManifestRow -Name "Profile"
   $set = Get-RowValue -Row $ManifestRow -Name "Set"
   $window = Get-RowValue -Row $ManifestRow -Name "Window"
   $expectedReportName = Get-RowValue -Row $ManifestRow -Name "ExpectedReportName"
   return $Template.
      Replace("{ExpectedReportName}", $expectedReportName).
      Replace("{Phase}", $phase).
      Replace("{PhaseShort}", $phaseShort).
      Replace("{Profile}", $profile).
      Replace("{Set}", $set).
      Replace("{Window}", $window)
}

function Find-Report {
   param(
      [string]$Root,
      [object]$ManifestRow,
      [string]$Template
   )

   $base = Get-ReportStem -Template $Template -ManifestRow $ManifestRow
   $candidates = @(
      (Join-Path $Root $base),
      (Join-Path $Root ($base + ".htm")),
      (Join-Path $Root ($base + ".html")),
      (Join-Path $Root ($base + ".xml"))
   )

   foreach($candidate in $candidates) {
      if(Test-Path -LiteralPath $candidate -PathType Leaf) {
         return (Resolve-Path -LiteralPath $candidate).Path
      }
   }

   $wild = Get-ChildItem -LiteralPath $Root -File -ErrorAction SilentlyContinue |
      Where-Object { $_.BaseName -eq $base -or $_.Name -like "$base.*" } |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1
   if($wild) { return $wild.FullName }
   return $null
}

function Get-RowValue {
   param(
      [object]$Row,
      [string]$Name
   )

   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return "" }
   return [string]$property.Value
}

function Read-ValidationReport {
   param(
      [string]$Path,
      [object]$ManifestRow
   )

   $priority = Get-RowValue -Row $ManifestRow -Name "Priority"
   $phase = Get-RowValue -Row $ManifestRow -Name "Phase"
   $profile = Get-RowValue -Row $ManifestRow -Name "Profile"
   $set = Get-RowValue -Row $ManifestRow -Name "Set"
   $window = Get-RowValue -Row $ManifestRow -Name "Window"
   $from = Get-RowValue -Row $ManifestRow -Name "From"
   $to = Get-RowValue -Row $ManifestRow -Name "To"
   $rank = Get-RowValue -Row $ManifestRow -Name "Rank"
   $expectedReportName = Get-RowValue -Row $ManifestRow -Name "ExpectedReportName"
   $initialDeposit = 1000.0
   $manifestInitialDeposit = Get-RowValue -Row $ManifestRow -Name "InitialDeposit"
   if(![string]::IsNullOrWhiteSpace([string]$manifestInitialDeposit)) {
      $parsedInitialDeposit = 0.0
      if([double]::TryParse(([string]$manifestInitialDeposit).Trim(),
                            [Globalization.NumberStyles]::Float,
                            [Globalization.CultureInfo]::InvariantCulture,
                            [ref]$parsedInitialDeposit) -and $parsedInitialDeposit -gt 0.0) {
         $initialDeposit = $parsedInitialDeposit
      }
   }
   $calendarDays = Get-CalendarDays -From $from -To $to

   if(!$Path) {
      return [pscustomobject]@{
         Rank = $rank
         Priority = $priority
         Phase = $phase
         Profile = $profile
         Set = $set
         Window = $window
         From = $from
         To = $to
         ExpectedReportName = $expectedReportName
         Status = "MISSING_REPORT"
         ReportPath = ""
         InitialDeposit = $initialDeposit
         CalendarDays = if($null -eq $calendarDays) { "" } else { $calendarDays }
         Years = ""
         NetProfit = ""
         Balance = ""
         TotalReturnPercent = ""
         AnnualizedReturnPercent = ""
         CagrPercent = ""
         ProfitFactor = ""
         ExpectedPayoff = ""
         SharpeRatio = ""
         WinRatePercent = ""
         TotalTrades = ""
         MaxConsecutiveLosses = ""
         MaxDrawdownMoney = ""
         MaxDrawdownPercent = ""
         BalanceDrawdownMaximal = ""
         EquityDrawdownMaximal = ""
         RecoveryFactor = ""
      }
   }

   $text = Normalize-ReportText -Path $Path
   $netProfit = Read-Metric -Text $text -Labels @("Total Net Profit", "Net Profit")
   $balance = Read-Metric -Text $text -Labels @("Final Balance", "Balance Final")
   $profitFactor = Read-Metric -Text $text -Labels @("Profit Factor")
   $expectedPayoff = Read-Metric -Text $text -Labels @("Expected Payoff")
   $sharpeRatio = Read-Metric -Text $text -Labels @("Sharpe Ratio", "Sharpe")
   $winRatePercent = Read-MetricPercent -Text $text -Labels @("Profit Trades", "Profitable Trades", "Winning Trades")
   $totalTrades = Read-Metric -Text $text -Labels @("Total Trades")
   $maxConsecutiveLosses = Read-Metric -Text $text -Labels @("Maximal consecutive losses", "Maximum consecutive losses", "Max consecutive losses", "Consecutive Losses")
   $balanceDrawdown = Read-Metric -Text $text -Labels @("Balance Drawdown Maximal", "Maximal balance drawdown")
   $equityDrawdown = Read-Metric -Text $text -Labels @("Equity Drawdown Maximal", "Maximal equity drawdown")
   $drawdownPercent = Read-MetricPercent -Text $text -Labels @("Equity Drawdown Maximal", "Balance Drawdown Maximal", "Maximal equity drawdown", "Maximal balance drawdown", "Maximal drawdown")

   if($null -eq $netProfit -and $null -ne $balance) {
      $netProfit = [Math]::Round($balance - $initialDeposit, 2)
   }
   if($null -eq $balance -and $null -ne $netProfit) {
      $balance = [Math]::Round($initialDeposit + $netProfit, 2)
   }

   $maxDrawdown = $null
   if($null -ne $equityDrawdown -and $null -ne $balanceDrawdown) {
      $maxDrawdown = [Math]::Max($equityDrawdown, $balanceDrawdown)
   } elseif($null -ne $equityDrawdown) {
      $maxDrawdown = $equityDrawdown
   } elseif($null -ne $balanceDrawdown) {
      $maxDrawdown = $balanceDrawdown
   }

   $recovery = $null
   if($null -ne $netProfit -and $null -ne $maxDrawdown -and $maxDrawdown -gt 0) {
      $recovery = [Math]::Round($netProfit / $maxDrawdown, 4)
   }

   $returnMetrics = Get-ReturnMetrics -NetProfit $netProfit -Balance $balance -InitialDeposit $initialDeposit -CalendarDays $calendarDays
   $status = if($null -ne $netProfit) { "PARSED" } else { "UNPARSED" }

   return [pscustomobject]@{
      Rank = $rank
      Priority = $priority
      Phase = $phase
      Profile = $profile
      Set = $set
      Window = $window
      From = $from
      To = $to
      ExpectedReportName = $expectedReportName
      Status = $status
      ReportPath = $Path.Replace($RepoRoot + "\", "")
      InitialDeposit = $initialDeposit
      CalendarDays = if($null -eq $calendarDays) { "" } else { $calendarDays }
      Years = if($null -eq $returnMetrics.Years) { "" } else { [Math]::Round($returnMetrics.Years, 4) }
      NetProfit = if($null -eq $netProfit) { "" } else { [Math]::Round($netProfit, 2) }
      Balance = if($null -eq $balance) { "" } else { [Math]::Round($balance, 2) }
      TotalReturnPercent = if($null -eq $returnMetrics.TotalReturnPercent) { "" } else { [Math]::Round($returnMetrics.TotalReturnPercent, 2) }
      AnnualizedReturnPercent = if($null -eq $returnMetrics.AnnualizedReturnPercent) { "" } else { [Math]::Round($returnMetrics.AnnualizedReturnPercent, 2) }
      CagrPercent = if($null -eq $returnMetrics.CagrPercent) { "" } else { [Math]::Round($returnMetrics.CagrPercent, 2) }
      ProfitFactor = if($null -eq $profitFactor) { "" } else { [Math]::Round($profitFactor, 4) }
      ExpectedPayoff = if($null -eq $expectedPayoff) { "" } else { [Math]::Round($expectedPayoff, 4) }
      SharpeRatio = if($null -eq $sharpeRatio) { "" } else { [Math]::Round($sharpeRatio, 4) }
      WinRatePercent = if($null -eq $winRatePercent) { "" } else { [Math]::Round($winRatePercent, 2) }
      TotalTrades = if($null -eq $totalTrades) { "" } else { [int][Math]::Round($totalTrades, 0) }
      MaxConsecutiveLosses = if($null -eq $maxConsecutiveLosses) { "" } else { [int][Math]::Round($maxConsecutiveLosses, 0) }
      MaxDrawdownMoney = if($null -eq $maxDrawdown) { "" } else { [Math]::Round($maxDrawdown, 2) }
      MaxDrawdownPercent = if($null -eq $drawdownPercent) { "" } else { [Math]::Round($drawdownPercent, 2) }
      BalanceDrawdownMaximal = if($null -eq $balanceDrawdown) { "" } else { [Math]::Round($balanceDrawdown, 2) }
      EquityDrawdownMaximal = if($null -eq $equityDrawdown) { "" } else { [Math]::Round($equityDrawdown, 2) }
      RecoveryFactor = if($null -eq $recovery) { "" } else { $recovery }
   }
}

$manifestFullPath = Join-Path $RepoRoot $ManifestPath
$reportRoot = Join-Path $RepoRoot $ReportDir
if(!(Test-Path -LiteralPath $manifestFullPath)) {
   throw "Validation manifest not found: $manifestFullPath"
}

$manifest = Import-Csv -LiteralPath $manifestFullPath
$rows = New-Object System.Collections.Generic.List[object]
foreach($item in $manifest) {
   $report = Find-Report -Root $reportRoot -ManifestRow $item -Template $ReportNameTemplate
   $rows.Add((Read-ValidationReport -Path $report -ManifestRow $item)) | Out-Null
}

$outResultsPath = Join-Path $RepoRoot $OutResults
$rows | Export-Csv -LiteralPath $outResultsPath -NoTypeInformation

$summary = foreach($group in ($rows | Group-Object Profile, Phase, Set)) {
   $parsed = @($group.Group | Where-Object { $_.Status -eq "PARSED" -and "$($_.NetProfit)" -ne "" })
   $profits = @($parsed | ForEach-Object { [double]$_.NetProfit })
   $drawdowns = @($parsed | Where-Object { "$($_.MaxDrawdownMoney)" -ne "" } | ForEach-Object { [double]$_.MaxDrawdownMoney })
   $profitFactors = @($parsed | Where-Object { "$($_.ProfitFactor)" -ne "" } | ForEach-Object { [double]$_.ProfitFactor })
   $sharpes = @($parsed | Where-Object { "$($_.SharpeRatio)" -ne "" } | ForEach-Object { [double]$_.SharpeRatio })
   $winRates = @($parsed | Where-Object { "$($_.WinRatePercent)" -ne "" } | ForEach-Object { [double]$_.WinRatePercent })
   $lossRuns = @($parsed | Where-Object { "$($_.MaxConsecutiveLosses)" -ne "" } | ForEach-Object { [int]$_.MaxConsecutiveLosses })
   $annualizedReturns = @($parsed | Where-Object { "$($_.AnnualizedReturnPercent)" -ne "" } | ForEach-Object { [double]$_.AnnualizedReturnPercent })
   $cagrs = @($parsed | Where-Object { "$($_.CagrPercent)" -ne "" } | ForEach-Object { [double]$_.CagrPercent })
   $parts = $group.Name -split ', '

   [pscustomobject]@{
      Profile = $parts[0]
      Phase = $parts[1]
      Set = $parts[2]
      ReportsExpected = $group.Count
      ReportsParsed = $parsed.Count
      MissingReports = @($group.Group | Where-Object Status -eq "MISSING_REPORT").Count
      UnparsedReports = @($group.Group | Where-Object Status -eq "UNPARSED").Count
      TotalNetProfit = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Sum).Sum, 2) }
      WorstWindowNetProfit = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Minimum).Minimum, 2) }
      BestWindowNetProfit = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Maximum).Maximum, 2) }
      AverageAnnualizedReturnPercent = if($annualizedReturns.Count -eq 0) { "" } else { [Math]::Round(($annualizedReturns | Measure-Object -Average).Average, 2) }
      WorstAnnualizedReturnPercent = if($annualizedReturns.Count -eq 0) { "" } else { [Math]::Round(($annualizedReturns | Measure-Object -Minimum).Minimum, 2) }
      AverageCagrPercent = if($cagrs.Count -eq 0) { "" } else { [Math]::Round(($cagrs | Measure-Object -Average).Average, 2) }
      WorstCagrPercent = if($cagrs.Count -eq 0) { "" } else { [Math]::Round(($cagrs | Measure-Object -Minimum).Minimum, 2) }
      LosingWindows = @($profits | Where-Object { $_ -lt 0 }).Count
      ProfitableWindows = @($profits | Where-Object { $_ -gt 0 }).Count
      FlatWindows = @($profits | Where-Object { $_ -eq 0 }).Count
      WorstDrawdownMoney = if($drawdowns.Count -eq 0) { "" } else { [Math]::Round(($drawdowns | Measure-Object -Maximum).Maximum, 2) }
      AverageProfitFactor = if($profitFactors.Count -eq 0) { "" } else { [Math]::Round(($profitFactors | Measure-Object -Average).Average, 4) }
      AverageSharpeRatio = if($sharpes.Count -eq 0) { "" } else { [Math]::Round(($sharpes | Measure-Object -Average).Average, 4) }
      AverageWinRatePercent = if($winRates.Count -eq 0) { "" } else { [Math]::Round(($winRates | Measure-Object -Average).Average, 2) }
      WorstConsecutiveLosses = if($lossRuns.Count -eq 0) { "" } else { ($lossRuns | Measure-Object -Maximum).Maximum }
      EvidenceComplete = $parsed.Count -eq $group.Count
   }
}

$outSummaryPath = Join-Path $RepoRoot $OutSummary
$summary | Sort-Object Profile, Phase, Set | Export-Csv -LiteralPath $outSummaryPath -NoTypeInformation

$markdown = New-Object System.Collections.Generic.List[string]
$markdown.Add("# Validation Report Metrics") | Out-Null
$markdown.Add("") | Out-Null
$markdown.Add("Generated from exported MT5 report files only. No MT5 process was launched.") | Out-Null
$markdown.Add("") | Out-Null
$parsedCount = @($rows | Where-Object { $_.Status -eq "PARSED" }).Count
$missingCount = @($rows | Where-Object { $_.Status -eq "MISSING_REPORT" }).Count
$unparsedCount = @($rows | Where-Object { $_.Status -eq "UNPARSED" }).Count
$markdown.Add("- Manifest: ``$ManifestPath``") | Out-Null
$markdown.Add("- Report name template: ``$ReportNameTemplate``") | Out-Null
$markdown.Add("- Expected reports: " + $rows.Count) | Out-Null
$markdown.Add("- Parsed reports: " + $parsedCount) | Out-Null
$markdown.Add("- Missing reports: " + $missingCount) | Out-Null
$markdown.Add("- Unparsed reports: " + $unparsedCount) | Out-Null
$markdown.Add("") | Out-Null
$markdown.Add("## Summary By Profile And Set") | Out-Null
$markdown.Add("") | Out-Null
$markdown.Add("| Profile | Phase | Set | Parsed/Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Avg CAGR % | Worst CAGR % | Losing | Worst DD | Avg PF | Avg Sharpe | Avg Win % | Worst Loss Run | Complete |") | Out-Null
$markdown.Add("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|") | Out-Null
foreach($item in ($summary | Sort-Object Profile, Phase, Set)) {
   $markdown.Add("| ``$($item.Profile)`` | $($item.Phase) | $($item.Set) | $($item.ReportsParsed)/$($item.ReportsExpected) | $($item.TotalNetProfit) | $($item.WorstWindowNetProfit) | $($item.AverageAnnualizedReturnPercent) | $($item.WorstAnnualizedReturnPercent) | $($item.AverageCagrPercent) | $($item.WorstCagrPercent) | $($item.LosingWindows) | $($item.WorstDrawdownMoney) | $($item.AverageProfitFactor) | $($item.AverageSharpeRatio) | $($item.AverageWinRatePercent) | $($item.WorstConsecutiveLosses) | $($item.EvidenceComplete) |") | Out-Null
}

$markdown.Add("") | Out-Null
$markdown.Add("## Missing Or Unparsed Reports") | Out-Null
$markdown.Add("") | Out-Null
$issues = @($rows | Where-Object { $_.Status -ne "PARSED" } | Sort-Object Priority, Profile, Set, Window)
if($issues.Count -eq 0) {
   $markdown.Add("All expected reports parsed.") | Out-Null
} else {
   $markdown.Add("| Profile | Phase | Set | Window | Status |") | Out-Null
   $markdown.Add("|---|---:|---:|---:|---:|") | Out-Null
   foreach($issue in ($issues | Select-Object -First 80)) {
      $markdown.Add("| ``$($issue.Profile)`` | $($issue.Phase) | $($issue.Set) | $($issue.Window) | $($issue.Status) |") | Out-Null
   }
   if($issues.Count -gt 80) {
      $markdown.Add("") | Out-Null
      $markdown.Add("Showing first 80 of $($issues.Count) missing/unparsed reports.") | Out-Null
   }
}

Set-Content -LiteralPath (Join-Path $RepoRoot $OutMarkdown) -Value $markdown -Encoding UTF8

Write-Output "Wrote $OutResults"
Write-Output "Wrote $OutSummary"
Write-Output "Wrote $OutMarkdown"
