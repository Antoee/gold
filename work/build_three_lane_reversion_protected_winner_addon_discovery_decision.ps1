param(
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_reversion_protected_winner_addon_discovery_model1_package\reports_here',
   [string]$ResultsPath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_DECISION.md',
   [string]$RunAttestationPath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_RUN_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = '1C28EC85646409F3C82E584AD2DA66E6A4FA936CEFAE142D09846694E5369FE2'
$expectedBinarySha256 = 'E4F17841780D7C6DCB96FCE88AFAF17626958571AD3D4844B9C55BC804070CFD'
$controlName = 'rvpwa_control'
$lowerTriggerName = 'rvpwa_trigger075'
$centerName = 'rvpwa_center'
$upperTriggerName = 'rvpwa_trigger125'
$lowerRiskName = 'rvpwa_risk010'
$upperRiskName = 'rvpwa_risk020'
$continuousWindow = 'continuous_2015_2020'
$windows = @('older_2015_2018','later_2019_2020',$continuousWindow)

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Money([double]$Value) {
   $sign = if($Value -ge 0.0) { '+' } else { '-' }
   return $sign + '$' + [Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}
function BoolText([bool]$Value) {
   if($Value) { return 'PASS' }
   return 'FAIL'
}
function Convert-HtmlCell([string]$Html) {
   return ([Net.WebUtility]::HtmlDecode([regex]::Replace($Html, '<[^>]+>', ''))).Trim()
}
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
      if($cells[4] -in @('in','in/out') -and $cells[12] -like 'RRO_ADD_*') { $count++ }
   }
   return $count
}

$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
if($manifest.Count -ne 18) { throw 'Expected eighteen frozen Model 1 manifest rows.' }
if(@($manifest | Where-Object { $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 }).Count -ne 0) {
   throw 'Manifest source or model identity changed.'
}
if(@($manifest.Candidate | Sort-Object -Unique).Count -ne 6 -or @($manifest.Window | Sort-Object -Unique).Count -ne 3) {
   throw 'Manifest candidate/window topology changed.'
}

$rawResults = 'work\RVPWAD_RAW_RESULTS.csv'
$rawSummary = 'work\RVPWAD_RAW_SUMMARY.csv'
$rawMetrics = 'work\RVPWAD_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }

