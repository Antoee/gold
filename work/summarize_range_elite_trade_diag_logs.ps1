param(
   [string]$PackageDir = "outputs\range_elite_failure_trade_diag_package",
   [string]$QueueManifest = "outputs\RANGE_ELITE_FAILURE_TRADE_DIAG_QUEUE.csv",
   [string]$OutTradesCsv = "outputs\RANGE_ELITE_FAILURE_TRADE_DIAG_TRADES.csv",
   [string]$OutSummaryCsv = "outputs\RANGE_ELITE_FAILURE_TRADE_DIAG_SUMMARY.csv",
   [string]$OutReasonCsv = "outputs\RANGE_ELITE_FAILURE_TRADE_DIAG_REASON_SUMMARY.csv",
   [string]$OutMarkdown = "outputs\RANGE_ELITE_FAILURE_TRADE_DIAG_ANALYSIS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$culture = [Globalization.CultureInfo]::InvariantCulture
$knownHeaders = @(
   "time", "event", "symbol", "ticket", "bias", "volume", "price", "sl", "tp",
   "risk_r", "profit", "reason", "atr", "spread_points", "max_favorable_r",
   "max_adverse_r", "held_bars", "entry_context", "profile_id", "source_hash", "run_label"
)

function Resolve-RepoPath {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return $Path }
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Ensure-ParentDir {
   param([string]$Path)
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

function To-DoubleOrNull {
   param([object]$Value)
   if($null -eq $Value) { return $null }
   $text = ([string]$Value).Trim()
   if($text -eq "") { return $null }
   $number = 0.0
   if([double]::TryParse($text.Replace("$", "").Replace(",", "").Replace("%", ""), [Globalization.NumberStyles]::Float, $culture, [ref]$number)) {
      return $number
   }
   return $null
}

function To-DateOrNull {
   param([object]$Value)
   if($null -eq $Value -or "$Value" -eq "") { return $null }
   $parsed = [datetime]::MinValue
   foreach($format in @("yyyy.MM.dd HH:mm:ss", "yyyy.MM.dd HH:mm", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-ddTHH:mm:ss")) {
      if([datetime]::TryParseExact(([string]$Value).Trim(), $format, $culture, [Globalization.DateTimeStyles]::AssumeLocal, [ref]$parsed)) {
         return $parsed
      }
   }
   if([datetime]::TryParse(([string]$Value).Trim(), [ref]$parsed)) { return $parsed }
   return $null
}

function Format-Number {
   param([object]$Value, [int]$Digits = 2)
   if($null -eq $Value) { return "" }
   return ([double]$Value).ToString(("F{0}" -f $Digits), $culture)
}

function Average-Values {
   param([object[]]$Values)
   $items = @($Values | Where-Object { $null -ne $_ })
   if($items.Count -eq 0) { return $null }
   return ($items | Measure-Object -Average).Average
}

function Sum-Values {
   param([object[]]$Values)
   $items = @($Values | Where-Object { $null -ne $_ })
   if($items.Count -eq 0) { return 0.0 }
   return ($items | Measure-Object -Sum).Sum
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

function Import-TradeLog {
   param([string]$Path)
   $lines = @(Get-Content -LiteralPath $Path | Where-Object { "$_".Trim() -ne "" })
   if($lines.Count -eq 0) { return @() }

   $firstFields = @(([string]$lines[0]).Split("`t"))
   $hasHeader = $false
   if($firstFields.Count -ge 3 -and
      $firstFields[0].Trim().ToLowerInvariant() -eq "time" -and
      $firstFields[1].Trim().ToLowerInvariant() -eq "event") {
      $hasHeader = $true
   }

   if($hasHeader) {
      return @(Import-Csv -LiteralPath $Path -Delimiter "`t")
   }

   $rows = [System.Collections.Generic.List[object]]::new()
   foreach($line in $lines) {
      $fields = @(([string]$line).Split("`t"))
      $obj = [ordered]@{}
      for($i = 0; $i -lt $knownHeaders.Count; $i++) {
         $obj[$knownHeaders[$i]] = if($i -lt $fields.Count) { $fields[$i] } else { "" }
      }
      $rows.Add([pscustomobject]$obj) | Out-Null
   }
   return @($rows)
}

function Get-Lane {
   param([string]$Reason)
   $text = ([string]$Reason)
   if($text -match "Range reversion|FMR|Flat month micro reversion") { return "range_reversion_fmr" }
   if($text -match "Liquidity sweep" -and $text -match "Diagnostic trend fallback") { return "sweep_plus_diagnostic" }
   if($text -match "Liquidity sweep") { return "liquidity_sweep" }
   if($text -match "Diagnostic trend fallback") { return "diagnostic_fallback" }
   if($text -match "In-session liquidity pullback|ISLP") { return "islp" }
   if($text -match "breakout|Breakout") { return "breakout" }
   return "other"
}

function Get-MaxTradeDrawdown {
   param([object[]]$Trades)
   $equity = 0.0
   $peak = 0.0
   $maxDd = 0.0
   foreach($trade in ($Trades | Sort-Object EntryTime, CloseTime, Ticket)) {
      $equity += [double]$trade.Profit
      if($equity -gt $peak) { $peak = $equity }
      $dd = $peak - $equity
      if($dd -gt $maxDd) { $maxDd = $dd }
   }
   return $maxDd
}

$packageFull = Resolve-RepoPath $PackageDir
$queueFull = Resolve-RepoPath $QueueManifest
if(!(Test-Path -LiteralPath $queueFull)) { throw "Queue manifest missing: $queueFull" }

$tradeLogDir = Join-Path $packageFull "trade_logs"
New-Item -ItemType Directory -Path $tradeLogDir -Force | Out-Null
$commonFilesDir = Join-Path $env:APPDATA "MetaQuotes\Terminal\Common\Files"

$queueRows = @(Import-Csv -LiteralPath $queueFull)
foreach($row in $queueRows) {
   $name = [string]$row.TradeLogFile
   if([string]::IsNullOrWhiteSpace($name)) { continue }
   $commonPath = Join-Path $commonFilesDir $name
   $targetPath = Join-Path $tradeLogDir $name
   if(Test-Path -LiteralPath $commonPath) {
      Copy-Item -LiteralPath $commonPath -Destination $targetPath -Force
   }
}

$trades = [System.Collections.Generic.List[object]]::new()
foreach($row in $queueRows) {
   $path = Join-Path $tradeLogDir ([string]$row.TradeLogFile)
   if(!(Test-Path -LiteralPath $path)) { continue }
   $records = @(Import-TradeLog $path)
   $entries = @{}
   foreach($record in $records) {
      $ticket = [string]$record.ticket
      if($ticket -eq "") { continue }
      if(([string]$record.event).Trim().ToLowerInvariant() -eq "entry") {
         $entries[$ticket] = $record
      }
   }

   foreach($record in $records) {
      if(([string]$record.event).Trim().ToLowerInvariant() -ne "closed_deal") { continue }
      $ticket = [string]$record.ticket
      $entry = if($entries.ContainsKey($ticket)) { $entries[$ticket] } else { $null }
      $entryTime = if($null -ne $entry) { To-DateOrNull $entry.time } else { $null }
      $closeTime = To-DateOrNull $record.time
      $entryReason = if($null -ne $entry) { [string]$entry.reason } else { "" }
      $closeReason = [string]$record.reason
      $profit = To-DoubleOrNull $record.profit
      $riskR = To-DoubleOrNull $record.risk_r
      $spread = if($null -ne $entry) { To-DoubleOrNull $entry.spread_points } else { To-DoubleOrNull $record.spread_points }
      $atr = if($null -ne $entry) { To-DoubleOrNull $entry.atr } else { To-DoubleOrNull $record.atr }

      $trades.Add([pscustomobject]@{
         Window = [string]$row.Window
         Role = [string]$row.Role
         Model = [string]$row.Model
         Ticket = $ticket
         EntryTime = $entryTime
         CloseTime = $closeTime
         Month = if($entryTime) { $entryTime.ToString("yyyy-MM") } else { "" }
         Hour = if($entryTime) { $entryTime.Hour } else { $null }
         Bias = if($null -ne $entry) { [string]$entry.bias } else { "" }
         Volume = if($null -ne $entry) { To-DoubleOrNull $entry.volume } else { To-DoubleOrNull $record.volume }
         EntryPrice = if($null -ne $entry) { To-DoubleOrNull $entry.price } else { $null }
         StopLoss = if($null -ne $entry) { To-DoubleOrNull $entry.sl } else { $null }
         TakeProfit = if($null -ne $entry) { To-DoubleOrNull $entry.tp } else { $null }
         PlannedR = if($null -ne $entry) { To-DoubleOrNull $entry.risk_r } else { $null }
         Profit = $profit
         RealizedR = $riskR
         EntryReason = $entryReason
         CloseReason = $closeReason
         Lane = Get-Lane $entryReason
         ATR = $atr
         SpreadPoints = $spread
         MFE_R = To-DoubleOrNull $record.max_favorable_r
         MAE_R = To-DoubleOrNull $record.max_adverse_r
         HeldBars = To-DoubleOrNull $record.held_bars
         ProfileId = [string]$record.profile_id
         SourceHash = [string]$record.source_hash
         RunLabel = [string]$record.run_label
         SourceLog = [string]$row.TradeLogFile
      }) | Out-Null
   }
}

$tradeRows = @($trades | Sort-Object Window, EntryTime, Ticket)
$summaryRows = foreach($group in ($tradeRows | Group-Object Window)) {
   $items = @($group.Group)
   $wins = @($items | Where-Object { $_.Profit -gt 0 })
   $losses = @($items | Where-Object { $_.Profit -lt 0 })
   $grossWin = Sum-Values @($wins | ForEach-Object { $_.Profit })
   $grossLossAbs = [Math]::Abs((Sum-Values @($losses | ForEach-Object { $_.Profit })))
   $pf = if($grossLossAbs -gt 0) { $grossWin / $grossLossAbs } elseif($grossWin -gt 0) { 999.0 } else { 0.0 }
   [pscustomobject]@{
      Window = $group.Name
      Role = ($items | Select-Object -First 1).Role
      Trades = $items.Count
      NetProfit = [Math]::Round((Sum-Values @($items | ForEach-Object { $_.Profit })), 2)
      ProfitFactor = [Math]::Round($pf, 4)
      Wins = $wins.Count
      Losses = $losses.Count
      AvgSpread = [Math]::Round((Average-Values @($items | ForEach-Object { $_.SpreadPoints })), 2)
      AvgATR = [Math]::Round((Average-Values @($items | ForEach-Object { $_.ATR })), 2)
      AvgRealizedR = [Math]::Round((Average-Values @($items | ForEach-Object { $_.RealizedR })), 2)
      TradePathMaxDD = [Math]::Round((Get-MaxTradeDrawdown $items), 2)
   }
}

$reasonRows = foreach($group in ($tradeRows | Group-Object Window, Lane)) {
   $items = @($group.Group)
   $wins = @($items | Where-Object { $_.Profit -gt 0 })
   $losses = @($items | Where-Object { $_.Profit -lt 0 })
   [pscustomobject]@{
      Window = ($items | Select-Object -First 1).Window
      Lane = ($items | Select-Object -First 1).Lane
      Trades = $items.Count
      NetProfit = [Math]::Round((Sum-Values @($items | ForEach-Object { $_.Profit })), 2)
      Wins = $wins.Count
      Losses = $losses.Count
      AvgSpread = [Math]::Round((Average-Values @($items | ForEach-Object { $_.SpreadPoints })), 2)
      AvgRealizedR = [Math]::Round((Average-Values @($items | ForEach-Object { $_.RealizedR })), 2)
   }
}

$outTradesFull = Resolve-RepoPath $OutTradesCsv
$outSummaryFull = Resolve-RepoPath $OutSummaryCsv
$outReasonFull = Resolve-RepoPath $OutReasonCsv
$outMarkdownFull = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $outTradesFull
Ensure-ParentDir $outSummaryFull
Ensure-ParentDir $outReasonFull
Ensure-ParentDir $outMarkdownFull

if($tradeRows.Count -gt 0) {
   $tradeRows | Export-Csv -LiteralPath $outTradesFull -NoTypeInformation -Encoding ASCII
} else {
   @('"Window","Role","Model","Ticket","EntryTime","CloseTime","Month","Hour","Bias","Volume","EntryPrice","StopLoss","TakeProfit","PlannedR","Profit","RealizedR","EntryReason","CloseReason","Lane","ATR","SpreadPoints","MFE_R","MAE_R","HeldBars","ProfileId","SourceHash","RunLabel","SourceLog"') |
      Set-Content -LiteralPath $outTradesFull -Encoding ASCII
}

if($summaryRows) { $summaryRows | Export-Csv -LiteralPath $outSummaryFull -NoTypeInformation -Encoding ASCII }
else { @('"Window","Role","Trades","NetProfit","ProfitFactor","Wins","Losses","AvgSpread","AvgATR","AvgRealizedR","TradePathMaxDD"') | Set-Content -LiteralPath $outSummaryFull -Encoding ASCII }

if($reasonRows) { $reasonRows | Export-Csv -LiteralPath $outReasonFull -NoTypeInformation -Encoding ASCII }
else { @('"Window","Lane","Trades","NetProfit","Wins","Losses","AvgSpread","AvgRealizedR"') | Set-Content -LiteralPath $outReasonFull -Encoding ASCII }

$missingLogs = @($queueRows | Where-Object { !(Test-Path -LiteralPath (Join-Path $tradeLogDir ([string]$_.TradeLogFile))) })
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Range-Elite Failure Trade Diagnostic Analysis") | Out-Null
$md.Add("") | Out-Null
$md.Add('Generated from MT5 Common Files trade logs copied into the package `trade_logs` folder. No MT5 process was launched by this analyzer.') | Out-Null
$md.Add("") | Out-Null
$md.Add("- Package dir: ``$PackageDir``") | Out-Null
$md.Add("- Expected logs: ``$($queueRows.Count)``") | Out-Null
$md.Add("- Missing logs: ``$($missingLogs.Count)``") | Out-Null
$md.Add("- Closed trades parsed: ``$($tradeRows.Count)``") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Window Summary") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Window | Role | Trades | Net | PF | Wins | Losses | Avg Spread | Trade Path DD |") | Out-Null
$md.Add("| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |") | Out-Null
foreach($row in ($summaryRows | Sort-Object Window)) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |" -f
      (Escape-MarkdownCell $row.Window),
      (Escape-MarkdownCell $row.Role),
      $row.Trades,
      (Format-Number $row.NetProfit 2),
      (Format-Number $row.ProfitFactor 2),
      $row.Wins,
      $row.Losses,
      (Format-Number $row.AvgSpread 2),
      (Format-Number $row.TradePathMaxDD 2))) | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Lane Summary") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Window | Lane | Trades | Net | Wins | Losses | Avg Spread | Avg R |") | Out-Null
