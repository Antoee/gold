[CmdletBinding()]
param(
   [string]$BaseManifestPath = 'outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv',
   [string]$SourcePath = 'outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5',
   [string]$ProfilePath = 'outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_v1.set',
   [string]$PackagePath = 'outputs\rdmc_money_ready_gate_repair_executable_package',
   [string]$ManifestPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_MANIFEST.csv',
   [string]$ContractPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_CONTRACT.md',
   [string]$DecisionCsvPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_DECISION.md',
   [string]$RunPlanCsvPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RUN_PLAN.csv',
   [string]$RunPlanMarkdownPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RUN_PLAN.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$expectedBaseManifestHash = '4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A'
$expectedSourceHash = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
$expectedProfileHash = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
$expectedManifestHash = 'EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972'

function Resolve-RepoPath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo ($Path -replace '/', '\')
}

& (Join-Path $PSScriptRoot 'build_rdmc_money_ready_gate_repair.ps1') | Out-Null
& (Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair.ps1') | Out-Null

$baseManifest = Resolve-RepoPath $BaseManifestPath
$source = Resolve-RepoPath $SourcePath
$profile = Resolve-RepoPath $ProfilePath
$package = Resolve-RepoPath $PackagePath
$manifest = Resolve-RepoPath $ManifestPath
$contract = Resolve-RepoPath $ContractPath
$decisionCsv = Resolve-RepoPath $DecisionCsvPath
$decisionMarkdown = Resolve-RepoPath $DecisionMarkdownPath
$runPlanCsv = Resolve-RepoPath $RunPlanCsvPath
$runPlanMarkdown = Resolve-RepoPath $RunPlanMarkdownPath
if((Get-FileHash -LiteralPath $baseManifest -Algorithm SHA256).Hash -ne $expectedBaseManifestHash) { throw 'Base executable manifest identity changed.' }
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $expectedSourceHash) { throw 'Gate-repair source identity changed.' }
if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -ne $expectedProfileHash) { throw 'Gate-repair profile identity changed.' }

$configsDirectory = Join-Path $package 'configs'
$reportsDirectory = Join-Path $package 'reports_here'
New-Item -ItemType Directory -Path $configsDirectory,$reportsDirectory -Force | Out-Null
$inputs = Import-SetInputs -Path $profile
if($inputs.Keys.Count -ne 589) { throw "Expected 589 profile inputs, found $($inputs.Keys.Count)." }
$baseRows = @(Import-Csv -LiteralPath $baseManifest | Sort-Object { [int]$_.QueueRank })
if($baseRows.Count -ne 24) { throw "Expected 24 base executable rows, found $($baseRows.Count)." }

$rows = foreach($baseRow in $baseRows) {
   $rank = [int]$baseRow.QueueRank
   $reportName = ([string]$baseRow.ExpectedReportName) -replace '^rdmc_exec_', 'rdmc_mrgr_exec_'
   $configName = ('{0:D3}_{1}.ini' -f $rank,$reportName)
   $configPath = Join-Path $configsDirectory $configName
   Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportsDirectory -ReportName $reportName `
      -From $baseRow.From -To $baseRow.To -Inputs $inputs -Model ([int]$baseRow.Model) `
      -Deposit ([int]$baseRow.Deposit) -Period 15
   $relativeConfig = $configPath.Substring($repo.Length + 1)
   $relativeReport = (Join-Path $reportsDirectory $reportName).Substring($repo.Length + 1)
   [pscustomobject][ordered]@{
      QueueRank = $rank
      Rank = [int]$baseRow.Rank
      Wave = [int]$baseRow.Wave
      Phase = $baseRow.Phase
      Role = $baseRow.Role
      Candidate = 'rdmc_money_ready_gate_repair_v1'
      Profile = 'rdmc_money_ready_gate_repair_v1'
      Set = 'frozen_gate_repair'
      Window = $baseRow.Window
      From = $baseRow.From
      To = $baseRow.To
      Model = [int]$baseRow.Model
      Deposit = [int]$baseRow.Deposit
      InitialDeposit = [int]$baseRow.InitialDeposit
      PackageConfig = $relativeConfig
      SourceConfig = $relativeConfig
      ExpectedReportName = $reportName
      ReportDestination = $relativeReport
      ProfileSha256 = $expectedProfileHash
      SourceSha256 = $expectedSourceHash
      ConfigSha256 = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash
      MinNetProfit = $baseRow.MinNetProfit
      MinProfitFactor = $baseRow.MinProfitFactor
      MinTrades = $baseRow.MinTrades
      MaxDrawdownPercent = $baseRow.MaxDrawdownPercent
      MinRecoveryFactor = $baseRow.MinRecoveryFactor
      MinCagrPercent = $baseRow.MinCagrPercent
      MaxParallelism = $baseRow.MaxParallelism
      StopRule = $baseRow.StopRule
      Status = 'LOCKED_LOCAL_LAUNCH_DISABLED'
   }
}
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash
if(![string]::IsNullOrWhiteSpace($expectedManifestHash) -and $manifestHash -ne $expectedManifestHash) { throw "Executable manifest identity changed: $manifestHash" }

