param(
   [string]$ArchiveRoot = "",
   [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if([string]::IsNullOrWhiteSpace($ArchiveRoot)) {
   $ArchiveRoot = Join-Path $repo ("archive\generated_artifacts_{0}" -f (Get-Date).ToString("yyyyMMdd_HHmmss"))
}
elseif(![IO.Path]::IsPathRooted($ArchiveRoot)) {
   $ArchiveRoot = Join-Path $repo $ArchiveRoot
}

function Resolve-ExistingPath {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { return $null }
   return (Resolve-Path -LiteralPath $Path).Path
}

function Assert-UnderPath {
   param([string]$Path, [string]$Root, [string]$Label)
   $fullPath = [IO.Path]::GetFullPath($Path)
   $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
   if(!$fullPath.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase) -and
      !$fullPath.Equals($fullRoot.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
      throw "$Label path is outside expected root. Path=$fullPath Root=$fullRoot"
   }
}

function Add-Candidate {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Source,
      [string]$ArchiveSubdir,
      [string]$Reason
   )

   $resolved = Resolve-ExistingPath $Source
   if($null -eq $resolved) { return }
   Assert-UnderPath -Path $resolved -Root $repo -Label "Source"
   $targetDir = Join-Path $ArchiveRoot $ArchiveSubdir
   Assert-UnderPath -Path $targetDir -Root $ArchiveRoot -Label "Target"
   $target = Join-Path $targetDir ([IO.Path]::GetFileName($resolved))
   $Rows.Add([pscustomobject]@{
      Source = $resolved
      Target = $target
      Reason = $Reason
      Applied = $false
   }) | Out-Null
}

$rows = New-Object System.Collections.Generic.List[object]

Add-Candidate $rows (Join-Path $repo "outputs\offline_refresh_logs") "outputs" "Large generated offline refresh log folder."

foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -File -Filter "*.log" -ErrorAction SilentlyContinue) {
   if($path.Name -eq "MT5_HIDDEN_COMPILE_ISLP_LOWATR_TESTER_STATS.log") { continue }
   Add-Candidate $rows $path.FullName "outputs\logs" "Generated output log."
}

foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "work") -File -Filter "*.log" -ErrorAction SilentlyContinue) {
   Add-Candidate $rows $path.FullName "work\logs" "Generated work log."
}

foreach($pattern in @("LOWATR_STATS_BACKGROUND.*", "TESTER_STATS_COLLECTOR_SMOKE_*.csv")) {
   foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -File -Filter $pattern -ErrorAction SilentlyContinue) {
      Add-Candidate $rows $path.FullName "outputs\temp" "Temporary validation smoke/background artifact."
   }
}

foreach($pattern in @("*.unlock", "*.pid")) {
   foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "work") -File -Filter $pattern -ErrorAction SilentlyContinue) {
      Add-Candidate $rows $path.FullName "work\temp" "Local coordination artifact."
   }
}

$manifestPath = Join-Path $repo "outputs\REPO_CLEANUP_GENERATED_ARTIFACTS_MANIFEST.csv"
if($Apply) {
   foreach($row in $rows) {
      $targetDir = Split-Path -Parent $row.Target
      New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
      if(Test-Path -LiteralPath $row.Target) {
         $suffix = Get-Date -Format "yyyyMMddHHmmssfff"
         $row.Target = "$($row.Target).$suffix"
      }
      Move-Item -LiteralPath $row.Source -Destination $row.Target -Force
      $row.Applied = $true
   }
}

$rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation

[pscustomobject]@{
   Mode = if($Apply) { "APPLY" } else { "DRY_RUN" }
   Candidates = $rows.Count
   ArchiveRoot = $ArchiveRoot
   Manifest = $manifestPath
}
