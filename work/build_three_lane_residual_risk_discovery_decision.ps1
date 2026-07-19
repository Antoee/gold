param(
   [string]$QueuePath = 'outputs\THREE_LANE_RESIDUAL_RISK_DISCOVERY_MODEL1_QUEUE.csv',
   [string]$ReportDir = 'outputs\three_lane_residual_risk_discovery_model1_package\reports_here',
   [string]$RunnerPath = 'outputs\THREE_LANE_RR_DISCOVERY_EXACT_1.csv',
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Residual_Risk_Research.mq5',
   [string]$ResultsPath = 'outputs\THREE_LANE_RESIDUAL_RISK_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_RESIDUAL_RISK_DISCOVERY_MODEL1_SUMMARY.csv',
   [string]$AttestationPath = 'outputs\THREE_LANE_RESIDUAL_RISK_DISCOVERY_MODEL1_RUN_ATTESTATION.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_RESIDUAL_RISK_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_RESIDUAL_RISK_DISCOVERY_DECISION.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Repo-Relative([string]$Path) {
   $full = [IO.Path]::GetFullPath($Path)
   if(!$full.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Path is outside repository: $full" }
   return $full.Substring($repo.Length + 1)
}
function Money([double]$Value) { $(if($Value -ge 0.0){'+'}else{'-'}) + '$' + [Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture) }

$rawResults = Join-Path $repo 'work\RR_DISCOVERY_DECISION_RAW_RESULTS.csv'
$rawSummary = Join-Path $repo 'work\RR_DISCOVERY_DECISION_RAW_SUMMARY.csv'
$rawMarkdown = Join-Path $repo 'work\RR_DISCOVERY_DECISION_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults 'work\RR_DISCOVERY_DECISION_RAW_RESULTS.csv' -OutSummary 'work\RR_DISCOVERY_DECISION_RAW_SUMMARY.csv' `
   -OutMarkdown 'work\RR_DISCOVERY_DECISION_RAW_METRICS.md' | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw = @(Import-Csv -LiteralPath $rawResults)
$runnerRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $RunnerPath))
if($queue.Count -ne 24 -or $raw.Count -ne 24 -or $runnerRows.Count -ne 24) { throw 'Expected 24 queue, parsed, and exact-run rows.' }
$rawByReport = @{}; foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$runnerByRank = @{}; foreach($row in $runnerRows) { $runnerByRank[[string]$row.QueueRank] = $row }
$reportRoot = Resolve-RepoPath $ReportDir
$packageRoot = Split-Path -Parent $reportRoot
$results = [Collections.Generic.List[object]]::new()
$attestations = [Collections.Generic.List[object]]::new()
foreach($item in ($queue | Sort-Object {[int]$_.QueueRank})) {
   $reportName = [string]$item.ExpectedReportName
   $parsed = $rawByReport[$reportName]
   $runner = $runnerByRank[[string]$item.QueueRank]
   if($null -eq $parsed -or $parsed.Status -ne 'PARSED' -or $null -eq $runner -or $runner.Status -ne 'REPORT_FOUND') {
      throw "Missing parsed/exact evidence: $reportName"
   }
   $report = Resolve-RepoPath ([string]$parsed.ReportPath)
   $reportHash = (Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash.ToUpperInvariant()
   $config = Join-Path $packageRoot ([string]$item.Config)
   $configHash = (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant()
   $identityPath = Join-Path $reportRoot ($reportName + '.identity.json')
   $identity = Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json
   if($configHash -ne ([string]$runner.PackageConfigSha256).ToUpperInvariant() -or
      $reportHash -ne ([string]$runner.ReportSha256).ToUpperInvariant() -or
      $reportHash -ne ([string]$identity.ReportSha256).ToUpperInvariant() -or
      ([string]$item.SourceSha256).ToUpperInvariant() -ne ([string]$runner.PackageSourceSha256).ToUpperInvariant() -or
      ([string]$item.SourceSha256).ToUpperInvariant() -ne ([string]$identity.SourceSha256).ToUpperInvariant() -or
      ([string]$runner.PortableBinarySha256).ToUpperInvariant() -ne ([string]$identity.PortableBinarySha256).ToUpperInvariant()) {
      throw "Config/source/binary/report identity mismatch: $reportName"
   }
   $attestations.Add([pscustomobject][ordered]@{
      QueueRank=$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$runner.Status
      ConfigSha256=$configHash;ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256
      PortableBinarySha256=$runner.PortableBinarySha256;ReportSha256=$reportHash
      IdentityCreatedUtc=$identity.CreatedUtc;ReportPath=(Repo-Relative $report)
   }) | Out-Null
   $results.Add([pscustomobject][ordered]@{
      QueueRank=$item.QueueRank;Candidate=$item.Candidate;CandidateRank=$item.CandidateRank;Window=$item.Window
      From=$item.From;To=$item.To;Model=$item.Model;Deposit=$item.Deposit;Enabled=$item.Enabled
      ReservePercent=$item.ReservePercent;RVMaximumEntryRiskPercent=$item.RVMaximumEntryRiskPercent
      MOMaximumEntryRiskPercent=$item.MOMaximumEntryRiskPercent;ATBMaximumEntryRiskPercent=$item.ATBMaximumEntryRiskPercent
      Status=$parsed.Status;ReportPath=(Repo-Relative $report);ReportSha256=$reportHash;ConfigSha256=$configHash
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;PortableBinarySha256=$runner.PortableBinarySha256
      InitialDeposit=$parsed.InitialDeposit;NetProfit=$parsed.NetProfit;Balance=$parsed.Balance
      TotalReturnPercent=$parsed.TotalReturnPercent;AnnualizedReturnPercent=$parsed.AnnualizedReturnPercent
      CagrPercent=$parsed.CagrPercent;ProfitFactor=$parsed.ProfitFactor;ExpectedPayoff=$parsed.ExpectedPayoff
      SharpeRatio=$parsed.SharpeRatio;WinRatePercent=$parsed.WinRatePercent;TotalTrades=$parsed.TotalTrades
      MaxDrawdownMoney=$parsed.MaxDrawdownMoney;MaxDrawdownPercent=$parsed.MaxDrawdownPercent
      RecoveryFactor=$parsed.RecoveryFactor
   }) | Out-Null
}
$sourceHashes = @($results.SourceSha256 | Sort-Object -Unique)
$binaryHashes = @($results.PortableBinarySha256 | Sort-Object -Unique)
if($sourceHashes.Count -ne 1 -or $binaryHashes.Count -ne 1) { throw 'Exact source/binary identity is not uniform.' }
if((Get-FileHash -LiteralPath (Resolve-RepoPath $SourcePath) -Algorithm SHA256).Hash.ToUpperInvariant() -ne $sourceHashes[0].ToUpperInvariant()) {
   throw 'Current research source differs from tested source.'
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$attestations | Export-Csv -LiteralPath (Resolve-RepoPath $AttestationPath) -NoTypeInformation -Encoding ASCII

$sets = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $sets[$group.Name] = [pscustomobject]@{
      Older=$group.Group | Where-Object Window -eq 'older_2015_2018' | Select-Object -First 1
      Later=$group.Group | Where-Object Window -eq 'calibration_2019_2020' | Select-Object -First 1
      Continuous=$group.Group | Where-Object Window -eq 'continuous_2015_2020' | Select-Object -First 1
   }
}
if($sets.Count -ne 8 -or !$sets.ContainsKey('rr_control')) { throw 'Candidate set is incomplete.' }
$control = $sets['rr_control'].Continuous
$controlEfficiency = [double]$control.TotalReturnPercent / [Math]::Max(0.000001,[double]$control.MaxDrawdownPercent)
$summary = [Collections.Generic.List[object]]::new()
foreach($name in ($sets.Keys | Sort-Object)) {
   $set = $sets[$name]
   $continuous = $set.Continuous
   $efficiency = [double]$continuous.TotalReturnPercent / [Math]::Max(0.000001,[double]$continuous.MaxDrawdownPercent)
   $basic = $name -ne 'rr_control' -and [double]$set.Older.NetProfit -gt 0.0 -and [double]$set.Later.NetProfit -gt 0.0 -and
      [double]$continuous.ProfitFactor -ge 1.50 -and [double]$continuous.MaxDrawdownPercent -le 2.25 -and
      [double]$continuous.CagrPercent -ge [double]$control.CagrPercent + 0.50
   $quality = [double]$continuous.NetProfit -gt [double]$control.NetProfit -and $efficiency -gt $controlEfficiency -and
      [double]$continuous.RecoveryFactor -ge [double]$control.RecoveryFactor
   $eligible = $basic -and $quality
   $summary.Add([pscustomobject][ordered]@{
      Candidate=$name;OlderNetProfit=$set.Older.NetProfit;LaterNetProfit=$set.Later.NetProfit
      ContinuousNetProfit=$continuous.NetProfit;ContinuousCagrPercent=$continuous.CagrPercent
      ContinuousProfitFactor=$continuous.ProfitFactor;ContinuousTrades=$continuous.TotalTrades
      ContinuousMaxDrawdownPercent=$continuous.MaxDrawdownPercent;ContinuousRecoveryFactor=$continuous.RecoveryFactor
      ReturnDrawdown=[Math]::Round($efficiency,4);BasicGatePass=$basic;QualityGatePass=$quality
      Decision=$(if($eligible){'NEIGHBORHOOD_REQUIRED'}elseif($name -eq 'rr_control'){'CONTROL_ONLY'}else{'REJECT_BEFORE_NEIGHBORHOOD'})
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$selected = $summary | Where-Object Decision -eq 'NEIGHBORHOOD_REQUIRED' | Sort-Object {[double]$_.ReturnDrawdown} -Descending | Select-Object -First 1
$selectedQueue = if($selected) { $queue | Where-Object {$_.Candidate -eq $selected.Candidate} | Select-Object -First 1 } else { $null }
$status = if($selected) {'CALIBRATION_SURVIVOR_NEIGHBORHOOD_REQUIRED'} else {'REJECTED_IN_CALIBRATION'}
$decision = [pscustomobject][ordered]@{
   Status=$status;Profiles=$summary.Count;ReportsParsed=$results.Count
   SelectedCandidate=$(if($selected){$selected.Candidate}else{''})
   SelectedProfileSha256=$(if($selectedQueue){$selectedQueue.ProfileSha256}else{''})
   NeighborhoodRequired=[bool]$selected;HoldoutPermitted=$false;Model4Opened=$false;NewBest=$false
   SourceSha256=$sourceHashes[0];PortableBinarySha256=$binaryHashes[0]
   FrozenForwardCandidateChanged=$false
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [Collections.Generic.List[string]]::new()
$md.Add('# Three-Lane Residual-Risk Calibration Decision'); $md.Add('')
if($selected) {
   $md.Add("**Decision: ``$($selected.Candidate)`` is a calibration survivor, but a tight parameter-neighborhood test is mandatory before any 2021+ historical cross-period check. It is not a new best.**")
} else {
   $md.Add('**Decision: REJECTED IN CALIBRATION. No later-period or Model 4 escalation is permitted.**')
}
$md.Add(''); $md.Add("- Exact source SHA-256: ``$($sourceHashes[0])``")
$md.Add("- Exact portable binary SHA-256: ``$($binaryHashes[0])``")
$md.Add('- Controlled run: `24 / 24` reports, one worker, zero errors, one binary identity')
$md.Add('- These dates were used in earlier portfolio research. This is calibration evidence, not pristine out-of-sample evidence.')
$md.Add(''); $md.Add('| Profile | 2015-18 | 2019-20 | Continuous | CAGR | PF | DD | Recovery | Return/DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object {[double]$_.ContinuousNetProfit} -Descending)) {
   $md.Add("| ``$($row.Candidate)`` | $(Money $row.OlderNetProfit) | $(Money $row.LaterNetProfit) | $(Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousMaxDrawdownPercent)% | $($row.ContinuousRecoveryFactor) | $($row.ReturnDrawdown) | $($row.Decision) |")
}
if($selected) {
   $gain = [double]$selected.ContinuousNetProfit - [double]($summary | Where-Object Candidate -eq 'rr_control').ContinuousNetProfit
   $md.Add(''); $md.Add("The selected calibration point improves continuous net by $(Money $gain), CAGR from ``$($control.CagrPercent)%`` to ``$($selected.ContinuousCagrPercent)%``, and return/DD from ``$([Math]::Round($controlEfficiency,4))`` to ``$($selected.ReturnDrawdown)``.")
   $md.Add('Its two disjoint eras are profitable, but each gives up some era-level efficiency versus control. A local ceiling neighborhood must show that the combined-path improvement is not a single-point effect.')
}
$md.Add(''); $md.Add('ATB150 remains the historical champion. The frozen forward candidate, account contract, source/profile/binary identity, evidence logs, and real-account lock are unchanged.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath $rawResults,$rawSummary,$rawMarkdown -Force -ErrorAction SilentlyContinue
$decision