$md.Add("| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |") | Out-Null
foreach($row in ($reasonRows | Sort-Object Window, Lane)) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |" -f
      (Escape-MarkdownCell $row.Window),
      (Escape-MarkdownCell $row.Lane),
      $row.Trades,
      (Format-Number $row.NetProfit 2),
      $row.Wins,
      $row.Losses,
      (Format-Number $row.AvgSpread 2),
      (Format-Number $row.AvgRealizedR 2))) | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Worst Closed Trades") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Window | Time | Bias | Profit | R | Spread | Lane | Entry Reason | Close |") | Out-Null
$md.Add("| --- | --- | --- | ---: | ---: | ---: | --- | --- | --- |") | Out-Null
foreach($row in ($tradeRows | Sort-Object Profit | Select-Object -First 12)) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |" -f
      (Escape-MarkdownCell $row.Window),
      (Escape-MarkdownCell ([string]$row.EntryTime)),
      (Escape-MarkdownCell $row.Bias),
      (Format-Number $row.Profit 2),
      (Format-Number $row.RealizedR 2),
      (Format-Number $row.SpreadPoints 2),
      (Escape-MarkdownCell $row.Lane),
      (Escape-MarkdownCell $row.EntryReason),
      (Escape-MarkdownCell $row.CloseReason))) | Out-Null
}
if($missingLogs.Count -gt 0) {
   $md.Add("") | Out-Null
   $md.Add("## Missing Logs") | Out-Null
   $md.Add("") | Out-Null
   foreach($row in $missingLogs) {
      $md.Add("- ``$($row.Window)`` expected ``$($row.TradeLogFile)``") | Out-Null
   }
}
$md | Set-Content -LiteralPath $outMarkdownFull -Encoding ASCII

[pscustomobject]@{
   ExpectedLogs = $queueRows.Count
   MissingLogs = $missingLogs.Count
   ClosedTrades = $tradeRows.Count
   TradesCsv = $OutTradesCsv
   SummaryCsv = $OutSummaryCsv
   ReasonCsv = $OutReasonCsv
   Markdown = $OutMarkdown
}
