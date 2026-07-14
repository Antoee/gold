param(
   [string]$ValidationResultsPath = "outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv",
   [string]$BrokerProxyResultsPath = "outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv",
   [string]$OutCsv = "outputs\MONEY_READY_EFFICIENCY_AUDIT.csv",
   [string]$OutMarkdown = "outputs\MONEY_READY_EFFICIENCY_AUDIT.md",
   [int]$ExpectedValidationRows = 53,
   [int]$ExpectedBrokerRows = 10,
   [double]$MinContinuousAnnualizedReturnPercent = 12.0,
   [double]$MinContinuousCagrPercent = 10.0,
   [double]$MinContinuousReturnToDrawdown = 3.0,
   [double]$MaxEquityDrawdownPercent = 3.0,
   [int]$MinContinuousTrades = 20,
   [double]$MinProfitFactor = 1.25,
   [double]$MinRecoveryFactor = 1.50,
   [double]$MinExpectedPayoff = 0.0,
   [double]$MinSharpeRatio = 0.10,
   [double]$MinWinRatePercent = 25.0,
   [int]$MaxConsecutiveLosses = 5,
   [double]$MinRecentAnnualizedReturnPercent = 8.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return $Path }
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

function Read-CsvSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   if(Test-Path -LiteralPath $resolved) { return @(Import-Csv -LiteralPath $resolved) }
   return @()
}

