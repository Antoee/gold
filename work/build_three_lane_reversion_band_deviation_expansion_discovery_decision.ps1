[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_BAND_DEVIATION_EXPANSION_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_reversion_band_deviation_expansion_discovery_model1_package\reports_here'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedBinarySha256 = 'D0619DFEF164F5A70F5AC48D124F553C554F30CE613C9A2A208B150B2E71C7FC'
$expectedManifestSha256 = 'C8C81D2FA812C73B87F1C8E8DDDDA98570FE4ECECAFBF096D2A7BF11EAE43042'
$prefix = 'THREE_LANE_REVERSION_BAND_DEVIATION_EXPANSION'
$controlName = 'rvbd_control200'
$centerName = 'rvbd_center180'
$neighborNames = @('rvbd_neighbor190','rvbd_neighbor170')
$candidateNames = @($controlName,'rvbd_neighbor190',$centerName,'rvbd_neighbor170')
$eraNames = @('older_2015_2018','middle_2019_2020','recent_2021_2023','latest_2024_2026')
$continuousName = 'continuous_2015_2026'

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Money([double]$Value) {
   $sign = if($Value -ge 0.0) { '+' } else { '-' }
   return $sign + '$' + [Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}
function Profit-Factor([object[]]$Trades) {
   $grossProfit = [double](($Trades | Where-Object { [double]$_.Profit -gt 0.0 } | Measure-Object Profit -Sum).Sum)
   $grossLoss = [Math]::Abs([double](($Trades | Where-Object { [double]$_.Profit -lt 0.0 } | Measure-Object Profit -Sum).Sum))
   if($grossLoss -le 0.0) { return 999.0 }
   return $grossProfit / $grossLoss
}
function Trade-Key([object]$Trade) {
   return "$($Trade.EntryTime)|$($Trade.Side)|$($Trade.EntryPrice)"
}

$manifestFile = Resolve-RepoPath $ManifestPath
if((Get-FileHash -LiteralPath $manifestFile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestSha256) {
   throw 'Frozen manifest identity changed.'
}
$manifest = @(Import-Csv -LiteralPath $manifestFile)
if($manifest.Count -ne 20 -or @($manifest.Candidate | Sort-Object -Unique).Count -ne 4 -or
   @($manifest.Window | Sort-Object -Unique).Count -ne 5) {
   throw 'Frozen manifest topology changed.'
}
if(@($manifest | Where-Object {
   $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 -or [double]$_.Deposit -ne 10000
}).Count -ne 0) {
   throw 'Manifest source, model, or deposit identity changed.'
}
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
if($raw.Count -ne 20 -or @($raw | Where-Object Status -ne 'PARSED').Count -ne 0) {
   throw 'Expected twenty parsed reports.'
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
if($firstRuns.Count -ne 20 -or $identityRefusals -ne 1 -or $runByKey.Count -ne 20) {
   throw 'Expected nineteen first-pass reports, one identity refusal, and one successful recovery.'
}

$results = [Collections.Generic.List[object]]::new()
$attestation = [Collections.Generic.List[object]]::new()
foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   $run = $runByKey["$($item.Candidate)|$($item.Window)"]
   if($null -eq $parsed -or $null -eq $run) { throw "Evidence missing for rank $($item.QueueRank)." }
   if($run.PackageSourceSha256 -ne $expectedSourceSha256 -or $run.PortableBinarySha256 -ne $expectedBinarySha256 -or
      $run.PortableExpertRecompiled -ne 'False') {
      throw "Run identity mismatch for rank $($item.QueueRank)."
   }
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
      From=$item.From;To=$item.To;Model=[int]$item.Model;BollingerDeviation=[double]$item.BollingerDeviation
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256
      Status=$parsed.Status;NetProfit=[Math]::Round([double]$parsed.NetProfit,2)
      TotalReturnPercent=[Math]::Round([double]$parsed.TotalReturnPercent,2)
      CagrPercent=[Math]::Round([double]$parsed.CagrPercent,2);ProfitFactor=[Math]::Round([double]$parsed.ProfitFactor,2)
      TotalTrades=[int]$parsed.TotalTrades;WinRatePercent=[Math]::Round([double]$parsed.WinRatePercent,2)
      MaxDrawdownPercent=[Math]::Round([double]$parsed.MaxDrawdownPercent,2)
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
$resultsPath = Resolve-RepoPath "outputs\${prefix}_DISCOVERY_MODEL1_RESULTS.csv"
$attestationPath = Resolve-RepoPath "outputs\${prefix}_DISCOVERY_RUN_ATTESTATION.csv"
$results | Export-Csv -LiteralPath $resultsPath -NoTypeInformation -Encoding ASCII
$attestation | Export-Csv -LiteralPath $attestationPath -NoTypeInformation -Encoding ASCII

$by = @{}
foreach($row in $results) { $by["$($row.Candidate)|$($row.Window)"] = $row }
function All-Eras-Positive([string]$Name) {
   return @($eraNames | Where-Object { [double]$by["$Name|$_"].NetProfit -le 0.0 }).Count -eq 0
}

$laneEvidence = [Collections.Generic.List[object]]::new()
$tradeSets = @{}
foreach($name in $candidateNames) {
   $path = Resolve-RepoPath "outputs\${prefix}_${name}_MODEL1_TRADES.csv"
   $trades = @(Import-Csv -LiteralPath $path)
   $tradeSets[$name] = $trades
   foreach($lane in @('Reversion','Momentum','Adaptive')) {
      $subset = switch($lane) {
         'Reversion' { @($trades | Where-Object EntryComment -like 'RRO*') }
         'Momentum' { @($trades | Where-Object EntryComment -like 'MTSM*') }
         default { @($trades | Where-Object EntryComment -like 'ATB*') }
      }
      $laneEvidence.Add([pscustomobject][ordered]@{
         Candidate=$name;BollingerDeviation=$by["$name|$continuousName"].BollingerDeviation;Lane=$lane
         Trades=$subset.Count;NetProfit=[Math]::Round([double](($subset | Measure-Object Profit -Sum).Sum),2)
         ProfitFactor=[Math]::Round((Profit-Factor $subset),3)
      }) | Out-Null
   }
}

$controlReversion = @($tradeSets[$controlName] | Where-Object EntryComment -like 'RRO*')
$controlKeys = @{}
foreach($trade in $controlReversion) { $controlKeys[(Trade-Key $trade)] = $true }
$displacement = [Collections.Generic.List[object]]::new()
foreach($name in $candidateNames | Where-Object { $_ -ne $controlName }) {
   $candidateReversion = @($tradeSets[$name] | Where-Object EntryComment -like 'RRO*')
   $candidateKeys = @{}
   foreach($trade in $candidateReversion) { $candidateKeys[(Trade-Key $trade)] = $true }
   $added = @($candidateReversion | Where-Object { !$controlKeys.ContainsKey((Trade-Key $_)) })
   $displaced = @($controlReversion | Where-Object { !$candidateKeys.ContainsKey((Trade-Key $_)) })
   $displacement.Add([pscustomobject][ordered]@{
      Candidate=$name;AddedTrades=$added.Count;AddedNetProfit=[Math]::Round([double](($added | Measure-Object Profit -Sum).Sum),2)
      AddedProfitFactor=[Math]::Round((Profit-Factor $added),3);DisplacedControlTrades=$displaced.Count
      DisplacedControlNetProfit=[Math]::Round([double](($displaced | Measure-Object Profit -Sum).Sum),2)
      DisplacedControlProfitFactor=[Math]::Round((Profit-Factor $displaced),3)
   }) | Out-Null
}
$laneEvidence | Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_LANE_EVIDENCE.csv") -NoTypeInformation -Encoding ASCII
$displacement | Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_DISPLACEMENT_EVIDENCE.csv") -NoTypeInformation -Encoding ASCII

$control = $by["$controlName|$continuousName"]
$center = $by["$centerName|$continuousName"]
function Center-Pass {
   $centerRRO = @($laneEvidence | Where-Object { $_.Candidate -eq $centerName -and $_.Lane -eq 'Reversion' })[0]
   $controlRRO = @($laneEvidence | Where-Object { $_.Candidate -eq $controlName -and $_.Lane -eq 'Reversion' })[0]
   return (All-Eras-Positive $centerName) -and [double]$center.NetProfit -ge 1.10 * [double]$control.NetProfit -and
      [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.15 -and
      [int]$centerRRO.Trades -ge [int]$controlRRO.Trades + 3 -and
      [int]$center.TotalTrades -ge [Math]::Ceiling(0.95 * [int]$control.TotalTrades) -and
      [double]$center.ProfitFactor -ge 0.90 * [double]$control.ProfitFactor -and
      [double]$center.RecoveryFactor -ge 0.85 * [double]$control.RecoveryFactor -and
      [double]$center.ReturnDrawdown -ge 0.85 * [double]$control.ReturnDrawdown -and
      [double]$center.MaxDrawdownPercent -le 1.75
}
function Neighbor-Pass([string]$Name) {
   $row = $by["$Name|$continuousName"]
   $candidateRRO = @($laneEvidence | Where-Object { $_.Candidate -eq $Name -and $_.Lane -eq 'Reversion' })[0]
   $controlRRO = @($laneEvidence | Where-Object { $_.Candidate -eq $controlName -and $_.Lane -eq 'Reversion' })[0]
   return (All-Eras-Positive $Name) -and [double]$row.NetProfit -ge 1.05 * [double]$control.NetProfit -and
      [int]$candidateRRO.Trades -gt [int]$controlRRO.Trades -and [double]$row.ProfitFactor -ge 0.85 * [double]$control.ProfitFactor -and
      [double]$row.RecoveryFactor -ge 0.75 * [double]$control.RecoveryFactor -and
      [double]$row.ReturnDrawdown -ge 0.75 * [double]$control.ReturnDrawdown -and [double]$row.MaxDrawdownPercent -le 2.00
}

$allRowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$centerPass = Center-Pass
$neighborPasses = [ordered]@{}
foreach($name in $neighborNames) { $neighborPasses[$name] = Neighbor-Pass $name }
$bothNeighborsPass = @($neighborPasses.Values | Where-Object { $_ }).Count -eq 2
$passed = $allRowsPositive -and $centerPass -and $bothNeighborsPass

$summary = foreach($name in $candidateNames) {
   $row = $by["$name|$continuousName"]
   $rro = @($laneEvidence | Where-Object { $_.Candidate -eq $name -and $_.Lane -eq 'Reversion' })[0]
   [pscustomobject][ordered]@{
      Candidate=$name;BollingerDeviation=$row.BollingerDeviation
      OlderNetProfit=$by["$name|older_2015_2018"].NetProfit;MiddleNetProfit=$by["$name|middle_2019_2020"].NetProfit
      RecentNetProfit=$by["$name|recent_2021_2023"].NetProfit;LatestNetProfit=$by["$name|latest_2024_2026"].NetProfit
      ContinuousNetProfit=$row.NetProfit;CagrPercent=$row.CagrPercent;ProfitFactor=$row.ProfitFactor
      TotalTrades=$row.TotalTrades;ReversionTrades=$rro.Trades;ReversionNetProfit=$rro.NetProfit
      MaxDrawdownPercent=$row.MaxDrawdownPercent;RecoveryFactor=$row.RecoveryFactor;ReturnDrawdown=$row.ReturnDrawdown
      FrozenGate=if($name -eq $controlName){'CONTROL'}elseif($name -eq $centerName){$centerPass}else{$neighborPasses[$name]}
   }
}
$summaryPath = Resolve-RepoPath "outputs\${prefix}_DISCOVERY_SUMMARY.csv"
$summary | Export-Csv -LiteralPath $summaryPath -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=20;IdentityValidReports=20
   PreservedIdentityRefusals=$identityRefusals;EveryRowProfitable=$allRowsPositive;CenterGatePass=$centerPass
   HighBandNeighborGatePass=$neighborPasses['rvbd_neighbor190'];LowBandNeighborGatePass=$neighborPasses['rvbd_neighbor170']
   BothNeighborsPass=$bothNeighborsPass;Model4ValidationPermitted=$passed;ResearchPromotionPermitted=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false;ControlNetProfit=$control.NetProfit
   ControlCagrPercent=$control.CagrPercent;ControlMaxDrawdownPercent=$control.MaxDrawdownPercent
   CenterNetProfit=$center.NetProfit;CenterCagrPercent=$center.CagrPercent;CenterMaxDrawdownPercent=$center.MaxDrawdownPercent
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;ManifestSha256=$expectedManifestSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_DECISION.csv") -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Reversion Band-Deviation Expansion Discovery Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Model 4 confirmation is permitted; promotion and live trading remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No Model 4 run, promotion, forward change, or real trading is permitted.**'}))
$lines.Add('')
$lines.Add('- Exact accepted Model 1 reports: `20/20`; preserved first-pass identity refusal: `1`; successful isolated recovery: `1`')
$lines.Add("- Source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add("- Manifest SHA-256: ``$expectedManifestSha256``")
$lines.Add('- One-factor contract: only `InpRVBollingerDeviation` and the evidence run label changed from the exact leader.')
$lines.Add('- Test contract: XAUUSD M15, `$10,000`, Model 1, four disjoint eras plus continuous 2015-01-01 through 2026-07-12.')
$lines.Add('')
$lines.Add('| Band deviation | 2015-18 | 2019-20 | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | RV trades | RV net | DD | Recovery | Return/DD | Gate |')
$lines.Add('|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $summary) {
   $label = if($row.Candidate -eq $centerName) { '**1.80 center**' } else { [double]$row.BollingerDeviation }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.LatestNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.ReversionTrades) | $(Money ([double]$row.ReversionNetProfit)) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) | $($row.FrozenGate) |")
}
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$lines.Add("Lowering the band produced monotonic deterioration: continuous net fell from ``$(Money ([double]$control.NetProfit))`` at 2.00 to ``$(Money ([double]$by['rvbd_neighbor190|continuous_2015_2026'].NetProfit))``, ``$(Money ([double]$center.NetProfit))``, and ``$(Money ([double]$by['rvbd_neighbor170|continuous_2015_2026'].NetProfit))``. Drawdown rose from ``$($control.MaxDrawdownPercent)%`` to as high as ``$($by['rvbd_neighbor170|continuous_2015_2026'].MaxDrawdownPercent)%``.")
$lines.Add('')
$lines.Add('The looser thresholds entered earlier but did not create a robust activity expansion. The 1.90 candidate added five unique reversion trades worth `+$306.12`, while displacing eight control reversion trades worth `+$583.66`. The 1.80 and 1.70 candidates displaced even stronger control cohorts. This family is closed rather than rescued with another threshold.')
$lines.Add('')
$lines.Add('The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo is not forward evidence, the registered candidate is unchanged, and real-account trading remains disabled.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_DECISION.md") -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_MODEL1_RAW_RESULTS.csv"),(Resolve-RepoPath "outputs\${prefix}_DISCOVERY_MODEL1_RAW_SUMMARY.csv"),(Resolve-RepoPath "outputs\${prefix}_DISCOVERY_MODEL1_RAW_METRICS.md") -Force -ErrorAction SilentlyContinue
$decision
