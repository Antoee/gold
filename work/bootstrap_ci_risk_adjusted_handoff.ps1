param(
   [string]$RepoRoot = (Resolve-Path ".").Path,
   [string]$GeneratedDir = "work\generated_profit_search",
   [string]$OutBatch = "outputs\RISK_ADJUSTED_MICRO_BATCH.csv",
   [string]$OutHandoffDir = "outputs\risk_adjusted_micro_handoff",
   [string]$OutHandoffZip = "outputs\risk_adjusted_micro_handoff.zip"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$baseProfile = Join-Path $RepoRoot "work\ci_profit_search_base_profile.set"
$baseProfileRel = $baseProfile.Replace($RepoRoot + "\", "")
$baseParent = Split-Path -Parent $baseProfile
if(!(Test-Path -LiteralPath $baseParent)) { New-Item -ItemType Directory -Force -Path $baseParent | Out-Null }

@(
   "InpMaxEquityDrawdownPercent=0.00"
   "InpRiskPercent=1.60"
   "InpStopATRMultiplier=1.80"
   "InpTakeProfitATRMultiplier=3.50"
   "InpTrailATRMultiplier=1.60"
   "InpMinRiskReward=1.50"
   "InpMaxStopATRMultiplier=3.00"
   "InpUseDateBuyBlock=false"
   "InpUseDateBuyBlock2=false"
   "InpUseDateSellBlock=false"
   "InpUseEMACrossEntry=false"
   "InpUseMomentumCandle=false"
   "InpUseEngulfing=false"
   "InpUseBOS=true"
   "InpUseLiquiditySweep=true"
   "InpMinimumConfirmations=2"
   "InpUseAdaptiveReverse=true"
   "InpUseProfitGivebackGuard=false"
   "InpDailyProfitGivebackPercent=35.0"
   "InpWeeklyProfitGivebackPercent=35.0"
   "InpMonthlyProfitGivebackPercent=35.0"
   "InpUseBreakEven=false"
   "InpBreakEvenTriggerR=1.00"
   "InpBreakEvenBufferPoints=10"
   "InpUseATRTrailing=true"
   "InpMaxDailyLossPercent=1.00"
   "InpMaxWeeklyLossPercent=2.50"
   "InpMaxMonthlyLossPercent=4.00"
   "InpShowDashboard=false"
   "InpDashboardInTester=false"
   "InpLogLevel=0"
   "InpTesterFitnessMode=1"
) | Set-Content -LiteralPath $baseProfile -Encoding ASCII

& (Join-Path $RepoRoot "work\generate_profit_search_configs.ps1") `
   -RepoRoot $RepoRoot `
   -BaseProfile $baseProfileRel `
   -OutputDir $GeneratedDir | Out-Null

$manifestPath = Join-Path $RepoRoot (Join-Path $GeneratedDir "PROFIT_SEARCH_CONFIG_MANIFEST.csv")
if(!(Test-Path -LiteralPath $manifestPath)) {
   throw "Generated manifest missing: $manifestPath"
}

$requiredProfiles = @("baseline_promoted", "risk12_tp38_sl18", "risk14_tp38_sl18", "baseline_dd4", "buyblock2_dd4")
$requiredWindows = @("2024_Q1", "2025_Q2", "2026_Q2", "2026_ytd")
$manifest = @(Import-Csv -LiteralPath $manifestPath)
$batch = New-Object System.Collections.Generic.List[object]
$rank = 1

foreach($profile in $requiredProfiles) {
   foreach($window in $requiredWindows) {
      $row = $manifest |
         Where-Object { $_.Phase -eq "phase1_fast_triage" -and $_.Profile -eq $profile -and $_.Window -eq $window } |
         Select-Object -First 1
      if($null -eq $row) {
         throw "Missing generated CI handoff row for $profile/$window."
      }

      $estimatedSeconds = if($row.Window -eq "2026_ytd") { 35 } elseif($row.Window -eq "2026_Q2") { 12 } else { 16 }
      $batch.Add([pscustomobject]@{
         Rank = $rank
         Priority = $row.Priority
         Phase = $row.Phase
         Model = $row.Model
         Profile = $row.Profile
         Set = $row.Set
         Window = $row.Window
         From = $row.From
         To = $row.To
         Config = $row.Config
         Status = "MISSING_REPORT"
         Role = if($rank -eq 1) { "Baseline" } else { "RiskAdjustedSmoke" }
         Reason = "Clean-checkout CI package smoke coverage."
         ExpectedReportName = "profit_search_phase1_$($row.Profile)_$($row.Set)_$($row.Window)"
         EstimatedSeconds = $estimatedSeconds
         EstimatedMinutes = [Math]::Round($estimatedSeconds / 60.0, 2)
      }) | Out-Null
      $rank++
   }
}

$batchParent = Split-Path -Parent (Join-Path $RepoRoot $OutBatch)
if(!(Test-Path -LiteralPath $batchParent)) { New-Item -ItemType Directory -Force -Path $batchParent | Out-Null }
$batch | Export-Csv -LiteralPath (Join-Path $RepoRoot $OutBatch) -NoTypeInformation

& (Join-Path $RepoRoot "work\build_next_test_handoff.ps1") `
   -BatchCsv $OutBatch `
   -OutDir $OutHandoffDir `
   -ZipPath $OutHandoffZip | Out-Null

"CI_RISK_ADJUSTED_HANDOFF_BOOTSTRAP_PASS"
