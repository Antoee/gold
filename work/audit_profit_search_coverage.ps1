param(
   [string]$ProfilesPath = "work\generated_profit_search\PROFIT_SEARCH_PROFILES.csv",
   [string]$ManifestPath = "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv",
   [string]$OutCsv = "outputs\PROFIT_SEARCH_COVERAGE_AUDIT.csv",
   [string]$OutReport = "outputs\PROFIT_SEARCH_COVERAGE_AUDIT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-Settings {
   param([string]$Path)

   $settings = @{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if([string]::IsNullOrWhiteSpace($line)) { continue }
      if($line.TrimStart().StartsWith(";")) { continue }
      $parts = $line -split "=", 2
      if($parts.Count -ne 2) { continue }
      $rawValue = $parts[1].Trim()
      $value = ($rawValue -split "\|\|", 2)[0]
      $settings[$parts[0].Trim()] = $value
   }
   return $settings
}

function Get-Setting {
   param(
      [hashtable]$Settings,
      [string]$Name,
      [string]$Default = ""
   )

   if($Settings.ContainsKey($Name)) { return [string]$Settings[$Name] }
   return $Default
}

function To-Double {
   param([string]$Value)
   if([string]::IsNullOrWhiteSpace($Value)) { return $null }
   return [double]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture)
}

if(!(Test-Path -LiteralPath $ProfilesPath)) { throw "Profiles manifest not found: $ProfilesPath" }
if(!(Test-Path -LiteralPath $ManifestPath)) { throw "Config manifest not found: $ManifestPath" }

$profiles = Import-Csv -LiteralPath $ProfilesPath
$manifest = Import-Csv -LiteralPath $ManifestPath
$rows = New-Object System.Collections.Generic.List[object]

