param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Weekend_Gap_Fade.mq5",
   [string]$PackageDir = "outputs\independent_m15_weekend_gap_fade_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-outputs directory: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function New-BaseInputs {
   $inputs = [ordered]@{}
   $defaults = [ordered]@{
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071751"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpEnforceInitialBalanceContract = "true"; InpExpectedInitialBalance = "10000.0"; InpInitialBalanceTolerance = "1.0"
      InpEnforceAccountCurrency = "true"; InpSignalTimeframe = "15"; InpATRTimeframe = "16408"; InpATRPeriod = "14"
      InpMinimumGapATR = "0.08"; InpMaximumGapATR = "0.50"; InpMinimumGapPoints = "50.0"
      InpMinimumConfirmationFraction = "0.15"; InpMaximumConfirmationFraction = "0.80"
      InpRequireDirectionalFirstBar = "true"; InpAllowBuy = "true"; InpAllowSell = "true"
      InpStopBufferATR = "0.03"; InpMaximumStopATR = "0.35"; InpMinimumRewardRisk = "1.15"
      InpMaximumHoldBars = "48"; InpUseBreakEven = "true"; InpBreakEvenTriggerR = "0.75"; InpBreakEvenLockR = "0.00"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumDailyLossPercent = "0.75"
      InpMaximumEquityDrawdownPercent = "5.00"; InpMaximumConsecutiveLosses = "3"; InpLossCooldownHours = "168"
      InpMaximumSpreadPoints = "100.0"; InpMaximumSpreadGapPercent = "15.0"; InpDeviationPoints = "20"
      InpRequireEmptyAccountAtEntry = "true"; InpAccountWideMaxOpenRiskPercent = "1.00"
      InpAccountWideBlockUnprotectedExposure = "true"; InpLogTrades = "false"
      InpLogFileName = "Independent_XAUUSD_M15_Weekend_Gap_Fade_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) {
      Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
   $inputs["InpExpectedAccountCurrency"] = "InpExpectedAccountCurrency=USD"
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_weekend_gap_fade_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name = "wgf_center"; MinGap = "0.08"; MaxGap = "0.50"; MinConfirm = "0.15" },
   [pscustomobject]@{ Name = "wgf_gap005"; MinGap = "0.05"; MaxGap = "0.50"; MinConfirm = "0.15" },
   [pscustomobject]@{ Name = "wgf_gap012"; MinGap = "0.12"; MaxGap = "0.50"; MinConfirm = "0.15" },
   [pscustomobject]@{ Name = "wgf_confirm000"; MinGap = "0.08"; MaxGap = "0.50"; MinConfirm = "0.00" },
   [pscustomobject]@{ Name = "wgf_confirm030"; MinGap = "0.08"; MaxGap = "0.50"; MinConfirm = "0.30" },
   [pscustomobject]@{ Name = "wgf_maxgap035"; MinGap = "0.08"; MaxGap = "0.35"; MinConfirm = "0.15" },
   [pscustomobject]@{ Name = "wgf_maxgap065"; MinGap = "0.08"; MaxGap = "0.65"; MinConfirm = "0.15" }
)

$windows = @(
   [pscustomobject]@{ Name = "older_2015_2018"; From = "2015.01.01"; To = "2018.12.31" },
   [pscustomobject]@{ Name = "repair_2019_2020"; From = "2019.01.01"; To = "2020.12.31" },
   [pscustomobject]@{ Name = "continuous_2015_2020"; From = "2015.01.01"; To = "2020.12.31" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new()
$manifestRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
$runLabel = "independent_m15_weekend_gap_fade_discovery_model1"
$stopRule = "Pre-2021 only: both disjoint eras positive, continuous PF >=1.20, trades >=40, DD <=2.50%, positive payoff, return/DD >=1.00, and one adjacent passing profile."

foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine -Inputs $inputs -Name "InpMinimumGapATR" -Value $variant.MinGap
   Set-InputLine -Inputs $inputs -Name "InpMaximumGapATR" -Value $variant.MaxGap
   Set-InputLine -Inputs $inputs -Name "InpMinimumConfirmationFraction" -Value $variant.MinConfirm
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value $runLabel
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value "$($variant.Name)_trades.csv"

   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15

      $queueRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; CandidateRank = $candidateRank
         SourceType = "independent_m15_weekend_gap_fade"; Phase = "discovery_model1"
         Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; RunLabel = $runLabel
         MinimumGapATR = $variant.MinGap; MaximumGapATR = $variant.MaxGap
         MinimumConfirmationFraction = $variant.MinConfirm; StopRule = $stopRule
      }) | Out-Null

      $manifestRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; Phase = "discovery_model1"; Window = $window.Name
         Model = 1; Deposit = 10000; PackageConfig = "$PackageDir\configs\$configName"
         ReportDestination = "$PackageDir\reports_here\$reportName"; ExpectedReportName = $reportName
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; RunLabel = $runLabel; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$manifestRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 Weekend-Gap Fade Discovery Package")
$md.Add("")
$md.Add("Frozen standalone research family. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$rank``")
$md.Add("- Risk per trade: ``0.10%``")
$md.Add("- Real-account trading default: ``false``")
$md.Add("")
$md.Add("The package is a fast rejection screen. Passing Model 1 is permission to test exact survivors on holdout data, not evidence of money readiness.")
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status = "READY"
   SourceHash = $sourceHash
   Variants = $variants.Count
   Windows = $windows.Count
   Configurations = $rank
   PackageDir = $PackageDir
}
