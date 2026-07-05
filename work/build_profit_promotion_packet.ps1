param(
   [string]$Profile = "baseline_promoted",
   [string]$MetricsPath = "outputs\PROFIT_SEARCH_REPORT_METRICS.csv",
   [string]$ProfilesPath = "work\generated_profit_search\PROFIT_SEARCH_PROFILES.csv",
   [string]$GuardrailPath = "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.csv",
   [string]$OutDir = "outputs\promotion_packets",
   [double]$BaselineFullProfit = 866.59,
   [double]$BaselineSplitAggregate = 2354.65,
   [double]$MinimumWorstWindow = 0.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function To-Double {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Format-Money {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return "" }
   $number = To-Double $Value
   return $number.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture)
}

function Add-Gate {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Gate,
      [bool]$Pass,
      [string]$Evidence,
      [string]$Required
   )

   $Rows.Add([pscustomobject]@{
      Gate = $Gate
      Status = if($Pass) { "PASS" } else { "FAIL" }
      Evidence = $Evidence
      Required = $Required
   }) | Out-Null
}

if(!(Test-Path -LiteralPath $MetricsPath)) { throw "Metrics file not found: $MetricsPath" }
if(!(Test-Path -LiteralPath $ProfilesPath)) { throw "Profiles file not found: $ProfilesPath" }

$metrics = Import-Csv -LiteralPath $MetricsPath
$profiles = Import-Csv -LiteralPath $ProfilesPath
$guardrails = if(Test-Path -LiteralPath $GuardrailPath) { @(Import-Csv -LiteralPath $GuardrailPath) } else { @() }
$profileInfo = $profiles | Where-Object { $_.Profile -eq $Profile } | Select-Object -First 1
if($null -eq $profileInfo) {
   throw "Profile '$Profile' not found in $ProfilesPath"
}
$guardrail = $guardrails | Where-Object { $_.Profile -eq $Profile } | Select-Object -First 1

$rows = @($metrics | Where-Object { $_.Profile -eq $Profile })
$phase1Rows = @($rows | Where-Object { $_.Phase -eq "phase1_fast_triage" })
$phase2Rows = @($rows | Where-Object { $_.Phase -eq "phase2_real_tick_validation" })
$phase1Parsed = @($phase1Rows | Where-Object { $_.Status -eq "PARSED" -and "$($_.NetProfit)" -ne "" })
$phase2Parsed = @($phase2Rows | Where-Object { $_.Status -eq "PARSED" -and "$($_.NetProfit)" -ne "" })

$phase2Profits = @($phase2Parsed | ForEach-Object { To-Double $_.NetProfit } | Where-Object { $null -ne $_ })
$phase2SplitProfits = @($phase2Parsed | Where-Object { $_.Set -eq "split" } | ForEach-Object { To-Double $_.NetProfit } | Where-Object { $null -ne $_ })
$phase2Drawdowns = @($phase2Parsed | ForEach-Object { To-Double $_.MaxDrawdownMoney } | Where-Object { $null -ne $_ })
$phase2ProfitFactors = @($phase2Parsed | ForEach-Object { To-Double $_.ProfitFactor } | Where-Object { $null -ne $_ })
$phase2Full = $phase2Parsed | Where-Object { $_.Set -eq "split" -and $_.Window -eq "full" } | Select-Object -First 1

$phase2Expected = $phase2Rows.Count
$phase2Missing = @($phase2Rows | Where-Object { $_.Status -eq "MISSING_REPORT" }).Count
$phase2Unparsed = @($phase2Rows | Where-Object { $_.Status -eq "UNPARSED" }).Count
$phase2Complete = $phase2Expected -gt 0 -and $phase2Parsed.Count -eq $phase2Expected
$phase2Total = if($phase2Profits.Count -gt 0) { ($phase2Profits | Measure-Object -Sum).Sum } else { 0.0 }
$phase2SplitTotal = if($phase2SplitProfits.Count -gt 0) { ($phase2SplitProfits | Measure-Object -Sum).Sum } else { 0.0 }
$phase2Worst = if($phase2Profits.Count -gt 0) { ($phase2Profits | Measure-Object -Minimum).Minimum } else { $null }
$phase2Losing = @($phase2Profits | Where-Object { $_ -lt 0 }).Count
$phase2WorstDrawdown = if($phase2Drawdowns.Count -gt 0) { ($phase2Drawdowns | Measure-Object -Maximum).Maximum } else { $null }
$phase2AveragePf = if($phase2ProfitFactors.Count -gt 0) { ($phase2ProfitFactors | Measure-Object -Average).Average } else { $null }
$fullProfit = if($null -ne $phase2Full) { To-Double $phase2Full.NetProfit } else { $null }

