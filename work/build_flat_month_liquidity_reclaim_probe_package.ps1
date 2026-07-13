param(
   [string]$PackageDir = "outputs\flat_month_liquidity_reclaim_probe_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set",
   [string]$ConservativeSetPath = "outputs\CANDIDATE_FMLR_CONSERVATIVE_PROFILE.set",
   [string]$BalancedSetPath = "outputs\CANDIDATE_FMLR_BALANCED_PROFILE.set",
   [string]$VwapDiscoverySetPath = "outputs\CANDIDATE_FMLR_VWAP_DISCOVERY_PROFILE.set",
   [int]$Model = 4,
   [string[]]$ProfileNames = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
   return [IO.Path]::GetFullPath((Join-Path $repo $Path))
}

function Assert-UnderRepo {
   param([string]$Path, [string]$Label)
   $fullPath = Resolve-RepoPath $Path
   $root = [IO.Path]::GetFullPath($repo).TrimEnd('\') + '\'
   if(!$fullPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and
      !$fullPath.Equals($root.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
      throw "$Label path is outside repo. Path=$fullPath Root=$root"
   }
}

function Format-Invariant {
   param([double]$Value, [string]$Pattern = "0.00")
   return [string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:$Pattern}", $Value)
}

function Set-ProbeInput {
   param($Inputs, [string]$Name, [object]$Value)
   Set-InputLine -Inputs $Inputs -Name $Name -Value ([string]$Value)
}

function Write-FmlrCandidateSet {
   param(
      [string]$Path,
      [double]$RiskMultiplier,
      [int]$MaxMonthlyEntries,
      [int]$SpacingMinutes,
      [int]$MinScore,
      [bool]$RequireOrderFlow,
      [bool]$RequireVwapReclaim,
      [double]$MaxVwapDistanceAtr,
      [int]$LookbackBars,
      [double]$MinWickPercent,
      [double]$MinCloseLocation,
      [double]$StopBufferAtr,
      [double]$StopBufferPoints,
      [double]$TakeProfitAtr,
      [double]$MinRr,
      [int]$BypassQualityScore,
      [bool]$UsePreviousWeek
   )

   Assert-UnderRepo -Path $Path -Label "Candidate set"
   $inputs = Import-SetInputs $BaseSetPath
   Set-ProbeInput $inputs "InpUseFlatMonthLiquidityReclaimLane" "true"
   Set-ProbeInput $inputs "InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter" "true"
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimBypassMinQualityScore" $BypassQualityScore
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimBypassMinPriceActionScore" "0"
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimBypassRequireLiquidSession" "true"
   Set-ProbeInput $inputs "InpUseFlatMonthOpportunityMode" "true"
   Set-ProbeInput $inputs "InpFlatMonthOpportunityOnlyOutsideMonthFilter" "true"
   Set-ProbeInput $inputs "InpFlatMonthRequireNoMonthlyLoss" "true"
   Set-ProbeInput $inputs "InpFlatMonthMaxEntryCount" "5"
   Set-ProbeInput $inputs "InpUseAdaptiveReverse" "false"
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimRiskMultiplier" (Format-Invariant $RiskMultiplier)
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimMaxMonthlyEntries" $MaxMonthlyEntries
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimSpacingMinutes" $SpacingMinutes
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimMinScore" $MinScore
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimRequireLiquidSession" "true"
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimRequireOrderFlow" $RequireOrderFlow.ToString().ToLowerInvariant()
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimRequireVWAPReclaim" $RequireVwapReclaim.ToString().ToLowerInvariant()
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimMaxVWAPDistanceATR" (Format-Invariant $MaxVwapDistanceAtr)
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimLookbackBars" $LookbackBars
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimMinWickPercent" (Format-Invariant $MinWickPercent "0.0")
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimMinCloseLocation" (Format-Invariant $MinCloseLocation)
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimStopBufferATR" (Format-Invariant $StopBufferAtr)
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimStopBufferPoints" (Format-Invariant $StopBufferPoints "0.0")
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimTakeProfitATR" (Format-Invariant $TakeProfitAtr)
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimMinRR" (Format-Invariant $MinRr)
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimUseEqualLevels" "true"
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimUsePreviousDay" "true"
   Set-ProbeInput $inputs "InpFlatMonthLiquidityReclaimUsePreviousWeek" $UsePreviousWeek.ToString().ToLowerInvariant()

   New-Item -ItemType Directory -Path (Split-Path -Parent (Resolve-RepoPath $Path)) -Force | Out-Null
   ($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath (Resolve-RepoPath $Path) -Encoding ASCII
}

Write-FmlrCandidateSet `
   -Path $ConservativeSetPath `
   -RiskMultiplier 0.16 `
   -MaxMonthlyEntries 3 `
   -SpacingMinutes 480 `
   -MinScore 7 `
   -RequireOrderFlow $true `
   -RequireVwapReclaim $true `
   -MaxVwapDistanceAtr 0.95 `
   -LookbackBars 20 `
   -MinWickPercent 38.0 `
   -MinCloseLocation 0.64 `
   -StopBufferAtr 0.16 `
   -StopBufferPoints 35.0 `
   -TakeProfitAtr 1.25 `
   -MinRr 0.95 `
   -BypassQualityScore 8 `
   -UsePreviousWeek $false

Write-FmlrCandidateSet `
   -Path $BalancedSetPath `
   -RiskMultiplier 0.20 `
   -MaxMonthlyEntries 4 `
   -SpacingMinutes 360 `
   -MinScore 6 `
   -RequireOrderFlow $true `
   -RequireVwapReclaim $false `
   -MaxVwapDistanceAtr 1.25 `
   -LookbackBars 18 `
   -MinWickPercent 32.0 `
   -MinCloseLocation 0.58 `
   -StopBufferAtr 0.14 `
   -StopBufferPoints 30.0 `
   -TakeProfitAtr 1.20 `
   -MinRr 0.90 `
   -BypassQualityScore 7 `
   -UsePreviousWeek $false

Write-FmlrCandidateSet `
   -Path $VwapDiscoverySetPath `
   -RiskMultiplier 0.12 `
   -MaxMonthlyEntries 3 `
   -SpacingMinutes 480 `
   -MinScore 6 `
   -RequireOrderFlow $false `
   -RequireVwapReclaim $true `
   -MaxVwapDistanceAtr 1.10 `
   -LookbackBars 16 `
   -MinWickPercent 30.0 `
   -MinCloseLocation 0.56 `
   -StopBufferAtr 0.12 `
   -StopBufferPoints 25.0 `
   -TakeProfitAtr 1.05 `
   -MinRr 0.85 `
   -BypassQualityScore 7 `
   -UsePreviousWeek $false

$profiles = @(
   [pscustomobject]@{ Name = "lowatr_current"; SetPath = $BaseSetPath },
   [pscustomobject]@{ Name = "fmlr_conservative"; SetPath = $ConservativeSetPath },
   [pscustomobject]@{ Name = "fmlr_balanced"; SetPath = $BalancedSetPath },
   [pscustomobject]@{ Name = "fmlr_vwap_discovery"; SetPath = $VwapDiscoverySetPath }
)

if($ProfileNames.Count -gt 0) {
   $wanted = @{}
   foreach($name in $ProfileNames) { $wanted[$name] = $true }
   $profiles = @($profiles | Where-Object { $wanted.ContainsKey($_.Name) })
   if($profiles.Count -le 0) { throw "No matching profiles selected: $($ProfileNames -join ', ')" }
}

$windows = @(
   [pscustomobject]@{ Window = "2024_01"; Phase = "flat"; Set = "zero_trade"; From = "2024.01.01"; To = "2024.01.31" },
   [pscustomobject]@{ Window = "2024_02"; Phase = "flat"; Set = "zero_trade"; From = "2024.02.01"; To = "2024.02.29" },
   [pscustomobject]@{ Window = "2024_04"; Phase = "flat"; Set = "zero_trade"; From = "2024.04.01"; To = "2024.04.30" },
   [pscustomobject]@{ Window = "2024_05"; Phase = "guard"; Set = "active_control"; From = "2024.05.01"; To = "2024.05.31" },
   [pscustomobject]@{ Window = "2024_09"; Phase = "flat"; Set = "zero_trade"; From = "2024.09.01"; To = "2024.09.30" },
   [pscustomobject]@{ Window = "2024_10"; Phase = "guard"; Set = "blocked_loss"; From = "2024.10.01"; To = "2024.10.31" },
   [pscustomobject]@{ Window = "2025_01"; Phase = "flat"; Set = "zero_trade"; From = "2025.01.01"; To = "2025.01.31" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "flat"; Set = "zero_trade"; From = "2025.04.01"; To = "2025.04.30" },
   [pscustomobject]@{ Window = "2025_06"; Phase = "flat"; Set = "zero_trade"; From = "2025.06.01"; To = "2025.06.30" },
   [pscustomobject]@{ Window = "2026_01"; Phase = "flat"; Set = "zero_trade"; From = "2026.01.01"; To = "2026.01.31" },
   [pscustomobject]@{ Window = "2026_05"; Phase = "guard"; Set = "active_control"; From = "2026.05.01"; To = "2026.05.31" },
   [pscustomobject]@{ Window = "2026_06"; Phase = "active"; Set = "profit_control"; From = "2026.06.01"; To = "2026.06.30" }
)

Assert-UnderRepo -Path $PackageDir -Label "Package"
$resolvedPackageDir = Resolve-RepoPath $PackageDir
if(Test-Path -LiteralPath $resolvedPackageDir) { Remove-Item -LiteralPath $resolvedPackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $resolvedPackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $resolvedPackageDir "reports_here") -Force | Out-Null

$expected = New-Object System.Collections.Generic.List[object]
$rank = 0
foreach($profile in $profiles) {
   foreach($window in $windows) {
      $rank++
      $inputs = Import-SetInputs $profile.SetPath
      Set-InputLine -Inputs $inputs -Name "InpAllowedSymbol" -Value "XAUUSD"
      Set-InputLine -Inputs $inputs -Name "InpSignalTimeframe" -Value "15"
      Set-InputLine -Inputs $inputs -Name "InpShowDashboard" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpDashboardInTester" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "0"

      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "flat_month_liquidity_reclaim_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $resolvedPackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model

      $expected.Add([pscustomobject]@{
         Rank = $rank
         Profile = $profile.Name
         Phase = $window.Phase
         Set = $window.Set
         Window = $window.Window
         From = $window.From
         To = $window.To
         Config = "configs\$configName"
         ExpectedReportName = $reportName
         Model = $Model
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $resolvedPackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath (Resolve-RepoPath "outputs\FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_MANIFEST.csv") -NoTypeInformation
"Built $rank flat-month liquidity-reclaim probe configs in $PackageDir"