function Get-Value {
   param([object]$Row, [string[]]$Names, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   foreach($name in $Names) {
      $property = $Row.PSObject.Properties[$name]
      if($null -ne $property -and $null -ne $property.Value -and "$($property.Value)" -ne "") {
         return $property.Value
      }
   }
   return $Default
}

function To-DoubleOrNull {
   param([object]$Value)
   if($null -eq $Value) { return $null }
   $text = ([string]$Value).Trim()
   if($text -eq "") { return $null }
   $text = $text -replace "[$,%]", ""
   $result = 0.0
   if([double]::TryParse($text, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$result)) {
      return $result
   }
   return $null
}

function Format-Number {
   param([object]$Value, [int]$Digits = 4)
   if($null -eq $Value) { return "" }
   return ([Math]::Round([double]$Value, $Digits)).ToString([System.Globalization.CultureInfo]::InvariantCulture)
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

$auditRows = [System.Collections.Generic.List[object]]::new()

function Add-Gate {
   param(
      [string]$Gate,
      [string]$Status,
      [string]$Required,
      [string]$Actual,
      [string]$Evidence,
      [string]$Severity,
      [string]$NextAction
   )

   $auditRows.Add([pscustomobject]@{
      Gate = $Gate
      Status = $Status
      Required = $Required
      Actual = $Actual
      Evidence = $Evidence
      Severity = $Severity
      NextAction = $NextAction
   }) | Out-Null
}

function Add-NumericGate {
   param(
      [string]$Gate,
      [Nullable[double]]$Value,
      [double]$Minimum,
      [string]$Label,
      [string]$Evidence,
      [string]$Severity,
      [string]$NextAction
   )
   $status = if($null -eq $Value) { "PENDING" } elseif([double]$Value -ge $Minimum) { "PASS" } else { "FAIL" }
   Add-Gate $Gate $status "$Label >= $Minimum" "$Label=$(Format-Number $Value 4)" $Evidence $Severity $NextAction
}

function Add-MaxGate {
   param(
      [string]$Gate,
      [Nullable[double]]$Value,
      [double]$Maximum,
      [string]$Label,
      [string]$Evidence,
      [string]$Severity,
      [string]$NextAction
   )
   $status = if($null -eq $Value) { "PENDING" } elseif([double]$Value -le $Maximum) { "PASS" } else { "FAIL" }
   Add-Gate $Gate $status "$Label <= $Maximum" "$Label=$(Format-Number $Value 4)" $Evidence $Severity $NextAction
}

function Convert-ResultRow {
   param([object]$Row, [string]$Source)
   $net = To-DoubleOrNull (Get-Value $Row @("NetProfit"))
   $returnPct = To-DoubleOrNull (Get-Value $Row @("TotalReturnPercent"))
   $ddPct = To-DoubleOrNull (Get-Value $Row @("MaxDrawdownPercent"))
   $returnToDd = if($null -eq $returnPct -or $null -eq $ddPct) {
      $null
   } elseif([double]$ddPct -le 0.0) {
      if([double]$returnPct -ge 0.0) { [double]::PositiveInfinity } else { [double]::NegativeInfinity }
   } else {
      [double]$returnPct / [double]$ddPct
   }

   return [pscustomobject]@{
      Source = $Source
      Phase = [string](Get-Value $Row @("Phase"))
      Profile = [string](Get-Value $Row @("Profile"))
      Set = [string](Get-Value $Row @("Set"))
      Window = [string](Get-Value $Row @("Window"))
      From = [string](Get-Value $Row @("From"))
      To = [string](Get-Value $Row @("To"))
      ExpectedReportName = [string](Get-Value $Row @("ExpectedReportName"))
      Status = [string](Get-Value $Row @("Status"))
      NetProfit = $net
      TotalReturnPercent = $returnPct
      AnnualizedReturnPercent = To-DoubleOrNull (Get-Value $Row @("AnnualizedReturnPercent"))
      CagrPercent = To-DoubleOrNull (Get-Value $Row @("CagrPercent"))
      ReturnToDrawdown = $returnToDd
      ProfitFactor = To-DoubleOrNull (Get-Value $Row @("ProfitFactor"))
      ExpectedPayoff = To-DoubleOrNull (Get-Value $Row @("ExpectedPayoff"))
      SharpeRatio = To-DoubleOrNull (Get-Value $Row @("SharpeRatio"))
      WinRatePercent = To-DoubleOrNull (Get-Value $Row @("WinRatePercent"))
      TotalTrades = To-DoubleOrNull (Get-Value $Row @("TotalTrades"))
      MaxConsecutiveLosses = To-DoubleOrNull (Get-Value $Row @("MaxConsecutiveLosses"))
      MaxDrawdownPercent = $ddPct
      RecoveryFactor = To-DoubleOrNull (Get-Value $Row @("RecoveryFactor"))
   }
}

$validationRowsRaw = @(Read-CsvSafe $ValidationResultsPath)
$brokerRowsRaw = @(Read-CsvSafe $BrokerProxyResultsPath)
$validationRows = @($validationRowsRaw | ForEach-Object { Convert-ResultRow $_ "validation" })
$brokerRows = @($brokerRowsRaw | ForEach-Object { Convert-ResultRow $_ "broker_proxy" })
$allRows = @($validationRows + $brokerRows)
$parsedRows = @($allRows | Where-Object Status -eq "PARSED")
$expectedRows = $ExpectedValidationRows + $ExpectedBrokerRows
$parsedExpectedRows = @($allRows | Where-Object Status -eq "PARSED").Count
$missingOrUnparsed = @($allRows | Where-Object Status -ne "PARSED").Count

$coverageStatus = if($validationRowsRaw.Count -lt $ExpectedValidationRows -or $brokerRowsRaw.Count -lt $ExpectedBrokerRows) {
   "PENDING"
} elseif($parsedExpectedRows -eq $expectedRows) {
   "PASS"
} elseif($missingOrUnparsed -gt 0) {
   "PENDING"
} else {
   "FAIL"
}
Add-Gate "full-evidence-coverage" $coverageStatus `
   "all $ExpectedValidationRows validation and $ExpectedBrokerRows broker-proxy reports are parsed exported MT5 reports" `
   "validationRows=$($validationRowsRaw.Count)/$ExpectedValidationRows; brokerRows=$($brokerRowsRaw.Count)/$ExpectedBrokerRows; parsed=$parsedExpectedRows/$expectedRows; missingOrUnparsed=$missingOrUnparsed" `
   "$ValidationResultsPath; $BrokerProxyResultsPath" `
   "blocking" `
   "Return every exported MT5 validation and broker-proxy report before judging efficiency."

$missingStats = @($parsedRows | Where-Object {
   $null -eq $_.NetProfit -or
   $null -eq $_.TotalReturnPercent -or
   $null -eq $_.AnnualizedReturnPercent -or
   $null -eq $_.CagrPercent -or
   $null -eq $_.ProfitFactor -or
   $null -eq $_.ExpectedPayoff -or
   $null -eq $_.SharpeRatio -or
   $null -eq $_.WinRatePercent -or
   $null -eq $_.TotalTrades -or
   $null -eq $_.MaxConsecutiveLosses -or
   $null -eq $_.MaxDrawdownPercent -or
   $null -eq $_.RecoveryFactor
})
$statsStatus = if($parsedRows.Count -eq 0) { "PENDING" } elseif($missingStats.Count -eq 0) { "PASS" } else { "FAIL" }
Add-Gate "full-stat-completeness" $statsStatus `
   "every parsed report has return, annualized, CAGR, PF, expected payoff, Sharpe, win rate, trades, loss streak, drawdown, and recovery stats" `
   "parsed=$($parsedRows.Count); missingStats=$($missingStats.Count)" `
   "$ValidationResultsPath; $BrokerProxyResultsPath" `
   "blocking" `
   "Export full MT5 tester reports, not screenshots or balance-only snippets."

$continuous = $validationRows | Where-Object { $_.Phase -eq "phase1_exact_realtick" -and $_.Window -eq "continuous_2024_2026" } | Select-Object -First 1
if($null -eq $continuous -or $continuous.Status -ne "PARSED") {
   Add-Gate "exact-continuous-report-present" "PENDING" "exact real-tick continuous report is parsed" "status=$(if($continuous) { $continuous.Status } else { 'missing' })" $ValidationResultsPath "blocking" "Return the exact real-tick continuous exported report."
} else {
   Add-Gate "exact-continuous-report-present" "PASS" "exact real-tick continuous report is parsed" "status=PARSED; report=$($continuous.ExpectedReportName)" $ValidationResultsPath "blocking" "Use this row as the main efficiency anchor."
}
$continuousAnnualized = if($null -eq $continuous -or $continuous.Status -ne "PARSED") { $null } else { $continuous.AnnualizedReturnPercent }
$continuousCagr = if($null -eq $continuous -or $continuous.Status -ne "PARSED") { $null } else { $continuous.CagrPercent }
$continuousReturnToDd = if($null -eq $continuous -or $continuous.Status -ne "PARSED") { $null } else { $continuous.ReturnToDrawdown }
$continuousDd = if($null -eq $continuous -or $continuous.Status -ne "PARSED") { $null } else { $continuous.MaxDrawdownPercent }
$continuousTrades = if($null -eq $continuous -or $continuous.Status -ne "PARSED") { $null } else { $continuous.TotalTrades }

Add-NumericGate "growth:continuous-annualized-return" $continuousAnnualized $MinContinuousAnnualizedReturnPercent "continuous annualized return %" $ValidationResultsPath "blocking" "Do not promote a tiny-profit bot as money-ready."
Add-NumericGate "growth:continuous-cagr" $continuousCagr $MinContinuousCagrPercent "continuous CAGR %" $ValidationResultsPath "blocking" "Require compounding growth strong enough to justify the time/risk."
Add-NumericGate "efficiency:continuous-return-to-drawdown" $continuousReturnToDd $MinContinuousReturnToDrawdown "continuous return % / DD %" $ValidationResultsPath "blocking" "Require return to beat drawdown by a wide margin."
Add-MaxGate "risk:continuous-drawdown-cap" $continuousDd $MaxEquityDrawdownPercent "continuous equity DD %" $ValidationResultsPath "blocking" "Reject candidates whose profit requires too much drawdown."
Add-NumericGate "quality:continuous-trade-count" $continuousTrades $MinContinuousTrades "continuous trades" $ValidationResultsPath "blocking" "Avoid trusting too-few-trade luck."

$redRows = @($parsedRows | Where-Object { $null -ne $_.NetProfit -and [double]$_.NetProfit -lt 0.0 })
$redStatus = if($parsedRows.Count -eq 0) { "PENDING" } elseif($redRows.Count -eq 0) { "PASS" } else { "FAIL" }
Add-Gate "robustness:no-red-parsed-windows" $redStatus `
   "no parsed validation, stress, or broker-proxy window is net negative" `
   "parsed=$($parsedRows.Count); redWindows=$($redRows.Count); worst=$(if($redRows.Count -gt 0) { ($redRows | Sort-Object NetProfit | Select-Object -First 1).ExpectedReportName } else { '' })" `
   "$ValidationResultsPath; $BrokerProxyResultsPath" `
   "blocking" `
   "Do not promote until broad windows are non-red."

$pfSamples = @($parsedRows | Where-Object { $null -ne $_.ProfitFactor -and $null -ne $_.TotalTrades -and [double]$_.TotalTrades -gt 0 } | ForEach-Object { [double]$_.ProfitFactor })
$minPf = if($pfSamples.Count -gt 0) { ($pfSamples | Measure-Object -Minimum).Minimum } else { $null }
Add-NumericGate "quality:min-profit-factor" $minPf $MinProfitFactor "minimum parsed PF" "$ValidationResultsPath; $BrokerProxyResultsPath" "blocking" "Require enough edge across all active parsed reports."

$expectedSamples = @($parsedRows | Where-Object { $null -ne $_.ExpectedPayoff -and $null -ne $_.TotalTrades -and [double]$_.TotalTrades -gt 0 } | ForEach-Object { [double]$_.ExpectedPayoff })
$minExpected = if($expectedSamples.Count -gt 0) { ($expectedSamples | Measure-Object -Minimum).Minimum } else { $null }
Add-NumericGate "quality:min-expected-payoff" $minExpected $MinExpectedPayoff "minimum expected payoff" "$ValidationResultsPath; $BrokerProxyResultsPath" "blocking" "Avoid profiles whose apparent profit comes with negative expectancy."

$sharpeSamples = @($parsedRows | Where-Object { $null -ne $_.SharpeRatio -and $null -ne $_.TotalTrades -and [double]$_.TotalTrades -gt 0 } | ForEach-Object { [double]$_.SharpeRatio })
$minSharpe = if($sharpeSamples.Count -gt 0) { ($sharpeSamples | Measure-Object -Minimum).Minimum } else { $null }
Add-NumericGate "quality:min-sharpe" $minSharpe $MinSharpeRatio "minimum Sharpe ratio" "$ValidationResultsPath; $BrokerProxyResultsPath" "blocking" "Require positive risk-adjusted behavior."

$winSamples = @($parsedRows | Where-Object { $null -ne $_.WinRatePercent -and $null -ne $_.TotalTrades -and [double]$_.TotalTrades -gt 0 } | ForEach-Object { [double]$_.WinRatePercent })
$minWin = if($winSamples.Count -gt 0) { ($winSamples | Measure-Object -Minimum).Minimum } else { $null }
Add-NumericGate "quality:min-win-rate" $minWin $MinWinRatePercent "minimum win rate %" "$ValidationResultsPath; $BrokerProxyResultsPath" "blocking" "Avoid extremely brittle win/loss distributions."

$lossSamples = @($parsedRows | Where-Object { $null -ne $_.MaxConsecutiveLosses -and $null -ne $_.TotalTrades -and [double]$_.TotalTrades -gt 0 } | ForEach-Object { [double]$_.MaxConsecutiveLosses })
$worstLosses = if($lossSamples.Count -gt 0) { ($lossSamples | Measure-Object -Maximum).Maximum } else { $null }
Add-MaxGate "risk:consecutive-loss-cap" $worstLosses $MaxConsecutiveLosses "worst consecutive losses" "$ValidationResultsPath; $BrokerProxyResultsPath" "blocking" "Keep loss streaks survivable before any live review."

$recoverySamples = @($parsedRows | Where-Object { $null -ne $_.RecoveryFactor -and $null -ne $_.TotalTrades -and [double]$_.TotalTrades -gt 0 } | ForEach-Object { [double]$_.RecoveryFactor })
$minRecovery = if($recoverySamples.Count -gt 0) { ($recoverySamples | Measure-Object -Minimum).Minimum } else { $null }
Add-NumericGate "efficiency:min-recovery-factor" $minRecovery $MinRecoveryFactor "minimum recovery factor" "$ValidationResultsPath; $BrokerProxyResultsPath" "blocking" "Require profit to recover drawdown efficiently."

$recentRows = @($parsedRows | Where-Object { $_.Window -eq "2026_ytd" -or $_.From -like "2026.*" })
$recentRed = @($recentRows | Where-Object { $null -ne $_.NetProfit -and [double]$_.NetProfit -lt 0.0 })
$recentAnnualizedSamples = @($recentRows | Where-Object { $null -ne $_.AnnualizedReturnPercent -and $null -ne $_.TotalTrades -and [double]$_.TotalTrades -gt 0 } | ForEach-Object { [double]$_.AnnualizedReturnPercent })
$minRecentAnnualized = if($recentAnnualizedSamples.Count -gt 0) { ($recentAnnualizedSamples | Measure-Object -Minimum).Minimum } else { $null }
$recentStatus = if($recentRows.Count -eq 0) {
   "PENDING"
} elseif($recentRed.Count -gt 0) {
   "FAIL"
} elseif($null -eq $minRecentAnnualized) {
   "PENDING"
} elseif([double]$minRecentAnnualized -ge $MinRecentAnnualizedReturnPercent) {
   "PASS"
} else {
   "FAIL"
}
Add-Gate "growth:recent-2026-evidence" $recentStatus `
   "recent/2026 parsed rows are non-red and annualized return >= $MinRecentAnnualizedReturnPercent%" `
   "recentRows=$($recentRows.Count); redRecent=$($recentRed.Count); minRecentAnnualized=$(Format-Number $minRecentAnnualized 4)" `
   "$ValidationResultsPath; $BrokerProxyResultsPath" `
   "blocking" `
   "Require the bot to still work on newer data, not only older windows."

$stressBrokerRows = @($parsedRows | Where-Object { $_.Source -eq "broker_proxy" -or $_.Phase -eq "phase4_stress_realtick" -or $_.Phase -eq "phase5_broker_proxy_realtick" })
$stressBrokerRed = @($stressBrokerRows | Where-Object { $null -ne $_.NetProfit -and [double]$_.NetProfit -lt 0.0 })
$stressBrokerWeakPf = @($stressBrokerRows | Where-Object { $null -ne $_.ProfitFactor -and [double]$_.ProfitFactor -lt $MinProfitFactor -and $null -ne $_.TotalTrades -and [double]$_.TotalTrades -gt 0 })
$stressStatus = if($stressBrokerRows.Count -eq 0) {
   "PENDING"
} elseif($stressBrokerRed.Count -gt 0 -or $stressBrokerWeakPf.Count -gt 0) {
   "FAIL"
} else {
   "PASS"
}
Add-Gate "robustness:stress-and-broker-survival" $stressStatus `
   "stress and broker-proxy parsed rows are non-red and have PF >= $MinProfitFactor when trades exist" `
   "stressBrokerRows=$($stressBrokerRows.Count); red=$($stressBrokerRed.Count); weakPF=$($stressBrokerWeakPf.Count)" `
   "$ValidationResultsPath; $BrokerProxyResultsPath" `
   "blocking" `
   "Reject profiles that only work under the primary/default test condition."

$failCount = @($auditRows | Where-Object Status -eq "FAIL").Count
$pendingCount = @($auditRows | Where-Object Status -eq "PENDING").Count
$passCount = @($auditRows | Where-Object Status -eq "PASS").Count
$overall = if($failCount -gt 0) { "FAIL" } elseif($pendingCount -gt 0) { "PENDING" } else { "PASS" }
$verdict = if($overall -eq "PASS") {
   "EFFICIENCY_TARGETS_MET"
} elseif($overall -eq "FAIL") {
   "NOT_EFFICIENT_ENOUGH"
} else {
   "WAITING_FOR_EVIDENCE"
}

$outCsvPath = Resolve-RepoPath $OutCsv
$outMarkdownPath = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $outCsvPath
Ensure-ParentDir $outMarkdownPath
$auditRows | Export-Csv -LiteralPath $outCsvPath -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Money-Ready Efficiency Audit")
$md.Add("")
$md.Add("Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.")
$md.Add("")
$md.Add(("- Overall: **{0}**" -f $overall))
$md.Add(("- Verdict: **{0}**" -f $verdict))
$md.Add(('- Passing gates: `{0}`' -f $passCount))
$md.Add(('- Pending gates: `{0}`' -f $pendingCount))
$md.Add(('- Failed gates: `{0}`' -f $failCount))
$md.Add(('- Continuous annualized return target: `{0}%`' -f $MinContinuousAnnualizedReturnPercent))
$md.Add(('- Continuous CAGR target: `{0}%`' -f $MinContinuousCagrPercent))
$md.Add(('- Continuous return/DD target: `{0}`' -f $MinContinuousReturnToDrawdown))
$md.Add(('- Max equity DD target: `{0}%`' -f $MaxEquityDrawdownPercent))
$md.Add("")
if($overall -eq "PASS") {
   $md.Add("The returned evidence clears the current money-ready efficiency targets. This is still not a live-trading approval by itself.")
} elseif($overall -eq "FAIL") {
   $md.Add("The returned evidence is not efficient enough for the money-ready target. Do not promote this profile.")
} else {
   $md.Add("The efficiency decision is pending because broad exported MT5 evidence is still missing or incomplete.")
}
$md.Add("")
$md.Add("## Gates")
$md.Add("")
$md.Add("| Gate | Status | Required | Actual | Evidence | Next Action |")
$md.Add("| --- | --- | --- | --- | --- | --- |")
foreach($row in $auditRows) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} |" -f
      (Escape-MarkdownCell $row.Gate),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.Required),
      (Escape-MarkdownCell $row.Actual),
      (Escape-MarkdownCell $row.Evidence),
      (Escape-MarkdownCell $row.NextAction)))
}

$md | Set-Content -LiteralPath $outMarkdownPath -Encoding ASCII

[pscustomobject]@{
   Overall = $overall
   Verdict = $verdict
   Pass = $passCount
   Pending = $pendingCount
   Fail = $failCount
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
