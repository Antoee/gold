$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_package\source\Professional_XAUUSD_EA.mq5'
$profile = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_package\profiles\rdmc_tiered_momentum_v7.set'
$broadDecision = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_DECISION_FIXTURE.csv'
$package = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_annual_package'
$configs = Join-Path $package 'configs'
$reports = Join-Path $package 'reports_here'
$packageSource = Join-Path $package 'source\Professional_XAUUSD_EA.mq5'
$packageProfile = Join-Path $package 'profiles\rdmc_tiered_momentum_v7.set'
$manifest = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_ANNUAL_GATE_MANIFEST.csv'
$decisionCsv = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_ANNUAL_DECISION_FIXTURE.csv'
$decisionMd = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_ANNUAL_DECISION.md'
$contract = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_ANNUAL_CONTRACT.md'
$expectedSource = '27CAD37CD903032335DA570CDEC75AC39C2EA6BEF04CA264D1586EDC866F6AF6'
$expectedProfile = '6E2EF7B031FF30216876E0232A8CE9D6BFC9F7913A863103DC9B12C1A04A100C'

if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSource) { throw 'Tiered-momentum source identity changed.' }
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedProfile) { throw 'Tiered-momentum profile identity changed.' }
$broad = @(Import-Csv -LiteralPath $broadDecision)
if($broad.Count -ne 1 -or $broad[0].BroadGatePass -ne 'True' -or $broad[0].Status -ne 'BROAD_MODEL4_GATE_PASS_PENDING_ANNUAL_AND_STRESS') {
   throw 'Annual gate requires the exact completed broad Model4 pass.'
}
$inputs = Import-SetInputs -Path $profile
if($inputs.Keys.Count -ne 614) { throw "Expected 614 profile inputs, found $($inputs.Keys.Count)." }

New-Item -ItemType Directory -Path $configs,$reports,(Split-Path -Parent $packageSource),(Split-Path -Parent $packageProfile) -Force | Out-Null
$existingEvidence = @(Get-ChildItem -LiteralPath $reports -File -ErrorAction SilentlyContinue | Where-Object Name -ne 'README.md')
if($existingEvidence.Count -gt 0) { throw 'Annual-gate evidence already exists; refusing to rebuild the frozen queue.' }
Copy-Item -LiteralPath $source -Destination $packageSource -Force
Copy-Item -LiteralPath $profile -Destination $packageProfile -Force

$years = @(
   [pscustomobject]@{ Rank=1; Wave=1; Window='2017'; From='2017.01.01'; To='2017.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=2; Wave=1; Window='2025'; From='2025.01.01'; To='2025.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=3; Wave=2; Window='2015'; From='2015.01.01'; To='2015.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=4; Wave=2; Window='2016'; From='2016.01.01'; To='2016.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=5; Wave=2; Window='2018'; From='2018.01.01'; To='2018.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=6; Wave=2; Window='2019'; From='2019.01.01'; To='2019.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=7; Wave=2; Window='2020'; From='2020.01.01'; To='2020.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=8; Wave=2; Window='2021'; From='2021.01.01'; To='2021.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=9; Wave=2; Window='2022'; From='2022.01.01'; To='2022.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=10; Wave=2; Window='2023'; From='2023.01.01'; To='2023.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=11; Wave=2; Window='2024'; From='2024.01.01'; To='2024.12.31'; MinTrades=1 },
   [pscustomobject]@{ Rank=12; Wave=2; Window='2026_ytd'; From='2026.01.01'; To='2026.07.12'; MinTrades=1 }
)

$rows = foreach($year in $years) {
   $reportName = 'rdmc_tmv7a_w{0:D2}_m4_annual_{1}' -f $year.Wave,$year.Window
   $config = Join-Path $configs ('{0:D3}_{1}.ini' -f $year.Rank,$reportName)
   Write-SeasonalTesterConfig -Path $config -ReportRoot $reports -ReportName $reportName `
      -From $year.From -To $year.To -Inputs $inputs -Model 4 -Deposit 10000 -Period 15
   [pscustomobject][ordered]@{
      QueueRank = $year.Rank
      Wave = $year.Wave
      Role = 'annual'
      Candidate = 'rdmc_tiered_momentum_v7_annual'
      Profile = 'rdmc_tiered_momentum_v7'
      Set = 'frozen_tiered_momentum'
      Window = $year.Window
      From = $year.From
      To = $year.To
      Model = 4
      Deposit = 10000
      InitialDeposit = 10000
      PackageConfig = $config.Substring($repo.Length + 1)
      SourceConfig = $config.Substring($repo.Length + 1)
      ExpectedReportName = $reportName
      ReportDestination = (Join-Path $reports $reportName).Substring($repo.Length + 1)
      ProfileSha256 = $expectedProfile
      SourceSha256 = $expectedSource
      ConfigSha256 = (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant()
      MinNetProfit = 0.01
      MinProfitFactor = 1.0
      MinTrades = $year.MinTrades
      MaxDrawdownPercent = 3.0
      MinRecoveryFactor = 0.0
      MinCagrPercent = 0.0
      MaxParallelism = 1
      StopRule = 'Every independent annual restart must be profitable with PF at least 1.0 and drawdown no higher than 3%.'
      Status = 'FROZEN_STAGED_GATE'
   }
}
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
@('Only the guarded local runner may add reports here.','Every report requires exact identity sidecar evidence.') |
   Set-Content -LiteralPath (Join-Path $reports 'README.md') -Encoding ASCII
@(
   '# RDMC Tiered Momentum v7 Annual Contract', '',
   '**ANNUAL RESTART ROBUSTNESS TEST. NOT REAL-MONEY APPROVAL.**', '',
   "- Source SHA-256: ``$expectedSource``",
   "- Profile SHA-256: ``$expectedProfile``",
   "- Manifest SHA-256: ``$manifestHash``",
   '- Wave 1 tests the two losing calendar segments observed inside the frozen continuous ledger: `2017` and `2025`.',
   '- Wave 2 remains closed unless both independent stress-year restarts are profitable.',
   '- Every annual restart must have positive net, PF at least `1.0`, at least one trade, and drawdown no higher than `3%`.',
   '- Run order uses observed weakness only to save compute; it does not change the EA or thresholds.'
) | Set-Content -LiteralPath $contract -Encoding ASCII
@('Frozen exact-identity annual Model4 package.','No hand-edited report evidence is admissible.') |
   Set-Content -LiteralPath (Join-Path $package 'README.md') -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status='AWAITING_WAVE_01_REPORTS'; CurrentWave=1; PassedRows=0; TotalRows=12; ReportsPresent=0
   TerminalRejection=$false; AnnualGatePass=$false; NextAction='RUN_FROZEN_2017_AND_2025_RESTARTS_ONLY'
   LaunchLocked=$true; ForwardCandidateChanged=$false; RealAccountApproved=$false
   ManifestSha256=$manifestHash; SourceSha256=$expectedSource; ProfileSha256=$expectedProfile
}
$decision | Export-Csv -LiteralPath $decisionCsv -NoTypeInformation -Encoding ASCII
@('# RDMC Tiered Momentum v7 Annual Decision','','**Status: AWAITING_WAVE_01_REPORTS. No real-money approval.**','','- Admitted years: `2017, 2025`',"- Manifest SHA-256: ``$manifestHash``") |
   Set-Content -LiteralPath $decisionMd -Encoding ASCII

[pscustomobject]@{ Status='FROZEN'; Rows=12; WaveCounts='2,10'; ManifestSha256=$manifestHash; MQL5Launched=$false; RealAccountApproved=$false }
