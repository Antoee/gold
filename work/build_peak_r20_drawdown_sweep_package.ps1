param(
   [string]$BaseSetPath = "outputs\lowatr_r20_opportunity_sweep_package\profiles\peak_r20_no_peaktrail_r10.set",
   [string]$OutDir = "outputs\peak_r20_drawdown_sweep_package",
   [string]$OutQueueManifest = "outputs\PEAK_R20_DRAWDOWN_SWEEP_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\PEAK_R20_DRAWDOWN_SWEEP_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\PEAK_R20_DRAWDOWN_SWEEP_PACKAGE.md",
   [string]$From = "2024.01.01",
   [string]$To = "2026.07.12",
   [int]$Model = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
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

function Clear-OutputDirSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   $outputs = (Resolve-Path -LiteralPath (Join-Path $repo "outputs")).Path
   $parent = Split-Path -Parent $resolved
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   if(Test-Path -LiteralPath $resolved) {
      $actual = (Resolve-Path -LiteralPath $resolved).Path
      if(!$actual.StartsWith($outputs, [System.StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-outputs directory: $actual"
      }
      Remove-Item -LiteralPath $actual -Recurse -Force
   }
   New-Item -ItemType Directory -Path $resolved -Force | Out-Null
}

function New-OrderedMap {
   param([hashtable]$Values)
   $map = [ordered]@{}
   foreach($key in $Values.Keys) {
      $map[$key] = [string]$Values[$key]
   }
   return $map
}

function Apply-Overrides {
   param($Inputs, [hashtable]$Overrides)
   foreach($entry in $Overrides.GetEnumerator()) {
      Set-InputLine -Inputs $Inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
}

function Add-CommonSafetyOverrides {
   param($Inputs, [string]$ProfileId, [string]$RunLabel, [string]$SourceHash)

   $common = [ordered]@{
      InpEvidenceProfileId = $ProfileId
      InpEvidenceSourceHash = $SourceHash
      InpEvidenceRunLabel = $RunLabel
      InpAllowedSymbol = "XAUUSD"
      InpSignalTimeframe = "15"
      InpShowDashboard = "false"
      InpDashboardInTester = "false"
      InpLogLevel = "0"
      InpTesterFitnessMode = "1"
      InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"
      InpAllowRealAccountTrading = "false"
      InpRealAccountApprovalCode = "DISABLED"
      InpRealAccountApprovalProfileId = "DISABLED"
      InpRealAccountApprovalSourceHash = "DISABLED"
   }

   foreach($entry in $common.GetEnumerator()) {
      Set-InputLine -Inputs $Inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
}

$baseSet = Resolve-RepoPath $BaseSetPath
if(!(Test-Path -LiteralPath $baseSet)) {
   throw "Base R10 frontier profile missing: $baseSet"
}

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$baseProfileHash = (Get-FileHash -LiteralPath $baseSet -Algorithm SHA256).Hash

$packageDir = Resolve-RepoPath $OutDir
Clear-OutputDirSafe $packageDir
$configDir = Join-Path $packageDir "configs"
$profileDir = Join-Path $packageDir "profiles"
$reportDir = Join-Path $packageDir "reports_here"
$sourceDir = Join-Path $packageDir "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force
Copy-Item -LiteralPath $baseSet -Destination (Join-Path $profileDir "peak_r20_no_peaktrail_r10_base.set") -Force

$variants = @(
   [pscustomobject]@{
      Candidate = "r10_base"
      Purpose = "Baseline aggressive R10 frontier for direct same-package comparison."
      Overrides = New-OrderedMap @{}
   },
   [pscustomobject]@{
      Candidate = "r10_minfloor02"
      Purpose = "Test the intended low-risk month multipliers by lowering the hidden minimum reduced risk floor."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.02"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_minfloor05"
      Purpose = "Moderate minimum risk-floor correction, especially for August and risk-reduced states."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_minfloor10"
      Purpose = "Keep global risk near the named R10 setting while allowing month and loss reductions to work."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.10"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_eqgb_q15_12_18"
      Purpose = "Soft equity-peak giveback quality gate after a 15 percent giveback from peak profit."
      Overrides = New-OrderedMap @{
         InpUseEquityPeakGivebackQualityGate = "true"
         InpEquityPeakGivebackStartPercent = "15.0"
         InpEquityPeakGivebackFullPercent = "45.0"
         InpEquityPeakGivebackMinQualityScore = "12"
         InpEquityPeakGivebackMaxQualityScore = "18"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_eqgb_q20_12_18"
      Purpose = "Less sensitive equity-peak giveback quality gate for drawdown control without early choking."
      Overrides = New-OrderedMap @{
         InpUseEquityPeakGivebackQualityGate = "true"
         InpEquityPeakGivebackStartPercent = "20.0"
         InpEquityPeakGivebackFullPercent = "50.0"
         InpEquityPeakGivebackMinQualityScore = "12"
         InpEquityPeakGivebackMaxQualityScore = "18"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_eqgb_q10_10_16"
      Purpose = "Earlier but lighter equity-peak giveback quality gate."
      Overrides = New-OrderedMap @{
         InpUseEquityPeakGivebackQualityGate = "true"
         InpEquityPeakGivebackStartPercent = "10.0"
         InpEquityPeakGivebackFullPercent = "40.0"
         InpEquityPeakGivebackMinQualityScore = "10"
         InpEquityPeakGivebackMaxQualityScore = "16"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_realgb_q15_12_18"
      Purpose = "Realized-profit giveback quality gate so the EA must earn higher quality after giving back closed profit."
      Overrides = New-OrderedMap @{
         InpUseRealizedProfitGivebackQualityGate = "true"
         InpRealizedProfitGivebackStartPercent = "15.0"
         InpRealizedProfitGivebackFullPercent = "45.0"
         InpRealizedProfitGivebackMinQualityScore = "12"
         InpRealizedProfitGivebackMaxQualityScore = "18"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_realgb_q20_12_18"
      Purpose = "Less sensitive realized-profit giveback quality gate."
      Overrides = New-OrderedMap @{
         InpUseRealizedProfitGivebackQualityGate = "true"
         InpRealizedProfitGivebackStartPercent = "20.0"
         InpRealizedProfitGivebackFullPercent = "50.0"
         InpRealizedProfitGivebackMinQualityScore = "12"
         InpRealizedProfitGivebackMaxQualityScore = "18"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_bothgb_q15"
      Purpose = "Combine equity-peak and realized-profit soft gates at the same thresholds."
      Overrides = New-OrderedMap @{
         InpUseEquityPeakGivebackQualityGate = "true"
         InpEquityPeakGivebackStartPercent = "15.0"
         InpEquityPeakGivebackFullPercent = "45.0"
         InpEquityPeakGivebackMinQualityScore = "12"
         InpEquityPeakGivebackMaxQualityScore = "18"
         InpUseRealizedProfitGivebackQualityGate = "true"
         InpRealizedProfitGivebackStartPercent = "15.0"
         InpRealizedProfitGivebackFullPercent = "45.0"
         InpRealizedProfitGivebackMinQualityScore = "12"
         InpRealizedProfitGivebackMaxQualityScore = "18"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_loss_scale_25"
      Purpose = "Enable daily, weekly, and monthly loss scaling with earlier throttling."
      Overrides = New-OrderedMap @{
         InpUseDailyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpUseWeeklyLossRiskScaling = "true"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpUseMonthlyLossRiskScaling = "true"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinMonthlyLossRiskMultiplier = "0.35"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_loss_scale_15"
      Purpose = "More aggressive loss scaling to determine whether drawdown can be cut without stopping trade flow."
      Overrides = New-OrderedMap @{
         InpUseDailyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.15"
         InpMinDailyLossRiskMultiplier = "0.25"
         InpUseWeeklyLossRiskScaling = "true"
         InpWeeklyLossRiskStartFraction = "0.15"
         InpMinWeeklyLossRiskMultiplier = "0.25"
         InpUseMonthlyLossRiskScaling = "true"
         InpMonthlyLossRiskStartFraction = "0.15"
         InpMinMonthlyLossRiskMultiplier = "0.25"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_floor10_loss25"
      Purpose = "Risk-floor correction plus moderate loss scaling."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.10"
         InpUseDailyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpUseWeeklyLossRiskScaling = "true"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpUseMonthlyLossRiskScaling = "true"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinMonthlyLossRiskMultiplier = "0.35"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_floor05_loss25"
      Purpose = "Lower risk floor plus moderate loss scaling, checking whether this becomes too defensive."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.05"
         InpUseDailyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpUseWeeklyLossRiskScaling = "true"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpUseMonthlyLossRiskScaling = "true"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinMonthlyLossRiskMultiplier = "0.35"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_floor10_eqgb"
      Purpose = "Risk-floor correction plus equity-peak soft gate."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.10"
         InpUseEquityPeakGivebackQualityGate = "true"
         InpEquityPeakGivebackStartPercent = "15.0"
         InpEquityPeakGivebackFullPercent = "45.0"
         InpEquityPeakGivebackMinQualityScore = "12"
         InpEquityPeakGivebackMaxQualityScore = "18"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_floor05_eqgb"
      Purpose = "Lower risk floor plus equity-peak soft gate."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.05"
         InpUseEquityPeakGivebackQualityGate = "true"
         InpEquityPeakGivebackStartPercent = "15.0"
         InpEquityPeakGivebackFullPercent = "45.0"
         InpEquityPeakGivebackMinQualityScore = "12"
         InpEquityPeakGivebackMaxQualityScore = "18"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_may260_floor10"
      Purpose = "Trim May risk slightly while fixing the hidden risk floor."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.10"
         InpMayRiskMultiplier = "2.60"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_may240_floor10"
      Purpose = "Trim May risk more noticeably while fixing the hidden risk floor."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.10"
         InpMayRiskMultiplier = "2.40"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_aug25_floor05"
      Purpose = "Use a corrected low risk floor but restore some August participation."
      Overrides = New-OrderedMap @{
         InpMinReducedRiskPercent = "0.05"
         InpAugustRiskMultiplier = "0.25"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_profit_guard40"
      Purpose = "Harder period profit giveback guard as a drawdown-control benchmark."
      Overrides = New-OrderedMap @{
         InpUseProfitGivebackGuard = "true"
         InpDailyProfitGivebackPercent = "40.0"
         InpWeeklyProfitGivebackPercent = "40.0"
         InpMonthlyProfitGivebackPercent = "40.0"
         InpMinProfitToProtectPercent = "0.50"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_eqlock4_50"
      Purpose = "Account-level profit lock benchmark, likely conservative but useful as a safety bound."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitLock = "true"
         InpEquityProfitLockStartPercent = "4.00"
         InpEquityProfitLockPercent = "50.0"
      }
   },
   [pscustomobject]@{
      Candidate = "r10_dailytrail35"
      Purpose = "Daily equity trail guard benchmark for intraday giveback control."
      Overrides = New-OrderedMap @{
         InpUseDailyEquityTrailGuard = "true"
         InpDailyEquityTrailGivebackPercent = "35.0"
         InpDailyEquityTrailMinProfitPercent = "0.50"
      }
   }
)

$queue = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
foreach($variant in $variants) {
   $rank++
   $inputs = Import-SetInputs $baseSet
   $profileId = $variant.Candidate
   $window = "continuous_2024_2026"
   $runLabel = "peak_r20_dd_{0}_{1}_m{2}" -f $variant.Candidate, $window, $Model
   Add-CommonSafetyOverrides -Inputs $inputs -ProfileId $profileId -RunLabel $runLabel -SourceHash $sourceHash
   Apply-Overrides -Inputs $inputs -Overrides $variant.Overrides

   $setName = "{0}.set" -f $variant.Candidate
   $setPath = Join-Path $profileDir $setName
   $setLines = [System.Collections.Generic.List[string]]::new()
   foreach($key in ($inputs.Keys | Sort-Object)) {
      $setLines.Add($inputs[$key]) | Out-Null
   }
   $setLines | Set-Content -LiteralPath $setPath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $setPath -Algorithm SHA256).Hash

   $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $variant.Candidate, $window, $Model
   $reportName = "peak_r20_dd_{0}_{1}_m{2}" -f $variant.Candidate, $window, $Model
   $configPath = Join-Path $configDir $configName
   Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $From -To $To -Inputs $inputs -Model $Model

   $stopRule = "Reject if broad window is red, drawdown remains above the R10 frontier without better profit/recovery, or profit is gained by fragile hard stopping."
   $queue.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $variant.Candidate
      CandidateRank = $rank
      SourceType = "peak_r20_drawdown_sweep"
      SourceRank = $rank
      Phase = "phase0_fast_model1"
      Set = $setName
      Window = $window
      From = $From
      To = $To
      Model = $Model
      Config = "configs\$configName"
      ExpectedReportName = $reportName
      ProfileSnapshot = "profiles\$setName"
      ProfileSha256 = $profileHash
      BaseProfileSha256 = $baseProfileHash
      StopRule = $stopRule
      Purpose = $variant.Purpose
   }) | Out-Null

   $runRows.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $variant.Candidate
      Phase = "phase0_fast_model1"
      PhaseLabel = "Peak R20 R10 drawdown sweep"
      Window = $window
      Model = $Model
      PackageConfig = "outputs\peak_r20_drawdown_sweep_package\configs\$configName"
      SourceConfig = "outputs\peak_r20_drawdown_sweep_package\configs\$configName"
      ExpectedReportName = $reportName
      ReportDestination = "outputs\peak_r20_drawdown_sweep_package\reports_here\$reportName"
      ProfileSha256 = $profileHash
      StopRule = $stopRule
   }) | Out-Null
}

$queuePath = Resolve-RepoPath $OutQueueManifest
$runPath = Resolve-RepoPath $OutPackageManifest
$mdPath = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $queuePath
Ensure-ParentDir $runPath
Ensure-ParentDir $mdPath

$queue | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath $runPath -NoTypeInformation -Encoding ASCII

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Peak R20 R10 Drawdown Sweep Package") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("Offline package builder only. This does not launch MT5.") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- Base profile: ``$BaseSetPath``") | Out-Null
$lines.Add("- Source hash: ``$sourceHash``") | Out-Null
$lines.Add("- Base profile hash: ``$baseProfileHash``") | Out-Null
$lines.Add("- Model: ``$Model``") | Out-Null
$lines.Add("- Variants: ``$($variants.Count)``") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## Hypotheses") | Out-Null
$lines.Add("") | Out-Null
foreach($variant in $variants) {
   $lines.Add("- ``$($variant.Candidate)``: $($variant.Purpose)") | Out-Null
}
$lines.Add("") | Out-Null
$lines.Add("## Files") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- Queue manifest: ``$OutQueueManifest``") | Out-Null
$lines.Add("- Runner manifest: ``$OutPackageManifest``") | Out-Null
$lines.Add("- Package dir: ``$OutDir``") | Out-Null
$lines | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   BaseProfileHash = $baseProfileHash
   Variants = $variants.Count
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   PackageDir = $OutDir
}
