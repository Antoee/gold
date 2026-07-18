Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$builder = Join-Path $repo 'work\build_rdmc_diversified_repair_offline_components.ps1'
$analyzer = Join-Path $repo 'work\analyze_rdmc_diversified_repair_offline_prescreen.py'
$summaryPath = Join-Path $repo 'outputs\RDMC_DIVERSIFIED_REPAIR_OFFLINE_SUMMARY.csv'
$tradesPath = Join-Path $repo 'outputs\RDMC_DIVERSIFIED_REPAIR_OFFLINE_TRADES.csv'
$markdownPath = Join-Path $repo 'outputs\RDMC_DIVERSIFIED_REPAIR_OFFLINE_PRESCREEN.md'
$r20Source = Join-Path $repo 'outputs\peak_r20_regime_combo_model4_yearly_package\source\Professional_XAUUSD_EA.mq5'
$checks = [Collections.Generic.List[object]]::new()

function Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{Check=$Name;Pass=$Pass;Evidence=$Evidence}) | Out-Null
   if(!$Pass) { throw "$Name failed: $Evidence" }
}

$built = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $builder 2>&1
if($LASTEXITCODE -ne 0) { throw "Component builder failed: $built" }
Check 'exact component extraction' (($built | Out-String) -match 'R20Trades\s+: 22' -and ($built | Out-String) -match 'DDBTrades\s+: 3') '22 R20 plus 3 DDB trades'

$run = & python $analyzer 2>&1
if($LASTEXITCODE -ne 0) { throw "Offline diversified screen failed: $run" }
Check 'architecture gate passes only post-hoc' (($run | Out-String) -match 'POSTHOC_ARCHITECTURE_GATE_PASS_NOT_A_NEW_BEST') ($run | Out-String).Trim()

$summary = @(Import-Csv -LiteralPath $summaryPath)
$trades = @(Import-Csv -LiteralPath $tradesPath)
Check 'twelve annual summaries' ($summary.Count -eq 12) "rows=$($summary.Count)"
Check 'exact component trade count' ($trades.Count -eq 376) "rows=$($trades.Count)"
Check 'all projected years positive' (@($summary | Where-Object PositiveYear -ne 'True').Count -eq 0) '12 / 12'

$year2019 = $summary | Where-Object TestWindow -eq '2019' | Select-Object -First 1
$year2022 = $summary | Where-Object TestWindow -eq '2022' | Select-Object -First 1
Check '2019 margin restored' ($year2019.PostHocNetProfit -eq '45.41' -and $year2019.PostHocProfitFactor -eq '1.2671' -and $year2019.PostHocTrades -eq '34') 'net=45.41 pf=1.2671 trades=34'
Check '2022 margin restored' ($year2022.PostHocNetProfit -eq '53.53' -and $year2022.PostHocProfitFactor -eq '1.1824' -and $year2022.PostHocTrades -eq '44') 'net=53.53 pf=1.1824 trades=44'

$net = [math]::Round([double](($trades | Measure-Object -Property Profit -Sum).Sum),2)
$grossProfit = [double](($trades | Where-Object {[double]$_.Profit -gt 0} | Measure-Object -Property Profit -Sum).Sum)
$grossLoss = [math]::Abs([double](($trades | Where-Object {[double]$_.Profit -lt 0} | Measure-Object -Property Profit -Sum).Sum))
$pf = [math]::Round($grossProfit / $grossLoss,4)
Check 'aggregate values frozen' ($net -eq 2217.13 -and $pf -eq 1.9330) "net=$net pf=$pf"

Check 'exact R20 source packaged' ((Get-FileHash -LiteralPath $r20Source -Algorithm SHA256).Hash -eq '2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D') 'report source identity restored'
$markdown = Get-Content -LiteralPath $markdownPath -Raw
Check 'capital and path caveats retained' ($markdown -match '\$1,000.*\$10,000' -and $markdown -match 'Filtering RC2 reversion trades can expose later entries' -and $markdown -match 'Simultaneous positions') 'not an executable equity curve'
Check 'forward boundary retained' ($markdown -match 'registered forward candidate' -and $markdown -match 'invalid `\$100,000` demo still contributes zero evidence' -and $markdown -match 'real-money trading remains locked') 'no substitution'

$checks | Format-Table -AutoSize
"PASS: $($checks.Count) RDMC diversified repair offline checks"
