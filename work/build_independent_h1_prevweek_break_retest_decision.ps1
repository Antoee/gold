param(
   [string]$ResultsCsv = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueueCsv = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$DecisionCsv = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdown = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "1A5799C5829D0E7108F60CBB331EB98BE39DACD0422C592020B6973C17147F26"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Format-Money([double]$Value) {
   if($Value -ge 0) { return ('+${0:N2}' -f $Value) }
   return ('-${0:N2}' -f [math]::Abs($Value))
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsCsv))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueCsv))
if($results.Count -ne 42 -or $queue.Count -ne 42) { throw "Expected 42 result and queue rows." }
if(@($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "Every discovery report must be parsed." }
if(@($results | Where-Object { $_.To -gt "2020.12.31" }).Count -ne 0) { throw "Post-2020 data leaked into discovery." }
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected source identity."
}
foreach($result in $results) {
   $queued = @($queue | Where-Object QueueRank -eq $result.QueueRank)
   if($queued.Count -ne 1 -or $queued[0].ProfileSha256 -ne $result.ProfileSha256) {
      throw "Result-to-queue identity mismatch at rank $($result.QueueRank)."
   }
}

$decisions = [System.Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   if($group.Count -ne 3) { throw "Candidate $($group.Name) does not have three windows." }
   $older = @($group.Group | Where-Object Window -eq "older_2015_2018")
   $newer = @($group.Group | Where-Object Window -eq "discovery_2019_2020")
   $continuous = @($group.Group | Where-Object Window -eq "continuous_2015_2020")
   if($older.Count -ne 1 -or $newer.Count -ne 1 -or $continuous.Count -ne 1) { throw "Unexpected window set for $($group.Name)." }
   $olderNet = [double]$older[0].NetProfit
   $newerNet = [double]$newer[0].NetProfit
   $continuousNet = [double]$continuous[0].NetProfit
   $pf = [double]$continuous[0].ProfitFactor
   $dd = [double]$continuous[0].MaxDrawdownPercent
   $trades = [int]$continuous[0].TotalTrades
   $bothPositive = $olderNet -gt 0 -and $newerNet -gt 0
   $gatePass = $bothPositive -and $pf -ge 1.20 -and $trades -ge 40 -and $dd -le 5.00
   $decisions.Add([pscustomobject]@{
      Candidate=$group.Name
      Older2015To2018Net=[math]::Round($olderNet, 2)
      Newer2019To2020Net=[math]::Round($newerNet, 2)
      Continuous2015To2020Net=[math]::Round($continuousNet, 2)
      ContinuousProfitFactor=[math]::Round($pf, 2)
      ContinuousMaxDrawdownPercent=[math]::Round($dd, 2)
      ContinuousTrades=$trades
      ContinuousWinRatePercent=[math]::Round([double]$continuous[0].WinRatePercent, 2)
      ContinuousRecoveryFactor=[math]::Round([double]$continuous[0].RecoveryFactor, 2)
      BothDisjointErasPositive=$bothPositive
      ProfitFactorAtLeast120=($pf -ge 1.20)
      TradesAtLeast40=($trades -ge 40)
      DrawdownAtMost5Percent=($dd -le 5.00)
      DiscoveryGatePass=$gatePass
      Decision=if($gatePass){"OPEN_YEARLY_DISCOVERY"}else{"REJECTED_NO_RECENT_NO_MODEL4"}
   }) | Out-Null
}

