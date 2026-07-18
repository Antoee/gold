param(
   [string]$AnalyzerPath = "work\analyze_rdmc_diversified_repair_collision_prescreen.py",
   [string]$TradesPath = "outputs\RDMC_DIVERSIFIED_REPAIR_COLLISION_TRADES.csv",
   [string]$SummaryPath = "outputs\RDMC_DIVERSIFIED_REPAIR_COLLISION_SUMMARY.csv",
   [string]$PriorityPath = "outputs\RDMC_DIVERSIFIED_REPAIR_COLLISION_PRIORITY_STRESS.csv",
   [string]$MarkdownPath = "outputs\RDMC_DIVERSIFIED_REPAIR_COLLISION_PRESCREEN.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Repo-Path([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$analyzer = Repo-Path $AnalyzerPath
$tradesFile = Repo-Path $TradesPath
$summaryFile = Repo-Path $SummaryPath
$priorityFile = Repo-Path $PriorityPath
$markdownFile = Repo-Path $MarkdownPath
if(!(Test-Path -LiteralPath $analyzer -PathType Leaf)) { throw "Analyzer missing: $analyzer" }

$runOutput = & python $analyzer
if($LASTEXITCODE -ne 0) { throw "Collision analyzer failed with exit code $LASTEXITCODE" }
if($runOutput -notmatch '^POSTHOC_COLLISION_GATE_PASS_NOT_A_NEW_BEST net=2067\.64 pf=1\.8942 accepted=368 blocked=8 positive_windows=12 min_window=40\.53$') {
   throw "Unexpected analyzer result: $runOutput"
}

foreach($required in @($tradesFile, $summaryFile, $priorityFile, $markdownFile)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Output missing: $required" }
}

$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{ Check = $Name; Pass = $Pass; Evidence = $Evidence })
}

$trades = @(Import-Csv -LiteralPath $tradesFile)
$summary = @(Import-Csv -LiteralPath $summaryFile)
$priority = @(Import-Csv -LiteralPath $priorityFile)
$markdown = Get-Content -LiteralPath $markdownFile -Raw
$accepted = @($trades | Where-Object Decision -eq "ACCEPT")
$blocked = @($trades | Where-Object Decision -eq "BLOCK_OVERLAP")

Add-Check "exact component trade count" ($trades.Count -eq 376) "rows=$($trades.Count)"
Add-Check "single-position decisions complete" ($accepted.Count -eq 368 -and $blocked.Count -eq 8) "accepted=$($accepted.Count) blocked=$($blocked.Count)"

$acceptedNet = [math]::Round(($accepted | Measure-Object -Property Profit -Sum).Sum, 2)
$blockedNet = [math]::Round(($blocked | Measure-Object -Property Profit -Sum).Sum, 2)
Add-Check "collision-adjusted net frozen" ($acceptedNet -eq 2067.64 -and $blockedNet -eq 149.49) "accepted=$acceptedNet blocked_opportunity=$blockedNet"

$grossProfit = ($accepted | Where-Object { [double]$_.Profit -gt 0 } | Measure-Object -Property Profit -Sum).Sum
$grossLoss = -($accepted | Where-Object { [double]$_.Profit -lt 0 } | Measure-Object -Property Profit -Sum).Sum
$pf = [math]::Round($grossProfit / $grossLoss, 4)
Add-Check "collision-adjusted PF frozen" ($pf -eq 1.8942) "pf=$pf"

Add-Check "twelve positive summaries" ($summary.Count -eq 12 -and @($summary | Where-Object PositiveWindow -ne "True").Count -eq 0) "rows=$($summary.Count) positive=$(@($summary | Where-Object PositiveWindow -eq 'True').Count)"
$year2019 = $summary | Where-Object TestWindow -eq "2019"
$year2022 = $summary | Where-Object TestWindow -eq "2022"
Add-Check "failure years stay positive" ([double]$year2019.CollisionAdjustedNet -eq 40.53 -and [double]$year2022.CollisionAdjustedNet -eq 53.53) "2019=$($year2019.CollisionAdjustedNet) 2022=$($year2022.CollisionAdjustedNet)"

