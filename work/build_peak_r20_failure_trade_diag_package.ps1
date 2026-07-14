param(
   [string]$BaseSetPath = "outputs\peak_r20_oos_yearly_package\profiles\r10_profit_guard40.set",
   [string]$OutDir = "outputs\peak_r20_failure_trade_diag_package",
   [string]$OutQueueManifest = "outputs\PEAK_R20_FAILURE_TRADE_DIAG_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\PEAK_R20_FAILURE_TRADE_DIAG_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\PEAK_R20_FAILURE_TRADE_DIAG_PACKAGE.md",
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
   [pscustomobject]@{ Window = "2021_full"; From = "2021.01.01"; To = "2021.12.31" },
   [pscustomobject]@{ Window = "2022_full"; From = "2022.01.01"; To = "2022.12.31" },
   [pscustomobject]@{ Window = "2023_full"; From = "2023.01.01"; To = "2023.12.31" },
   [pscustomobject]@{ Window = "2024_full"; From = "2024.01.01"; To = "2024.12.31" }
)

$baseSet = Resolve-RepoPath $BaseSetPath
if(!(Test-Path -LiteralPath $baseSet)) {
   throw "Base diagnostic profile missing: $baseSet"
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
foreach($window in $windows) {
   $rank++
   $inputs = Import-SetInputs $baseSet
   $candidate = "r10_profit_guard40_diag"
   $profileId = "{0}_{1}" -f $candidate, $window.Window
   $tradeLogName = "PXEA_R10PG40_{0}_trades.csv" -f $window.Window
   $runLabel = "peak_r20_failure_diag_{0}_m{1}" -f $window.Window, $Model

   Apply-Overrides -Inputs $inputs -Overrides @{
      InpEvidenceProfileId = $profileId
      InpEvidenceSourceHash = $sourceHash
      InpEvidenceRunLabel = $runLabel
      InpLogLevel = "2"
      InpLogFileName = $tradeLogName
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

   $setName = "{0}_{1}.set" -f $candidate, $window.Window
   $setPath = Join-Path $profileDir $setName
   $setLines = [System.Collections.Generic.List[string]]::new()
   foreach($key in ($inputs.Keys | Sort-Object)) {
      $setLines.Add($inputs[$key]) | Out-Null
   }
   $setLines | Set-Content -LiteralPath $setPath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $setPath -Algorithm SHA256).Hash

   $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $candidate, $window.Window, $Model
   $reportName = "peak_r20_failure_diag_{0}_m{1}" -f $window.Window, $Model
   $configPath = Join-Path $configDir $configName
   Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model

   $stopRule = "Diagnostic only. Use trade logs to identify losing years, not to promote a profile."
   $queue.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $candidate
      CandidateRank = $rank
      SourceType = "peak_r20_failure_trade_diag"
      SourceRank = $rank
      Phase = "phase3_failure_trade_diag_model$Model"
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
      TradeLogFile = $tradeLogName
      StopRule = $stopRule
      Purpose = "Trade-level diagnostic for r10_profit_guard40 older-year failures."
   }) | Out-Null

   $runRows.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $candidate
      Phase = "phase3_failure_trade_diag_model$Model"
      PhaseLabel = "Peak R20 R10 failure trade diagnostics"
      Window = $window.Window
      Model = $Model
      PackageConfig = "$OutDir\configs\$configName"
      SourceConfig = "$OutDir\configs\$configName"
      ExpectedReportName = $reportName
      ReportDestination = "$OutDir\reports_here\$reportName"
      ProfileSha256 = $profileHash
      TradeLogFile = $tradeLogName
      StopRule = $stopRule
   }) | Out-Null
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
$md.Add("# Peak R20 Failure Trade Diagnostic Package") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline package builder only. This does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Source hash: ``$sourceHash``") | Out-Null
$md.Add("- Base profile hash: ``$baseProfileHash``") | Out-Null
$md.Add("- Model: ``$Model``") | Out-Null
$md.Add("- Configs: ``$rank``") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Diagnostic Windows") | Out-Null
$md.Add("") | Out-Null
foreach($window in $windows) {
   $md.Add("- ``$($window.Window)``: ``$($window.From)`` to ``$($window.To)``") | Out-Null
}
$md.Add("") | Out-Null
$md.Add("Trade logs are written through MT5 common files using names like ``PXEA_R10PG40_2019_full_trades.csv``.") | Out-Null
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   BaseProfileHash = $baseProfileHash
   Configs = $rank
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   PackageDir = $OutDir
}
