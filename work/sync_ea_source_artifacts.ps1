param(
   [string]$CanonicalSource = "outputs\Professional_XAUUSD_EA.mq5",
   [string]$RootSource = "Professional_XAUUSD_EA.mq5",
   [string]$PackageSource = "outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5",
   [string]$OutCsv = "outputs\EA_SOURCE_ARTIFACT_SYNC.csv",
   [string]$OutMarkdown = "outputs\EA_SOURCE_ARTIFACT_SYNC.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Copy-Source {
   param(
      [string]$From,
      [string]$To
   )

   $parent = Split-Path -Parent $To
   if(![string]::IsNullOrWhiteSpace($parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   Copy-Item -LiteralPath $From -Destination $To -Force
}

function Source-Row {
   param(
      [string]$Role,
      [string]$Path,
      [string]$CanonicalHash
   )

   $exists = Test-Path -LiteralPath $Path
   $hash = if($exists) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash } else { "" }
   $lines = if($exists) { (Get-Content -LiteralPath $Path | Measure-Object -Line).Lines } else { 0 }
   [pscustomobject]@{
      Role = $Role
      Path = $Path
      Exists = $exists
      Hash = $hash
      Lines = $lines
      MatchesCanonical = ($exists -and $hash -eq $CanonicalHash)
   }
}

if(!(Test-Path -LiteralPath $CanonicalSource)) {
   throw "Canonical EA source missing: $CanonicalSource"
}

$canonicalHash = (Get-FileHash -LiteralPath $CanonicalSource -Algorithm SHA256).Hash

Copy-Source $CanonicalSource $RootSource
Copy-Source $CanonicalSource $PackageSource

$rows = @(
   Source-Row "canonical" $CanonicalSource $canonicalHash
   Source-Row "repo_root" $RootSource $canonicalHash
   Source-Row "external_package" $PackageSource $canonicalHash
)

$failed = @($rows | Where-Object { $_.MatchesCanonical -ne $true })
New-Item -ItemType Directory -Path (Split-Path -Parent $OutCsv) -Force | Out-Null
$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# EA Source Artifact Sync") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline source sync only. This script does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$(if($failed.Count -eq 0) { "PASS" } else { "FAIL" })**") | Out-Null
$md.Add("- Canonical hash: ``$canonicalHash``") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Role | Exists | Matches | Lines | Path | Hash |") | Out-Null
$md.Add("|---|---|---|---:|---|---|") | Out-Null
foreach($row in $rows) {
   $md.Add("| $($row.Role) | $($row.Exists) | $($row.MatchesCanonical) | $($row.Lines) | ``$($row.Path)`` | ``$($row.Hash)`` |") | Out-Null
}
Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8

if($failed.Count -gt 0) {
   throw "EA source artifact sync failed: $($failed.Count) mismatched artifact(s)."
}

[pscustomobject]@{
   Overall = "PASS"
   Hash = $canonicalHash
   Artifacts = $rows.Count
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
