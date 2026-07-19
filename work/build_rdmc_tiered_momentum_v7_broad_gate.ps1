$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_package\source\Professional_XAUUSD_EA.mq5'
$profile = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_package\profiles\rdmc_tiered_momentum_v7.set'
$package = Join-Path $repo 'outputs\rdmc_tiered_momentum_v7_broad_package'
$configs = Join-Path $package 'configs'
$reports = Join-Path $package 'reports_here'
$packageSource = Join-Path $package 'source\Professional_XAUUSD_EA.mq5'
$packageProfile = Join-Path $package 'profiles\rdmc_tiered_momentum_v7.set'
$manifest = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_GATE_MANIFEST.csv'
$decisionCsv = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_DECISION_FIXTURE.csv'
$decisionMd = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_DECISION.md'
$contract = Join-Path $repo 'outputs\RDMC_TIERED_MOMENTUM_V7_BROAD_CONTRACT.md'
$expectedSource = '27CAD37CD903032335DA570CDEC75AC39C2EA6BEF04CA264D1586EDC866F6AF6'
$expectedProfile = '6E2EF7B031FF30216876E0232A8CE9D6BFC9F7913A863103DC9B12C1A04A100C'

if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSource) { throw 'Tiered-momentum source identity changed.' }
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedProfile) { throw 'Tiered-momentum profile identity changed.' }
$inputs = Import-SetInputs -Path $profile
if($inputs.Keys.Count -ne 614) { throw "Expected 614 profile inputs, found $($inputs.Keys.Count)." }

New-Item -ItemType Directory -Path $configs,$reports,(Split-Path -Parent $packageSource),(Split-Path -Parent $packageProfile) -Force | Out-Null
$existingEvidence = @(Get-ChildItem -LiteralPath $reports -File -ErrorAction SilentlyContinue | Where-Object Name -ne 'README.md')
if($existingEvidence.Count -gt 0) { throw 'Broad-gate evidence already exists; refusing to rebuild the frozen queue.' }
Copy-Item -LiteralPath $source -Destination $packageSource -Force
Copy-Item -LiteralPath $profile -Destination $packageProfile -Force

$specs = @(
   [pscustomobject]@{ Rank=1; Wave=1; Role='broad'; Window='older_2015_2018'; From='2015.01.01'; To='2018.12.31'; Model=1; MinPF=1.15; MinTrades=60; MaxDD=3.0; MinRecovery=1.0; MinCagr=0.0 },
   [pscustomobject]@{ Rank=2; Wave=1; Role='broad'; Window='middle_2019_2022'; From='2019.01.01'; To='2022.12.31'; Model=1; MinPF=1.10; MinTrades=50; MaxDD=3.0; MinRecovery=0.5; MinCagr=0.0 },
   [pscustomobject]@{ Rank=3; Wave=1; Role='broad'; Window='recent_2023_2026'; From='2023.01.01'; To='2026.07.12'; Model=1; MinPF=1.10; MinTrades=40; MaxDD=3.0; MinRecovery=0.5; MinCagr=0.0 },
   [pscustomobject]@{ Rank=4; Wave=1; Role='continuous'; Window='continuous_2015_2026'; From='2015.01.01'; To='2026.07.12'; Model=1; MinPF=1.20; MinTrades=160; MaxDD=4.0; MinRecovery=1.5; MinCagr=0.25 },
   [pscustomobject]@{ Rank=5; Wave=2; Role='critical'; Window='2019'; From='2019.01.01'; To='2019.12.31'; Model=4; MinPF=1.05; MinTrades=15; MaxDD=3.0; MinRecovery=0.0; MinCagr=0.0 },
   [pscustomobject]@{ Rank=6; Wave=2; Role='critical'; Window='2022'; From='2022.01.01'; To='2022.12.31'; Model=4; MinPF=1.05; MinTrades=15; MaxDD=3.0; MinRecovery=0.0; MinCagr=0.0 },
   [pscustomobject]@{ Rank=7; Wave=3; Role='broad'; Window='older_2015_2018'; From='2015.01.01'; To='2018.12.31'; Model=4; MinPF=1.15; MinTrades=60; MaxDD=4.0; MinRecovery=1.0; MinCagr=0.0 },
   [pscustomobject]@{ Rank=8; Wave=3; Role='broad'; Window='middle_2019_2022'; From='2019.01.01'; To='2022.12.31'; Model=4; MinPF=1.15; MinTrades=50; MaxDD=4.0; MinRecovery=0.75; MinCagr=0.0 },
   [pscustomobject]@{ Rank=9; Wave=3; Role='broad'; Window='recent_2023_2026'; From='2023.01.01'; To='2026.07.12'; Model=4; MinPF=1.15; MinTrades=40; MaxDD=4.0; MinRecovery=0.75; MinCagr=0.0 },
   [pscustomobject]@{ Rank=10; Wave=3; Role='continuous'; Window='continuous_2015_2026'; From='2015.01.01'; To='2026.07.12'; Model=4; MinPF=1.20; MinTrades=160; MaxDD=4.0; MinRecovery=1.5; MinCagr=0.25 }
)

