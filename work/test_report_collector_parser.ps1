param(
   [string]$RepoRoot = (Resolve-Path ".").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Equal {
   param(
      [object]$Actual,
      [object]$Expected,
      [string]$Label
   )

   if([string]$Actual -ne [string]$Expected) {
      throw "$Label expected '$Expected' but got '$Actual'"
   }
}

$tempRoot = Join-Path $RepoRoot "work\parser_smoke_tmp"
$resolvedRepo = (Resolve-Path -LiteralPath $RepoRoot).Path
$resolvedParent = (Resolve-Path -LiteralPath (Join-Path $RepoRoot "work")).Path

if(Test-Path -LiteralPath $tempRoot) {
   $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
   if(!$resolvedTemp.StartsWith($resolvedParent, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to clean unexpected parser smoke path: $resolvedTemp"
   }
   Remove-Item -LiteralPath $tempRoot -Recurse -Force
}

$reportsDir = Join-Path $tempRoot "reports"
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

$manifestRows = @(
   [pscustomobject]@{
      Priority = 1
      Phase = "phase1_fast_triage"
      Profile = "fixture_profile"
      Set = "stress"
      Window = "2024_Q1"
      From = "2024.01.01"
      To = "2024.03.31"
   },
   [pscustomobject]@{
      Priority = 2
      Phase = "phase2_real_tick_validation"
      Profile = "balance_only"
      Set = "split"
      Window = "full"
      From = "2024.01.01"
      To = "2026.07.02"
   },
   [pscustomobject]@{
      Priority = 3
      Phase = "phase1_fast_triage"
      Profile = "bad_report"
      Set = "stress"
      Window = "missing_profit"
      From = "2025.01.01"
      To = "2025.03.31"
   }
)

$manifestPath = Join-Path $tempRoot "manifest.csv"
$manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation

$fullReport = @"
<html><body>
<table>
<tr><td>Total Net Profit:</td><td>1,234.56</td><td>Balance Drawdown Maximal:</td><td>88.25 (8.82%)</td></tr>
<tr><td>Profit Factor:</td><td>2.35</td><td>Expected Payoff:</td><td>24.20</td></tr>
<tr><td>Total Trades:</td><td>51</td><td>Equity Drawdown Maximal:</td><td>91.50 (9.15%)</td></tr>
</table>
</body></html>
"@

$balanceOnlyReport = @"
<html><body>
<table>
<tr><th>Final Balance</th><td>1,777.77</td></tr>
<tr><th>Profit Factor</th><td>1.80</td></tr>
<tr><th>Total Trades</th><td>12</td></tr>
<tr><th>Balance Drawdown Maximal</th><td>33.30</td></tr>
</table>
</body></html>
"@

$badReport = @"
<html><body>
<table>
<tr><td>Symbol</td><td>XAUUSD</td></tr>
<tr><td>Period</td><td>M15</td></tr>
<tr><td>Total Trades:</td><td>9</td></tr>
<tr><td>Profit Factor:</td><td>not available</td></tr>
</table>
</body></html>
"@

Set-Content -LiteralPath (Join-Path $reportsDir "validation_fixture_profile_stress_2024_Q1.htm") -Value $fullReport -Encoding UTF8
Set-Content -LiteralPath (Join-Path $reportsDir "validation_balance_only_split_full.html") -Value $balanceOnlyReport -Encoding UTF8
Set-Content -LiteralPath (Join-Path $reportsDir "validation_bad_report_stress_missing_profit.htm") -Value $badReport -Encoding UTF8

$collector = Join-Path $resolvedRepo "work\collect_validation_results.ps1"
$outResults = "results.csv"
$outSummary = "summary.csv"
$outMarkdown = "metrics.md"

& powershell -NoProfile -ExecutionPolicy Bypass -File $collector `
   -RepoRoot $tempRoot `
   -ManifestPath "manifest.csv" `
   -ReportDir "reports" `
   -ReportNameTemplate "validation_{Profile}_{Set}_{Window}" `
   -OutResults $outResults `
   -OutSummary $outSummary `
   -OutMarkdown $outMarkdown | Out-Null

$results = Import-Csv -LiteralPath (Join-Path $tempRoot $outResults)
$first = $results | Where-Object Profile -eq "fixture_profile" | Select-Object -First 1
$second = $results | Where-Object Profile -eq "balance_only" | Select-Object -First 1
$bad = $results | Where-Object Profile -eq "bad_report" | Select-Object -First 1

if($null -eq $first -or $null -eq $second -or $null -eq $bad) {
   throw "Expected parser smoke rows were not produced."
}

Assert-Equal $first.Status "PARSED" "First report status"
Assert-Equal $first.NetProfit "1234.56" "First net profit"
Assert-Equal $first.Balance "2234.56" "First derived balance"
Assert-Equal $first.ProfitFactor "2.35" "First profit factor"
Assert-Equal $first.TotalTrades "51" "First total trades"
Assert-Equal $first.MaxDrawdownMoney "91.5" "First max drawdown"
Assert-Equal $first.RecoveryFactor "13.4925" "First recovery factor"

Assert-Equal $second.Status "PARSED" "Second report status"
Assert-Equal $second.NetProfit "777.77" "Second derived net profit"
Assert-Equal $second.Balance "1777.77" "Second final balance"
Assert-Equal $second.MaxDrawdownMoney "33.3" "Second max drawdown"
Assert-Equal $second.RecoveryFactor "23.3565" "Second recovery factor"

Assert-Equal $bad.Status "UNPARSED" "Bad report status"
Assert-Equal $bad.NetProfit "" "Bad report net profit"
Assert-Equal $bad.Balance "" "Bad report balance"

$summary = Import-Csv -LiteralPath (Join-Path $tempRoot $outSummary)
$badSummary = $summary | Where-Object Profile -eq "bad_report" | Select-Object -First 1
if($null -eq $badSummary) {
   throw "Expected bad-report summary row was not produced."
}
Assert-Equal $badSummary.ReportsParsed "0" "Bad report summary parsed count"
Assert-Equal $badSummary.UnparsedReports "1" "Bad report summary unparsed count"
Assert-Equal $badSummary.EvidenceComplete "False" "Bad report evidence completeness"

"REPORT_COLLECTOR_PARSER_SMOKE_PASS"
