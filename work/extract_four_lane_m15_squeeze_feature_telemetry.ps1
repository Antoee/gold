[CmdletBinding()]
param(
   [string]$EventsPath='outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_EVENTS.csv',
   [string]$ResultPath='outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_RESULT.csv',
   [string]$RunPath='outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_WORKER_1.csv',
   [string]$LedgerPath='outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_TRADES.csv',
   [string]$AttestationPath='outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_ATTESTATION.csv'
)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path;$culture=[Globalization.CultureInfo]::InvariantCulture
$expectedEventsHash='582EDBE4CBF398CB8108CCE7E11CA7C7FBFE64F2D1D68419AFC54C8D6A1A2F5E';$expectedResultHash='7BD6BB00475FB4EFF999E1BE95D1E38BFBFC667262647322E650FBEF34F2149D';$expectedSourceHash='C6B4BC66F661BB70CC51B92E320A87A5643745454C26791B09766F84DA9C94C4';$expectedBinaryHash='EAC3F26DDCE7E7FC59CD02AFFE3F358397FCABF4F9D402F8F0B6D27B8EE3AA9C';$expectedReportHash='798F149A67CFECD2BDC51220D0F03C1857710FFB4D8EC2F472D9BE3941898218';$expectedRunLabel='four_lane_m15_squeeze_feature_telemetry_model1';$expectedProfile='m15_sq_pr_telemetry'
$featureMap=[ordered]@{BreakoutATR='breakout_atr';BodyRatio='body_ratio';CloseLocation='close_location';RangeATR='range_atr';ExpansionRatio='expansion_ratio';ChannelWidthATR='channel_width_atr';SqueezeRangeATR='squeeze_range_atr';TickVolumeRatio='tick_volume_ratio';ATRPercent='atr_pct';ADX='adx';TrendDistanceATR='trend_distance_atr';TrendSlopeATR='trend_slope_atr';SqueezeRatioMean='squeeze_ratio_mean';SqueezeRatioMax='squeeze_ratio_max';StopATR='stop_atr'}
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Parse-Double([string]$Value,[string]$Field){$parsed=0.0;if(![double]::TryParse($Value,[Globalization.NumberStyles]::Float,$culture,[ref]$parsed)){throw "Invalid $Field value: $Value"};return $parsed}
function Read-Feature([string]$Reason,[string]$Name){$match=[regex]::Match($Reason,"(?:^|;)$([regex]::Escape($Name))=([-+]?\d+(?:\.\d+)?)");if(!$match.Success){throw "Entry telemetry is missing $Name."};return Parse-Double $match.Groups[1].Value $Name}
function Read-OpenFlag([string]$Reason){$match=[regex]::Match($Reason,'(?:^|;)position_open_after_exit=([01])(?:;|$)');if(!$match.Success){throw 'Exit telemetry is missing position_open_after_exit.'};return $match.Groups[1].Value -eq '1'}

