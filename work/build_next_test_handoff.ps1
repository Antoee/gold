param(
   [string]$BatchCsv = "outputs\NEXT_PROFIT_SEARCH_BATCH.csv",
   [string]$OutDir = "outputs\next_test_handoff",
   [string]$ZipPath = "outputs\next_test_handoff.zip"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if(!(Test-Path -LiteralPath $BatchCsv)) {
   throw "Batch CSV not found: $BatchCsv"
}

$batch = Import-Csv -LiteralPath $BatchCsv
if($batch.Count -eq 0) {
   throw "Batch CSV has no rows: $BatchCsv"
}

$configDir = Join-Path $OutDir "configs"
if(Test-Path -LiteralPath $OutDir) {
   Remove-Item -LiteralPath $OutDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

$manifestRows = New-Object System.Collections.Generic.List[object]

foreach($row in ($batch | Sort-Object {[int]$_.Rank})) {
   $source = [string]$row.Config
   if(!(Test-Path -LiteralPath $source)) {
      throw "Config listed in batch does not exist: $source"
   }

   $rank = ([int]$row.Rank).ToString("000")
   $targetName = "{0}_{1}_{2}_{3}_{4}.ini" -f $rank, $row.Profile, $row.Set, $row.Window, $row.Phase
   $targetName = $targetName -replace '[^A-Za-z0-9_.-]', '_'
   $target = Join-Path $configDir $targetName
   Copy-Item -LiteralPath $source -Destination $target -Force

   $manifestRows.Add([pscustomobject]@{
      Rank = [int]$row.Rank
      Profile = $row.Profile
      Phase = $row.Phase
      Set = $row.Set
      Window = $row.Window
      Model = $row.Model
      Role = $row.Role
      Reason = $row.Reason
      From = $row.From
      To = $row.To
      SourceConfig = $source
      HandoffConfig = $target
      ExpectedReportName = $row.ExpectedReportName
   }) | Out-Null
}

$handoffCsv = Join-Path $OutDir "HANDOFF_MANIFEST.csv"
$manifestRows | Export-Csv -LiteralPath $handoffCsv -NoTypeInformation

$readme = New-Object System.Collections.Generic.List[string]
$readme.Add("# Next Test Handoff") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("Generated without launching MT5. This folder is a handoff package for the next safe testing window.") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("- Source batch: ``$BatchCsv``") | Out-Null
$readme.Add("- Config count: $($manifestRows.Count)") | Out-Null
$readme.Add("- Config folder: ``configs/``") | Out-Null
$readme.Add("- Manifest: ``HANDOFF_MANIFEST.csv``") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("## Safety") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("Do not run these locally while MT5 is locked for PC usability. Local MT5 launch requires `ALLOW_MT5_FOCUS_RISK=1` and `work\ALLOW_MT5_LOCAL_LAUNCH.unlock`, and should only be enabled after a controlled hidden-desktop test.") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("## Run Order") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("| Rank | Profile | Phase | Set | Window | Model | Config | Expected Report |") | Out-Null
$readme.Add("|---:|---|---|---|---|---:|---|---|") | Out-Null
foreach($row in ($manifestRows | Sort-Object Rank)) {
   $configName = Split-Path -Leaf $row.HandoffConfig
   $readme.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Phase) | $($row.Set) | $($row.Window) | $($row.Model) | ``configs/$configName`` | ``$($row.ExpectedReportName)`` |") | Out-Null
}
$readme.Add("") | Out-Null
$readme.Add("## After Reports Exist") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("1. Export reports into `outputs/`.") | Out-Null
$readme.Add("2. Run the profit-search collector command from `NEXT_VALIDATION_RUNBOOK.md`.") | Out-Null
$readme.Add("3. Rerun `work/analyze_profit_search.ps1`.") | Out-Null
$readme.Add("4. Rerun `work/build_next_profit_search_batch.ps1`.") | Out-Null
$readme.Add("5. For any promising profile, run `work/build_profit_promotion_packet.ps1 -Profile <profile_name>`.") | Out-Null

Set-Content -LiteralPath (Join-Path $OutDir "README.md") -Value $readme -Encoding UTF8

if(Test-Path -LiteralPath $ZipPath) {
   Remove-Item -LiteralPath $ZipPath -Force
}
$zipParent = Split-Path -Parent $ZipPath
if(!(Test-Path -LiteralPath $zipParent)) {
   New-Item -ItemType Directory -Force -Path $zipParent | Out-Null
}
$zipItems = Get-ChildItem -LiteralPath $OutDir -Force
if($zipItems.Count -eq 0) {
   throw "No handoff files found to compress in $OutDir"
}
Compress-Archive -LiteralPath $zipItems.FullName -DestinationPath $ZipPath -Force
if(!(Test-Path -LiteralPath $ZipPath)) {
   throw "Zip was not created: $ZipPath"
}

[pscustomobject]@{
   ConfigCount = $manifestRows.Count
   HandoffDir = $OutDir
   ZipPath = $ZipPath
   Manifest = $handoffCsv
}
