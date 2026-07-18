Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$checks = [Collections.Generic.List[object]]::new()

function Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{Check=$Name;Pass=$Pass;Evidence=$Evidence}) | Out-Null
   if(!$Pass) { throw "$Name failed: $Evidence" }
}

$sourcePath = Join-Path $repo "work\Professional_XAUUSD_Reversion_D1_Momentum_Cap_Signal_Range_Gate.mq5"
$profilePath = Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_CENTER_PROFILE.set"
$contractPath = Join-Path $repo "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_CONTRACT.md"
$compileEvidencePath = Join-Path $repo "outputs\RDMC_SIGNAL_RANGE_GATE_COMPILE_EVIDENCE.csv"
$queuePath = Join-Path $repo "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_QUEUE.csv"
$manifestPath = Join-Path $repo "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_MANIFEST.csv"
$selectionPath = Join-Path $repo "outputs\RDMC_SIGNAL_RANGE_GATE_SELECTION.csv"
$joinedPath = Join-Path $repo "outputs\RDMC_CAP12_MODEL4_2015_2018_MOMENTUM_FEATURES.csv"
$package = Join-Path $repo "outputs\rdmc_signal_range_gate_repair_model1_package"

$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
$contractHash = (Get-FileHash -LiteralPath $contractPath -Algorithm SHA256).Hash
Check "source identity" ($sourceHash -eq "32DE39C13DBE06A6AE2BD733ED2183D7103C003884F08DD13024FDEE18BAD241") $sourceHash
Check "parent profile identity" ($profileHash -eq "BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC") $profileHash
Check "contract identity" ($contractHash -eq "F8864C26088E63494D16E0606DE04C66BB46E99FFC798FE0D40C83AA20AA643C") $contractHash

$source = Get-Content -LiteralPath $sourcePath -Raw
Check "real-account lock default" ($source -match 'InpUseRealAccountSafetyLock\s*=\s*true' -and $source -match 'InpAllowRealAccountTrading\s*=\s*false') "locked and disabled"
Check "range gate inputs" ($source -match 'InpMOUseMinimumSignalRangeGate\s*=\s*false' -and $source -match 'InpMOMinimumSignalRangeATR\s*=\s*1\.25') "optional 1.25 ATR default"
Check "completed signal bar" ($source -match 'iHigh\(_Symbol, InpMOSignalTimeframe, 1\)' -and $source -match 'iLow\(_Symbol, InpMOSignalTimeframe, 1\)') "shift 1 only"
Check "gate is entry-only" ($source -match 'signalRange < InpMOMinimumSignalRangeATR \* atr') "returns before breakout entry"
Check "range validation" ($source -match 'InpMOMinimumSignalRangeATR > 10\.0') "bounded parameter"
$compileEvidence = Import-Csv -LiteralPath $compileEvidencePath | Select-Object -First 1
Check "clean compile" ($compileEvidence.CompileResult -eq '0 errors, 0 warnings' -and $compileEvidence.InstalledFrozenArtifactsUnchanged -eq 'True') "isolated compile"

& (Join-Path $repo "work\analyze_rdmc_momentum_signal_range_selection.ps1") | Out-Null
Check "joined ledger identity" ((Get-FileHash -LiteralPath $joinedPath -Algorithm SHA256).Hash -eq "2BA7856B36D144B57334037A2B1B2BD389E94495413549B6388465A52179B087") "135 exact matches"
$selection = @(Import-Csv -LiteralPath $selectionPath)
Check "four frozen selection profiles" ($selection.Count -eq 4) "rows=$($selection.Count)"
Check "all selection years positive" (@($selection | Where-Object { [int]$_.PositiveSelectionYears -ne 4 }).Count -eq 0) "2015-2018"
$centerSelection = $selection | Where-Object Candidate -eq "srg_min125_center" | Select-Object -First 1
Check "center selection frozen" ($centerSelection.MinimumSignalRangeATR -eq "1.25" -and [int]$centerSelection.Trades -eq 80) "1.25 ATR, 80 trades"

$queue = @(Import-Csv -LiteralPath $queuePath)
$manifest = @(Import-Csv -LiteralPath $manifestPath)
Check "eight early-gate configs" ($queue.Count -eq 8 -and $manifest.Count -eq 8) "queue=$($queue.Count), manifest=$($manifest.Count)"
Check "failure years only" (@($queue.Window | Sort-Object -Unique) -join ',' -eq 'year_2019,year_2022') "no broad data opened"
Check "four profile family" (@($queue.Candidate | Sort-Object -Unique).Count -eq 4) "control, center, two neighbors"
Check "exact source in queue" (@($queue | Where-Object SourceSha256 -ne $sourceHash).Count -eq 0) $sourceHash
Check "exact contract in queue" (@($queue | Where-Object ContractSha256 -ne $contractHash).Count -eq 0) $contractHash
$profileMismatches = foreach($row in ($queue | Sort-Object Candidate -Unique)) {
   $candidateProfile = Join-Path $package $row.ProfileSnapshot
   if((Get-FileHash -LiteralPath $candidateProfile -Algorithm SHA256).Hash -ne $row.ProfileSha256) {
      $row.Candidate
   }
}
Check "profile byte identities" (@($profileMismatches).Count -eq 0) "four exact profile hashes"
Check "no real trading profile" (@(Get-ChildItem -LiteralPath (Join-Path $package 'profiles') -Filter '*.set' | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match 'InpAllowRealAccountTrading=true' }).Count -eq 0) "all profiles disabled"
Check "configs present" (@($manifest | Where-Object { !(Test-Path -LiteralPath (Join-Path $repo $_.PackageConfig)) }).Count -eq 0) "8 / 8"
Check "no generated reports" (@(Get-ChildItem -LiteralPath (Join-Path $package 'reports_here') -File -ErrorAction SilentlyContinue).Count -eq 0) "early gate unopened"

$checks | Format-Table -AutoSize
"PASS: $($checks.Count) RDMC signal-range repair checks"
