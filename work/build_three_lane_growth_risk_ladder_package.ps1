param(
   [string]$SourcePath = "work\Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5",
   [string]$BaseProfilePath = "outputs\three_lane_ddb045_model4_validation_package\profiles\three_lane_ddb045.set",
   [string]$PackageDir = "outputs\three_lane_growth_risk_ladder_model1_package",
   [string]$QueueManifestPath = "outputs\THREE_LANE_GROWTH_RISK_LADDER_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\THREE_LANE_GROWTH_RISK_LADDER_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\THREE_LANE_GROWTH_RISK_LADDER_MODEL1_PACKAGE.md",
   [string]$YtdEnd = "2026.07.15"
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

$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$profileFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$expectedSourceHash = "45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90"
if($sourceHash -ne $expectedSourceHash) { throw "Frozen three-lane source changed: $sourceHash" }
$baseProfileHash = (Get-FileHash -LiteralPath $profileFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name = "three_lane_risk050"; Risk = "0.50"; Effective = "0.50"; Open = "0.75" },
   [pscustomobject]@{ Name = "three_lane_risk065"; Risk = "0.65"; Effective = "0.65"; Open = "0.90" },
   [pscustomobject]@{ Name = "three_lane_risk080"; Risk = "0.80"; Effective = "0.80"; Open = "1.05" },
   [pscustomobject]@{ Name = "three_lane_risk100"; Risk = "1.00"; Effective = "1.00"; Open = "1.25" }
)
$windows = @(
   [pscustomobject]@{ Name = "continuous_2015_2026"; From = "2015.01.01"; To = $YtdEnd },
   [pscustomobject]@{ Name = "older_2015_2018"; From = "2015.01.01"; To = "2018.12.31" },
   [pscustomobject]@{ Name = "middle_2019_2022"; From = "2019.01.01"; To = "2022.12.31" },
   [pscustomobject]@{ Name = "recent_2023_2026"; From = "2023.01.01"; To = $YtdEnd }
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
$runRows = [System.Collections.Generic.List[object]]::new()
$profileRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
$stopRule = "Require all broad eras positive, continuous and era PF at least 1.20, drawdown at or below 5%, no activity loss, and smooth neighboring risk behavior."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = Import-SetInputs $profileFull
   Set-InputLine -Inputs $inputs -Name "InpRiskPercent" -Value $variant.Risk
   Set-InputLine -Inputs $inputs -Name "InpMaxEffectiveRiskPercent" -Value $variant.Effective
   Set-InputLine -Inputs $inputs -Name "InpMaxOpenRiskPercent" -Value $variant.Open
   Set-InputLine -Inputs $inputs -Name "InpAccountWideMaxOpenRiskPercent" -Value $variant.Open
   Set-InputLine -Inputs $inputs -Name "InpTradeReadyMaxRiskPercent" -Value $variant.Effective
   Set-InputLine -Inputs $inputs -Name "InpTradeReadyMaxOpenRiskPercent" -Value $variant.Open
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "three_lane_growth_risk_ladder_model1"
   Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "0"
   Set-InputLine -Inputs $inputs -Name "InpUseBlockReasonDiagnostics" -Value "false"
   Set-InputLine -Inputs $inputs -Name "InpShowDashboard" -Value "false"
   Set-InputLine -Inputs $inputs -Name "InpDashboardInTester" -Value "false"
   Set-InputLine -Inputs $inputs -Name "InpAllowedSymbol" -Value "XAUUSD"
   Set-InputLine -Inputs $inputs -Name "InpUseSymbolSafetyLock" -Value "true"
   Set-InputLine -Inputs $inputs -Name "InpUseRealAccountSafetyLock" -Value "true"
   Set-InputLine -Inputs $inputs -Name "InpAllowRealAccountTrading" -Value "false"
   Set-InputLine -Inputs $inputs -Name "InpRealAccountApprovalCode" -Value "DISABLED"
   Set-InputLine -Inputs $inputs -Name "InpRealAccountApprovalProfileId" -Value "DISABLED"
   Set-InputLine -Inputs $inputs -Name "InpRealAccountApprovalSourceHash" -Value "DISABLED"

   $profileName = "$($variant.Name).set"
   $profileOutput = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profileOutput -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profileOutput -Algorithm SHA256).Hash
   $profileRows.Add([pscustomobject]@{ Candidate = $variant.Name; RiskPercent = $variant.Risk; EffectiveCap = $variant.Effective; OpenRiskCap = $variant.Open; ProfileSha256 = $profileHash }) | Out-Null

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $queueRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; CandidateRank = $candidateRank
         SourceType = "three_lane_growth_risk_ladder"; SourceRank = 1; Phase = "broad_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; BaseProfileSha256 = $baseProfileHash; SourceSha256 = $sourceHash
         RiskPercent = $variant.Risk; EffectiveRiskCap = $variant.Effective; OpenRiskCap = $variant.Open; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; Phase = "broad_model1"
         PhaseLabel = "Three-lane growth risk ladder Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Three-Lane Growth Risk Ladder Model 1 Package")
$md.Add("")
$md.Add("Scales only the frozen three-lane base-risk contract and matching exposure caps. Entry, exit, lane allocation, and calendar logic remain unchanged.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Base profile SHA-256: ``$baseProfileHash``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add("| Candidate | Base risk | Effective cap | Open-risk cap | Profile SHA-256 |")
$md.Add("| --- | ---: | ---: | ---: | --- |")
foreach($row in $profileRows) { $md.Add("| ``$($row.Candidate)`` | $($row.RiskPercent)% | $($row.EffectiveCap)% | $($row.OpenRiskCap)% | ``$($row.ProfileSha256)`` |") }
$md.Add("")
$md.Add("Model 1 is a fast scaling screen only. Any survivor still requires yearly and continuous Model 4 real-tick validation and refreshed Monte Carlo stress.")
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{ Status = "READY"; SourceHash = $sourceHash; Variants = $variants.Count; Windows = $windows.Count; Configurations = $rank; PackageDir = $PackageDir }
