param(
   [string]$ReleasePath = "release\transferable-portfolio-v0.2-rc1"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$release = if([IO.Path]::IsPathRooted($ReleasePath)) { $ReleasePath } else { Join-Path $repo $ReleasePath }
if(!(Test-Path -LiteralPath $release -PathType Container)) { throw "Release directory missing: $release" }
$release = (Resolve-Path -LiteralPath $release).Path
$manifestPath = Join-Path $release "MANIFEST.csv"
if(!(Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Release manifest missing." }

$manifest = @(Import-Csv -LiteralPath $manifestPath)
if($manifest.Count -ne 9) { throw "Expected 9 release artifacts, found $($manifest.Count)." }
foreach($row in $manifest) {
   if([string]::IsNullOrWhiteSpace($row.Path) -or $row.Path.Contains("..") -or [IO.Path]::IsPathRooted($row.Path)) {
      throw "Unsafe manifest path: $($row.Path)"
   }
   $file = Join-Path $release $row.Path
   if(!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Manifest artifact missing: $($row.Path)" }
   if((Get-Item -LiteralPath $file).Length -ne [long]$row.Bytes) { throw "Size mismatch: $($row.Path)" }
   $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
   if($hash -ne $row.Sha256) { throw "SHA-256 mismatch: $($row.Path)" }
}

$sourceHash = (Get-FileHash -LiteralPath (Join-Path $release "Professional_XAUUSD_Operational_Hardening_Portfolio.mq5") -Algorithm SHA256).Hash
if($sourceHash -ne "015DCCDBA020796895C1A71B150C31B4F0F276A9334243BD7474293F73385EB4") { throw "Source identity mismatch." }
$profileHash = (Get-FileHash -LiteralPath (Join-Path $release "OPERATIONAL_HARDENING_PROFILE.set") -Algorithm SHA256).Hash
if($profileHash -ne "7E7081A9BF179BC1B93623316D8EFFFB3C0CED91ACF0FFDE91BD61ABD712F6B2") { throw "Profile identity mismatch." }

$model1Rows = @(Import-Csv -LiteralPath (Join-Path $release "evidence\OPERATIONAL_HARDENING_PORTFOLIO_MODEL1_RESULTS.csv"))
$model4Rows = @(Import-Csv -LiteralPath (Join-Path $release "evidence\OPERATIONAL_HARDENING_PORTFOLIO_MODEL4_RESULTS.csv"))
$model1 = $model1Rows[0]
$model4 = $model4Rows[0]
if($model1Rows.Count -ne 1 -or $model1.Status -ne "PARSED" -or [double]$model1.NetProfit -ne 1616.49 -or [int]$model1.TotalTrades -ne 370 -or [double]$model1.MaxDrawdownPercent -ne 3.24) {
   throw "Model1 evidence contract mismatch."
}
if($model4Rows.Count -ne 1 -or $model4.Status -ne "PARSED" -or [double]$model4.NetProfit -ne 1615.36 -or [int]$model4.TotalTrades -ne 362 -or [double]$model4.MaxDrawdownPercent -ne 2.83) {
   throw "Model4 evidence contract mismatch."
}

$fidelity = @(Import-Csv -LiteralPath (Join-Path $release "evidence\OPERATIONAL_HARDENING_PORTFOLIO_FIDELITY.csv"))
if($fidelity.Count -ne 4 -or @($fidelity | Where-Object { $_.Exact -ne "TRUE" -or [int]$_.MismatchedEvents -ne 0 }).Count -ne 0) {
   throw "Event-fidelity contract mismatch."
}
$decision = Get-Content -LiteralPath (Join-Path $release "evidence\OPERATIONAL_HARDENING_PORTFOLIO_DECISION.md") -Raw
foreach($marker in @("DO NOT DECLARE LIVE-READY", "no valid forward evidence", "Real-money use is not approved")) {
   if($decision -notmatch [regex]::Escape($marker)) { throw "Decision safety marker missing: $marker" }
}

[pscustomobject]@{
   Status = "PASS"
   ManifestArtifacts = $manifest.Count
   SourceSha256 = $sourceHash
   ProfileSha256 = $profileHash
   Model1Trades = [int]$model1.TotalTrades
   Model4Trades = [int]$model4.TotalTrades
   FidelityRows = $fidelity.Count
   LiveReady = $false
}
