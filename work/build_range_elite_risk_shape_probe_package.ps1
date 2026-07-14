param(
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE.set",
   [string]$OutDir = "outputs\range_elite_risk_shape_probe_package",
   [string]$OutQueueManifest = "outputs\RANGE_ELITE_RISK_SHAPE_PROBE_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\RANGE_ELITE_RISK_SHAPE_PROBE_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\RANGE_ELITE_RISK_SHAPE_PROBE_PACKAGE.md",
   [int]$Model = 1,
   [string[]]$CandidateFilter = @(),
   [switch]$Include2025
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

function Get-SourceInputNames {
   param([string]$Path)
   $names = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -match '^\s*input\s+\S+\s+(Inp[A-Za-z0-9_]+)\s*=') {
         $names.Add($matches[1]) | Out-Null
      }
   }
   return $names
}

function Assert-InputsExposed {
   param($Inputs, [System.Collections.Generic.HashSet[string]]$ExposedInputs)
   $missing = @($Inputs.Keys | Where-Object { !$ExposedInputs.Contains($_) } | Sort-Object)
   if($missing.Count -gt 0) {
      throw "Profile/config contains input(s) not exposed by the current EA source: $($missing -join ', ')"
   }
}

function Assert-OverridesExposed {
   param([hashtable]$Overrides, [System.Collections.Generic.HashSet[string]]$ExposedInputs)
   $missing = @($Overrides.Keys | Where-Object { !$ExposedInputs.Contains($_) } | Sort-Object)
   if($missing.Count -gt 0) {
      throw "Candidate/fixed override contains input(s) not exposed by the current EA source: $($missing -join ', ')"
   }
}

function Remove-StaleInputs {
   param($Inputs, [System.Collections.Generic.HashSet[string]]$ExposedInputs)
   $removed = @($Inputs.Keys | Where-Object { !$ExposedInputs.Contains($_) } | Sort-Object)
   foreach($key in $removed) {
      $Inputs.Remove($key)
   }
   return $removed
}

$windows = @(
   [pscustomobject]@{ Window = "2019_full"; Short = "2019"; From = "2019.01.01"; To = "2019.12.31"; Role = "red_year" },
   [pscustomobject]@{ Window = "2021_full"; Short = "2021"; From = "2021.01.01"; To = "2021.12.31"; Role = "red_year" },
   [pscustomobject]@{ Window = "2023_full"; Short = "2023"; From = "2023.01.01"; To = "2023.12.31"; Role = "red_year" },
   [pscustomobject]@{ Window = "2024_full"; Short = "2024"; From = "2024.01.01"; To = "2024.12.31"; Role = "profit_control" },
   [pscustomobject]@{ Window = "2026_ytd"; Short = "2026ytd"; From = "2026.01.01"; To = "2026.07.12"; Role = "high_dd_recent" }
)
if($Include2025) {
   $windows = @($windows[0..3]) +
              [pscustomobject]@{ Window = "2025_full"; Short = "2025"; From = "2025.01.01"; To = "2025.12.31"; Role = "profit_control" } +
              @($windows[4..($windows.Count - 1)])
}

