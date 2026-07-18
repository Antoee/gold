param(
   [string]$SourcePath = "work\Professional_XAUUSD_Operational_Hardening_Portfolio.mq5",
   [string]$PackageDir = "outputs\operational_hardening_portfolio_model4_package",
   [string]$QueueManifestPath = "outputs\OPERATIONAL_HARDENING_PORTFOLIO_MODEL4_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\OPERATIONAL_HARDENING_PORTFOLIO_MODEL4_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\OPERATIONAL_HARDENING_PORTFOLIO_MODEL4_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "015DCCDBA020796895C1A71B150C31B4F0F276A9334243BD7474293F73385EB4"

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
if($sourceHash -ne $expectedSourceHash) { throw "Hardened source identity changed: $sourceHash" }

$inputs = Get-PinnedSourceInputs -Path $sourceFull
Set-PinnedInput -Inputs $inputs -Name "InpLogTrades" -Value "true"
Set-PinnedInput -Inputs $inputs -Name "InpRVLogFileName" -Value "OPERATIONAL_HARDENING_RV_MODEL4_EVENTS.csv" -StringValue
Set-PinnedInput -Inputs $inputs -Name "InpMOLogFileName" -Value "OPERATIONAL_HARDENING_MO_MODEL4_EVENTS.csv" -StringValue
Set-PinnedInput -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash -StringValue
Set-PinnedInput -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "operational_hardening_model4" -StringValue

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$profileName = "operational_hardening_rv045_mo015_model4.set"
$profilePath = Join-Path $profileDir $profileName
@($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
   Set-Content -LiteralPath $profilePath -Encoding ASCII
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

$configName = "001_operational_hardening_continuous_2015_2026_m4.ini"
$reportName = "operational_hardening_continuous_2015_2026_m4"
Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
   -ReportName $reportName -From "2015.01.01" -To "2026.07.16" `
   -Inputs $inputs -Model 4 -Deposit 10000

$stopRule = "Require zero signal drift versus v0.1: identical trade count, lane, side, entry time, exit time, and profit within report precision. Any safety-triggered historical divergence rejects v0.2 pending review."
$queue = [pscustomobject]@{
   QueueRank=1; Candidate="operational_hardening_rv045_mo015"; CandidateRank=1
   SourceType="transferable_portfolio_safety_fork"; SourceRank=1; Phase="continuous_model4_fidelity"
   Set=$profileName; Window="continuous_2015_2026"; From="2015.01.01"; To="2026.07.16"
   Model=4; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName
   ProfileSnapshot="profiles\$profileName"; ProfileSha256=$profileHash
   SourceSha256=$sourceHash; StopRule=$stopRule
}
$manifest = [pscustomobject]@{
   QueueRank=1; Candidate="operational_hardening_rv045_mo015"; Phase="continuous_model4_fidelity"
   PhaseLabel="Operational-hardening Model4 real-tick schedule fidelity"
   Window="continuous_2015_2026"; Model=4; Deposit=10000
   PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
   ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
   ProfileSha256=$profileHash; StopRule=$stopRule
}
$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

@(
   "# Operational-Hardening Portfolio Model4 Fidelity Package",
   "",
   "Safety-only fork of the released transferable portfolio.",
   "",
   "- Source SHA-256: $sourceHash",
   "- Profile SHA-256: $profileHash",
   "- Window: 2015-01-01 through 2026-07-16",
   "- Risk: 0.45% reversion + 0.15% momentum; 0.75% shared open-risk cap",
   "- Added gates: 1.25% weekly, 1.50% monthly, nine-loss/48-hour cooldown, 300% margin floor",
   "- Initial attachment: USD account and 10,000 balance within 1%",
   "",
   $stopRule
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status="READY"; Configurations=1; Inputs=$inputs.Count; SourceHash=$sourceHash
   ProfileHash=$profileHash; PackageDir=$PackageDir
}
