param(
   [string]$ProfilesDir = "work\generated_profit_search\profiles",
   [string]$ConfigManifestPath = "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv",
   [string]$OutCsv = "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.csv",
   [string]$OutReport = "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-ProfileSet {
   param([string]$Path)
   $values = @{}
   foreach($line in (Get-Content -LiteralPath $Path)) {
      $trimmed = $line.Trim()
      if([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith(";") -or $trimmed.StartsWith("#")) { continue }
      $parts = $trimmed -split "=", 2
      if($parts.Count -ne 2) { continue }
      $values[$parts[0].Trim()] = (($parts[1] -split "\|\|", 2)[0]).Trim()
   }
   return $values
}

function Get-Value {
   param([hashtable]$Values, [string]$Name, [object]$Default = "")
   if($Values.ContainsKey($Name)) { return $Values[$Name] }
   return $Default
}

function To-Double {
   param([object]$Value, [double]$Default = 0.0)
   $parsed = 0.0
   if([double]::TryParse([string]$Value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) { return $parsed }
   return $Default
}

function To-Bool {
   param([object]$Value)
   return ([string]$Value).Trim().ToLowerInvariant() -eq "true"
}

if(!(Test-Path -LiteralPath $ProfilesDir)) { throw "Profiles directory not found: $ProfilesDir" }

$manifestRows = @()
if(Test-Path -LiteralPath $ConfigManifestPath) { $manifestRows = @(Import-Csv -LiteralPath $ConfigManifestPath) }

$phaseCounts = @{}
foreach($row in $manifestRows) {
   $profile = [string]$row.Profile
   if(!$phaseCounts.ContainsKey($profile)) { $phaseCounts[$profile] = [ordered]@{ Phase1 = 0; Phase2 = 0; Stress = 0; Full = 0 } }
   if($row.Phase -eq "phase1_fast_triage") { $phaseCounts[$profile].Phase1++ }
   if($row.Phase -eq "phase2_real_tick_validation") { $phaseCounts[$profile].Phase2++ }
   if($row.Set -eq "stress") { $phaseCounts[$profile].Stress++ }
   if($row.Window -eq "full") { $phaseCounts[$profile].Full++ }
}

$rows = New-Object System.Collections.Generic.List[object]
foreach($file in (Get-ChildItem -LiteralPath $ProfilesDir -Filter "*.set" -File | Sort-Object Name)) {
   $values = Read-ProfileSet $file.FullName
   $profile = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
   $riskPercent = To-Double (Get-Value $values "InpRiskPercent")
   $stopAtr = To-Double (Get-Value $values "InpStopATRMultiplier")
   $tpAtr = To-Double (Get-Value $values "InpTakeProfitATRMultiplier")
   $minRr = To-Double (Get-Value $values "InpMinRiskReward")
   $dailyLoss = To-Double (Get-Value $values "InpMaxDailyLossPercent")
   $weeklyLoss = To-Double (Get-Value $values "InpMaxWeeklyLossPercent")
   $monthlyLoss = To-Double (Get-Value $values "InpMaxMonthlyLossPercent")
   $equityDd = To-Double (Get-Value $values "InpMaxEquityDrawdownPercent")
   $testerDd = To-Double (Get-Value $values "InpTesterMaxDrawdownPercent")
   $testerPf = To-Double (Get-Value $values "InpTesterMinProfitFactor")
   $confirmations = [int](To-Double (Get-Value $values "InpMinimumConfirmations"))
   $dateBlock = (To-Bool (Get-Value $values "InpUseDateBuyBlock")) -or (To-Bool (Get-Value $values "InpUseDateBuyBlock2")) -or (To-Bool (Get-Value $values "InpUseDateSellBlock"))
   $usesBos = To-Bool (Get-Value $values "InpUseBOS")
   $usesSweep = To-Bool (Get-Value $values "InpUseLiquiditySweep")
   $usesAtrTrail = To-Bool (Get-Value $values "InpUseATRTrailing")
   $usesGiveback = To-Bool (Get-Value $values "InpUseProfitGivebackGuard")
   $usesAdaptiveReverse = To-Bool (Get-Value $values "InpUseAdaptiveReverse")

   $hardRiskFlags = New-Object System.Collections.Generic.List[string]
   $promotionRiskFlags = New-Object System.Collections.Generic.List[string]
   if($dailyLoss -le 0 -or $weeklyLoss -le 0 -or $monthlyLoss -le 0) { $hardRiskFlags.Add("loss_limit_missing") | Out-Null }
   if($equityDd -le 0) { $promotionRiskFlags.Add("equity_drawdown_guard_disabled") | Out-Null }
   if($testerDd -gt 25.0) { $promotionRiskFlags.Add("tester_drawdown_gate_loose") | Out-Null }
   if($testerPf -lt 1.05) { $promotionRiskFlags.Add("tester_pf_gate_loose") | Out-Null }

   $overfitFlags = New-Object System.Collections.Generic.List[string]
   if($dateBlock) { $overfitFlags.Add("date_block_enabled") | Out-Null }
   if($usesAdaptiveReverse) { $overfitFlags.Add("adaptive_reverse_requires_walk_forward") | Out-Null }
   if($tpAtr -ge 4.20) { $overfitFlags.Add("far_tp_extension") | Out-Null }
   if($stopAtr -lt 1.70) { $overfitFlags.Add("tighter_stop_variant") | Out-Null }

   $structureFlags = New-Object System.Collections.Generic.List[string]
   if(!$usesBos) { $structureFlags.Add("bos_disabled") | Out-Null }
   if(!$usesSweep) { $structureFlags.Add("sweep_disabled") | Out-Null }
   if($confirmations -lt 2) { $structureFlags.Add("confirmation_count_low") | Out-Null }
   if(!$usesAtrTrail) { $structureFlags.Add("atr_trailing_disabled") | Out-Null }

   $score = 100 - ($hardRiskFlags.Count * 20) - ($promotionRiskFlags.Count * 8) - ($overfitFlags.Count * 10) - ($structureFlags.Count * 12)
   if($usesGiveback) { $score += 5 }
   if($riskPercent -le 1.40) { $score += 5 }
   if($score -lt 0) { $score = 0 }
   if($score -gt 100) { $score = 100 }

   $allRiskFlags = New-Object System.Collections.Generic.List[string]
   foreach($flag in $hardRiskFlags) { $allRiskFlags.Add($flag) | Out-Null }
   foreach($flag in $promotionRiskFlags) { $allRiskFlags.Add($flag) | Out-Null }
   if($riskPercent -gt 1.60) { $allRiskFlags.Add("risk_percent_above_promoted") | Out-Null }

   $status = "PASS"
   if($dateBlock -or $structureFlags.Count -gt 0 -or $hardRiskFlags.Count -gt 0 -or $riskPercent -gt 2.0) { $status = "REJECT_PROMOTION" }
   elseif($promotionRiskFlags.Count -gt 0 -or $overfitFlags.Count -gt 0 -or $riskPercent -gt 1.60) { $status = "REVIEW_REQUIRED" }

   $counts = if($phaseCounts.ContainsKey($profile)) { $phaseCounts[$profile] } else { [ordered]@{ Phase1 = 0; Phase2 = 0; Stress = 0; Full = 0 } }
   $nextAction = if($status -eq "PASS") { "Eligible for phase-1 triage; promotion still requires full phase-2 gate." } elseif($status -eq "REVIEW_REQUIRED") { "Eligible for testing, but require stricter promotion review before replacing the default." } else { "Do not promote; keep only as research unless the rule is generalized and revalidated." }

   $rows.Add([pscustomobject]@{
      Profile = $profile; GuardrailStatus = $status; GuardrailScore = $score; RiskPercent = $riskPercent; StopATR = $stopAtr; TakeProfitATR = $tpAtr; MinRR = $minRr; DailyLossPct = $dailyLoss; WeeklyLossPct = $weeklyLoss; MonthlyLossPct = $monthlyLoss; EquityDrawdownPct = $equityDd; UsesGivebackGuard = $usesGiveback; DateBlocksEnabled = $dateBlock; RiskFlags = ($allRiskFlags -join ";"); OverfitFlags = ($overfitFlags -join ";"); StructureFlags = ($structureFlags -join ";"); Phase1Configs = $counts.Phase1; Phase2Configs = $counts.Phase2; StressConfigs = $counts.Stress; FullConfigs = $counts.Full; NextAction = $nextAction
   }) | Out-Null
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$statusCounts = $rows | Group-Object GuardrailStatus | Sort-Object Name
$topTestEligible = @($rows | Where-Object GuardrailStatus -ne "REJECT_PROMOTION" | Sort-Object @{ Expression = "GuardrailScore"; Descending = $true }, RiskPercent, TakeProfitATR | Select-Object -First 12)
$review = @($rows | Where-Object GuardrailStatus -eq "REVIEW_REQUIRED" | Sort-Object @{ Expression = "GuardrailScore"; Descending = $true }, RiskPercent | Select-Object -First 12)

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Optimization Guardrail Audit") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline audit only. No MT5 process was launched.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Profiles audited: $($rows.Count)") | Out-Null
$md.Add("- Config manifest rows: $($manifestRows.Count)") | Out-Null
$md.Add("- Guardrail rule: promotion candidates should avoid date blocks, keep risk near or below the promoted 1.60%, preserve BOS+sweep confirmations, and pass phase-2 real-tick evidence before replacement.") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Status Counts") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Status | Profiles |") | Out-Null
$md.Add("|---|---:|") | Out-Null
foreach($count in $statusCounts) { $md.Add("| $($count.Name) | $($count.Count) |") | Out-Null }
$md.Add("") | Out-Null
$md.Add("## Top Test-Eligible Candidates") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Profile | Status | Score | Risk % | SL ATR | TP ATR | Giveback | Phase1 | Phase2 | Next Action |") | Out-Null
$md.Add("|---|---|---:|---:|---:|---:|---|---:|---:|---|") | Out-Null
foreach($row in $topTestEligible) { $md.Add("| ``$($row.Profile)`` | $($row.GuardrailStatus) | $($row.GuardrailScore) | $($row.RiskPercent) | $($row.StopATR) | $($row.TakeProfitATR) | $($row.UsesGivebackGuard) | $($row.Phase1Configs) | $($row.Phase2Configs) | $($row.NextAction) |") | Out-Null }
$md.Add("") | Out-Null
$md.Add("## Review Queue") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Profile | Score | Risk Flags | Overfit Flags | Structure Flags | Next Action |") | Out-Null
$md.Add("|---|---:|---|---|---|---|") | Out-Null
foreach($row in $review) { $md.Add("| ``$($row.Profile)`` | $($row.GuardrailScore) | $($row.RiskFlags) | $($row.OverfitFlags) | $($row.StructureFlags) | $($row.NextAction) |") | Out-Null }
$md.Add("") | Out-Null
$md.Add("## Bottom Line") | Out-Null
$md.Add("") | Out-Null
$md.Add("Use this audit to prevent high-profit-looking variants from bypassing risk discipline. PASS means eligible for testing, not eligible for promotion. Promotion still requires the full no-losing-window gate.") | Out-Null
Set-Content -LiteralPath $OutReport -Value $md -Encoding UTF8

[pscustomobject]@{ Profiles = $rows.Count; ManifestRows = $manifestRows.Count; OutCsv = $OutCsv; OutReport = $OutReport }
