[CmdletBinding()]
param(
   [string]$ManifestPath='outputs\FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir='outputs\four_lane_m15_squeeze_partial_runner_discovery_model1_package\reports_here'
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256='1E05D5E8A9283EC34EC9F8116E21C363E4D100BE782065E87DDDC90CCC3E6005'
$expectedBinarySha256='405665BCE71400E067AD6DE80CFA4CAEE4C937C2F916F05A1545327DAAE2E4B1'
$expectedManifestSha256='A6BA5855A67F090B20CC9E895EC81070402DE75F3E01D6011FE32663F6FD266E'
$leaderName='sqpr_exact_control';$referenceName='sqpr_reference';$centerName='sqpr_center'
$neighborNames=@('sqpr_close70','sqpr_close90','sqpr_target300','sqpr_target500','sqpr_lock100','sqpr_lock140')
$candidateNames=@($leaderName,$referenceName,$centerName)+$neighborNames
$eraNames=@('older_2015_2018','discovery_2019_2020');$continuousName='continuous_2015_2020'
$prefix='FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER'

function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Money([double]$Value){$sign=if($Value -ge 0.0){'+'}else{'-'};return $sign+'$'+[Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}

$manifestFile=Resolve-RepoPath $ManifestPath
if((Get-FileHash -LiteralPath $manifestFile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestSha256){throw 'Frozen manifest identity changed.'}
$manifest=@(Import-Csv -LiteralPath $manifestFile)
if($manifest.Count -ne 27 -or @($manifest.Candidate|Sort-Object -Unique).Count -ne 9 -or @($manifest.Window|Sort-Object -Unique).Count -ne 3){throw 'Frozen manifest topology changed.'}
if(@($manifest|Where-Object{$_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 -or [double]$_.Deposit -ne 10000}).Count -ne 0){throw 'Manifest source, model, or deposit identity changed.'}
foreach($item in $manifest){$config=Resolve-RepoPath ([string]$item.PackageConfig);if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $item.ConfigSha256){throw "Config identity changed at rank $($item.QueueRank)."}}

$rawResults="work\${prefix}_DECISION_RAW_RESULTS.csv";$rawSummary="work\${prefix}_DECISION_RAW_SUMMARY.csv";$rawMetrics="work\${prefix}_DECISION_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') -RepoRoot $repo -Manifest $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0){throw 'Shared report collector failed.'}
$raw=@(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
if($raw.Count -ne 27 -or @($raw|Where-Object Status -ne 'PARSED').Count -ne 0){throw 'Expected twenty-seven parsed reports.'}
$rawByReport=@{};foreach($row in $raw){$rawByReport[[string]$row.ExpectedReportName]=$row}

$firstRuns=@(Get-ChildItem (Resolve-RepoPath 'outputs') -Filter "${prefix}_WORKER_*.csv" -File|ForEach-Object{Import-Csv -LiteralPath $_.FullName})
$recoveryRuns=@(Get-ChildItem (Resolve-RepoPath 'outputs') -Filter "${prefix}_RECOVERY_*.csv" -File|ForEach-Object{Import-Csv -LiteralPath $_.FullName})
$identityRefusals=@($firstRuns|Where-Object Status -eq 'ERROR').Count
$acceptedRuns=@($firstRuns+$recoveryRuns|Where-Object Status -eq 'REPORT_FOUND')
$runByKey=@{};foreach($run in $acceptedRuns){$runByKey["$($run.Candidate)|$($run.Window)"]=$run}
if($firstRuns.Count -ne 27 -or $identityRefusals -ne 2 -or $recoveryRuns.Count -ne 2 -or $runByKey.Count -ne 27){throw 'Expected 25 first-pass reports, two preserved refusals, and two exact recoveries.'}

$results=[Collections.Generic.List[object]]::new();$attestation=[Collections.Generic.List[object]]::new()
foreach($item in ($manifest|Sort-Object{[int]$_.QueueRank})){
   $parsed=$rawByReport[[string]$item.ExpectedReportName];$run=$runByKey["$($item.Candidate)|$($item.Window)"]
   if($null -eq $parsed -or $null -eq $run){throw "Evidence missing for rank $($item.QueueRank)."}
   if($run.PackageSourceSha256 -ne $expectedSourceSha256 -or $run.PortableBinarySha256 -ne $expectedBinarySha256 -or $run.PortableExpertRecompiled -ne 'False'){throw "Run identity mismatch for rank $($item.QueueRank)."}
   $identityPath=[string]$run.ReportIdentityPath
   if(!(Test-Path -LiteralPath $identityPath -PathType Leaf)){throw "Identity sidecar missing for rank $($item.QueueRank)."}
   $identity=Get-Content -LiteralPath $identityPath -Raw|ConvertFrom-Json
   if($identity.SourceSha256 -ne $expectedSourceSha256 -or $identity.PortableBinarySha256 -ne $expectedBinarySha256 -or $identity.ReportSha256 -ne $run.ReportSha256 -or $identity.ConfigSha256 -ne $run.PackageConfigSha256){throw "Identity sidecar mismatch for rank $($item.QueueRank)."}
   $returnDrawdown=if([double]$parsed.MaxDrawdownPercent -gt 0.0){[double]$parsed.TotalReturnPercent/[double]$parsed.MaxDrawdownPercent}else{0.0}
   $results.Add([pscustomobject][ordered]@{QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window;From=$item.From;To=$item.To;Model=[int]$item.Model;PartialRunnerEnabled=$item.PartialRunnerEnabled;ClosePercent=[double]$item.ClosePercent;TriggerR=[double]$item.TriggerR;TargetR=[double]$item.TargetR;StopLockR=[double]$item.StopLockR;ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256;Status=$parsed.Status;NetProfit=[Math]::Round([double]$parsed.NetProfit,2);TotalReturnPercent=[Math]::Round([double]$parsed.TotalReturnPercent,2);CagrPercent=[Math]::Round([double]$parsed.CagrPercent,2);ProfitFactor=[Math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades;WinRatePercent=[Math]::Round([double]$parsed.WinRatePercent,2);MaxDrawdownPercent=[Math]::Round([double]$parsed.MaxDrawdownPercent,2);RecoveryFactor=[Math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[Math]::Round($returnDrawdown,4);SharpeRatio=[Math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses;ReportSha256=$run.ReportSha256})|Out-Null
   $attestation.Add([pscustomobject][ordered]@{QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status;IdentityReused=[bool]::Parse($run.ReportIdentityReused);SourceSha256=$run.PackageSourceSha256;BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256;IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished})|Out-Null
}
$results|Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_MODEL1_RESULTS.csv") -NoTypeInformation -Encoding ASCII
$attestation|Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_RUN_ATTESTATION.csv") -NoTypeInformation -Encoding ASCII

$by=@{};foreach($row in $results){$by["$($row.Candidate)|$($row.Window)"]=$row}
$leader=$by["$leaderName|$continuousName"];$reference=$by["$referenceName|$continuousName"];$center=$by["$centerName|$continuousName"]
function Era-NoWorse([string]$Name,[double]$Floor){foreach($era in $eraNames){if([double]$by["$Name|$era"].NetProfit -lt $Floor*[double]$by["$referenceName|$era"].NetProfit){return $false}};return $true}
function Activity-Pass([string]$Name){$trades=[int]$by["$Name|$continuousName"].TotalTrades;return $trades -ge 380 -and $trades -le 450}
function Quality-Pass([string]$Name,[double]$ReferenceQualityFloor){$row=$by["$Name|$continuousName"];return [double]$row.ProfitFactor -ge 0.98*[double]$leader.ProfitFactor -and [double]$row.MaxDrawdownPercent -le [Math]::Min(1.30,[double]$reference.MaxDrawdownPercent+0.15) -and [double]$row.RecoveryFactor -ge $ReferenceQualityFloor*[double]$reference.RecoveryFactor -and [double]$row.ReturnDrawdown -ge $ReferenceQualityFloor*[double]$reference.ReturnDrawdown}
function Neighbor-Pass([string]$Name){$row=$by["$Name|$continuousName"];return (Era-NoWorse $Name 0.98) -and (Activity-Pass $Name) -and [double]$row.NetProfit -ge 1.01*[double]$reference.NetProfit -and (Quality-Pass $Name 0.98)}

$leaderReproduced=[double]$by["$leaderName|older_2015_2018"].NetProfit -eq 1036.19 -and [double]$by["$leaderName|discovery_2019_2020"].NetProfit -eq 370.60 -and [double]$leader.NetProfit -eq 1379.93
$referenceReproduced=[double]$by["$referenceName|older_2015_2018"].NetProfit -eq 1141.49 -and [double]$by["$referenceName|discovery_2019_2020"].NetProfit -eq 459.89 -and [double]$reference.NetProfit -eq 1575.70
$allRowsProfitable=@($results|Where-Object{[double]$_.NetProfit -le 0.0}).Count -eq 0
$centerEraPass=Era-NoWorse $centerName 1.0;$centerActivity=Activity-Pass $centerName
$centerProfitPass=[double]$center.NetProfit -ge 1.03*[double]$reference.NetProfit -and [double]$center.CagrPercent -ge [double]$reference.CagrPercent+0.08
$centerQualityPass=Quality-Pass $centerName 1.0
$centerPass=$centerEraPass -and $centerActivity -and $centerProfitPass -and $centerQualityPass
$neighborPasses=[ordered]@{};foreach($name in $neighborNames){$neighborPasses[$name]=Neighbor-Pass $name}
$neighborPassCount=@($neighborPasses.Values|Where-Object{$_}).Count
$passed=$leaderReproduced -and $referenceReproduced -and $allRowsProfitable -and $centerPass -and $neighborPassCount -ge 3

$summary=foreach($name in $candidateNames){$row=$by["$name|$continuousName"];[pscustomobject][ordered]@{Candidate=$name;Role=$row.Role;ClosePercent=$row.ClosePercent;TargetR=$row.TargetR;StopLockR=$row.StopLockR;OlderNetProfit=$by["$name|older_2015_2018"].NetProfit;MiddleNetProfit=$by["$name|discovery_2019_2020"].NetProfit;ContinuousNetProfit=$row.NetProfit;CagrPercent=$row.CagrPercent;ProfitFactor=$row.ProfitFactor;ProfitFactorRetentionPercent=[Math]::Round(100.0*[double]$row.ProfitFactor/[double]$leader.ProfitFactor,2);TotalTrades=$row.TotalTrades;MaxDrawdownPercent=$row.MaxDrawdownPercent;RecoveryFactor=$row.RecoveryFactor;ReturnDrawdown=$row.ReturnDrawdown;FrozenGate=if($name -eq $leaderName){'LEADER_CONTROL'}elseif($name -eq $referenceName){'ACTIVE_REFERENCE'}elseif($name -eq $centerName){$centerPass}else{$neighborPasses[$name]}}}
$summary|Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_SUMMARY.csv") -NoTypeInformation -Encoding ASCII
$decision=[pscustomobject][ordered]@{Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=27;IdentityValidReports=27;PreservedIdentityRefusals=$identityRefusals;SuccessfulExactRecoveries=$recoveryRuns.Count;LeaderControlReproduced=$leaderReproduced;ActiveReferenceReproduced=$referenceReproduced;EveryReportProfitable=$allRowsProfitable;CenterEraPass=$centerEraPass;CenterActivityPass=$centerActivity;CenterProfitPass=$centerProfitPass;CenterQualityPass=$centerQualityPass;CenterGatePass=$centerPass;NeighborPassCount=$neighborPassCount;RequiredNeighborPassCount=3;Model4ValidationPermitted=$passed;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false;LeaderProfitFactor=$leader.ProfitFactor;CenterProfitFactor=$center.ProfitFactor;CenterProfitFactorRetentionPercent=[Math]::Round(100.0*[double]$center.ProfitFactor/[double]$leader.ProfitFactor,2);ReferenceNetProfit=$reference.NetProfit;CenterNetProfit=$center.NetProfit;SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;ManifestSha256=$expectedManifestSha256}
$decision|Export-Csv -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_DECISION.csv") -NoTypeInformation -Encoding ASCII

$lines=[Collections.Generic.List[string]]::new();$lines.Add('# Four-Lane M15 Squeeze Partial-Runner Discovery Decision');$lines.Add('');$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. A separately frozen post-2020 gate is permitted; promotion and live trading remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No post-2020 run, Model 4 run, promotion, forward change, or real trading is permitted. NO NEW BEST.**'}));$lines.Add('');$lines.Add('- Exact accepted Model 1 reports: `27/27`; preserved identity refusals: `2`; successful exact recoveries: `2`');$lines.Add("- Source SHA-256: ``$expectedSourceSha256``");$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``");$lines.Add("- Manifest SHA-256: ``$expectedManifestSha256``");$lines.Add('- Test contract: XAUUSD M15, `$10,000`, Model 1, frozen 2015-2020 discovery.');$lines.Add('')
$lines.Add('| Candidate | Close | Target | Lock | 2015-18 | 2019-20 | Continuous | CAGR | PF | PF/leader | Trades | DD | Recovery | Return/DD | Gate |');$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $summary){$label=switch($row.Candidate){'sqpr_exact_control'{'Leader control'}'sqpr_reference'{'Active squeeze reference'}'sqpr_center'{'**80% / 4R / +1.25R center**'}default{$row.Candidate}};$lines.Add("| $label | $($row.ClosePercent)% | $($row.TargetR)R | $($row.StopLockR)R | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.ProfitFactorRetentionPercent)% | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) | $($row.FrozenGate) |")}
$lines.Add('');$lines.Add('## Frozen Gate');$lines.Add('');$lines.Add("- Leader control reproduced: ``$leaderReproduced``");$lines.Add("- Active squeeze reference reproduced: ``$referenceReproduced``");$lines.Add("- Every broad-window report profitable: ``$allRowsProfitable``");$lines.Add("- Center improved both disjoint eras: ``$centerEraPass``");$lines.Add("- Center profit/CAGR gate: ``$centerProfitPass``");$lines.Add("- Center quality gate: ``$centerQualityPass``");$lines.Add("- Passing neighbors: ``$neighborPassCount/6``; required: ``3/6``")
$lines.Add('');$lines.Add('## Interpretation');$lines.Add('');$lines.Add("The fixed center raised continuous pre-2021 net from ``$(Money ([double]$reference.NetProfit))`` to ``$(Money ([double]$center.NetProfit))`` and CAGR from ``$($reference.CagrPercent)%`` to ``$($center.CagrPercent)%`` while holding maximum drawdown at ``$($center.MaxDrawdownPercent)%``. Its PF improved from ``$($reference.ProfitFactor)`` to ``$($center.ProfitFactor)``, but retained only ``$([Math]::Round(100.0*[double]$center.ProfitFactor/[double]$leader.ProfitFactor,2))%`` of the ``$($leader.ProfitFactor)`` leader PF, below the frozen ``98%`` floor. That single frozen quality miss rejects the center despite ``$neighborPassCount/6`` supporting neighbors.")
$lines.Add('');$lines.Add('The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo contributes zero forward days and zero forward trades; the registered candidate is unchanged and real-account trading remains disabled.')
$lines|Set-Content -LiteralPath (Resolve-RepoPath "outputs\${prefix}_DISCOVERY_DECISION.md") -Encoding ASCII
Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics),(Resolve-RepoPath 'work\SQPR_RAW_RESULTS.csv'),(Resolve-RepoPath 'work\SQPR_RAW_SUMMARY.csv'),(Resolve-RepoPath 'work\SQPR_RAW_METRICS.md') -Force -ErrorAction SilentlyContinue
$decision
