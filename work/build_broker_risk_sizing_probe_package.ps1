param(
   [string]$BaseSetPath = "outputs\CANDIDATE_RANGE_ELITE_HIGHPROFIT_PEAKTRAIL_OFF_CONTINUOUS_PROFILE.set",
   [string]$PackageDir = "outputs\broker_risk_sizing_probe_package",
   [string]$OutQueueManifest = "outputs\BROKER_RISK_SIZING_PROBE_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\BROKER_RISK_SIZING_PROBE_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\BROKER_RISK_SIZING_PROBE_PACKAGE.md",
   [ValidateSet("RiskSizing", "DgfActivity", "StabilityRebase", "StabilityRealtick")][string]$ProbeMode = "RiskSizing",
   [ValidateRange(100,100000000)][int]$Deposit = 1000,
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

function Apply-Overrides {
   param($Inputs, [hashtable]$Overrides)
   foreach($entry in $Overrides.GetEnumerator()) {
      Set-InputLine -Inputs $Inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
}

$baseSet = Resolve-RepoPath $BaseSetPath
if(!(Test-Path -LiteralPath $baseSet)) { throw "Base profile missing: $baseSet" }

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$baseProfileHash = (Get-FileHash -LiteralPath $baseSet -Algorithm SHA256).Hash

$variants = if($ProbeMode -eq "StabilityRealtick") {
   @(
      [pscustomobject]@{
         Name = "sr_m4_sweep_off"
         Description = "Continuous real-tick confirmation of the corrected-risk stability survivor with standalone sweeps disabled."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "1.00"
         }
      }
   )
} elseif($ProbeMode -eq "StabilityRebase") {
   @(
      [pscustomobject]@{
         Name = "sr_control"
         Description = "Corrected-risk rebase of the supplied stability profile with standalone sweep behavior preserved."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "true"
            InpMaxEffectiveRiskPercent = "1.00"
         }
      },
      [pscustomobject]@{
         Name = "sr_sweep_off"
         Description = "Corrected-risk rebase of the supplied stability profile with standalone sweeps disabled."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "1.00"
         }
      }
   )
} elseif($ProbeMode -eq "DgfActivity") {
   @(
      [pscustomobject]@{
         Name = "dfa_lb_on_throttle050"
         Description = "Correct sizing control: standalone sweeps off, 1.00% cap, DGF loss block on, 0.50 no-cushion risk."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "1.00"
            InpUseDiagnosticFallbackNoCushionLossBlock = "true"
            InpUseDiagnosticFallbackCushionRiskThrottle = "true"
            InpDiagnosticFallbackNoCushionRiskMultiplier = "0.50"
         }
      },
      [pscustomobject]@{
         Name = "dfa_lb_off_throttle025"
         Description = "DGF loss block off; hold DGF at 0.25 risk until the 5% closed-profit cushion."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "1.00"
            InpUseDiagnosticFallbackNoCushionLossBlock = "false"
            InpUseDiagnosticFallbackCushionRiskThrottle = "true"
            InpDiagnosticFallbackNoCushionRiskMultiplier = "0.25"
         }
      },
      [pscustomobject]@{
         Name = "dfa_lb_off_throttle050"
         Description = "DGF loss block off; hold DGF at 0.50 risk until the 5% closed-profit cushion."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "1.00"
            InpUseDiagnosticFallbackNoCushionLossBlock = "false"
            InpUseDiagnosticFallbackCushionRiskThrottle = "true"
            InpDiagnosticFallbackNoCushionRiskMultiplier = "0.50"
         }
      },
      [pscustomobject]@{
         Name = "dfa_lb_off_throttle075"
         Description = "DGF loss block off; hold DGF at 0.75 risk until the 5% closed-profit cushion."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "1.00"
            InpUseDiagnosticFallbackNoCushionLossBlock = "false"
            InpUseDiagnosticFallbackCushionRiskThrottle = "true"
            InpDiagnosticFallbackNoCushionRiskMultiplier = "0.75"
         }
      },
      [pscustomobject]@{
         Name = "dfa_lb_off_fullrisk"
         Description = "DGF loss block and cushion throttle off; standalone sweeps off; hard 1.00% effective-risk cap."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "1.00"
            InpUseDiagnosticFallbackNoCushionLossBlock = "false"
            InpUseDiagnosticFallbackCushionRiskThrottle = "false"
         }
      }
   )
} else {
   @(
      [pscustomobject]@{
         Name = "brs_uncapped_sweep_on"
         Description = "OrderCalcProfit sizing; preserve standalone liquidity-sweep entries; no effective-risk cap."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "true"
            InpMaxEffectiveRiskPercent = "0.00"
         }
      },
      [pscustomobject]@{
         Name = "brs_uncapped_sweep_off"
         Description = "OrderCalcProfit sizing; reject standalone liquidity-sweep entries; no effective-risk cap."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "0.00"
         }
      },
      [pscustomobject]@{
         Name = "brs_cap100_sweep_on"
         Description = "OrderCalcProfit sizing; preserve standalone liquidity sweeps; cap effective risk at 1.00%."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "true"
            InpMaxEffectiveRiskPercent = "1.00"
         }
      },
      [pscustomobject]@{
         Name = "brs_cap100_sweep_off"
         Description = "OrderCalcProfit sizing; reject standalone liquidity sweeps; cap effective risk at 1.00%."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "1.00"
         }
      },
      [pscustomobject]@{
         Name = "brs_cap075_sweep_off"
         Description = "OrderCalcProfit sizing; reject standalone liquidity sweeps; cap effective risk at 0.75%."
         Overrides = @{
            InpAllowStandaloneLiquiditySweepEntry = "false"
            InpMaxEffectiveRiskPercent = "0.75"
         }
      }
   )
}