$events=Resolve-RepoPath $EventsPath;$result=Resolve-RepoPath $ResultPath;$runFile=Resolve-RepoPath $RunPath;$ledger=Resolve-RepoPath $LedgerPath;$attestation=Resolve-RepoPath $AttestationPath
if((Get-FileHash -LiteralPath $events -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedEventsHash){throw 'Telemetry event identity changed.'};if((Get-FileHash -LiteralPath $result -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedResultHash){throw 'Telemetry control-result identity changed.'}
$control=Import-Csv -LiteralPath $result|Select-Object -First 1
$reproductionPass=$control.Status -eq 'PARSED' -and [double]$control.NetProfit -eq 1695.16 -and [int]$control.TotalTrades -eq 391 -and [double]$control.ProfitFactor -eq 1.84 -and [double]$control.MaxDrawdownPercent -eq 1.10
if(!$reproductionPass){throw 'Behavior-neutral telemetry control did not reproduce the frozen partial-runner center.'}
$run=Import-Csv -LiteralPath $runFile|Select-Object -First 1
if($run.Status -ne 'REPORT_FOUND' -or $run.PackageSourceSha256 -ne $expectedSourceHash -or $run.PortableBinarySha256 -ne $expectedBinaryHash -or $run.ReportSha256 -ne $expectedReportHash -or $run.PortableExpertRecompiled -ne 'False'){throw 'Telemetry run identity changed.'}
$identity=Get-Content -LiteralPath $run.ReportIdentityPath -Raw|ConvertFrom-Json
if($identity.SourceSha256 -ne $expectedSourceHash -or $identity.PortableBinarySha256 -ne $expectedBinaryHash -or $identity.ReportSha256 -ne $expectedReportHash -or $identity.ConfigSha256 -ne $run.PackageConfigSha256){throw 'Telemetry report sidecar identity changed.'}

$headers='Time','Event','Symbol','Ticket','Side','Volume','Price','Stop','Profit','Reason','Profile','SourceHash','RunLabel'
$rows=@(Import-Csv -LiteralPath $events -Delimiter "`t" -Header $headers)
if($rows.Count -ne 258 -or @($rows|Where-Object Event -eq 'entry').Count -ne 88 -or @($rows|Where-Object Event -eq 'exit').Count -ne 129 -or @($rows|Where-Object Event -eq 'partial_runner').Count -ne 41){throw 'Telemetry event topology changed.'}
foreach($row in $rows){if($row.Symbol -ne 'XAUUSD' -or $row.Profile -ne $expectedProfile -or $row.SourceHash -ne $expectedSourceHash -or $row.RunLabel -ne $expectedRunLabel){throw "Telemetry identity mismatch at $($row.Time)."}}

$open=@{};$trades=[Collections.Generic.List[object]]::new()
foreach($row in $rows){
   $time=[datetime]::ParseExact($row.Time,'yyyy.MM.dd HH:mm:ss',$culture);$ticket=[string]$row.Ticket
   if($row.Event -eq 'entry'){
      if($open.ContainsKey($ticket)){throw "Duplicate squeeze entry for $ticket."}
      $features=[ordered]@{};foreach($name in $featureMap.Keys){$features[$name]=Read-Feature $row.Reason $featureMap[$name]}
      $open[$ticket]=[pscustomobject]@{Time=$time;Side=$row.Side;Volume=(Parse-Double $row.Volume 'volume');Price=(Parse-Double $row.Price 'entry price');Stop=(Parse-Double $row.Stop 'initial stop');Features=$features;Profit=0.0;ExitVolume=0.0;ExitCount=0}
      continue
   }
   if($row.Event -eq 'partial_runner'){if(!$open.ContainsKey($ticket)){throw "Partial event without entry for $ticket."};continue}
   if($row.Event -ne 'exit'){throw "Unexpected telemetry event: $($row.Event)"}
   if(!$open.ContainsKey($ticket)){throw "Exit without entry for $ticket."}
   $entry=$open[$ticket];$entry.Profit += Parse-Double $row.Profit 'profit';$entry.ExitVolume += Parse-Double $row.Volume 'exit volume';$entry.ExitCount++
   if(Read-OpenFlag $row.Reason){continue}
   $initialRiskMoney=[math]::Abs($entry.Price-$entry.Stop)*$entry.Volume*100.0
   if($initialRiskMoney -le 0.0){throw "Invalid initial risk for $ticket."}
   $trade=[ordered]@{PositionIdentifier=$ticket;EntryTime=$entry.Time.ToString('o');ExitTime=$time.ToString('o');Year=$entry.Time.Year;TrainingSplit=if($entry.Time.Year -le 2016){'training_2015_2016'}elseif($entry.Time.Year -le 2018){'training_2017_2018'}else{'validation_2019_2020'};Side=$entry.Side;InitialVolume=$entry.Volume;ExitVolume=[math]::Round($entry.ExitVolume,2);ExitDeals=$entry.ExitCount;EntryPrice=$entry.Price;InitialStop=$entry.Stop;InitialRiskMoney=[math]::Round($initialRiskMoney,6);Profit=[math]::Round($entry.Profit,2);RiskR=[math]::Round($entry.Profit/$initialRiskMoney,6);HoldHours=[math]::Round(($time-$entry.Time).TotalHours,4)}
   foreach($name in $featureMap.Keys){$trade[$name]=$entry.Features[$name]}
   $trades.Add([pscustomobject]$trade)|Out-Null;$open.Remove($ticket)
}
if($open.Count -ne 0 -or $trades.Count -ne 88){throw 'Telemetry position aggregation did not close exactly 88 trades.'}
$trades|Export-Csv -LiteralPath $ledger -NoTypeInformation -Encoding ASCII;$ledgerHash=(Get-FileHash -LiteralPath $ledger -Algorithm SHA256).Hash.ToUpperInvariant()
[pscustomobject][ordered]@{Status='EXACT_CONTROL_REPRODUCTION_AND_LEDGER_PASS';ControlNetProfit=1695.16;ControlTotalTrades=391;ControlProfitFactor=1.84;ControlMaxDrawdownPercent=1.10;SqueezeTrades=$trades.Count;SqueezeExitDeals=@($rows|Where-Object Event -eq 'exit').Count;PartialEvents=@($rows|Where-Object Event -eq 'partial_runner').Count;SqueezeNetProfit=[math]::Round(($trades|Measure-Object Profit -Sum).Sum,2);TrainingTrades=@($trades|Where-Object Year -le 2018).Count;ValidationTrades=@($trades|Where-Object Year -ge 2019).Count;EventsSha256=$expectedEventsHash;ResultSha256=$expectedResultHash;LedgerSha256=$ledgerHash;SourceSha256=$expectedSourceHash;BinarySha256=$expectedBinaryHash;ReportSha256=$expectedReportHash;AnalyzerSha256='EDD9DC6CE723F111C9C888B321DF76405A0E581AF539C0DD04F566912E7558C8';ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false}|Export-Csv -LiteralPath $attestation -NoTypeInformation -Encoding ASCII
Import-Csv -LiteralPath $attestation