$rows = foreach($spec in $specs) {
   $reportName = 'rdmc_tmv7b_w{0:D2}_m{1}_{2}_{3}' -f $spec.Wave,$spec.Model,$spec.Role,$spec.Window
   $config = Join-Path $configs ('{0:D3}_{1}.ini' -f $spec.Rank,$reportName)
   Write-SeasonalTesterConfig -Path $config -ReportRoot $reports -ReportName $reportName `
      -From $spec.From -To $spec.To -Inputs $inputs -Model $spec.Model -Deposit 10000 -Period 15
   [pscustomobject][ordered]@{
      QueueRank = $spec.Rank
      Wave = $spec.Wave
      Role = $spec.Role
      Candidate = 'rdmc_tiered_momentum_v7_broad'
      Profile = 'rdmc_tiered_momentum_v7'
      Set = 'frozen_tiered_momentum'
      Window = $spec.Window
      From = $spec.From
      To = $spec.To
      Model = $spec.Model
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
      MinProfitFactor = $spec.MinPF
      MinTrades = $spec.MinTrades
      MaxDrawdownPercent = $spec.MaxDD
      MinRecoveryFactor = $spec.MinRecovery
      MinCagrPercent = $spec.MinCagr
      MaxParallelism = 1
      StopRule = 'Reject the exact identity if any completed row is red or fails its frozen quality, activity, drawdown, recovery, or CAGR floor.'
      Status = 'FROZEN_STAGED_GATE'
   }
}
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()

@(
   'Only the guarded local runner may add reports here.',
   'Every report requires matching config, source, compiled-binary, and report SHA-256 evidence.'
) | Set-Content -LiteralPath (Join-Path $reports 'README.md') -Encoding ASCII
@(
   '# RDMC Tiered Momentum v7 Broad Gate', '',
   '**FROZEN RESEARCH QUALIFICATION. NOT A NEW BEST OR REAL-MONEY APPROVAL.**', '',
   '- Wave 1: four disjoint/continuous Model1 rows; Model1 can reject only.',
   '- Wave 2: 2019 and 2022 Model4 real-tick critical rows.',
   '- Wave 3: three disjoint Model4 eras plus continuous Model4.',
   '- All rows use `$10,000`, the exact v7 source/profile, one position maximum, and static lane-risk ceilings.',
   '- A pass still requires annual restarts, cost/Monte Carlo stress, broker variation, and valid forward evidence.'
) | Set-Content -LiteralPath (Join-Path $package 'README.md') -Encoding ASCII
@(
   '# RDMC Tiered Momentum v7 Broad Contract', '',
   '**The exact three-window pass is being tested for broad and real-tick transferability without tuning.**', '',
   "- Source SHA-256: ``$expectedSource``",
   "- Profile SHA-256: ``$expectedProfile``",
   "- Manifest SHA-256: ``$manifestHash``",
   '- Capital contract: `$10,000 USD`',
   '- Chart: `XAUUSD M15`',
   '- Frozen cutoff: `2026-07-12`',
   '- No martingale, grid, averaging down, recovery sizing, or real-account permission.', '',
   'Wave 1 must pass before any real-tick work. Wave 2 must pass before broad real ticks. Any completed losing row terminally rejects this identity. Thresholds were frozen from the older-data activity rate and risk-first quality floors before recent/broad results were opened.'
) | Set-Content -LiteralPath $contract -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status = 'AWAITING_WAVE_01_REPORTS'
   CurrentWave = 1
   PassedRows = 0
   TotalRows = 10
   ReportsPresent = 0
   TerminalRejection = $false
   BroadGatePass = $false
   NextAction = 'RUN_FROZEN_MODEL1_BROAD_GATE_ONLY'
   LaunchLocked = $true
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
   ManifestSha256 = $manifestHash
   SourceSha256 = $expectedSource
   ProfileSha256 = $expectedProfile
}
$decision | Export-Csv -LiteralPath $decisionCsv -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Tiered Momentum v7 Broad Decision', '',
   '**Status: AWAITING_WAVE_01_REPORTS. No new best, forward substitution, or real-money approval.**', '',
   '- Admitted work: `Model1 broad/continuous only`',
   '- Reports: `0/10`',
   "- Manifest SHA-256: ``$manifestHash``"
) | Set-Content -LiteralPath $decisionMd -Encoding ASCII

[pscustomobject]@{
   Status = 'FROZEN'
   Rows = $rows.Count
   WaveCounts = (@(1..3 | ForEach-Object { @($rows | Where-Object Wave -eq $_).Count }) -join ',')
   SourceSha256 = $expectedSource
   ProfileSha256 = $expectedProfile
   ManifestSha256 = $manifestHash
   MQL5Launched = $false
   RealAccountApproved = $false
}
