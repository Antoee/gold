param(
   [string]$PackageDirectory = "outputs\rdmc_diversified_repair_model1_package",
   [string]$ManifestPath = "outputs\RDMC_DIVERSIFIED_REPAIR_MODEL1_MANIFEST.csv",
   [string]$QueuePath = "outputs\RDMC_DIVERSIFIED_REPAIR_MODEL1_QUEUE.csv",
   [string]$PackageDocumentPath = "outputs\RDMC_DIVERSIFIED_REPAIR_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Repo-Path([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$package = Repo-Path $PackageDirectory
$source = Join-Path $package "source\Professional_XAUUSD_EA.mq5"
$profile = Join-Path $package "profiles\rdmc_diversified_repair_v1.set"
$manifestFile = Repo-Path $ManifestPath
$queueFile = Repo-Path $QueuePath
$document = Repo-Path $PackageDocumentPath
foreach($required in @($source, $profile, $manifestFile, $queueFile, $document)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required artifact missing: $required" }
}

$checks = 0
function Pass([string]$Message) {
   $script:checks++
   Write-Host "PASS: $Message"
}
function Require([bool]$Condition, [string]$Message) {
   if(!$Condition) { throw $Message }
   Pass $Message
}
function Require-Marker([string]$Text, [string]$Marker) {
   Require ($Text.Contains($Marker)) "source marker exists: $Marker"
}

$text = Get-Content -LiteralPath $source -Raw
$profileText = Get-Content -LiteralPath $profile -Raw
$documentBytes = [IO.File]::ReadAllBytes($document)
$documentText = [Text.Encoding]::ASCII.GetString($documentBytes)
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash
$manifestRows = @(Import-Csv -LiteralPath $manifestFile)
$queue = @(Import-Csv -LiteralPath $queueFile)

Require ($manifestRows.Count -eq 1) "manifest has one frozen identity row"
$manifest = $manifestRows[0]
Require ($manifest.SourceSha256 -eq $sourceHash) "manifest source hash matches package source"
Require ($manifest.ProfileSha256 -eq $profileHash) "manifest profile hash matches package profile"
Require ($manifest.Status -eq "STATIC_ONLY_LOCKED") "manifest remains static-only and locked"
Require ($manifest.PromotionStatus -eq "NOT_PROMOTED") "candidate is not promoted"
Require ($manifest.ForwardCandidateChanged -eq "NO") "forward candidate is unchanged"
Require ($manifest.StartingCapital -eq "10000" -and $manifest.Currency -eq "USD") "capital contract is 10,000 USD"
Require ($manifest.CompileStatus -eq "NOT_RUN_LOCAL_LOCK_ACTIVE") "compile status does not claim unrun evidence"
Require ($manifest.BacktestStatus -eq "NOT_RUN_LOCAL_LOCK_ACTIVE") "backtest status does not claim unrun evidence"

Require ($queue.Count -eq 12) "queue contains 12 annual/YTD Model1 windows"
Require (@($queue | Where-Object { $_.Status -ne "LOCKED_LOCAL_LAUNCH_DISABLED" }).Count -eq 0) "every queue row is locked"
Require (@($queue | Where-Object { $_.Deposit -ne "10000" -or $_.Model -ne "1" }).Count -eq 0) "every queue row uses Model1 and 10,000 deposit"
Require (@($queue | Where-Object { $_.SourceSha256 -ne $sourceHash -or $_.ProfileSha256 -ne $profileHash }).Count -eq 0) "queue identities match frozen source and profile"

$configFiles = @(Get-ChildItem -LiteralPath (Join-Path $package "configs") -Filter "*.ini" -File)
Require ($configFiles.Count -eq 12) "package contains exactly 12 configs"
foreach($config in $configFiles) {
   $configText = Get-Content -LiteralPath $config.FullName -Raw
   if($configText -notmatch '(?m)^Deposit=10000\r?$' -or
      $configText -notmatch '(?m)^Model=1\r?$' -or
      $configText -notmatch '(?m)^Visual=0\r?$' -or
      $configText -notmatch '(?m)^InpUseResearchTesterOnlyLock=true') {
      throw "Config contract failed: $($config.Name)"
   }
}
Pass "all configs are nonvisual, Model1, tester-only, and use 10,000 deposit"

$inputMatches = [regex]::Matches($text, '(?m)^input\s+\S+\s+(Inp[A-Za-z0-9_]+)\s*=')
$inputNames = @($inputMatches | ForEach-Object { $_.Groups[1].Value })
$profileInputNames = @([regex]::Matches($profileText, '(?m)^(Inp[A-Za-z0-9_]+)=') |
   ForEach-Object { $_.Groups[1].Value })
Require ($inputNames.Count -ge 550 -and $inputNames.Count -lt 1000) "source input count stays inside MT5 limit guard"
Require (($inputNames | Sort-Object -Unique).Count -eq $inputNames.Count) "source input names are unique"
Require (@($inputNames | Where-Object { $_.Length -gt 63 }).Count -eq 0) "source input identifiers fit MQL5 limits"
Require (($profileInputNames | Sort-Object -Unique).Count -eq $profileInputNames.Count) "profile input names are unique"
Require (@(Compare-Object ($inputNames | Sort-Object) ($profileInputNames | Sort-Object)).Count -eq 0) "profile explicitly freezes every source input"
Require (([regex]::Matches($text, '\{')).Count -eq ([regex]::Matches($text, '\}')).Count) "source braces are balanced"
Require (([regex]::Matches($text, '\(')).Count -eq ([regex]::Matches($text, '\)')).Count) "source parentheses are balanced"
Require (!$text.Contains('<<<<<<<') -and !$text.Contains('=======') -and !$text.Contains('>>>>>>>')) "source contains no merge-conflict markers"

foreach($marker in @(
   'bool IsResearchPortfolioMagic(const long magic)',
   'input bool            InpUseResearchTesterOnlyLock = true;',
   'input bool            InpUseInitialBalanceContract = true;',
   'bool ResearchCapitalContractAllows()',
   'class CMomentumLane',
   'riskManager.LotsForRisk(bias, entryPrice, stopDistance, riskMultiplier)',
   'riskManager.ExposureAllows(bias, entryPrice, stopDistance, lots, exposureReason)',
   'InpBandVWAPReversionUseD1MomentumCap',
   'double recentD1Close = iClose(_Symbol, PERIOD_D1, 1);',
   'double pastD1Close = iClose(_Symbol, PERIOD_D1, 1 + momentumLookback);',
   'riskMultiplier *= MathMax(0.0, InpPrimaryLaneRiskMultiplier);',
   'g_momentum.OnTick();',
   'g_momentum.OnTradeTransaction(trans);',
   'g_momentum.CloseAll(riskExitReason);',
   'g_momentum.CloseAll("weekend close");',
   'g_momentum.CloseAll("manual news filter");',
   'if(!RealAccountSafetyLockAllows())'
)) { Require-Marker $text $marker }

$periodProfitStart = $text.IndexOf('double PeriodProfit(const ENUM_TIMEFRAMES period)')
$periodProfitEnd = $text.IndexOf('bool LossLimitHit(', $periodProfitStart)
Require ($periodProfitStart -ge 0 -and $periodProfitEnd -gt $periodProfitStart) "shared period-profit block is locatable"
$periodProfitBlock = $text.Substring($periodProfitStart, $periodProfitEnd - $periodProfitStart)
Require ($periodProfitBlock.Contains('IsResearchPortfolioMagic')) "shared loss limits account for both portfolio magics"

$positionManagerStart = $text.IndexOf('class CPositionManager')
$momentumClassStart = $text.IndexOf('class CMomentumLane')
$manageStart = $text.IndexOf('void Manage(const ENUM_TRADE_BIAS currentSignalBias)', $positionManagerStart)
$managerEnd = $text.IndexOf('class CStatistics', $manageStart)
Require ($positionManagerStart -ge 0 -and $manageStart -gt $positionManagerStart -and $managerEnd -gt $manageStart) "primary position manager block is locatable"
$managerBlock = $text.Substring($manageStart, $managerEnd - $manageStart)
Require (!$managerBlock.Contains('IsResearchPortfolioMagic')) "primary manager cannot manage the momentum magic"
Require ($momentumClassStart -gt $managerEnd) "momentum lane is independently owned"

function Profile-Value([string]$Key) {
   $match = [regex]::Match($profileText, "(?m)^$([regex]::Escape($Key))=([^|\r\n]*)")
   if(!$match.Success) { throw "Profile key missing: $Key" }
   return $match.Groups[1].Value
}
$expectedProfile = [ordered]@{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseInitialBalanceContract = 'true'
   InpExpectedInitialBalance = '10000.0'
   InpRequiredAccountCurrency = 'USD'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
   InpRiskPercent = '0.50'
   InpPrimaryLaneRiskMultiplier = '0.20'
   InpBandVWAPReversionRiskMultiplier = '0.90'
   InpBandVWAPReversionUseDIEdgeGate = 'true'
   InpBandVWAPReversionMinDIEdge = '-12.0'
   InpBandVWAPReversionUseD1MomentumCap = 'true'
   InpBandVWAPReversionD1MomentumLookbackBars = '126'
   InpBandVWAPReversionMaxAbsoluteD1MomentumPercent = '12.0'
   InpDailyDonchianRiskMultiplier = '0.45'
   InpMOEnabled = 'true'
   InpMORiskPercent = '0.15'
   InpMOEntryLookbackBars = '20'
   InpMOMomentumLookbackBars = '126'
   InpAccountWideMaxOpenRiskPercent = '0.75'
   InpAccountWideMaxPositions = '1'
   InpMaxEquityDrawdownPercent = '5.00'
   InpAllowMinLotRiskOverflow = 'false'
   InpEvidenceSourceHash = $sourceHash
}
foreach($key in $expectedProfile.Keys) {
   Require ((Profile-Value $key) -eq $expectedProfile[$key]) "profile contract: $key=$($expectedProfile[$key])"
}
Require ((Profile-Value 'InpMagicNumber') -ne (Profile-Value 'InpMOMagicNumber')) "lane magic numbers are distinct"

Require (!($documentBytes -contains 0)) "package document contains no null bytes"
Require (!$documentText.Contains('$sourceHash') -and !$documentText.Contains('$profileHash')) "package document contains no unresolved hash placeholders"
Require ($documentText.Contains($sourceHash) -and $documentText.Contains($profileHash)) "package document records frozen identities"
Require ($documentText.Contains('It does not establish a new best.')) "package document makes no new-best claim"

[pscustomobject]@{
   Status = "PASS"
   Checks = $checks
   Inputs = $inputNames.Count
   SourceSha256 = $sourceHash
   ProfileSha256 = $profileHash
   QueueRows = $queue.Count
   CompileStatus = $manifest.CompileStatus
   PromotionStatus = $manifest.PromotionStatus
}
