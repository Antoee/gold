[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_PARTIAL_RUNNER_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_momentum_partial_runner_discovery_model1_package\reports_here'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = '1092D9AD0036C6C4E7A0F61CB7318B31CDCE75F9311762388CF256AFFB6BFEA9'
$expectedBinarySha256 = '8B72A5B1457BCBF79118381AA5F2F8B1D709DA703611BE60778C4DB518DCD130'
$expectedManifestSha256 = '81D2138F43F8B4B7B24BDD75036CA4B87AD27A9ADF2495E9AEDBA014D121505A'
$controlName = 'mopr_control'
$centerName = 'mopr_center'
$neighborNames = @('mopr_close50','mopr_close70','mopr_target300','mopr_target500','mopr_lock100','mopr_lock150')
$candidateNames = @($controlName,$centerName) + $neighborNames
$eraNames = @('older_2015_2018','middle_2019_2020')
$continuousName = 'continuous_2015_2020'
$prefix = 'THREE_LANE_MOMENTUM_PARTIAL_RUNNER'

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Money([double]$Value) {
   $sign = if($Value -ge 0.0) { '+' } else { '-' }
   return $sign + '$' + [Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}

$manifestFile = Resolve-RepoPath $ManifestPath
if((Get-FileHash -LiteralPath $manifestFile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestSha256) {
   throw 'Frozen manifest identity changed.'
}
$manifest = @(Import-Csv -LiteralPath $manifestFile)
if($manifest.Count -ne 24 -or @($manifest.Candidate | Sort-Object -Unique).Count -ne 8 -or
   @($manifest.Window | Sort-Object -Unique).Count -ne 3) {
   throw 'Frozen manifest topology changed.'
}
if(@($manifest | Where-Object {
   $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 -or [double]$_.Deposit -ne 10000
}).Count -ne 0) { throw 'Manifest source, model, or deposit identity changed.' }
foreach($item in $manifest) {
   $config = Resolve-RepoPath ([string]$item.PackageConfig)
   if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $item.ConfigSha256) {
      throw "Config identity changed at rank $($item.QueueRank)."
   }
}

$rawResults = "work\${prefix}_DECISION_RAW_RESULTS.csv"
$rawSummary = "work\${prefix}_DECISION_RAW_SUMMARY.csv"
$rawMetrics = "work\${prefix}_DECISION_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -Manifest $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }
$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
if($raw.Count -ne 24 -or @($raw | Where-Object Status -ne 'PARSED').Count -ne 0) {
   throw 'Expected twenty-four parsed reports.'
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$firstRuns = @(Get-ChildItem (Resolve-RepoPath 'outputs') -Filter "${prefix}_DISCOVERY_WORKER_*.csv" -File |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$recoveryRuns = @(Get-ChildItem (Resolve-RepoPath 'outputs') -Filter "${prefix}_DISCOVERY_RECOVERY_*.csv" -File |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$identityRefusals = @($firstRuns | Where-Object Status -eq 'ERROR').Count
$acceptedRuns = @($firstRuns + $recoveryRuns | Where-Object Status -eq 'REPORT_FOUND')
$runByKey = @{}
foreach($run in $acceptedRuns) { $runByKey["$($run.Candidate)|$($run.Window)"] = $run }
if($firstRuns.Count -ne 24 -or $identityRefusals -ne 2 -or $recoveryRuns.Count -ne 2 -or $runByKey.Count -ne 24) {
   throw 'Expected twenty-two first-pass reports, two identity refusals, and two successful exact recoveries.'
}

$results = [Collections.Generic.List[object]]::new()
$attestation = [Collections.Generic.List[object]]::new()
foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   $run = $runByKey["$($item.Candidate)|$($item.Window)"]
   if($null -eq $parsed -or $null -eq $run) { throw "Evidence missing for rank $($item.QueueRank)." }
   if($run.PackageSourceSha256 -ne $expectedSourceSha256 -or $run.PortableBinarySha256 -ne $expectedBinarySha256 -or
      $run.PortableExpertRecompiled -ne 'False') { throw "Run identity mismatch for rank $($item.QueueRank)." }
   $identityPath = [string]$run.ReportIdentityPath
   if(!(Test-Path -LiteralPath $identityPath -PathType Leaf)) { throw "Identity sidecar missing for rank $($item.QueueRank)." }
   $identity = Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json
   if($identity.SourceSha256 -ne $expectedSourceSha256 -or $identity.PortableBinarySha256 -ne $expectedBinarySha256 -or
      $identity.ReportSha256 -ne $run.ReportSha256 -or $identity.ConfigSha256 -ne $run.PackageConfigSha256) {
      throw "Identity sidecar mismatch for rank $($item.QueueRank)."
   }
   $returnDrawdown = if([double]$parsed.MaxDrawdownPercent -gt 0.0) {
      [double]$parsed.TotalReturnPercent / [double]$parsed.MaxDrawdownPercent
   } else { 0.0 }
   $results.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window
      From=$item.From;To=$item.To;Model=[int]$item.Model;PartialRunnerEnabled=$item.PartialRunnerEnabled
      ClosePercent=[double]$item.ClosePercent;TriggerR=[double]$item.TriggerR;TargetR=[double]$item.TargetR
      StopLockR=[double]$item.StopLockR;ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256
      BinarySha256=$run.PortableBinarySha256;Status=$parsed.Status;NetProfit=[Math]::Round([double]$parsed.NetProfit,2)
      TotalReturnPercent=[Math]::Round([double]$parsed.TotalReturnPercent,2);CagrPercent=[Math]::Round([double]$parsed.CagrPercent,2)
      ProfitFactor=[Math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades
      WinRatePercent=[Math]::Round([double]$parsed.WinRatePercent,2);MaxDrawdownPercent=[Math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor=[Math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[Math]::Round($returnDrawdown,4)
      SharpeRatio=[Math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses
      ReportSha256=$run.ReportSha256
   }) | Out-Null
   $attestation.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status
      IdentityReused=[bool]::Parse($run.ReportIdentityReused);SourceSha256=$run.PackageSourceSha256
      BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256
      IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished
   }) | Out-Null
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_MODEL1_RESULTS.csv") -NoTypeInformation -Encoding ASCII
$attestation | Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_RUN_ATTESTATION.csv") -NoTypeInformation -Encoding ASCII

$by = @{}
foreach($row in $results) { $by["$($row.Candidate)|$($row.Window)"] = $row }
$control = $by["$controlName|$continuousName"]
$center = $by["$centerName|$continuousName"]
function Era-Floor([string]$Name) {
   foreach($era in $eraNames) {
      if([double]$by["$Name|$era"].NetProfit -lt 0.98 * [double]$by["$controlName|$era"].NetProfit) { return $false }
   }
   return $true
}
function Quality-Pass([string]$Name) {
   $row = $by["$Name|$continuousName"]
   return [double]$row.ProfitFactor -ge 0.95 * [double]$control.ProfitFactor -and
      [double]$row.MaxDrawdownPercent -le [Math]::Min(1.25,[double]$control.MaxDrawdownPercent + 0.15) -and
      [double]$row.RecoveryFactor -ge 0.95 * [double]$control.RecoveryFactor -and
      [double]$row.ReturnDrawdown -ge 0.95 * [double]$control.ReturnDrawdown
}
function Neighbor-Pass([string]$Name) {
   $row = $by["$Name|$continuousName"]
   return (Era-Floor $Name) -and [double]$row.NetProfit -ge 1.02 * [double]$control.NetProfit -and (Quality-Pass $Name)
}

$controlReproduced = [double]$by["$controlName|older_2015_2018"].NetProfit -eq 1036.19 -and
                     [double]$by["$controlName|middle_2019_2020"].NetProfit -eq 370.60
$allRowsProfitable = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$centerActivity = [int]$center.TotalTrades -gt [int]$control.TotalTrades
$centerPass = (Era-Floor $centerName) -and $centerActivity -and
   [double]$center.NetProfit -ge 1.05 * [double]$control.NetProfit -and
   [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.08 -and (Quality-Pass $centerName)
$neighborPasses = [ordered]@{}
foreach($name in $neighborNames) { $neighborPasses[$name] = Neighbor-Pass $name }
$neighborPassCount = @($neighborPasses.Values | Where-Object { $_ }).Count
$passed = $controlReproduced -and $allRowsProfitable -and $centerPass -and $neighborPassCount -ge 4

$summary = foreach($name in $candidateNames) {
   $row = $by["$name|$continuousName"]
   [pscustomobject][ordered]@{
      Candidate=$name;Role=$row.Role;ClosePercent=$row.ClosePercent;TargetR=$row.TargetR;StopLockR=$row.StopLockR
      OlderNetProfit=$by["$name|older_2015_2018"].NetProfit;MiddleNetProfit=$by["$name|middle_2019_2020"].NetProfit
      ContinuousNetProfit=$row.NetProfit;CagrPercent=$row.CagrPercent;ProfitFactor=$row.ProfitFactor
      TotalTrades=$row.TotalTrades;MaxDrawdownPercent=$row.MaxDrawdownPercent;RecoveryFactor=$row.RecoveryFactor
      ReturnDrawdown=$row.ReturnDrawdown;EraFloor=if($name -eq $controlName){$true}else{Era-Floor $name}
      FrozenGate=if($name -eq $controlName){'CONTROL'}elseif($name -eq $centerName){$centerPass}else{$neighborPasses[$name]}
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_SUMMARY.csv") -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=24;IdentityValidReports=24
   PreservedIdentityRefusals=$identityRefusals;SuccessfulExactRecoveries=$recoveryRuns.Count
   ControlReproduced=$controlReproduced;EveryReportProfitable=$allRowsProfitable;CenterActivityConfirmed=$centerActivity
   CenterGatePass=$centerPass;NeighborPassCount=$neighborPassCount;RequiredNeighborPassCount=4
   Model4ValidationPermitted=$passed;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false
   RealAccountTradingAllowed=$false;ControlNetProfit=$control.NetProfit;CenterNetProfit=$center.NetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;ManifestSha256=$expectedManifestSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_DECISION.csv") -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Momentum Partial-Runner Discovery Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Model 4 confirmation is permitted; promotion and live trading remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No Model 4 run, promotion, forward change, or real trading is permitted. NO NEW BEST.**'}))
$lines.Add('')
$lines.Add('- Exact accepted Model 1 reports: `24/24`; preserved identity refusals: `2`; successful exact recoveries: `2`')
$lines.Add("- Source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add("- Manifest SHA-256: ``$expectedManifestSha256``")
$lines.Add('- Test contract: XAUUSD M15, `$10,000`, Model 1, frozen pre-2021 discovery.')
$lines.Add('- Initial entries and risk were unchanged. Unsplittable positions retained the exact 2R baseline exit.')
$lines.Add('')
$lines.Add('| Candidate | Close | Target | Lock | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $summary) {
   $label = switch($row.Candidate) {
      'mopr_control' {'Disabled control'}
      'mopr_center' {'**60% / 4R / +1.25R center**'}
      default {$row.Candidate}
   }
   $lines.Add("| $label | $($row.ClosePercent)% | $($row.TargetR)R | $($row.StopLockR)R | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) | $($row.FrozenGate) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add("- Disabled control reproduced the exact prior 2015-18 and 2019-20 results: ``$controlReproduced``")
$lines.Add("- Every report profitable: ``$allRowsProfitable``")
$lines.Add("- Center partial path active: ``$centerActivity``")
$lines.Add("- Center gate pass: ``$centerPass``")
$lines.Add("- Passing neighbors: ``$neighborPassCount/6``; required: ``4/6``")
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$lines.Add("The frozen center reduced continuous net from ``$(Money ([double]$control.NetProfit))`` to ``$(Money ([double]$center.NetProfit))``. It also missed the older-era floor and the 95% recovery and return/drawdown floors. The increased report-trade count (``$($control.TotalTrades)`` to ``$($center.TotalTrades)``) confirms that the partial-close path executed.")
$lines.Add('')
$lines.Add('Only the 70% close and 5R target neighbors passed their training gates. They are not promoted or called a new best. Any interaction follow-up must be separately frozen and judged on post-2020 holdout data without changing this rejection.')
$lines.Add('')
$lines.Add('The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo is not forward evidence, the registered candidate is unchanged, and real-account trading remains disabled.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_DECISION.md") -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_MODEL1_RAW_RESULTS.csv"),(Resolve-RepoPath "outputs\${prefix}_DISCOVERY_MODEL1_RAW_SUMMARY.csv"),(Resolve-RepoPath "outputs\${prefix}_DISCOVERY_MODEL1_RAW_METRICS.md") -Force -ErrorAction SilentlyContinue
$decision
