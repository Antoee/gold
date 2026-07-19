$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_package\source\Professional_XAUUSD_EA.mq5'
$profile = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_package\profiles\rdmc_tiered_momentum_v7.set'
$baseManifest = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_01_MANIFEST.csv'
$package = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_package'
$configs = Join-Path $package 'configs'
$reports = Join-Path $package 'reports_here'
$manifest = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_GATE_MANIFEST.csv'
$expectedSource = '27CAD37CD903032335DA570CDEC75AC39C2EA6BEF04CA264D1586EDC866F6AF6'
$expectedProfile = '6E2EF7B031FF30216876E0232A8CE9D6BFC9F7913A863103DC9B12C1A04A100C'

if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSource) { throw 'Rewrite source identity changed.' }
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedProfile) { throw 'Rewrite profile identity changed.' }
$inputs = Import-SetInputs -Path $profile
if($inputs.Keys.Count -ne 614) { throw "Expected 614 rewrite profile inputs, found $($inputs.Keys.Count)." }
$baseRows = @(Import-Csv -LiteralPath $baseManifest | Sort-Object { [int]$_.QueueRank })
if($baseRows.Count -ne 2 -or ($baseRows.Window -join ',') -ne '2019,2022') { throw 'Frozen predecessor Wave 1 shape changed.' }

New-Item -ItemType Directory -Path $configs,$reports -Force | Out-Null
$existingEvidence = @(Get-ChildItem -LiteralPath $reports -File -ErrorAction SilentlyContinue | Where-Object Name -ne 'README.md')
if($existingEvidence.Count -gt 0) { throw 'Rewrite gate evidence already exists; refusing to rebuild its frozen queue.' }

$specs = @(
   [pscustomobject]@{
      QueueRank=1; Wave=1; Role='training'; Window='2015_2018'; From='2015.01.01'; To='2018.12.31'
      MinNetProfit=0.01; MinProfitFactor=1.15; MinTrades=60; MaxDrawdownPercent=3.0
      MinRecoveryFactor=1.0; MinCagrPercent=0.0; MaxParallelism=1
      StopRule='Reject before critical years if the older training era is not profitable, active, and risk-efficient.'
   },
   [pscustomobject]@{
      QueueRank=2; Wave=2; Role='critical'; Window='2019'; From=$baseRows[0].From; To=$baseRows[0].To
      MinNetProfit=$baseRows[0].MinNetProfit; MinProfitFactor=$baseRows[0].MinProfitFactor
      MinTrades=$baseRows[0].MinTrades; MaxDrawdownPercent=$baseRows[0].MaxDrawdownPercent
      MinRecoveryFactor=$baseRows[0].MinRecoveryFactor; MinCagrPercent=$baseRows[0].MinCagrPercent
      MaxParallelism=2; StopRule=$baseRows[0].StopRule
   },
   [pscustomobject]@{
      QueueRank=3; Wave=2; Role='critical'; Window='2022'; From=$baseRows[1].From; To=$baseRows[1].To
      MinNetProfit=$baseRows[1].MinNetProfit; MinProfitFactor=$baseRows[1].MinProfitFactor
      MinTrades=$baseRows[1].MinTrades; MaxDrawdownPercent=$baseRows[1].MaxDrawdownPercent
      MinRecoveryFactor=$baseRows[1].MinRecoveryFactor; MinCagrPercent=$baseRows[1].MinCagrPercent
      MaxParallelism=2; StopRule=$baseRows[1].StopRule
   }
)

$rows = foreach($spec in $specs) {
   $rank = [int]$spec.QueueRank
   $reportName = 'rdmc_tmv7_w{0:D2}_m1_{1}_{2}' -f ([int]$spec.Wave),$spec.Role,$spec.Window
   $config = Join-Path $configs ('{0:D3}_{1}.ini' -f $rank,$reportName)
   Write-SeasonalTesterConfig -Path $config -ReportRoot $reports -ReportName $reportName `
      -From $spec.From -To $spec.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
   [pscustomobject][ordered]@{
      QueueRank = $rank
      Wave = $spec.Wave
      Role = $spec.Role
      Candidate = 'rdmc_tiered_momentum_v7'
      Profile = 'rdmc_tiered_momentum_v7'
      Set = 'frozen_tiered_momentum'
      Window = $spec.Window
      From = $spec.From
      To = $spec.To
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
      MinNetProfit = $spec.MinNetProfit
      MinProfitFactor = $spec.MinProfitFactor
      MinTrades = $spec.MinTrades
      MaxDrawdownPercent = $spec.MaxDrawdownPercent
      MinRecoveryFactor = $spec.MinRecoveryFactor
      MinCagrPercent = $spec.MinCagrPercent
      MaxParallelism = $spec.MaxParallelism
      StopRule = $spec.StopRule
      Status = 'FROZEN_STAGED_GATE'
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
   Waves = (@($rows.Wave | Sort-Object -Unique) -join ',')
   Windows = $rows.Window -join ','
   Inputs = $inputs.Keys.Count
   SourceSha256 = $expectedSource
   ProfileSha256 = $expectedProfile
   ManifestSha256 = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
   MQL5Launched = $false
   RealAccountApproved = $false
}
