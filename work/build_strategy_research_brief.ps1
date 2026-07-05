param(
   [string]$OutputsDir = "outputs",
   [string]$OutMarkdown = "outputs\STRATEGY_RESEARCH_BRIEF.md",
   [string]$OutCsv = "outputs\STRATEGY_RESEARCH_BRIEF.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-FirstRow {
   param([Parameter(Mandatory = $true)][string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { return $null }
   $rows = @(Import-Csv -LiteralPath $Path)
   if($rows.Count -eq 0) { return $null }
   return $rows[0]
}

function To-Double {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return 0.0 }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Add-Theme {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [Parameter(Mandatory = $true)][string]$Theme,
      [Parameter(Mandatory = $true)][string]$Status,
      [Parameter(Mandatory = $true)][string]$Evidence,
      [Parameter(Mandatory = $true)][double]$Profit,
      [Parameter(Mandatory = $true)][double]$Worst,
      [Parameter(Mandatory = $true)][int]$Losing,
      [Parameter(Mandatory = $true)][int]$Windows,
      [Parameter(Mandatory = $true)][string]$Decision,
      [Parameter(Mandatory = $true)][string]$NextAction
   )

   $riskTier = if($Losing -eq 0 -and $Worst -ge 0 -and $Windows -ge 7) {
      "Validated no-loss"
   }
   elseif($Losing -le 1 -and $Worst -gt -25 -and $Windows -ge 7) {
      "Low-loss research"
   }
   elseif($Windows -lt 7) {
      "Thin coverage"
   }
   else {
      "High caution"
   }

   $Rows.Add([pscustomobject]@{
      Theme = $Theme
      Status = $Status
      Evidence = $Evidence
      Profit = [Math]::Round($Profit, 2)
      WorstWindow = [Math]::Round($Worst, 2)
      LosingWindows = $Losing
      Windows = $Windows
      RiskTier = $riskTier
      Decision = $Decision
      NextAction = $NextAction
   }) | Out-Null
}

if(!(Test-Path -LiteralPath $OutputsDir)) {
   throw "Outputs directory not found: $OutputsDir"
}

$themes = New-Object System.Collections.Generic.List[object]

$promotedSplit = Read-FirstRow (Join-Path $OutputsDir "BOS_SWEEP_SPLIT_SUMMARY_risk1p6_sl18_tp35.csv")
$promotedQuarter = Read-FirstRow (Join-Path $OutputsDir "BOS_SWEEP_WINDOW_SUMMARY_risk1p6_sl18_tp35.csv")
$riskNeighborhood = @(Import-Csv -LiteralPath (Join-Path $OutputsDir "RISK16_NEIGHBORHOOD_SUMMARY.csv"))
$momentum = Read-FirstRow (Join-Path $OutputsDir "MOMENTUM_SWEEP_SPLIT_SUMMARY.csv")
$secondBuy = @(Import-Csv -LiteralPath (Join-Path $OutputsDir "SECOND_BUY_BLOCK_STANDARD_REAL_TICK_SUMMARY.csv"))
$profitSearchSummaryPath = Join-Path $OutputsDir "PROFIT_SEARCH_REPORT_SUMMARY.csv"
$profitSearchSummaryRows = if(Test-Path -LiteralPath $profitSearchSummaryPath) { @(Import-Csv -LiteralPath $profitSearchSummaryPath) } else { @() }

if($null -ne $promotedSplit) {
   Add-Theme $themes -Theme "Current BOS+sweep default" -Status "Keep promoted" -Evidence "Split validation: BOS_SWEEP_SPLIT_SUMMARY_risk1p6_sl18_tp35.csv" -Profit (To-Double $promotedSplit.TotalNetProfit) -Worst (To-Double $promotedSplit.WorstWindowNetProfit) -Losing ([int]$promotedSplit.LosingWindows) -Windows ([int]$promotedSplit.Windows) -Decision "This remains the active default because it has the strongest broad no-loss evidence." -NextAction "Use as baseline in every future candidate batch."
}

if($null -ne $promotedQuarter) {
   Add-Theme $themes -Theme "Monthly/quarter no-loss confirmation" -Status "Supports promoted default" -Evidence "Monthly/quarter validation: BOS_SWEEP_WINDOW_SUMMARY_risk1p6_sl18_tp35.csv" -Profit (To-Double $promotedQuarter.TotalNetProfit) -Worst (To-Double $promotedQuarter.WorstWindowNetProfit) -Losing ([int]$promotedQuarter.LosingWindows) -Windows ([int]$promotedQuarter.Windows) -Decision "The default is not just a full-period fit; it also survives smaller windows." -NextAction "Preserve these gates when searching for extra profit."
}

$tp38Candidates = @($riskNeighborhood | Where-Object { $_.Candidate -in @("risk160_sl18_tp38", "risk160_sl16_tp38") })
foreach($row in $tp38Candidates) {
   Add-Theme $themes -Theme "TP 3.8 neighborhood: $($row.Candidate)" -Status "Promising, unpromoted" -Evidence "Risk neighborhood stress windows: RISK16_NEIGHBORHOOD_SUMMARY.csv" -Profit (To-Double $row.TotalNetProfit) -Worst (To-Double $row.WorstWindowNetProfit) -Losing ([int]$row.LosingWindows) -Windows ([int]$row.Windows) -Decision "Looks better than the monthly/quarter baseline in limited windows, but lacks full phase-2 real-tick evidence." -NextAction "Prioritize fast stress prune, then phase-2 real ticks only if phase 1 does not reveal losses."
}

if($null -ne $momentum) {
   Add-Theme $themes -Theme "Momentum+sweep entry family" -Status "Research only" -Evidence "Split validation: MOMENTUM_SWEEP_SPLIT_SUMMARY.csv" -Profit (To-Double $momentum.TotalNetProfit) -Worst (To-Double $momentum.WorstWindowNetProfit) -Losing ([int]$momentum.LosingWindows) -Windows ([int]$momentum.Windows) -Decision "Profit is competitive, but it violates the current zero-losing-window preference." -NextAction "Use as a clue for confirmation logic, not as a default profile."
}

if($secondBuy.Count -gt 0) {
   $yearly = $secondBuy | Where-Object { $_.Group -eq "yearly" } | Select-Object -First 1
   $walk = $secondBuy | Where-Object { $_.Group -eq "walk_forward" } | Select-Object -First 1
   if($null -ne $yearly) {
      Add-Theme $themes -Theme "Date-block buy benchmark, yearly" -Status "Benchmark only" -Evidence "SECOND_BUY_BLOCK_STANDARD_REAL_TICK_SUMMARY.csv" -Profit (To-Double $yearly.TotalNetProfit) -Worst (To-Double $yearly.WorstNetProfit) -Losing ([int]$yearly.LosingWindows) -Windows ([int]$yearly.Windows) -Decision "High profit, but calendar-specific blocking has overfitting risk." -NextAction "Translate only if a general regime rule explains it."
   }
   if($null -ne $walk) {
      Add-Theme $themes -Theme "Date-block buy benchmark, walk-forward" -Status "Benchmark only" -Evidence "SECOND_BUY_BLOCK_STANDARD_REAL_TICK_SUMMARY.csv" -Profit (To-Double $walk.TotalNetProfit) -Worst (To-Double $walk.WorstNetProfit) -Losing ([int]$walk.LosingWindows) -Windows ([int]$walk.Windows) -Decision "Walk-forward result is strong, but the rule source is still date-specific." -NextAction "Research volatility/trend/session explanations before considering any implementation."
   }
}

if($profitSearchSummaryRows.Count -gt 0) {
   $expected = [int](($profitSearchSummaryRows | ForEach-Object { To-Double $_.ReportsExpected } | Measure-Object -Sum).Sum)
   $parsed = [int](($profitSearchSummaryRows | ForEach-Object { To-Double $_.ReportsParsed } | Measure-Object -Sum).Sum)
   Add-Theme $themes -Theme "Profit-search evidence gap" -Status "Missing tester evidence" -Evidence "PROFIT_SEARCH_REPORT_SUMMARY.csv" -Profit 0 -Worst 0 -Losing 0 -Windows $parsed -Decision "$parsed of $expected profit-search reports are parsed; no new profile can be promoted from this pack yet." -NextAction "Run only the audited handoff batch during a controlled safe testing window."
}

$themes | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$ordered = @($themes | Sort-Object @{ Expression = { if($_.Status -eq "Keep promoted") { 0 } elseif($_.Status -like "Promising*") { 1 } elseif($_.Status -like "Research*") { 2 } else { 3 } } }, @{ Expression = "Profit"; Descending = $true })

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Strategy Research Brief") | Out-Null
$md.Add("") | Out-Null
$md.Add("Generated from existing offline reports only. No MT5 process was launched.") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Executive Read") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Keep ``risk1p6_sl18_tp35`` as the promoted BOS+sweep default until a candidate beats it with complete phase-2 real-tick evidence.") | Out-Null
$md.Add("- The most sensible profit-improvement search remains TP expansion around ``3.8`` with SL ``1.6`` to ``1.8``; it has zero-loss stress evidence but is not fully validated.") | Out-Null
$md.Add("- Momentum+sweep and date-block results are useful research clues, not default replacements.") | Out-Null
$md.Add("- No new profile should be promoted while profit-search reports remain missing.") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Evidence Themes") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Theme | Status | Profit | Worst | Losing | Windows | Risk Tier | Decision | Next Action |") | Out-Null
$md.Add("|---|---|---:|---:|---:|---:|---|---|---|") | Out-Null
foreach($row in $ordered) {
   $decision = ([string]$row.Decision) -replace '\|', '/'
   $next = ([string]$row.NextAction) -replace '\|', '/'
   $md.Add("| ``$($row.Theme)`` | $($row.Status) | $($row.Profit) | $($row.WorstWindow) | $($row.LosingWindows) | $($row.Windows) | $($row.RiskTier) | $decision | $next |") | Out-Null
}

$md.Add("") | Out-Null
$md.Add("## Research Discipline") | Out-Null
$md.Add("") | Out-Null
$md.Add("1. Do not promote from phase 1 or single-window evidence.") | Out-Null
$md.Add("2. Any replacement must beat the current full-period profit target while preserving zero losing split/month/quarter windows.") | Out-Null
$md.Add("3. Date-specific blocks should become general market-regime filters before they are eligible for promotion.") | Out-Null
$md.Add("4. Profit expansion should be searched near already profitable behavior first: TP, stop width, trailing, breakeven, and giveback guard variants around the promoted BOS+sweep core.") | Out-Null

Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8

[pscustomobject]@{
   Themes = $themes.Count
   OutMarkdown = $OutMarkdown
   OutCsv = $OutCsv
}
