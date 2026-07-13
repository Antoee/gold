param(
   [string]$ArchiveRoot = "",
   [switch]$IncludeGeneratedPackages,
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
   if(!$seenSources.Add($resolved)) { return }
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
$seenSources = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

Add-Candidate $rows (Join-Path $repo "outputs\offline_refresh_logs") "outputs" "Large generated offline refresh log folder."

foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Recurse -File -Filter "*.log" -ErrorAction SilentlyContinue) {
   if($path.Name -eq "MT5_HIDDEN_COMPILE_ISLP_LOWATR_TESTER_STATS.log") { continue }
   if($path.Name -eq "MT5_HIDDEN_COMPILE_FSD_EFFICIENCY_RELAXATION.log") { continue }
   Add-Candidate $rows $path.FullName "outputs\logs" "Generated output log."
}

foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "work") -Recurse -File -Filter "*.log" -ErrorAction SilentlyContinue) {
   Add-Candidate $rows $path.FullName "work\logs" "Generated work log."
}

foreach($pattern in @("LOWATR_STATS_BACKGROUND.*", "TESTER_STATS_COLLECTOR_SMOKE_*.csv")) {
   foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -File -Filter $pattern -ErrorAction SilentlyContinue) {
      Add-Candidate $rows $path.FullName "outputs\temp" "Temporary validation smoke/background artifact."
   }
}

foreach($pattern in @("*_COMPACT.mq5", "*_TESTER.mq5", "BLOCK_REASON_DIAGNOSTICS_RAW.csv")) {
   foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -File -Filter $pattern -ErrorAction SilentlyContinue) {
      Add-Candidate $rows $path.FullName "outputs\generated_sources" "Generated MT5 tester source or bulky raw diagnostic artifact; summarized by root result files."
   }
}

foreach($pattern in @("*_BACKGROUND.*", "*.pid")) {
   foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -File -Filter $pattern -ErrorAction SilentlyContinue) {
      Add-Candidate $rows $path.FullName "outputs\temp" "Temporary background-run coordination artifact."
   }
}

foreach($pattern in @("*.unlock", "*.pid")) {
   foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "work") -File -Filter $pattern -ErrorAction SilentlyContinue) {
      Add-Candidate $rows $path.FullName "work\temp" "Local coordination artifact."
   }
}

if($IncludeGeneratedPackages) {
   $keepOutputDirs = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
   @(
      "realtick_islp_lowatr_orderflow_probe_package",
      "realtick_islp_lowatr_orderflow_monthly_validation_package",
      "realtick_islp_lowatr_orderflow_quarterly_validation_package",
      "realtick_dec_islp_monthly_validation_package",
      "realtick_dec_islp_quarterly_validation_package"
   ) | ForEach-Object { [void]$keepOutputDirs.Add($_) }

   foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "work") -Directory -ErrorAction SilentlyContinue) {
      Add-Candidate $rows $path.FullName "work\generated_packages" "Generated local MT5 package/config folder."
   }

   foreach($path in Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Directory -ErrorAction SilentlyContinue) {
      if($keepOutputDirs.Contains($path.Name)) { continue }
      Add-Candidate $rows $path.FullName "outputs\generated_packages" "Generated MT5 package/config folder; summarized by root CSVs and research notes."
   }

   foreach($pattern in @("outputs_ci_generated_*", "quality_tp_*")) {
      foreach($path in Get-ChildItem -LiteralPath $repo -Directory -Filter $pattern -ErrorAction SilentlyContinue) {
         Add-Candidate $rows $path.FullName "root\generated_packages" "Generated root-level validation package folder."
      }
   }
}

$manifestPath = Join-Path $repo "outputs\REPO_CLEANUP_GENERATED_ARTIFACTS_MANIFEST.csv"
if($Apply) {
   foreach($row in $rows) {
      if(!(Test-Path -LiteralPath $row.Source)) {
         continue
      }
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
