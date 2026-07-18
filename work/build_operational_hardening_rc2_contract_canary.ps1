param(
   [string]$SourcePath = "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5",
   [string]$BaseConfigPath = "outputs\operational_hardening_rc2_model1_package\configs\001_operational_hardening_rc2_continuous_2015_2026_m1.ini",
   [string]$BaseProfilePath = "outputs\operational_hardening_rc2_model1_package\profiles\operational_hardening_rc2_rv045_mo015_model1.set",
   [string]$PackageDir = "outputs\operational_hardening_rc2_contract_canary"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"

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

$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "RC2 source identity changed: $sourceHash" }
$baseConfig = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseConfigPath)).Path
$baseProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseProfilePath)).Path

$package = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir = Join-Path $package "configs"
$profileDir = Join-Path $package "profiles"
$reportDir = Join-Path $package "reports_here"
$sourceDir = Join-Path $package "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$profileText = Get-Content -LiteralPath $baseProfile -Raw
$profileText = $profileText.Replace("InpEvidenceRunLabel=operational_hardening_rc2_model1", "InpEvidenceRunLabel=operational_hardening_rc2_wrong_capital_canary")
$profileText = $profileText.Replace("InpLogTrades=true||true||0||0||N", "InpLogTrades=false||false||0||0||N")
$profileName = "operational_hardening_rc2_wrong_capital_m1.set"
$profilePath = Join-Path $profileDir $profileName
$profileText | Set-Content -LiteralPath $profilePath -Encoding ASCII -NoNewline
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

$configText = Get-Content -LiteralPath $baseConfig -Raw
$replacements = [ordered]@{
   "FromDate=2015.01.01" = "FromDate=2024.01.01"
   "ToDate=2026.07.16" = "ToDate=2024.02.01"
   "Deposit=10000" = "Deposit=100000"
   "Report=operational_hardening_rc2_continuous_2015_2026_m1" = "Report=operational_hardening_rc2_wrong_capital_m1"
   "InpEvidenceRunLabel=operational_hardening_rc2_model1" = "InpEvidenceRunLabel=operational_hardening_rc2_wrong_capital_canary"
   "InpLogTrades=true||true||0||0||N" = "InpLogTrades=false||false||0||0||N"
}
foreach($item in $replacements.GetEnumerator()) {
   if(!$configText.Contains($item.Key)) { throw "Base config marker missing: $($item.Key)" }
   $configText = $configText.Replace($item.Key, $item.Value)
}
$configName = "001_operational_hardening_rc2_wrong_capital_m1.ini"
$configText | Set-Content -LiteralPath (Join-Path $configDir $configName) -Encoding ASCII -NoNewline

$stopRule = "Must log the starting-capital initialization block and a nonzero OnInit stop with zero trades."
$queue = [pscustomobject]@{
   QueueRank=1; Candidate="operational_hardening_rc2_wrong_capital"; CandidateRank=1
   SourceType="account_contract_canary"; SourceRank=1; Phase="wrong_capital_init_lock"
   Set=$profileName; Window="2024_january"; From="2024.01.01"; To="2024.02.01"
   Model=1; Deposit=100000; Config="configs\$configName"
   ExpectedReportName="operational_hardening_rc2_wrong_capital_m1"
   ProfileSnapshot="profiles\$profileName"; ProfileSha256=$profileHash
   SourceSha256=$sourceHash; StopRule=$stopRule
}
$manifest = [pscustomobject]@{
   QueueRank=1; Candidate="operational_hardening_rc2_wrong_capital"; Phase="wrong_capital_init_lock"
   PhaseLabel="RC2 wrong-capital initialization canary"; Window="2024_january"; Model=1; Deposit=100000
   PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
   ExpectedReportName="operational_hardening_rc2_wrong_capital_m1"
   ReportDestination="$PackageDir\reports_here\operational_hardening_rc2_wrong_capital_m1"
   ProfileSha256=$profileHash; StopRule=$stopRule
}
$queue | Export-Csv -LiteralPath (Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY_QUEUE.csv") -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY_MANIFEST.csv") -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status="READY"; Configurations=1; SourceSha256=$sourceHash; ProfileSha256=$profileHash; PackageDir=$PackageDir
}
