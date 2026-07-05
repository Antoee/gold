param(
   [string]$BatchCsv = "outputs\NEXT_PROFIT_SEARCH_BATCH.csv",
   [string]$ProfilesCsv = "work\generated_profit_search\PROFIT_SEARCH_PROFILES.csv",
   [string]$ResearchBriefCsv = "outputs\STRATEGY_RESEARCH_BRIEF.csv",
   [string]$CoverageCsv = "outputs\PROFIT_SEARCH_COVERAGE_AUDIT.csv",
   [string]$OutCsv = "outputs\PROFIT_SEARCH_BATCH_RATIONALE.csv",
   [string]$OutMarkdown = "outputs\PROFIT_SEARCH_BATCH_RATIONALE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-CsvOrEmpty {
   param([Parameter(Mandatory = $true)][string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { return @() }
   return @(Import-Csv -LiteralPath $Path)
}

function Get-ProfileFamily {
   param([string]$Profile)
   if($Profile -eq "baseline_promoted") { return "baseline" }
   if($Profile -match "tp\d+_sl\d+") { return "take_profit_stop" }
   if($Profile -match "^tp\d+") { return "take_profit" }
   if($Profile -match "^trail") { return "trailing" }
   if($Profile -match "^rr") { return "risk_reward" }
   if($Profile -match "^risk") { return "risk" }
   if($Profile -match "^giveback") { return "giveback" }
   if($Profile -match "^be") { return "break_even" }
   return "other"
}

function Get-ResearchAlignment {
   param([string]$Profile, [string]$Family)
   if($Profile -eq "baseline_promoted") { return [pscustomobject]@{ Tier = "Baseline anchor"; Score = 5; Note = "Required comparison anchor for detecting data drift and candidate uplift." } }
   if($Profile -in @("tp38_sl18", "tp38_sl16")) { return [pscustomobject]@{ Tier = "Evidence-backed upside"; Score = 5; Note = "Matches the TP 3.8 / SL 1.6-1.8 thesis from existing zero-loss stress evidence." } }
   if($Profile -in @("tp42_sl18", "tp42_sl16", "tp45_sl18")) { return [pscustomobject]@{ Tier = "Adjacent upside"; Score = 4; Note = "Nearby TP expansion around the current evidence-backed profit search." } }
   if($Family -in @("trailing", "giveback", "break_even")) { return [pscustomobject]@{ Tier = "Risk-control variant"; Score = 3; Note = "Could improve loss control, but may reduce winner size; validate expectancy carefully." } }
   if($Family -in @("risk", "risk_reward")) { return [pscustomobject]@{ Tier = "Risk/expectancy probe"; Score = 2; Note = "Useful only after core TP/SL evidence is known; watch drawdown and losing windows." } }
   return [pscustomobject]@{ Tier = "General research"; Score = 1; Note = "No special offline thesis support yet." }
}

if(!(Test-Path -LiteralPath $BatchCsv)) { throw "Batch CSV not found: $BatchCsv" }
if(!(Test-Path -LiteralPath $ProfilesCsv)) { throw "Profiles CSV not found: $ProfilesCsv" }

$batch = @(Import-Csv -LiteralPath $BatchCsv)
$profiles = @(Import-Csv -LiteralPath $ProfilesCsv)
$research = Read-CsvOrEmpty $ResearchBriefCsv
$coverage = Read-CsvOrEmpty $CoverageCsv

$profileMap = @{}
foreach($profile in $profiles) { $profileMap[[string]$profile.Profile] = $profile }

$coverageMap = @{}
foreach($row in $coverage) {
   if($row.PSObject.Properties.Name -contains "Profile") { $coverageMap[[string]$row.Profile] = $row }
}

$knownResearchProfiles = @{}
foreach($row in $research) {
   $theme = [string]$row.Theme
   foreach($profile in @("baseline_promoted", "tp38_sl18", "tp38_sl16", "risk160_sl18_tp38", "risk160_sl16_tp38")) {
      if($theme -like "*$profile*" -or ($profile -eq "baseline_promoted" -and $theme -like "*Current BOS+sweep*")) { $knownResearchProfiles[$profile] = $row }
   }
}

$rows = New-Object System.Collections.Generic.List[object]
foreach($item in $batch) {
   $profileName = [string]$item.Profile
   $profile = if($profileMap.ContainsKey($profileName)) { $profileMap[$profileName] } else { $null }
   $family = if($null -ne $profile -and $profile.PSObject.Properties.Name -contains "Family") { [string]$profile.Family } else { Get-ProfileFamily $profileName }
   if([string]::IsNullOrWhiteSpace($family)) { $family = Get-ProfileFamily $profileName }
   $phase = [string]$item.Phase
   $set = [string]$item.Set
   $window = [string]$item.Window
   $alignment = Get-ResearchAlignment -Profile $profileName -Family $family
   $phaseValue = if($phase -eq "phase1_fast_triage") { 2 } elseif($phase -eq "phase2_real_tick_validation") { 4 } else { 1 }
   $stressValue = if($set -eq "stress") { 3 } elseif($window -eq "full" -or $set -eq "full") { 2 } else { 1 }
   $baselineValue = if($profileName -eq "baseline_promoted") { 2 } else { 0 }
   $riskPenalty = 0
   $riskNote = "normal"
   if($profileName -match "risk20") { $riskPenalty = 3; $riskNote = "aggressive risk, prune only" }
   elseif($family -eq "risk") { $riskPenalty = 1; $riskNote = "risk-sizing probe" }
   elseif($family -eq "giveback") { $riskPenalty = 1; $riskNote = "guard can cut winners" }
   elseif($family -eq "break_even") { $riskPenalty = 1; $riskNote = "breakeven can reduce expectancy" }
   $coverageNote = "not in coverage audit"
   if($coverageMap.ContainsKey($profileName)) {
      $coverageRow = $coverageMap[$profileName]
      if($coverageRow.PSObject.Properties.Name -contains "RiskNote") { $coverageNote = [string]$coverageRow.RiskNote }
   }
   $rationaleScore = ($alignment.Score * 10) + ($phaseValue * 3) + $stressValue + $baselineValue - $riskPenalty
   $decision = if($phase -eq "phase1_fast_triage") { "Run as fast prune only; do not promote from this result." } elseif($phase -eq "phase2_real_tick_validation") { "Run only after phase-1 evidence is clean; promotion still requires full gate." } else { "Review manually." }
   $rows.Add([pscustomobject]@{
      Rank = [int]$item.Rank; Profile = $profileName; Phase = $phase; Set = $set; Window = $window; Model = $item.Model; Family = $family; ResearchTier = $alignment.Tier; RationaleScore = [Math]::Round($rationaleScore, 2); RiskNote = $riskNote; CoverageNote = $coverageNote; WhyThisRun = $alignment.Note; DecisionRule = $decision; ExpectedReportName = $item.ExpectedReportName; Config = $item.Config
   }) | Out-Null
}

$rows | Sort-Object Rank | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$byProfile = @($rows | Group-Object Profile | Sort-Object @{ Expression = { ($_.Group | Select-Object -First 1).Rank } })
$byTier = @($rows | Group-Object ResearchTier | Sort-Object Count -Descending)

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Profit Search Batch Rationale") | Out-Null
$md.Add("") | Out-Null
$md.Add("Generated without launching MT5. This explains why the current next batch is worth tester time.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Batch source: ``$BatchCsv``") | Out-Null
$md.Add("- Profiles source: ``$ProfilesCsv``") | Out-Null
$md.Add("- Runs explained: $($rows.Count)") | Out-Null
$md.Add("- Phase-1 fast triage runs: $(@($rows | Where-Object { $_.Phase -eq 'phase1_fast_triage' }).Count)") | Out-Null
$md.Add("- Phase-2 real-tick runs: $(@($rows | Where-Object { $_.Phase -eq 'phase2_real_tick_validation' }).Count)") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Rationale Summary") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Tier | Runs |") | Out-Null
$md.Add("|---|---:|") | Out-Null
foreach($tier in $byTier) { $md.Add("| $($tier.Name) | $($tier.Count) |") | Out-Null }
$md.Add("") | Out-Null
$md.Add("## Profile Coverage In This Batch") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Profile | Runs | First Rank | Tier | Family | Risk Note |") | Out-Null
$md.Add("|---|---:|---:|---|---|---|") | Out-Null
foreach($group in $byProfile) {
   $first = $group.Group | Sort-Object Rank | Select-Object -First 1
   $md.Add("| ``$($group.Name)`` | $($group.Count) | $($first.Rank) | $($first.ResearchTier) | $($first.Family) | $($first.RiskNote) |") | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Run-Level Rationale") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Rank | Profile | Set | Window | Model | Tier | Why | Decision |") | Out-Null
$md.Add("|---:|---|---|---|---:|---|---|---|") | Out-Null
foreach($row in ($rows | Sort-Object Rank)) {
   $why = ([string]$row.WhyThisRun) -replace '\|', '/'
   $decision = ([string]$row.DecisionRule) -replace '\|', '/'
   $md.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Set) | $($row.Window) | $($row.Model) | $($row.ResearchTier) | $why | $decision |") | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Guardrail") | Out-Null
$md.Add("") | Out-Null
$md.Add("This rationale does not prove profitability. It only prioritizes scarce tester time. A candidate still needs parsed reports, phase-2 real ticks, zero losing validation windows, and the promotion gate before replacing the promoted default.") | Out-Null
Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8

[pscustomobject]@{ Runs = $rows.Count; Profiles = $byProfile.Count; OutCsv = $OutCsv; OutMarkdown = $OutMarkdown }
