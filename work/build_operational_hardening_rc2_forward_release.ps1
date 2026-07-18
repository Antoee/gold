param(
   [string]$ReleasePath = "release\operational-hardening-rc2-forward-prep"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$release = if([IO.Path]::IsPathRooted($ReleasePath)) { $ReleasePath } else { Join-Path $repo $ReleasePath }
$release = [IO.Path]::GetFullPath($release)
if(!$release.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) {
   throw "Release path is outside the workspace: $release"
}

& (Join-Path $PSScriptRoot "test_operational_hardening_rc2_forward_package.ps1") | Out-Null
New-Item -ItemType Directory -Path $release -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $release "evidence") -Force | Out-Null

$copies = [ordered]@{
   "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5" = "Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5"
   "work\Professional_XAUUSD_Operational_Hardening_RC2_Forward_Sentinel.mq5" = "Professional_XAUUSD_Operational_Hardening_RC2_Forward_Sentinel.mq5"
   "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_DEMO_PROFILE.set" = "OPERATIONAL_HARDENING_RC2_FORWARD_DEMO_PROFILE.set"
   "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_PROFILE.set" = "OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_PROFILE.set"
   "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_REGISTRATION_DRAFT.json" = "OPERATIONAL_HARDENING_RC2_FORWARD_REGISTRATION_DRAFT.json"
   "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_REGISTRATION_DRAFT.json" = "OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_REGISTRATION_DRAFT.json"
   "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PACKAGE.md" = "README.md"
   "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PREFLIGHT_TEST.md" = "evidence\OPERATIONAL_HARDENING_RC2_FORWARD_PREFLIGHT_TEST.md"
   "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PREFLIGHT_TEST.csv" = "evidence\OPERATIONAL_HARDENING_RC2_FORWARD_PREFLIGHT_TEST.csv"
   "outputs\OPERATIONAL_HARDENING_RC2_COMPILE.log" = "evidence\OPERATIONAL_HARDENING_RC2_COMPILE.log"
   "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_COMPILE.log" = "evidence\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_COMPILE.log"
   "outputs\OPERATIONAL_HARDENING_RC2_DECISION.md" = "evidence\OPERATIONAL_HARDENING_RC2_DECISION.md"
}
foreach($sourceRelative in $copies.Keys) {
   $source = Join-Path $repo $sourceRelative
   if(!(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Release source artifact missing: $sourceRelative" }
   Copy-Item -LiteralPath $source -Destination (Join-Path $release $copies[$sourceRelative]) -Force
}

$rows = foreach($relative in $copies.Values) {
   $file = Join-Path $release $relative
   [pscustomobject]@{
      Path = $relative.Replace('\', '/')
      Bytes = (Get-Item -LiteralPath $file).Length
      Sha256 = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
   }
}
$rows | Export-Csv -LiteralPath (Join-Path $release "MANIFEST.csv") -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status = "PREPARED_NOT_REGISTERED"
   ReleasePath = $release
   ManifestArtifacts = $rows.Count
   ForwardDays = 0
   ForwardTrades = 0
   LiveReady = $false
}