foreach($wave in 1..5) {
   $wavePath = Resolve-RepoPath ('outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_{0:D2}_MANIFEST.csv' -f $wave)
   @($rows | Where-Object Wave -eq $wave | Sort-Object QueueRank) | Export-Csv -LiteralPath $wavePath -NoTypeInformation -Encoding ASCII
}

@(
   '# RDMC Money-Ready Gate Repair Executable Package', '',
   '**LOCKED. ZERO MT5 REPORTS.**', '',
   'This package references the gate-repair source/profile identity and contains the complete 24-row executable requalification queue. Reports belong in this directory only after the guarded runner records matching config, source, profile, compiled-binary, and report identities.', '',
   'Wave order is `2, 4, 2, 4, 12`: Model1 critical years, Model1 broad/continuous, Model4 critical years, Model4 broad/continuous, then annual Model4 restarts. Model1 can reject only.'
) | Set-Content -LiteralPath (Join-Path $package 'README.md') -Encoding ASCII
@(
   'Place no hand-edited files here.',
   'Only identity-bound reports and sidecars produced by the guarded local runner may be admitted.'
) | Set-Content -LiteralPath (Join-Path $reportsDirectory 'README.md') -Encoding ASCII

@(
   '# RDMC Money-Ready Gate Repair Executable Contract', '',
   '**NOT A NEW BEST AND NOT MONEY-READY.** This is the full requalification contract for the static-admission successor.', '',
   '## Identity', '',
   "- Source SHA-256: ``$expectedSourceHash``",
   "- Profile SHA-256: ``$expectedProfileHash``",
   "- Manifest SHA-256: ``$manifestHash``",
   '- Initial deposit: `$10,000 USD`',
   '- Signal chart: `XAUUSD M15`', '',
   '## Efficient gate order', '',
   '1. Wave 1: Model1 2019 and 2022. Reject immediately on nonpositive net, low PF/activity, or drawdown above `3%`.',
   '2. Wave 2: three disjoint Model1 eras plus continuous Model1. Model1 remains reject-only.',
   '3. Wave 3: Model4 real ticks for 2019 and 2022.',
   '4. Wave 4: three disjoint Model4 eras, verified tick-cache union, then continuous Model4.',
   '5. Wave 5: all 12 annual/YTD Model4 restarts, with every row required profitable.', '',
   'Continuous Model4 must exceed PF `1.30`, 250 trades, recovery `3`, CAGR `1.00%`, and stay at or below `5%` drawdown. Passing this queue still opens, but does not satisfy, identity-bound executable-ledger cost/Monte Carlo stress, distinct-broker validation, and valid forward testing.', '',
   'Both local launch locks are currently present. No compile, report, profit, forward substitution, or real-account approval is inferred from static equivalence. Real-account trading remains disabled.'
) | Set-Content -LiteralPath $contract -Encoding ASCII

