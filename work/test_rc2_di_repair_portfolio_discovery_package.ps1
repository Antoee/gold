param(
   [string]$PackageDir = "outputs\rc2_di_repair_portfolio_discovery_model1_package",
   [string]$QueuePath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_MANIFEST.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = '9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302'
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$packageFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $PackageDir)).Path
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
if($queue.Count -ne 24 -or $manifest.Count -ne 24) {
   throw "Expected 24 queue and manifest rows; queue=$($queue.Count), manifest=$($manifest.Count)."
}
$expectedCandidates = @(
   'dir_mo015_di08_strict','dir_mo015_di10_center','dir_mo015_di12_control',
   'dir_mo020_di08_strict','dir_mo020_di10_center','dir_mo020_di12_control'
)
$expectedWindows = @('continuous_2015_2020','older_2015_2018','repair_2019','repair_2020')
if(Compare-Object $expectedCandidates @($queue.Candidate | Sort-Object -Unique)) { throw "Frozen candidate matrix changed." }
if(Compare-Object $expectedWindows @($queue.Window | Sort-Object -Unique)) { throw "Frozen window matrix changed." }
if(@($queue | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) { throw "Post-2020 data leaked into discovery." }
if(@($queue | Where-Object { $_.Model -ne '1' -or $_.Deposit -ne '10000' }).Count -gt 0) {
   throw "Discovery must use Model 1 and a 10000 USD deposit."
}
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected RC2 source identity."
}
if(@($queue.RunLabel | Sort-Object -Unique).Count -ne 1 -or
   $queue[0].RunLabel -ne 'rc2_di_repair_portfolio_discovery_model1') {
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
   $expectedMo = if($candidate -like 'dir_mo015*') { '0.15' } else { '0.20' }
   $expectedDi = if($candidate -like '*di12*') { '-12.0' } elseif($candidate -like '*di10*') { '-10.0' } else { '-8.0' }
   foreach($token in @(
      'InpAllowRealAccountTrading=false',
      'InpRVRiskPercent=0.45',
      'InpRVUseDIEdgeGate=true',
      "InpRVMinimumDIEdge=$expectedDi",
      "InpMORiskPercent=$expectedMo",
      'InpMaximumPortfolioOpenRiskPercent=0.75',
      "InpEvidenceSourceHash=$expectedSourceHash",
      'InpEvidenceRunLabel=rc2_di_repair_portfolio_discovery_model1'
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
