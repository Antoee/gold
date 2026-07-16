param(
   [string]$PackageDir = "outputs\money_ready_broker_proxy_package",
   [string]$ReportRoot = "",
   [string]$ProfilePath = "outputs\CANDIDATE_MONEY_READY_PROFILE.set",
   [string]$SourcePath = "outputs\Professional_XAUUSD_EA.mq5",
   [string]$OutManifest = "outputs\MONEY_READY_BROKER_PROXY_MANIFEST.csv",
   [string]$ProfileName = "money_ready",
   [string]$ProfileDisplayName = "Money-Ready",
   [string]$BrokerProfilePrefix = "",
   [string]$ManifestFileName = "MONEY_READY_BROKER_PROXY_MANIFEST.csv",
   [string]$ReadmeFileName = "README_MONEY_READY_BROKER_PROXY.md",
   [string]$ExpectedReportPrefix = "money_ready_broker_proxy",
   [ValidateSet("recent","broad")][string]$WindowPreset = "recent",
   [ValidateRange(100,100000000)][int]$InitialDeposit = 1000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedPackageDir = Join-Path $repo $PackageDir
$resolvedOutputsDir = Join-Path $repo "outputs"
$resolvedProfilePath = Join-Path $repo $ProfilePath
$resolvedSourcePath = Join-Path $repo $SourcePath
$resolvedOutManifest = Join-Path $repo $OutManifest

if(!(Test-Path -LiteralPath $resolvedProfilePath)) {
   throw "Missing validation profile: $resolvedProfilePath"
}
if(!(Test-Path -LiteralPath $resolvedSourcePath)) {
   throw "Missing EA source: $resolvedSourcePath"
}

if([string]::IsNullOrWhiteSpace($ReportRoot)) {
   $ReportRoot = Join-Path $PackageDir "reports_here"
}
$resolvedReportRoot = Join-Path $repo $ReportRoot

if(Test-Path -LiteralPath $resolvedPackageDir) {
   $actualPackageDir = (Resolve-Path -LiteralPath $resolvedPackageDir).Path
   $actualOutputsDir = (Resolve-Path -LiteralPath $resolvedOutputsDir).Path
   if(!$actualPackageDir.StartsWith($actualOutputsDir, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to clean package outside outputs: $actualPackageDir"
   }
   Remove-Item -LiteralPath $actualPackageDir -Recurse -Force
}

New-Item -ItemType Directory -Path (Join-Path $resolvedPackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $resolvedPackageDir "profiles") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $resolvedPackageDir "source") -Force | Out-Null
New-Item -ItemType Directory -Path $resolvedReportRoot -Force | Out-Null

Copy-Item -LiteralPath $resolvedSourcePath -Destination (Join-Path $resolvedPackageDir "source\Professional_XAUUSD_EA.mq5") -Force

function Add-ProfileOverrides {
   param($Inputs, [hashtable]$Overrides)
   foreach($entry in $Overrides.GetEnumerator()) {
      Set-InputLine -Inputs $Inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
}

function Format-BrokerProfileName {
   param([string]$BaseName)
   if([string]::IsNullOrWhiteSpace($BrokerProfilePrefix)) {
      return $BaseName
   }
   return "{0}_{1}" -f $BrokerProfilePrefix, $BaseName
}

$windows = if($WindowPreset -eq "broad") {
   @([pscustomobject]@{ Window = "continuous_2019_2026"; Set = "broad"; From = "2019.01.01"; To = "2026.07.12" })
}
else {
   @(
      [pscustomobject]@{ Window = "continuous_2024_2026"; Set = "full"; From = "2024.01.01"; To = "2026.07.12" },
      [pscustomobject]@{ Window = "2026_ytd"; Set = "recent"; From = "2026.01.01"; To = "2026.07.12" }
   )
}

$profiles = @(
   [pscustomobject]@{
      Name = (Format-BrokerProfileName "broker_proxy_base")
      BrokerProxy = "Current safety-gated $ProfileDisplayName settings"
      Overrides = @{}
   },
   [pscustomobject]@{
      Name = (Format-BrokerProfileName "broker_proxy_wide_spread")
      BrokerProxy = "Wider/less stable spread environment; stricter spread acceptance and RR"
      Overrides = @{
         InpMaxSpreadPoints = "160"
         InpMaxSpreadATRPercent = "8.0"
         InpMaxSpreadRegimeRatio = "1.10"
         InpM1SpreadShockMaxRatio = "1.35"
         InpMinSpreadAdjustedRR = "1.45"
         InpSpreadRiskStartPoints = "75.0"
         InpMinSpreadRiskMultiplier = "0.35"
      }
   },
   [pscustomobject]@{
      Name = (Format-BrokerProfileName "broker_proxy_high_commission")
      BrokerProxy = "Commission-heavy XAUUSD account proxy"
      Overrides = @{
         InpEstimatedRoundTurnCommissionPerLot = "10.00"
         InpMaxTradingCostRiskPercent = "5.0"
         InpMinSpreadAdjustedRR = "1.45"
      }
   },
   [pscustomobject]@{
      Name = (Format-BrokerProfileName "broker_proxy_tight_slippage")
      BrokerProxy = "Low slippage tolerance / strict execution proxy"
      Overrides = @{
         InpDeviationPoints = "10"
         InpMaxSpreadPoints = "180"
         InpMaxSpreadATRPercent = "9.0"
         InpMinSpreadAdjustedRR = "1.40"
      }
   },
   [pscustomobject]@{
      Name = (Format-BrokerProfileName "broker_proxy_margin_pressure")
      BrokerProxy = "Lower leverage / higher margin-pressure proxy"
      Overrides = @{
         InpMinMarginLevelPercent = "800.0"
         InpMarginPressureStartLevelPercent = "1100.0"
         InpMaxTradeMarginFreePercent = "6.0"
         InpTradeMarginRiskStartFraction = "0.25"
         InpMinTradeMarginRiskMultiplier = "0.35"
      }
   }
)

$expected = [System.Collections.Generic.List[object]]::new()
$profileHashes = [System.Collections.Generic.List[object]]::new()
$rank = 0
$profileRank = 0

foreach($profile in $profiles) {
   $profileRank++
   $snapshotName = "$($profile.Name).set"
   $snapshotPath = Join-Path $resolvedPackageDir "profiles\$snapshotName"
   $snapshotInputs = Import-SetInputs $resolvedProfilePath
   Add-ProfileOverrides -Inputs $snapshotInputs -Overrides $profile.Overrides
   $snapshotInputs.Keys | Sort-Object | ForEach-Object { $snapshotInputs[$_] } | Set-Content -LiteralPath $snapshotPath -Encoding ASCII
   $snapshotHash = (Get-FileHash -LiteralPath $snapshotPath -Algorithm SHA256).Hash
   $profileHashes.Add([pscustomobject]@{
      Profile = $profile.Name
      Snapshot = "profiles\$snapshotName"
      Sha256 = $snapshotHash
      BrokerProxy = $profile.BrokerProxy
   }) | Out-Null

   foreach($window in $windows) {
      $rank++
      $inputs = Import-SetInputs $snapshotPath
      Set-InputLine -Inputs $inputs -Name "InpAllowedSymbol" -Value "XAUUSD"
      Set-InputLine -Inputs $inputs -Name "InpSignalTimeframe" -Value "15"
      Set-InputLine -Inputs $inputs -Name "InpShowDashboard" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpDashboardInTester" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "0"

      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "{0}_{1}_{2}" -f $ExpectedReportPrefix, $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $resolvedPackageDir "configs\$configName") -ReportRoot $resolvedReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 4 -Deposit $InitialDeposit

      $expected.Add([pscustomobject]@{
         Rank = $rank
         QueueRank = $rank
         Candidate = $profile.Name
         CandidateRank = $profileRank
         SourceType = "broker_proxy"
         SourceRank = 1
         Profile = $profile.Name
         Phase = "phase5_broker_proxy_realtick"
         Set = $window.Set
         Window = $window.Window
         From = $window.From
         To = $window.To
         Config = "configs\$configName"
         PackageConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName
         ReportDestination = "$PackageDir\reports_here\$reportName"
         Model = 4
         Deposit = $InitialDeposit
         InitialDeposit = $InitialDeposit
         ProfileSnapshot = "profiles\$snapshotName"
         ProfileSha256 = $snapshotHash
         BrokerProxy = $profile.BrokerProxy
         StopRule = "Reject if the base profile loses or if execution-proxy profiles reveal material sensitivity to spread, commission, slippage tolerance, or margin pressure."
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $resolvedPackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath (Join-Path $resolvedPackageDir $ManifestFileName) -NoTypeInformation
$expected | Export-Csv -LiteralPath $resolvedOutManifest -NoTypeInformation
$profileHashes | Export-Csv -LiteralPath (Join-Path $resolvedPackageDir "PROFILE_HASHES.csv") -NoTypeInformation

$sourceHash = (Get-FileHash -LiteralPath (Join-Path $resolvedPackageDir "source\Professional_XAUUSD_EA.mq5") -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $resolvedProfilePath -Algorithm SHA256).Hash
$readme = @(
   "# $ProfileDisplayName Broker Proxy Package",
   "",
   "Offline package only. This does not launch MT5.",
   "",
   "- EA source hash: ``$sourceHash``",
   "- Base profile hash: ``$profileHash``",
   "- Configs: ``$rank``",
   "- Initial deposit: ``$InitialDeposit`` USD",
   "",
   "## Purpose",
   "",
   "These configs approximate broker variation by tightening spread, commission, slippage, and margin assumptions through EA inputs. They do not replace testing on another broker's actual XAUUSD contract specification.",
   "",
   "## Profiles",
   "",
   "- ``$(Format-BrokerProfileName "broker_proxy_base")``",
   "- ``$(Format-BrokerProfileName "broker_proxy_wide_spread")``",
   "- ``$(Format-BrokerProfileName "broker_proxy_high_commission")``",
   "- ``$(Format-BrokerProfileName "broker_proxy_tight_slippage")``",
   "- ``$(Format-BrokerProfileName "broker_proxy_margin_pressure")``"
)
$readme | Set-Content -LiteralPath (Join-Path $resolvedPackageDir $ReadmeFileName) -Encoding ASCII

"Built $rank $ProfileDisplayName broker-proxy configs in $PackageDir"
