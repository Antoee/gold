param(
   [string]$PackageDir = "outputs\peak_trail_unblock_probe_package",
   [string]$ReportRoot = "outputs",
   [int]$Model = 4,
   [string]$From = "2019.01.01",
   [string]$To = "2026.07.12",
   [string]$Window = "continuous_2019_2026"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Clear-OutputDirSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   $outputs = (Resolve-Path -LiteralPath (Join-Path $repo "outputs")).Path
   $parent = Split-Path -Parent $resolved
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   if(Test-Path -LiteralPath $resolved) {
      $actual = (Resolve-Path -LiteralPath $resolved).Path
      if(!$actual.StartsWith($outputs, [System.StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-outputs directory: $actual"
      }
      Remove-Item -LiteralPath $actual -Recurse -Force
   }
   New-Item -ItemType Directory -Path $resolved -Force | Out-Null
}

function New-ProbeProfile {
   param(
      [string]$BasePath,
      [string]$Name,
      [hashtable]$Overrides,
      [string]$ProfileDir
   )

   $inputs = Import-SetInputs $BasePath
   foreach($entry in $Overrides.GetEnumerator()) {
      Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
   }

   $profilePath = Join-Path $ProfileDir "$Name.set"
   ($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath $profilePath -Encoding ASCII

   return $profilePath
}

$baseProfiles = @(
   [pscustomobject]@{
      Base = "stability"
      Path = "outputs\CANDIDATE_RANGE_ELITE_STABILITY_DGF_LOSSBLOCK_PROFILE.set"
   },
   [pscustomobject]@{
      Base = "highprofit"
      Path = "outputs\CANDIDATE_RANGE_ELITE_HIGH_PROFIT_DGF_LOSSBLOCK_PROFILE.set"
   }
)

$variants = @(
   [pscustomobject]@{
      Suffix = "peaktrail_off"
      Description = "Disable global equity profit peak trail to test whether it caused the continuous-account stall."
      Overrides = @{
         InpUseEquityProfitPeakTrail = "false"
      }
   },
   [pscustomobject]@{
      Suffix = "peaktrail_8p_50gb"
      Description = "Keep peak-trail risk control, but only after an 8% account gain with 50% peak-profit giveback."
      Overrides = @{
         InpUseEquityProfitPeakTrail = "true"
         InpEquityProfitPeakTrailMinProfitPercent = "8.00"
         InpEquityProfitPeakTrailGivebackPercent = "50.0"
      }
   }
)

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$packagePath = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packagePath

$configDir = Join-Path $packagePath "configs"
$profileDir = Join-Path $packagePath "profiles"
$reportDir = Join-Path $packagePath "reports_here"
$sourceDir = Join-Path $packagePath "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queue = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0

foreach($base in $baseProfiles) {
   $basePath = Resolve-RepoPath $base.Path
   if(!(Test-Path -LiteralPath $basePath)) {
      throw "Base profile missing: $basePath"
   }

   foreach($variant in $variants) {
      $rank++
      $candidate = "lossblock_{0}_{1}" -f $base.Base, $variant.Suffix
      $profilePath = New-ProbeProfile -BasePath $basePath -Name $candidate -Overrides $variant.Overrides -ProfileDir $profileDir
      $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
      $inputs = Import-SetInputs $profilePath

      $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $candidate, $Window, $Model
      $reportName = "{0}_{1}_m{2}" -f $candidate, $Window, $Model
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName -From $From -To $To -Inputs $inputs -Model $Model

      $queue.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate
         Base = $base.Base
         Variant = $variant.Suffix
         Description = $variant.Description
         Window = $Window
         From = $From
         To = $To
         Model = $Model
         Config = "configs\$configName"
         ExpectedReportName = $reportName
         ProfileSnapshot = "profiles\$candidate.set"
         ProfileSha256 = $profileHash
         SourceSha256 = $sourceHash
         StopRule = "Reject if continuous Model4 remains sparse, red, or drawdown is unacceptable."
      }) | Out-Null

      $runRows.Add([pscustomobject]@{
         QueueRank = $rank
         Candidate = $candidate
         Phase = "peak_trail_unblock_probe"
         PhaseLabel = "Peak-trail unblock continuous Model$Model"
         Window = $Window
         Model = $Model
         PackageConfig = "$PackageDir\configs\$configName"
         SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName
         ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash
         StopRule = "Reject if continuous Model4 remains sparse, red, or drawdown is unacceptable."
      }) | Out-Null
   }
}

$queuePath = Resolve-RepoPath "outputs\PEAK_TRAIL_UNBLOCK_PROBE_QUEUE.csv"
$manifestPath = Resolve-RepoPath "outputs\PEAK_TRAIL_UNBLOCK_PROBE_PACKAGE_MANIFEST.csv"
$mdPath = Resolve-RepoPath "outputs\PEAK_TRAIL_UNBLOCK_PROBE_PACKAGE.md"
$queue | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Peak-Trail Unblock Probe Package")
$md.Add("")
$md.Add("Offline package builder only. This does not launch MT5.")
$md.Add("")
$md.Add("- Purpose: test whether the global equity profit peak trail caused the continuous-account stall after August 2019.")
$md.Add(("- Window: ``{0}`` to ``{1}``" -f $From, $To))
$md.Add(("- Model: ``{0}``" -f $Model))
$md.Add(("- Source hash: ``{0}``" -f $sourceHash))
$md.Add("")
$md.Add("## Candidates")
$md.Add("")
$md.Add("| Rank | Candidate | Profile SHA-256 | Description |")
$md.Add("| ---: | --- | --- | --- |")
foreach($row in $queue) {
   $md.Add(("| {0} | ``{1}`` | ``{2}`` | {3} |" -f $row.QueueRank, $row.Candidate, $row.ProfileSha256, $row.Description))
}
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   PackageDir = $PackageDir
   QueueManifest = "outputs\PEAK_TRAIL_UNBLOCK_PROBE_QUEUE.csv"
   PackageManifest = "outputs\PEAK_TRAIL_UNBLOCK_PROBE_PACKAGE_MANIFEST.csv"
   Markdown = "outputs\PEAK_TRAIL_UNBLOCK_PROBE_PACKAGE.md"
   Rows = $rank
   SourceHash = $sourceHash
}
