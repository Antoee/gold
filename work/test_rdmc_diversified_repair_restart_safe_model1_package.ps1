Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$package = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package"
$sourcePath = Join-Path $package "source\Professional_XAUUSD_EA.mq5"
$profilePath = Join-Path $package "profiles\rdmc_diversified_repair_restart_safe_v2.set"
$v1SourcePath = Join-Path $repo "outputs\rdmc_diversified_repair_model1_package\source\Professional_XAUUSD_EA.mq5"
$queuePath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_QUEUE.csv"
$manifestPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_MANIFEST.csv"
$documentPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_PACKAGE.md"

$expectedSourceHash = "10DF970C59843F88A9A2DF16DBF5EF6C067F818680DFAE380717781DFEBC6517"
$expectedProfileHash = "C46152D20D32B3C55E8E0B53A599E70DFF9C58138553676FF878750E24CF1922"
$expectedV1SourceHash = "4740338598E290360946FE414CC6F2FE0CF3B704006860514367DCB996A8D2B5"

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

function Invoke-CapitalContractModel {
   param(
      [bool]$Tester = $false,
      [double]$Balance = 10000.0,
      [double]$Equity = 10000.0,
      [double]$Expected = 10000.0,
      [double]$TolerancePercent = 1.0,
      [int]$FundingCount = 1,
      [int]$TradeDealCount = 0,
      [int]$ForeignTradeCount = 0,
      [int]$OpenPositionCount = 0,
      [int]$ForeignOpenPositionCount = 0,
      [bool]$StoredBalanceExists = $false,
      [double]$StoredBalance = 0.0,
      [bool]$StoredFundingExists = $false,
      [int]$StoredFundingCount = 0,
      [bool]$StoredPeakExists = $false,
      [double]$StoredPeak = 0.0
   )
   $tolerance = $Expected * [Math]::Max(0.0, $TolerancePercent) / 100.0
   if($Tester) {
      if($Expected -le 0.0 -or [Math]::Abs($Balance - $Expected) -gt $tolerance) { return "starting-capital contract" }
      return "allowed"
   }
   if($ForeignTradeCount -gt 0 -or $ForeignOpenPositionCount -gt 0) { return "dedicated-account contract" }
   if($StoredBalanceExists) {
      if([Math]::Abs($StoredBalance - $Expected) -gt 0.01) { return "stored starting-capital contract" }
   }
   else {
      if($Expected -le 0.0 -or [Math]::Abs($Balance - $Expected) -gt $tolerance) { return "starting-capital contract" }
      if($TradeDealCount -gt 0 -or $OpenPositionCount -gt 0) { return "unused flat account contract" }
   }
   if($StoredFundingExists) {
      if($StoredFundingCount -ne $FundingCount) { return "funding changed" }
   }
   elseif($StoredBalanceExists) { return "funding persistence missing" }
   if($StoredPeakExists) {
      if($StoredPeak -le 0.0 -or $StoredPeak + $tolerance -lt $Expected) { return "stored peak invalid" }
   }
   elseif($StoredBalanceExists) { return "peak persistence missing" }
   elseif($Equity -le 0.0 -or [Math]::Abs($Equity - $Balance) -gt 0.01) { return "peak registration" }
   return "allowed"
}

