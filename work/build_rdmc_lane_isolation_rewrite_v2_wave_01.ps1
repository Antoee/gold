$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $repo 'outputs\rdmc_lane_isolation_rewrite_v2_package\source\Professional_XAUUSD_EA.mq5'
$profile = Join-Path $repo 'outputs\rdmc_lane_isolation_rewrite_v2_package\profiles\rdmc_lane_isolation_rewrite_v2.set'
$baseManifest = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_01_MANIFEST.csv'
$package = Join-Path $repo 'outputs\rdmc_lane_isolation_rewrite_v2_package'
$configs = Join-Path $package 'configs'
$reports = Join-Path $package 'reports_here'
$manifest = Join-Path $repo 'outputs\RDMC_LANE_ISOLATION_REWRITE_V2_WAVE_01_MANIFEST.csv'
$expectedSource = '1376E383DBB4A040DBC14337EA736DBFA4417C3B5D36DD629205665B9B81E569'
$expectedProfile = '6C01552D24702869C9E950846D96A74469E958B08E5D176FA34792D44D9224F0'

if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSource) { throw 'Rewrite source identity changed.' }
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedProfile) { throw 'Rewrite profile identity changed.' }
$inputs = Import-SetInputs -Path $profile
if($inputs.Keys.Count -ne 600) { throw "Expected 600 rewrite profile inputs, found $($inputs.Keys.Count)." }
$baseRows = @(Import-Csv -LiteralPath $baseManifest | Sort-Object { [int]$_.QueueRank })
if($baseRows.Count -ne 2 -or ($baseRows.Window -join ',') -ne '2019,2022') { throw 'Frozen predecessor Wave 1 shape changed.' }

New-Item -ItemType Directory -Path $configs,$reports -Force | Out-Null
$existingEvidence = @(Get-ChildItem -LiteralPath $reports -File -ErrorAction SilentlyContinue | Where-Object Name -ne 'README.md')
if($existingEvidence.Count -gt 0) { throw 'Rewrite Wave 1 evidence already exists; refusing to rebuild its frozen queue.' }

$rows = foreach($base in $baseRows) {
   $rank = [int]$base.QueueRank
   $reportName = 'rdmc_lir2_w01_m1_critical_' + $base.Window
   $config = Join-Path $configs ('{0:D3}_{1}.ini' -f $rank,$reportName)
   Write-SeasonalTesterConfig -Path $config -ReportRoot $reports -ReportName $reportName `
      -From $base.From -To $base.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
   [pscustomobject][ordered]@{
      QueueRank = $rank
      Wave = 1
      Role = 'critical'
      Candidate = 'rdmc_lane_isolation_rewrite_v2'
      Profile = 'rdmc_lane_isolation_rewrite_v2'
      Set = 'frozen_lane_isolation_rewrite'
      Window = $base.Window
      From = $base.From
      To = $base.To
      Model = 1
      Deposit = 10000
      InitialDeposit = 10000
      PackageConfig = $config.Substring($repo.Length + 1)
      SourceConfig = $config.Substring($repo.Length + 1)
      ExpectedReportName = $reportName
      ReportDestination = (Join-Path $reports $reportName).Substring($repo.Length + 1)
      ProfileSha256 = $expectedProfile
      SourceSha256 = $expectedSource
      ConfigSha256 = (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant()
      MinNetProfit = $base.MinNetProfit
      MinProfitFactor = $base.MinProfitFactor
      MinTrades = $base.MinTrades
      MaxDrawdownPercent = $base.MaxDrawdownPercent
      MinRecoveryFactor = $base.MinRecoveryFactor
      MinCagrPercent = $base.MinCagrPercent
      MaxParallelism = 2
      StopRule = $base.StopRule
      Status = 'FROZEN_WAVE_01_ONLY'
   }
}
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
@(
   'Only the guarded local runner may add reports here.',
   'Every report requires matching config, source, compiled-binary, and report SHA-256 evidence.'
) | Set-Content -LiteralPath (Join-Path $reports 'README.md') -Encoding ASCII

[pscustomobject]@{
   Status = 'FROZEN'
   Rows = $rows.Count
   Windows = $rows.Window -join ','
   Inputs = $inputs.Keys.Count
   SourceSha256 = $expectedSource
   ProfileSha256 = $expectedProfile
   ManifestSha256 = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
   MQL5Launched = $false
   RealAccountApproved = $false
}