$candidates = @(
   [pscustomobject]@{
      Name = "re_base"
      Thesis = "Current range-elite baseline on the focused windows."
      Overrides = @{}
   },
   [pscustomobject]@{
      Name = "re_may100"
      Thesis = "Remove the May 2.80 risk boost while keeping May trades enabled."
      Overrides = @{ InpMayRiskMultiplier = "1.00" }
   },
   [pscustomobject]@{
      Name = "re_may140"
      Thesis = "Keep a smaller May opportunity boost without letting May dominate account risk."
      Overrides = @{ InpMayRiskMultiplier = "1.40" }
   },
   [pscustomobject]@{
      Name = "re_may200"
      Thesis = "Intermediate May cap between current 2.80 and neutral 1.00."
      Overrides = @{ InpMayRiskMultiplier = "2.00" }
   },
   [pscustomobject]@{
      Name = "re_maxrisk100"
      Thesis = "Cap effective risk at 1.00%, clipping May/profit boosts without touching entries."
      Overrides = @{ InpMaxEffectiveRiskPercent = "1.00" }
   },
   [pscustomobject]@{
      Name = "re_lotcap030"
      Thesis = "Cap position size at 0.30 lots to block oversized late equity-growth losers."
      Overrides = @{ InpMaxPositionLots = "0.30" }
   },
   [pscustomobject]@{
      Name = "re_ny_end16"
      Thesis = "End New York entries before hour 16, the worst trade-log hour."
      Overrides = @{ InpNewYorkEndHour = "16" }
   },
   [pscustomobject]@{
      Name = "re_ny16_may140_lot030"
      Thesis = "Combined tail-risk cap: earlier NY end, smaller May boost, and 0.30 lot cap."
      Overrides = @{
         InpNewYorkEndHour = "16"
         InpMayRiskMultiplier = "1.40"
         InpMaxPositionLots = "0.30"
      }
   },
   [pscustomobject]@{
      Name = "re_dgfq_default"
      Thesis = "Enable the built-in diagnostic-fallback quality gate with default PA/SMQ/execution requirements."
      Overrides = @{
         InpUseDiagnosticFallbackQualityGate = "true"
      }
   },
   [pscustomobject]@{
      Name = "re_dgfq_pa6_smq4"
      Thesis = "Require stronger price-action and smart-money scores before diagnostic fallback can contribute."
      Overrides = @{
         InpUseDiagnosticFallbackQualityGate = "true"
         InpDiagnosticFallbackMinPriceActionScore = "6"
         InpDiagnosticFallbackMinSmartMoneyScore = "4"
      }
   },
   [pscustomobject]@{
      Name = "re_dgfq_struct"
      Thesis = "Require nearby structure evidence for diagnostic fallback instead of candle direction alone."
      Overrides = @{
         InpUseDiagnosticFallbackQualityGate = "true"
         InpDiagnosticFallbackRequireStructure = "true"
      }
   },
   [pscustomobject]@{
      Name = "re_dgfq_struct_liq"
      Thesis = "Require both structure and liquidity evidence for diagnostic fallback."
      Overrides = @{
         InpUseDiagnosticFallbackQualityGate = "true"
         InpDiagnosticFallbackRequireStructure = "true"
         InpDiagnosticFallbackRequireLiquidity = "true"
      }
   },
   [pscustomobject]@{
      Name = "re_may140_dgfq"
      Thesis = "Combine smaller May risk with the default diagnostic-fallback quality gate."
      Overrides = @{
         InpMayRiskMultiplier = "1.40"
         InpUseDiagnosticFallbackQualityGate = "true"
      }
   },
   [pscustomobject]@{
      Name = "re_blockliq"
      Thesis = "Block diagnostic fallback when the setup is also a liquidity-sweep setup."
      Overrides = @{
         InpDiagnosticFallbackBlockLiquiditySweep = "true"
      }
   },
   [pscustomobject]@{
      Name = "re_blockliq_may140"
      Thesis = "Block diagnostic/liquidity conflict and keep a smaller May risk boost."
      Overrides = @{
         InpDiagnosticFallbackBlockLiquiditySweep = "true"
         InpMayRiskMultiplier = "1.40"
      }
   },
   [pscustomobject]@{
      Name = "re_blockliq_may100"
      Thesis = "Block diagnostic/liquidity conflict and remove the May risk boost."
      Overrides = @{
         InpDiagnosticFallbackBlockLiquiditySweep = "true"
         InpMayRiskMultiplier = "1.00"
      }
   },
   [pscustomobject]@{
      Name = "re_dgf_liq_reject1"
      Thesis = "Reject DGF plus liquidity-sweep entries when liquidity sweep is the only pre-DGF confirmation."
      Overrides = @{
         InpDiagnosticFallbackRejectLiquiditySweepSignal = "true"
         InpDiagnosticFallbackLiquidityRejectMaxConfirmations = "1"
      }
   },
   [pscustomobject]@{
      Name = "re_may140_dgf_liq_reject1"
      Thesis = "Combine smaller May risk with true rejection of weak DGF plus liquidity-sweep entries."
      Overrides = @{
         InpMayRiskMultiplier = "1.40"
         InpDiagnosticFallbackRejectLiquiditySweepSignal = "true"
         InpDiagnosticFallbackLiquidityRejectMaxConfirmations = "1"
      }
   },
   [pscustomobject]@{
      Name = "re_may140_late15_dgf_liq_reject1"
      Thesis = "Combine May risk cap, late pure-DGF guard, and true rejection of weak DGF plus liquidity-sweep entries."
      Overrides = @{
         InpMayRiskMultiplier = "1.40"
         InpUseDiagnosticFallbackLateSessionGuard = "true"
         InpDiagnosticFallbackLateSessionStartHour = "15"
         InpDiagnosticFallbackLateSessionPureOnly = "true"
         InpDiagnosticFallbackRejectLiquiditySweepSignal = "true"
         InpDiagnosticFallbackLiquidityRejectMaxConfirmations = "1"
      }
   },
   [pscustomobject]@{
      Name = "re_dgf_late16_pure"
      Thesis = "Block pure diagnostic-fallback entries at or after hour 16 while keeping stronger confirmed setups."
      Overrides = @{
         InpUseDiagnosticFallbackLateSessionGuard = "true"
         InpDiagnosticFallbackLateSessionStartHour = "16"
         InpDiagnosticFallbackLateSessionPureOnly = "true"
      }
   },
   [pscustomobject]@{
      Name = "re_dgf_late15_pure"
      Thesis = "Stricter pure diagnostic-fallback late-session guard starting at hour 15."
      Overrides = @{
         InpUseDiagnosticFallbackLateSessionGuard = "true"
         InpDiagnosticFallbackLateSessionStartHour = "15"
         InpDiagnosticFallbackLateSessionPureOnly = "true"
      }
   },
   [pscustomobject]@{
      Name = "re_may140_late16_pure"
      Thesis = "Combine smaller May risk with the hour-16 pure diagnostic-fallback guard."
      Overrides = @{
         InpMayRiskMultiplier = "1.40"
         InpUseDiagnosticFallbackLateSessionGuard = "true"
         InpDiagnosticFallbackLateSessionStartHour = "16"
         InpDiagnosticFallbackLateSessionPureOnly = "true"
      }
   },
   [pscustomobject]@{
      Name = "re_may140_late15_pure"
      Thesis = "Combine smaller May risk with the stricter hour-15 pure diagnostic-fallback guard."
      Overrides = @{
         InpMayRiskMultiplier = "1.40"
         InpUseDiagnosticFallbackLateSessionGuard = "true"
         InpDiagnosticFallbackLateSessionStartHour = "15"
         InpDiagnosticFallbackLateSessionPureOnly = "true"
      }
   }
)

