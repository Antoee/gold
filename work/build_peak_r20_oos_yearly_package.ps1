param(
   [string]$ProfileDir = "outputs\peak_r20_drawdown_sweep_package\profiles",
   [string]$OutDir = "outputs\peak_r20_oos_yearly_package",
   [string]$OutQueueManifest = "outputs\PEAK_R20_OOS_YEARLY_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\PEAK_R20_OOS_YEARLY_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\PEAK_R20_OOS_YEARLY_PACKAGE.md",
   [string[]]$Candidates = @("r10_base", "r10_loss_scale_15", "r10_profit_guard40"),
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

$windows = @(
   [pscustomobject]@{ Window = "2019_full"; From = "2019.01.01"; To = "2019.12.31" },
   [pscustomobject]@{ Window = "2020_full"; From = "2020.01.01"; To = "2020.12.31" },
   [pscustomobject]@{ Window = "2021_full"; From = "2021.01.01"; To = "2021.12.31" },
   [pscustomobject]@{ Window = "2022_full"; From = "2022.01.01"; To = "2022.12.31" },
   [pscustomobject]@{ Window = "2023_full"; From = "2023.01.01"; To = "2023.12.31" },
   [pscustomobject]@{ Window = "2024_full"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2025_full"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2026_ytd"; From = "2026.01.01"; To = "2026.07.12" }
)

$resolvedProfileDir = Resolve-RepoPath $ProfileDir
if(!(Test-Path -LiteralPath $resolvedProfileDir)) {
   throw "Profile directory missing: $resolvedProfileDir"
}

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash

$packageDir = Resolve-RepoPath $OutDir
Clear-OutputDirSafe $packageDir
$configDir = Join-Path $packageDir "configs"
$profileOutDir = Join-Path $packageDir "profiles"
$reportDir = Join-Path $packageDir "reports_here"
$sourceDir = Join-Path $packageDir "source"
New-Item -ItemType Directory -Path $configDir, $profileOutDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queue = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
foreach($candidate in $Candidates) {
   $sourceSet = Join-Path $resolvedProfileDir ("{0}.set" -f $candidate)
   if(!(Test-Path -LiteralPath $sourceSet)) {
      throw "Candidate profile missing: $sourceSet"
   }

   $setName = "{0}.set" -f $candidate
   $setPath = Join-Path $profileOutDir $setName
   $inputs = Import-SetInputs $sourceSet
   Apply-Overrides -Inputs $inputs -Overrides @{
      InpEvidenceProfileId = $candidate
      InpEvidenceSourceHash = $sourceHash
      InpEvidenceRunLabel = "peak_r20_oos_yearly_model$Model"
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
   $setLines = [System.Collections.Generic.List[string]]::new()
   foreach($key in ($inputs.Keys | Sort-Object)) {
      $setLines.Add($inputs[$key]) | Out-Null
   }
   $setLines | Set-Content -LiteralPath $setPath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $setPath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $candidate, $window.Window, $Model
      $reportName = "peak_r20_oos_{0}_{1}_m{2}" -f $candidate, $window.Window, $Model
      $configPath = Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model

      $stopRule = "Reject money-ready claims if older/yearly windows are red, too sparse, or show unstable drawdown/profit quality."
      $queue.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate
         CandidateRank = $rank
         SourceType = "peak_r20_oos_yearly"
         SourceRank = $rank
         Phase = "phase2_oos_yearly_model$Model"
         Set = $setName
         Window = $window.Window
         From = $window.From
         To = $window.To
         Model = $Model
         Config = "configs\$configName"
         ExpectedReportName = $reportName
         ProfileSnapshot = "profiles\$setName"
         ProfileSha256 = $profileHash
         StopRule = $stopRule
         Purpose = "Older and year-by-year validation to avoid trusting only 2024-2026 seen research data."
      }) | Out-Null

      $runRows.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate
         Phase = "phase2_oos_yearly_model$Model"
         PhaseLabel = "Peak R20 R10 OOS yearly Model$Model"
         Window = $window.Window
         Model = $Model
         PackageConfig = "$OutDir\configs\$configName"
         SourceConfig = "$OutDir\configs\$configName"
         ExpectedReportName = $reportName
         ReportDestination = "$OutDir\reports_here\$reportName"
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
$md.Add("# Peak R20 OOS Yearly Validation Package") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline package builder only. This does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Source hash: ``$sourceHash``") | Out-Null
$md.Add("- Model: ``$Model``") | Out-Null
$md.Add("- Candidates: ``$($Candidates -join ', ')``") | Out-Null
$md.Add("- Windows: ``$($windows.Window -join ', ')``") | Out-Null
$md.Add("- Configs: ``$rank``") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Purpose") | Out-Null
$md.Add("") | Out-Null
$md.Add("This package tests whether the R10 research branches survive older and year-by-year windows instead of only looking good on the recent 2024-2026 research-seen range.") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Files") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Queue manifest: ``$OutQueueManifest``") | Out-Null
$md.Add("- Runner manifest: ``$OutPackageManifest``") | Out-Null
$md.Add("- Package dir: ``$OutDir``") | Out-Null
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   Candidates = $Candidates.Count
   Windows = $windows.Count
   Configs = $rank
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   PackageDir = $OutDir
}
