param(
   [string]$BaseSetPath = "outputs\CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set",
   [string]$OutDir = "outputs\lowatr_exit_sweep_package",
   [string]$OutQueueManifest = "outputs\LOWATR_EXIT_SWEEP_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\LOWATR_EXIT_SWEEP_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\LOWATR_EXIT_SWEEP_PACKAGE.md",
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
   $fullParent = Split-Path -Parent $resolved
   if($fullParent -and !(Test-Path -LiteralPath $fullParent)) {
      New-Item -ItemType Directory -Path $fullParent -Force | Out-Null
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
   foreach($key in $Values.Keys) { $map[$key] = [string]$Values[$key] }
   return $map
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

function Apply-Overrides {
   param($Inputs, [hashtable]$Overrides)
   foreach($entry in $Overrides.GetEnumerator()) {
      Set-InputLine -Inputs $Inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
}

$baseSet = Resolve-RepoPath $BaseSetPath
if(!(Test-Path -LiteralPath $baseSet)) { throw "Base LowATR profile missing: $baseSet" }

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash

$packageDir = Resolve-RepoPath $OutDir
Clear-OutputDirSafe $packageDir
$configDir = Join-Path $packageDir "configs"
$profileDir = Join-Path $packageDir "profiles"
$reportDir = Join-Path $packageDir "reports_here"
$sourceDir = Join-Path $packageDir "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$variants = @(
   [pscustomobject]@{
      Candidate = "lowatr_exit_be08"
      Purpose = "Protect winners earlier with break-even at 0.80R."
      Overrides = New-OrderedMap @{
         InpUseBreakEven = "true"
         InpBreakEvenTriggerR = "0.80"
         InpBreakEvenBufferPoints = "30"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_be06"
      Purpose = "More aggressive break-even at 0.60R with smaller buffer."
      Overrides = New-OrderedMap @{
         InpUseBreakEven = "true"
         InpBreakEvenTriggerR = "0.60"
         InpBreakEvenBufferPoints = "20"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_trail12"
      Purpose = "Tighten ATR trailing from the default/profile behavior."
      Overrides = New-OrderedMap @{
         InpUseATRTrailing = "true"
         InpTrailATRMultiplier = "1.20"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_trail10"
      Purpose = "Very tight ATR trailing to cut high-drawdown paths."
      Overrides = New-OrderedMap @{
         InpUseATRTrailing = "true"
         InpTrailATRMultiplier = "1.00"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_mfe_tight"
      Purpose = "Tighter MFE giveback and profit lock after trades move in favor."
      Overrides = New-OrderedMap @{
         InpUseMFEGivebackExit = "true"
         InpMFEGivebackStartR = "1.00"
         InpMFEGivebackMaxGivebackR = "0.55"
         InpMFEGivebackMinCloseR = "0.25"
         InpUseMFEProfitLockStop = "true"
         InpMFEProfitLockStartR = "1.20"
         InpMFEProfitLockGivebackR = "0.55"
         InpMFEProfitLockMinR = "0.30"
         InpUseMFEProfitLockMonthFilter = "false"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_mfe_early"
      Purpose = "Exit early when a trade gives back after reaching moderate MFE."
      Overrides = New-OrderedMap @{
         InpUseEarlyMFEReversalExit = "true"
         InpEarlyMFEReversalStartR = "0.60"
         InpEarlyMFEReversalExitR = "-0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_combo_guard"
      Purpose = "Combine earlier break-even, tighter trailing, and tighter MFE lock."
      Overrides = New-OrderedMap @{
         InpUseBreakEven = "true"
         InpBreakEvenTriggerR = "0.80"
         InpBreakEvenBufferPoints = "25"
         InpUseATRTrailing = "true"
         InpTrailATRMultiplier = "1.20"
         InpUseMFEGivebackExit = "true"
         InpMFEGivebackStartR = "1.10"
         InpMFEGivebackMaxGivebackR = "0.60"
         InpUseMFEProfitLockStop = "true"
         InpMFEProfitLockStartR = "1.25"
         InpMFEProfitLockGivebackR = "0.60"
         InpUseMFEProfitLockMonthFilter = "false"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_loss_scale"
      Purpose = "Throttle risk after realized daily/weekly/monthly losses without hard blocking all trades."
      Overrides = New-OrderedMap @{
         InpUseDailyLossRiskScaling = "true"
         InpUseWeeklyLossRiskScaling = "true"
         InpUseMonthlyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpMinMonthlyLossRiskMultiplier = "0.35"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_guard"
      Purpose = "Use account profit giveback protection to keep large winning paths from handing too much back."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_raw_cap6"
      Purpose = "Raw locked LowATR with a hard 6% equity drawdown stop."
      Overrides = New-OrderedMap @{
         InpMaxEquityDrawdownPercent = "6.00"
         InpClosePositionsOnRiskLimit = "true"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_mfe_early_cap6"
      Purpose = "Early MFE reversal exit plus a hard 6% equity drawdown stop."
      Overrides = New-OrderedMap @{
         InpUseEarlyMFEReversalExit = "true"
         InpEarlyMFEReversalStartR = "0.60"
         InpEarlyMFEReversalExitR = "-0.05"
         InpMaxEquityDrawdownPercent = "6.00"
         InpClosePositionsOnRiskLimit = "true"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_loss_scale_cap6"
      Purpose = "Loss-scaling plus a hard 6% equity drawdown stop."
      Overrides = New-OrderedMap @{
         InpUseDailyLossRiskScaling = "true"
         InpUseWeeklyLossRiskScaling = "true"
         InpUseMonthlyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpMinMonthlyLossRiskMultiplier = "0.35"
         InpMaxEquityDrawdownPercent = "6.00"
         InpClosePositionsOnRiskLimit = "true"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_guard_cap6"
      Purpose = "Peak-profit guard plus a hard 6% equity drawdown stop."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
         InpMaxEquityDrawdownPercent = "6.00"
         InpClosePositionsOnRiskLimit = "true"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_guard_cap8"
      Purpose = "Peak-profit guard plus a hard 8% equity drawdown stop for a slightly looser research comparison."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
         InpMaxEquityDrawdownPercent = "8.00"
         InpClosePositionsOnRiskLimit = "true"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_r25"
      Purpose = "Peak-profit guard at 0.25% risk to test whether drawdown scales down without a hard stop."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.25"
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_r20"
      Purpose = "Peak-profit guard at 0.20% risk for the under-6% drawdown boundary."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.20"
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_r22"
      Purpose = "Peak-profit guard at 0.22% risk for the under-6% drawdown boundary."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.22"
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_r24"
      Purpose = "Peak-profit guard at 0.24% risk for the under-6% drawdown boundary."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.24"
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_r30"
      Purpose = "Peak-profit guard at 0.30% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.30"
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_r35"
      Purpose = "Peak-profit guard at 0.35% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.35"
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_r40"
      Purpose = "Peak-profit guard at 0.40% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.40"
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_peak_r50"
      Purpose = "Peak-profit guard at 0.50% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.50"
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "2.00"
         InpEquityProfitPeakTrailGivebackPercent = "10.0"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_mfe_early_r25"
      Purpose = "Early MFE reversal exit at 0.25% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.25"
         InpUseEarlyMFEReversalExit = "true"
         InpEarlyMFEReversalStartR = "0.60"
         InpEarlyMFEReversalExitR = "-0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_mfe_early_r30"
      Purpose = "Early MFE reversal exit at 0.30% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.30"
         InpUseEarlyMFEReversalExit = "true"
         InpEarlyMFEReversalStartR = "0.60"
         InpEarlyMFEReversalExitR = "-0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_mfe_early_r35"
      Purpose = "Early MFE reversal exit at 0.35% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.35"
         InpUseEarlyMFEReversalExit = "true"
         InpEarlyMFEReversalStartR = "0.60"
         InpEarlyMFEReversalExitR = "-0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_mfe_early_r40"
      Purpose = "Early MFE reversal exit at 0.40% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.40"
         InpUseEarlyMFEReversalExit = "true"
         InpEarlyMFEReversalStartR = "0.60"
         InpEarlyMFEReversalExitR = "-0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_mfe_early_r50"
      Purpose = "Early MFE reversal exit at 0.50% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.50"
         InpUseEarlyMFEReversalExit = "true"
         InpEarlyMFEReversalStartR = "0.60"
         InpEarlyMFEReversalExitR = "-0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_loss_scale_r25"
      Purpose = "Loss-scaling at 0.25% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.25"
         InpUseDailyLossRiskScaling = "true"
         InpUseWeeklyLossRiskScaling = "true"
         InpUseMonthlyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpMinMonthlyLossRiskMultiplier = "0.35"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_loss_scale_r30"
      Purpose = "Loss-scaling at 0.30% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.30"
         InpUseDailyLossRiskScaling = "true"
         InpUseWeeklyLossRiskScaling = "true"
         InpUseMonthlyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpMinMonthlyLossRiskMultiplier = "0.35"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_loss_scale_r35"
      Purpose = "Loss-scaling at 0.35% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.35"
         InpUseDailyLossRiskScaling = "true"
         InpUseWeeklyLossRiskScaling = "true"
         InpUseMonthlyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpMinMonthlyLossRiskMultiplier = "0.35"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_loss_scale_r40"
      Purpose = "Loss-scaling at 0.40% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.40"
         InpUseDailyLossRiskScaling = "true"
         InpUseWeeklyLossRiskScaling = "true"
         InpUseMonthlyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpMinMonthlyLossRiskMultiplier = "0.35"
      }
   },
   [pscustomobject]@{
      Candidate = "lowatr_exit_loss_scale_r50"
      Purpose = "Loss-scaling at 0.50% risk."
      Overrides = New-OrderedMap @{
         InpRiskPercent = "0.50"
         InpUseDailyLossRiskScaling = "true"
         InpUseWeeklyLossRiskScaling = "true"
         InpUseMonthlyLossRiskScaling = "true"
         InpDailyLossRiskStartFraction = "0.25"
         InpWeeklyLossRiskStartFraction = "0.25"
         InpMonthlyLossRiskStartFraction = "0.25"
         InpMinDailyLossRiskMultiplier = "0.35"
         InpMinWeeklyLossRiskMultiplier = "0.35"
         InpMinMonthlyLossRiskMultiplier = "0.35"
      }
   }
)

$queue = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0

foreach($variant in $variants) {
   $rank++
   $inputs = Import-SetInputs $baseSet
   $profileId = [string]$variant.Candidate
   $runLabel = "lowatr_exit_sweep_$profileId"
   Add-CommonSafetyOverrides -Inputs $inputs -ProfileId $profileId -RunLabel $runLabel -SourceHash $sourceHash
   Apply-Overrides -Inputs $inputs -Overrides $variant.Overrides

   $profileName = "$profileId.set"
   $profilePath = Join-Path $profileDir $profileName
   $inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] } | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   $configName = "{0:000}_{1}_continuous_m1.ini" -f $rank, $profileId
   $reportName = "lowatr_exit_sweep_{0}_continuous_m1" -f $profileId
   $configPath = Join-Path $configDir $configName
   Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $From -To $To -Inputs $inputs -Model $Model

   $queue.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $profileId
      CandidateRank = 1
      SourceType = "exit_sweep"
      SourceRank = 1
      Phase = "phase0_fast_model1"
      Set = $profileName
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Model = $Model
      Config = "configs\$configName"
      ExpectedReportName = $reportName
      ProfileSnapshot = "profiles\$profileName"
      ProfileSha256 = $profileHash
      StopRule = "Reject if red, too sparse, or drawdown remains above the first-pass risk cap."
   }) | Out-Null

   $runRows.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $profileId
      Phase = "phase0_fast_model1"
      PhaseLabel = "continuous Model1 fast exit sweep"
      Window = "continuous_2024_2026"
      Model = $Model
      PackageConfig = "outputs\lowatr_exit_sweep_package\configs\$configName"
      SourceConfig = "outputs\lowatr_exit_sweep_package\configs\$configName"
      ExpectedReportName = $reportName
      ReportDestination = "outputs\lowatr_exit_sweep_package\reports_here\$reportName"
      ProfileSha256 = $profileHash
      StopRule = "Reject if red, too sparse, or drawdown remains above the first-pass risk cap."
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

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# LowATR Exit Sweep Package")
$md.Add("")
$md.Add("Offline package builder only. This does not launch MT5.")
$md.Add("")
$md.Add("- Source hash: ``$sourceHash``")
$md.Add("- Base profile: ``$BaseSetPath``")
$md.Add("- Window: ``$From`` to ``$To``")
$md.Add("- Model: ``$Model``")
$md.Add("- Configs: ``$($variants.Count)``")
$md.Add("")
$md.Add("## Variants")
$md.Add("")
$md.Add("| Rank | Candidate | Purpose | Overrides |")
$md.Add("| ---: | --- | --- | --- |")
foreach($variant in $variants) {
   $overrideText = (($variant.Overrides.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "<br>")
   $md.Add(("| {0} | ``{1}`` | {2} | {3} |" -f
      (@($variants).IndexOf($variant) + 1),
      $variant.Candidate,
      $variant.Purpose,
      $overrideText))
}
$md.Add("")
$md.Add("## Files")
$md.Add("")
$md.Add("- Queue manifest: ``$OutQueueManifest``")
$md.Add("- Runner manifest: ``$OutPackageManifest``")
$md.Add("- Package dir: ``$OutDir``")
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   Variants = $variants.Count
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   PackageDir = $OutDir
   OutMarkdown = $OutMarkdown
}
