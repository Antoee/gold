param(
   [string]$BaseSetPath = "outputs\lowatr_exit_sweep_package\profiles\lowatr_exit_peak_r20.set",
   [string]$OutDir = "outputs\lowatr_r20_opportunity_sweep_package",
   [string]$OutQueueManifest = "outputs\LOWATR_R20_OPPORTUNITY_SWEEP_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\LOWATR_R20_OPPORTUNITY_SWEEP_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\LOWATR_R20_OPPORTUNITY_SWEEP_PACKAGE.md",
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
   throw "Base R20 profile missing: $baseSet"
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
Copy-Item -LiteralPath $baseSet -Destination (Join-Path $profileDir "lowatr_exit_peak_r20_base.set") -Force

$variants = @(
   [pscustomobject]@{
      Candidate = "peak_r20_base"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Baseline R20 profile for direct comparison in the same package."
      Overrides = New-OrderedMap @{}
   },
   [pscustomobject]@{
      Candidate = "peak_r20_diag_2025"
      Window = "diagnostic_2025"
      From = "2025.01.01"
      To = "2025.12.31"
      Purpose = "Base R20 with block-reason diagnostics enabled for the weak 2025 split."
      Overrides = New-OrderedMap @{
         InpUseBlockReasonDiagnostics = "true"
         InpBlockReasonDiagnosticsFile = "LOWATR_R20_BLOCK_REASONS_2025.csv"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_may_full"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Let May trade past day 10 while keeping the rest of the R20 safety stack."
      Overrides = New-OrderedMap @{
         InpMayMaxDay = "31"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_may_full_spread22"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Relax May day window and spread cap modestly to see if quality May trades were excluded."
      Overrides = New-OrderedMap @{
         InpMayMaxDay = "31"
         InpMayMaxSpreadPoints = "22.0"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_aug_risk60"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Slightly less throttled August risk, testing whether the safe branch is under-sizing good August setups."
      Overrides = New-OrderedMap @{
         InpAugustRiskMultiplier = "0.60"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_may31_aug60"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Combined May window relaxation plus modest August risk restoration."
      Overrides = New-OrderedMap @{
         InpMayMaxDay = "31"
         InpMayMaxSpreadPoints = "22.0"
         InpAugustRiskMultiplier = "0.60"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_islp_may_aug"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Allow the existing ISLP lane to evaluate May and August signals at low risk."
      Overrides = New-OrderedMap @{
         InpISLPTradeMay = "true"
         InpISLPTradeAugust = "true"
         InpInSessionLiquidityPullbackRiskMultiplier = "0.25"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_islp_broad_lowrisk"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Broader ISLP month coverage with low lane risk and existing month-filter bypass."
      Overrides = New-OrderedMap @{
         InpISLPTradeApril = "true"
         InpISLPTradeMay = "true"
         InpISLPTradeJune = "true"
         InpISLPTradeJuly = "true"
         InpISLPTradeAugust = "true"
         InpISLPTradeSeptember = "true"
         InpISLPTradeOctober = "true"
         InpISLPTradeNovember = "true"
         InpInSessionLiquidityPullbackRiskMultiplier = "0.20"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_octnov_main_lowrisk"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Test October/November as primary months but with explicit low month risk."
      Overrides = New-OrderedMap @{
         InpTradeOctober = "true"
         InpTradeNovember = "true"
         InpOctoberRiskMultiplier = "0.20"
         InpNovemberRiskMultiplier = "0.20"
         InpOctoberMaxSpreadPoints = "24.0"
         InpNovemberMaxSpreadPoints = "24.0"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_fmlr_strict"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Enable strict flat-month liquidity reclaim as a small-risk standalone opportunity lane."
      Overrides = New-OrderedMap @{
         InpUseFlatMonthLiquidityReclaimLane = "true"
         InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter = "true"
         InpFlatMonthLiquidityReclaimRiskMultiplier = "0.10"
         InpFlatMonthLiquidityReclaimMinScore = "8"
         InpFlatMonthLiquidityReclaimBypassMinQualityScore = "9"
         InpFlatMonthLiquidityReclaimRequireOrderFlow = "true"
         InpFlatMonthLiquidityReclaimRequireLiquidSession = "true"
         InpFlatMonthLiquidityReclaimRequireForwardClearance = "true"
         InpFlatMonthLiquidityReclaimUseLiquidityTarget = "true"
         InpFlatMonthLiquidityReclaimUseStructureTrail = "true"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_fmlr_sweep_bos"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Require sweep-displacement/BOS style reclaim before a tiny-risk liquidity-reclaim entry."
      Overrides = New-OrderedMap @{
         InpUseFlatMonthLiquidityReclaimLane = "true"
         InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter = "true"
         InpFlatMonthLiquidityReclaimRiskMultiplier = "0.10"
         InpFlatMonthLiquidityReclaimMinScore = "7"
         InpFlatMonthLiquidityReclaimBypassMinQualityScore = "8"
         InpFlatMonthLiquidityReclaimRequireOrderFlow = "true"
         InpFlatMonthLiquidityReclaimUseSweepDisplacementBOS = "true"
         InpFlatMonthLiquidityReclaimRequireSweepDisplacementBOS = "true"
         InpFlatMonthLiquidityReclaimUseLiquidityTarget = "true"
         InpFlatMonthLiquidityReclaimUseStructureTrail = "true"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_fmlr_fvg_ob"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Tiny-risk liquidity reclaim using FVG/order-block/CHoCH retest components as extra price-action evidence."
      Overrides = New-OrderedMap @{
         InpUseFlatMonthLiquidityReclaimLane = "true"
         InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter = "true"
         InpFlatMonthLiquidityReclaimRiskMultiplier = "0.10"
         InpFlatMonthLiquidityReclaimMinScore = "8"
         InpFlatMonthLiquidityReclaimBypassMinQualityScore = "8"
         InpFlatMonthLiquidityReclaimUseFvgRetest = "true"
         InpFlatMonthLiquidityReclaimUseOrderBlockRetest = "true"
         InpFlatMonthLiquidityReclaimUseChochRetest = "true"
         InpFlatMonthLiquidityReclaimRequireForwardClearance = "true"
         InpFlatMonthLiquidityReclaimUseLiquidityTarget = "true"
         InpFlatMonthLiquidityReclaimUseStructureTrail = "true"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_soft_weak_gate"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Slightly soften weak-regime gate while leaving the gate enabled."
      Overrides = New-OrderedMap @{
         InpWeakRegimeQualityBypassScore = "12"
         InpWeakRegimeMaxADX = "18.0"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_day_window_lowrisk"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Disable the month-day window, offset by lower base risk, to test whether timing gates are the bottleneck."
      Overrides = New-OrderedMap @{
         InpUseMonthDayWindowFilter = "false"
         InpRiskPercent = "0.12"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Disable equity profit peak trail to test whether the safe branch can keep trading after early gains."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail_r15"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "No equity peak trail with lower base risk to keep later-year participation under control."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
         InpRiskPercent = "0.15"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail_r10"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "No equity peak trail with half-sized base risk and existing month multipliers."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
         InpRiskPercent = "0.10"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail_r10_norm"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "No equity peak trail with normalized month risk to reduce May multiplier concentration."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
         InpRiskPercent = "0.10"
         InpUseMonthRiskMultipliers = "false"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail_loss_scale"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Replace the hard equity peak blocker with loss-based risk scaling after drawdown starts."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
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
      Candidate = "peak_r20_no_peaktrail_cap6"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "No equity peak trail with a hard 6% equity drawdown safety stop."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
         InpMaxEquityDrawdownPercent = "6.00"
         InpClosePositionsOnRiskLimit = "true"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail_r08_floor05"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "No equity peak trail with lower risk and an explicit 0.05% reduced-risk floor."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
         InpRiskPercent = "0.08"
         InpMinReducedRiskPercent = "0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail_r10_floor05"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "No equity peak trail at 0.10% base risk with a lower reduced-risk floor."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
         InpRiskPercent = "0.10"
         InpMinReducedRiskPercent = "0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail_r12_floor05"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "No equity peak trail at 0.12% base risk with a lower reduced-risk floor."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
         InpRiskPercent = "0.12"
         InpMinReducedRiskPercent = "0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail_r14_floor05"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "No equity peak trail at 0.14% base risk with a lower reduced-risk floor."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
         InpRiskPercent = "0.14"
         InpMinReducedRiskPercent = "0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_no_peaktrail_r16_floor05"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "No equity peak trail at 0.16% base risk with a lower reduced-risk floor."
      Overrides = New-OrderedMap @{
         InpUseEquityProfitPeakTrail = "false"
         InpRiskPercent = "0.16"
         InpMinReducedRiskPercent = "0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_all_nodec_r05_norm"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "Trade every month except December at very low normalized risk after diagnostics showed many primary signals blocked by month filter."
      Overrides = New-OrderedMap @{
         InpTradeJanuary = "true"
         InpTradeFebruary = "true"
         InpTradeMarch = "true"
         InpTradeApril = "true"
         InpTradeMay = "true"
         InpTradeJune = "true"
         InpTradeJuly = "true"
         InpTradeAugust = "true"
         InpTradeSeptember = "true"
         InpTradeOctober = "true"
         InpTradeNovember = "true"
         InpTradeDecember = "false"
         InpUseMonthDayWindowFilter = "false"
         InpUseMonthRiskMultipliers = "false"
         InpRiskPercent = "0.05"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_all_nodec_r08_norm"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "All non-December months at normalized 0.08% risk."
      Overrides = New-OrderedMap @{
         InpTradeJanuary = "true"
         InpTradeFebruary = "true"
         InpTradeMarch = "true"
         InpTradeApril = "true"
         InpTradeMay = "true"
         InpTradeJune = "true"
         InpTradeJuly = "true"
         InpTradeAugust = "true"
         InpTradeSeptember = "true"
         InpTradeOctober = "true"
         InpTradeNovember = "true"
         InpTradeDecember = "false"
         InpUseMonthDayWindowFilter = "false"
         InpUseMonthRiskMultipliers = "false"
         InpRiskPercent = "0.08"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_all_nodec_r10_norm"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "All non-December months at normalized 0.10% risk."
      Overrides = New-OrderedMap @{
         InpTradeJanuary = "true"
         InpTradeFebruary = "true"
         InpTradeMarch = "true"
         InpTradeApril = "true"
         InpTradeMay = "true"
         InpTradeJune = "true"
         InpTradeJuly = "true"
         InpTradeAugust = "true"
         InpTradeSeptember = "true"
         InpTradeOctober = "true"
         InpTradeNovember = "true"
         InpTradeDecember = "false"
         InpUseMonthDayWindowFilter = "false"
         InpUseMonthRiskMultipliers = "false"
         InpRiskPercent = "0.10"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_all_nodec_r12_norm"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "All non-December months at normalized 0.12% risk."
      Overrides = New-OrderedMap @{
         InpTradeJanuary = "true"
         InpTradeFebruary = "true"
         InpTradeMarch = "true"
         InpTradeApril = "true"
         InpTradeMay = "true"
         InpTradeJune = "true"
         InpTradeJuly = "true"
         InpTradeAugust = "true"
         InpTradeSeptember = "true"
         InpTradeOctober = "true"
         InpTradeNovember = "true"
         InpTradeDecember = "false"
         InpUseMonthDayWindowFilter = "false"
         InpUseMonthRiskMultipliers = "false"
         InpRiskPercent = "0.12"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_all_nodec_r08_conf2"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "All non-December months at 0.08% risk, requiring two confirmations instead of one."
      Overrides = New-OrderedMap @{
         InpTradeJanuary = "true"
         InpTradeFebruary = "true"
         InpTradeMarch = "true"
         InpTradeApril = "true"
         InpTradeMay = "true"
         InpTradeJune = "true"
         InpTradeJuly = "true"
         InpTradeAugust = "true"
         InpTradeSeptember = "true"
         InpTradeOctober = "true"
         InpTradeNovember = "true"
         InpTradeDecember = "false"
         InpUseMonthDayWindowFilter = "false"
         InpUseMonthRiskMultipliers = "false"
         InpRiskPercent = "0.08"
         InpMinimumConfirmations = "2"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_all_nodec_r10_conf2"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "All non-December months at 0.10% risk, requiring two confirmations instead of one."
      Overrides = New-OrderedMap @{
         InpTradeJanuary = "true"
         InpTradeFebruary = "true"
         InpTradeMarch = "true"
         InpTradeApril = "true"
         InpTradeMay = "true"
         InpTradeJune = "true"
         InpTradeJuly = "true"
         InpTradeAugust = "true"
         InpTradeSeptember = "true"
         InpTradeOctober = "true"
         InpTradeNovember = "true"
         InpTradeDecember = "false"
         InpUseMonthDayWindowFilter = "false"
         InpUseMonthRiskMultipliers = "false"
         InpRiskPercent = "0.10"
         InpMinimumConfirmations = "2"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_all_nodec_r08_weighted"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "All non-December months with weighted entry score gate at low risk."
      Overrides = New-OrderedMap @{
         InpTradeJanuary = "true"
         InpTradeFebruary = "true"
         InpTradeMarch = "true"
         InpTradeApril = "true"
         InpTradeMay = "true"
         InpTradeJune = "true"
         InpTradeJuly = "true"
         InpTradeAugust = "true"
         InpTradeSeptember = "true"
         InpTradeOctober = "true"
         InpTradeNovember = "true"
         InpTradeDecember = "false"
         InpUseMonthDayWindowFilter = "false"
         InpUseMonthRiskMultipliers = "false"
         InpRiskPercent = "0.08"
         InpUseWeightedEntryScore = "true"
         InpMinimumEntryScore = "12"
      }
   },
   [pscustomobject]@{
      Candidate = "peak_r20_all_nodec_r08_diagq"
      Window = "continuous_2024_2026"
      From = $From
      To = $To
      Purpose = "All non-December months while forcing diagnostic fallback signals to show structure and execution quality."
      Overrides = New-OrderedMap @{
         InpTradeJanuary = "true"
         InpTradeFebruary = "true"
         InpTradeMarch = "true"
         InpTradeApril = "true"
         InpTradeMay = "true"
         InpTradeJune = "true"
         InpTradeJuly = "true"
         InpTradeAugust = "true"
         InpTradeSeptember = "true"
         InpTradeOctober = "true"
         InpTradeNovember = "true"
         InpTradeDecember = "false"
         InpUseMonthDayWindowFilter = "false"
         InpUseMonthRiskMultipliers = "false"
         InpRiskPercent = "0.08"
         InpUseDiagnosticFallbackQualityGate = "true"
         InpDiagnosticFallbackMinPriceActionScore = "4"
         InpDiagnosticFallbackMinSmartMoneyScore = "2"
         InpDiagnosticFallbackRequireStructure = "true"
         InpDiagnosticFallbackRequireExecution = "true"
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
   $runLabel = "lowatr_r20_opp_{0}_{1}_m{2}" -f $variant.Candidate, $variant.Window, $Model
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

   $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $variant.Candidate, $variant.Window, $Model
   $reportName = "lowatr_r20_opp_{0}_{1}_m{2}" -f $variant.Candidate, $variant.Window, $Model
   $configPath = Join-Path $configDir $configName
   Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $variant.From -To $variant.To -Inputs $inputs -Model $Model

   $queue.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $variant.Candidate
      CandidateRank = $rank
      SourceType = "r20_opportunity_sweep"
      SourceRank = $rank
      Phase = "phase0_fast_model1"
      Set = $setName
      Window = $variant.Window
      From = $variant.From
      To = $variant.To
      Model = $Model
      Config = "configs\$configName"
      ExpectedReportName = $reportName
      ProfileSnapshot = "profiles\$setName"
      ProfileSha256 = $profileHash
      BaseProfileSha256 = $baseProfileHash
      StopRule = "Reject if broad window is red, drawdown exceeds 6%, 2025 quality stays weak, or the change only increases profit by accepting fragile risk."
      Purpose = $variant.Purpose
   }) | Out-Null

   $runRows.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $variant.Candidate
      Phase = "phase0_fast_model1"
      PhaseLabel = "R20 opportunity sweep"
      Window = $variant.Window
      Model = $Model
      PackageConfig = "outputs\lowatr_r20_opportunity_sweep_package\configs\$configName"
      SourceConfig = "outputs\lowatr_r20_opportunity_sweep_package\configs\$configName"
      ExpectedReportName = $reportName
      ReportDestination = "outputs\lowatr_r20_opportunity_sweep_package\reports_here\$reportName"
      ProfileSha256 = $profileHash
      StopRule = "Reject if broad window is red, drawdown exceeds 6%, 2025 quality stays weak, or the change only increases profit by accepting fragile risk."
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
$lines.Add("# LowATR R20 Opportunity Sweep Package") | Out-Null
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
