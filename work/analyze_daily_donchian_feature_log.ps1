param(
   [string]$LogPath = "outputs\DAILY_DONCHIAN_FEATURE_LOG.csv",
   [ValidateSet("Discovery","DiscoveryExtension","Validation","Holdout","All")][string]$Phase = "Discovery",
   [string]$GateId = "",
   [string]$OutTrades = "outputs\DAILY_DONCHIAN_FEATURE_TRADES.csv",
   [string]$OutScreen = "outputs\DAILY_DONCHIAN_FEATURE_GATE_SCREEN.csv",
   [string]$OutMarkdown = "outputs\DAILY_DONCHIAN_FEATURE_GATE_SCREEN.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Parse-Number([string]$Text) {
   if([string]::IsNullOrWhiteSpace($Text) -or $Text -eq "na") { return [double]::NaN }
   return [double]::Parse($Text, [Globalization.CultureInfo]::InvariantCulture)
}
function Feature-Number([string]$Reason, [string]$Name) {
   $match = [regex]::Match($Reason, "(?:^|\|)" + [regex]::Escape($Name) + "=(?<value>-?[0-9]+(?:\.[0-9]+)?|na)(?:\||;)")
   if(!$match.Success) { return [double]::NaN }
   return Parse-Number $match.Groups["value"].Value
}
function Gate-Id([string]$Feature, [string]$Direction, [double]$Threshold) {
   $text = $Threshold.ToString("0.####", [Globalization.CultureInfo]::InvariantCulture).Replace(".", "p")
   return "${Feature}_${Direction}_${text}"
}
function Get-GateSpecs {
   $specs = [Collections.Generic.List[object]]::new()
   $primaryGrids = [ordered]@{
      di_edge = @(0.0, 5.0, 10.0, 15.0, 20.0, 25.0)
      eff10 = @(0.30, 0.40, 0.50, 0.60, 0.70)
      body_pct = @(20.0, 30.0, 40.0, 50.0, 60.0)
      close_pct = @(60.0, 70.0, 80.0, 90.0)
   }
   foreach($feature in $primaryGrids.Keys) {
      foreach($threshold in $primaryGrids[$feature]) {
         $specs.Add([pscustomobject]@{
            GateId = Gate-Id $feature "min" $threshold
            Feature = $feature
            Direction = "min"
            Threshold = [double]$threshold
            Family = "primary"
         }) | Out-Null
      }
   }
   $extensionGrids = @(
      [pscustomobject]@{ Feature = "slope_atr"; Direction = "min"; Thresholds = @(0.05, 0.075, 0.10, 0.15, 0.20) },
      [pscustomobject]@{ Feature = "range_atr"; Direction = "min"; Thresholds = @(0.80, 1.00, 1.20, 1.40) },
      [pscustomobject]@{ Feature = "volume20_ratio"; Direction = "min"; Thresholds = @(0.80, 1.00, 1.20) },
      [pscustomobject]@{ Feature = "atr63_ratio"; Direction = "min"; Thresholds = @(0.80, 0.90, 1.00, 1.10) },
      [pscustomobject]@{ Feature = "ema_dist_atr"; Direction = "max"; Thresholds = @(2.00, 3.00, 4.00, 5.00) },
      [pscustomobject]@{ Feature = "break_atr"; Direction = "max"; Thresholds = @(0.20, 0.40, 0.60, 0.80) }
   )
   foreach($grid in $extensionGrids) {
      foreach($threshold in $grid.Thresholds) {
         $specs.Add([pscustomobject]@{
            GateId = Gate-Id $grid.Feature $grid.Direction $threshold
            Feature = $grid.Feature
            Direction = $grid.Direction
            Threshold = [double]$threshold
            Family = "extension"
         }) | Out-Null
      }
   }
   return @($specs)
}
function Trade-Feature([object]$Trade, [string]$Feature) {
   return [double]$Trade.$Feature
}
function Test-Gate([object]$Trade, [object]$Gate) {
   $value = Trade-Feature $Trade $Gate.Feature
   if([double]::IsNaN($value)) { return $false }
   if($Gate.Direction -eq "max") { return $value -le $Gate.Threshold }
   return $value -ge $Gate.Threshold
}
function Get-Metrics([object[]]$Rows) {
   $ordered = @($Rows | Sort-Object EntryTime)
   $grossProfit = [double](($ordered | Where-Object { $_.Profit -gt 0 } | Measure-Object Profit -Sum).Sum)
   $grossLoss = [double](($ordered | Where-Object { $_.Profit -lt 0 } | Measure-Object Profit -Sum).Sum)
   $net = $grossProfit + $grossLoss
   $wins = @($ordered | Where-Object { $_.Profit -gt 0 }).Count
   $losses = @($ordered | Where-Object { $_.Profit -lt 0 }).Count
   $maxLosses = 0
   $lossRun = 0
   $equity = 0.0
   $peak = 0.0
   $maxDrawdown = 0.0
   foreach($trade in $ordered) {
      if($trade.Profit -lt 0) { $lossRun++; $maxLosses = [Math]::Max($maxLosses, $lossRun) }
      else { $lossRun = 0 }
      $equity += [double]$trade.Profit
      $peak = [Math]::Max($peak, $equity)
      $maxDrawdown = [Math]::Max($maxDrawdown, $peak - $equity)
   }
   $yearRows = @($ordered | Group-Object EntryYear | ForEach-Object {
      [pscustomobject]@{ Year = [int]$_.Name; Net = [double](($_.Group | Measure-Object Profit -Sum).Sum) }
   })
   return [pscustomobject]@{
      Trades = $ordered.Count
      Wins = $wins
      Losses = $losses
      NetProfit = [Math]::Round($net, 2)
      GrossProfit = [Math]::Round($grossProfit, 2)
      GrossLoss = [Math]::Round($grossLoss, 2)
      ProfitFactor = if($grossLoss -lt 0) { [Math]::Round($grossProfit / [Math]::Abs($grossLoss), 4) } elseif($grossProfit -gt 0) { 999.0 } else { 0.0 }
      WinRatePercent = if($ordered.Count -gt 0) { [Math]::Round(100.0 * $wins / $ordered.Count, 2) } else { 0.0 }
      MaxConsecutiveLosses = $maxLosses
      TradeCloseDrawdown = [Math]::Round($maxDrawdown, 2)
      NegativeYears = @($yearRows | Where-Object { $_.Net -lt 0 }).Count
      ActiveYears = $yearRows.Count
   }
}

