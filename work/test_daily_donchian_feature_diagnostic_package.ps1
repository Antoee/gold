param(
   [string]$PackageDir = "outputs\daily_donchian_feature_diagnostic_package",
   [string]$QueuePath = "outputs\DAILY_DONCHIAN_FEATURE_DIAGNOSTIC_QUEUE.csv",
   [string]$ManifestPath = "outputs\DAILY_DONCHIAN_FEATURE_DIAGNOSTIC_PACKAGE_MANIFEST.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Assert-True([bool]$Condition, [string]$Message) {
   if(!$Condition) { throw $Message }
}

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
Assert-True ($queue.Count -eq 1) "Expected exactly one diagnostic queue row."
Assert-True ($manifest.Count -eq 1) "Expected exactly one diagnostic manifest row."

$source = Resolve-RepoPath "$PackageDir\source\Professional_XAUUSD_EA.mq5"
$profile = Resolve-RepoPath "$PackageDir\profiles\$($queue[0].Set)"
$config = Resolve-RepoPath "$PackageDir\$($queue[0].Config)"
Assert-True (Test-Path -LiteralPath $source) "Packaged source is missing."
Assert-True (Test-Path -LiteralPath $profile) "Packaged profile is missing."
Assert-True (Test-Path -LiteralPath $config) "Packaged config is missing."

$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash
$profileText = Get-Content -LiteralPath $profile -Raw
$configText = Get-Content -LiteralPath $config -Raw
Assert-True ($sourceHash -eq $queue[0].SourceSha256) "Packaged source hash does not match queue evidence."
Assert-True ($profileHash -eq $queue[0].ProfileSha256) "Packaged profile hash does not match queue evidence."
Assert-True ($profileText -match '(?m)^InpLogLevel=2\|\|') "Trade logging is not enabled."
Assert-True ($profileText -match '(?m)^InpUseBlockReasonDiagnostics=false\|\|') "Heavy block diagnostics must remain disabled."
Assert-True ($profileText -match '(?m)^InpDailyDonchianUseChannelExit=true\|\|') "The exact promoted Donchian channel exit is not enabled."
Assert-True ($sourceHash -ne 'D387779DC3BABD6A8294C46E5827D1029AA536EA29F91C06C357D66D2B098153') "Feature source unexpectedly matches the uninstrumented source."
Assert-True ($configText -match '(?m)^Model=1\r?$') "Fast diagnostic must use Model 1."
Assert-True ($configText -match '(?m)^Deposit=10000\r?$') "Diagnostic deposit must be 10000."
Assert-True ($configText -match '(?m)^FromDate=2015\.01\.01\r?$') "Diagnostic start date is wrong."
Assert-True ($configText -match '(?m)^ToDate=2026\.07\.12\r?$') "Diagnostic end date is wrong."

[pscustomobject]@{
   Status = "PASS"
   QueueRows = $queue.Count
   ManifestRows = $manifest.Count
   SourceSha256 = $sourceHash
   ProfileSha256 = $profileHash
}

