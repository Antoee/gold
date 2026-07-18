param(
   [string]$PackageDir = "outputs\reversion_shock_guard_portfolio_discovery_model1_package",
   [string]$QueuePath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_MANIFEST.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = 'A681A1371E3DC2A07234C373F9E4574CC16F0E3C96C9C48E2B703962D2A5B8A9'
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$packageFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $PackageDir)).Path
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
if($queue.Count -ne 56 -or $manifest.Count -ne 56) {
   throw "Expected 56 queue and manifest rows; queue=$($queue.Count), manifest=$($manifest.Count)."
}
$expectedCandidates = @(
   'rsg_mo015_body25','rsg_mo015_combo20','rsg_mo015_combo25','rsg_mo015_combo25_di08',
   'rsg_mo015_combo30','rsg_mo015_control','rsg_mo015_di10',
   'rsg_mo020_body25','rsg_mo020_combo20','rsg_mo020_combo25','rsg_mo020_combo25_di08',
   'rsg_mo020_combo30','rsg_mo020_control','rsg_mo020_di10'
)
$expectedWindows = @('continuous_2015_2020','older_2015_2018','repair_2019','repair_2020')
if(Compare-Object $expectedCandidates @($queue.Candidate | Sort-Object -Unique)) { throw "Frozen candidate matrix changed." }
if(Compare-Object $expectedWindows @($queue.Window | Sort-Object -Unique)) { throw "Frozen window matrix changed." }
if(@($queue | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) { throw "Post-2020 data leaked into discovery." }
if(@($queue | Where-Object { $_.Model -ne '1' -or $_.Deposit -ne '10000' }).Count -gt 0) {
   throw "Discovery must use Model 1 and a 10000 USD deposit."
}
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected shock-guard source identity."
}
if(@($queue.RunLabel | Sort-Object -Unique).Count -ne 1 -or
   $queue[0].RunLabel -ne 'reversion_shock_guard_portfolio_discovery_model1') {
   throw "Unexpected run label."
}
$packagedSource = Join-Path $packageFull 'source\Professional_XAUUSD_EA.mq5'
if((Get-FileHash -LiteralPath $packagedSource -Algorithm SHA256).Hash -ne $expectedSourceHash) {
   throw "Packaged source identity mismatch."
}

foreach($candidate in $expectedCandidates) {
   $rows = @($queue | Where-Object Candidate -eq $candidate)
   if($rows.Count -ne 4 -or @($rows.ProfileSha256 | Sort-Object -Unique).Count -ne 1) {
      throw "Candidate $candidate does not have one profile identity across four windows."
   }
   $profilePath = Join-Path $packageFull $rows[0].ProfileSnapshot
   if((Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash -ne $rows[0].ProfileSha256) {
      throw "Profile hash mismatch for $candidate."
   }
   $profile = Get-Content -LiteralPath $profilePath -Raw
   $expectedMo = $rows[0].MORiskPercent
   $expectedDi = $rows[0].RVMinimumDIEdge
   $expectedUseBody = $rows[0].RVUseMinimumBodyGate
   $expectedBody = $rows[0].RVMinimumBodyPercent
   foreach($token in @(
      'InpAllowRealAccountTrading=false',
      'InpRVRiskPercent=0.45',
      'InpRVUseDIEdgeGate=true',
      "InpRVMinimumDIEdge=$expectedDi",
      "InpRVUseMinimumBodyGate=$expectedUseBody",
      "InpRVMinimumBodyPercent=$expectedBody",
      "InpMORiskPercent=$expectedMo",
      'InpMaximumPortfolioOpenRiskPercent=0.75',
      "InpEvidenceSourceHash=$expectedSourceHash",
      'InpEvidenceRunLabel=reversion_shock_guard_portfolio_discovery_model1'
   )) {
      if($profile.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
         throw "Profile $candidate missing token: $token"
      }
   }
}

foreach($row in $manifest) {
   $config = Get-Content -LiteralPath (Resolve-RepoPath $row.PackageConfig) -Raw
   foreach($token in @('Model=1','Deposit=10000','Currency=USD','Visual=0','ShutdownTerminal=1')) {
      if($config.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
         throw "Config $($row.PackageConfig) missing token: $token"
      }
   }
}

[pscustomobject]@{
   Status='PASS';Rows=$queue.Count;Profiles=$expectedCandidates.Count;Windows=$expectedWindows.Count
   SourceSha256=$expectedSourceHash;LatestDiscoveryDate='2020-12-31'
}
