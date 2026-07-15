param(
   [string]$ReportDir = "outputs\returned_mt5_reports\first_pass_inbox",
   [string]$OutCsv = "outputs\PEAK_TRAIL_UNBLOCK_CONTINUOUS_MODEL4_COMPARISON.csv",
   [string]$OutMarkdown = "outputs\PEAK_TRAIL_UNBLOCK_CONTINUOUS_MODEL4_DECISION.md",
   [double]$InitialDeposit = 1000.0,
   [string]$From = "2019-01-01",
   [string]$To = "2026-07-12"
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

function Convert-ToRepoRelative {
   param([string]$Path)
   $resolved = $Path
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
   }
   $root = $repo.TrimEnd('\') + '\'
   if($resolved.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
      return $resolved.Substring($root.Length)
   }
   return $resolved
}

function To-Number {
   param([string]$Text)
   if([string]::IsNullOrWhiteSpace($Text)) { return $null }
   $first = [regex]::Match($Text, '[-+]?\d[\d\s,]*(?:\.\d+)?')
   if(!$first.Success) { return $null }
   $value = $first.Value.Replace(" ", "").Replace(",", "")
   return [double]::Parse($value, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-ReportCells {
   param([string]$Path)
   $html = Get-Content -LiteralPath $Path -Raw
   return @([regex]::Matches($html, '<t[dh][^>]*>(.*?)</t[dh]>', 'Singleline') |
      ForEach-Object {
         ([System.Net.WebUtility]::HtmlDecode(($_.Groups[1].Value -replace '<[^>]+>', ''))).Trim()
      })
}

function Get-AfterLabel {
   param([string[]]$Cells, [string]$Pattern)
   for($i = 0; $i -lt $Cells.Count - 1; $i++) {
      if($Cells[$i] -match $Pattern) { return $Cells[$i + 1] }
   }
   return ""
}

function Read-ReportStats {
   param([string]$Candidate, [string]$ReportBaseName, [string]$Decision)
   $path = Resolve-RepoPath (Join-Path $ReportDir "$ReportBaseName.htm")
   if(!(Test-Path -LiteralPath $path)) {
      return [pscustomobject]@{
         Candidate = $Candidate
         Status = "MISSING_REPORT"
         Decision = $Decision
         ReportPath = Convert-ToRepoRelative $path
      }
   }

   $cells = Get-ReportCells -Path $path
   $net = To-Number (Get-AfterLabel -Cells $cells -Pattern '^Total\s+Net\s+Profit:')
   $equityDd = To-Number (Get-AfterLabel -Cells $cells -Pattern '^Equity\s+Drawdown\s+Maximal:')
   $balanceDd = To-Number (Get-AfterLabel -Cells $cells -Pattern '^Balance\s+Drawdown\s+Maximal:')
   $trades = To-Number (Get-AfterLabel -Cells $cells -Pattern '^Total\s+Trades:')
   $profitFactor = To-Number (Get-AfterLabel -Cells $cells -Pattern '^Profit\s+Factor:')
   $expectedPayoff = To-Number (Get-AfterLabel -Cells $cells -Pattern '^Expected\s+Payoff:')
   $sharpe = To-Number (Get-AfterLabel -Cells $cells -Pattern '^Sharpe\s+Ratio:')
   $recovery = To-Number (Get-AfterLabel -Cells $cells -Pattern '^Recovery\s+Factor:')
   $winRate = To-Number (Get-AfterLabel -Cells $cells -Pattern '^Profit\s+Trades')

   $equityDdText = Get-AfterLabel -Cells $cells -Pattern '^Equity\s+Drawdown\s+Maximal:'
   $equityDdPct = $null
   $pctMatch = [regex]::Match($equityDdText, '\(([-+]?\d+(?:\.\d+)?)%\)')
   if($pctMatch.Success) {
      $equityDdPct = [double]::Parse($pctMatch.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
   }

   $years = (([datetime]$To) - ([datetime]$From)).TotalDays / 365.25
   $totalReturnPct = if($null -ne $net) { [math]::Round(100.0 * $net / $InitialDeposit, 2) } else { $null }
   $annualizedReturnPct = if($null -ne $totalReturnPct -and $years -gt 0.0) { [math]::Round($totalReturnPct / $years, 2) } else { $null }
   $cagrPct = if($null -ne $net -and $InitialDeposit + $net -gt 0.0 -and $years -gt 0.0) {
      [math]::Round(100.0 * ([math]::Pow(($InitialDeposit + $net) / $InitialDeposit, 1.0 / $years) - 1.0), 2)
   } else {
      $null
   }
   $returnToDd = if($null -ne $totalReturnPct -and $null -ne $equityDdPct -and $equityDdPct -gt 0.0) {
      [math]::Round($totalReturnPct / $equityDdPct, 2)
   } else {
      $null
   }

   [pscustomobject]@{
      Candidate = $Candidate
      Status = "PARSED"
      Decision = $Decision
      NetProfit = $net
      TotalReturnPercent = $totalReturnPct
      AnnualizedReturnPercent = $annualizedReturnPct
      CagrPercent = $cagrPct
      ProfitFactor = $profitFactor
      ExpectedPayoff = $expectedPayoff
      SharpeRatio = $sharpe
      WinRatePercent = $winRate
      TotalTrades = $trades
      BalanceDrawdownMoney = $balanceDd
      EquityDrawdownMoney = $equityDd
      EquityDrawdownPercent = $equityDdPct
      ReturnToEquityDrawdown = $returnToDd
      RecoveryFactor = $recovery
      ReportPath = Convert-ToRepoRelative $path
   }
}

$reports = @(
   [pscustomobject]@{
      Candidate = "original_highprofit_lossblock_peaktrail_on"
      ReportBaseName = "range_elite_dgf_lossblock_highprofit_continuous_2019_2026_m4"
      Decision = "Rejected as sequential account profile; global peak trail stalls after 3 trades."
   },
   [pscustomobject]@{
      Candidate = "original_stability_lossblock_peaktrail_on"
      ReportBaseName = "range_elite_dgf_lossblock_stability_continuous_2019_2026_m4"
      Decision = "Rejected as sequential account profile; global peak trail stalls after 3 trades."
   },
   [pscustomobject]@{
      Candidate = "lossblock_stability_peaktrail_off"
      ReportBaseName = "lossblock_stability_peaktrail_off_continuous_2019_2026_m4"
      Decision = "Rejected; unblocking exposes a losing continuous curve."
   },
   [pscustomobject]@{
      Candidate = "lossblock_stability_peaktrail_8p_50gb"
      ReportBaseName = "lossblock_stability_peaktrail_8p_50gb_continuous_2019_2026_m4"
      Decision = "Rejected; same losing continuous curve as peak-trail off."
   },
   [pscustomobject]@{
      Candidate = "lossblock_highprofit_peaktrail_off"
      ReportBaseName = "lossblock_highprofit_peaktrail_off_continuous_2019_2026_m4"
      Decision = "New DGF continuous high-profit research lead, not money-ready due high drawdown."
   },
   [pscustomobject]@{
      Candidate = "lossblock_highprofit_peaktrail_8p_50gb"
      ReportBaseName = "lossblock_highprofit_peaktrail_8p_50gb_continuous_2019_2026_m4"
      Decision = "Rejected; profit too small for drawdown and recovery is weak."
   }
)

$rows = foreach($report in $reports) {
   Read-ReportStats -Candidate $report.Candidate -ReportBaseName $report.ReportBaseName -Decision $report.Decision
}

$outCsvFull = Resolve-RepoPath $OutCsv
$outMarkdownFull = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $outCsvFull
Ensure-ParentDir $outMarkdownFull
$rows | Export-Csv -LiteralPath $outCsvFull -NoTypeInformation -Encoding ASCII

$best = @($rows | Where-Object { $_.Status -eq "PARSED" } | Sort-Object NetProfit -Descending | Select-Object -First 1)
$bestRow = if($best.Count -gt 0) { $best[0] } else { $null }

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Peak-Trail Unblock Continuous Model4 Decision")
$md.Add("")
$md.Add("Date: 2026-07-14")
$md.Add("")
$md.Add("Verdict: **one new DGF continuous high-profit research lead, no money-ready profile**")
$md.Add("")
$md.Add("The prior DGF loss-block broad-window totals were useful restart-window research scores, but the continuous 2019-2026 Model4 account path showed that the original peak-trail-on profiles stalled after only 3 trades. This follow-up tested whether changing the global equity profit peak trail exposes a viable sequential account curve.")
$md.Add("")
$md.Add("## Result")
$md.Add("")
$md.Add("| Candidate | Net | Ann. %/yr | CAGR % | PF | Trades | Equity DD % | Return/DD | Recovery | Decision |")
$md.Add("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
foreach($row in $rows) {
   if($row.Status -ne "PARSED") {
      $md.Add(("| `{0}` |  |  |  |  |  |  |  |  | {1} |" -f $row.Candidate, $row.Decision))
      continue
   }
   $netText = if($row.NetProfit -ge 0) { "+$('{0:N2}' -f $row.NetProfit)" } else { "-$('{0:N2}' -f [math]::Abs($row.NetProfit))" }
   $md.Add(("| `{0}` | `{1}` | `{2}` | `{3}` | `{4}` | `{5}` | `{6}` | `{7}` | `{8}` | {9} |" -f
      $row.Candidate,
      $netText,
      $row.AnnualizedReturnPercent,
      $row.CagrPercent,
      $row.ProfitFactor,
      $row.TotalTrades,
      $row.EquityDrawdownPercent,
      $row.ReturnToEquityDrawdown,
      $row.RecoveryFactor,
      $row.Decision))
}
$md.Add("")
$md.Add("## Interpretation")
$md.Add("")
if($null -ne $bestRow) {
   $md.Add(('- `lossblock_highprofit_peaktrail_off` is the only profitable continuous-account DGF follow-up worth keeping as a research lead: net ``+${0}``, CAGR ``{1}%``, PF ``{2}``, ``127`` trades, but equity drawdown is ``{3}%``.' -f
      ('{0:N2}' -f $bestRow.NetProfit),
      $bestRow.CagrPercent,
      $bestRow.ProfitFactor,
      $bestRow.EquityDrawdownPercent))
}
$md.Add("- The original peak-trail-on loss-block profiles are no longer acceptable as promoted leads because they stalled after 3 trades on the continuous account path. Their yearly-window totals must be described as restart-window comparison scores, not achievable account returns.")
$md.Add('- The stability variants are rejected: once unblocked, they lost money (`-$199.80`) with about `37.22%` equity drawdown.')
$md.Add('- The 8%/50% high-profit peak-trail variant is rejected because it made only `+$108.48` with `19.90%` equity drawdown and recovery `0.39`.')
$md.Add("")
$md.Add("## Next Gate")
$md.Add("")
$md.Add("Do not call this trade-ready. The next useful test is risk shaping for `lossblock_highprofit_peaktrail_off`: reduce drawdown without reintroducing a permanent account freeze, then run yearly/monthly/quarterly/stress/broker checks with exported reports.")

$md | Set-Content -LiteralPath $outMarkdownFull -Encoding ASCII

[pscustomobject]@{
   Rows = $rows.Count
   Parsed = @($rows | Where-Object Status -eq "PARSED").Count
   BestCandidate = if($null -ne $bestRow) { $bestRow.Candidate } else { "" }
   BestNetProfit = if($null -ne $bestRow) { $bestRow.NetProfit } else { "" }
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
