param(
   [string]$SourcePath = "work\Professional_XAUUSD_Operational_Hardening_RC2_Forward_Sentinel.mq5",
   [string]$CompileLogPath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_COMPILE.log"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source = (Resolve-Path -LiteralPath (Join-Path $repo $SourcePath)).Path
$compileLog = (Resolve-Path -LiteralPath (Join-Path $repo $CompileLogPath)).Path
$expectedSourceHash = "801229B267FB126878B40F12BE1C833C7A4F381017040726B342CED27F7E46BF"
$expectedBinaryHash = "6E7067BD1DFE9CDC96F012D7FDABE379B2149FDA075C0B7FD12A8DE2CB06B3C0"
$binary = [IO.Path]::ChangeExtension($source, ".ex5")

$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$binaryHash = (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Sentinel source identity changed: $sourceHash" }
if($binaryHash -ne $expectedBinaryHash) { throw "Sentinel binary identity changed: $binaryHash" }

$text = Get-Content -Raw -LiteralPath $source
$compileText = Get-Content -Raw -LiteralPath $compileLog
if($compileText -notmatch 'Result:\s+0 errors, 0 warnings') { throw "Sentinel compile did not pass cleanly." }

$required = @(
   'InpExpectedSymbol = "XAUUSD"',
   'InpExpectedCurrency = "USD"',
   'InpPortfolioMagic = 26071781',
   'InpRunLabel = "operational_hardening_rc2_forward_frozen"',
   '9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302',
   '8B3A06E9776EA99C1DDE02A14F098B0837653B34B0AAD56491D0FE0248FEEC57',
   'OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL.csv',
   'bool AccountHistorySnapshot',
   'funding_adjustment_count',
   'foreign_trade_count',
   'history_available',
   'account_currency',
   'candidate_open_risk_percent'
)
foreach($marker in $required) {
   if($text -notmatch [regex]::Escape($marker)) { throw "Required sentinel marker missing: $marker" }
}

$forbiddenPatterns = @(
   '#include\s+<Trade',
   '\bCTrade\b',
   '\bOrderSend(?:Async)?\s*\(',
   '\.Buy\s*\(',
   '\.Sell\s*\(',
   '\bPositionClose\s*\(',
   '\bPositionModify\s*\(',
   '\bOrderDelete\s*\(',
   '\bOrderModify\s*\(',
   '\bTRADE_ACTION_(?:DEAL|PENDING|SLTP|MODIFY|REMOVE|CLOSE_BY)\b',
   '\bACCOUNT_LOGIN\b'
)
foreach($pattern in $forbiddenPatterns) {
   if($text -match $pattern) { throw "Forbidden trading or identifier pattern found: $pattern" }
}

if($text -notmatch 'void\s+OnTick\s*\(\s*\)\s*\{\s*\}') {
   throw "Sentinel OnTick is not empty."
}
if($text -notmatch 'FILE_COMMON' -or $text -notmatch 'EventSetTimer') {
   throw "Sentinel heartbeat transport or timer missing."
}

[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = $sourceHash
   BinarySha256 = $binaryHash
   CompileErrors = 0
   CompileWarnings = 0
   TradingPaths = 0
   AccountIdentifierFields = 0
}
