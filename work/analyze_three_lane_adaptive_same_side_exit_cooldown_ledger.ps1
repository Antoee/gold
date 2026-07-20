[CmdletBinding()]
param(
   [ValidateRange(2015,2026)][int]$FromYear,
   [ValidateRange(2015,2026)][int]$ToYear,
   [string]$LedgerPath='outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_CONTINUOUS_TRADES.csv',
   [string]$OutCsv,
   [string]$OutMarkdown
)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
if($FromYear-gt$ToYear){throw 'FromYear must not exceed ToYear.'}
if([string]::IsNullOrWhiteSpace($OutCsv)-or[string]::IsNullOrWhiteSpace($OutMarkdown)){throw 'Output paths are required.'}
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Sum-Profit($Rows){$total=0.0;foreach($row in @($Rows)){$total+=[double]$row.Profit};return $total}
$ledger=(Resolve-Path -LiteralPath (Resolve-RepoPath $LedgerPath)).Path
$expectedLedgerHash='6D880F634BD792281DAB72C5ACC6BF9F2C617888184881BD9AFA2D84DCEFAC40'
$ledgerHash=(Get-FileHash $ledger -Algorithm SHA256).Hash.ToUpperInvariant()
if($ledgerHash-ne$expectedLedgerHash){throw "Leader ledger identity changed: $ledgerHash"}
$culture=[Globalization.CultureInfo]::InvariantCulture
$trades=@(Import-Csv $ledger|ForEach-Object{
   [pscustomobject]@{
      Entry=[datetime]::Parse($_.EntryTime,$culture)
      Exit=[datetime]::Parse($_.ExitTime,$culture)
      Year=[int]$_.EntryYear
      Side=[string]$_.Side
      Lane=if($_.EntryComment-like'MTSM*'){'momentum'}elseif($_.EntryComment-like'ATB*'){'adaptive'}else{'reversion'}
      Profit=[double]::Parse($_.Profit,$culture)
   }
})
$window=@($trades|Where-Object{$_.Year-ge$FromYear-and$_.Year-le$ToYear})
$adaptive=@($window|Where-Object Lane -eq 'adaptive')
$features=foreach($trade in $adaptive){
   $prior=@($trades|Where-Object{$_.Exit-le$trade.Entry-and$_.Lane-eq'adaptive'-and$_.Side-eq$trade.Side}|Sort-Object Exit -Descending|Select-Object -First 1)
   if($prior.Count-ne1){continue}
   [pscustomobject]@{Entry=$trade.Entry;Side=$trade.Side;AgeMinutes=($trade.Entry-$prior[0].Exit).TotalMinutes;Profit=$trade.Profit}
}
$portfolioNet=Sum-Profit $window;$adaptiveNet=Sum-Profit $adaptive
$rows=foreach($threshold in 2880,4320,5760,7200){
   $blocked=@($features|Where-Object AgeMinutes -le $threshold)
   $wins=Sum-Profit @($blocked|Where-Object Profit -gt 0);$losses=Sum-Profit @($blocked|Where-Object Profit -lt 0);$blockedNet=$wins+$losses
   [pscustomobject][ordered]@{
      FromYear=$FromYear;ToYear=$ToYear;CooldownMinutes=$threshold;CooldownHours=$threshold/60
      AffectedTrades=$blocked.Count;AffectedNet=[Math]::Round($blockedNet,2)
      AffectedProfitFactor=if($losses-lt-0.000001){[Math]::Round($wins/(-1.0*$losses),4)}else{0.0}
      AdaptiveControlTrades=$adaptive.Count;AdaptiveControlNet=[Math]::Round($adaptiveNet,2)
      PortfolioControlTrades=$window.Count;PortfolioControlNet=[Math]::Round($portfolioNet,2)
      OfflineProjectedPortfolioNet=[Math]::Round($portfolioNet-$blockedNet,2)
      OfflineProjectedImprovement=[Math]::Round(-$blockedNet,2)
      LedgerSha256=$ledgerHash
   }
}
$outCsvPath=Resolve-RepoPath $OutCsv;$outMarkdownPath=Resolve-RepoPath $OutMarkdown
$rows|Export-Csv $outCsvPath -NoTypeInformation -Encoding ASCII
$lines=@(
   '# Adaptive Same-Side Exit Cooldown Ledger Screen','',
   "- Window: ``$FromYear-$ToYear``",
   "- Exact leader ledger SHA-256: ``$ledgerHash``",
   '- Rule screened: suppress an adaptive-lane entry when the most recent adaptive-lane exit on the same symbol and side occurred within the fixed elapsed-time threshold.',
   '- The screen never reads the prior trade outcome. Offline projected profit is nomination evidence only; executable MT5 behavior can differ because sizing, equity, and exposure paths change.','',
   '| Cooldown | Affected trades | Affected net | PF | Portfolio control | Offline projection | Improvement |',
   '|---:|---:|---:|---:|---:|---:|---:|'
)
foreach($row in $rows){$lines+=('| {0}h | {1} | {2:+$0.00;-$0.00;$0.00} | {3} | {4:+$0.00;-$0.00;$0.00} | {5:+$0.00;-$0.00;$0.00} | {6:+$0.00;-$0.00;$0.00} |' -f $row.CooldownHours,$row.AffectedTrades,$row.AffectedNet,$row.AffectedProfitFactor,$row.PortfolioControlNet,$row.OfflineProjectedPortfolioNet,$row.OfflineProjectedImprovement)}
$lines|Set-Content $outMarkdownPath -Encoding ASCII
[pscustomobject]@{Status='ANALYZED';FromYear=$FromYear;ToYear=$ToYear;Rows=$rows.Count;LedgerSha256=$ledgerHash;OutCsv=$OutCsv;OutMarkdown=$OutMarkdown}
