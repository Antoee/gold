param(
   [string]$ResultsCsv = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueueCsv = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$DecisionCsv = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdown = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "DE93CFC433C0F3A9B19A6F8D58AAF32894FC8FE6DC41F98A3745FD209C787E8E"

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
if($results.Count -ne 30) { throw "Expected 30 discovery results, found $($results.Count)." }
if($queue.Count -ne 30) { throw "Expected 30 discovery queue rows, found $($queue.Count)." }
if(@($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "Every discovery report must be parsed before a decision is built." }
if(@($results | Where-Object { $_.To -gt "2020.12.31" }).Count -ne 0) { throw "Post-2020 data leaked into the discovery decision." }
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected source identity in discovery evidence."
}
foreach($result in $results) {
   $queued = @($queue | Where-Object QueueRank -eq $result.QueueRank)
   if($queued.Count -ne 1 -or $queued[0].ProfileSha256 -ne $result.ProfileSha256) {
      throw "Result-to-queue identity mismatch at rank $($result.QueueRank)."
   }
}

$decisionRows = [System.Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   if($group.Count -ne 3) { throw "Candidate $($group.Name) does not have exactly three discovery windows." }
   $older = @($group.Group | Where-Object Window -eq "older_2015_2018")
   $newer = @($group.Group | Where-Object Window -eq "discovery_2019_2020")
   $continuous = @($group.Group | Where-Object Window -eq "continuous_2015_2020")
   if($older.Count -ne 1 -or $newer.Count -ne 1 -or $continuous.Count -ne 1) {
      throw "Candidate $($group.Name) has an unexpected discovery window set."
   }

   $olderNet = [double]$older[0].NetProfit
   $newerNet = [double]$newer[0].NetProfit
   $continuousNet = [double]$continuous[0].NetProfit
   $profitFactor = [double]$continuous[0].ProfitFactor
   $drawdown = [double]$continuous[0].MaxDrawdownPercent
   $trades = [int]$continuous[0].TotalTrades
   $bothErasPositive = $olderNet -gt 0 -and $newerNet -gt 0
   $profitFactorPass = $profitFactor -ge 1.20
   $tradeCountPass = $trades -ge 60
   $drawdownPass = $drawdown -le 5.00
   $gatePass = $bothErasPositive -and $profitFactorPass -and $tradeCountPass -and $drawdownPass

   $decisionRows.Add([pscustomobject]@{
      Candidate = $group.Name
      Older2015To2018Net = [math]::Round($olderNet, 2)
      Newer2019To2020Net = [math]::Round($newerNet, 2)
      Continuous2015To2020Net = [math]::Round($continuousNet, 2)
      ContinuousProfitFactor = [math]::Round($profitFactor, 2)
      ContinuousMaxDrawdownPercent = [math]::Round($drawdown, 2)
      ContinuousTrades = $trades
      ContinuousWinRatePercent = [math]::Round([double]$continuous[0].WinRatePercent, 2)
      ContinuousRecoveryFactor = [math]::Round([double]$continuous[0].RecoveryFactor, 2)
      BothDisjointErasPositive = $bothErasPositive
      ProfitFactorAtLeast120 = $profitFactorPass
      TradesAtLeast60 = $tradeCountPass
      DrawdownAtMost5Percent = $drawdownPass
      DiscoveryGatePass = $gatePass
      Decision = if($gatePass) { "OPEN_YEARLY_DISCOVERY" } else { "REJECTED_NO_RECENT_NO_MODEL4" }
   }) | Out-Null
}

$ordered = @($decisionRows | Sort-Object Continuous2015To2020Net -Descending)
if($ordered.Count -ne 10) { throw "Expected ten candidate decisions." }
if(@($ordered | Where-Object DiscoveryGatePass).Count -ne 0) { throw "A candidate unexpectedly passed; this rejection builder must be revised before use." }
if(@($ordered | Where-Object { [double]$_.Older2015To2018Net -ge 0 }).Count -ne 0) { throw "The expected all-negative older-era result was not reproduced." }

$ordered | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 Previous-Day Liquidity Sweep Decision")
$md.Add("")
$md.Add("Decision date: $((Get-Date).ToString('yyyy-MM-dd'))")
$md.Add("")
$md.Add("**Verdict: rejected during Model 1 discovery. No 2021-2026 retrospective run was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**")
$md.Add("")
$md.Add("## Test Contract")
$md.Add("")
$md.Add("This standalone price-action EA trades fresh M15 sweeps and reclaims of the previous D1 high or low. The ten-variant neighborhood changes sweep depth, reclaim depth, wick shape, tick-volume confirmation, H1 trend alignment, maximum ADX, payoff, midpoint targeting, and session timing without using calendar cutoffs or recent-period optimization.")
$md.Add("")
$md.Add("- Source: ``work/Independent_XAUUSD_M15_PrevDay_Sweep.mq5``")
$md.Add("- Source SHA-256: ``$expectedSourceHash``")
$md.Add("- Compile: ``0 errors, 0 warnings``")
$md.Add("- Discovery data only: 2015-01-01 through 2020-12-31")
$md.Add("- Clean reports returned and parsed: ``30 / 30``")
$md.Add("- Candidate variants: ``10``")
$md.Add("- Continuous risk per trade: ``0.10%``")
$md.Add("- 2021-2026 retrospective configurations run: ``0``")
$md.Add("- Model 4 configurations run: ``0``")
$md.Add("")
$md.Add("## Discovery Evidence")
$md.Add("")
$md.Add("The predeclared gate required both disjoint eras to be profitable, continuous profit factor of at least 1.20, at least 60 continuous trades, maximum drawdown no greater than 5%, and support from nearby parameter shapes. Every tested configuration lost money in the older 2015-2018 era, so none could pass regardless of its continuous headline.")
$md.Add("")
$md.Add("| Candidate | 2015-2018 | 2019-2020 | Continuous 2015-2020 | PF | Max DD | Trades | Win rate | Decision |")
$md.Add("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
foreach($row in $ordered) {
   $md.Add("| ``$($row.Candidate)`` | ``$(Format-Money $row.Older2015To2018Net)`` | ``$(Format-Money $row.Newer2019To2020Net)`` | ``$(Format-Money $row.Continuous2015To2020Net)`` | ``$('{0:N2}' -f $row.ContinuousProfitFactor)`` | ``$('{0:N2}' -f $row.ContinuousMaxDrawdownPercent)%`` | ``$($row.ContinuousTrades)`` | ``$('{0:N2}' -f $row.ContinuousWinRatePercent)%`` | rejected |")
}
$md.Add("")
$lead = $ordered[0]
$md.Add("The least-bad continuous row was ``$($lead.Candidate)`` at ``$(Format-Money $lead.Continuous2015To2020Net)``, but it still lost ``$(Format-Money $lead.Older2015To2018Net)`` in the independent older era, had PF ``$('{0:N2}' -f $lead.ContinuousProfitFactor)``, and produced only ``$($lead.ContinuousTrades)`` continuous trades. The parameter neighborhood therefore provides no robust edge worth escalating.")
$md.Add("")
$md.Add("## Decision")
$md.Add("")
$md.Add("- Reject previous-day high/low sweep reversal at the tested M15 risk and confirmation neighborhood.")
$md.Add("- Do not use 2021-2026 to rescue the branch; the strategy failed before recent data was opened.")
$md.Add("- Skip Model 4 because the broad Model 1 discovery gate failed.")
$md.Add("- Do not merge this standalone engine into the frozen EA.")
$md.Add("- Preserve the frozen three-lane benchmark, exact installed binary, and forward boundary unchanged.")
$md.Add("")
$md.Add("## Evidence")
$md.Add("")
$md.Add("- ``outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_RESULTS.csv``")
$md.Add("- ``outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_SUMMARY.csv``")
$md.Add("- ``outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_METRICS.md``")
$md.Add("- ``outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_RUN.csv``")
$md.Add("- ``outputs/INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_DECISION.csv``")
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Encoding ASCII

[pscustomobject]@{
   Status = "REJECTED"
   Results = $results.Count
   Candidates = $ordered.Count
   GatePasses = @($ordered | Where-Object DiscoveryGatePass).Count
   BestContinuousCandidate = $lead.Candidate
   BestContinuousNet = $lead.Continuous2015To2020Net
   RecentRuns = 0
   Model4Runs = 0
}
