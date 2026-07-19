$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $repo 'outputs\rdmc_momentum_loss_decay_v3_package\source\Professional_XAUUSD_EA.mq5'
$profile = Join-Path $repo 'outputs\rdmc_momentum_loss_decay_v3_package\profiles\rdmc_momentum_loss_decay_v3.set'
$baseManifest = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_01_MANIFEST.csv'
$package = Join-Path $repo 'outputs\rdmc_momentum_loss_decay_v3_package'
$configs = Join-Path $package 'configs'
$reports = Join-Path $package 'reports_here'
$manifest = Join-Path $repo 'outputs\RDMC_MOMENTUM_LOSS_DECAY_V3_WAVE_01_MANIFEST.csv'
$expectedSource = '59A872EB7D4DA5159CDCAED791A51DF1C118F3E34EE460F0242BA486D7977370'
$expectedProfile = 'ED26F488D5E3025093714BF1C376AEEF95868E60334ACFFF20CD375632D9028D'

if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSource) { throw 'Rewrite source identity changed.' }
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedProfile) { throw 'Rewrite profile identity changed.' }
$inputs = Import-SetInputs -Path $profile
if($inputs.Keys.Count -ne 601) { throw "Expected 601 rewrite profile inputs, found $($inputs.Keys.Count)." }
$baseRows = @(Import-Csv -LiteralPath $baseManifest | Sort-Object { [int]$_.QueueRank })
if($baseRows.Count -ne 2 -or ($baseRows.Window -join ',') -ne '2019,2022') { throw 'Frozen predecessor Wave 1 shape changed.' }

New-Item -ItemType Directory -Path $configs,$reports -Force | Out-Null
$existingEvidence = @(Get-ChildItem -LiteralPath $reports -File -ErrorAction SilentlyContinue | Where-Object Name -ne 'README.md')
if($existingEvidence.Count -gt 0) { throw 'Rewrite Wave 1 evidence already exists; refusing to rebuild its frozen queue.' }

$rows = foreach($base in $baseRows) {
   $rank = [int]$base.QueueRank
   $reportName = 'rdmc_mld3_w01_m1_critical_' + $base.Window
   $config = Join-Path $configs ('{0:D3}_{1}.ini' -f $rank,$reportName)
   Write-SeasonalTesterConfig -Path $config -ReportRoot $reports -ReportName $reportName `
      -From $base.From -To $base.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
   [pscustomobject][ordered]@{
      QueueRank = $rank
      Wave = 1
      Role = 'critical'
      Candidate = 'rdmc_momentum_loss_decay_v3'
      Profile = 'rdmc_momentum_loss_decay_v3'
      Set = 'frozen_momentum_loss_decay'
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
