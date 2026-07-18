param(
   [string]$TelemetryPath = "outputs\RC2_MOMENTUM_FEATURE_TELEMETRY_MO_2015_2018.csv",
   [string]$AnnualTradesPath = "outputs\RDMC_CAP12_MODEL4_ANNUAL_TRADES.csv",
   [string]$JoinedPath = "outputs\RDMC_CAP12_MODEL4_2015_2018_MOMENTUM_FEATURES.csv",
   [string]$SelectionPath = "outputs\RDMC_SIGNAL_RANGE_GATE_SELECTION.csv",
   [string]$MarkdownPath = "outputs\RDMC_SIGNAL_RANGE_GATE_SELECTION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedTelemetryHash = "B7828DF6F85C91660996F12051C8B1436941E597D761677D02E7D39E0978D3D1"
$expectedAnnualTradesHash = "6BC726AB9D2C1BBC022419B1AEEB2F62C1D9E2EA7435B59F7BADD03539F22576"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Ensure-ParentDirectory([string]$Path) {
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

$telemetry = (Resolve-Path -LiteralPath (Resolve-RepoPath $TelemetryPath)).Path
$annualTrades = (Resolve-Path -LiteralPath (Resolve-RepoPath $AnnualTradesPath)).Path
if((Get-FileHash -LiteralPath $telemetry -Algorithm SHA256).Hash -ne $expectedTelemetryHash) {
   throw "Selection telemetry identity changed."
}
if((Get-FileHash -LiteralPath $annualTrades -Algorithm SHA256).Hash -ne $expectedAnnualTradesHash) {
   throw "Annual Model4 trade ledger identity changed."
}

$featureNames = @(
   "channel_width_atr","breakout_atr","h1_efficiency","d1_efficiency",
   "d1_momentum_pct","atr_pct","body_ratio","close_location","range_atr",
   "volume_ratio","stop_atr"
)
$evidenceRows = @(Import-Csv -LiteralPath $telemetry -Delimiter "`t" `
   -Header Time,Event,Symbol,Ticket,Side,Volume,Price,Stop,Profit,Reason,Profile,SourceHash,RunLabel)
$telemetryEntries = [Collections.Generic.List[object]]::new()
$pendingEntry = $null
foreach($row in $evidenceRows) {
   if($row.Event -eq "entry") {
      $entry = [ordered]@{
         EntryTime = ([datetime]::ParseExact($row.Time,"yyyy.MM.dd HH:mm:ss",
            [Globalization.CultureInfo]::InvariantCulture)).ToString("s")
         Side = $row.Side
      }
      foreach($feature in $featureNames) {
         if($row.Reason -notmatch (([regex]::Escape($feature)) + "=([-0-9.]+)")) {
            throw "Entry telemetry is missing $feature at $($row.Time)."
         }
         $entry[$feature] = [double]$Matches[1]
      }
      $pendingEntry = [pscustomobject]$entry
   }
   elseif($row.Event -eq "exit" -and $null -ne $pendingEntry) {
      $telemetryEntries.Add($pendingEntry) | Out-Null
      $pendingEntry = $null
   }
}
if($telemetryEntries.Count -ne 135) {
   throw "Expected 135 completed momentum telemetry entries, found $($telemetryEntries.Count)."
}

$model4Momentum = @(Import-Csv -LiteralPath $annualTrades | Where-Object {
   $_.TestWindow -in @("2015","2016","2017","2018") -and
   $_.EntryComment -like "MTSM_*"
})
if($model4Momentum.Count -ne 135) {
   throw "Expected 135 matching annual Model4 momentum trades, found $($model4Momentum.Count)."
}

$joined = foreach($entry in $telemetryEntries) {
   $matches = @($model4Momentum | Where-Object {
      $_.EntryTime -eq $entry.EntryTime -and $_.Side -eq $entry.Side
   })
   if($matches.Count -ne 1) {
      throw "Expected one Model4 match for $($entry.EntryTime) $($entry.Side), found $($matches.Count)."
   }
   $trade = $matches[0]
   $output = [ordered]@{
      Year = ([datetime]$entry.EntryTime).Year
      EntryTime = $entry.EntryTime
      Side = $entry.Side
      Profit = [double]$trade.Profit
      RiskR = [double]$trade.RiskR
   }
   foreach($feature in $featureNames) { $output[$feature] = $entry.$feature }
   [pscustomobject]$output
}

$joinedFull = Resolve-RepoPath $JoinedPath
$selectionFull = Resolve-RepoPath $SelectionPath
$markdownFull = Resolve-RepoPath $MarkdownPath
Ensure-ParentDirectory $joinedFull
Ensure-ParentDirectory $selectionFull
Ensure-ParentDirectory $markdownFull
$joined | Export-Csv -LiteralPath $joinedFull -NoTypeInformation -Encoding ASCII

$profiles = @(
   [pscustomobject]@{Candidate="srg_control";Enabled=$false;Minimum=0.0},
   [pscustomobject]@{Candidate="srg_min100";Enabled=$true;Minimum=1.0},
   [pscustomobject]@{Candidate="srg_min125_center";Enabled=$true;Minimum=1.25},
   [pscustomobject]@{Candidate="srg_min150";Enabled=$true;Minimum=1.5}
)
$selection = foreach($profile in $profiles) {
   $kept = @($joined | Where-Object {
      !$profile.Enabled -or [double]$_.range_atr -ge $profile.Minimum
   })
   $grossProfit = [double](($kept | Where-Object { [double]$_.Profit -gt 0 } |
      Measure-Object Profit -Sum).Sum)
   $grossLoss = -[double](($kept | Where-Object { [double]$_.Profit -lt 0 } |
      Measure-Object Profit -Sum).Sum)
   $yearNets = foreach($year in 2015..2018) {
      [math]::Round([double](($kept | Where-Object { [int]$_.Year -eq $year } |
         Measure-Object Profit -Sum).Sum),2)
   }
   [pscustomobject]@{
      Candidate = $profile.Candidate
      GateEnabled = [string]$profile.Enabled
      MinimumSignalRangeATR = if($profile.Enabled) { $profile.Minimum } else { 0.0 }
      Trades = $kept.Count
      NetProfit = [math]::Round([double](($kept | Measure-Object Profit -Sum).Sum),2)
      ProfitFactor = [math]::Round($grossProfit / $grossLoss,4)
      Net2015 = $yearNets[0]
      Net2016 = $yearNets[1]
      Net2017 = $yearNets[2]
      Net2018 = $yearNets[3]
      PositiveSelectionYears = @($yearNets | Where-Object { $_ -gt 0 }).Count
   }
}
$selection | Export-Csv -LiteralPath $selectionFull -NoTypeInformation -Encoding ASCII

$md = [Collections.Generic.List[string]]::new()
$md.Add("# RDMC Momentum Signal-Range Selection")
$md.Add("")
$md.Add("Behavior-preserving Model1 feature values were joined one-to-one by time and side to exact annual Model4 outcomes. All 135 momentum entries matched.")
$md.Add("")
$md.Add("| Candidate | Min range/ATR | Trades | Net | PF | 2015 | 2016 | 2017 | 2018 |")
$md.Add("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
foreach($row in $selection) {
   $threshold = if($row.GateEnabled -eq "True") { $row.MinimumSignalRangeATR } else { "Off" }
   $md.Add("| $($row.Candidate) | $threshold | $($row.Trades) | $($row.NetProfit) | $($row.ProfitFactor) | $($row.Net2015) | $($row.Net2016) | $($row.Net2017) | $($row.Net2018) |")
}
$md.Add("")
$md.Add("Selection evidence only. The 2019 and 2022 repair reports were not used to choose or move these thresholds.")
$md | Set-Content -LiteralPath $markdownFull -Encoding ASCII

[pscustomobject]@{
   Status = "PASS"
   TelemetryEntries = $telemetryEntries.Count
   Model4Matches = $joined.Count
   JoinedSha256 = (Get-FileHash -LiteralPath $joinedFull -Algorithm SHA256).Hash
   SelectionPath = $SelectionPath
}
