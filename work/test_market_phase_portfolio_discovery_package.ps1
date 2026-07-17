param(
   [string]$QueueManifestPath = "outputs\MARKET_PHASE_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\market_phase_portfolio_discovery_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Assert-True([bool]$Condition, [string]$Message) { if(!$Condition) { throw $Message } }
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$packageFull = Resolve-RepoPath $PackageDir
$source = Join-Path $packageFull "source\Professional_XAUUSD_EA.mq5"
Assert-True ($queue.Count -eq 24) "Expected 24 discovery rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 8) "Expected eight variants."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 3) "Expected three discovery windows."
Assert-True (@($queue.To | Where-Object { $_ -gt "2020.12.31" }).Count -eq 0) "Post-2020 data leaked into discovery."
Assert-True (Test-Path -LiteralPath $source -PathType Leaf) "Package source is missing."
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
Assert-True (@($queue.SourceSha256 | Sort-Object -Unique).Count -eq 1) "Queue contains multiple source identities."
Assert-True ($queue[0].SourceSha256 -eq $sourceHash) "Queue/package source identity mismatch."
foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 3) "Each variant must have three discovery windows."
   $first = $candidate.Group[0]
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $profile -PathType Leaf) "Missing profile: $($first.ProfileSnapshot)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $first.ProfileSha256) "Profile hash mismatch."
   $text = Get-Content -LiteralPath $profile -Raw
   foreach($required in @(
      "InpRVRiskPercent=0.45", "InpMORiskPercent=0.15", "InpMaximumPortfolioOpenRiskPercent=0.75",
      "InpMarketPhaseTimeframe=16385", "InpMarketPhaseEfficiencyLookbackBars=",
      "InpMarketPhaseRangeEfficiency=", "InpMarketPhaseTrendEfficiency=",
      "InpMarketPhaseHostileRiskScale=",
      "InpMaximumPortfolioEquityDrawdownPercent=5.00", "InpUseRealAccountSafetyLock=true",
      "InpAllowRealAccountTrading=false", "InpShowDashboard=false"
   )) { Assert-True ($text.Contains($required)) "Profile contract missing: $required" }
}
$control = @($queue | Where-Object Candidate -eq "mpp_fixed_control")
Assert-True ($control.Count -eq 3 -and @($control.PhaseEnabled | Sort-Object -Unique)[0] -eq "false") "Fixed-risk control missing."
[pscustomobject]@{ Status="PASS"; Rows=24; Variants=8; Windows=3; HoldoutRows=0; FixedRiskControl=$true; SourceSha256=$sourceHash }
