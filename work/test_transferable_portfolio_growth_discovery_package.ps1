param(
   [string]$QueuePath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\transferable_portfolio_growth_discovery_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Assert-True([bool]$Condition,[string]$Message) { if(!$Condition) { throw $Message } }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$package = Resolve-RepoPath $PackageDir
Assert-True ($queue.Count -eq 28) "Expected 28 package rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 7) "Expected seven allocation profiles."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 4) "Expected four windows."
Assert-True (@($queue.Model | Where-Object { [int]$_ -ne 1 }).Count -eq 0) "Package contains non-Model1 rows."
Assert-True (@($queue.SourceSha256 | Sort-Object -Unique).Count -eq 1) "Package contains multiple source identities."

$source = Join-Path $package "source\Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
Assert-True ($sourceHash -eq "5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3") "Frozen source identity changed."

foreach($group in ($queue | Group-Object Candidate)) {
   Assert-True ($group.Count -eq 4) "Each profile must have four windows."
   $row = $group.Group[0]
   $profile = Join-Path $package $row.ProfileSnapshot
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $row.ProfileSha256) "Profile hash mismatch: $($row.Candidate)"
   $text = Get-Content -LiteralPath $profile -Raw
   foreach($required in @(
      "InpRVRiskPercent=$($row.RVRiskPercent)",
      "InpMORiskPercent=$($row.MORiskPercent)",
      'InpMaximumPortfolioOpenRiskPercent=0.75',
      'InpMaximumPortfolioEquityDrawdownPercent=5.00',
      'InpUseRealAccountSafetyLock=true',
      'InpAllowRealAccountTrading=false',
      'InpLogTrades=false'
   )) { Assert-True ($text.Contains($required)) "Profile contract missing: $required" }
   $riskSum = [double]$row.RVRiskPercent + [double]$row.MORiskPercent
   Assert-True ($riskSum -le 0.7500001) "Profile exceeds the frozen open-risk cap: $($row.Candidate)"
}

[pscustomobject]@{ Status='PASS'; Rows=$queue.Count; Profiles=7; Windows=4; SourceSha256=$sourceHash; MaximumRiskCap='0.75%' }
