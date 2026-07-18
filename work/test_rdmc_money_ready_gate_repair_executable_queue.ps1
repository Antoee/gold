$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$manifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_MANIFEST.csv'
$baseManifestPath = Join-Path $repo 'outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv'
$sourcePath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5'
$profilePath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_v1.set'
$configsPath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_executable_package\configs'
$reportsPath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_executable_package\reports_here'
$contractPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_CONTRACT.md'
$expectedManifestHash = 'EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972'
$expectedSourceHash = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
$expectedProfileHash = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$temp = [IO.Path]::GetFullPath((Join-Path $tempRoot ('rdmc-money-ready-queue-test-' + [guid]::NewGuid().ToString('N'))))
if(!$temp.StartsWith($tempRoot + '\rdmc-money-ready-queue-test-', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe queue-test path.' }
New-Item -ItemType Directory -Path $temp -Force | Out-Null
$decisionPath = Join-Path $temp 'decision.csv'
$decisionMarkdownPath = Join-Path $temp 'decision.md'
$runPlanPath = Join-Path $temp 'run-plan.csv'
$runPlanMarkdownPath = Join-Path $temp 'run-plan.md'

& (Join-Path $PSScriptRoot 'build_rdmc_money_ready_gate_repair_executable_queue.ps1') `
   -DecisionCsvPath $decisionPath -DecisionMarkdownPath $decisionMarkdownPath `
   -RunPlanCsvPath $runPlanPath -RunPlanMarkdownPath $runPlanMarkdownPath | Out-Null

if((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -ne $expectedManifestHash) { throw 'Executable queue manifest hash changed.' }
if((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -ne $expectedSourceHash) { throw 'Executable queue source hash changed.' }
if((Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash -ne $expectedProfileHash) { throw 'Executable queue profile hash changed.' }

$rows = @(Import-Csv -LiteralPath $manifestPath | Sort-Object { [int]$_.QueueRank })
$baseRows = @(Import-Csv -LiteralPath $baseManifestPath | Sort-Object { [int]$_.QueueRank })
if($rows.Count -ne 24 -or $baseRows.Count -ne 24) { throw 'Executable queue row count changed.' }
if((@($rows | Select-Object -ExpandProperty QueueRank) -join ',') -ne ((1..24) -join ',')) { throw 'Queue ranks are not exact.' }
$waveCounts = @(1..5 | ForEach-Object { $wave=$_; @($rows | Where-Object Wave -eq ([string]$wave)).Count })
if(($waveCounts -join ',') -ne '2,4,2,4,12') { throw "Wave counts changed: $($waveCounts -join ',')" }
if(@($rows | Where-Object Model -eq '1').Count -ne 6 -or @($rows | Where-Object Model -eq '4').Count -ne 18) { throw 'Model allocation changed.' }
if((@($rows | Where-Object Wave -eq '1' | Select-Object -ExpandProperty Window) -join ',') -ne '2019,2022') { throw 'Critical reject-first windows changed.' }
if(@($rows | Where-Object { $_.SourceSha256 -ne $expectedSourceHash -or $_.ProfileSha256 -ne $expectedProfileHash }).Count -gt 0) { throw 'Queue identity is mixed.' }
if(@($rows | Where-Object { $_.Deposit -ne '10000' -or $_.InitialDeposit -ne '10000' }).Count -gt 0) { throw 'Starting-capital contract changed.' }
if(@($rows | Where-Object Status -ne 'LOCKED_LOCAL_LAUNCH_DISABLED').Count -gt 0) { throw 'A queue row is not launch locked.' }

$invariantFields = @('QueueRank','Rank','Wave','Phase','Role','Window','From','To','Model','Deposit','InitialDeposit','MinNetProfit','MinProfitFactor','MinTrades','MaxDrawdownPercent','MinRecoveryFactor','MinCagrPercent','MaxParallelism','StopRule')
for($index=0; $index -lt $rows.Count; $index++) {
   foreach($field in $invariantFields) {
      if([string]$rows[$index].$field -ne [string]$baseRows[$index].$field) { throw "Gate threshold/order changed at rank $($rows[$index].QueueRank), field $field." }
   }
}

$profileInputs = Import-SetInputs -Path $profilePath
if($profileInputs.Keys.Count -ne 589) { throw 'Frozen executable profile no longer has 589 inputs.' }
$configFiles = @(Get-ChildItem -LiteralPath $configsPath -Filter '*.ini' -File)
if($configFiles.Count -ne 24) { throw "Expected 24 configs, found $($configFiles.Count)." }
$reportNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($row in $rows) {
   $configPath = Join-Path $repo $row.PackageConfig
   if(!(Test-Path -LiteralPath $configPath -PathType Leaf)) { throw "Config missing at rank $($row.QueueRank)." }
   if((Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash -ne $row.ConfigSha256) { throw "Config hash mismatch at rank $($row.QueueRank)." }
   $configInputs = Import-SetInputs -Path $configPath
   foreach($name in $profileInputs.Keys) {
      if(!$configInputs.ContainsKey($name) -or $configInputs[$name] -ne $profileInputs[$name]) { throw "Config input mismatch at rank $($row.QueueRank): $name" }
   }
   $configText = Get-Content -Raw -LiteralPath $configPath
   foreach($required in @('Expert=Professional_XAUUSD_EA.ex5','Symbol=XAUUSD','Period=15','Optimization=0','Visual=0','Deposit=10000','Currency=USD','ShutdownTerminal=1')) {
      if($configText -notmatch ('(?m)^' + [regex]::Escape($required) + '\r?$')) { throw "Config contract missing at rank $($row.QueueRank): $required" }
   }
   if($configText -notmatch ('(?m)^Model=' + [regex]::Escape([string]$row.Model) + '\r?$')) { throw "Config model mismatch at rank $($row.QueueRank)." }
   if($configText -notmatch ('(?m)^Report=' + [regex]::Escape([string]$row.ExpectedReportName) + '\r?$')) { throw "Config report mismatch at rank $($row.QueueRank)." }
   if(!$reportNames.Add([string]$row.ExpectedReportName)) { throw "Duplicate report name: $($row.ExpectedReportName)" }
}

foreach($wave in 1..5) {
   $wavePath = Join-Path $repo ('outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_{0:D2}_MANIFEST.csv' -f $wave)
   $waveRows = @(Import-Csv -LiteralPath $wavePath | Sort-Object { [int]$_.QueueRank })
   $expectedRows = @($rows | Where-Object Wave -eq ([string]$wave) | Sort-Object { [int]$_.QueueRank })
   if(($waveRows.QueueRank -join ',') -ne ($expectedRows.QueueRank -join ',')) { throw "Wave $wave manifest differs from the combined queue." }
}

$reportArtifacts = @(Get-ChildItem -LiteralPath $reportsPath -File | Where-Object Name -ne 'README.md')
if($reportArtifacts.Count -ne 0) { throw 'Executable queue contains unvalidated report artifacts.' }
$decision = @(Import-Csv -LiteralPath $decisionPath)
if($decision.Count -ne 1 -or $decision[0].Status -ne 'LOCKED_AWAITING_WAVE_01_REPORTS' -or $decision[0].ExecutableGatePass -ne 'False' -or $decision[0].ReportsPresent -ne '0') { throw 'Executable decision overclaims current evidence.' }
if($decision[0].ManifestSha256 -ne $expectedManifestHash -or $decision[0].SourceSha256 -ne $expectedSourceHash -or $decision[0].ProfileSha256 -ne $expectedProfileHash) { throw 'Executable decision identity mismatch.' }
$contract = Get-Content -Raw -LiteralPath $contractPath
foreach($boundary in @('NOT A NEW BEST AND NOT MONEY-READY','Model1 remains reject-only','distinct-broker validation','Real-account trading remains disabled')) {
   if($contract.IndexOf($boundary, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Executable contract boundary missing: $boundary" }
}

$repoLock = Test-Path -LiteralPath (Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock')
$outerLock = Test-Path -LiteralPath (Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock')
$mt5Processes = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match 'terminal64|metatester64|metaeditor64' })
if(!$repoLock -or !$outerLock -or $mt5Processes.Count -ne 0) { throw 'Local launch-safety state changed during offline queue testing.' }

Remove-Item -LiteralPath $temp -Recurse -Force

[pscustomobject]@{
   Status = 'PASS'
   Rows = $rows.Count
   WaveCounts = $waveCounts -join ','
   Model1Rows = @($rows | Where-Object Model -eq '1').Count
   Model4Rows = @($rows | Where-Object Model -eq '4').Count
   Configs = $configFiles.Count
   InputsPerConfig = $profileInputs.Keys.Count
   ReportsPresent = $reportArtifacts.Count
   ThresholdsChangedFromFullGate = 0
   SourceSha256 = $expectedSourceHash
   ProfileSha256 = $expectedProfileHash
   ManifestSha256 = $expectedManifestHash
   LaunchLocks = 2
   MT5Processes = $mt5Processes.Count
   MQL5Launched = $false
   RealAccountApproved = $false
}
