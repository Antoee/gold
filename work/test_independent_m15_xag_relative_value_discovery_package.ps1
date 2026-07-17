param(
   [string]$PackageDir = "outputs\independent_m15_xag_relative_value_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath))
if($queue.Count -ne 32 -or $manifest.Count -ne 32) { throw "Expected 16 variants across two windows." }
if(@($queue.Candidate | Sort-Object -Unique).Count -ne 16) { throw "Expected 16 unique cross-metal variants." }
if(@($queue | Where-Object { $_.Model -ne '1' -or [datetime]$_.To -gt [datetime]'2020-12-31' }).Count -ne 0) {
   throw "Cross-metal discovery opened post-2020 data or changed the tester model."
}
foreach($candidate in @($queue.Candidate | Sort-Object -Unique)) {
   $rows = @($queue | Where-Object Candidate -eq $candidate)
   if($rows.Count -ne 2) { throw "Candidate $candidate does not have two disjoint rows." }
   $windows = @($rows.Window | Sort-Object)
   if(Compare-Object @('discovery_2018_2020','older_2015_2017') $windows) { throw "Candidate $candidate has unexpected windows." }
}
foreach($row in $manifest) {
   $config = Resolve-RepoPath $row.PackageConfig
   if(!(Test-Path -LiteralPath $config)) { throw "Config missing: $config" }
   $text = Get-Content -LiteralPath $config -Raw
   foreach($token in @('Expert=Professional_XAUUSD_EA.ex5','Model=1','Visual=0','InpReferenceSymbol=XAGUSD','InpRiskPercent=0.10','InpAllowRealAccountTrading=false')) {
      if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Config token missing: $token" }
   }
   if(@($text -split "`r?`n" | Where-Object { $_ -eq 'InpReferenceSymbol=XAGUSD' }).Count -ne 1) {
      throw "Reference symbol must be serialized as one raw string input line."
   }
   if($text -match '(?m)^InpReferenceSymbol=.*\|\|') {
      throw "Reference symbol was incorrectly serialized as an optimizer tuple."
   }
}
$source = Join-Path (Resolve-RepoPath $PackageDir) 'source\Professional_XAUUSD_EA.mq5'
if(!(Test-Path -LiteralPath $source)) { throw "Packaged source missing." }
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if(@($queue | Where-Object SourceSha256 -ne $sourceHash).Count -ne 0) { throw "Packaged source hash mismatch." }
[pscustomobject]@{ Status="PASS"; Configurations=32; Candidates=16; Windows=2; LatestDate="2020-12-31"; RealTradingDefault=$false }
