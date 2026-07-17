param(
   [string]$QueuePath="outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$PackageDir="outputs\low_activity_diversifier_holdout_model1_package",
   [string]$ResultsPath="outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_RESULTS.csv",
   [string]$SummaryPath="outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_SUMMARY.csv",
   [string]$MetricsPath="outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_METRICS.md",
   [string]$DecisionCsvPath="outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_DECISION.csv",
   [string]$DecisionMarkdownPath="outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Get-Field([object]$Row,[string]$Name,[object]$Default=''){if($null -eq $Row){return $Default};$p=$Row.PSObject.Properties[$Name];if($null -eq $p -or "$($p.Value)" -eq ''){return $Default};return $p.Value}
function Format-Money([object]$Value){$n=[double]$Value;return $(if($n -ge 0){'+'}else{'-'})+'$'+[math]::Abs($n).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}

$queue=@(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$package=Resolve-RepoPath $PackageDir
$central=Join-Path $repo 'work\LOW_ACTIVITY_DIVERSIFIER_RAW_REPORTS'
if(Test-Path -LiteralPath $central){Remove-Item -LiteralPath $central -Recurse -Force}
New-Item -ItemType Directory -Path $central -Force | Out-Null
foreach($report in (Get-ChildItem -LiteralPath $package -Recurse -File | Where-Object {$_.Directory.Name -eq 'reports_here' -and $_.Extension -in @('.htm','.html','.xml')})){
   Copy-Item -LiteralPath $report.FullName -Destination (Join-Path $central $report.Name) -Force
}
if(@(Get-ChildItem -LiteralPath $central -File).Count -ne 9){throw 'Expected nine centralized reports.'}

$rawResults='work\LAD_RAW_RESULTS.csv';$rawSummary='work\LAD_RAW_SUMMARY.csv';$rawMetrics='work\LAD_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir 'work\LOW_ACTIVITY_DIVERSIFIER_RAW_REPORTS' -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0){throw 'Shared report collector failed.'}
$raw=@(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults));$rawByReport=@{}
foreach($row in $raw){$rawByReport[[string]$row.ExpectedReportName]=$row}
$runnerByRank=@{}
foreach($path in (Get-ChildItem -LiteralPath (Join-Path $repo 'outputs') -Filter 'LOW_ACTIVITY_DIVERSIFIER_PORTABLE_*.csv' -ErrorAction SilentlyContinue)){
   foreach($row in (Import-Csv -LiteralPath $path.FullName)){$key=[string]$row.QueueRank;if(!$runnerByRank.ContainsKey($key) -or [string]$row.Status -eq 'REPORT_FOUND'){$runnerByRank[$key]=$row}}
}
$results=[System.Collections.Generic.List[object]]::new()
foreach($item in ($queue | Sort-Object {[int]$_.QueueRank})){
   $parsed=$rawByReport[[string]$item.ExpectedReportName];if($null -eq $parsed){throw "Missing parser row: $($item.ExpectedReportName)"}
   $runner=$runnerByRank[[string]$item.QueueRank]
   $reportPath=[string](Get-Field $parsed 'ReportPath');$reportHash=if($reportPath){(Get-FileHash -LiteralPath (Resolve-RepoPath $reportPath) -Algorithm SHA256).Hash}else{''}
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank;Candidate=$item.Candidate;CandidateRank=$item.CandidateRank;Family=$item.Family;Phase=$item.Phase
      Window=$item.Window;From=$item.From;To=$item.To;Model=$item.Model;Deposit=$item.Deposit;ExpectedReportName=$item.ExpectedReportName
      ProfileSnapshot=$item.ProfileSnapshot;ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;RiskPercent=$item.RiskPercent;StopRule=$item.StopRule
      Status=$parsed.Status;ReportPath=$reportPath;ReportSha256=$reportHash;InitialDeposit=$parsed.InitialDeposit;CalendarDays=$parsed.CalendarDays;Years=$parsed.Years
      NetProfit=$parsed.NetProfit;Balance=$parsed.Balance;TotalReturnPercent=$parsed.TotalReturnPercent;AnnualizedReturnPercent=$parsed.AnnualizedReturnPercent;CagrPercent=$parsed.CagrPercent
      ProfitFactor=$parsed.ProfitFactor;ExpectedPayoff=$parsed.ExpectedPayoff;SharpeRatio=$parsed.SharpeRatio;WinRatePercent=$parsed.WinRatePercent;TotalTrades=$parsed.TotalTrades
      MaxConsecutiveLosses=$parsed.MaxConsecutiveLosses;MaxDrawdownMoney=$parsed.MaxDrawdownMoney;MaxDrawdownPercent=$parsed.MaxDrawdownPercent
      BalanceDrawdownMaximal=$parsed.BalanceDrawdownMaximal;EquityDrawdownMaximal=$parsed.EquityDrawdownMaximal;RecoveryFactor=$parsed.RecoveryFactor
      RunnerStatus=(Get-Field $runner 'Status');RunnerEvidence=(Get-Field $runner 'Evidence')
   }) | Out-Null
}
if($results.Count -ne 9 -or @($results | Where-Object Status -ne 'PARSED').Count -ne 0){throw 'Expected nine parsed holdout reports.'}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$pre2021=@{
   fbt_b16_fixed_r200=[pscustomobject]@{Older=65.89;Later=29.31;Trades=54;PF=1.45}
   m15sq_break8=[pscustomobject]@{Older=98.71;Later=81.19;Trades=88;PF=1.44}
   m15vcr_vol130=[pscustomobject]@{Older=73.23;Later=35.37;Trades=84;PF=1.27}
}
$summary=[System.Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)){
   $a=$group.Group | Where-Object Window -eq 'holdout_2021_2022' | Select-Object -First 1
   $b=$group.Group | Where-Object Window -eq 'holdout_2023_2026' | Select-Object -First 1
   $c=$group.Group | Where-Object Window -eq 'continuous_2021_2026' | Select-Object -First 1
   if(!$a -or !$b -or !$c){throw "Incomplete holdout: $($group.Name)"}
   $pre=$pre2021[$group.Name]
   $pass=[double]$a.NetProfit -gt 0 -and [double]$b.NetProfit -gt 0 -and [double]$c.NetProfit -gt 0 -and [double]$c.ProfitFactor -ge 1.15 -and [int]$c.TotalTrades -ge 35 -and [double]$c.MaxDrawdownPercent -le 2.0
   $summary.Add([pscustomobject]@{
      Candidate=$group.Name;Pre2015_2018Net=$pre.Older;Pre2019_2020Net=$pre.Later;PreContinuousPF=$pre.PF;PreTrades=$pre.Trades
      Holdout2021_2022Net=$a.NetProfit;Holdout2021_2022PF=$a.ProfitFactor;Holdout2021_2022Trades=$a.TotalTrades
      Holdout2023_2026Net=$b.NetProfit;Holdout2023_2026PF=$b.ProfitFactor;Holdout2023_2026Trades=$b.TotalTrades
      HoldoutContinuousNet=$c.NetProfit;HoldoutContinuousCagrPercent=$c.CagrPercent;HoldoutContinuousPF=$c.ProfitFactor
      HoldoutContinuousTrades=$c.TotalTrades;HoldoutContinuousMaxDrawdownPercent=$c.MaxDrawdownPercent;HoldoutContinuousRecoveryFactor=$c.RecoveryFactor
      LaneGatePass=$pass;Decision=$(if($pass){'TRADE_ANALYSIS_ELIGIBLE'}else{'REJECTED_BROAD_HOLDOUT'})
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$eligible=@($summary | Where-Object LaneGatePass -eq $true)
$resultsHash=(Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
$decision=[pscustomobject]@{
   Status=$(if($eligible.Count -gt 0){'HOLDOUT_GATE_PASSED'}else{'REJECTED_IN_HOLDOUT'});Profiles=$summary.Count;ReportsParsed=$results.Count
   TradeAnalysisEligible=$eligible.Count;PortfolioAnalysisPermitted=($eligible.Count -gt 0);Model4Permitted=$false;ReleasedCandidateChanged=$false;ResultsSha256=$resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$md=[System.Collections.Generic.List[string]]::new();$md.Add('# Low-Activity Diversifier Holdout Decision');$md.Add('')
$md.Add($(if($eligible.Count -gt 0){'**Decision: HOLDOUT GATE PASSED FOR AT LEAST ONE LANE. Trade extraction and preregistered portfolio analysis are permitted; no Model 4 run, implementation, new best, or live approval exists.**'}else{'**Decision: REJECTED IN POST-2020 HOLDOUT. No trade extraction, portfolio combination, Model 4 run, new best, or live approval was opened.**'}));$md.Add('')
$md.Add('The exact pre-2021 profiles were retained at `0.10%` risk. This explicitly holdout-informed screen tests diversification eligibility, not standalone promotion. Any losing disjoint holdout era rejects a lane.');$md.Add('')
$md.Add('- Reports: `9 / 9` parsed with exact embedded source identities');$md.Add("- Trade-analysis eligible lanes: ``$($eligible.Count) / 3``");$md.Add('')
$md.Add('| Profile | Pre 2015-18 | Pre 2019-20 | 2021-22 | PF | Trades | 2023-26 | PF | Trades | Holdout | PF | Trades | DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object {[double]$_.HoldoutContinuousNet} -Descending)){
   $md.Add("| ``$($row.Candidate)`` | $(Format-Money $row.Pre2015_2018Net) | $(Format-Money $row.Pre2019_2020Net) | $(Format-Money $row.Holdout2021_2022Net) | $($row.Holdout2021_2022PF) | $($row.Holdout2021_2022Trades) | $(Format-Money $row.Holdout2023_2026Net) | $($row.Holdout2023_2026PF) | $($row.Holdout2023_2026Trades) | $(Format-Money $row.HoldoutContinuousNet) | $($row.HoldoutContinuousPF) | $($row.HoldoutContinuousTrades) | $($row.HoldoutContinuousMaxDrawdownPercent)% | $($row.Decision) |")
}
$md.Add('');$md.Add('The released and frozen forward candidates remain unchanged. A passing lane still requires a separately frozen correlation/allocation screen before implementation or Model 4.');$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
@('# Low-Activity Diversifier Holdout Metrics','',"- Parsed reports: ``$($results.Count) / $($queue.Count)``","- Results SHA-256: ``$resultsHash``",'- Starting deposit: `$10,000`','- Requested risk: `0.10%`','- Real-account trading: disabled','','See `outputs/LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_DECISION.md`.') | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII
$decision
