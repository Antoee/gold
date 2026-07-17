param(
   [string]$DiscoveryResultsCsv = "outputs\INDEPENDENT_M15_FAILED_BREAKOUT_TRAP_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DiscoveryQueueCsv = "outputs\INDEPENDENT_M15_FAILED_BREAKOUT_TRAP_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$LivenessResultsCsv = "outputs\INDEPENDENT_M15_FAILED_BREAKOUT_LIVENESS_MODEL1_RESULTS.csv",
   [string]$LivenessQueueCsv = "outputs\INDEPENDENT_M15_FAILED_BREAKOUT_LIVENESS_MODEL1_QUEUE.csv",
   [string]$DecisionCsv = "outputs\INDEPENDENT_M15_FAILED_BREAKOUT_DECISION.csv",
   [string]$DecisionMarkdown = "outputs\INDEPENDENT_M15_FAILED_BREAKOUT_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "EFB39ED06E5C7CA3D75C971F24ADB3073E597CC9CB2373257521EC41BDC57990"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Format-Money([double]$Value) {
   if($Value -ge 0.0) { return ('+${0:N2}' -f $Value) }
   return ('-${0:N2}' -f [math]::Abs($Value))
}

function Read-ValidatedEvidence([string]$ResultsPath, [string]$QueuePath, [int]$ExpectedCount) {
   $results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
   $queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
   if($results.Count -ne $ExpectedCount -or $queue.Count -ne $ExpectedCount) {
      throw "Unexpected evidence count for $ResultsPath."
   }
   if(@($results | Where-Object Status -ne "PARSED").Count -ne 0) {
      throw "Every report must be parsed before decision generation."
   }
   if(@($results | Where-Object { $_.To -gt "2020.12.31" }).Count -ne 0) {
      throw "Post-2020 data leaked into failed-breakout discovery."
   }
   if(@($queue.SourceSha256 | Where-Object { $_ -ne $expectedSourceHash }).Count -ne 0) {
      throw "Unexpected source identity in failed-breakout evidence."
   }
   foreach($result in $results) {
      $queued = @($queue | Where-Object QueueRank -eq $result.QueueRank)
      if($queued.Count -ne 1 -or $queued[0].ProfileSha256 -ne $result.ProfileSha256) {
         throw "Result-to-queue identity mismatch at rank $($result.QueueRank)."
      }
   }
   return $results
}

$discovery = @(Read-ValidatedEvidence $DiscoveryResultsCsv $DiscoveryQueueCsv 48)
$liveness = @(Read-ValidatedEvidence $LivenessResultsCsv $LivenessQueueCsv 36)

$supportedFamilies = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$fixedRows = foreach($group in ($liveness | Group-Object Candidate)) {
   if($group.Name -notmatch '^fbt_b(?<box>\d+)_fixed_r\d+$') { continue }
   $older = @($group.Group | Where-Object Window -eq "older_2015_2018")[0]
   $newer = @($group.Group | Where-Object Window -eq "discovery_2019_2020")[0]
   $continuous = @($group.Group | Where-Object Window -eq "continuous_2015_2020")[0]
   [pscustomobject]@{
      Family = "fixed_box_$($Matches.box)"
      BothPositive = [double]$older.NetProfit -gt 0.0 -and [double]$newer.NetProfit -gt 0.0
      PfPass = [double]$continuous.ProfitFactor -ge 1.20
   }
}
foreach($family in ($fixedRows | Group-Object Family)) {
   if($family.Count -ge 3 -and @($family.Group | Where-Object { $_.BothPositive -and $_.PfPass }).Count -ge 3) {
      $supportedFamilies.Add($family.Name) | Out-Null
   }
}

