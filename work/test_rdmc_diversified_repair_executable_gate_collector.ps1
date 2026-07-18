Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$collector = Join-Path $PSScriptRoot "collect_rdmc_diversified_repair_executable_gate_results.ps1"
$manifest = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_WAVE_01_MANIFEST.csv"))
$sourceHash = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
$binaryHash = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
$tempRelative = "outputs\_rdmc_exec_collector_test_" + [guid]::NewGuid().ToString("N")
$temp = Join-Path $repo $tempRelative
$reports = Join-Path $temp "reports"
$ledger = Join-Path $temp "runner_1.csv"

if(!$temp.StartsWith((Join-Path $repo "outputs") + "\", [StringComparison]::OrdinalIgnoreCase)) {
   throw "Unsafe collector-test directory."
}
New-Item -ItemType Directory -Path $reports -Force | Out-Null
$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

function Write-SyntheticReport([object]$Row, [bool]$IncludeSourceHash = $true) {
   $identity = if($IncludeSourceHash) { $sourceHash } else { "SOURCE_IDENTITY_REMOVED" }
   $path = Join-Path $reports ($Row.ExpectedReportName + ".htm")
   $html = @"
<html><body><table>
<tr><td>Initial Deposit:</td><td>10000</td></tr>
<tr><td>Total Net Profit:</td><td>100.00</td></tr>
<tr><td>Final Balance:</td><td>10100.00</td></tr>
<tr><td>Profit Factor:</td><td>1.50</td></tr>
<tr><td>Expected Payoff:</td><td>3.33</td></tr>
<tr><td>Sharpe Ratio:</td><td>1.20</td></tr>
<tr><td>Profit Trades (% of total):</td><td>18 (60.00%)</td></tr>
<tr><td>Total Trades:</td><td>30</td></tr>
<tr><td>Maximum consecutive losses:</td><td>3</td></tr>
<tr><td>Balance Drawdown Maximal:</td><td>80.00 (0.80%)</td></tr>
<tr><td>Equity Drawdown Maximal:</td><td>100.00 (1.00%)</td></tr>
</table><p>$identity</p></body></html>
"@
   [IO.File]::WriteAllText($path, $html, [Text.Encoding]::ASCII)
   return $path
}

function Write-RunnerLedger([bool]$TamperConfig = $false) {
   $rows = foreach($row in $manifest) {
      $report = Join-Path $reports ($row.ExpectedReportName + ".htm")
      $relativeReport = $report.Substring($repo.Length + 1)
      [pscustomobject]@{
         QueueRank = $row.QueueRank
         Candidate = $row.Candidate
         Status = "REPORT_FOUND"
         ReportPath = $relativeReport
         PackageSourceSha256 = $sourceHash
         PackageConfigSha256 = if($TamperConfig -and $row.QueueRank -eq $manifest[0].QueueRank) { "BAD" } else { $row.ConfigSha256 }
         PortableBinarySha256 = $binaryHash
      }
   }
   $rows | Export-Csv -LiteralPath $ledger -NoTypeInformation -Encoding ASCII
}

try {
   foreach($row in $manifest) { Write-SyntheticReport $row | Out-Null }
   Write-RunnerLedger

   $common = @{
      Wave = 1
      ReportDir = ($reports.Substring($repo.Length + 1))
      RunnerLedgerGlob = ($ledger.Substring($repo.Length + 1))
      ResultsPath = "$tempRelative\canonical.csv"
      RunAuditPath = "$tempRelative\audit.csv"
      RawResultsPath = "$tempRelative\raw.csv"
      SummaryPath = "$tempRelative\summary.csv"
      MetricsMarkdownPath = "$tempRelative\metrics.md"
      SkipAdmissionRefresh = $true
   }
   $result = & $collector @common
   if($result.Status -ne "PARSED_IDENTITY_BOUND" -or $result.Reports -ne 2 -or $result.PortableBinarySha256 -ne $binaryHash) {
      throw "Collector did not return the expected identity-bound result."
   }
   $canonical = @(Import-Csv -LiteralPath (Join-Path $temp "canonical.csv"))
   if($canonical.Count -ne 2 -or @($canonical | Where-Object Status -ne "PARSED").Count -gt 0) {
      throw "Collector did not produce two parsed canonical rows."
   }
   if(@($canonical | Where-Object { [double]$_.InitialDeposit -ne 10000.0 -or [double]$_.NetProfit -ne 100.0 -or [double]$_.MaxDrawdownPercent -ne 1.0 }).Count -gt 0) {
      throw "Collector metrics do not match the synthetic reports."
   }
   if(@($canonical | Where-Object { $_.ConfigSha256 -notin $manifest.ConfigSha256 -or $_.SourceSha256 -ne $sourceHash -or $_.PortableBinarySha256 -ne $binaryHash }).Count -gt 0) {
      throw "Collector lost frozen identity fields."
   }

   Write-RunnerLedger -TamperConfig $true
   $configRejected = $false
   try { & $collector @common | Out-Null } catch { $configRejected = $_.Exception.Message -match "Runner config mismatch" }
   if(!$configRejected) { throw "Collector accepted a tampered runner config identity." }

   Write-RunnerLedger
   Write-SyntheticReport $manifest[0] $false | Out-Null
   $sourceRejected = $false
   try { & $collector @common | Out-Null } catch { $sourceRejected = $_.Exception.Message -match "lacks the frozen source identity" }
   if(!$sourceRejected) { throw "Collector accepted a report without the frozen source identity." }

   $after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   if($after.Count -gt $before.Count) { throw "Collector test launched an MT5-family process." }

   [pscustomobject]@{
      Status = "PASS"
      ParsedReports = $canonical.Count
      TamperedConfigRejected = $configRejected
      MissingSourceIdentityRejected = $sourceRejected
      MQL5Launched = $false
   }
}
finally {
   if(Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