if($CandidateFilter.Count -gt 0) {
   $wanted = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
   foreach($name in $CandidateFilter) {
      foreach($part in ([string]$name -split ',')) {
         if(![string]::IsNullOrWhiteSpace($part)) {
            $wanted.Add($part.Trim()) | Out-Null
         }
      }
   }
   $candidates = @($candidates | Where-Object { $wanted.Contains($_.Name) })
   $selectedCandidateNames = @($candidates | ForEach-Object { $_.Name })
   $missingCandidates = @($wanted | Where-Object { $selectedCandidateNames -notcontains $_ })
   if($missingCandidates.Count -gt 0) {
      throw "CandidateFilter requested unknown candidate(s): $($missingCandidates -join ', ')"
   }
}

$baseSet = Resolve-RepoPath $BaseSetPath
if(!(Test-Path -LiteralPath $baseSet)) {
   throw "Range-elite profile missing: $baseSet"
}

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$sourceInputNames = Get-SourceInputNames -Path $sourcePath
if($sourceInputNames.Count -gt 1000) {
   throw "Current EA source exposes $($sourceInputNames.Count) MT5 tester inputs; keep this under 1000 before building packages."
}
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
   $inputs = Import-SetInputs $baseSet
   Assert-OverridesExposed -Overrides $candidate.Overrides -ExposedInputs $sourceInputNames
   Apply-Overrides -Inputs $inputs -Overrides $candidate.Overrides
   $fixedOverrides = @{
      InpEvidenceProfileId = $candidate.Name
      InpEvidenceSourceHash = $sourceHash
      InpEvidenceRunLabel = "range_elite_risk_shape_probe_m$Model"
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
   Assert-OverridesExposed -Overrides $fixedOverrides -ExposedInputs $sourceInputNames
   Apply-Overrides -Inputs $inputs -Overrides $fixedOverrides
   $removedStaleInputs = @(Remove-StaleInputs -Inputs $inputs -ExposedInputs $sourceInputNames)
   Assert-InputsExposed -Inputs $inputs -ExposedInputs $sourceInputNames

   $setName = "{0}.set" -f $candidate.Name
   $setPath = Join-Path $profileDir $setName
   $setLines = [System.Collections.Generic.List[string]]::new()
   foreach($key in ($inputs.Keys | Sort-Object)) {
      $setLines.Add($inputs[$key]) | Out-Null
   }
   $setLines | Set-Content -LiteralPath $setPath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $setPath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $candidate.Name, $window.Window, $Model
      $reportName = "re_risk_{0}_{1}_m{2}" -f $candidate.Name, $window.Short, $Model
      $configPath = Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model

      $stopRule = "Reject if focused red years stay red, if 2026 drawdown stays excessive, or if 2024 profit engine collapses."
      $queue.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate.Name
         CandidateRank = $rank
         SourceType = "range_elite_risk_shape_probe"
         SourceRank = $rank
         Phase = "phase4_range_elite_risk_shape_model$Model"
         Set = $setName
         Window = $window.Window
         Role = $window.Role
         From = $window.From
         To = $window.To
         Model = $Model
         Config = "configs\$configName"
         ExpectedReportName = $reportName
         ProfileSnapshot = "profiles\$setName"
         ProfileSha256 = $profileHash
         BaseProfileSha256 = $baseProfileHash
         Thesis = $candidate.Thesis
         Overrides = (($candidate.Overrides.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ";")
         StopRule = $stopRule
      }) | Out-Null

      $runRows.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate.Name
         Phase = "phase4_range_elite_risk_shape_model$Model"
         PhaseLabel = "Range-elite risk-shape probe"
         Window = $window.Window
         Role = $window.Role
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
$md.Add("# Range-Elite Risk-Shape Probe Package") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline package builder only. This does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Source hash: ``$sourceHash``") | Out-Null
$md.Add("- Base profile hash: ``$baseProfileHash``") | Out-Null
$md.Add("- Model: ``$Model``") | Out-Null
$md.Add("- Candidates: ``$($candidates.Count)``") | Out-Null
$md.Add("- Windows per candidate: ``$($windows.Count)``") | Out-Null
$md.Add("- Configs: ``$rank``") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Candidate Theses") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Candidate | Thesis | Overrides |") | Out-Null
$md.Add("| --- | --- | --- |") | Out-Null
foreach($candidate in $candidates) {
   $overrideText = (($candidate.Overrides.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; ")
   if([string]::IsNullOrWhiteSpace($overrideText)) { $overrideText = "base" }
   $md.Add(("| `{0}` | {1} | `{2}` |" -f $candidate.Name, $candidate.Thesis, $overrideText)) | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Windows") | Out-Null
$md.Add("") | Out-Null
$md.Add(("``{0}``" -f ($windows.Window -join ', '))) | Out-Null
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
