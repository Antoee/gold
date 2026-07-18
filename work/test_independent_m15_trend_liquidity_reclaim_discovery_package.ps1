param(
   [string]$PackageDir = "outputs\independent_m15_trend_liquidity_reclaim_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_MANIFEST.csv"
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
if($queue.Count -ne 28 -or $manifest.Count -ne 28) {
   throw "Expected 28 queue and manifest rows; queue=$($queue.Count), manifest=$($manifest.Count)."
}
$expectedCandidates = @('tlr_control_q0','tlr_center_q14','tlr_q07','tlr_q21','tlr_body30','tlr_lookback08','tlr_lookback20')
$actualCandidates = @($queue.Candidate | Sort-Object -Unique)
if(Compare-Object $expectedCandidates $actualCandidates) { throw "Frozen candidate neighborhood changed." }
$expectedWindows = @('continuous_2015_2020','older_2015_2018','repair_2019','repair_2020')
$actualWindows = @($queue.Window | Sort-Object -Unique)
if(Compare-Object $expectedWindows $actualWindows) { throw "Frozen discovery windows changed." }
if(@($queue | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) { throw "Post-2020 data leaked into discovery." }
if(@($queue | Where-Object { $_.Model -ne '1' -or $_.Deposit -ne '10000' }).Count -gt 0) {
   throw "Discovery must use Model 1 and a 10000 USD deposit."
}
$expectedHash = '67167ACC0BFEA04357EE17195C30320342DEE0D566F2C94E01CC1BF521F26002'
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedHash) {
   throw "Unexpected discovery source identity."
}
if(@($queue.RunLabel | Sort-Object -Unique).Count -ne 1 -or
   $queue[0].RunLabel -ne 'trend_liquidity_reclaim_discovery_model1') {
   throw "Unexpected discovery run label."
}
$packagedSource = Join-Path $packageFull 'source\Professional_XAUUSD_EA.mq5'
if((Get-FileHash -LiteralPath $packagedSource -Algorithm SHA256).Hash -ne $expectedHash) {
   throw "Packaged source hash does not match the queue."
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
   $profileText = Get-Content -LiteralPath $profilePath -Raw
   foreach($required in @(
      'InpAllowRealAccountTrading=false','InpUseRealAccountSafetyLock=true','InpRiskPercent=0.10',
      'InpMaximumTradesPerDay=1','InpMaximumDailyLossPercent=0.75',
      'InpMaximumEquityDrawdownPercent=5.00','InpUseAccountWideExposureGuard=true',
      'InpAccountWideBlockUnprotectedExposure=true','InpUseTrendEMAFilter=true',
      'InpTrendEMAPeriod=200','InpUseMinimumADXFilter=true','InpMinimumADX=20.0',
      'InpEntryStartHour=9','InpEntryEndHour=11',"InpEvidenceProfileId=$candidate",
      "InpEvidenceSourceHash=$expectedHash",'InpEvidenceRunLabel=trend_liquidity_reclaim_discovery_model1'
   )) {
      if($profileText.IndexOf($required, [StringComparison]::Ordinal) -lt 0) {
         throw "Profile $candidate missing token: $required"
      }
   }
}

$center = Get-Content -LiteralPath (Join-Path $packageFull 'profiles\tlr_center_q14.set') -Raw
$control = Get-Content -LiteralPath (Join-Path $packageFull 'profiles\tlr_control_q0.set') -Raw
foreach($token in @('InpLiquidityLookbackBars=12','InpMinimumBodyPercent=20.0','InpUsePostLossQuarantine=true','InpPostLossQuarantineDays=14')) {
   if($center.IndexOf($token,[StringComparison]::Ordinal) -lt 0) { throw "Center missing token: $token" }
}
foreach($token in @('InpUsePostLossQuarantine=false','InpPostLossQuarantineDays=0')) {
   if($control.IndexOf($token,[StringComparison]::Ordinal) -lt 0) { throw "Control missing token: $token" }
}

foreach($row in $manifest) {
   $configText = Get-Content -LiteralPath (Resolve-RepoPath $row.PackageConfig) -Raw
   foreach($required in @('Model=1','Deposit=10000','Currency=USD','Visual=0','ShutdownTerminal=1')) {
      if($configText.IndexOf($required,[StringComparison]::Ordinal) -lt 0) {
         throw "Config $($row.PackageConfig) missing token: $required"
      }
   }
}

[pscustomobject]@{Status='PASS';Rows=$queue.Count;Variants=$actualCandidates.Count;Windows=$actualWindows.Count;DiscoveryCutoff='2020-12-31';SourceSha256=$expectedHash}
