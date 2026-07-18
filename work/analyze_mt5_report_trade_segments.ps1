param(
   [Parameter(Mandatory = $true)][string]$ReportPath,
   [string]$OutTrades = "outputs\MT5_REPORT_TRADES.csv",
   [string]$OutSummary = "outputs\MT5_REPORT_TRADE_SEGMENTS.csv",
   [string]$OutMarkdown = "outputs\MT5_REPORT_TRADE_SEGMENTS.md",
   [ValidateRange(0.000001,1000000.0)][double]$ContractSize = 100.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
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

function Convert-HtmlCell {
   param([string]$Html)
   $text = [regex]::Replace($Html, '<[^>]+>', '')
   return ([System.Net.WebUtility]::HtmlDecode($text)).Trim()
}

function Convert-ReportNumber {
   param([string]$Text)
   $normalized = ([string]$Text).Replace([char]0xA0, ' ').Replace(' ', '').Replace(',', '')
   if([string]::IsNullOrWhiteSpace($normalized)) { return 0.0 }
   $value = 0.0
   if(![double]::TryParse($normalized, [Globalization.NumberStyles]::Float -bor [Globalization.NumberStyles]::AllowLeadingSign, [Globalization.CultureInfo]::InvariantCulture, [ref]$value)) {
      throw "Could not parse report number '$Text'."
   }
   return $value
}

function Get-EntrySubtype {
   param([string]$Comment)
   if($Comment -match '(?i)Liquidity sweep') { return 'liquidity_sweep' }
   if($Comment -match '(?i)Diagnostic trend fallback') { return 'trend_fallback' }
   if($Comment -match '(?i)^DGF;') { return 'dgf_other' }
   return 'other'
}

function New-SummaryRow {
   param([string]$Dimension, [string]$Segment, [object[]]$Rows)

   $profits = @($Rows | ForEach-Object { [double]$_.Profit })
   $grossProfit = [double](($profits | Where-Object { $_ -gt 0 } | Measure-Object -Sum).Sum)
   $grossLossSigned = [double](($profits | Where-Object { $_ -lt 0 } | Measure-Object -Sum).Sum)
   $grossLoss = [math]::Abs($grossLossSigned)
   $net = [double](($profits | Measure-Object -Sum).Sum)
   $wins = @($profits | Where-Object { $_ -gt 0 }).Count
   $pf = if($grossLoss -gt 0) { [math]::Round($grossProfit / $grossLoss, 4) } elseif($grossProfit -gt 0) { 'INF' } else { '0' }
   $avgHold = [double](($Rows | Measure-Object -Property HoldMinutes -Average).Average)

   [pscustomobject]@{
      Dimension = $Dimension
      Segment = $Segment
      Trades = $Rows.Count
      NetProfit = [math]::Round($net, 2)
      GrossProfit = [math]::Round($grossProfit, 2)
      GrossLoss = [math]::Round($grossLoss, 2)
      ProfitFactor = $pf
      WinRatePercent = [math]::Round(100.0 * $wins / [math]::Max(1, $Rows.Count), 2)
      AverageProfit = [math]::Round($net / [math]::Max(1, $Rows.Count), 2)
      AverageHoldMinutes = [math]::Round($avgHold, 2)
   }
}

$resolvedReport = Resolve-RepoPath $ReportPath
if(!(Test-Path -LiteralPath $resolvedReport)) { throw "MT5 report not found: $resolvedReport" }

$html = Get-Content -LiteralPath $resolvedReport -Raw
$ordersMarker = $html.IndexOf('<b>Orders</b>', [StringComparison]::OrdinalIgnoreCase)
$dealsMarker = $html.IndexOf('<b>Deals</b>', [StringComparison]::OrdinalIgnoreCase)
if($dealsMarker -lt 0) { throw "Deals section was not found in $resolvedReport" }
$options = [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::Singleline

$entryOrders = [System.Collections.Generic.List[object]]::new()
if($ordersMarker -ge 0 -and $ordersMarker -lt $dealsMarker) {
   $ordersHtml = $html.Substring($ordersMarker, $dealsMarker - $ordersMarker)
   $orderRowMatches = [regex]::Matches($ordersHtml, '<tr\b[^>]*>(?<row>.*?)</tr>', $options)
   foreach($rowMatch in $orderRowMatches) {
      $cellMatches = [regex]::Matches($rowMatch.Groups['row'].Value, '<td\b[^>]*>(?<cell>.*?)</td>', $options)
      if($cellMatches.Count -lt 11) { continue }
      $cells = @($cellMatches | ForEach-Object { Convert-HtmlCell $_.Groups['cell'].Value })
      $side = ([string]$cells[3]).ToLowerInvariant()
      if($side -notin @('buy', 'sell')) { continue }

      $stopPrice = Convert-ReportNumber $cells[6]
      if($stopPrice -le 0.0) { continue }

      $volumeText = ([string]$cells[4]).Split('/')[0].Trim()
      $entryOrders.Add([pscustomobject]@{
         OpenTime = [datetime]::ParseExact($cells[0], 'yyyy.MM.dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
         Symbol = [string]$cells[2]
         Side = $side
         Volume = Convert-ReportNumber $volumeText
         InitialStop = $stopPrice
         InitialTarget = Convert-ReportNumber $cells[7]
         Comment = [string]$cells[10]
         Matched = $false
      }) | Out-Null
   }
}

$dealsHtml = $html.Substring($dealsMarker)
$rowMatches = [regex]::Matches($dealsHtml, '<tr\b[^>]*>(?<row>.*?)</tr>', $options)

$openTrades = [System.Collections.Generic.List[object]]::new()
$trades = [System.Collections.Generic.List[object]]::new()
foreach($rowMatch in $rowMatches) {
   $cellMatches = [regex]::Matches($rowMatch.Groups['row'].Value, '<td\b[^>]*>(?<cell>.*?)</td>', $options)
   if($cellMatches.Count -lt 13) { continue }
   $cells = @($cellMatches | ForEach-Object { Convert-HtmlCell $_.Groups['cell'].Value })
   $direction = [string]$cells[4]
   if($direction -notin @('in', 'out', 'in/out')) { continue }

   $timestamp = [datetime]::ParseExact($cells[0], 'yyyy.MM.dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
   $symbol = [string]$cells[2]
   $commission = Convert-ReportNumber $cells[8]
   $swap = Convert-ReportNumber $cells[9]

   if($direction -in @('in', 'in/out')) {
      $entryVolume = Convert-ReportNumber $cells[5]
      $matchingOrder = $null
      foreach($order in $entryOrders) {
         if(!$order.Matched -and
            $order.OpenTime -eq $timestamp -and
            $order.Symbol -eq $symbol -and
            $order.Side -eq ([string]$cells[3]).ToLowerInvariant() -and
            [Math]::Abs([double]$order.Volume - $entryVolume) -lt 0.000001) {
            $matchingOrder = $order
            $order.Matched = $true
            break
         }
      }

      $openTrades.Add([pscustomobject]@{
         EntryTime = $timestamp
         Symbol = $symbol
         Side = [string]$cells[3]
         Volume = $entryVolume
         EntryPrice = Convert-ReportNumber $cells[6]
         InitialStop = if($null -ne $matchingOrder) { [double]$matchingOrder.InitialStop } else { 0.0 }
         InitialTarget = if($null -ne $matchingOrder) { [double]$matchingOrder.InitialTarget } else { 0.0 }
         EntryCommission = $commission
         EntrySwap = $swap
         EntryComment = [string]$cells[12]
      }) | Out-Null
      if($direction -eq 'in') { continue }
   }

   $entryIndex = -1
   for($i = 0; $i -lt $openTrades.Count; $i++) {
      if($openTrades[$i].Symbol -eq $symbol) { $entryIndex = $i; break }
   }
   if($entryIndex -lt 0) { continue }

   $entry = $openTrades[$entryIndex]
   $openTrades.RemoveAt($entryIndex)
   $profit = (Convert-ReportNumber $cells[10]) + [double]$entry.EntryCommission + [double]$entry.EntrySwap + $commission + $swap
   $holdMinutes = ($timestamp - [datetime]$entry.EntryTime).TotalMinutes
   $initialRiskDistance = if([double]$entry.InitialStop -gt 0.0) {
      [Math]::Abs([double]$entry.EntryPrice - [double]$entry.InitialStop)
   }
   else { 0.0 }
   $initialRiskMoney = $initialRiskDistance * [double]$entry.Volume * $ContractSize
   $riskR = if($initialRiskMoney -gt 0.0) { $profit / $initialRiskMoney } else { $null }
   $trades.Add([pscustomobject]@{
      EntryTime = ([datetime]$entry.EntryTime).ToString('s')
      ExitTime = $timestamp.ToString('s')
      EntryYear = ([datetime]$entry.EntryTime).Year
      EntryMonth = ([datetime]$entry.EntryTime).Month
      EntryHour = ([datetime]$entry.EntryTime).Hour
      DayOfWeek = ([datetime]$entry.EntryTime).DayOfWeek.ToString()
      Symbol = $symbol
      Side = [string]$entry.Side
      Volume = [double]$entry.Volume
      EntryPrice = [double]$entry.EntryPrice
      ExitPrice = Convert-ReportNumber $cells[6]
      InitialStop = if([double]$entry.InitialStop -gt 0.0) { [double]$entry.InitialStop } else { $null }
      InitialTarget = if([double]$entry.InitialTarget -gt 0.0) { [double]$entry.InitialTarget } else { $null }
      InitialRiskMoney = if($initialRiskMoney -gt 0.0) { [math]::Round($initialRiskMoney, 4) } else { $null }
      RiskR = if($null -ne $riskR) { [math]::Round([double]$riskR, 6) } else { $null }
      HoldMinutes = [math]::Round($holdMinutes, 2)
      Profit = [math]::Round($profit, 2)
      Winner = [string]($profit -gt 0)
      EntrySubtype = Get-EntrySubtype ([string]$entry.EntryComment)
      EntryComment = [string]$entry.EntryComment
      ExitComment = [string]$cells[12]
   }) | Out-Null
}

if($trades.Count -eq 0) { throw "No closed trades were parsed from $resolvedReport" }

$summary = [System.Collections.Generic.List[object]]::new()
$summary.Add((New-SummaryRow -Dimension 'Overall' -Segment 'all' -Rows @($trades))) | Out-Null
foreach($definition in @(
   @{ Dimension = 'EntrySubtype'; Property = 'EntrySubtype' },
   @{ Dimension = 'EntryHour'; Property = 'EntryHour' },
   @{ Dimension = 'EntryYear'; Property = 'EntryYear' },
   @{ Dimension = 'EntryMonth'; Property = 'EntryMonth' },
   @{ Dimension = 'Side'; Property = 'Side' },
   @{ Dimension = 'DayOfWeek'; Property = 'DayOfWeek' }
)) {
   foreach($group in ($trades | Group-Object -Property $definition.Property | Sort-Object Name)) {
      $summary.Add((New-SummaryRow -Dimension $definition.Dimension -Segment ([string]$group.Name) -Rows @($group.Group))) | Out-Null
   }
}

$tradesPath = Resolve-RepoPath $OutTrades
$summaryPath = Resolve-RepoPath $OutSummary
$markdownPath = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $tradesPath
Ensure-ParentDir $summaryPath
Ensure-ParentDir $markdownPath
$trades | Export-Csv -LiteralPath $tradesPath -NoTypeInformation -Encoding ASCII
$summary | Export-Csv -LiteralPath $summaryPath -NoTypeInformation -Encoding ASCII

$overall = $summary | Where-Object Dimension -eq 'Overall' | Select-Object -First 1
$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# MT5 Report Trade Segments')
$md.Add('')
$md.Add("- Report: ``$ReportPath``")
$md.Add("- Closed trades: ``$($overall.Trades)``")
$md.Add("- Parsed net profit: ``$($overall.NetProfit)``")
$md.Add("- Profit factor: ``$($overall.ProfitFactor)``")
$riskRows = @($trades | Where-Object { $null -ne $_.RiskR })
$md.Add("- Initial-risk coverage: ``$($riskRows.Count) / $($trades.Count)``")
$md.Add("- Contract size used for R calculation: ``$ContractSize``")
$md.Add('')
$md.Add('| Dimension | Segment | Trades | Net | PF | Win % | Avg | Avg Hold Min |')
$md.Add('| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |')
foreach($row in ($summary | Where-Object { $_.Dimension -in @('EntrySubtype', 'EntryHour', 'EntryYear') })) {
   $md.Add("| $($row.Dimension) | $($row.Segment) | $($row.Trades) | $($row.NetProfit) | $($row.ProfitFactor) | $($row.WinRatePercent) | $($row.AverageProfit) | $($row.AverageHoldMinutes) |")
}
$md | Set-Content -LiteralPath $markdownPath -Encoding ASCII

[pscustomobject]@{
   Report = $ReportPath
   Trades = $trades.Count
   NetProfit = $overall.NetProfit
   ProfitFactor = $overall.ProfitFactor
   OutTrades = $OutTrades
   OutSummary = $OutSummary
   OutMarkdown = $OutMarkdown
}
