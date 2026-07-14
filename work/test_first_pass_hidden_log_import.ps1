$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tempRoot = Join-Path $repo ("work\first_pass_hidden_log_import_test_{0}" -f $PID)

function Assert-True {
   param([bool]$Condition, [string]$Message)
   if(!$Condition) { throw $Message }
}

try {
   New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

   $queueRoot = Join-Path $tempRoot "queue"
   $manifestPath = Join-Path $tempRoot "queue.csv"
   $queueMd = Join-Path $tempRoot "queue.md"
   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\build_first_pass_validation_queue.ps1") `
      -OutDir $queueRoot `
      -OutManifest $manifestPath `
      -OutMarkdown $queueMd | Out-Null

   $manifest = @(Import-Csv -LiteralPath $manifestPath)
   $first = $manifest | Where-Object QueueRank -eq "1" | Select-Object -First 1
   Assert-True ($null -ne $first) "Fixture queue should include rank 1"

   $runCsv = Join-Path $tempRoot "hidden_run.csv"
   @([pscustomobject]@{
      QueueRank = $first.QueueRank
      Candidate = $first.Candidate
      Window = $first.Window
      Model = $first.Model
      Status = "NO_REPORT"
      Action = "RUN_HIDDEN"
      Config = $first.Config
      ConfigExists = "True"
      ExpectedReportName = $first.ExpectedReportName
      FirstPassInbox = "outputs\returned_mt5_reports\first_pass_inbox"
      MaxCpuPercent = "80"
      Reports = ""
      Evidence = "Terminal exited but no report file was found."
      Started = "2026-07-14T08:54:07"
      Finished = "2026-07-14T08:54:21"
   }) | Export-Csv -LiteralPath $runCsv -NoTypeInformation -Encoding ASCII

   $logPath = Join-Path $tempRoot "20260714.log"
   @(
      "QG`t0`t08:54:16.431`tCore 01`t2026.07.10 22:59:59   TESTER_STATS net=0.00 balance=1000.00 profit_factor=0.0000 recovery_factor=0.0000 sharpe=0.0000 equity_dd_pct=0.0000 trades=0",
      "QK`t0`t08:54:16.431`tCore 01`tfinal balance 1000.00 USD"
   ) | Set-Content -LiteralPath $logPath -Encoding ASCII

   $results = Join-Path $tempRoot "results.csv"
   $summary = Join-Path $tempRoot "summary.csv"
   $metricsMd = Join-Path $tempRoot "metrics.md"
   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\import_first_pass_hidden_log_results.ps1") `
      -RunCsv $runCsv `
      -QueueManifestPath $manifestPath `
      -TesterLogPath $logPath `
      -OutResults $results `
      -OutSummary $summary `
      -OutMarkdown $metricsMd | Out-Null

   $resultRows = @(Import-Csv -LiteralPath $results)
   $parsed = $resultRows | Where-Object QueueRank -eq "1" | Select-Object -First 1
   Assert-True ($resultRows.Count -eq $manifest.Count) "Importer should preserve one result row per queue row"
   Assert-True ($parsed.Status -eq "PARSED_FROM_LOG") "Rank 1 should parse from log"
   Assert-True ([string]$parsed.NetProfit -eq "0") "Rank 1 net should be 0"
   Assert-True ([string]$parsed.Balance -eq "1000") "Rank 1 balance should be 1000"
   Assert-True ([string]$parsed.TotalTrades -eq "0") "Rank 1 trades should be 0"
   Assert-True ([string]$parsed.ProfitFactor -eq "0") "Rank 1 profit factor should be 0"
   Assert-True ([string]$parsed.MaxDrawdownPercent -eq "0") "Rank 1 drawdown percent should be 0"
   Assert-True (@($resultRows | Where-Object Status -eq "MISSING_REPORT").Count -eq ($manifest.Count - 1)) "Remaining rows should stay missing"

   $staleExistingPath = Join-Path $tempRoot "stale_existing_results.csv"
   $staleRows = @($resultRows)
   $staleRows[0].Candidate = "stale_candidate"
   $staleRows | Export-Csv -LiteralPath $staleExistingPath -NoTypeInformation -Encoding ASCII

   $emptyRunCsv = Join-Path $tempRoot "empty_hidden_run.csv"
   @([pscustomobject]@{
      QueueRank = $first.QueueRank
      Candidate = $first.Candidate
      Window = $first.Window
      Model = $first.Model
      Status = "PENDING"
      Action = "SKIP"
      Config = $first.Config
      ConfigExists = "True"
      ExpectedReportName = $first.ExpectedReportName
      FirstPassInbox = "outputs\returned_mt5_reports\first_pass_inbox"
      MaxCpuPercent = "80"
      Reports = ""
      Evidence = ""
      Started = ""
      Finished = ""
   }) | Export-Csv -LiteralPath $emptyRunCsv -NoTypeInformation -Encoding ASCII

   $staleImportResults = Join-Path $tempRoot "stale_import_results.csv"
   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\import_first_pass_hidden_log_results.ps1") `
      -RunCsv $emptyRunCsv `
      -QueueManifestPath $manifestPath `
      -ExistingResultsPath $staleExistingPath `
      -TesterLogPath $logPath `
      -OutResults $staleImportResults `
      -OutSummary (Join-Path $tempRoot "stale_summary.csv") `
      -OutMarkdown (Join-Path $tempRoot "stale_metrics.md") | Out-Null

   $staleImportRows = @(Import-Csv -LiteralPath $staleImportResults)
   $staleRankOne = $staleImportRows | Where-Object QueueRank -eq "1" | Select-Object -First 1
   Assert-True ($staleRankOne.Candidate -eq $first.Candidate) "Importer should not preserve a stale candidate identity by rank"
   Assert-True ($staleRankOne.Status -eq "MISSING_REPORT") "Mismatched existing log evidence should be discarded"

   $decisionCsv = Join-Path $tempRoot "decision.csv"
   $decisionMd = Join-Path $tempRoot "decision.md"
   $decisionSummary = Join-Path $tempRoot "decision_summary.csv"
   $ranking = Join-Path $tempRoot "ranking.csv"
   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\analyze_first_pass_validation_queue.ps1") `
      -ManifestPath $manifestPath `
      -ResultsPath $results `
      -OutDecisionCsv $decisionCsv `
      -OutDecisionMarkdown $decisionMd `
      -OutSummaryCsv $decisionSummary `
      -OutRankingCsv $ranking | Out-Null

   $decisionRows = @(Import-Csv -LiteralPath $decisionCsv)
   $rankingRows = @(Import-Csv -LiteralPath $ranking)
   Assert-True (@($decisionRows | Where-Object { $_.Gate -like "*-fast-model1-continuous-annualized-return-floor" -and $_.Status -eq "FAIL" }).Count -ge 1) "Zero-trade fast screen should fail annualized return"
   Assert-True (@($rankingRows | Where-Object Recommendation -eq "REJECT_FIRST_PASS").Count -ge 1) "Zero-trade fast screen should reject the candidate"

   "FIRST_PASS_HIDDEN_LOG_IMPORT_SMOKE_PASS"
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
