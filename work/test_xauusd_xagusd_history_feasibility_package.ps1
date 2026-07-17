param(
   [string]$PackageDir = "outputs\xauusd_xagusd_history_feasibility_package",
   [string]$ManifestPath = "outputs\XAUUSD_XAGUSD_HISTORY_FEASIBILITY_MANIFEST.csv",
   [string]$QueuePath = "outputs\XAUUSD_XAGUSD_HISTORY_FEASIBILITY_QUEUE.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
if($manifest.Count -ne 2 -or $queue.Count -ne 2) { throw "Expected two disjoint feasibility configurations." }
if(@($queue | Where-Object { $_.Model -ne '1' -or [datetime]$_.To -gt [datetime]'2020-12-31' }).Count -ne 0) {
   throw "History feasibility package opened post-2020 data or changed the tester model."
}
$expectedWindows = @('older_2015_2018','discovery_2019_2020') | Sort-Object
if(Compare-Object $expectedWindows @($queue.Window | Sort-Object)) { throw "Unexpected feasibility windows." }
foreach($row in $manifest) {
   $config = Resolve-RepoPath $row.PackageConfig
   if(!(Test-Path -LiteralPath $config)) { throw "Config missing: $config" }
   $text = Get-Content -LiteralPath $config -Raw
   foreach($token in @('Expert=Professional_XAUUSD_EA.ex5','Model=1','Visual=0','InpReferenceSymbol=XAGUSD','InpUseRealAccountSafetyLock=true')) {
      if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Config token missing: $token" }
   }
}
$source = Join-Path (Resolve-RepoPath $PackageDir) 'source\Professional_XAUUSD_EA.mq5'
if(!(Test-Path -LiteralPath $source)) { throw "Packaged source missing." }
[pscustomobject]@{ Status="PASS"; Configurations=2; LatestDate="2020-12-31"; SendsOrders=$false }