$decisionRows = [System.Collections.Generic.List[object]]::new()
foreach($stage in @(
   [pscustomobject]@{ Name="initial_discovery"; Rows=$discovery },
   [pscustomobject]@{ Name="liveness_followup"; Rows=$liveness }
)) {
   foreach($group in ($stage.Rows | Group-Object Candidate)) {
      if($group.Count -ne 3) { throw "Candidate $($group.Name) does not have three windows." }
      $older = @($group.Group | Where-Object Window -eq "older_2015_2018")[0]
      $newer = @($group.Group | Where-Object Window -eq "discovery_2019_2020")[0]
      $continuous = @($group.Group | Where-Object Window -eq "continuous_2015_2020")[0]
      $olderNet = [double]$older.NetProfit
      $newerNet = [double]$newer.NetProfit
      $continuousNet = [double]$continuous.NetProfit
      $pf = [double]$continuous.ProfitFactor
      $dd = [double]$continuous.MaxDrawdownPercent
      $trades = [int]$continuous.TotalTrades
      $bothPositive = $olderNet -gt 0.0 -and $newerNet -gt 0.0
      $pfPass = $pf -ge 1.20
      $tradePass = $trades -ge 60
      $ddPass = $dd -le 5.00
      $numericPass = $bothPositive -and $pfPass -and $tradePass -and $ddPass
      $family = if($group.Name -match '^fbt_b(?<box>\d+)_fixed_r\d+$') { "fixed_box_$($Matches.box)" } else { "" }
      $neighborPass = $family -ne "" -and $supportedFamilies.Contains($family)
      $finalPass = $numericPass -and $neighborPass
      $decision = if($numericPass -and !$neighborPass) {
         "REJECTED_UNSUPPORTED_NUMERIC_PASS"
      } elseif($neighborPass -and !$tradePass) {
         "REJECTED_ACTIVITY_FLOOR"
      } else {
         "REJECTED_DISCOVERY_GATE"
      }

      $decisionRows.Add([pscustomobject]@{
         Stage=$stage.Name; Candidate=$group.Name
         Older2015To2018Net=[math]::Round($olderNet, 2); OlderProfitFactor=[math]::Round([double]$older.ProfitFactor, 2)
         Newer2019To2020Net=[math]::Round($newerNet, 2); NewerProfitFactor=[math]::Round([double]$newer.ProfitFactor, 2)
         Continuous2015To2020Net=[math]::Round($continuousNet, 2)
         AnnualizedReturnPercent=[math]::Round([double]$continuous.AnnualizedReturnPercent, 2)
         ContinuousProfitFactor=[math]::Round($pf, 2); ContinuousMaxDrawdownPercent=[math]::Round($dd, 2)
         ContinuousTrades=$trades; ContinuousWinRatePercent=[math]::Round([double]$continuous.WinRatePercent, 2)
         ContinuousRecoveryFactor=[math]::Round([double]$continuous.RecoveryFactor, 2)
         BothDisjointErasPositive=$bothPositive; ProfitFactorAtLeast120=$pfPass
         TradesAtLeast60=$tradePass; DrawdownAtMost5Percent=$ddPass
         QuantitativeGatePass=$numericPass; NeighborSupportPass=$neighborPass
         FinalPromotionGatePass=$finalPass; Decision=$decision
      }) | Out-Null
   }
}

$ordered = @($decisionRows | Sort-Object Stage, @{Expression="Continuous2015To2020Net"; Descending=$true})
if($ordered.Count -ne 28) { throw "Expected 28 candidate decisions." }
if(@($ordered | Where-Object FinalPromotionGatePass).Count -ne 0) {
   throw "A candidate unexpectedly passed the final promotion gate."
}
$ordered | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv) -NoTypeInformation -Encoding ASCII

