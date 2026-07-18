Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourcePath = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package\source\Professional_XAUUSD_EA.mq5"
$profilePath = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package\profiles\rdmc_diversified_repair_restart_safe_v2.set"

$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{ Check = $Name; Pass = $Pass; Evidence = $Evidence })
}

function Get-Section([string]$Text, [string]$Start, [string]$End) {
   $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
   $endIndex = if($startIndex -ge 0) { $Text.IndexOf($End, $startIndex, [StringComparison]::Ordinal) } else { -1 }
   if($startIndex -lt 0 -or $endIndex -le $startIndex) { return "" }
   return $Text.Substring($startIndex, $endIndex - $startIndex)
}

function Read-Profile([string]$Path) {
   $values = @{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -match '^([^;=]+)=([^|]*)(.*)$') { $values[$matches[1]] = $matches[2] }
   }
   return $values
}

function Test-MarketEntryPath(
   [bool]$QuoteValid,
   [bool]$PreflightAccepted,
   [bool]$Submitted,
   [string]$Retcode,
   [uint64]$Deal
) {
   if(!$QuoteValid -or !$PreflightAccepted) { return $false }
   return $Submitted -and $Retcode -in @('DONE', 'DONE_PARTIAL') -and $Deal -gt 0
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Order-preflight audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$validatedTrade = Get-Section $source "class CValidatedTrade : public CTrade" "CValidatedTrade trade;"
$entry = Get-Section $source "bool ExecuteMarketEntry(CValidatedTrade &executor," "bool ExecutePositionClose(CTrade &executor,"
$closeMatch = [regex]::Match($source, 'bool ExecutePositionClose\(CTrade &executor, const ulong ticket\)\s*\{')
$closeEnd = if($closeMatch.Success) { $source.IndexOf('bool TradePriceMatches(', $closeMatch.Index, [StringComparison]::Ordinal) } else { -1 }
$close = if($closeMatch.Success -and $closeEnd -gt $closeMatch.Index) { $source.Substring($closeMatch.Index, $closeEnd - $closeMatch.Index) } else { '' }
$finalOnTickIndex = $source.LastIndexOf('void OnTick()', [StringComparison]::Ordinal)
$finalTransactionIndex = $source.LastIndexOf('void OnTradeTransaction', [StringComparison]::Ordinal)
$onTick = if($finalOnTickIndex -ge 0 -and $finalTransactionIndex -gt $finalOnTickIndex) { $source.Substring($finalOnTickIndex, $finalTransactionIndex - $finalOnTickIndex) } else { '' }

Add-Check "source version is 1.30" ($source.Contains('#property version   "1.30"')) "version"
Add-Check "description advertises scoped ownership-checked execution" ($source.Contains('verified account-scoped') -and $source.Contains('ownership-checked execution')) "description"
Add-Check "validated executor derives from CTrade" ($validatedTrade.Contains('class CValidatedTrade : public CTrade')) "derived executor"
Add-Check "market preflight is a public executor method" ($validatedTrade.Contains('public:') -and $validatedTrade.Contains('bool MarketEntryPreflight(')) "public method"
Add-Check "preflight reads one atomic tick" ([regex]::Matches($validatedTrade, 'SymbolInfoTick\(symbol, tick\)').Count -eq 1) "atomic quote"
Add-Check "preflight rejects missing or crossed prices" ($validatedTrade.Contains('tick.bid <= 0.0') -and $validatedTrade.Contains('tick.ask <= 0.0') -and $validatedTrade.Contains('tick.ask <= tick.bid')) "quote geometry"
Add-Check "invalid quote maps to PRICE_OFF" ($validatedTrade.Contains('m_result.retcode = TRADE_RETCODE_PRICE_OFF;') -and $validatedTrade.Contains('preflight: invalid quote')) "actionable result"
Add-Check "request is zero initialized" ($validatedTrade.Contains('MqlTradeRequest request;') -and $validatedTrade.Contains('ZeroMemory(request);')) "clean request"
Add-Check "request action is market deal" ($validatedTrade.Contains('request.action = TRADE_ACTION_DEAL;')) "action"
Add-Check "request carries configured magic" ($validatedTrade.Contains('request.magic = m_magic;')) "magic"
Add-Check "request carries exact symbol" ($validatedTrade.Contains('request.symbol = symbol;')) "symbol"
Add-Check "request carries exact volume" ($validatedTrade.Contains('request.volume = volume;')) "volume"
Add-Check "request uses direction-correct current price" ($validatedTrade.Contains('request.price = buy ? tick.ask : tick.bid;')) "price"
Add-Check "request carries exact protective stop" ($validatedTrade.Contains('request.sl = sl;')) "stop loss"
Add-Check "request carries exact take profit" ($validatedTrade.Contains('request.tp = tp;')) "take profit"
Add-Check "request carries configured deviation" ($validatedTrade.Contains('request.deviation = m_deviation;')) "deviation"
Add-Check "request carries direction" ($validatedTrade.Contains('request.type = buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;')) "order type"
Add-Check "request carries symbol-native filling" ($validatedTrade.Contains('request.type_filling = m_type_filling;')) "filling"
Add-Check "request carries strategy comment" ($validatedTrade.Contains('request.comment = comment;')) "comment"
Add-Check "broker OrderCheck uses persistent check result" ($validatedTrade.Contains('OrderCheck(request, m_check_result)')) "OrderCheck"
Add-Check "only accepted preflight returns true" ($validatedTrade.Contains('if(OrderCheck(request, m_check_result))') -and $validatedTrade.Contains('return true;')) "accepted only"
Add-Check "failed preflight clears stale execution result" ($validatedTrade.Contains('ZeroMemory(m_result);')) "result reset"
Add-Check "failed preflight propagates broker retcode" ($validatedTrade.Contains('m_check_result.retcode != 0') -and $validatedTrade.Contains('TRADE_RETCODE_ERROR')) "retcode fallback"
Add-Check "failed preflight propagates broker comment" ($validatedTrade.Contains('m_result.comment = "preflight: " + m_check_result.comment;')) "comment"
Add-Check "preflight does not send an order" ($validatedTrade -notmatch '\.(?:Buy|Sell|PositionOpen)\s*\(' -and $validatedTrade -notmatch '(?<!\.)OrderSend(?:Async)?\s*\(') "check only"

$preflightIndex = $entry.IndexOf('MarketEntryPreflight(', [StringComparison]::Ordinal)
$buyIndex = $entry.IndexOf('executor.Buy(', [StringComparison]::Ordinal)
$sellIndex = $entry.IndexOf('executor.Sell(', [StringComparison]::Ordinal)
Add-Check "entry wrapper preflights before either send" ($preflightIndex -ge 0 -and $buyIndex -gt $preflightIndex -and $sellIndex -gt $preflightIndex) "preflight=$preflightIndex buy=$buyIndex sell=$sellIndex"
Add-Check "preflight rejection returns before send" ($entry.Contains('if(!executor.MarketEntryPreflight') -and $entry.Contains('return false;')) "fail closed"
Add-Check "entry wrapper retains completed-retcode requirement" ($entry.Contains('TRADE_RETCODE_DONE') -and $entry.Contains('TRADE_RETCODE_DONE_PARTIAL') -and !$entry.Contains('TRADE_RETCODE_PLACED')) "completed execution"
Add-Check "entry wrapper retains deal-ticket requirement" ($entry.Contains('if(executor.ResultDeal() <= 0)')) "deal required"
Add-Check "exactly two validated executors exist" ([regex]::Matches($source, 'CValidatedTrade\s+(?:trade|m_trade)\s*;').Count -eq 2) "primary and momentum"
Add-Check "all four entry lanes retain one shared wrapper" ([regex]::Matches($source, 'ExecuteMarketEntry\(').Count -eq 5) "definition plus four calls"
Add-Check "only one broker preflight implementation exists" ([regex]::Matches($source, 'OrderCheck\(request, m_check_result\)').Count -eq 1) "one shared check"
Add-Check "only wrapper sends Buy and Sell" ([regex]::Matches($source, '\.Buy\s*\(').Count -eq 1 -and [regex]::Matches($source, '\.Sell\s*\(').Count -eq 1) "one each"
Add-Check "close wrapper remains base CTrade" ($close.Contains('bool ExecutePositionClose(CTrade &executor,') -and !$close.Contains('MarketEntryPreflight')) "protective close unchanged"
Add-Check "final OnTick has no global preflight return" (!$onTick.Contains('MarketEntryPreflight')) "management remains reachable"
Add-Check "failure evidence includes broker comment" ($source.Contains('", comment=" + executor.ResultComment()')) "preflight detail visible"

$scenarios = @(
   @{ Name='accepted full execution'; Expected=$true; Quote=$true; Check=$true; Submit=$true; Retcode='DONE'; Deal=11 },
   @{ Name='accepted partial execution'; Expected=$true; Quote=$true; Check=$true; Submit=$true; Retcode='DONE_PARTIAL'; Deal=12 },
   @{ Name='missing quote'; Expected=$false; Quote=$false; Check=$true; Submit=$true; Retcode='DONE'; Deal=13 },
   @{ Name='broker preflight rejects'; Expected=$false; Quote=$true; Check=$false; Submit=$true; Retcode='DONE'; Deal=14 },
   @{ Name='local submission failure'; Expected=$false; Quote=$true; Check=$true; Submit=$false; Retcode='DONE'; Deal=15 },
   @{ Name='broker send rejects'; Expected=$false; Quote=$true; Check=$true; Submit=$true; Retcode='REJECT'; Deal=0 },
   @{ Name='merely placed'; Expected=$false; Quote=$true; Check=$true; Submit=$true; Retcode='PLACED'; Deal=0 },
   @{ Name='completed without deal'; Expected=$false; Quote=$true; Check=$true; Submit=$true; Retcode='DONE'; Deal=0 }
)
foreach($scenario in $scenarios) {
   $actual = Test-MarketEntryPath $scenario.Quote $scenario.Check $scenario.Submit $scenario.Retcode $scenario.Deal
   Add-Check "preflight model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

foreach($contract in @{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseDedicatedAccountContract = 'true'
   InpUseAccountWideExposureGuard = 'true'
   InpUseMarginGuard = 'true'
   InpUseMarginAwareLotCap = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "preflight profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC order-preflight checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC order-preflight checks"
