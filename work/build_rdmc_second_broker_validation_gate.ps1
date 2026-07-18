[CmdletBinding()]
param(
   [string]$PackageDir = "outputs\rdmc_second_broker_validation_package",
   [string]$ManifestPath = "outputs\RDMC_SECOND_BROKER_VALIDATION_MANIFEST.csv",
   [string]$SpecificationTemplatePath = "outputs\RDMC_SECOND_BROKER_SPECIFICATION_TEMPLATE.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$baseManifestPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv"
$basePackage = Join-Path $repo "outputs\rdmc_diversified_repair_executable_gate_package"
$sourcePath = Join-Path $basePackage "source\Professional_XAUUSD_EA.mq5"
$profilePath = Join-Path $basePackage "profiles\rdmc_diversified_repair_restart_safe_v2.set"
$repoLock = Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"
$outerLock = Join-Path (Split-Path -Parent $repo) "MT5_LOCAL_LAUNCH_DISABLED.lock"

$expectedBaseManifestHash = "4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A"
$expectedSourceHash = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
$expectedProfileHash = "746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883"
$primaryCompanyFingerprint = "C9D9B521F3325D6CE4996576CD61C7AA3E860A08B84DC47540C2B30E98924092"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
   return [IO.Path]::GetFullPath((Join-Path $repo $Path))
}