$livenessDecision = @($ordered | Where-Object Stage -eq "liveness_followup" | Sort-Object Continuous2015To2020Net -Descending)
$numeric = @($livenessDecision | Where-Object QuantitativeGatePass)
$supportedSparse = @($livenessDecision | Where-Object { $_.NeighborSupportPass -and !$_.TradesAtLeast60 })
$lead = $livenessDecision[0]

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 Failed-Breakout Trap Decision")
$md.Add("")
$md.Add("Decision date: $((Get-Date).ToString('yyyy-MM-dd'))")
$md.Add("")
$md.Add("**Verdict: rejected before holdout. No 2021-2026 retrospective run was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**")
$md.Add("")
$md.Add("## Test Contract")
$md.Add("")
$md.Add("The standalone M15 EA fades the first closed-bar snapback after a false break of a bounded compression box. It uses a stop beyond the failed excursion, either the opposite box edge or a fixed-R target, broker-accurate ``OrderCalcProfit`` sizing at ``0.10%`` risk, no forced minimum lot, and account-wide exposure protection.")
$md.Add("")
$md.Add("- Source: ``work/Independent_XAUUSD_M15_Failed_Breakout_Trap.mq5``")
$md.Add("- Source SHA-256: ``$expectedSourceHash``")
$md.Add("- Compile: ``0 errors, 0 warnings``")
$md.Add("- Data used: 2015-01-01 through 2020-12-31 only")
$md.Add("- Initial discovery: ``48 / 48`` reports parsed")
$md.Add("- Bounded liveness follow-up: ``36 / 36`` reports parsed")
$md.Add("- Total reports: ``84 / 84``")
$md.Add("- 2021-2026 configurations run: ``0``")
$md.Add("- Model 4 configurations run: ``0``")
$md.Add("")
$md.Add("## Result")
$md.Add("")
$md.Add("The initial 16-variant screen had no promotion pass. Its 16-bar structural-target row was positive in both eras at ``+`$32.66`` and PF ``1.49``, but had only ``16`` trades in six years and no support from the losing 8/12-bar neighbors.")
$md.Add("")
$md.Add("The liveness follow-up found a coherent 16-bar fixed-R neighborhood: 1.25R, 1.5R, and 2.0R were all profitable in both disjoint eras, with continuous PF from ``1.26`` to ``1.45`` and drawdown from ``0.58%`` to ``0.65%``. Every row had only ``54`` trades, below the frozen minimum of ``60``.")
$md.Add("")
$md.Add("The only quantitative gate row was ``fbt_b14_fixed_r200``. It made ``$(Format-Money $lead.Continuous2015To2020Net)`` continuously, but only ``+`$0.76`` in 2019-2020 at PF ``1.00``; adjacent 1.25R and 1.5R versions lost in that era. It therefore failed the required neighbor-support gate and is not robust evidence.")
$md.Add("")
$md.Add("| Candidate | 2015-2018 | 2019-2020 | Continuous | Annualized | PF | Max DD | Trades | Neighbor support | Decision |")
$md.Add("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |")
foreach($row in $livenessDecision) {
   $md.Add("| ``$($row.Candidate)`` | ``$(Format-Money $row.Older2015To2018Net)`` | ``$(Format-Money $row.Newer2019To2020Net)`` | ``$(Format-Money $row.Continuous2015To2020Net)`` | ``$('{0:N2}' -f $row.AnnualizedReturnPercent)%`` | ``$('{0:N2}' -f $row.ContinuousProfitFactor)`` | ``$('{0:N2}' -f $row.ContinuousMaxDrawdownPercent)%`` | ``$($row.ContinuousTrades)`` | ``$($row.NeighborSupportPass)`` | ``$($row.Decision)`` |")
}
$md.Add("")
$md.Add("## Decision")
$md.Add("")
$md.Add("- Do not promote or merge the failed-breakout trap into the frozen EA.")
$md.Add("- Do not lower the activity floor after observing a 54-trade neighborhood.")
$md.Add("- Do not use the newer holdout to rescue an underpowered discovery result.")
$md.Add("- Skip Model 4 because the predeclared discovery contract was not fully met.")
$md.Add("- Preserve the 16-bar fixed-R neighborhood as a research clue only, not a deployable profile.")
$md.Add("")
$md.Add("## Evidence")
$md.Add("")
$md.Add("- ``outputs/INDEPENDENT_M15_FAILED_BREAKOUT_TRAP_DISCOVERY_MODEL1_RESULTS.csv``")
$md.Add("- ``outputs/INDEPENDENT_M15_FAILED_BREAKOUT_LIVENESS_MODEL1_RESULTS.csv``")
$md.Add("- ``outputs/INDEPENDENT_M15_FAILED_BREAKOUT_DECISION.csv``")
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Encoding ASCII

[pscustomobject]@{
   Status="REJECTED"; Reports=84; Candidates=$ordered.Count
   NumericGatePasses=$numeric.Count; SupportedSparseRows=$supportedSparse.Count
   FinalGatePasses=@($ordered | Where-Object FinalPromotionGatePass).Count
   RecentRuns=0; Model4Runs=0
}
