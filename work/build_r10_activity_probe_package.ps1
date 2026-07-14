param(
   [string]$BaseSetPath = "outputs\peak_r20_regime_combo_candidate_profiles\r10_pg40_atr085_adapt7.set",
   [string]$ActivitySetPath = "outputs\CANDIDATE_FMLR_ACTIVITY_BLEND_PROFILE.set",
   [string]$ActivityTightSetPath = "outputs\CANDIDATE_FMLR_ACTIVITY_BLEND_TIGHT_PROFILE.set",
   [string]$OutDir = "outputs\r10_activity_probe_package",
   [string]$OutQueueManifest = "outputs\R10_ACTIVITY_PROBE_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\R10_ACTIVITY_PROBE_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\R10_ACTIVITY_PROBE_PACKAGE.md",
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

function Get-FmlrOverrides {
   param([string]$Path)
   $source = Import-SetInputs (Resolve-RepoPath $Path)
   $overrides = @{}
   foreach($key in ($source.Keys | Sort-Object)) {
      if($key -match '^InpFlatMonthLiquidityReclaim' -or
         $key -match '^InpFMLR' -or
         $key -in @(
            "InpUseFlatMonthLiquidityReclaimLane",
            "InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter",
            "InpUseTickSpeedImpulse"
         )) {
         $line = [string]$source[$key]
         $idx = $line.IndexOf("=")
         if($idx -ge 0) {
            $value = $line.Substring($idx + 1)
            $pipe = $value.IndexOf("||")
            if($pipe -ge 0) { $value = $value.Substring(0, $pipe) }
            $overrides[$key] = $value
         }
      }
   }
   return $overrides
}

$windows = @(
   [pscustomobject]@{ Window = "2020_full"; From = "2020.01.01"; To = "2020.12.31" },
   [pscustomobject]@{ Window = "2022_full"; From = "2022.01.01"; To = "2022.12.31" },
   [pscustomobject]@{ Window = "2024_full"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2025_full"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2026_ytd"; From = "2026.01.01"; To = "2026.07.12" }
)

$baseSet = Resolve-RepoPath $BaseSetPath
if(!(Test-Path -LiteralPath $baseSet)) { throw "Base profile missing: $baseSet" }
if(!(Test-Path -LiteralPath (Resolve-RepoPath $ActivitySetPath))) { throw "Activity profile missing: $ActivitySetPath" }
if(!(Test-Path -LiteralPath (Resolve-RepoPath $ActivityTightSetPath))) { throw "Tight activity profile missing: $ActivityTightSetPath" }

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$baseProfileHash = (Get-FileHash -LiteralPath $baseSet -Algorithm SHA256).Hash
$fmlrBlend = Get-FmlrOverrides $ActivitySetPath
$fmlrTight = Get-FmlrOverrides $ActivityTightSetPath
$dfgSpreadRisk = @{
   InpUseDiagnosticFallbackSpreadRiskScaling = "true"
   InpDiagnosticFallbackSpreadRiskStartPoints = "25.0"
   InpDiagnosticFallbackSpreadRiskFullPoints = "45.0"
   InpDiagnosticFallbackMinSpreadRiskMultiplier = "0.50"
}

$candidates = @(
   [pscustomobject]@{
      Name = "r10_a7_current"
      Rationale = "Control: current R10 A7 stability lead."
      Overrides = @{}
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_risk_25_45_50"
      Rationale = "Known partial improvement: diagnostic fallback spread risk scaling."
      Overrides = $dfgSpreadRisk
   },
   [pscustomobject]@{
      Name = "r10_a7_fmlr_blend"
      Rationale = "Graft FMLR activity blend onto current R10 A7 profile to test dead-window participation."
      Overrides = $fmlrBlend
   },
   [pscustomobject]@{
      Name = "r10_a7_fmlr_tight"
      Rationale = "Graft tighter FMLR activity blend onto current R10 A7 profile."
      Overrides = $fmlrTight
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_fmlr_blend"
      Rationale = "Combine known diagnostic fallback spread-risk reduction with FMLR activity blend."
      Overrides = (Merge-Overrides @($fmlrBlend, $dfgSpreadRisk))
   },
   [pscustomobject]@{
      Name = "r10_a7_dfg_fmlr_tight"
      Rationale = "Combine known diagnostic fallback spread-risk reduction with tighter FMLR activity blend."
      Overrides = (Merge-Overrides @($fmlrTight, $dfgSpreadRisk))
   }
)

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
   $inputs = Import-SetInputs $baseSet
   Apply-Overrides -Inputs $inputs -Overrides $candidate.Overrides
   Apply-Overrides -Inputs $inputs -Overrides @{
      InpEvidenceProfileId = $candidate.Name
      InpEvidenceSourceHash = $sourceHash
      InpEvidenceRunLabel = "r10_activity_probe_model$Model"
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

   $setName = "{0}.set" -f $candidate.Name
   $setPath = Join-Path $profileDir $setName
   $setLines = [System.Collections.Generic.List[string]]::new()
   foreach($key in ($inputs.Keys | Sort-Object)) { $setLines.Add($inputs[$key]) | Out-Null }
   $setLines | Set-Content -LiteralPath $setPath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $setPath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $candidate.Name, $window.Window, $Model
      $reportName = "r10_activity_probe_{0}_{1}_m{2}" -f $candidate.Name, $window.Window, $Model
      $configPath = Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model

      $stopRule = "Reject unless blocker windows improve without creating red focus windows or excessive drawdown."
      $queue.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate.Name
         CandidateRank = $rank
         SourceType = "r10_activity_probe"
         SourceRank = $rank
         Phase = "phase7_activity_probe_model$Model"
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
         Phase = "phase7_activity_probe_model$Model"
         PhaseLabel = "R10 A7 blocker-window activity probe Model$Model"
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
$md.Add("# R10 Activity Probe Package") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline package builder only. This does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Source hash: ``$sourceHash``") | Out-Null
$md.Add("- Base profile hash: ``$baseProfileHash``") | Out-Null
$md.Add("- Model: ``$Model``") | Out-Null
$md.Add("- Candidates: ``$($candidates.Name -join ', ')``") | Out-Null
$md.Add("- Windows: ``$($windows.Window -join ', ')``") | Out-Null
$md.Add("- Configs: ``$rank``") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Purpose") | Out-Null
$md.Add("") | Out-Null
$md.Add("This first-pass package targets the current stability lead's blocker years. It tests whether already-built low-risk FMLR activity logic can add participation without replacing the R10 A7 stability settings.") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Files") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Queue manifest: ``$OutQueueManifest``") | Out-Null
$md.Add("- Runner manifest: ``$OutPackageManifest``") | Out-Null
$md.Add("- Package dir: ``$OutDir``") | Out-Null
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   Candidates = $candidates.Count
   Windows = $windows.Count
   Configs = $rank
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   PackageDir = $OutDir
}
