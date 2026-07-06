param(
   [string]$LogPath = "work\compile.log",
   [string]$ExpectedSourcePath = "outputs\Professional_XAUUSD_EA.mq5",
   [string]$CompiledSourcePath = "",
   [bool]$RequireSourceHashMatch = $true,
   [string]$OutCsv = "outputs\MT5_COMPILE_STATUS.csv",
   [string]$OutMarkdown = "outputs\MT5_COMPILE_STATUS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-CompileCount {
   param(
      [string]$Text,
      [string]$Name
   )

   $pattern = "(?i)(\d+)\s+$Name"
   $match = [regex]::Match($Text, $pattern)
   if($match.Success) { return [int]$match.Groups[1].Value }
   return $null
}

function Escape-MarkdownCell {
   param([string]$Value)
   if($null -eq $Value) { return "" }
   return (($Value -replace '\|', '/') -replace "`r?`n", " ").Trim()
}

$rows = New-Object System.Collections.Generic.List[object]
$status = "MISSING"
$errors = $null
$warnings = $null
$elapsed = ""
$resultLine = ""
$sourceFile = ""
$sourceHash = ""
$expectedSourceHash = ""
$sourceHashStatus = "NOT_CHECKED"
$evidence = "Compile log was not found at $LogPath."
$nextAction = "Export a MetaEditor compile log, then rerun this importer before accepting new backtest reports."

if(Test-Path -LiteralPath $LogPath) {
   $text = Get-Content -LiteralPath $LogPath -Raw
   $lines = @($text -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
   $resultLine = [string]($lines | Where-Object { $_ -match '(?i)Result:\s+\d+\s+errors?,\s+\d+\s+warnings?' } | Select-Object -Last 1)
   $sourceLine = [string]($lines | Where-Object { $_ -match '(?i):\s+information:\s+compiling\s+' } | Select-Object -Last 1)

   if($sourceLine -match '(?i)compiling\s+(.+)$') { $sourceFile = $Matches[1].Trim() }
   if(![string]::IsNullOrWhiteSpace($CompiledSourcePath)) {
      $sourceFile = $CompiledSourcePath
   }
   if(![string]::IsNullOrWhiteSpace($sourceFile) -and (Test-Path -LiteralPath $sourceFile -ErrorAction SilentlyContinue)) {
      $sourceHash = (Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash
   }
   if(Test-Path -LiteralPath $ExpectedSourcePath -ErrorAction SilentlyContinue) {
      $expectedSourceHash = (Get-FileHash -LiteralPath $ExpectedSourcePath -Algorithm SHA256).Hash
   }
   if(![string]::IsNullOrWhiteSpace($sourceHash) -and ![string]::IsNullOrWhiteSpace($expectedSourceHash)) {
      $sourceHashStatus = if($sourceHash -eq $expectedSourceHash) { "MATCH" } else { "MISMATCH" }
   } elseif(![string]::IsNullOrWhiteSpace($expectedSourceHash)) {
      $sourceHashStatus = "EXPECTED_ONLY"
   } elseif(![string]::IsNullOrWhiteSpace($sourceHash)) {
      $sourceHashStatus = "COMPILED_ONLY"
   }
   if($resultLine -match '(?i)Result:\s+(\d+)\s+errors?,\s+(\d+)\s+warnings?,\s+(.+)$') {
      $errors = [int]$Matches[1]
      $warnings = [int]$Matches[2]
      $elapsed = $Matches[3].Trim()
   } else {
      $errors = Get-CompileCount $text "errors?"
      $warnings = Get-CompileCount $text "warnings?"
   }

   if($null -eq $errors -or $null -eq $warnings) {
      $status = "UNPARSED"
      $evidence = "Compile log exists, but no standard MetaEditor result line was found."
      $nextAction = "Open the log and confirm whether compilation succeeded; update the parser only after seeing the real format."
   } elseif($errors -gt 0) {
      $status = "FAIL"
      $evidence = "$errors compile errors, $warnings warnings. $resultLine"
      $nextAction = "Fix compile errors before running or importing any backtest reports."
   } elseif($warnings -gt 0) {
      $status = "WARN"
      $evidence = "0 compile errors, $warnings warnings. $resultLine"
      $nextAction = "Review warnings before backtesting; warnings do not prove failure, but they should not be ignored."
   } else {
      $status = "PASS"
      $evidence = "0 compile errors, 0 warnings. $resultLine"
      $nextAction = "Compile gate is satisfied for this log; backtest evidence is still required separately."
   }

   if($RequireSourceHashMatch -and $status -in @("PASS", "WARN") -and $sourceHashStatus -ne "MATCH") {
      $status = "STALE"
      $evidence = "Compile log is clean, but compiled source hash did not match expected source. HashStatus=$sourceHashStatus; Source=$sourceFile; Expected=$ExpectedSourcePath"
      $nextAction = "Import the compile log with -CompiledSourcePath pointing to the exact compiled EA source copy, and require SourceHashStatus=MATCH before trusting reports."
   }
}

$rows.Add([pscustomobject]@{
   Area = "MT5 compile"
   Status = $status
   LogPath = $LogPath
   SourceFile = $sourceFile
   SourceHash = $sourceHash
   ExpectedSourcePath = $ExpectedSourcePath
   ExpectedSourceHash = $expectedSourceHash
   SourceHashStatus = $sourceHashStatus
   Errors = if($null -eq $errors) { "" } else { $errors }
   Warnings = if($null -eq $warnings) { "" } else { $warnings }
   Elapsed = $elapsed
   Evidence = $evidence
   NextAction = $nextAction
}) | Out-Null

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# MT5 Compile Status") | Out-Null
$report.Add("") | Out-Null
$report.Add("Offline import only. This script does not launch MetaEditor or MT5.") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Area | Status | Log | Source | Hash Status | Errors | Warnings | Evidence | Next Action |") | Out-Null
$report.Add("|---|---|---|---|---|---:|---:|---|---|") | Out-Null
foreach($row in $rows) {
   $report.Add("| $($row.Area) | $($row.Status) | $(Escape-MarkdownCell $row.LogPath) | $(Escape-MarkdownCell $row.SourceFile) | $($row.SourceHashStatus) | $($row.Errors) | $($row.Warnings) | $(Escape-MarkdownCell $row.Evidence) | $(Escape-MarkdownCell $row.NextAction) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Bottom Line") | Out-Null
$report.Add("") | Out-Null
if($status -eq "PASS") {
   $report.Add("The imported compile log is clean. This is a compile gate only; it does not prove profitability.") | Out-Null
} elseif($status -eq "WARN") {
   $report.Add("The imported compile log has warnings. Review them before spending tester time.") | Out-Null
} elseif($status -eq "STALE") {
   $report.Add("The compile log is not trusted for this EA source because source hash verification did not match.") | Out-Null
} elseif($status -eq "FAIL") {
   $report.Add("The imported compile log has errors. Do not run backtests until they are fixed.") | Out-Null
} else {
   $report.Add("No usable compile proof is available yet.") | Out-Null
}
Set-Content -LiteralPath $OutMarkdown -Value $report -Encoding UTF8

$rows

if($status -eq "FAIL" -or $status -eq "UNPARSED" -or $status -eq "STALE") { exit 1 }
