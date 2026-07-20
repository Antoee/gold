[CmdletBinding()]
param(
   [string]$EventsPath = 'outputs\THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_MODEL4_FULL_EVENTS.csv',
   [string]$ResultPath = 'outputs\THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_MODEL4_FULL_RESULT.csv',
   [string]$LedgerPath = 'outputs\THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_MODEL4_FULL_TRADES.csv',
   [string]$AttestationPath = 'outputs\THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_MODEL4_FULL_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$culture = [Globalization.CultureInfo]::InvariantCulture
$expectedEventsHash = '049630A8B11F6B0B0C704756F8C4B7585DAE6AF3D24B7A9F3BD9A9A788C48E58'
$expectedResultHash = '6EF6298474E81E849FD94122DE2CC54551C18B01954F39D3996F99EC14F1149C'
$expectedSourceHash = '14F40409A6865F081774AEE18FEEC3E0F22ED1833F8ECAB54DD4BD852A3AD14B'
$expectedRunLabel = 'three_lane_momentum_feature_telemetry_model4_full'
$expectedReportHash = '295A16EFD6B60BF167E9F188D3EDC9C47A4F1A94782DC7DF95EB3FF13E247D82'
$expectedBinaryHash = '2167D676ED538E8D97CE1C3AB68F3A4264FABB9D6B3622D97E6CFF847980F544'

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Parse-Double([string]$Value, [string]$Field) {
   $parsed = 0.0
   if(![double]::TryParse($Value, [Globalization.NumberStyles]::Float, $culture, [ref]$parsed)) {
      throw "Invalid $Field value: $Value"
   }
   return $parsed
}
function Read-Feature([string]$Reason, [string]$Name) {
   $match = [regex]::Match($Reason, "(?:^|;)$([regex]::Escape($Name))=([-+]?\d+(?:\.\d+)?)")
   if(!$match.Success) { throw "Entry telemetry is missing $Name." }
   return Parse-Double $match.Groups[1].Value $Name
}
function Get-Era([int]$Year) {
   if($Year -le 2018) { return 'era_2015_2018' }
   if($Year -le 2020) { return 'era_2019_2020' }
   if($Year -le 2023) { return 'era_2021_2023' }
   return 'era_2024_2026'
}

$events = Resolve-RepoPath $EventsPath
$result = Resolve-RepoPath $ResultPath
$ledger = Resolve-RepoPath $LedgerPath
$attestation = Resolve-RepoPath $AttestationPath
if((Get-FileHash -LiteralPath $events -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedEventsHash) {
   throw 'Full Model4 momentum telemetry event identity changed.'
}
if((Get-FileHash -LiteralPath $result -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedResultHash) {
   throw 'Full Model4 control result identity changed.'
}

$control = Import-Csv -LiteralPath $result | Select-Object -First 1
$reproductionPass = $control.Status -eq 'PARSED' -and
   [double]$control.NetProfit -eq 2492.25 -and [int]$control.TotalTrades -eq 400 -and
   [double]$control.ProfitFactor -eq 1.93 -and [double]$control.MaxDrawdownPercent -eq 1.18
if(!$reproductionPass) { throw 'Behavior-neutral Model4 control did not reproduce the frozen leader.' }

$headers = 'Time','Event','Symbol','Ticket','Side','Volume','Price','Stop','Profit','Reason','Profile','SourceHash','RunLabel'
$rows = @(Import-Csv -LiteralPath $events -Delimiter "`t" -Header $headers)
if($rows.Count -ne 620) { throw "Expected 620 telemetry events, found $($rows.Count)." }
foreach($row in $rows) {
   if($row.Symbol -ne 'XAUUSD' -or $row.Profile -ne 'tlp_mom_e20' -or
      $row.SourceHash -ne $expectedSourceHash -or $row.RunLabel -ne $expectedRunLabel) {
      throw "Telemetry identity mismatch at $($row.Time)."
   }
}

$trades = [Collections.Generic.List[object]]::new()
$entry = $null
foreach($row in $rows) {
   $time = [datetime]::ParseExact($row.Time, 'yyyy.MM.dd HH:mm:ss', $culture)
   if($row.Event -eq 'entry') {
      if($null -ne $entry) { throw "Overlapping momentum entry at $($row.Time)." }
      $entry = [pscustomobject]@{
         Time=$time;Side=$row.Side;Volume=(Parse-Double $row.Volume 'volume')
         Price=(Parse-Double $row.Price 'entry price');Stop=(Parse-Double $row.Stop 'initial stop')
         D1MomentumPercent=(Read-Feature $row.Reason 'd1_pct')
         BreakoutATR=(Read-Feature $row.Reason 'breakout_atr')
         BodyRatio=(Read-Feature $row.Reason 'body_ratio')
         CloseLocation=(Read-Feature $row.Reason 'close_location')
         RangeATR=(Read-Feature $row.Reason 'range_atr')
         ChannelWidthATR=(Read-Feature $row.Reason 'channel_width_atr')
         ATRPercent=(Read-Feature $row.Reason 'atr_pct')
         TickVolumeRatio=(Read-Feature $row.Reason 'tick_volume_ratio')
         StopATR=(Read-Feature $row.Reason 'stop_atr')
      }
      if($entry.Side -notin @('buy','sell') -or $entry.Volume -le 0.0 -or
         $entry.Price -le 0.0 -or $entry.Stop -le 0.0 -or $entry.Price -eq $entry.Stop) {
         throw "Invalid momentum entry at $($row.Time)."
      }
      continue
   }
   if($row.Event -ne 'exit') { throw "Unexpected telemetry event: $($row.Event)" }
   if($null -eq $entry) { throw "Momentum exit without entry at $($row.Time)." }
   $profit = Parse-Double $row.Profit 'profit'
   $initialRiskMoney = [math]::Abs($entry.Price - $entry.Stop) * $entry.Volume * 100.0
   if($initialRiskMoney -le 0.0) { throw "Invalid initial risk at $($entry.Time)." }
   $trades.Add([pscustomobject][ordered]@{
      EntryTime=$entry.Time.ToString('o');ExitTime=$time.ToString('o');Era=(Get-Era $entry.Time.Year)
      Year=$entry.Time.Year;Side=$entry.Side;Volume=$entry.Volume;EntryPrice=$entry.Price
      InitialStop=$entry.Stop;InitialRiskMoney=[math]::Round($initialRiskMoney,6)
      Profit=$profit;RiskR=[math]::Round($profit/$initialRiskMoney,6)
      HoldHours=[math]::Round(($time-$entry.Time).TotalHours,4)
      D1MomentumPercent=$entry.D1MomentumPercent;BreakoutATR=$entry.BreakoutATR
      BodyRatio=$entry.BodyRatio;CloseLocation=$entry.CloseLocation;RangeATR=$entry.RangeATR
      ChannelWidthATR=$entry.ChannelWidthATR;ATRPercent=$entry.ATRPercent
      TickVolumeRatio=$entry.TickVolumeRatio;StopATR=$entry.StopATR
   }) | Out-Null
   $entry = $null
}
if($null -ne $entry) { throw 'Unclosed momentum entry remains after telemetry parsing.' }
if($trades.Count -ne 310) { throw "Expected 310 completed momentum trades, found $($trades.Count)." }
$trades | Export-Csv -LiteralPath $ledger -NoTypeInformation -Encoding ASCII
$ledgerHash = (Get-FileHash -LiteralPath $ledger -Algorithm SHA256).Hash.ToUpperInvariant()

[pscustomobject][ordered]@{
   Status='EXACT_CONTROL_REPRODUCTION_AND_LEDGER_PASS';ControlNetProfit=2492.25
   ControlTotalTrades=400;ControlProfitFactor=1.93;ControlMaxDrawdownPercent=1.18
   MomentumTrades=$trades.Count;FirstEntry=$trades[0].EntryTime;LastExit=$trades[-1].ExitTime
   EventsSha256=$expectedEventsHash;ResultSha256=$expectedResultHash;LedgerSha256=$ledgerHash
   SourceSha256=$expectedSourceHash;BinarySha256=$expectedBinaryHash;ReportSha256=$expectedReportHash
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
} | Export-Csv -LiteralPath $attestation -NoTypeInformation -Encoding ASCII

Import-Csv -LiteralPath $attestation
