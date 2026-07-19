param(
   [string]$QueuePath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_EXACT_MODEL1_QUEUE.csv',
   [string]$ReportDir = 'outputs\three_lane_protected_winner_addon_discovery_exact_model1_package\reports_here',
   [string]$RunnerPath = 'outputs\THREE_LANE_PWA_DISCOVERY_EXACT_1.csv',
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Protected_Winner_AddOn_Research.mq5',
   [string]$ResultsPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_SUMMARY.csv',
   [string]$AttestationPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_RUN_ATTESTATION.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_DECISION.md',
   [string]$MetricsPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_METRICS.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Money([double]$Value) { $(if($Value -ge 0.0){'+'}else{'-'}) + '$' + [Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture) }
function Convert-HtmlCell([string]$Html) { ([Net.WebUtility]::HtmlDecode([regex]::Replace($Html, '<[^>]+>', ''))).Trim() }
function Count-AddOnEntries([string]$Path) {
   $html = Get-Content -LiteralPath $Path -Raw
   $marker = $html.IndexOf('<b>Deals</b>', [StringComparison]::OrdinalIgnoreCase)
   if($marker -lt 0) { throw "Deals section missing: $Path" }
   $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::Singleline
   $count = 0
   foreach($row in [regex]::Matches($html.Substring($marker), '<tr\b[^>]*>(?<row>.*?)</tr>', $options)) {
      $cellMatches = [regex]::Matches($row.Groups['row'].Value, '<td\b[^>]*>(?<cell>.*?)</td>', $options)
      if($cellMatches.Count -lt 13) { continue }
      $cells = @($cellMatches | ForEach-Object { Convert-HtmlCell $_.Groups['cell'].Value })
      if($cells[4] -in @('in','in/out') -and $cells[12] -like 'MTSM_ADD_*') { $count++ }
   }
   return $count
}

$rawResults = Join-Path $repo 'work\PWA_DECISION_RAW_RESULTS.csv'
$rawSummary = Join-Path $repo 'work\PWA_DECISION_RAW_SUMMARY.csv'
$rawMarkdown = Join-Path $repo 'work\PWA_DECISION_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults 'work\PWA_DECISION_RAW_RESULTS.csv' -OutSummary 'work\PWA_DECISION_RAW_SUMMARY.csv' `
   -OutMarkdown 'work\PWA_DECISION_RAW_METRICS.md' | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw = @(Import-Csv -LiteralPath $rawResults)
$runnerRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $RunnerPath))
if($queue.Count -ne 30 -or $runnerRows.Count -ne 30) { throw 'Expected 30 queue and exact-run rows.' }
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
      ([string]$item.SourceSha256).ToUpperInvariant() -ne ([string]$identity.SourceSha256).ToUpperInvariant() -or
      ([string]$runner.PortableBinarySha256).ToUpperInvariant() -ne ([string]$identity.PortableBinarySha256).ToUpperInvariant()) {
      throw "Config/source/binary/report identity mismatch: $reportName"
   }
   $addOnEntries = Count-AddOnEntries $report
   $attestations.Add([pscustomobject][ordered]@{
      QueueRank=$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$runner.Status
      ConfigSha256=$configHash;ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256
      PortableBinarySha256=$runner.PortableBinarySha256;ReportSha256=$reportHash
      IdentityCreatedUtc=$identity.CreatedUtc;AddOnEntries=$addOnEntries
   }) | Out-Null
   $results.Add([pscustomobject][ordered]@{
      QueueRank=$item.QueueRank;Candidate=$item.Candidate;CandidateRank=$item.CandidateRank;Window=$item.Window
      From=$item.From;To=$item.To;Model=$item.Model;Deposit=$item.Deposit;Enabled=$item.Enabled
      MinimumProfitR=$item.MinimumProfitR;BreakoutLookbackBars=$item.BreakoutLookbackBars
      RiskMultiplier=$item.RiskMultiplier;PrimaryLockR=$item.PrimaryLockR;LockedProfitCoverage=$item.LockedProfitCoverage
      Status=$parsed.Status;ReportPath=$parsed.ReportPath;ReportSha256=$reportHash;ConfigSha256=$configHash
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;PortableBinarySha256=$runner.PortableBinarySha256
      InitialDeposit=$parsed.InitialDeposit;NetProfit=$parsed.NetProfit;Balance=$parsed.Balance
      TotalReturnPercent=$parsed.TotalReturnPercent;AnnualizedReturnPercent=$parsed.AnnualizedReturnPercent
      CagrPercent=$parsed.CagrPercent;ProfitFactor=$parsed.ProfitFactor;ExpectedPayoff=$parsed.ExpectedPayoff
      SharpeRatio=$parsed.SharpeRatio;WinRatePercent=$parsed.WinRatePercent;TotalTrades=$parsed.TotalTrades
      MaxDrawdownMoney=$parsed.MaxDrawdownMoney;MaxDrawdownPercent=$parsed.MaxDrawdownPercent
      RecoveryFactor=$parsed.RecoveryFactor;AddOnEntries=$addOnEntries
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
      Later=$group.Group | Where-Object Window -eq 'discovery_2019_2020' | Select-Object -First 1
      Continuous=$group.Group | Where-Object Window -eq 'continuous_2015_2020' | Select-Object -First 1
   }
}
if($sets.Count -ne 10 -or !$sets.ContainsKey('pwa_control')) { throw 'Candidate set is incomplete.' }
$controlSet = $sets['pwa_control']
$control = $controlSet.Continuous
$controlEfficiency = [double]$control.TotalReturnPercent / [Math]::Max(0.000001,[double]$control.MaxDrawdownPercent)
$basic = @{}; $quality = @{}
foreach($name in $sets.Keys) {
   $set = $sets[$name]; $continuous = $set.Continuous
   $basic[$name] = $name -ne 'pwa_control' -and [double]$set.Older.NetProfit -gt 0.0 -and
      [double]$set.Later.NetProfit -gt 0.0 -and [double]$continuous.ProfitFactor -ge 1.50 -and
      [double]$continuous.MaxDrawdownPercent -le 2.0 -and [int]$continuous.TotalTrades -gt [int]$control.TotalTrades -and
      [int]$continuous.AddOnEntries -ge 2
   $efficiency = [double]$continuous.TotalReturnPercent / [Math]::Max(0.000001,[double]$continuous.MaxDrawdownPercent)
   $quality[$name] = [double]$continuous.NetProfit -gt [double]$control.NetProfit -and
      $efficiency -gt $controlEfficiency -and [double]$continuous.ProfitFactor -ge [double]$control.ProfitFactor
}
$neighbors = @{
   pwa_center=@('pwa_lookback4','pwa_lookback8','pwa_trigger100','pwa_trigger150','pwa_risk025','pwa_risk060','pwa_coverage100','pwa_coverage150')
   pwa_lookback4=@('pwa_center');pwa_lookback8=@('pwa_center');pwa_trigger100=@('pwa_center');pwa_trigger150=@('pwa_center')
   pwa_risk025=@('pwa_center');pwa_risk060=@('pwa_center');pwa_coverage100=@('pwa_center');pwa_coverage150=@('pwa_center')
}
$summary = [Collections.Generic.List[object]]::new()
foreach($name in ($sets.Keys | Sort-Object)) {
   $set = $sets[$name]; $continuous = $set.Continuous
   $passingNeighbors = @(if($name -ne 'pwa_control') {
      $neighbors[$name] | Where-Object {$basic[$_] -and $quality[$_]}
   })
   $adjacentPass = if($name -eq 'pwa_center') {$passingNeighbors.Count -ge 2} elseif($name -eq 'pwa_control') {$false} else {$passingNeighbors.Count -ge 1}
   $eligible = $basic[$name] -and $quality[$name] -and $adjacentPass
   $efficiency = [double]$continuous.TotalReturnPercent / [Math]::Max(0.000001,[double]$continuous.MaxDrawdownPercent)
   $summary.Add([pscustomobject][ordered]@{
      Candidate=$name;OlderNetProfit=$set.Older.NetProfit;LaterNetProfit=$set.Later.NetProfit
      ContinuousNetProfit=$continuous.NetProfit;ContinuousReturnPercent=$continuous.TotalReturnPercent
      ContinuousCagrPercent=$continuous.CagrPercent;ContinuousProfitFactor=$continuous.ProfitFactor
      ContinuousTrades=$continuous.TotalTrades;ContinuousAddOnEntries=$continuous.AddOnEntries
      ContinuousMaxDrawdownPercent=$continuous.MaxDrawdownPercent;ContinuousRecoveryFactor=$continuous.RecoveryFactor
      ReturnDrawdown=[Math]::Round($efficiency,4);BasicGatePass=$basic[$name];QualityGatePass=$quality[$name]
      AdjacentPass=$adjacentPass;PassingNeighbors=($passingNeighbors -join ';')
      Decision=$(if($eligible){'DISCOVERY_ELIGIBLE'}elseif($name -eq 'pwa_control'){'CONTROL_ONLY'}else{'REJECT_BEFORE_HOLDOUT'})
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$eligible = @($summary | Where-Object Decision -eq 'DISCOVERY_ELIGIBLE' | Sort-Object -Property `
   @{Expression={[double]$_.ReturnDrawdown};Descending=$true},
   @{Expression={[double]$_.ContinuousNetProfit};Descending=$true})
$selected = $eligible | Select-Object -First 1
$selectedQueue = if($selected) { $queue | Where-Object {$_.Candidate -eq $selected.Candidate -and $_.Window -eq 'continuous_2015_2020'} | Select-Object -First 1 } else { $null }
$status = if($selected) {'DISCOVERY_SURVIVOR'} else {'REJECTED_IN_DISCOVERY'}
$resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash.ToUpperInvariant()
$attestationHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $AttestationPath) -Algorithm SHA256).Hash.ToUpperInvariant()
$decision = [pscustomobject][ordered]@{
   Status=$status;Profiles=$summary.Count;ReportsParsed=$results.Count;EligibleProfiles=$eligible.Count
   SelectedCandidate=$(if($selected){$selected.Candidate}else{''});SelectedProfileSha256=$(if($selectedQueue){$selectedQueue.ProfileSha256}else{''})
   HoldoutPermitted=[bool]$selected;HoldoutOpened=$false;Model4Opened=$false;NewBest=$false
   SourceSha256=$sourceHashes[0];PortableBinarySha256=$binaryHashes[0]
   ResultsSha256=$resultsHash;RunAttestationSha256=$attestationHash;FrozenForwardCandidateChanged=$false
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [Collections.Generic.List[string]]::new()
$md.Add('# Three-Lane Protected Winner Add-On Discovery Decision'); $md.Add('')
if($selected) {
   $md.Add("**Decision: DISCOVERY SURVIVOR. A frozen 2021+ holdout is permitted only for ``$($selected.Candidate)``; Model 4, promotion, forward registration, and real trading remain closed.**")
} else {
   $md.Add('**Decision: REJECTED IN SEALED 2015-2020 DISCOVERY. No holdout or Model 4 escalation is permitted.**')
}
$md.Add(''); $md.Add("- Exact source SHA-256: ``$($sourceHashes[0])``")
$md.Add("- Exact portable binary SHA-256: ``$($binaryHashes[0])``")
$md.Add('- Controlled run: `30 / 30` reports, one worker, zero errors, one binary identity')
$md.Add('- Starting deposit: `$10,000`; real-account trading: disabled')
$md.Add('- Frozen ATB150 and frozen forward candidate: unchanged')
$md.Add(''); $md.Add('| Profile | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | Add-ons | DD | Return/DD | Gate |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object {[double]$_.ContinuousNetProfit} -Descending)) {
   $md.Add("| ``$($row.Candidate)`` | $(Money $row.OlderNetProfit) | $(Money $row.LaterNetProfit) | $(Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousAddOnEntries) | $($row.ContinuousMaxDrawdownPercent)% | $($row.ReturnDrawdown) | $($row.Decision) |")
}
$md.Add(''); $md.Add('## Interpretation'); $md.Add('')
if($selected) {
   $gain = [double]$selected.ContinuousNetProfit - [double]$control.NetProfit
   $md.Add("- Selected discovery profile ``$($selected.Candidate)`` improved continuous net by $(Money $gain) versus the disabled-feature control, with PF ``$($selected.ContinuousProfitFactor)`` and DD ``$($selected.ContinuousMaxDrawdownPercent)%``.")
   $md.Add('- The result is a small research improvement, not a new best. Only an untouched 2021-2026 holdout can determine whether the gain transfers.')
} else {
   $md.Add('- No profile combined profitable disjoint eras, useful add-on activity, improved return/drawdown, and adjacent support.')
}
$md.Add('- The add-on is winner-only and requires broker-valued stop-locked profit to cover its full initial risk. It never adds to a loser.')
$md.Add('- ATB150 remains the research best until every later gate passes.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
@(
   '# Three-Lane Protected Winner Add-On Discovery Metrics','',
   "- Parsed reports: ``$($results.Count) / 30``","- Source SHA-256: ``$($sourceHashes[0])``",
   "- Portable binary SHA-256: ``$($binaryHashes[0])``",'- Exact binary identities: `1`',
   "- Discovery-eligible profiles: ``$($eligible.Count)``","- Holdout permitted: ``$(if($selected){'YES'}else{'NO'})``",
   '- Model 4 opened: `NO`','- New best: `NO`'
) | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII

Remove-Item -LiteralPath $rawResults,$rawSummary,$rawMarkdown -Force -ErrorAction SilentlyContinue
$decision
