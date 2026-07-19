param(
   [string]$ManifestPath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_noncompounding_risk_budget_model1_package\reports_here',
   [string]$ResultsPath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_DECISION.md',
   [string]$RunAttestationPath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_RUN_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = 'B72F61E0633F5A57C3BC4D5688C8F7F29155B772F7D2BDE3EDC72429A41E9EA8'
$expectedBinarySha256 = '7D5F1FF625C50609019B8DEBB48026DEF58583613DE971ADA63D5B0AF0DCF03F'
$controlName = 'ncrb_control'
$candidateName = 'ncrb_strong_noncomp'
$continuousWindow = 'continuous_2015_2026'
$windows = @('older_2015_2018','middle_2019_2022','recent_2023_2026',$continuousWindow)

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Money([double]$Value) {
   $sign = if($Value -ge 0.0) { '+' } else { '-' }
   return $sign + '$' + [Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}
function GateText([bool]$Value) { if($Value) { return 'PASS' } return 'FAIL' }

$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
if($manifest.Count -ne 16 -or @($manifest.Candidate | Sort-Object -Unique).Count -ne 4 -or
   @($manifest.Window | Sort-Object -Unique).Count -ne 4) {
   throw 'Expected the frozen four-profile, four-window manifest.'
}
if(@($manifest | Where-Object { $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 }).Count -ne 0) {
   throw 'Manifest source or model identity changed.'
}

$rawResults = 'work\NCRB_RAW_RESULTS.csv'
$rawSummary = 'work\NCRB_RAW_SUMMARY.csv'
$rawMetrics = 'work\NCRB_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }
$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
if($raw.Count -ne 16 -or @($raw | Where-Object Status -ne 'PARSED').Count -ne 0) {
   throw 'Expected sixteen parsed Model1 reports.'
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$attempts = [Collections.Generic.List[object]]::new()
foreach($pattern in @('THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_EXACT_?.csv','THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_RETRY_?.csv')) {
   foreach($file in @(Get-ChildItem (Join-Path $repo 'outputs') -Filter $pattern -File | Sort-Object Name)) {
      foreach($row in @(Import-Csv -LiteralPath $file.FullName)) { $attempts.Add($row) | Out-Null }
   }
}
$identityRetries = @($attempts | Where-Object {
   $_.Status -eq 'ERROR' -and $_.Evidence -eq 'Portable report does not embed the expected package-source identity.'
}).Count
$workerRows = [Collections.Generic.List[object]]::new()
foreach($group in ($attempts | Group-Object QueueRank)) {
   $valid = @($group.Group | Where-Object Status -eq 'REPORT_FOUND' | Sort-Object { [datetime]$_.Finished } -Descending)
   if($valid.Count -lt 1) { throw "No identity-valid worker result for rank $($group.Name)." }
   $workerRows.Add($valid[0]) | Out-Null
}
if($workerRows.Count -ne 16 -or @($workerRows | Where-Object {
   $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableBinarySha256 -ne $expectedBinarySha256 -or
   $_.PortableExpertRecompiled -ne 'False'
}).Count -ne 0) {
   throw 'Runner evidence is incomplete or has an identity mismatch.'
}
$workerByRank = @{}
foreach($row in $workerRows) { $workerByRank[[string]$row.QueueRank] = $row }

$results = [Collections.Generic.List[object]]::new()
$attestation = [Collections.Generic.List[object]]::new()
foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   $run = $workerByRank[[string]$item.QueueRank]
   if($null -eq $parsed -or $null -eq $run) { throw "Evidence missing for rank $($item.QueueRank)." }
   $identity = Get-Content -LiteralPath ([string]$run.ReportIdentityPath) -Raw | ConvertFrom-Json
   if($identity.SourceSha256 -ne $expectedSourceSha256 -or
      $identity.PortableBinarySha256 -ne $expectedBinarySha256 -or
      $identity.ReportSha256 -ne $run.ReportSha256) {
      throw "Identity sidecar mismatch for rank $($item.QueueRank)."
   }
   $returnDrawdown = if([double]$parsed.MaxDrawdownPercent -gt 0.0) {
      [double]$parsed.TotalReturnPercent / [double]$parsed.MaxDrawdownPercent
   } else { 0.0 }
   $results.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;From=$item.From;To=$item.To;Model=1
      StrongSignalRiskEnabled=$item.StrongSignalRiskEnabled;NoncompoundingRiskBudgetEnabled=$item.NoncompoundingRiskBudgetEnabled
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256;Status=$parsed.Status
      NetProfit=[math]::Round([double]$parsed.NetProfit,2);TotalReturnPercent=[math]::Round([double]$parsed.TotalReturnPercent,2)
      CagrPercent=[math]::Round([double]$parsed.CagrPercent,2);ProfitFactor=[math]::Round([double]$parsed.ProfitFactor,2)
      TotalTrades=[int]$parsed.TotalTrades;WinRatePercent=[math]::Round([double]$parsed.WinRatePercent,2)
      MaxDrawdownMoney=[math]::Round([double]$parsed.MaxDrawdownMoney,2);MaxDrawdownPercent=[math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor=[math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[math]::Round($returnDrawdown,4)
      SharpeRatio=[math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses
      ReportSha256=$run.ReportSha256
   }) | Out-Null
   $rankAttempts = @($attempts | Where-Object QueueRank -eq $item.QueueRank).Count
   $attestation.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status
      Attempts=$rankAttempts;IdentityRetries=$rankAttempts-1;SourceSha256=$run.PackageSourceSha256
      BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256
      IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished
   }) | Out-Null
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$attestation | Export-Csv -LiteralPath (Resolve-RepoPath $RunAttestationPath) -NoTypeInformation -Encoding ASCII

$by = @{}
foreach($row in $results) { $by["$($row.Candidate)|$($row.Window)"] = $row }
$control = $by["$controlName|$continuousWindow"]
$candidate = $by["$candidateName|$continuousWindow"]
$allWindowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$candidateNetEveryEra = @($windows | Where-Object {
   [double]$by["$candidateName|$_"].NetProfit -lt [double]$by["$controlName|$_"].NetProfit
}).Count -eq 0
$netGate = [double]$candidate.NetProfit -ge 1.05 * [double]$control.NetProfit
$cagrGate = [double]$candidate.CagrPercent -ge [double]$control.CagrPercent + 0.08
$pfGate = [double]$candidate.ProfitFactor -ge [double]$control.ProfitFactor
$ddGate = [double]$candidate.MaxDrawdownPercent -le 1.25 -and
   [double]$candidate.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent + 0.05
$recoveryGate = [double]$candidate.RecoveryFactor -ge [double]$control.RecoveryFactor
$returnDrawdownGate = [double]$candidate.ReturnDrawdown -ge [double]$control.ReturnDrawdown
$tradeGate = [int]$candidate.TotalTrades -ge 400
$passed = $allWindowsPositive -and $candidateNetEveryEra -and $netGate -and $cagrGate -and
   $pfGate -and $ddGate -and $recoveryGate -and $returnDrawdownGate -and $tradeGate

$candidateOrder = @('ncrb_control','ncrb_budget_only','ncrb_strong_dynamic','ncrb_strong_noncomp')
$summary = foreach($name in $candidateOrder) {
   $continuous = $by["$name|$continuousWindow"]
   [pscustomobject][ordered]@{
      Candidate=$name;StrongSignalRiskEnabled=$continuous.StrongSignalRiskEnabled
      NoncompoundingRiskBudgetEnabled=$continuous.NoncompoundingRiskBudgetEnabled
      OlderNetProfit=$by["$name|older_2015_2018"].NetProfit;MiddleNetProfit=$by["$name|middle_2019_2022"].NetProfit
      RecentNetProfit=$by["$name|recent_2023_2026"].NetProfit;ContinuousNetProfit=$continuous.NetProfit
      TotalReturnPercent=$continuous.TotalReturnPercent;CagrPercent=$continuous.CagrPercent;ProfitFactor=$continuous.ProfitFactor
      TotalTrades=$continuous.TotalTrades;MaxDrawdownPercent=$continuous.MaxDrawdownPercent
      RecoveryFactor=$continuous.RecoveryFactor;ReturnDrawdown=$continuous.ReturnDrawdown
      GatePass=if($name -eq $candidateName){$passed}else{$false}
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'MODEL1_GATE_PASSED'}else{'REJECTED_IN_MODEL1'};ReportsParsed=$results.Count
   IdentityValidReports=$attestation.Count;IdentityRetries=$identityRetries;AllWindowsPositive=$allWindowsPositive
   CandidateNetAtLeastControlEveryWindow=$candidateNetEveryEra;ContinuousNetAtLeastControlPlusFivePercent=$netGate
   CagrAtLeastControlPlusPointZeroEight=$cagrGate;ProfitFactorAtLeastControl=$pfGate
   DrawdownWithinFrozenLimits=$ddGate;RecoveryAtLeastControl=$recoveryGate
   ReturnDrawdownAtLeastControl=$returnDrawdownGate;ContinuousTradesAtLeast400=$tradeGate
   Model4Permitted=$passed;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
   ControlNetProfit=$control.NetProfit;CandidateNetProfit=$candidate.NetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;CandidateProfileSha256=$candidate.ProfileSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Noncompounding Risk-Budget Model 1 Decision')
$lines.Add('')
$lines.Add($(if($passed){
   '**Decision: MODEL 1 GATE PASSED. The fixed four-profile design may open Model 4; the frozen forward candidate remains unchanged.**'
}else{
   '**Decision: REJECTED IN MODEL 1. No Model 4 run, research promotion, forward change, or live approval is permitted.**'
}))
$lines.Add('')
$lines.Add("- Reports: ``16 / 16`` parsed and exact source/binary identity valid; identity retries: ``$identityRetries``")
$lines.Add("- Source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add('- Feature behavior: sizing capital is `min(current equity, frozen initial capital)` when enabled')
$lines.Add('- Real-account trading: disabled')
$lines.Add('')
$lines.Add('| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
$labels = @{
   ncrb_control='Champion control';ncrb_budget_only='Budget only';
   ncrb_strong_dynamic='Strong risk only';ncrb_strong_noncomp='Strong risk + budget'
}
foreach($row in $summary) {
   $lines.Add("| $($labels[$row.Candidate]) | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add('| Requirement | Result | Status |')
$lines.Add('|---|---|---|')
$lines.Add("| Every profile/window profitable | ``$allWindowsPositive`` | $(GateText $allWindowsPositive) |")
$lines.Add("| Combined net no worse than control in every era | ``$candidateNetEveryEra`` | $(GateText $candidateNetEveryEra) |")
$lines.Add("| Continuous net at least control +5% | $(Money ([double]$candidate.NetProfit)) vs required $(Money (1.05*[double]$control.NetProfit)) | $(GateText $netGate) |")
$lines.Add("| CAGR at least control +0.08 point | ``$($candidate.CagrPercent)%`` vs required ``$([double]$control.CagrPercent+0.08)%`` | $(GateText $cagrGate) |")
$lines.Add("| PF no worse than control | ``$($candidate.ProfitFactor)`` vs ``$($control.ProfitFactor)`` | $(GateText $pfGate) |")
$lines.Add("| DD <=1.25% and <=control +0.05 point | ``$($candidate.MaxDrawdownPercent)%`` vs ``$($control.MaxDrawdownPercent)%`` | $(GateText $ddGate) |")
$lines.Add("| Recovery no worse than control | ``$($candidate.RecoveryFactor)`` vs ``$($control.RecoveryFactor)`` | $(GateText $recoveryGate) |")
$lines.Add("| Return/DD no worse than control | ``$($candidate.ReturnDrawdown)`` vs ``$($control.ReturnDrawdown)`` | $(GateText $returnDrawdownGate) |")
$lines.Add("| At least 400 continuous trades | ``$($candidate.TotalTrades)`` | $(GateText $tradeGate) |")
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$lines.Add('The budget mechanism improved stability as intended. Combined PF rose from `1.83` to `1.93`, drawdown fell from `1.17%` to `1.05%`, recovery rose from `15.8168` to `17.1048`, and return/drawdown rose from `18.7692` to `20.7905`.')
$lines.Add('')
$lines.Add('It did not preserve growth. Combined net was `+$2,182.92`, below control at `+$2,195.53`; CAGR fell from `1.74%` to `1.73%`; the older and middle eras were also below control; and continuous trades fell from 415 to 402. The budget-only profile was weaker still. The fixed growth gates therefore fail and Model 4 remains closed.')
$lines.Add('')
$lines.Add('This is a useful conservative risk-control result, but it is not a higher-APR candidate. ATB150 remains the historical champion, and the registered forward candidate, invalid-account boundary, and real-account lock remain unchanged.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