$fullProfitEvidence = if($null -eq $fullProfit) { "missing full-period phase-2 report" } else { Format-Money $fullProfit }
$worstWindowEvidence = if($null -eq $phase2Worst) { "missing" } else { Format-Money $phase2Worst }
$drawdownEvidence = if($null -eq $phase2WorstDrawdown) { "missing" } else { Format-Money $phase2WorstDrawdown }
$profitFactorEvidence = if($null -eq $phase2AveragePf) { "missing" } else { $phase2AveragePf.ToString("0.0000", [Globalization.CultureInfo]::InvariantCulture) }
$guardrailStatus = if($null -eq $guardrail) { "MISSING" } else { [string]$guardrail.GuardrailStatus }
$guardrailScore = if($null -eq $guardrail) { "" } else { [string]$guardrail.GuardrailScore }
$riskFlags = if($null -eq $guardrail) { "missing guardrail audit" } else { [string]$guardrail.RiskFlags }
$overfitFlags = if($null -eq $guardrail) { "missing guardrail audit" } else { [string]$guardrail.OverfitFlags }
$equityDrawdownPct = if($null -eq $guardrail) { "" } else { [string]$guardrail.EquityDrawdownPct }
$guardrailEvidence = if($null -eq $guardrail) { "missing guardrail audit" } else { "status=$guardrailStatus, score=$guardrailScore, equity_dd=$equityDrawdownPct, risk_flags=$riskFlags, overfit_flags=$overfitFlags" }
$hasEquityGuard = $null -ne $guardrail -and (To-Double $guardrail.EquityDrawdownPct) -gt 0.0
$isBaseline = $Profile -eq "baseline_promoted"

$gateRows = New-Object System.Collections.Generic.List[object]
Add-Gate -Rows $gateRows -Gate "Optimization guardrail tracked" -Pass ($null -ne $guardrail -and $guardrailStatus -ne "REJECT_PROMOTION") -Evidence $guardrailEvidence -Required "Guardrail audit exists and does not reject promotion"
Add-Gate -Rows $gateRows -Gate "Equity drawdown guard active or baseline anchor" -Pass ($isBaseline -or $hasEquityGuard) -Evidence "InpMaxEquityDrawdownPercent=$equityDrawdownPct" -Required "Non-baseline candidates must use an equity drawdown guard"
Add-Gate -Rows $gateRows -Gate "Complete phase-2 evidence" -Pass $phase2Complete -Evidence "$($phase2Parsed.Count)/$phase2Expected parsed, $phase2Missing missing, $phase2Unparsed unparsed" -Required "Every phase-2 real-tick report parsed"
Add-Gate -Rows $gateRows -Gate "Full-period profit beats baseline" -Pass ($null -ne $fullProfit -and $fullProfit -gt $BaselineFullProfit) -Evidence $fullProfitEvidence -Required ("> " + (Format-Money $BaselineFullProfit))
Add-Gate -Rows $gateRows -Gate "Split aggregate beats baseline" -Pass ($phase2SplitTotal -gt $BaselineSplitAggregate) -Evidence (Format-Money $phase2SplitTotal) -Required ("> " + (Format-Money $BaselineSplitAggregate))
Add-Gate -Rows $gateRows -Gate "No losing phase-2 windows" -Pass ($phase2Complete -and $phase2Losing -eq 0) -Evidence "$phase2Losing losing windows" -Required "0 losing windows"
Add-Gate -Rows $gateRows -Gate "Worst window non-negative" -Pass ($phase2Complete -and $null -ne $phase2Worst -and $phase2Worst -ge $MinimumWorstWindow) -Evidence $worstWindowEvidence -Required (">= " + (Format-Money $MinimumWorstWindow))
Add-Gate -Rows $gateRows -Gate "Drawdown available for review" -Pass ($phase2Complete -and $null -ne $phase2WorstDrawdown) -Evidence $drawdownEvidence -Required "Parsed maximal drawdown"
Add-Gate -Rows $gateRows -Gate "Profit factor available for review" -Pass ($phase2Complete -and $null -ne $phase2AveragePf) -Evidence $profitFactorEvidence -Required "Parsed profit factor"