$headers = @("time","event","symbol","ticket","bias","volume","price","sl","tp","risk_r","profit","reason","atr","spread_points","max_favorable_r","max_adverse_r","held_bars","entry_context","profile_id","source_hash","run_label")
$raw = @(Get-Content -LiteralPath (Resolve-RepoPath $LogPath) | ConvertFrom-Csv -Delimiter "`t" -Header $headers)
$entries = @($raw | Where-Object { $_.event -eq "entry" })
$closed = @($raw | Where-Object { $_.event -eq "closed_deal" } | Group-Object ticket)
if($entries.Count -ne 51) { throw "Expected 51 entry rows, found $($entries.Count)." }
if($closed.Count -ne 51) { throw "Expected 51 closed trade groups, found $($closed.Count)." }

$closedByTicket = @{}
foreach($group in $closed) {
   $closedByTicket[$group.Name] = [pscustomobject]@{
      ExitTime = [datetime]::ParseExact(($group.Group | Sort-Object time | Select-Object -Last 1).time, "yyyy.MM.dd HH:mm:ss", [Globalization.CultureInfo]::InvariantCulture)
      Profit = [double](($group.Group | ForEach-Object { Parse-Number $_.profit } | Measure-Object -Sum).Sum)
   }
}

$trades = [Collections.Generic.List[object]]::new()
foreach($entry in $entries) {
   if(!$closedByTicket.ContainsKey($entry.ticket)) { throw "No close row for ticket $($entry.ticket)." }
   $entryTime = [datetime]::ParseExact($entry.time, "yyyy.MM.dd HH:mm:ss", [Globalization.CultureInfo]::InvariantCulture)
   $close = $closedByTicket[$entry.ticket]
   $trades.Add([pscustomobject]@{
      Ticket = $entry.ticket
      EntryTime = $entryTime
      ExitTime = $close.ExitTime
      EntryYear = $entryTime.Year
      Side = $entry.bias
      Profit = [Math]::Round($close.Profit, 2)
      Winner = $close.Profit -gt 0
      adx = Feature-Number $entry.reason "adx"
      di_edge = Feature-Number $entry.reason "di_edge"
      di_align = Feature-Number $entry.reason "di_align"
      slope_atr = Feature-Number $entry.reason "slope_atr"
      ema_dist_atr = Feature-Number $entry.reason "ema_dist_atr"
      break_atr = Feature-Number $entry.reason "break_atr"
      channel_atr = Feature-Number $entry.reason "channel_atr"
      eff10 = Feature-Number $entry.reason "eff10"
      body_pct = Feature-Number $entry.reason "body_pct"
      close_pct = Feature-Number $entry.reason "close_pct"
      range_atr = Feature-Number $entry.reason "range_atr"
      gap_atr = Feature-Number $entry.reason "gap_atr"
      atr63_ratio = Feature-Number $entry.reason "atr63_ratio"
      volume20_ratio = Feature-Number $entry.reason "volume20_ratio"
   }) | Out-Null
}

$trades | Export-Csv -LiteralPath (Resolve-RepoPath $OutTrades) -NoTypeInformation -Encoding ASCII
$specs = @(Get-GateSpecs)
switch($Phase) {
   "Discovery" { $periodTrades = @($trades | Where-Object { $_.EntryYear -ge 2015 -and $_.EntryYear -le 2020 }); $period = "discovery_2015_2020" }
   "DiscoveryExtension" { $periodTrades = @($trades | Where-Object { $_.EntryYear -ge 2015 -and $_.EntryYear -le 2020 }); $period = "discovery_extension_2015_2020" }
   "Validation" { $periodTrades = @($trades | Where-Object { $_.EntryYear -ge 2021 -and $_.EntryYear -le 2023 }); $period = "validation_2021_2023" }
   "Holdout" { $periodTrades = @($trades | Where-Object { $_.EntryYear -ge 2024 }); $period = "holdout_2024_2026" }
   "All" { $periodTrades = @($trades); $period = "all_2015_2026" }
}
if($periodTrades.Count -eq 0) { throw "No trades found for $period." }

