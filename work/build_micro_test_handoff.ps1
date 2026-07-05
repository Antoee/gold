param(
   [string]$BatchPath = "outputs\NEXT_PROFIT_SEARCH_BATCH.csv",
   [string]$OutDir = "outputs\micro_test_handoff",
   [string]$OutManifest = "outputs\micro_test_handoff\HANDOFF_MANIFEST.csv",
   [string]$OutReadme = "outputs\micro_test_handoff\README.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Copy-HandoffConfig {
   param(
      [object]$Row,
      [int]$Rank,
      [string]$DestinationDir
   )

   $source = [string]$Row.Config
   if(!(Test-Path -LiteralPath $source)) {
      throw "Source config missing: $source"
   }

   $safeProfile = ([string]$Row.Profile) -replace '[^A-Za-z0-9_.-]', '_'
   $safeSet = ([string]$Row.Set) -replace '[^A-Za-z0-9_.-]', '_'
   $safeWindow = ([string]$Row.Window) -replace '[^A-Za-z0-9_.-]', '_'
   $safePhase = ([string]$Row.Phase) -replace '[^A-Za-z0-9_.-]', '_'
   $dest = Join-Path $DestinationDir ("{0:000}_{1}_{2}_{3}_{4}.ini" -f $Rank, $safeProfile, $safeSet, $safeWindow, $safePhase)
   Copy-Item -LiteralPath $source -Destination $dest -Force
   return $dest
}

if(!(Test-Path -LiteralPath $BatchPath)) {
   throw "Batch file not found: $BatchPath"
}

$batch = @(Import-Csv -LiteralPath $BatchPath)
if($batch.Count -eq 0) {
   throw "Batch file has no rows: $BatchPath"
}

$windows = @("2024_Q1", "2024_Q3", "2025_Q2", "2025_Q3")
$candidateProfile = [string](($batch | Sort-Object {[int]$_.Rank} | Where-Object { $_.Profile -ne "baseline_promoted" -and $_.Set -eq "stress" } | Select-Object -First 1).Profile)
if([string]::IsNullOrWhiteSpace($candidateProfile)) {
   throw "No non-baseline stress candidate found in batch."
}

$configDir = Join-Path $OutDir "configs"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

$manifestRows = New-Object System.Collections.Generic.List[object]
$rank = 1
foreach($window in $windows) {
   foreach($profile in @($candidateProfile, "baseline_promoted")) {
      $row = $batch | Where-Object { $_.Profile -eq $profile -and $_.Set -eq "stress" -and $_.Window -eq $window } | Sort-Object {[int]$_.Rank} | Select-Object -First 1
      if($null -eq $row) {
         throw "Missing paired row for profile=$profile window=$window"
      }

      $destConfig = Copy-HandoffConfig -Row $row -Rank $rank -DestinationDir $configDir
      $manifestRows.Add([pscustomobject]@{
         Rank = $rank
         SourceRank = [int]$row.Rank
         Profile = $row.Profile
         Phase = $row.Phase
         Model = $row.Model
         Set = $row.Set
         Window = $row.Window
         From = $row.From
         To = $row.To
         HandoffConfig = $destConfig
         SourceConfig = $row.Config
         ExpectedReportName = $row.ExpectedReportName
         GuardrailStatus = $row.GuardrailStatus
         GuardrailScore = $row.GuardrailScore
         RiskFlags = $row.RiskFlags
         OverfitFlags = $row.OverfitFlags
      }) | Out-Null
      $rank++
   }
}

$manifestRows | Export-Csv -LiteralPath $OutManifest -NoTypeInformation

$readme = New-Object System.Collections.Generic.List[string]
$readme.Add("# Micro Test Handoff") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("Fast first-pass validation for the top protected candidate against the current promoted baseline.") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("## Purpose") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("The full handoff is still the authority for promotion decisions. This micro handoff only answers whether the top candidate deserves more tester time.") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("## Test Pairing") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("Each stress window runs the candidate and baseline back-to-back:") | Out-Null
foreach($window in $windows) { $readme.Add("- $candidateProfile vs baseline_promoted on $window") | Out-Null }
$readme.Add("") | Out-Null
$readme.Add("## Decision Rule") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("If the protected candidate loses any paired stress window, keep the current promoted profile and deprioritize that candidate.") | Out-Null
$readme.Add("If it matches or improves every paired stress window, continue to the full 24-config handoff and phase-2 real ticks before considering promotion.") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("## Local Safety") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("This builder does not launch MT5. Do not run local MT5 tester jobs while normal PC use must remain uninterrupted.") | Out-Null
Set-Content -LiteralPath $OutReadme -Value $readme -Encoding UTF8

[pscustomobject]@{
   ConfigCount = $manifestRows.Count
   TopCandidate = $candidateProfile
   HandoffDir = $OutDir
   Manifest = $OutManifest
}
