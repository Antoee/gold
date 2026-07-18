Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tempRoot = Join-Path $env:TEMP ("mt5_trade_segments_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

function Assert-Equal {
   param($Actual, $Expected, [string]$Message)
   if([string]$Actual -ne [string]$Expected) {
      throw "$Message. Expected '$Expected', got '$Actual'."
   }
}

try {
   $report = Join-Path $tempRoot 'fixture.htm'
   $trades = Join-Path $tempRoot 'trades.csv'
   $summary = Join-Path $tempRoot 'summary.csv'
   $markdown = Join-Path $tempRoot 'summary.md'
   @'
<html><body><b>Deals</b><table>
<tr><td>Time</td><td>Deal</td><td>Symbol</td><td>Type</td><td>Direction</td><td>Volume</td><td>Price</td><td>Order</td><td>Commission</td><td>Swap</td><td>Profit</td><td>Balance</td><td>Comment</td></tr>
<tr><td>2025.01.02 09:00:00</td><td>1</td><td>XAUUSD</td><td>buy</td><td>in</td><td>0.10</td><td>2000.00</td><td>1</td><td>-1.00</td><td>0.00</td><td>0.00</td><td>10000.00</td><td>DGF;Liquidity sweep;Diagnostic</td></tr>
<tr><td>2025.01.02 10:00:00</td><td>2</td><td>XAUUSD</td><td>sell</td><td>out</td><td>0.10</td><td>2010.00</td><td>2</td><td>-1.00</td><td>0.00</td><td>100.00</td><td>10098.00</td><td>tp</td></tr>
<tr><td>2025.01.03 10:00:00</td><td>3</td><td>XAUUSD</td><td>sell</td><td>in</td><td>0.10</td><td>2010.00</td><td>3</td><td>0.00</td><td>0.00</td><td>0.00</td><td>10098.00</td><td>DGF;Diagnostic trend fallback;</td></tr>
<tr><td>2025.01.03 10:30:00</td><td>4</td><td>XAUUSD</td><td>buy</td><td>out</td><td>0.10</td><td>2015.00</td><td>4</td><td>0.00</td><td>0.00</td><td>-50.00</td><td>10048.00</td><td>sl</td></tr>
</table></body></html>
'@ | Set-Content -LiteralPath $report -Encoding ASCII

   & (Join-Path $repo 'work\analyze_mt5_report_trade_segments.ps1') -ReportPath $report -OutTrades $trades -OutSummary $summary -OutMarkdown $markdown | Out-Null
   $tradeRows = @(Import-Csv -LiteralPath $trades)
   $summaryRows = @(Import-Csv -LiteralPath $summary)
   Assert-Equal $tradeRows.Count 2 'Closed trade count'
   Assert-Equal $tradeRows[0].Profit 98 'Commission-adjusted winning profit'
   Assert-Equal $tradeRows[0].EntrySubtype 'liquidity_sweep' 'Liquidity subtype'
   Assert-Equal $tradeRows[1].EntrySubtype 'trend_fallback' 'Fallback subtype'
   $overall = $summaryRows | Where-Object Dimension -eq 'Overall'
   Assert-Equal $overall.NetProfit 48 'Overall net profit'
   Assert-Equal $overall.ProfitFactor 1.96 'Overall profit factor'
   'MT5_REPORT_TRADE_SEGMENTS_SMOKE_PASS'
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
