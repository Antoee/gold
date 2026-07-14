param(
   [string]$BaseSetPath = "outputs\peak_r20_oos_yearly_package\profiles\r10_profit_guard40.set",
   [string]$OutDir = "outputs\peak_r20_regime_combo_sweep_package",
   [string]$OutQueueManifest = "outputs\PEAK_R20_REGIME_COMBO_SWEEP_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\PEAK_R20_REGIME_COMBO_SWEEP_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\PEAK_R20_REGIME_COMBO_SWEEP_PACKAGE.md",
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

function New-OverrideTable {
   param([hashtable[]]$Tables)
   $merged = @{}
   foreach($table in $Tables) {
      foreach($entry in $table.GetEnumerator()) {
         $merged[$entry.Key] = $entry.Value
      }
   }
   return $merged
}

$windows = @(
   [pscustomobject]@{ Window = "2019_full"; From = "2019.01.01"; To = "2019.12.31" },
   [pscustomobject]@{ Window = "2021_full"; From = "2021.01.01"; To = "2021.12.31" },
   [pscustomobject]@{ Window = "2022_full"; From = "2022.01.01"; To = "2022.12.31" },
   [pscustomobject]@{ Window = "2023_full"; From = "2023.01.01"; To = "2023.12.31" },
   [pscustomobject]@{ Window = "2024_full"; From = "2024.01.01"; To = "2024.12.31" }
)

$atr085 = @{
   InpUseDynamicATRRegimeGuard = "true"
   InpMinATRRegimeRatio = "0.85"
   InpMaxATRRegimeRatio = "1.65"
}
$adapt6 = @{
   InpUseAdaptiveRegimeConfidenceGate = "true"
   InpAdaptiveRegimeMinScore = "6"
}
$adapt7 = @{
   InpUseAdaptiveRegimeConfidenceGate = "true"
   InpAdaptiveRegimeMinScore = "7"
   InpAdaptiveRegimeMinEfficiency = "0.45"
}
$sessionExhaust = @{
   InpUseSessionRangeExhaustionGuard = "true"
   InpSessionRangeExhaustionMinATR = "2.20"
   InpSessionRangeExhaustionExtremePercent = "82.0"
}

$candidates = @(
   [pscustomobject]@{
      Name = "r10_pg40_atr085_control"
      Family = "atr_regime"
      Rationale = "Carry-forward control from first sweep: dynamic ATR guard 0.85-1.65."
      Overrides = $atr085
   },
   [pscustomobject]@{
      Name = "r10_pg40_atr085_adapt6"
      Family = "atr_plus_adaptive"
      Rationale = "ATR guard plus moderate adaptive regime confidence."
      Overrides = New-OverrideTable @($atr085, $adapt6)
   },
   [pscustomobject]@{
      Name = "r10_pg40_atr085_adapt7"
      Family = "atr_plus_adaptive"
      Rationale = "ATR guard plus high adaptive regime confidence."
      Overrides = New-OverrideTable @($atr085, $adapt7)
   },
   [pscustomobject]@{
      Name = "r10_pg40_atr085_session"
      Family = "atr_plus_session"
      Rationale = "ATR guard plus session range exhaustion block."
      Overrides = New-OverrideTable @($atr085, $sessionExhaust)
   },
   [pscustomobject]@{
      Name = "r10_pg40_atr085_adapt6_session"
      Family = "atr_adaptive_session"
      Rationale = "ATR guard, moderate adaptive gate, and session exhaustion block."
      Overrides = New-OverrideTable @($atr085, $adapt6, $sessionExhaust)
   },
   [pscustomobject]@{
      Name = "r10_pg40_atr085_adapt7_session"
      Family = "atr_adaptive_session"
      Rationale = "ATR guard, high adaptive gate, and session exhaustion block."
      Overrides = New-OverrideTable @($atr085, $adapt7, $sessionExhaust)
   },
   [pscustomobject]@{
      Name = "r10_pg40_atr085_adx22"
      Family = "atr_plus_trend_strength"
      Rationale = "ATR guard plus slightly higher trend ADX threshold."
      Overrides = New-OverrideTable @($atr085, @{ InpTrendADXThreshold = "22.0" })
   },
   [pscustomobject]@{
      Name = "r10_pg40_atr085_adx24"
      Family = "atr_plus_trend_strength"
      Rationale = "ATR guard plus higher trend ADX threshold."
      Overrides = New-OverrideTable @($atr085, @{ InpTrendADXThreshold = "24.0" })
   },
   [pscustomobject]@{
      Name = "r10_pg40_atr085_no_diagfallback"
      Family = "atr_plus_fallback_off"
      Rationale = "ATR guard with diagnostic fallback disabled."
      Overrides = New-OverrideTable @($atr085, @{ InpUseDiagnosticTrendFallbackEntry = "false" })
   }
)

$baseSet = Resolve-RepoPath $BaseSetPath
if(!(Test-Path -LiteralPath $baseSet)) {
   throw "Base combo sweep profile missing: $baseSet"
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
      $runLabel = "peak_r20_regime_combo_{0}_{1}_m{2}" -f $candidate.Name, $window.Window, $Model

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
      $reportName = "peak_r20_regime_combo_{0}_{1}_m{2}" -f $candidate.Name, $window.Window, $Model
      $configPath = Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model

      $stopRule = "Reject unless combo improves older-year stability without creating a new recent-year failure."
      $queue.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate.Name
         CandidateRank = $rank
         Family = $candidate.Family
         SourceType = "peak_r20_regime_combo_sweep"
         SourceRank = $rank
         Phase = "phase4_regime_combo_sweep_model$Model"
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
         Phase = "phase4_regime_combo_sweep_model$Model"
         PhaseLabel = "Peak R20 R10 regime combo sweep"
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
$md.Add("# Peak R20 Regime Combo Sweep Package") | Out-Null
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
$md.Add("## Candidate Families") | Out-Null
$md.Add("") | Out-Null
foreach($candidate in $candidates) {
   $md.Add("- ``$($candidate.Name)`` ($($candidate.Family)): $($candidate.Rationale)") | Out-Null
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