$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
if($raw.Count -ne 18 -or @($raw | Where-Object Status -ne 'PARSED').Count -ne 0) {
   throw 'Expected eighteen parsed reports.'
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$workerRows = [Collections.Generic.List[object]]::new()
$workerFiles = @(
   Get-ChildItem (Join-Path $repo 'outputs') -Filter 'THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_EXACT_?.csv' -File
   Get-ChildItem (Join-Path $repo 'outputs') -Filter 'THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_RETRY_?.csv' -File
) | Sort-Object Name
foreach($file in $workerFiles) {
   foreach($row in @(Import-Csv -LiteralPath $file.FullName)) { $workerRows.Add($row) | Out-Null }
}
if($workerRows.Count -ne 19 -or @($workerRows | Where-Object {
   $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableExpertRecompiled -ne 'False' -or
   ($_.Status -eq 'REPORT_FOUND' -and $_.PortableBinarySha256 -ne $expectedBinarySha256)
}).Count -ne 0) {
   throw 'Runner evidence is incomplete or has an identity mismatch.'
}
$workerByRank = @{}
foreach($rank in 1..18) {
   $attempts = @($workerRows | Where-Object { [int]$_.QueueRank -eq $rank })
   $valid = @($attempts | Where-Object Status -eq 'REPORT_FOUND' | Sort-Object Finished)
   if($valid.Count -ne 1) { throw "Rank $rank does not have exactly one valid final report." }
   $workerByRank[[string]$rank] = $valid[0]
}
if(@($workerRows | Where-Object Status -eq 'ERROR').Count -ne 1) {
   throw 'Expected one preserved identity-only refusal.'
}

$results = [Collections.Generic.List[object]]::new()
$attestation = [Collections.Generic.List[object]]::new()
foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   $run = $workerByRank[[string]$item.QueueRank]
   if($null -eq $parsed -or $null -eq $run) { throw "Evidence missing for rank $($item.QueueRank)." }
   $identityPath = [string]$run.ReportIdentityPath
   if(!(Test-Path -LiteralPath $identityPath -PathType Leaf)) { throw "Identity sidecar missing for rank $($item.QueueRank)." }
   $identity = Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json
   if($identity.SourceSha256 -ne $expectedSourceSha256 -or
      $identity.PortableBinarySha256 -ne $expectedBinarySha256 -or
      $identity.ReportSha256 -ne $run.ReportSha256) {
      throw "Identity sidecar mismatch for rank $($item.QueueRank)."
   }
   $returnDrawdown = if([double]$parsed.MaxDrawdownPercent -gt 0.0) {
      [double]$parsed.TotalReturnPercent / [double]$parsed.MaxDrawdownPercent
   } else { 0.0 }
   $addOnEntries = Count-AddOnEntries ([string]$parsed.ReportPath)
   $results.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role
      StrongSignalRiskEnabled=$item.StrongSignalRiskEnabled;AddOnEnabled=$item.AddOnEnabled
      AddOnTriggerR=[double]$item.AddOnTriggerR;AddOnPrimaryLockR=[double]$item.AddOnPrimaryLockR
      AddOnRiskPercent=[double]$item.AddOnRiskPercent;AddOnEntries=$addOnEntries
      Window=$item.Window;From=$item.From;To=$item.To;Model=[int]$item.Model
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256
      Status=$parsed.Status;NetProfit=[math]::Round([double]$parsed.NetProfit,2)
      TotalReturnPercent=[math]::Round([double]$parsed.TotalReturnPercent,2);CagrPercent=[math]::Round([double]$parsed.CagrPercent,2)
      ProfitFactor=[math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades
      WinRatePercent=[math]::Round([double]$parsed.WinRatePercent,2);MaxDrawdownPercent=[math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor=[math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[math]::Round($returnDrawdown,4)
      SharpeRatio=[math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses
      ReportSha256=$run.ReportSha256
   }) | Out-Null
   $attestation.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status
      Attempts=@($workerRows | Where-Object { [int]$_.QueueRank -eq [int]$item.QueueRank }).Count
      IdentityRetries=@($workerRows | Where-Object { [int]$_.QueueRank -eq [int]$item.QueueRank -and $_.Status -eq 'ERROR' }).Count
      SourceSha256=$run.PackageSourceSha256;BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256
      ReportSha256=$run.ReportSha256;IdentitySidecarPresent=$true;PortableExpertRecompiled=$false
      Started=$run.Started;Finished=$run.Finished
   }) | Out-Null
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$attestation | Export-Csv -LiteralPath (Resolve-RepoPath $RunAttestationPath) -NoTypeInformation -Encoding ASCII

$byCandidateWindow = @{}
foreach($row in $results) { $byCandidateWindow["$($row.Candidate)|$($row.Window)"] = $row }
$control = $byCandidateWindow["$controlName|$continuousWindow"]
$lowerTrigger = $byCandidateWindow["$lowerTriggerName|$continuousWindow"]
$center = $byCandidateWindow["$centerName|$continuousWindow"]
$upperTrigger = $byCandidateWindow["$upperTriggerName|$continuousWindow"]
$lowerRisk = $byCandidateWindow["$lowerRiskName|$continuousWindow"]
$upperRisk = $byCandidateWindow["$upperRiskName|$continuousWindow"]

function EveryWindowAtLeast([string]$CandidateName, [string]$ControlName, [double]$Ratio) {
   return @($windows | Where-Object {
      [double]$byCandidateWindow["$CandidateName|$_"].NetProfit -lt $Ratio * [double]$byCandidateWindow["$ControlName|$_"].NetProfit
   }).Count -eq 0
}
function NeighborPass($Neighbor, [string]$Name) {
   $disjointPositive = [double]$byCandidateWindow["$Name|older_2015_2018"].NetProfit -gt 0.0 -and
      [double]$byCandidateWindow["$Name|later_2019_2020"].NetProfit -gt 0.0
   return $disjointPositive -and
      [double]$Neighbor.NetProfit -ge 1.01 * [double]$control.NetProfit -and
      [double]$Neighbor.CagrPercent -ge [double]$control.CagrPercent + 0.02 -and
      [double]$Neighbor.ProfitFactor -ge [double]$control.ProfitFactor -and
      [double]$Neighbor.RecoveryFactor -ge [double]$control.RecoveryFactor -and
      [double]$Neighbor.ReturnDrawdown -ge [double]$control.ReturnDrawdown -and
      [double]$Neighbor.MaxDrawdownPercent -le 1.25 -and [int]$Neighbor.AddOnEntries -ge 2
}

$allWindowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$centerEveryWindow = EveryWindowAtLeast $centerName $controlName 1.0
$centerGrowth = [double]$center.NetProfit -ge 1.03 * [double]$control.NetProfit
$centerCagr = [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.05
$centerEfficiency = [double]$center.ProfitFactor -ge [double]$control.ProfitFactor -and
   [double]$center.RecoveryFactor -ge [double]$control.RecoveryFactor -and
   [double]$center.ReturnDrawdown -ge [double]$control.ReturnDrawdown
$centerRisk = [double]$center.MaxDrawdownPercent -le 1.25 -and
   [double]$center.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent + 0.08
$centerActivity = [int]$center.AddOnEntries -ge 3
$lowerTriggerGate = NeighborPass $lowerTrigger $lowerTriggerName
$upperTriggerGate = NeighborPass $upperTrigger $upperTriggerName
$lowerRiskGate = NeighborPass $lowerRisk $lowerRiskName
$upperRiskGate = NeighborPass $upperRisk $upperRiskName
$passed = $allWindowsPositive -and $centerEveryWindow -and $centerGrowth -and $centerCagr -and
   $centerEfficiency -and $centerRisk -and $centerActivity -and $lowerTriggerGate -and
   $upperTriggerGate -and $lowerRiskGate -and $upperRiskGate

$summary = foreach($name in @($controlName,$lowerTriggerName,$centerName,$upperTriggerName,$lowerRiskName,$upperRiskName)) {
   $continuous = $byCandidateWindow["$name|$continuousWindow"]
   [pscustomobject][ordered]@{
      Candidate=$name;Role=$continuous.Role;AddOnEnabled=$continuous.AddOnEnabled
      AddOnTriggerR=$continuous.AddOnTriggerR;AddOnPrimaryLockR=$continuous.AddOnPrimaryLockR
      AddOnRiskPercent=$continuous.AddOnRiskPercent
      OlderNetProfit=$byCandidateWindow["$name|older_2015_2018"].NetProfit
      LaterNetProfit=$byCandidateWindow["$name|later_2019_2020"].NetProfit
      ContinuousNetProfit=$continuous.NetProfit;TotalReturnPercent=$continuous.TotalReturnPercent;CagrPercent=$continuous.CagrPercent
      ProfitFactor=$continuous.ProfitFactor;TotalTrades=$continuous.TotalTrades;MaxDrawdownPercent=$continuous.MaxDrawdownPercent
      RecoveryFactor=$continuous.RecoveryFactor;ReturnDrawdown=$continuous.ReturnDrawdown;AddOnEntries=$continuous.AddOnEntries
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=$results.Count
   IdentityValidReports=$attestation.Count;TotalAttempts=$workerRows.Count;IdentityRetries=@($workerRows|Where-Object Status -eq 'ERROR').Count
   AllWindowsPositive=$allWindowsPositive;CenterNoWorseEveryWindow=$centerEveryWindow
   CenterGrowthGate=$centerGrowth;CenterCagrGate=$centerCagr;CenterEfficiencyGate=$centerEfficiency
   CenterRiskGate=$centerRisk;CenterActivityGate=$centerActivity;LowerTriggerGate=$lowerTriggerGate
   UpperTriggerGate=$upperTriggerGate;LowerRiskGate=$lowerRiskGate;UpperRiskGate=$upperRiskGate
   HoldoutValidationPermitted=$passed;Model4ValidationPermitted=$false
   ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
   ControlNetProfit=$control.NetProfit;CenterNetProfit=$center.NetProfit;CenterAddOnEntries=$center.AddOnEntries
   LowerTriggerNetProfit=$lowerTrigger.NetProfit;UpperTriggerNetProfit=$upperTrigger.NetProfit
   LowerRiskNetProfit=$lowerRisk.NetProfit;UpperRiskNetProfit=$upperRisk.NetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;CenterProfileSha256=$center.ProfileSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Reversion Protected Winner Add-On Discovery Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. The frozen holdout may open; Model 4, promotion, and forward changes remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No holdout, Model 4, promotion, forward change, or live approval is permitted.**'}))
$lines.Add('')
$lines.Add('- Reports: `18 / 18` parsed with exact source/binary identity valid')
$lines.Add('- Attempts: `19`; identity-only retries: `1`')
$lines.Add("- Exact source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- Exact EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add('- Mechanism: strong-signal reversion winner only, one add-on maximum, primary stop locked first, locked-profit coverage, minimum remaining reward, and account-wide risk reconciliation')
$lines.Add('- Frozen risk context: strong-reversion requested risk `0.70%`, adaptive-trend risk `0.15%`, add-on risk `0.10%` to `0.20%`')
$lines.Add('- Real-account trading: disabled')
$lines.Add('')
$lines.Add('| Profile | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | Add-ons | DD | Recovery | Return/DD |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
foreach($row in $summary) {
   $label = switch($row.Candidate) {
      $controlName {'Control (disabled)'}
      $lowerTriggerName {'Trigger 0.75R'}
      $centerName {'Center 1.00R / 0.15%'}
      $upperTriggerName {'Trigger 1.25R'}
      $lowerRiskName {'Risk 0.10%'}
      $upperRiskName {'Risk 0.20%'}
   }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.LaterNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.AddOnEntries) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add("- Every report profitable: ``$allWindowsPositive`` ($(BoolText $allWindowsPositive))")
$lines.Add("- Center no worse than control in every window: ``$centerEveryWindow`` ($(BoolText $centerEveryWindow))")
$lines.Add("- Center growth gate: ``$centerGrowth`` ($(BoolText $centerGrowth))")
$lines.Add("- Center CAGR gate: ``$centerCagr`` ($(BoolText $centerCagr))")
$lines.Add("- Center PF/recovery/return-DD gate: ``$centerEfficiency`` ($(BoolText $centerEfficiency))")
$lines.Add("- Center drawdown gate: ``$centerRisk`` ($(BoolText $centerRisk))")
$lines.Add("- Center activity gate: ``$centerActivity`` ($(BoolText $centerActivity))")
$lines.Add("- Trigger 0.75R neighbor gate: ``$lowerTriggerGate`` ($(BoolText $lowerTriggerGate))")
$lines.Add("- Trigger 1.25R neighbor gate: ``$upperTriggerGate`` ($(BoolText $upperTriggerGate))")
$lines.Add("- Risk 0.10% neighbor gate: ``$lowerRiskGate`` ($(BoolText $lowerRiskGate))")
$lines.Add("- Risk 0.20% neighbor gate: ``$upperRiskGate`` ($(BoolText $upperRiskGate))")
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$lines.Add("The center, trigger-0.75R, and risk-0.20% variants produced zero add-ons and were behaviorally identical to the control at ``$(Money ([double]$control.NetProfit))`` continuous net. The active trigger-1.25R variant opened ``$($upperTrigger.AddOnEntries)`` add-ons but reduced net to ``$(Money ([double]$upperTrigger.NetProfit))`` and PF to ``$($upperTrigger.ProfitFactor)``. The active risk-0.10% variant opened ``$($lowerRisk.AddOnEntries)`` add-ons and fell further to ``$(Money ([double]$lowerRisk.NetProfit))`` with PF ``$($lowerRisk.ProfitFactor)``.")
$lines.Add('')
$lines.Add($(if($passed){'The complete preregistered discovery neighborhood passed. Only the exact frozen center may proceed to the unopened 2021-26 holdout; Model 4 remains closed until that holdout passes.'}else{'The protected winner add-on did not improve the pre-2021 portfolio. Active variants materially degraded payoff, so the family is rejected without post-result trigger, lock, risk, coverage, or reward retuning. The 2021-26 holdout and Model 4 remain unopened, and ATB150 remains the historical champion.'}))
$lines.Add('')
$lines.Add('The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