$eras = @(
   [pscustomobject]@{ Name = "older"; Windows = @("2015", "2016", "2017", "2018"); Expected = 687.51 },
   [pscustomobject]@{ Name = "middle"; Windows = @("2019", "2020", "2021", "2022"); Expected = 650.83 },
   [pscustomobject]@{ Name = "recent"; Windows = @("2023", "2024", "2025", "2026_ytd"); Expected = 729.30 }
)
$eraPass = $true
$eraEvidence = @()
foreach($era in $eras) {
   $net = [math]::Round(($summary | Where-Object { $_.TestWindow -in $era.Windows } | Measure-Object -Property CollisionAdjustedNet -Sum).Sum, 2)
   $eraPass = $eraPass -and $net -eq $era.Expected
   $eraEvidence += "$($era.Name)=$net"
}
Add-Check "all broad eras positive and frozen" $eraPass ($eraEvidence -join " ")

$blockedByLane = $blocked | Group-Object Component
$mtsmBlocked = $blockedByLane | Where-Object Name -eq "MTSM_CAP12_ANNUAL"
$rroBlocked = $blockedByLane | Where-Object Name -eq "RRO_DI12_CAP12_CONTINUOUS"
$ddbBlocked = $blockedByLane | Where-Object Name -eq "DDB045_ANNUAL_RESTART"
Add-Check "blocked lane counts frozen" ($mtsmBlocked.Count -eq 2 -and $rroBlocked.Count -eq 5 -and $ddbBlocked.Count -eq 1) "MTSM=$($mtsmBlocked.Count) RRO=$($rroBlocked.Count) DDB=$($ddbBlocked.Count)"

$acceptedOrdered = @($accepted | Sort-Object {[datetime]$_.EntryTime})
$overlapErrors = 0
for($i = 1; $i -lt $acceptedOrdered.Count; $i++) {
   if([datetime]$acceptedOrdered[$i].EntryTime -lt [datetime]$acceptedOrdered[$i - 1].ExitTime) { $overlapErrors++ }
}
Add-Check "accepted replay has no open-position overlap" ($overlapErrors -eq 0) "overlap_errors=$overlapErrors"

$blockedErrors = 0
foreach($row in $blocked) {
   if([string]::IsNullOrWhiteSpace($row.BlockedByComponent) -or
      [datetime]$row.EntryTime -ge [datetime]$row.BlockedByExitTime) { $blockedErrors++ }
}
Add-Check "every blocked trade has an active blocker" ($blockedErrors -eq 0) "blocker_errors=$blockedErrors"

$priorityNets = @($priority | Select-Object -ExpandProperty NetProfit -Unique)
$priorityPfs = @($priority | Select-Object -ExpandProperty ProfitFactor -Unique)
$priorityWindows = @($priority | Select-Object -ExpandProperty PositiveWindows -Unique)
Add-Check "all lane-priority permutations enumerated" ($priority.Count -eq 24 -and @($priority | Where-Object IsSourceOrder -eq "True").Count -eq 1) "rows=$($priority.Count) source_rows=$(@($priority | Where-Object IsSourceOrder -eq 'True').Count)"
Add-Check "priority permutation result is invariant" ($priorityNets.Count -eq 1 -and $priorityNets[0] -eq "2067.64" -and $priorityPfs.Count -eq 1 -and $priorityPfs[0] -eq "1.8942" -and $priorityWindows.Count -eq 1 -and $priorityWindows[0] -eq "12") "net=$($priorityNets -join ',') pf=$($priorityPfs -join ',') windows=$($priorityWindows -join ',')"

Add-Check "post-hoc boundary retained" ($markdown.Contains("cannot promote the combined EA") -and $markdown.Contains("Blocking an entry changes cooldowns") -and $markdown.Contains("not untouched out-of-sample evidence")) "promotion and path caveats present"
Add-Check "forward and real-money boundary retained" ($markdown.Contains("registered forward candidate remains unchanged") -and $markdown.Contains("real-money trading remains locked")) "no forward substitution"
Add-Check "no account identifier published" ($markdown -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $markdown -notmatch '(?i)login\s*[:=]\s*\d{5,}') "public markdown contains no account id"

$failed = @($checks | Where-Object Pass -eq $false)
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "$($failed.Count) RDMC collision pre-screen checks failed."
}
Write-Host "PASS: $($checks.Count) RDMC collision pre-screen checks"
