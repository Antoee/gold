param(
   [string]$PackageDir = "outputs\xauusd_h4_channel_capital_feasibility_package",
   [string]$ManifestPath = "outputs\XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_MANIFEST.csv",
   [string]$QueuePath = "outputs\XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_QUEUE.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$packageFull = Resolve-RepoPath $PackageDir
$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
if($manifest.Count -ne 3 -or $queue.Count -ne 3) { throw "Expected three feasibility configurations." }
if(@($manifest.Candidate | Sort-Object -Unique).Count -ne 3) { throw "Candidate identifiers are not unique." }
if(@($queue | Where-Object { $_.From -ne '2015.01.01' -or $_.To -ne '2026.07.12' -or $_.Model -ne '1' }).Count -ne 0) { throw "Unexpected diagnostic window/model." }
foreach($row in $manifest) {
   $config = Resolve-RepoPath $row.PackageConfig
   if(!(Test-Path -LiteralPath $config)) { throw "Config missing: $config" }
   $text = Get-Content -LiteralPath $config -Raw
   foreach($token in @('Expert=Professional_XAUUSD_EA.ex5','Model=1','Visual=0','InpRiskPercent=0.10','InpUseRealAccountSafetyLock=true')) {
      if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Config token missing: $token" }
   }
}
$source = Join-Path $packageFull 'source\Professional_XAUUSD_EA.mq5'
if(!(Test-Path -LiteralPath $source)) { throw "Packaged source missing." }
[pscustomobject]@{ Status = "PASS"; Configurations = $manifest.Count; Candidates = 3; SendsOrders = $false }
