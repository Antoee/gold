param(
   [string]$PackageDir = "outputs\independent_m15_weekend_gap_fade_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_MANIFEST.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$packageFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $PackageDir)).Path
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
if($queue.Count -ne 21 -or $manifest.Count -ne 21) {
   throw "Expected 21 queue and manifest rows; queue=$($queue.Count), manifest=$($manifest.Count)."
}

$expectedCandidates = @(
   'wgf_center', 'wgf_gap005', 'wgf_gap012', 'wgf_confirm000',
   'wgf_confirm030', 'wgf_maxgap035', 'wgf_maxgap065'
)
$actualCandidates = @($queue.Candidate | Sort-Object -Unique)
if(Compare-Object $expectedCandidates $actualCandidates) {
   throw "Frozen candidate neighborhood changed."
}
$expectedWindows = @('continuous_2015_2020', 'older_2015_2018', 'repair_2019_2020')
$actualWindows = @($queue.Window | Sort-Object -Unique)
if(Compare-Object $expectedWindows $actualWindows) {
   throw "Frozen discovery windows changed."
}
if(@($queue | Where-Object { [datetime]::ParseExact($_.To, 'yyyy.MM.dd', $null).Year -gt 2020 }).Count -gt 0) {
   throw "Post-2020 data leaked into discovery."
}
if(@($queue | Where-Object { $_.Model -ne '1' -or $_.Deposit -ne '10000' }).Count -gt 0) {
   throw "Discovery must use Model 1 and a 10000 USD deposit."
}
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or
   $queue[0].SourceSha256 -ne '0B0DB2770C3CF7170C248A94B829932166F9ADA42ACB3956B7FC4450993C8121') {
   throw "Unexpected discovery source identity."
}
if(@($queue.RunLabel | Sort-Object -Unique).Count -ne 1 -or
   $queue[0].RunLabel -ne 'independent_m15_weekend_gap_fade_discovery_model1') {
   throw "Unexpected discovery run label."
}

$packagedSource = Join-Path $packageFull 'source\Professional_XAUUSD_EA.mq5'
if((Get-FileHash -LiteralPath $packagedSource -Algorithm SHA256).Hash -ne $queue[0].SourceSha256) {
   throw "Packaged source hash does not match the queue."
}

foreach($candidate in $expectedCandidates) {
   $rows = @($queue | Where-Object Candidate -eq $candidate)
   if($rows.Count -ne 3 -or @($rows.ProfileSha256 | Sort-Object -Unique).Count -ne 1) {
      throw "Candidate $candidate does not have one profile identity across three windows."
   }
   $profilePath = Join-Path $packageFull $rows[0].ProfileSnapshot
   if((Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash -ne $rows[0].ProfileSha256) {
      throw "Profile hash mismatch for $candidate."
   }
   $profileText = Get-Content -LiteralPath $profilePath -Raw
   foreach($required in @(
      'InpAllowRealAccountTrading=false',
      'InpEnforceInitialBalanceContract=true',
      'InpExpectedInitialBalance=10000.0',
      'InpExpectedAccountCurrency=USD',
      'InpRiskPercent=0.10',
      "InpEvidenceProfileId=$candidate",
      "InpEvidenceSourceHash=$($queue[0].SourceSha256)",
      'InpEvidenceRunLabel=independent_m15_weekend_gap_fade_discovery_model1'
   )) {
      if($profileText.IndexOf($required, [StringComparison]::Ordinal) -lt 0) {
         throw "Profile $candidate missing token: $required"
      }
   }
}

foreach($row in $manifest) {
   $configPath = Resolve-RepoPath $row.PackageConfig
   $configText = Get-Content -LiteralPath $configPath -Raw
   foreach($required in @('Model=1', 'Deposit=10000', 'Currency=USD', 'Visual=0', 'ShutdownTerminal=1')) {
      if($configText.IndexOf($required, [StringComparison]::Ordinal) -lt 0) {
         throw "Config $($row.PackageConfig) missing token: $required"
      }
   }
}

[pscustomobject]@{
   Status = 'PASS'
   Rows = $queue.Count
   Variants = $actualCandidates.Count
   Windows = $actualWindows.Count
   DiscoveryCutoff = '2020-12-31'
   SourceSha256 = $queue[0].SourceSha256
}