foreach($required in @($sourcePath, $profilePath, $v1SourcePath, $queuePath, $manifestPath, $documentPath)) {
   Add-Check "required artifact: $([IO.Path]::GetFileName($required))" (Test-Path -LiteralPath $required -PathType Leaf) $required
}
if($checks.Where({ !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Required restart-safe package artifacts are missing."
}

$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
$v1Hash = (Get-FileHash -LiteralPath $v1SourcePath -Algorithm SHA256).Hash
Add-Check "v2 source hash frozen" ($sourceHash -eq $expectedSourceHash) $sourceHash
Add-Check "v2 profile hash frozen" ($profileHash -eq $expectedProfileHash) $profileHash
Add-Check "v1 predecessor unchanged" ($v1Hash -eq $expectedV1SourceHash) $v1Hash

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Get-Content -LiteralPath $profilePath
$sourceInputs = @([regex]::Matches($source, '(?m)^input\s+\S+\s+(Inp[A-Za-z0-9_]+)\s*=') |
   ForEach-Object { $_.Groups[1].Value })
$profileValues = @{}
foreach($line in $profile) {
   if($line -match '^([^;=]+)=([^|]*)(.*)$') { $profileValues[$matches[1]] = $matches[2] }
}
$missing = @($sourceInputs | Where-Object { !$profileValues.ContainsKey($_) })
$extra = @($profileValues.Keys | Where-Object { $_ -notin $sourceInputs })
Add-Check "588 source inputs remain below MT5 limit" ($sourceInputs.Count -eq 588) "source=$($sourceInputs.Count)"
Add-Check "profile freezes every source input" ($profileValues.Count -eq 588 -and $missing.Count -eq 0 -and $extra.Count -eq 0) "profile=$($profileValues.Count) missing=$($missing.Count) extra=$($extra.Count)"
Add-Check "source inputs are unique" (@($sourceInputs | Group-Object | Where-Object Count -gt 1).Count -eq 0) "inputs=$($sourceInputs.Count)"

foreach($contract in @{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseInitialBalanceContract = 'true'
   InpExpectedInitialBalance = '10000.0'
   InpUseAccountCurrencyLock = 'true'
   InpRequiredAccountCurrency = 'USD'
   InpUseDedicatedAccountContract = 'true'
   InpRejectFundingChangesAfterRegistration = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
   InpUseAccountWideExposureGuard = 'true'
   InpAccountWideMaxOpenRiskPercent = '0.75'
   InpAccountWideMaxPositions = '1'
   InpMaxEquityDrawdownPercent = '5.00'
}.GetEnumerator()) {
   Add-Check "profile contract: $($contract.Key)" ($profileValues[$contract.Key] -eq $contract.Value) "$($profileValues[$contract.Key])"
}
Add-Check "profile identity is v2" ($profileValues.InpEvidenceProfileId -eq 'rdmc_diversified_repair_restart_safe_v2') $profileValues.InpEvidenceProfileId
Add-Check "profile source identity matches" ($profileValues.InpEvidenceSourceHash -eq $sourceHash) $profileValues.InpEvidenceSourceHash
Add-Check "v2 magic identities are distinct" ($profileValues.InpMagicNumber -eq '26071831' -and $profileValues.InpMOMagicNumber -eq '26071762') "primary=$($profileValues.InpMagicNumber) momentum=$($profileValues.InpMOMagicNumber)"

$fundingSection = Get-Section $source "bool IsFundingMutationDealType" "bool AccountHistoryContractSnapshot"
Add-Check "funding mutation types are explicit" (@('DEAL_TYPE_BALANCE','DEAL_TYPE_CREDIT','DEAL_TYPE_CORRECTION','DEAL_TYPE_BONUS').Where({ $fundingSection.Contains($_) }).Count -eq 4) "deposit/credit/correction/bonus"
Add-Check "broker costs are not classified as funding" (@('DEAL_TYPE_COMMISSION','DEAL_TYPE_CHARGE','DEAL_TYPE_INTEREST').Where({ $fundingSection.Contains($_) }).Count -eq 0) "commission/charge/interest excluded"

$capitalSection = Get-Section $source "bool ResearchCapitalContractAllows()" "bool RealAccountSafetyLockAllows()"
foreach($marker in @('AccountHistoryContractSnapshot','ForeignOpenPositionCount','GlobalVariableCheck(balanceKey)','FundingCountContractKey()','PeakEquityContractKey()','tradeDealCount > 0 || PositionsTotal() > 0','balanceContractExists','peak-equity persistence is missing')) {
   Add-Check "capital contract marker: $marker" $capitalSection.Contains($marker) $marker
}

$riskSection = Get-Section $source "class CRiskManager" "class CPositionManager"
Add-Check "risk manager restores original capital baseline" ($riskSection.Contains('m_initialEquity = InpExpectedInitialBalance;') -and $riskSection.Contains('m_initialBalance = InpExpectedInitialBalance;')) "expected initial balance used"
Add-Check "risk manager restores persisted lifetime peak" ($riskSection.Contains('GlobalVariableGet(PeakEquityContractKey())') -and $riskSection.Contains('UpdatePeakEquity(equity);')) "peak loaded and updated"
Add-Check "peak persistence failure closes entry path" ($source.Contains('g_peakEquityPersistenceHealthy = false;') -and $source.Contains('Failed to initialize persistent peak-equity protection.')) "fail closed"
$drawdownSection = Get-Section $source "double CurrentEquityDrawdownPercent()" "void RefreshConsecutiveLosses()"
Add-Check "peak write failure blocks the same risk check" ($drawdownSection.Contains('if(!g_peakEquityPersistenceHealthy)') -and $drawdownSection.Contains('return DBL_MAX;')) "blocking drawdown sentinel"

$environmentSection = Get-Section $source "bool TradeEnvironmentAllows(string &reason)" "bool TradeReadinessSafetyGateAllows()"
$runtimeIndex = $environmentSection.IndexOf('RuntimeAccountHistoryContractAllows(reason)', [StringComparison]::Ordinal)
$guardIndex = $environmentSection.IndexOf('if(!InpUseTradeEnvironmentGuard)', [StringComparison]::Ordinal)
Add-Check "runtime account contract precedes optional environment guard" ($runtimeIndex -ge 0 -and $guardIndex -gt $runtimeIndex) "runtime=$runtimeIndex guard=$guardIndex"
$readinessSection = Get-Section $source "bool TradeReadinessSafetyGateAllows()" "bool SymbolSafetyLockAllows()"
$readinessMarkers = @('starting-capital contract disabled or invalid','account currency contract disabled or invalid','dedicated-account contract disabled','funding-drift contract disabled','account-wide exposure guard disabled','account-wide open risk cap missing or too high','account-wide position cap missing or too high','account-wide unprotected exposure block disabled')
Add-Check "trade-readiness gate requires persistent account-wide safety" (@($readinessMarkers | Where-Object { !$readinessSection.Contains($_) }).Count -eq 0) "markers=$($readinessMarkers.Count)"

$onTickIndex = $source.LastIndexOf('void OnTick()', [StringComparison]::Ordinal)
$onTradeIndex = $source.LastIndexOf('void OnTradeTransaction', [StringComparison]::Ordinal)
$onTick = if($onTickIndex -ge 0 -and $onTradeIndex -gt $onTickIndex) { $source.Substring($onTickIndex, $onTradeIndex - $onTickIndex) } else { '' }
$dirtyIndex = $onTick.IndexOf('g_accountHistoryStateDirty = true;', [StringComparison]::Ordinal)
$momentumIndex = $onTick.IndexOf('g_momentum.OnTick();', [StringComparison]::Ordinal)
Add-Check "history refresh precedes momentum entry evaluation" ($dirtyIndex -ge 0 -and $momentumIndex -gt $dirtyIndex) "dirty=$dirtyIndex momentum=$momentumIndex"

$scenarios = @(
   @{ Name='tester exact capital'; Expected='allowed'; Args=@{ Tester=$true; Balance=10000.0 } },
   @{ Name='tester capital mismatch'; Expected='starting-capital contract'; Args=@{ Tester=$true; Balance=100000.0 } },
   @{ Name='fresh live registration'; Expected='allowed'; Args=@{} },
   @{ Name='fresh live mismatch'; Expected='starting-capital contract'; Args=@{ Balance=100000.0; Equity=100000.0 } },
   @{ Name='restart after profit'; Expected='allowed'; Args=@{ Balance=12100.0; Equity=12050.0; StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1; StoredPeakExists=$true; StoredPeak=12500.0 } },
   @{ Name='restart after loss'; Expected='allowed'; Args=@{ Balance=9400.0; Equity=9350.0; StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1; StoredPeakExists=$true; StoredPeak=10200.0 } },
   @{ Name='funding change'; Expected='funding changed'; Args=@{ FundingCount=2; StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1; StoredPeakExists=$true; StoredPeak=10000.0 } },
   @{ Name='foreign closed trade'; Expected='dedicated-account contract'; Args=@{ ForeignTradeCount=1 } },
   @{ Name='foreign open position'; Expected='dedicated-account contract'; Args=@{ ForeignOpenPositionCount=1; OpenPositionCount=1 } },
   @{ Name='missing funding persistence'; Expected='funding persistence missing'; Args=@{ StoredBalanceExists=$true; StoredBalance=10000.0; StoredPeakExists=$true; StoredPeak=10000.0 } },
   @{ Name='missing peak persistence'; Expected='peak persistence missing'; Args=@{ StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1 } },
   @{ Name='invalid stored peak'; Expected='stored peak invalid'; Args=@{ StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1; StoredPeakExists=$true; StoredPeak=9000.0 } },
   @{ Name='used account registration'; Expected='unused flat account contract'; Args=@{ TradeDealCount=2 } },
   @{ Name='non-flat registration'; Expected='unused flat account contract'; Args=@{ OpenPositionCount=1 } }
)
foreach($scenario in $scenarios) {
   $modelArgs = $scenario.Args
   $actual = Invoke-CapitalContractModel @modelArgs
   Add-Check "state model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual expected=$($scenario.Expected)"
}

$queue = @(Import-Csv -LiteralPath $queuePath)
$manifest = @(Import-Csv -LiteralPath $manifestPath)
$configs = @(Get-ChildItem -LiteralPath (Join-Path $package 'configs') -Filter '*.ini' -File)
$reports = @(Get-ChildItem -LiteralPath (Join-Path $package 'reports') -File -ErrorAction SilentlyContinue)
$configContractPass = $true
$configProfilePass = $true
foreach($config in $configs) {
   $configLines = @(Get-Content -LiteralPath $config.FullName)
   foreach($marker in @('Optimization=0','Model=1','Deposit=10000','Currency=USD','Visual=0','ShutdownTerminal=1')) {
      if($configLines -notcontains $marker) { $configContractPass = $false }
   }
   $inputsIndex = [Array]::IndexOf($configLines, '[TesterInputs]')
   if($inputsIndex -lt 0) {
      $configProfilePass = $false
   }
   else {
      $embeddedProfile = @($configLines[($inputsIndex + 1)..($configLines.Count - 1)])
      if([string]::Join("`n", $embeddedProfile) -cne [string]::Join("`n", $profile)) {
         $configProfilePass = $false
      }
   }
}
Add-Check "queue contains 12 locked annual/YTD rows" ($queue.Count -eq 12 -and @($queue | Where-Object Status -ne 'LOCKED_LOCAL_LAUNCH_DISABLED').Count -eq 0) "rows=$($queue.Count)"
Add-Check "queue identity and capital are frozen" (@($queue | Where-Object { $_.SourceSha256 -ne $sourceHash -or $_.ProfileSha256 -ne $profileHash -or $_.Deposit -ne '10000' -or $_.Model -ne '1' }).Count -eq 0) "rows=$($queue.Count)"
Add-Check "package contains 12 nonvisual configs" ($configs.Count -eq 12 -and @($configs | Where-Object { (Get-Content -Raw $_.FullName) -notmatch '(?m)^Visual=0\r?$' }).Count -eq 0) "configs=$($configs.Count)"
Add-Check "every config freezes the tester contract" $configContractPass "configs=$($configs.Count)"
Add-Check "every config embeds the exact profile" $configProfilePass "profile_lines=$($profile.Count)"
Add-Check "locked package contains no MT5 reports" ($reports.Count -eq 0) "reports=$($reports.Count)"
Add-Check "manifest remains static and unpromoted" ($manifest.Count -eq 1 -and $manifest[0].Status -eq 'STATIC_ONLY_LOCKED' -and $manifest[0].PromotionStatus -eq 'NOT_PROMOTED' -and $manifest[0].HistoricalBestChanged -eq 'NO') "rows=$($manifest.Count)"

$document = Get-Content -LiteralPath $documentPath -Raw
Add-Check "package states restart repair boundary" ($document.Contains('supersedes the uncompiled v1 package') -and $document.Contains('does not establish a new best') -and $document.Contains('Static checks cannot prove compilation')) "boundary present"
Add-Check "registered forward candidate stays unchanged" ($document.Contains('does not') -and $manifest[0].ForwardCandidateChanged -eq 'NO') $manifest[0].ForwardCandidateChanged
Add-Check "no account identifier published" ($document -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $document -notmatch '(?i)login\s*[:=]\s*\d{5,}') "public markdown clean"
Add-Check "no GitHub token published" ($document -notmatch 'github_pat_|gh[pousr]_[A-Za-z0-9]{20,}') "public markdown clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) restart-safe package checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC restart-safe package checks"
