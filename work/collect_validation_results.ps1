param(
   [string]$RepoRoot = (Resolve-Path ".").Path,
   [string]$ManifestPath = "work\generated_validation\VALIDATION_MANIFEST.csv",
   [string]$ReportDir = "outputs",
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

function Get-RowValue {
   param(
      [object]$Row,
      [string]$Name
   )

   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return "" }
   return [string]$property.Value
}

function Find-Report {
   param(
      [string]$Root,
      [object]$ManifestRow
   )

   $profile = Get-RowValue -Row $ManifestRow -Name "Profile"
   $set = Get-RowValue -Row $ManifestRow -Name "Set"
   $window = Get-RowValue -Row $ManifestRow -Name "Window"
   $base = "validation_{0}_{1}_{2}" -f $profile, $set, $window
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

function Read-ValidationReport {
   param(
      [string]$Path,
      [object]$ManifestRow
   )

   $priority = Get-RowValue -Row $ManifestRow -Name "Priority"
   $profile = Get-RowValue -Row $ManifestRow -Name "Profile"
   $set = Get-RowValue -Row $ManifestRow -Name "Set"
   $window = Get-RowValue -Row $ManifestRow -Name "Window"
   $from = Get-RowValue -Row $ManifestRow -Name "From"
   $to = Get-RowValue -Row $ManifestRow -Name "To"

   if(!$Path) {
      return [pscustomobject]@{
         Priority = $priority
         Profile = $profile
         Set = $set
         Window = $window
         From = $from
         To = $to
         Status = "MISSING_REPORT"
         ReportPath = ""
         NetProfit = ""
         Balance = ""
         ProfitFactor = ""
         ExpectedPayoff = ""
         TotalTrades = ""
         MaxDrawdownMoney = ""
         MaxDrawdownPercent = ""
         BalanceDrawdownMaximal = ""
         EquityDrawdownMaximal = ""
         RecoveryFactor = ""
      }
   }

   $text = Normalize-ReportText -Path $Path
   $initialDeposit = 1000.0
   $netProfit = Read-Metric -Text $text -Labels @("Total Net Profit", "Net Profit")
   $balance = Read-Metric -Text $text -Labels @("Final Balance", "Balance Final")
   $profitFactor = Read-Metric -Text $text -Labels @("Profit Factor")
   $expectedPayoff = Read-Metric -Text $text -Labels @("Expected Payoff")
   $totalTrades = Read-Metric -Text $text -Labels @("Total Trades")
   $balanceDrawdown = Read-Metric -Text $text -Labels @("Balance Drawdown Maximal", "Maximal balance drawdown")
   $equityDrawdown = Read-Metric -Text $text -Labels @("Equity Drawdown Maximal", "Maximal equity drawdown")
   $drawdownPercent = Read-Metric -Text $text -Labels @("Balance Drawdown Maximal (%)", "Equity Drawdown Maximal (%)", "Maximal drawdown (%)")

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

   $status = if($null -ne $netProfit) { "PARSED" } else { "UNPARSED" }

   return [pscustomobject]@{
      Priority = $priority
      Profile = $profile
      Set = $set
      Window = $window
      From = $from
      To = $to
      Status = $status
      ReportPath = $Path.Replace($RepoRoot + "\", "")
      NetProfit = if($null -eq $netProfit) { "" } else { [Math]::Round($netProfit, 2) }
      Balance = if($null -eq $balance) { "" } else { [Math]::Round($balance, 2) }
      ProfitFactor = if($null -eq $profitFactor) { "" } else { [Math]::Round($profitFactor, 4) }
      ExpectedPayoff = if($null -eq $expectedPayoff) { "" } else { [Math]::Round($expectedPayoff, 4) }
      TotalTrades = if($null -eq $totalTrades) { "" } else { [int][Math]::Round($totalTrades, 0) }
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
   $report = Find-Report -Root $reportRoot -ManifestRow $item
   $rows.Add((Read-ValidationReport -Path $report -ManifestRow $item)) | Out-Null
}

$outResultsPath = Join-Path $RepoRoot $OutResults
$rows | Export-Csv -LiteralPath $outResultsPath -NoTypeInformation

$summary = foreach($group in ($rows | Group-Object Profile, Set)) {
   $parsed = @($group.Group | Where-Object { $_.Status -eq "PARSED" -and "$($_.NetProfit)" -ne "" })
   $profits = @($parsed | ForEach-Object { [double]$_.NetProfit })
   $drawdowns = @($parsed | Where-Object { "$($_.MaxDrawdownMoney)" -ne "" } | ForEach-Object { [double]$_.MaxDrawdownMoney })
   $profitFactors = @($parsed | Where-Object { "$($_.ProfitFactor)" -ne "" } | ForEach-Object { [double]$_.ProfitFactor })
   $parts = $group.Name -split ', '

   [pscustomobject]@{
      Profile = $parts[0]
      Set = $parts[1]
      ReportsExpected = $group.Count
      ReportsParsed = $parsed.Count
      MissingReports = @($group.Group | Where-Object Status -eq "MISSING_REPORT").Count
      UnparsedReports = @($group.Group | Where-Object Status -eq "UNPARSED").Count
      TotalNetProfit = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Sum).Sum, 2) }
      WorstWindowNetProfit = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Minimum).Minimum, 2) }
      BestWindowNetProfit = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Maximum).Maximum, 2) }
      LosingWindows = @($profits | Where-Object { $_ -lt 0 }).Count
      ProfitableWindows = @($profits | Where-Object { $_ -gt 0 }).Count
      FlatWindows = @($profits | Where-Object { $_ -eq 0 }).Count
      WorstDrawdownMoney = if($drawdowns.Count -eq 0) { "" } else { [Math]::Round(($drawdowns | Measure-Object -Maximum).Maximum, 2) }
      AverageProfitFactor = if($profitFactors.Count -eq 0) { "" } else { [Math]::Round(($profitFactors | Measure-Object -Average).Average, 4) }
      EvidenceComplete = $parsed.Count -eq $group.Count
   }
}