$baseline = Get-Metrics $periodTrades
$selectedSpecs = if($Phase -eq "Discovery") { @($specs | Where-Object Family -eq "primary") } elseif($Phase -eq "DiscoveryExtension") { @($specs | Where-Object Family -eq "extension") } else {
   if([string]::IsNullOrWhiteSpace($GateId)) { throw "GateId is required for phase $Phase." }
   @($specs | Where-Object { $_.GateId -eq $GateId })
}
if($selectedSpecs.Count -eq 0) { throw "Unknown GateId: $GateId" }

$screen = [Collections.Generic.List[object]]::new()
foreach($gate in $selectedSpecs) {
   $kept = @($periodTrades | Where-Object { Test-Gate $_ $gate })
   $removed = @($periodTrades | Where-Object { !(Test-Gate $_ $gate) })
   $metrics = Get-Metrics $kept
   $retention = if($baseline.Trades -gt 0) { 100.0 * $metrics.Trades / $baseline.Trades } else { 0.0 }
   $eligible = $metrics.Trades -ge [Math]::Ceiling(0.70 * $baseline.Trades) -and
               $metrics.NetProfit -ge $baseline.NetProfit -and
               $metrics.ProfitFactor -ge $baseline.ProfitFactor -and
               $metrics.TradeCloseDrawdown -le $baseline.TradeCloseDrawdown -and
               $metrics.NegativeYears -le $baseline.NegativeYears
   $screen.Add([pscustomobject]@{
      Phase = $period
      GateId = $gate.GateId
      Feature = $gate.Feature
      Threshold = $gate.Threshold
      Eligible = $eligible
      Trades = $metrics.Trades
      RetentionPercent = [Math]::Round($retention, 2)
      RemovedTrades = $removed.Count
      RemovedWinners = @($removed | Where-Object Winner).Count
      RemovedLosers = @($removed | Where-Object { !$_.Winner }).Count
      NetProfit = $metrics.NetProfit
      NetDelta = [Math]::Round($metrics.NetProfit - $baseline.NetProfit, 2)
      ProfitFactor = $metrics.ProfitFactor
      WinRatePercent = $metrics.WinRatePercent
      MaxConsecutiveLosses = $metrics.MaxConsecutiveLosses
      TradeCloseDrawdown = $metrics.TradeCloseDrawdown
      NegativeYears = $metrics.NegativeYears
      ActiveYears = $metrics.ActiveYears
      BaselineTrades = $baseline.Trades
      BaselineNetProfit = $baseline.NetProfit
      BaselineProfitFactor = $baseline.ProfitFactor
      BaselineTradeCloseDrawdown = $baseline.TradeCloseDrawdown
      BaselineNegativeYears = $baseline.NegativeYears
   }) | Out-Null
}

$orderedScreen = @($screen | Sort-Object @{Expression="Eligible";Descending=$true}, @{Expression="NetProfit";Descending=$true}, @{Expression="ProfitFactor";Descending=$true})
$orderedScreen | Export-Csv -LiteralPath (Resolve-RepoPath $OutScreen) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Daily Donchian Feature Gate Screen") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- Phase: **$period**") | Out-Null
$lines.Add("- Baseline: **$($baseline.Trades) trades, `$$($baseline.NetProfit), PF $($baseline.ProfitFactor), trade-close DD `$$($baseline.TradeCloseDrawdown), $($baseline.NegativeYears) negative active years**") | Out-Null
$lines.Add("- Discovery eligibility: retain at least 70% of trades, do not reduce net/PF, do not increase trade-close drawdown or negative active years.") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("| Gate | Eligible | Trades | Retained | Net | Delta | PF | DD | Neg years | Removed W/L |") | Out-Null
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|") | Out-Null
foreach($row in ($orderedScreen | Select-Object -First 30)) {
   $lines.Add("| $($row.GateId) | $($row.Eligible) | $($row.Trades) | $($row.RetentionPercent)% | `$$($row.NetProfit) | `$$($row.NetDelta) | $($row.ProfitFactor) | `$$($row.TradeCloseDrawdown) | $($row.NegativeYears) | $($row.RemovedWinners)/$($row.RemovedLosers) |") | Out-Null
}
$lines | Set-Content -LiteralPath (Resolve-RepoPath $OutMarkdown) -Encoding ASCII

[pscustomobject]@{
   Phase = $period
   TradesParsed = $trades.Count
   BaselineTrades = $baseline.Trades
   BaselineNetProfit = $baseline.NetProfit
   EligibleGates = @($screen | Where-Object Eligible).Count
   OutTrades = $OutTrades
   OutScreen = $OutScreen
   OutMarkdown = $OutMarkdown
}