function Relative-RepoPath([string]$Path) {
   $full = [IO.Path]::GetFullPath($Path)
   if(!$full.StartsWith($repo + "\", [StringComparison]::OrdinalIgnoreCase)) {
      throw "Generated path is outside the repository: $full"
   }
   return $full.Substring($repo.Length + 1)
}

function Ensure-Directory([string]$Path) {
   if(!(Test-Path -LiteralPath $Path -PathType Container)) {
      New-Item -ItemType Directory -Path $Path -Force | Out-Null
   }
}

function Get-Sha256([string]$Path) {
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

foreach($required in @($baseManifestPath,$sourcePath,$profilePath,$repoLock,$outerLock)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required frozen artifact or launch lock is missing: $required" }
}
if((Get-Sha256 $baseManifestPath) -ne $expectedBaseManifestHash -or
   (Get-Sha256 $sourcePath) -ne $expectedSourceHash -or
   (Get-Sha256 $profilePath) -ne $expectedProfileHash) {
   throw "Frozen executable source, profile, or manifest identity changed."
}

$packageFull = Resolve-RepoPath $PackageDir
$manifestFull = Resolve-RepoPath $ManifestPath
$templateFull = Resolve-RepoPath $SpecificationTemplatePath
$reportsDir = Join-Path $packageFull "reports_here"
foreach($directory in @($packageFull,$reportsDir)) { Ensure-Directory $directory }

$baseRows = @(Import-Csv -LiteralPath $baseManifestPath | Where-Object Model -eq "4" | Sort-Object { [int]$_.QueueRank })
if($baseRows.Count -ne 18) { throw "Expected exactly 18 frozen Model4 rows." }
$manifest = [System.Collections.Generic.List[object]]::new()

for($index = 0; $index -lt $baseRows.Count; $index++) {
   $base = $baseRows[$index]
   $rank = $index + 1
   $wave = if([int]$base.QueueRank -le 8) { 1 } elseif([int]$base.QueueRank -le 12) { 2 } else { 3 }
   $phase = "wave_{0:D2}_m4_{1}" -f $wave,$base.Role
   $reportName = [string]$base.ExpectedReportName
   $sourceConfig = Resolve-RepoPath ([string]$base.PackageConfig)
   if((Get-Sha256 $sourceConfig) -ne [string]$base.ConfigSha256) { throw "Referenced executable config identity changed." }

   $stopRule = switch($wave) {
      1 { "Reject the second broker immediately unless both known failure years remain profitable within their frozen PF, activity, and drawdown limits." }
      2 { "Reject unless all three disjoint eras and the continuous path pass risk-normalized real-tick thresholds on the distinct broker specification." }
      3 { "Require all 12 annual/YTD real-tick rows profitable, then enforce annual-to-continuous and primary-to-secondary consistency." }
   }
   $manifest.Add([pscustomobject][ordered]@{
      QueueRank = $rank
      Rank = $rank
      Wave = $wave
      Phase = $phase
      Role = $base.Role
      Candidate = "rdmc_diversified_repair_restart_safe_v2"
      Profile = "rdmc_diversified_repair_restart_safe_v2"
      Set = "frozen_second_broker"
      Window = $base.Window
      From = $base.From
      To = $base.To
      Model = 4
      Deposit = 10000
      InitialDeposit = 10000
      PackageConfig = Relative-RepoPath $sourceConfig
      SourceConfig = Relative-RepoPath $sourceConfig
      ExpectedReportName = $reportName
      ReportDestination = Relative-RepoPath (Join-Path $reportsDir $reportName)
      ProfileSha256 = $expectedProfileHash
      SourceSha256 = $expectedSourceHash
      ConfigSha256 = [string]$base.ConfigSha256
      PrimaryCompanyFingerprintSha256 = $primaryCompanyFingerprint
      MinNetProfit = $base.MinNetProfit
      MinProfitFactor = $base.MinProfitFactor
      MinTrades = $base.MinTrades
      MaxDrawdownPercent = $base.MaxDrawdownPercent
      MinRecoveryFactor = $base.MinRecoveryFactor
      MinCagrPercent = $base.MinCagrPercent
      MaxParallelism = 1
      StopRule = $stopRule
      Status = "PREREQUISITE_LOCKED"
   }) | Out-Null
}

$manifest | Export-Csv -LiteralPath $manifestFull -NoTypeInformation -Encoding ASCII
foreach($wave in 1..3) {
   $manifest | Where-Object Wave -eq $wave | Export-Csv -LiteralPath (Join-Path (Split-Path -Parent $manifestFull) ("RDMC_SECOND_BROKER_VALIDATION_WAVE_{0:D2}_MANIFEST.csv" -f $wave)) -NoTypeInformation -Encoding ASCII
}

$template = [pscustomobject][ordered]@{
   SchemaVersion = 1
   EnvironmentRole = "SECONDARY"
   CompanyFingerprintSha256 = "REPLACE_WITH_SHA256_OF_NORMALIZED_COMPANY_NAME"
   ServerFingerprintSha256 = "REPLACE_WITH_SHA256_OF_NORMALIZED_SERVER_NAME"
   PrimaryCompanyFingerprintSha256 = $primaryCompanyFingerprint
   Symbol = "XAUUSD"
   AccountCurrency = "USD"
   MarginMode = "HEDGING"
   TerminalBuild = ""
   ContractSize = ""
   TickSize = ""
   TickValueProfit = ""
   TickValueLoss = ""
   Point = ""
   Digits = ""
   VolumeMin = ""
   VolumeMax = ""
   VolumeStep = ""
   StopsLevelPoints = ""
   FreezeLevelPoints = ""
   TradeMode = "FULL"
   SwapMode = ""
   SwapLong = ""
   SwapShort = ""
   SpecificationCapturedUtc = ""
   SourceSha256 = $expectedSourceHash
   ProfileSha256 = $expectedProfileHash
   AccountIdentifierPublished = "False"
}
$template | Export-Csv -LiteralPath $templateFull -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status = "BUILT_PREREQUISITE_LOCKED"
   Rows = $manifest.Count
   WaveCounts = (@(1..3 | ForEach-Object { @($manifest | Where-Object Wave -eq $_).Count }) -join ',')
   SourceSha256 = Get-Sha256 $sourcePath
   ProfileSha256 = Get-Sha256 $profilePath
   ManifestSha256 = Get-Sha256 $manifestFull
   PrimaryCompanyFingerprintSha256 = $primaryCompanyFingerprint
   LaunchLocked = $true
}