foreach($profile in ($profiles | Sort-Object {[int]$_.Priority})) {
   $settingsPath = [string]$profile.Settings
   if(!(Test-Path -LiteralPath $settingsPath)) {
      throw "Settings file not found for $($profile.Profile): $settingsPath"
   }

   $settings = Read-Settings -Path $settingsPath
   $phase1Count = @($manifest | Where-Object { $_.Profile -eq $profile.Profile -and $_.Phase -eq "phase1_fast_triage" }).Count
   $phase2Count = @($manifest | Where-Object { $_.Profile -eq $profile.Profile -and $_.Phase -eq "phase2_real_tick_validation" }).Count
   $risk = To-Double (Get-Setting $settings "InpRiskPercent")
   $sl = To-Double (Get-Setting $settings "InpStopATRMultiplier")
   $tp = To-Double (Get-Setting $settings "InpTakeProfitATRMultiplier")
   $rr = To-Double (Get-Setting $settings "InpMinRiskReward")
   $trail = To-Double (Get-Setting $settings "InpTrailATRMultiplier")
   $breakEven = Get-Setting $settings "InpUseBreakEven"
   $giveback = Get-Setting $settings "InpUseProfitGivebackGuard"

   $riskBand = if($null -eq $risk) {
      "unknown"
   } elseif($risk -lt 1.6) {
      "reduced"
   } elseif($risk -eq 1.6) {
      "baseline"
   } elseif($risk -le 1.8) {
      "moderate"
   } else {
      "aggressive"
   }

   $changeFamily = New-Object System.Collections.Generic.List[string]
   if($profile.Profile -eq "baseline_promoted") { $changeFamily.Add("baseline") | Out-Null }
   if([string]$profile.Overrides -match "InpTakeProfitATRMultiplier") { $changeFamily.Add("take_profit") | Out-Null }
   if([string]$profile.Overrides -match "InpStopATRMultiplier") { $changeFamily.Add("stop_loss") | Out-Null }
   if([string]$profile.Overrides -match "InpTrailATRMultiplier") { $changeFamily.Add("trailing") | Out-Null }
   if([string]$profile.Overrides -match "InpRiskPercent") { $changeFamily.Add("risk") | Out-Null }
   if([string]$profile.Overrides -match "InpMinRiskReward") { $changeFamily.Add("risk_reward") | Out-Null }
   if([string]$profile.Overrides -match "InpUseProfitGivebackGuard") { $changeFamily.Add("giveback") | Out-Null }
   if([string]$profile.Overrides -match "InpUseBreakEven") { $changeFamily.Add("break_even") | Out-Null }
   if($changeFamily.Count -eq 0) { $changeFamily.Add("unknown") | Out-Null }

   $promotableSeed = [string]$profile.Phase2Seed -eq "True"
   $riskNote = "ok"
   if($riskBand -eq "aggressive" -and $promotableSeed) {
      $riskNote = "phase2 aggressive risk needs extra caution"
   } elseif($riskBand -eq "aggressive") {
      $riskNote = "aggressive risk, phase1 prune only"
   } elseif($changeFamily -contains "giveback") {
      $riskNote = "guard behavior must preserve full-period profit"
   } elseif($changeFamily -contains "break_even") {
      $riskNote = "breakeven can reduce winners; validate expectancy"
   }

   $rows.Add([pscustomobject]@{
      Priority = [int]$profile.Priority
      Profile = $profile.Profile
      Phase2Seed = $promotableSeed
      Phase1Configs = $phase1Count
      Phase2Configs = $phase2Count
      Family = ($changeFamily -join "+")
      RiskBand = $riskBand
      RiskPercent = if($null -eq $risk) { "" } else { $risk.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture) }
      StopATR = if($null -eq $sl) { "" } else { $sl.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture) }
      TakeProfitATR = if($null -eq $tp) { "" } else { $tp.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture) }
      MinRR = if($null -eq $rr) { "" } else { $rr.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture) }
      TrailATR = if($null -eq $trail) { "" } else { $trail.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture) }
      BreakEven = $breakEven
      GivebackGuard = $giveback
      Overrides = $profile.Overrides
      RiskNote = $riskNote
   }) | Out-Null
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$families = $rows | Group-Object Family | Sort-Object Name
$riskBands = $rows | Group-Object RiskBand | Sort-Object Name
$phase2Rows = @($rows | Where-Object Phase2Seed -eq $true)
$phase1OnlyRows = @($rows | Where-Object Phase2Seed -ne $true)
$aggressiveRows = @($rows | Where-Object RiskBand -eq "aggressive")
$hasReducedRisk = @($rows | Where-Object RiskBand -eq "reduced").Count -gt 0
$hasBaseline = @($rows | Where-Object Family -eq "baseline").Count -gt 0
$hasGiveback = @($rows | Where-Object { $_.Family -match "giveback" }).Count -gt 0
$hasBreakEven = @($rows | Where-Object { $_.Family -match "break_even" }).Count -gt 0
$hasTrailing = @($rows | Where-Object { $_.Family -match "trailing" }).Count -gt 0

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Profit Search Coverage Audit") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated without launching MT5. This audits the candidate search space and risk coverage only.") | Out-Null
$report.Add("") | Out-Null
$report.Add("- Profiles: $($rows.Count)") | Out-Null
$report.Add("- Phase-2 seeds: $($phase2Rows.Count)") | Out-Null
$report.Add("- Phase-1 only: $($phase1OnlyRows.Count)") | Out-Null
$report.Add("- Aggressive-risk profiles: $($aggressiveRows.Count)") | Out-Null
$report.Add("- Reduced-risk profiles present: $hasReducedRisk") | Out-Null
$report.Add("- Baseline present: $hasBaseline") | Out-Null
$report.Add("- Giveback variants present: $hasGiveback") | Out-Null
$report.Add("- Breakeven variants present: $hasBreakEven") | Out-Null
$report.Add("- Trailing variants present: $hasTrailing") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Coverage By Family") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Family | Profiles |") | Out-Null
$report.Add("|---|---:|") | Out-Null
foreach($family in $families) {
   $report.Add("| $($family.Name) | $($family.Count) |") | Out-Null
}
$report.Add("") | Out-Null
$report.Add("## Coverage By Risk Band") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Risk Band | Profiles |") | Out-Null
$report.Add("|---|---:|") | Out-Null
foreach($band in $riskBands) {
   $report.Add("| $($band.Name) | $($band.Count) |") | Out-Null
}
$report.Add("") | Out-Null
$report.Add("## Candidate Details") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Priority | Profile | Phase2 | Family | Risk | SL | TP | RR | Trail | BE | Giveback | Note |") | Out-Null
$report.Add("|---:|---|---:|---|---:|---:|---:|---:|---:|---|---|---|") | Out-Null
foreach($row in ($rows | Sort-Object Priority)) {
   $report.Add("| $($row.Priority) | ``$($row.Profile)`` | $($row.Phase2Seed) | $($row.Family) | $($row.RiskPercent) | $($row.StopATR) | $($row.TakeProfitATR) | $($row.MinRR) | $($row.TrailATR) | $($row.BreakEven) | $($row.GivebackGuard) | $($row.RiskNote) |") | Out-Null
}
$report.Add("") | Out-Null
$report.Add("## Interpretation") | Out-Null
$report.Add("") | Out-Null
$report.Add("The current pack is intentionally centered around the validated no-date BOS/sweep baseline. It explores upside through TP/SL, trailing, RR, risk, giveback, and breakeven changes. Higher risk profiles remain phase-1 pruning candidates and should not become defaults unless they later pass complete real-tick phase-2 evidence plus promotion packets.") | Out-Null

Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8

$rows | Sort-Object Priority