$ordered = @($decisions | Sort-Object Continuous2015To2020Net -Descending)
if($ordered.Count -ne 14) { throw "Expected fourteen decisions." }
if(@($ordered | Where-Object DiscoveryGatePass).Count -ne 0) { throw "A candidate unexpectedly passed." }
if(@($ordered | Where-Object { [double]$_.Older2015To2018Net -ge 0 }).Count -ne 0) { throw "Expected every older-era row to be negative." }
if(@($ordered | Where-Object { [double]$_.Continuous2015To2020Net -ge 0 }).Count -ne 0) { throw "Expected every continuous row to be negative." }
$ordered | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent H1 Previous-Week Break-And-Retest Decision")
$md.Add("")
$md.Add("Decision date: $((Get-Date).ToString('yyyy-MM-dd'))")
$md.Add("")
$md.Add("**Verdict: rejected during Model 1 discovery. No 2021-2026 retrospective run was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**")
$md.Add("")
$md.Add("## Test Contract")
$md.Add("")
$md.Add("This standalone strategy records an H1 close beyond the prior W1 high or low, then requires a later bounded retest and reclaim before entry. The fourteen-variant neighborhood changes breakout quality, setup lifetime, retest depth, volume, trend/ADX, session timing, and payoff without calendar fitting.")
$md.Add("")
$md.Add("- Source: ``work/Independent_XAUUSD_H1_PrevWeek_Break_Retest.mq5``")
$md.Add("- Source SHA-256: ``$expectedSourceHash``")
$md.Add("- Compile: ``0 errors, 0 warnings``")
$md.Add("- Source/profile input contract: ``77`` inputs matched")
$md.Add("- Discovery data only: 2015-01-01 through 2020-12-31")
$md.Add("- Clean reports returned and parsed: ``42 / 42``")
$md.Add("- Candidate variants: ``14``")
$md.Add("- Risk per trade: ``0.10%``")
$md.Add("- 2021-2026 retrospective configurations run: ``0``")
$md.Add("- Model 4 configurations run: ``0``")
$md.Add("")
$md.Add("## Discovery Evidence")
$md.Add("")
$md.Add("Every tested variant lost money in 2015-2018 and every continuous 2015-2020 row was negative. No continuous profit factor reached 1.00, so the family failed before sample-size or drawdown could rescue it.")
$md.Add("")
$md.Add("| Candidate | 2015-2018 | 2019-2020 | Continuous 2015-2020 | PF | Max DD | Trades | Win rate | Decision |")
$md.Add("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
foreach($row in $ordered) {
   $md.Add("| ``$($row.Candidate)`` | ``$(Format-Money $row.Older2015To2018Net)`` | ``$(Format-Money $row.Newer2019To2020Net)`` | ``$(Format-Money $row.Continuous2015To2020Net)`` | ``$('{0:N2}' -f $row.ContinuousProfitFactor)`` | ``$('{0:N2}' -f $row.ContinuousMaxDrawdownPercent)%`` | ``$($row.ContinuousTrades)`` | ``$('{0:N2}' -f $row.ContinuousWinRatePercent)%`` | rejected |")
}
$md.Add("")
$lead = $ordered[0]
$md.Add("The least-bad continuous row was ``$($lead.Candidate)`` at ``$(Format-Money $lead.Continuous2015To2020Net)``, PF ``$('{0:N2}' -f $lead.ContinuousProfitFactor)``, and only ``$($lead.ContinuousTrades)`` trades. It still lost ``$(Format-Money $lead.Older2015To2018Net)`` in the older era. Broad/strict shapes, age, retest depth, volume, trend, session, and payoff variants all failed, so there is no stable neighborhood to escalate.")
$md.Add("")
$md.Add("## Decision")
$md.Add("")
$md.Add("- Reject H1 previous-week break-and-retest continuation at the tested structure/risk neighborhood.")
$md.Add("- Do not use 2021-2026 to rescue a family that failed discovery.")
$md.Add("- Skip Model 4 because every continuous Model 1 candidate lost money.")
$md.Add("- Do not merge this standalone engine into the frozen EA.")
$md.Add("- Preserve the frozen three-lane benchmark, exact installed binary, and forward boundary unchanged.")
$md.Add("")
$md.Add("## Evidence")
$md.Add("")
$md.Add("- ``outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_RESULTS.csv``")
$md.Add("- ``outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_SUMMARY.csv``")
$md.Add("- ``outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_METRICS.md``")
$md.Add("- ``outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_RUN.csv``")
$md.Add("- ``outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_DECISION.csv``")
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Encoding ASCII

[pscustomobject]@{ Status="REJECTED"; Results=$results.Count; Candidates=$ordered.Count; GatePasses=0; BestContinuousCandidate=$lead.Candidate; BestContinuousNet=$lead.Continuous2015To2020Net; RecentRuns=0; Model4Runs=0 }