$outSummaryPath = Join-Path $RepoRoot $OutSummary
$summary | Sort-Object Profile, Set | Export-Csv -LiteralPath $outSummaryPath -NoTypeInformation

$markdown = New-Object System.Collections.Generic.List[string]
$markdown.Add("# Validation Report Metrics") | Out-Null
$markdown.Add("") | Out-Null
$markdown.Add("Generated from exported MT5 report files only. No MT5 process was launched.") | Out-Null
$markdown.Add("") | Out-Null
$parsedCount = @($rows | Where-Object { $_.Status -eq "PARSED" }).Count
$missingCount = @($rows | Where-Object { $_.Status -eq "MISSING_REPORT" }).Count
$unparsedCount = @($rows | Where-Object { $_.Status -eq "UNPARSED" }).Count
$markdown.Add("- Manifest: ``$ManifestPath``") | Out-Null
$markdown.Add("- Expected reports: " + $rows.Count) | Out-Null
$markdown.Add("- Parsed reports: " + $parsedCount) | Out-Null
$markdown.Add("- Missing reports: " + $missingCount) | Out-Null
$markdown.Add("- Unparsed reports: " + $unparsedCount) | Out-Null
$markdown.Add("") | Out-Null
$markdown.Add("## Summary By Profile And Set") | Out-Null
$markdown.Add("") | Out-Null
$markdown.Add("| Profile | Set | Parsed/Expected | Total Net | Worst Window | Losing | Worst DD | Avg PF | Complete |") | Out-Null
$markdown.Add("|---|---:|---:|---:|---:|---:|---:|---:|---:|") | Out-Null
foreach($item in ($summary | Sort-Object Profile, Set)) {
   $markdown.Add("| ``$($item.Profile)`` | $($item.Set) | $($item.ReportsParsed)/$($item.ReportsExpected) | $($item.TotalNetProfit) | $($item.WorstWindowNetProfit) | $($item.LosingWindows) | $($item.WorstDrawdownMoney) | $($item.AverageProfitFactor) | $($item.EvidenceComplete) |") | Out-Null
}

$markdown.Add("") | Out-Null
$markdown.Add("## Missing Or Unparsed Reports") | Out-Null
$markdown.Add("") | Out-Null
$issues = @($rows | Where-Object { $_.Status -ne "PARSED" } | Sort-Object Priority, Profile, Set, Window)
if($issues.Count -eq 0) {
   $markdown.Add("All expected reports parsed.") | Out-Null
} else {
   $markdown.Add("| Profile | Set | Window | Status |") | Out-Null
   $markdown.Add("|---|---:|---:|---:|") | Out-Null
   foreach($issue in ($issues | Select-Object -First 80)) {
      $markdown.Add("| ``$($issue.Profile)`` | $($issue.Set) | $($issue.Window) | $($issue.Status) |") | Out-Null
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
