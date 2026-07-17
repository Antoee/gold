param(
   [string]$SourcePath = "work\Professional_XAUUSD_Two_Bar_Confirmation_Portfolio.mq5",
   [string]$BaseProfilePath = "outputs\TRANSFERABLE_PORTFOLIO_BASE_PROFILE.set",
   [string]$PackageDir = "outputs\two_bar_confirmation_portfolio_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\TWO_BAR_CONFIRMATION_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\TWO_BAR_CONFIRMATION_PORTFOLIO_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\TWO_BAR_CONFIRMATION_PORTFOLIO_DISCOVERY_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to clear non-outputs directory: $resolved" }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

& (Join-Path $PSScriptRoot "test_two_bar_confirmation_portfolio_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$baseProfileFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseProfilePath)).Path
$baseProfileHash = (Get-FileHash -LiteralPath $baseProfileFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="tbc_fixed_control"; RVEnabled="false"; RVClose="false"; RVProgress="false"; MOEnabled="false"; MOProgress="false" },
   [pscustomobject]@{ Name="tbc_rv_wick"; RVEnabled="true"; RVClose="false"; RVProgress="true"; MOEnabled="false"; MOProgress="false" },
   [pscustomobject]@{ Name="tbc_rv_close"; RVEnabled="true"; RVClose="true"; RVProgress="true"; MOEnabled="false"; MOProgress="false" },
   [pscustomobject]@{ Name="tbc_mo_hold"; RVEnabled="false"; RVClose="false"; RVProgress="false"; MOEnabled="true"; MOProgress="false" },
   [pscustomobject]@{ Name="tbc_mo_progress"; RVEnabled="false"; RVClose="false"; RVProgress="false"; MOEnabled="true"; MOProgress="true" },
   [pscustomobject]@{ Name="tbc_both_wick_hold"; RVEnabled="true"; RVClose="false"; RVProgress="true"; MOEnabled="true"; MOProgress="false" },
   [pscustomobject]@{ Name="tbc_both_close_hold"; RVEnabled="true"; RVClose="true"; RVProgress="true"; MOEnabled="true"; MOProgress="false" },
   [pscustomobject]@{ Name="tbc_both_wick_progress"; RVEnabled="true"; RVClose="false"; RVProgress="true"; MOEnabled="true"; MOProgress="true" }
)
$windows = @(
   [pscustomobject]@{ Name="older_2015_2018"; From="2015.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="discovery_2019_2020"; From="2019.01.01"; To="2020.12.31" },
   [pscustomobject]@{ Name="continuous_2015_2020"; From="2015.01.01"; To="2020.12.31" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"; $profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"; $sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new(); $runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0; $candidateRank = 0
$stopRule = "Discovery only: both eras positive; continuous PF >= 1.45, trades >= 180, DD <= 2.80%; at least 5% control-relative net or return/DD improvement under frozen quality tolerances; one adjacent confirmation profile must pass."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = Import-SetInputs -Path $baseProfileFull
   foreach($pair in @(
      @("InpPortfolioMagic","26071784"), @("InpRVMagicNumber","26071725"), @("InpMOMagicNumber","26071765"),
      @("InpRVUseTwoBarReclaimConfirmation",$variant.RVEnabled),
      @("InpRVRequirePriorCloseOutsideBand",$variant.RVClose), @("InpRVRequireConfirmationProgress",$variant.RVProgress),
      @("InpMOUseTwoCloseBreakoutConfirmation",$variant.MOEnabled),
      @("InpMORequireConfirmationProgress",$variant.MOProgress),
      @("InpEvidenceSourceHash",$sourceHash), @("InpEvidenceRunLabel","two_bar_confirmation_portfolio_discovery_model1"),
      @("InpShowDashboard","false")
   )) { Set-InputLine -Inputs $inputs -Name $pair[0] -Value $pair[1] }
   $inputs["InpRVLogFileName"] = "InpRVLogFileName=$($variant.Name)_rv_events.csv"
   $inputs["InpMOLogFileName"] = "InpMOLogFileName=$($variant.Name)_mo_events.csv"
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 60
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="two_bar_confirmation_portfolio"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; BaseProfileSha256=$baseProfileHash; SignalTimeframe="60"
         RVConfirmationEnabled=$variant.RVEnabled; RVRequirePriorCloseOutside=$variant.RVClose
         RVRequireProgress=$variant.RVProgress; MOConfirmationEnabled=$variant.MOEnabled
         MORequireProgress=$variant.MOProgress; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Two-bar confirmation portfolio discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Two-Bar Confirmation Portfolio Discovery Package", "",
   "Released risk, stops, targets, and position management with separately testable closed-bar reversion-reclaim and breakout-hold confirmations. No configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Released base-profile SHA-256: ``$baseProfileHash``",
   "- Variants: ``$($variants.Count)``", "- Configurations: ``$rank``", "",
   "Frozen gate: $stopRule"
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; BaseProfileHash=$baseProfileHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