$windows = if($ProbeMode -eq "StabilityRealtick") {
   @([pscustomobject]@{ Name = "continuous_2019_2026"; From = "2019.01.01"; To = "2026.07.12" })
} else {
   @(
      [pscustomobject]@{ Name = "continuous_2019_2026"; From = "2019.01.01"; To = "2026.07.12" },
      [pscustomobject]@{ Name = "2019_full"; From = "2019.01.01"; To = "2019.12.31" },
      [pscustomobject]@{ Name = "2020_full"; From = "2020.01.01"; To = "2020.12.31" },
      [pscustomobject]@{ Name = "2021_full"; From = "2021.01.01"; To = "2021.12.31" },
      [pscustomobject]@{ Name = "2022_full"; From = "2022.01.01"; To = "2022.12.31" },
      [pscustomobject]@{ Name = "2023_full"; From = "2023.01.01"; To = "2023.12.31" },
      [pscustomobject]@{ Name = "2024_full"; From = "2024.01.01"; To = "2024.12.31" },
      [pscustomobject]@{ Name = "2025_full"; From = "2025.01.01"; To = "2025.12.31" },
      [pscustomobject]@{ Name = "2026_ytd"; From = "2026.01.01"; To = "2026.07.12" }
   )
}
$variants = @($variants)
$windows = @($windows)

$packagePath = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packagePath
$configDir = Join-Path $packagePath "configs"
$profileDir = Join-Path $packagePath "profiles"
$reportDir = Join-Path $packagePath "reports_here"
$sourceDir = Join-Path $packagePath "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queue = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0

foreach($variant in $variants) {
   $inputs = Import-SetInputs $baseSet
   Apply-Overrides -Inputs $inputs -Overrides $variant.Overrides
   Apply-Overrides -Inputs $inputs -Overrides @{
      InpEvidenceProfileId = $variant.Name
      InpEvidenceSourceHash = $sourceHash
      InpEvidenceRunLabel = "broker_risk_sizing_$($ProbeMode.ToLowerInvariant())_m$Model"
      InpLogLevel = "0"
      InpUseBlockReasonDiagnostics = "false"
      InpShowDashboard = "false"
      InpDashboardInTester = "false"
      InpTesterFitnessMode = "1"
      InpAllowedSymbol = "XAUUSD"
      InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"
      InpAllowRealAccountTrading = "false"
      InpRealAccountApprovalCode = "DISABLED"
      InpRealAccountApprovalProfileId = "DISABLED"
      InpRealAccountApprovalSourceHash = "DISABLED"
   }

   $setName = "$($variant.Name).set"
   $setPath = Join-Path $profileDir $setName
   ($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath $setPath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $setPath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $variant.Name, $window.Name, $Model
      $reportName = "broker_risk_{0}_{1}_m{2}" -f $variant.Name, $window.Name, $Model
      $configPath = Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model -Deposit $Deposit

      $stopRule = "Reject if any broad year loses, continuous net is non-positive, PF is below 1.20, or drawdown remains above 10%."
      $queue.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $variant.Name
         SourceType = "broker_risk_sizing_probe"
         Phase = "fast_model$Model"
         Set = $setName
         Window = $window.Name
         From = $window.From
         To = $window.To
         Model = $Model
         InitialDeposit = $Deposit
         Config = "configs\$configName"
         ExpectedReportName = $reportName
         ProfileSnapshot = "profiles\$setName"
         ProfileSha256 = $profileHash
         BaseProfileSha256 = $baseProfileHash
         SourceSha256 = $sourceHash
         StopRule = $stopRule
         Rationale = $variant.Description
      }) | Out-Null

      $runRows.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $variant.Name
         Phase = "broker_risk_sizing_model$Model"
         PhaseLabel = "Broker-accurate risk sizing Model$Model"
         Window = $window.Name
         Model = $Model
         InitialDeposit = $Deposit
         PackageConfig = "$PackageDir\configs\$configName"
         SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName
         ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash
         StopRule = $stopRule
      }) | Out-Null
   }
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
$md.Add("# Broker-Accurate Risk Sizing Probe Package")
$md.Add("")
$md.Add("Offline package builder only. This does not launch MT5.")
$md.Add("")
$md.Add(("- Source hash: {0}" -f $sourceHash))
$md.Add(("- Base profile hash: {0}" -f $baseProfileHash))
$md.Add(("- Probe mode: {0}" -f $ProbeMode))
$md.Add(("- Model: {0}" -f $Model))
$md.Add(("- Initial deposit: {0}" -f $Deposit))
$md.Add(("- Variants: {0}" -f $variants.Count))
$md.Add(("- Windows per variant: {0}" -f $windows.Count))
$md.Add(("- Configs: {0}" -f $rank))
$md.Add("")
$md.Add($(if($ProbeMode -eq "StabilityRealtick") {
   "The package performs one continuous Model4 real-tick confirmation of the corrected-risk stability survivor."
} elseif($ProbeMode -eq "StabilityRebase") {
   "The matrix rebases a prior stability profile on broker-accurate sizing and compares preserved versus disabled standalone sweeps."
} elseif($ProbeMode -eq "DgfActivity") {
   "The matrix tests DGF activity after broker-accurate sizing, with standalone sweeps disabled and a hard 1.00% effective-risk cap."
} else {
   "The matrix isolates broker-accurate `OrderCalcProfit` sizing, the standalone liquidity-sweep lane, and hard effective-risk caps."
}))
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   PackageDir = $PackageDir
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   Markdown = $OutMarkdown
   Rows = $rank
   SourceHash = $sourceHash
}