$repoLocked = Test-Path -LiteralPath (Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock')
$outerLocked = Test-Path -LiteralPath (Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock')
$waveOne = @($rows | Where-Object Wave -eq 1)
$planStatus = if($repoLocked -or $outerLocked) { 'LOCKED' } else { 'HARNESS_BINDING_REQUIRED' }
$planRows = foreach($row in $waveOne) {
   [pscustomobject]@{
      Wave = 1
      QueueRank = $row.QueueRank
      Model = $row.Model
      Role = $row.Role
      Window = $row.Window
      ConfigSha256 = $row.ConfigSha256
      Status = $planStatus
      Action = if($planStatus -eq 'LOCKED') { 'WAIT_FOR_DELIBERATE_LOCK_REVIEW' } else { 'BIND_IDENTITY_COLLECTOR_BEFORE_RUN' }
      AvailableWorkers = 0
      MaxCpuPercent = 80
      TimeoutMinutesPerConfig = 15
      MQL5Launched = $false
   }
}
$planRows | Export-Csv -LiteralPath $runPlanCsv -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Money-Ready Gate Repair Executable Run Plan', '',
   "- Status: **$planStatus**",
   '- Admitted wave: `1`',
   "- Rows: ``$($waveOne.Count)``",
   '- Available workers: `not inventoried by offline builder`',
   '- CPU ceiling: `80%`',
   '- Timeout per config: `15 minutes`',
   "- Repository lock: ``$repoLocked``",
   "- Outer lock: ``$outerLocked``", '',
   'This plan does not launch MT5. The new manifest must be bound to the compile-once runner, report sidecars, collector, and evaluator before either lock is reviewed. Wave 1 remains the only admitted spend.'
) | Set-Content -LiteralPath $runPlanMarkdown -Encoding ASCII

$decision = [pscustomobject]@{
   Status = 'LOCKED_AWAITING_WAVE_01_REPORTS'
   CurrentWave = 1
   PassedRows = 0
   TotalRows = 24
   NextAction = 'BIND_IDENTITY_HARNESS_THEN_REVIEW_LAUNCH_LOCK'
   TerminalRejection = $false
   ExecutableGatePass = $false
   ReportsPresent = 0
   LaunchLocked = [bool]($repoLocked -or $outerLocked)
   StaticReadinessPass = $true
   SourceNormalizedToBase = $true
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
   ManifestSha256 = $manifestHash
   SourceSha256 = $expectedSourceHash
   ProfileSha256 = $expectedProfileHash
}
$decision | Export-Csv -LiteralPath $decisionCsv -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Money-Ready Gate Repair Executable Decision', '',
   '**Status: LOCKED_AWAITING_WAVE_01_REPORTS. No new best, forward substitution, or real-money approval.**', '',
   '- Current wave: `1`',
   '- Reports supplied: `0/24`',
   '- Static readiness: `PASS`',
   '- Source normalizes to frozen trading source after reversing the declared gate patch: `PASS`',
   "- Launch locked: ``$($decision.LaunchLocked)``",
   "- Manifest SHA-256: ``$manifestHash``",
   "- Source SHA-256: ``$expectedSourceHash``",
   "- Profile SHA-256: ``$expectedProfileHash``", '',
   'Static equivalence does not transfer profit evidence. The exact new identity must pass all 24 rows before executable-ledger and broker gates can open.'
) | Set-Content -LiteralPath $decisionMarkdown -Encoding ASCII

[pscustomobject]@{
   Status = $decision.Status
   ManifestSha256 = $manifestHash
   SourceSha256 = $expectedSourceHash
   ProfileSha256 = $expectedProfileHash
   Rows = $rows.Count
   WaveCounts = (@(1..5 | ForEach-Object { @($rows | Where-Object Wave -eq $_).Count }) -join ',')
   Model1Rows = @($rows | Where-Object Model -eq 1).Count
   Model4Rows = @($rows | Where-Object Model -eq 4).Count
   ReportsPresent = 0
   LaunchLocked = $decision.LaunchLocked
   MQL5Launched = $false
}
