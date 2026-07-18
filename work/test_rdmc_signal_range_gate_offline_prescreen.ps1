Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$analyzer = Join-Path $repo 'work\analyze_rdmc_signal_range_gate_offline_prescreen.py'
$summaryPath = Join-Path $repo 'outputs\RDMC_SIGNAL_RANGE_GATE_OFFLINE_PRESCREEN_SUMMARY.csv'
$tradesPath = Join-Path $repo 'outputs\RDMC_SIGNAL_RANGE_GATE_OFFLINE_PRESCREEN_TRADES.csv'
$markdownPath = Join-Path $repo 'outputs\RDMC_SIGNAL_RANGE_GATE_OFFLINE_PRESCREEN.md'
$checks = [Collections.Generic.List[object]]::new()

function Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{Check=$Name;Pass=$Pass;Evidence=$Evidence}) | Out-Null
   if(!$Pass) { throw "$Name failed: $Evidence" }
}

$run = & python $analyzer 2>&1
if($LASTEXITCODE -ne 0) { throw "Offline pre-screen failed: $run" }
Check 'diagnostic rejects family' (($run | Out-String) -match 'POSTHOC_REJECT_ALL_FROZEN_THRESHOLDS') ($run | Out-String).Trim()

$summary = @(Import-Csv -LiteralPath $summaryPath)
$trades = @(Import-Csv -LiteralPath $tradesPath)
Check 'eight profile-year summaries' ($summary.Count -eq 8) "rows=$($summary.Count)"
Check 'all 66 failure-year momentum trades mapped' ($trades.Count -eq 66) "rows=$($trades.Count)"
Check 'all frozen thresholds fail' (@($summary | Where-Object { $_.Candidate -ne 'srg_control' -and $_.PostHocProfileGate -ne 'False' }).Count -eq 0) 'no post-hoc pass'

$expected = @{
   'srg_min100|2019'=@('-47.01','24');'srg_min100|2022'=@('-86.36','22')
   'srg_min125_center|2019'=@('-16.36','19');'srg_min125_center|2022'=@('-76.42','14')
   'srg_min150|2019'=@('-14.88','11');'srg_min150|2022'=@('-53.31','10')
}
$mismatches = foreach($key in $expected.Keys) {
   $candidate,$year = $key -split '\|'
   $row = $summary | Where-Object { $_.Candidate -eq $candidate -and $_.Year -eq $year } | Select-Object -First 1
   if($null -eq $row -or $row.PostHocNetProfit -ne $expected[$key][0] -or $row.PostHocTrades -ne $expected[$key][1]) { $key }
}
Check 'exact projected nets and activity' (@($mismatches).Count -eq 0) 'six threshold-year rows match'

$markdown = Get-Content -LiteralPath $markdownPath -Raw
Check 'path-dependence caveat retained' ($markdown -match 'Removing a trade can expose later signals' -and $markdown -match 'only the preregistered eight Model1 reports') 'diagnostic is not promoted'
Check 'forward and real-money state retained' ($markdown -match 'registered forward candidate is unchanged' -and $markdown -match 'real-money trading remains locked') 'no substitution'

$checks | Format-Table -AutoSize
"PASS: $($checks.Count) RDMC offline signal-range pre-screen checks"
