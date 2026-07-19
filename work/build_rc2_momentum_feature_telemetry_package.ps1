param(
   [string]$SourcePath = "work\Professional_XAUUSD_RC2_Momentum_Feature_Telemetry.mq5",
   [string]$PackageDir = "outputs\rc2_momentum_feature_telemetry_model1_package",
   [string]$QueueManifestPath = "outputs\RC2_MOMENTUM_FEATURE_TELEMETRY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\RC2_MOMENTUM_FEATURE_TELEMETRY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\RC2_MOMENTUM_FEATURE_TELEMETRY_CONTRACT.md",
   [string]$WindowTag = "2015_2018",
   [string]$From = "2015.01.01",
   [string]$To = "2018.12.31",
   [string]$ReservedWindow = "2019-01-01 through 2020-12-31"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "9BC49EFDCB95F46C1B473072CBD7A67B3794BACA0D2AE190979CC75C51D84ACC"

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

function Convert-SourceDefault([string]$Type, [string]$Value) {
   $trimmed = $Value.Trim()
   if($Type -eq "string") {
      if($trimmed.Length -lt 2 -or !$trimmed.StartsWith('"') -or !$trimmed.EndsWith('"')) {
         throw "Unsupported string default: $trimmed"
      }
      return $trimmed.Substring(1, $trimmed.Length - 2)
   }
   if($Type -eq "ENUM_TIMEFRAMES") {
      $timeframes = @{ PERIOD_H1 = "16385"; PERIOD_D1 = "16408" }
      if(!$timeframes.ContainsKey($trimmed)) { throw "Unsupported timeframe default: $trimmed" }
      return $timeframes[$trimmed]
   }
   return $trimmed
}

function Get-PinnedSourceInputs([string]$Path) {
   $inputs = [ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$') { continue }
      $type = $Matches[1]
      $name = $Matches[2]
      $value = Convert-SourceDefault -Type $type -Value $Matches[3]
      if($inputs.Contains($name)) { throw "Duplicate source input: $name" }
      if($type -eq "string") { $inputs[$name] = "$name=$value" }
      else { $inputs[$name] = "$name=$value||$value||0||0||N" }
   }
   if($inputs.Count -lt 100) { throw "Unexpectedly small hardened input contract: $($inputs.Count)" }
   return $inputs
}

function Set-PinnedInput($Inputs, [string]$Name, [string]$Value, [switch]$StringValue) {
   if(!$Inputs.Contains($Name)) { throw "Cannot override unknown input: $Name" }
   if($StringValue) { $Inputs[$Name] = "$Name=$Value" }
   else { $Inputs[$Name] = "$Name=$Value||$Value||0||0||N" }
}

$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Telemetry source identity changed: $sourceHash" }

$inputs = Get-PinnedSourceInputs -Path $sourceFull
Set-PinnedInput $inputs "InpLogTrades" "true"
Set-PinnedInput $inputs "InpRVLogFileName" ("RC2_MOMENTUM_FEATURE_TELEMETRY_RV_{0}.csv" -f $WindowTag.ToUpperInvariant()) -StringValue
Set-PinnedInput $inputs "InpMOLogFileName" ("RC2_MOMENTUM_FEATURE_TELEMETRY_MO_{0}.csv" -f $WindowTag.ToUpperInvariant()) -StringValue
Set-PinnedInput $inputs "InpEvidenceSourceHash" $sourceHash -StringValue
Set-PinnedInput $inputs "InpEvidenceRunLabel" ("rc2_momentum_feature_telemetry_{0}" -f $WindowTag) -StringValue

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$profileName = "rc2_momentum_feature_telemetry_{0}.set" -f $WindowTag
$profilePath = Join-Path $profileDir $profileName
@($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
   Set-Content -LiteralPath $profilePath -Encoding ASCII
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

$configName = "001_rc2_momentum_feature_telemetry_{0}_m1.ini" -f $WindowTag
$reportName = "rc2_momentum_feature_telemetry_{0}_m1" -f $WindowTag
Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
   -ReportName $reportName -From $From -To $To `
   -Inputs $inputs -Model 1 -Deposit 10000

$stopRule = "Telemetry only. Feature selection may use $WindowTag outcomes; $ReservedWindow remains outside this telemetry package."
$queue = [pscustomobject]@{
   QueueRank=1; Candidate="rc2_momentum_feature_telemetry"; CandidateRank=1
   SourceType="behavior_preserving_telemetry_fork"; SourceRank=1; Phase="feature_telemetry_model1"
   Set=$profileName; Window="feature_selection_$WindowTag"; From=$From; To=$To
   Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName
   ProfileSnapshot="profiles\$profileName"; ProfileSha256=$profileHash
   SourceSha256=$sourceHash; StopRule=$stopRule
}
$manifest = [pscustomobject]@{
   QueueRank=1; Candidate="rc2_momentum_feature_telemetry"; Phase="feature_telemetry_model1"
   PhaseLabel="RC2 momentum feature telemetry Model1"
   Window="feature_selection_$WindowTag"; Model=1; Deposit=10000
   PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
   ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
   ProfileSha256=$profileHash; StopRule=$stopRule
}
$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

@(
   "# RC2 Momentum Feature Telemetry Contract",
   "",
   "Frozen before inspecting feature-conditioned results for this window.",
   "",
   "- Source SHA-256: ``$sourceHash``",
   "- Profile SHA-256: ``$profileHash``",
   "- Window: ``$From`` through ``$To``",
   "- Model: ``1``; deposit: ```$10,000``",
   "- Behavior: exact RC2 strategy plus entry-reason telemetry only",
   "- Outside this telemetry package: ``$ReservedWindow``",
   "",
   "Telemetry fields: channel width/ATR, breakout distance/ATR, H1 and D1 efficiency ratios, D1 momentum percent, ATR percent, body ratio, close location, range/ATR, tick-volume ratio, and stop distance/ATR.",
   "",
   $stopRule
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status="READY"; Configurations=1; Inputs=$inputs.Count; SourceHash=$sourceHash
   ProfileHash=$profileHash; PackageDir=$PackageDir
}
