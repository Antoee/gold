param(
   [string]$BaseSetPath = "outputs\CANDIDATE_RANGE_ELITE_HIGHPROFIT_PEAKTRAIL_OFF_CONTINUOUS_PROFILE.set",
   [string]$PackageDir = "outputs\dgf_highprofit_risk_shape_package",
   [string]$OutQueueManifest = "outputs\DGF_HIGHPROFIT_RISK_SHAPE_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\DGF_HIGHPROFIT_RISK_SHAPE_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\DGF_HIGHPROFIT_RISK_SHAPE_PACKAGE.md",
   [int]$Model = 4,
   [string]$From = "2019.01.01",
   [string]$To = "2026.07.12",
   [string]$Window = "continuous_2019_2026"
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

function Merge-HashTables {
   param([hashtable[]]$Tables)
   $merged = @{}
   foreach($table in $Tables) {
      foreach($entry in $table.GetEnumerator()) {
         $merged[$entry.Key] = $entry.Value
      }
   }
   return $merged
}

$baseSet = Resolve-RepoPath $BaseSetPath
if(!(Test-Path -LiteralPath $baseSet)) { throw "Base profile missing: $baseSet" }

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$baseProfileHash = (Get-FileHash -LiteralPath $baseSet -Algorithm SHA256).Hash

$lossScaling = @{
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

$variants = @(
   [pscustomobject]@{
      Name = "dgf_hp_control"
      Description = "Current high-profit DGF continuous lead control."
      Overrides = @{}
   },
   [pscustomobject]@{
      Name = "dgf_hp_risk050"
      Description = "Scale base risk from 1.00% to 0.50%."
      Overrides = @{ InpRiskPercent = "0.50" }
   },
   [pscustomobject]@{
      Name = "dgf_hp_risk060"
      Description = "Scale base risk from 1.00% to 0.60%."
      Overrides = @{ InpRiskPercent = "0.60" }
   },
   [pscustomobject]@{
      Name = "dgf_hp_risk070"
      Description = "Scale base risk from 1.00% to 0.70%."
      Overrides = @{ InpRiskPercent = "0.70" }
   },
   [pscustomobject]@{
      Name = "dgf_hp_risk080"
      Description = "Scale base risk from 1.00% to 0.80%."
      Overrides = @{ InpRiskPercent = "0.80" }
   },
   [pscustomobject]@{
      Name = "dgf_hp_risk060_loss_scale"
      Description = "0.60% base risk plus daily/weekly/monthly loss-risk scaling."
      Overrides = (Merge-HashTables @(@{ InpRiskPercent = "0.60" }, $lossScaling))
   },
   [pscustomobject]@{
      Name = "dgf_hp_risk080_loss_scale"
      Description = "0.80% base risk plus daily/weekly/monthly loss-risk scaling."
      Overrides = (Merge-HashTables @(@{ InpRiskPercent = "0.80" }, $lossScaling))
   },
   [pscustomobject]@{
      Name = "dgf_hp_risk080_dd12"
      Description = "0.80% base risk plus 12% max-equity-drawdown safety cap."
      Overrides = @{
         InpRiskPercent = "0.80"
         InpMaxEquityDrawdownPercent = "12.00"
      }
   },
   [pscustomobject]@{
      Name = "dgf_hp_peaktrail_20p70gb"
      Description = "Late profit lock after 20% gain with 70% peak-profit giveback."
      Overrides = @{
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "20.00"
         InpEquityProfitPeakTrailGivebackPercent = "70.0"
      }
   },
   [pscustomobject]@{
      Name = "dgf_hp_peaktrail_35p70gb"
      Description = "Later profit lock after 35% gain with 70% peak-profit giveback."
      Overrides = @{
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "35.00"
         InpEquityProfitPeakTrailGivebackPercent = "70.0"
      }
   },
   [pscustomobject]@{
      Name = "dgf_hp_risk080_peaktrail_20p70gb"
      Description = "0.80% base risk plus late 20%/70% profit lock."
      Overrides = @{
         InpRiskPercent = "0.80"
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "20.00"
         InpEquityProfitPeakTrailGivebackPercent = "70.0"
      }
   }
)

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
   $rank++
   $inputs = Import-SetInputs $baseSet
   Apply-Overrides -Inputs $inputs -Overrides $variant.Overrides
   Apply-Overrides -Inputs $inputs -Overrides @{
      InpEvidenceProfileId = $variant.Name
      InpEvidenceSourceHash = $sourceHash
      InpEvidenceRunLabel = "dgf_highprofit_risk_shape_m$Model"
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

   $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $variant.Name, $Window, $Model
   $reportName = "dgf_hp_risk_shape_{0}_{1}_m{2}" -f $variant.Name, $Window, $Model
   $configPath = Join-Path $configDir $configName
   Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $From -To $To -Inputs $inputs -Model $Model

   $stopRule = "Reject if net/DD efficiency weakens, if drawdown remains above trade-ready range, or if profit comes from an early global freeze."
   $queue.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $variant.Name
      SourceType = "dgf_highprofit_risk_shape"
      Phase = "continuous_model$Model"
      Set = $setName
      Window = $Window
      From = $From
      To = $To
      Model = $Model
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
      Phase = "dgf_highprofit_risk_shape_model$Model"
      PhaseLabel = "DGF high-profit risk-shape continuous Model$Model"
      Window = $Window
      Model = $Model
      PackageConfig = "$PackageDir\configs\$configName"
      SourceConfig = "$PackageDir\configs\$configName"
      ExpectedReportName = $reportName
      ReportDestination = "$PackageDir\reports_here\$reportName"
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

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# DGF High-Profit Risk-Shape Probe Package")
$md.Add("")
$md.Add("Offline package builder only. This does not launch MT5.")
$md.Add("")
$md.Add("- Purpose: reduce drawdown on the profitable DGF continuous branch without returning to the early global peak-trail freeze.")
$md.Add(("- Source hash: {0}" -f $sourceHash))
$md.Add(("- Base profile hash: {0}" -f $baseProfileHash))
$md.Add(("- Window: {0} to {1}" -f $From, $To))
$md.Add(("- Model: {0}" -f $Model))
$md.Add(("- Configs: {0}" -f $rank))
$md.Add("")
$md.Add("## Candidates")
$md.Add("")
$md.Add("| Rank | Candidate | Profile SHA-256 | Rationale |")
$md.Add("| ---: | --- | --- | --- |")
foreach($row in $queue) {
   $md.Add(("| {0} | {1} | {2} | {3} |" -f $row.QueueRank, $row.Candidate, $row.ProfileSha256, $row.Rationale))
}
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   PackageDir = $PackageDir
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   Markdown = $OutMarkdown
   Rows = $rank
   SourceHash = $sourceHash
}