$allPassed = @($gateRows | Where-Object { $_.Status -ne "PASS" }).Count -eq 0
$decision = if($allPassed) { "PROMOTION_REVIEW" } elseif($phase2Parsed.Count -eq 0) { "MISSING_EVIDENCE" } else { "DO_NOT_PROMOTE" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$safeProfile = $Profile -replace '[^A-Za-z0-9_.-]', '_'
$outCsv = Join-Path $OutDir ("{0}_promotion_gates.csv" -f $safeProfile)
$outReport = Join-Path $OutDir ("{0}_promotion_packet.md" -f $safeProfile)
$gateRows | Export-Csv -LiteralPath $outCsv -NoTypeInformation

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Promotion Packet: $Profile") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated without launching MT5. This packet uses parsed report metrics only.") | Out-Null
$report.Add("") | Out-Null
$report.Add("- Decision: **$decision**") | Out-Null
$report.Add("- Profile priority: $($profileInfo.Priority)") | Out-Null
$report.Add("- Phase-2 seed: $($profileInfo.Phase2Seed)") | Out-Null
$report.Add("- Overrides: ``$($profileInfo.Overrides)``") | Out-Null
$report.Add("- Guardrail status: $guardrailStatus") | Out-Null
$report.Add("- Guardrail score: $guardrailScore") | Out-Null
$report.Add("- Equity drawdown guard: $equityDrawdownPct") | Out-Null
$report.Add("- Risk flags: ``$riskFlags``") | Out-Null
$report.Add("- Overfit flags: ``$overfitFlags``") | Out-Null
$report.Add("- Phase-1 parsed: $($phase1Parsed.Count)/$($phase1Rows.Count)") | Out-Null
$report.Add("- Phase-2 parsed: $($phase2Parsed.Count)/$phase2Expected") | Out-Null
$report.Add("- Phase-2 total net profit: $(Format-Money $phase2Total)") | Out-Null
$report.Add("- Phase-2 split aggregate: $(Format-Money $phase2SplitTotal)") | Out-Null
$report.Add("- Phase-2 worst window: $worstWindowEvidence") | Out-Null
$report.Add("- Phase-2 losing windows: $phase2Losing") | Out-Null
$report.Add("- Phase-2 worst drawdown: $drawdownEvidence") | Out-Null
$report.Add("- Phase-2 average profit factor: $profitFactorEvidence") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Gates") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Gate | Status | Evidence | Required |") | Out-Null
$report.Add("|---|---|---|---|") | Out-Null
foreach($gate in $gateRows) { $report.Add("| $($gate.Gate) | $($gate.Status) | $($gate.Evidence) | $($gate.Required) |") | Out-Null }
$report.Add("") | Out-Null
$report.Add("## Rule") | Out-Null
$report.Add("") | Out-Null
$report.Add("Only a `PROMOTION_REVIEW` packet may be considered for replacing the current default, and even then it still needs human review of drawdown shape, trade count, broker-data quality, and overfitting risk.") | Out-Null

Set-Content -LiteralPath $outReport -Value $report -Encoding UTF8

[pscustomobject]@{
   Profile = $Profile
   Decision = $decision
   Phase2Parsed = $phase2Parsed.Count
   Phase2Expected = $phase2Expected
   Phase2TotalNetProfit = [Math]::Round($phase2Total, 2)
   Phase2SplitAggregate = [Math]::Round($phase2SplitTotal, 2)
   Phase2WorstWindow = if($null -eq $phase2Worst) { "" } else { [Math]::Round($phase2Worst, 2) }
   Phase2LosingWindows = $phase2Losing
   Report = $outReport
   Gates = $outCsv
}
