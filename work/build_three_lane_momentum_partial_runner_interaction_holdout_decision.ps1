[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_PARTIAL_RUNNER_INTERACTION_HOLDOUT_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_momentum_partial_runner_interaction_holdout_model1_package\reports_here'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceSha = '1092D9AD0036C6C4E7A0F61CB7318B31CDCE75F9311762388CF256AFFB6BFEA9'
$binarySha = '8B72A5B1457BCBF79118381AA5F2F8B1D709DA703611BE60778C4DB518DCD130'
$manifestSha = 'C4F01E5DB151660484D3BE6301ABEFB1667D9C2FA05422932610FC2CCD723A72'
$prefix = 'THREE_LANE_MOMENTUM_PARTIAL_RUNNER_INTERACTION_HOLDOUT'
$controlName = 'mopri_control'
$centerName = 'mopri_combo'
$componentNames = @('mopri_close70','mopri_target500')
$candidateNames = @($controlName) + $componentNames + @($centerName)
$eraNames = @('recent_2021_2023','latest_2024_2026')
$continuousName = 'continuous_2021_2026'

function Repo-Path([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Money([double]$Value) {
   $sign = if($Value -ge 0.0) { '+' } else { '-' }
   return $sign + '$' + [Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}

$manifestFile = Repo-Path $ManifestPath
if((Get-FileHash $manifestFile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $manifestSha) { throw 'Frozen manifest identity changed.' }
$manifest = @(Import-Csv $manifestFile)
if($manifest.Count -ne 12 -or @($manifest.Candidate | Sort-Object -Unique).Count -ne 4 -or
   @($manifest.Window | Sort-Object -Unique).Count -ne 3) { throw 'Frozen manifest topology changed.' }
foreach($item in $manifest) {
   if($item.SourceSha256 -ne $sourceSha -or [int]$item.Model -ne 1 -or [double]$item.Deposit -ne 10000) {
      throw "Manifest identity changed at rank $($item.QueueRank)."
   }
   $config = Repo-Path ([string]$item.PackageConfig)
   if((Get-FileHash $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $item.ConfigSha256) {
      throw "Config identity changed at rank $($item.QueueRank)."
   }
}

$tempResults = 'work\MOPRI_DECISION_RAW_RESULTS.csv'
$tempSummary = 'work\MOPRI_DECISION_RAW_SUMMARY.csv'
$tempMetrics = 'work\MOPRI_DECISION_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -Manifest $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults $tempResults -OutSummary $tempSummary -OutMarkdown $tempMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }
$raw = @(Import-Csv (Repo-Path $tempResults))
if($raw.Count -ne 12 -or @($raw | Where-Object Status -ne 'PARSED').Count -ne 0) { throw 'Expected twelve parsed reports.' }
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$firstRuns = @(Get-ChildItem (Repo-Path 'outputs') -Filter "${prefix}_WORKER_*.csv" -File | ForEach-Object { Import-Csv $_.FullName })
$recoveryRuns = @(Get-ChildItem (Repo-Path 'outputs') -Filter "${prefix}_RECOVERY_*.csv" -File | ForEach-Object { Import-Csv $_.FullName })
$identityRefusals = @($firstRuns | Where-Object Status -eq 'ERROR').Count
$acceptedRuns = @($firstRuns + $recoveryRuns | Where-Object Status -eq 'REPORT_FOUND')
$runByKey = @{}
foreach($run in $acceptedRuns) { $runByKey["$($run.Candidate)|$($run.Window)"] = $run }
if($firstRuns.Count -ne 12 -or $identityRefusals -ne 2 -or $recoveryRuns.Count -ne 2 -or $runByKey.Count -ne 12) {
   throw 'Expected ten first-pass reports, two identity refusals, and two successful exact recoveries.'
}

$results = [Collections.Generic.List[object]]::new()
$attestation = [Collections.Generic.List[object]]::new()
foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   $run = $runByKey["$($item.Candidate)|$($item.Window)"]
   if($null -eq $parsed -or $null -eq $run -or $run.PackageSourceSha256 -ne $sourceSha -or
      $run.PortableBinarySha256 -ne $binarySha -or $run.PortableExpertRecompiled -ne 'False') {
      throw "Run identity mismatch for rank $($item.QueueRank)."
   }
   $identity = Get-Content -LiteralPath $run.ReportIdentityPath -Raw | ConvertFrom-Json
   if($identity.SourceSha256 -ne $sourceSha -or $identity.PortableBinarySha256 -ne $binarySha -or
      $identity.ReportSha256 -ne $run.ReportSha256 -or $identity.ConfigSha256 -ne $run.PackageConfigSha256) {
      throw "Identity sidecar mismatch for rank $($item.QueueRank)."
   }
   $returnDd = if([double]$parsed.MaxDrawdownPercent -gt 0.0) {
      [double]$parsed.TotalReturnPercent / [double]$parsed.MaxDrawdownPercent
   } else { 0.0 }
   $results.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window
      From=$item.From;To=$item.To;Model=[int]$item.Model;PartialRunnerEnabled=$item.PartialRunnerEnabled
      ClosePercent=[double]$item.ClosePercent;TriggerR=[double]$item.TriggerR;TargetR=[double]$item.TargetR
      StopLockR=[double]$item.StopLockR;ProfileSha256=$item.ProfileSha256;SourceSha256=$sourceSha;BinarySha256=$binarySha
      Status=$parsed.Status;NetProfit=[Math]::Round([double]$parsed.NetProfit,2)
      TotalReturnPercent=[Math]::Round([double]$parsed.TotalReturnPercent,2);CagrPercent=[Math]::Round([double]$parsed.CagrPercent,2)
      ProfitFactor=[Math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades
      WinRatePercent=[Math]::Round([double]$parsed.WinRatePercent,2);MaxDrawdownPercent=[Math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor=[Math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[Math]::Round($returnDd,4)
      SharpeRatio=[Math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses
      ReportSha256=$run.ReportSha256
   }) | Out-Null
   $attestation.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status
      SourceSha256=$run.PackageSourceSha256;BinarySha256=$run.PortableBinarySha256
      ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256
      IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished
   }) | Out-Null
}
$results | Export-Csv (Repo-Path "outputs\${prefix}_MODEL1_RESULTS.csv") -NoTypeInformation -Encoding ASCII
$attestation | Export-Csv (Repo-Path "outputs\${prefix}_RUN_ATTESTATION.csv") -NoTypeInformation -Encoding ASCII

$by = @{}
foreach($row in $results) { $by["$($row.Candidate)|$($row.Window)"] = $row }
$control = $by["$controlName|$continuousName"]
$center = $by["$centerName|$continuousName"]
function Era-Floor([string]$Name) {
   foreach($era in $eraNames) {
      if([double]$by["$Name|$era"].NetProfit -lt 0.95 * [double]$by["$controlName|$era"].NetProfit) { return $false }
   }
   return $true
}
function Quality-Pass([string]$Name) {
   $row = $by["$Name|$continuousName"]
   return [double]$row.ProfitFactor -ge 0.95 * [double]$control.ProfitFactor -and
      [double]$row.MaxDrawdownPercent -le [Math]::Min(1.50,[double]$control.MaxDrawdownPercent + 0.20) -and
      [double]$row.RecoveryFactor -ge 0.95 * [double]$control.RecoveryFactor -and
      [double]$row.ReturnDrawdown -ge 0.95 * [double]$control.ReturnDrawdown
}
function Component-Pass([string]$Name) {
   $row = $by["$Name|$continuousName"]
   return (Era-Floor $Name) -and [double]$row.NetProfit -ge 1.02 * [double]$control.NetProfit -and (Quality-Pass $Name)
}
$controlReproduced = [double]$by["$controlName|recent_2021_2023"].NetProfit -eq 629.61 -and
                     [double]$by["$controlName|latest_2024_2026"].NetProfit -eq 434.36
$allProfitable = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$centerActivity = [int]$center.TotalTrades -gt [int]$control.TotalTrades
$centerPass = (Era-Floor $centerName) -and $centerActivity -and
   [double]$center.NetProfit -ge 1.05 * [double]$control.NetProfit -and
   [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.10 -and (Quality-Pass $centerName)
$componentPasses = [ordered]@{}
foreach($name in $componentNames) { $componentPasses[$name] = Component-Pass $name }
$componentPassCount = @($componentPasses.Values | Where-Object { $_ }).Count
$passed = $controlReproduced -and $allProfitable -and $centerPass -and $componentPassCount -ge 1

$summary = foreach($name in $candidateNames) {
   $row = $by["$name|$continuousName"]
   [pscustomobject][ordered]@{
      Candidate=$name;Role=$row.Role;ClosePercent=$row.ClosePercent;TargetR=$row.TargetR;StopLockR=$row.StopLockR
      RecentNetProfit=$by["$name|recent_2021_2023"].NetProfit;LatestNetProfit=$by["$name|latest_2024_2026"].NetProfit
      ContinuousNetProfit=$row.NetProfit;CagrPercent=$row.CagrPercent;ProfitFactor=$row.ProfitFactor
      TotalTrades=$row.TotalTrades;MaxDrawdownPercent=$row.MaxDrawdownPercent;RecoveryFactor=$row.RecoveryFactor
      ReturnDrawdown=$row.ReturnDrawdown;EraFloor=if($name -eq $controlName){$true}else{Era-Floor $name}
      FrozenGate=if($name -eq $controlName){'CONTROL'}elseif($name -eq $centerName){$centerPass}else{$componentPasses[$name]}
   }
}
$summary | Export-Csv (Repo-Path "outputs\${prefix}_SUMMARY.csv") -NoTypeInformation -Encoding ASCII
$decision = [pscustomobject][ordered]@{
   Status=if($passed){'HOLDOUT_GATE_PASSED'}else{'REJECTED_IN_HOLDOUT'};ReportsParsed=12;IdentityValidReports=12
   PreservedIdentityRefusals=$identityRefusals;SuccessfulExactRecoveries=$recoveryRuns.Count
   ControlReproduced=$controlReproduced;EveryReportProfitable=$allProfitable;CenterActivityConfirmed=$centerActivity
   CenterGatePass=$centerPass;ComponentPassCount=$componentPassCount;RequiredComponentPassCount=1
   Model4ValidationPermitted=$passed;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false
   RealAccountTradingAllowed=$false;ControlNetProfit=$control.NetProfit;CenterNetProfit=$center.NetProfit
   SourceSha256=$sourceSha;BinarySha256=$binarySha;ManifestSha256=$manifestSha
}
$decision | Export-Csv (Repo-Path "outputs\${prefix}_DECISION.csv") -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Momentum Partial-Runner Interaction Holdout Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: HOLDOUT GATE PASSED. Model 4 confirmation is permitted; promotion and live trading remain closed.**'}else{'**Decision: REJECTED IN HOLDOUT. No Model 4 run, promotion, forward change, or real trading is permitted. NO NEW BEST.**'}))
$lines.Add('')
$lines.Add('- Exact accepted Model 1 reports: `12/12`; preserved identity refusals: `2`; successful exact recoveries: `2`')
$lines.Add("- Source SHA-256: ``$sourceSha``")
$lines.Add("- EX5 SHA-256: ``$binarySha``")
$lines.Add("- Manifest SHA-256: ``$manifestSha``")
$lines.Add('- Test contract: XAUUSD M15, `$10,000`, Model 1, post-2020 feature holdout only.')
$lines.Add('')
$lines.Add('| Candidate | Close | Target | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $summary) {
   $label = switch($row.Candidate) {
      'mopri_control' {'Disabled control'}
      'mopri_combo' {'**70% / 5R interaction**'}
      'mopri_close70' {'70% / 4R component'}
      default {'60% / 5R component'}
   }
   $lines.Add("| $label | $($row.ClosePercent)% | $($row.TargetR)R | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.LatestNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) | $($row.FrozenGate) |")
}
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$growth = 100.0 * ([double]$center.NetProfit / [double]$control.NetProfit - 1.0)
$lines.Add("The interaction raised post-2020 continuous net by only ``$(Money ([double]$center.NetProfit - [double]$control.NetProfit))`` (``$($growth.ToString('N2',[Globalization.CultureInfo]::InvariantCulture))%``), from ``$(Money ([double]$control.NetProfit))`` to ``$(Money ([double]$center.NetProfit))``. That is far below the frozen 5% growth and +0.10-point CAGR requirements.")
$lines.Add('')
$lines.Add("Neither individual component passed its 2% holdout growth gate. The best headline row, the 5R component at ``$(Money ([double]$by['mopri_target500|continuous_2021_2026'].NetProfit))``, improved control by less than 1%. The partial-runner branch is closed without Model 4 threshold chasing.")
$lines.Add('')
$lines.Add('The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo is not forward evidence, the registered candidate is unchanged, and real-account trading remains disabled.')
$lines | Set-Content (Repo-Path "outputs\${prefix}_DECISION.md") -Encoding ASCII

Remove-Item (Repo-Path $tempResults),(Repo-Path $tempSummary),(Repo-Path $tempMetrics) -Force -ErrorAction SilentlyContinue
Remove-Item (Repo-Path "outputs\${prefix}_MODEL1_RAW_RESULTS.csv"),(Repo-Path "outputs\${prefix}_MODEL1_RAW_SUMMARY.csv"),(Repo-Path "outputs\${prefix}_MODEL1_RAW_METRICS.md") -Force -ErrorAction SilentlyContinue
$decision
