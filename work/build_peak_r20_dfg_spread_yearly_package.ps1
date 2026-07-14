param(
   [string]$BaseSetPath = "outputs\peak_r20_regime_combo_candidate_profiles\r10_pg40_atr085_adapt7.set",
   [string]$OutDir = "outputs\peak_r20_dfg_spread_yearly_package",
   [string]$OutQueueManifest = "outputs\PEAK_R20_DFG_SPREAD_YEARLY_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\PEAK_R20_DFG_SPREAD_YEARLY_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\PEAK_R20_DFG_SPREAD_YEARLY_PACKAGE.md",
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

$candidates = @(
   [pscustomobject]@{
      Name = "r10_a7_dfg_base"
      Rationale = "Control: no diagnostic fallback spread guard."
      Overrides = @{}
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_spread29"
      Rationale = "Block diagnostic fallback entries above 29 spread points."
      Overrides = @{
         InpUseDiagnosticFallbackSpreadGuard = "true"
         InpDiagnosticFallbackMaxSpreadPoints = "29.0"
      }
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_spread27"
      Rationale = "Block diagnostic fallback entries above 27 spread points."
      Overrides = @{
         InpUseDiagnosticFallbackSpreadGuard = "true"
         InpDiagnosticFallbackMaxSpreadPoints = "27.0"
      }
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_spread25"
      Rationale = "Block diagnostic fallback entries above 25 spread points."
      Overrides = @{
         InpUseDiagnosticFallbackSpreadGuard = "true"
         InpDiagnosticFallbackMaxSpreadPoints = "25.0"
      }
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_atr75"
      Rationale = "Block diagnostic fallback entries above 7.5 percent spread/ATR."
      Overrides = @{
         InpUseDiagnosticFallbackSpreadGuard = "true"
         InpDiagnosticFallbackMaxSpreadATRPercent = "7.5"
      }
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_atr70"
      Rationale = "Block diagnostic fallback entries above 7.0 percent spread/ATR."
      Overrides = @{
         InpUseDiagnosticFallbackSpreadGuard = "true"
         InpDiagnosticFallbackMaxSpreadATRPercent = "7.0"
      }
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_spread29_atr75"
      Rationale = "Block diagnostic fallback entries above 29 spread points or 7.5 percent spread/ATR."
      Overrides = @{
         InpUseDiagnosticFallbackSpreadGuard = "true"
         InpDiagnosticFallbackMaxSpreadPoints = "29.0"
         InpDiagnosticFallbackMaxSpreadATRPercent = "7.5"
      }
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_spread27_atr70"
      Rationale = "Block diagnostic fallback entries above 27 spread points or 7.0 percent spread/ATR."
      Overrides = @{
         InpUseDiagnosticFallbackSpreadGuard = "true"
         InpDiagnosticFallbackMaxSpreadPoints = "27.0"
         InpDiagnosticFallbackMaxSpreadATRPercent = "7.0"
      }
   }
)

$baseSet = Resolve-RepoPath $BaseSetPath
if(!(Test-Path -LiteralPath $baseSet)) {
   throw "Base DFG spread profile missing: $baseSet"
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

$queue = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
foreach($candidate in $candidates) {
   foreach($window in $windows) {
      $rank++
      $inputs = Import-SetInputs $baseSet
      $profileId = "{0}_{1}" -f $candidate.Name, $window.Window
      $runLabel = "peak_r20_dfg_spread_{0}_{1}_m{2}" -f $candidate.Name, $window.Window, $Model

      Apply-Overrides -Inputs $inputs -Overrides $candidate.Overrides
      Apply-Overrides -Inputs $inputs -Overrides @{
         InpEvidenceProfileId = $profileId
         InpEvidenceSourceHash = $sourceHash
         InpEvidenceRunLabel = $runLabel
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

      $setName = "{0}_{1}.set" -f $candidate.Name, $window.Window
      $setPath = Join-Path $profileDir $setName
      $setLines = [System.Collections.Generic.List[string]]::new()
      foreach($key in ($inputs.Keys | Sort-Object)) {
         $setLines.Add($inputs[$key]) | Out-Null
      }
      $setLines | Set-Content -LiteralPath $setPath -Encoding ASCII
      $profileHash = (Get-FileHash -LiteralPath $setPath -Algorithm SHA256).Hash

      $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $candidate.Name, $window.Window, $Model
      $reportName = "peak_r20_dfg_spread_{0}_{1}_m{2}" -f $candidate.Name, $window.Window, $Model
      $configPath = Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model

      $stopRule = "Reject unless diagnostic fallback spread control removes Model4 fragility without killing yearly stability."
      $queue.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate.Name
         CandidateRank = $rank
         SourceType = "peak_r20_dfg_spread_yearly"
         SourceRank = $rank
         Phase = "phase6_dfg_spread_yearly_model$Model"
         Set = $setName
         Window = $window.Window
         From = $window.From
         To = $window.To
         Model = $Model
         Config = "configs\$configName"
         ExpectedReportName = $reportName
         ProfileSnapshot = "profiles\$setName"
         ProfileSha256 = $profileHash
         BaseProfileSha256 = $baseProfileHash
         StopRule = $stopRule
         Rationale = $candidate.Rationale
      }) | Out-Null

      $runRows.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate.Name
         Phase = "phase6_dfg_spread_yearly_model$Model"
         PhaseLabel = "Peak R20 diagnostic fallback spread yearly Model$Model"
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
$md.Add("# Peak R20 Diagnostic Fallback Spread Yearly Package") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline package builder only. This does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Source hash: ``$sourceHash``") | Out-Null
$md.Add("- Base profile hash: ``$baseProfileHash``") | Out-Null
$md.Add("- Model: ``$Model``") | Out-Null
$md.Add("- Candidates: ``$($candidates.Count)``") | Out-Null
$md.Add("- Windows: ``$($windows.Count)``") | Out-Null
$md.Add("- Configs: ``$rank``") | Out-Null
$md.Add("") | Out-Null
foreach($candidate in $candidates) {
   $md.Add("- ``$($candidate.Name)``: $($candidate.Rationale)") | Out-Null
}
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   BaseProfileHash = $baseProfileHash
   Candidates = $candidates.Count
   Windows = $windows.Count
   Configs = $rank
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   PackageDir = $OutDir
}
