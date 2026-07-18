param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueuePath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$RunPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_RUN.csv",
   [string]$CompileLogPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_COMPILE.log",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = '0B0DB2770C3CF7170C248A94B829932166F9ADA42ACB3956B7FC4450993C8121'
$expectedBinaryHash = 'BCC66BFFFA22A6F096006104CCC03EA0FB66032AF7DF1505F69FBE33C23F4F3E'
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Format-Money([double]$Value) {
   if($Value -ge 0) { return ('+${0:N2}' -f $Value) }
   return ('-${0:N2}' -f [math]::Abs($Value))
}
function Is-Adjacent([string]$Left, [string]$Right) {
   if($Left -eq $Right) { return $false }
   return $Left -eq 'wgf_center' -or $Right -eq 'wgf_center'
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$runs = @(Import-Csv -LiteralPath (Resolve-RepoPath $RunPath))
$compile = Get-Content -LiteralPath (Resolve-RepoPath $CompileLogPath) -Raw
if($results.Count -ne 21 -or $queue.Count -ne 21 -or $runs.Count -ne 21) {
   throw "Expected 21 results, queue rows, and canonical run rows."
}
if(@($results | Where-Object Status -ne 'PARSED').Count -gt 0 -or
   @($runs | Where-Object Status -ne 'REPORT_FOUND').Count -gt 0) {
   throw "Every discovery report must be identity-valid and parsed."
}
if(@($results | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) {
   throw "Post-2020 data leaked into the discovery decision."
}
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected source identity in the queue."
}
if($compile -notmatch 'Result: 0 errors, 0 warnings') { throw "Compile evidence is not clean." }
foreach($row in $results) {
   $queued = @($queue | Where-Object QueueRank -eq $row.QueueRank)
   $run = @($runs | Where-Object QueueRank -eq $row.QueueRank)
   if($queued.Count -ne 1 -or $run.Count -ne 1 -or
      $row.ProfileSha256 -ne $queued[0].ProfileSha256 -or
      $row.SourceSha256 -ne $expectedSourceHash -or
      $run[0].PackageSourceSha256 -ne $expectedSourceHash) {
      throw "Result, queue, or runner identity mismatch at rank $($row.QueueRank)."
   }
}

$baseRows = [System.Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   if($group.Count -ne 3) { throw "Candidate $($group.Name) does not have three discovery windows." }
   $older = @($group.Group | Where-Object Window -eq 'older_2015_2018')
   $repair = @($group.Group | Where-Object Window -eq 'repair_2019_2020')
   $continuous = @($group.Group | Where-Object Window -eq 'continuous_2015_2020')
   if($older.Count -ne 1 -or $repair.Count -ne 1 -or $continuous.Count -ne 1) {
      throw "Candidate $($group.Name) has an unexpected window set."
   }
   $olderNet = [double]$older[0].NetProfit
   $repairNet = [double]$repair[0].NetProfit
   $continuousNet = [double]$continuous[0].NetProfit
   $pf = [double]$continuous[0].ProfitFactor
   $trades = [int]$continuous[0].TotalTrades
   $dd = [double]$continuous[0].MaxDrawdownPercent
   $payoff = [double]$continuous[0].ExpectedPayoff
   $returnPercent = 100.0 * $continuousNet / 10000.0
   $returnToDd = if($dd -gt 0.0) { $returnPercent / $dd } elseif($returnPercent -gt 0.0) { [double]::PositiveInfinity } else { 0.0 }
   $basePass = $olderNet -gt 0.0 -and $repairNet -gt 0.0 -and $continuousNet -gt 0.0 -and
               $pf -ge 1.20 -and $trades -ge 40 -and $dd -le 2.50 -and
               $payoff -gt 0.0 -and $returnToDd -ge 1.00
   $baseRows.Add([pscustomobject]@{
      Candidate = $group.Name
      Older2015To2018Net = [math]::Round($olderNet, 2)
      Repair2019To2020Net = [math]::Round($repairNet, 2)
      Continuous2015To2020Net = [math]::Round($continuousNet, 2)
      ContinuousProfitFactor = [math]::Round($pf, 4)
      ContinuousExpectedPayoff = [math]::Round($payoff, 4)
      ContinuousTrades = $trades
      ContinuousMaxDrawdownPercent = [math]::Round($dd, 2)
      ContinuousReturnToDrawdown = if([double]::IsPositiveInfinity($returnToDd)) { 999.0 } else { [math]::Round($returnToDd, 4) }
      ContinuousWinRatePercent = [math]::Round([double]$continuous[0].WinRatePercent, 2)
      BothDisjointErasPositive = $olderNet -gt 0.0 -and $repairNet -gt 0.0
      ProfitFactorAtLeast120 = $pf -ge 1.20
      TradesAtLeast40 = $trades -ge 40
      DrawdownAtMost250 = $dd -le 2.50
      ExpectedPayoffPositive = $payoff -gt 0.0
      ReturnToDrawdownAtLeast100 = $returnToDd -ge 1.00
      BaseGatePass = $basePass
   }) | Out-Null
}

$decisionRows = foreach($row in $baseRows) {
   $adjacentPass = @($baseRows | Where-Object { $_.BaseGatePass -eq $true -and (Is-Adjacent $row.Candidate $_.Candidate) }).Count -gt 0
   $gatePass = $row.BaseGatePass -and $adjacentPass
   [pscustomobject]@{
      Candidate = $row.Candidate
      Older2015To2018Net = $row.Older2015To2018Net
      Repair2019To2020Net = $row.Repair2019To2020Net
      Continuous2015To2020Net = $row.Continuous2015To2020Net
      ContinuousProfitFactor = $row.ContinuousProfitFactor
      ContinuousExpectedPayoff = $row.ContinuousExpectedPayoff
      ContinuousTrades = $row.ContinuousTrades
      ContinuousMaxDrawdownPercent = $row.ContinuousMaxDrawdownPercent
      ContinuousReturnToDrawdown = $row.ContinuousReturnToDrawdown
      ContinuousWinRatePercent = $row.ContinuousWinRatePercent
      BothDisjointErasPositive = $row.BothDisjointErasPositive
      ProfitFactorAtLeast120 = $row.ProfitFactorAtLeast120
      TradesAtLeast40 = $row.TradesAtLeast40
      DrawdownAtMost250 = $row.DrawdownAtMost250
      ExpectedPayoffPositive = $row.ExpectedPayoffPositive
      ReturnToDrawdownAtLeast100 = $row.ReturnToDrawdownAtLeast100
      BaseGatePass = $row.BaseGatePass
      AdjacentProfilePass = $adjacentPass
      DiscoveryGatePass = $gatePass
      Decision = if($gatePass) { 'OPEN_FROZEN_HOLDOUT' } else { 'REJECTED_NO_HOLDOUT_NO_MODEL4' }
   }
}
$ordered = @($decisionRows | Sort-Object Continuous2015To2020Net -Descending)
if($ordered.Count -ne 7) { throw "Expected seven candidate decisions." }
if(@($ordered | Where-Object DiscoveryGatePass -eq $true).Count -gt 0) {
   throw "A profile passed; the rejection-only publication must be revised before use."
}
$ordered | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# Independent M15 Weekend-Gap Fade Decision')
$md.Add('')
$md.Add("Decision date: $((Get-Date).ToString('yyyy-MM-dd'))")
$md.Add('')
$md.Add('**Verdict: rejected during frozen Model 1 discovery. No 2021-2026 holdout was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**')
$md.Add('')
$md.Add('## Test Contract')
$md.Add('')
$md.Add('- Source: `work/Independent_XAUUSD_M15_Weekend_Gap_Fade.mq5`')
$md.Add("- Source SHA-256: ``$expectedSourceHash``")
$md.Add("- Compiled binary SHA-256: ``$expectedBinaryHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Discovery data only: 2015-01-01 through 2020-12-31')
$md.Add('- Identity-valid reports parsed: `21 / 21`')
$md.Add('- Candidate variants: `7`')
$md.Add('- Risk per trade: `0.10%`')
$md.Add('- 2021-2026 holdout configurations run: `0`')
$md.Add('- Model 4 configurations run: `0`')
$md.Add('')
$md.Add('Two initial portable rows hit startup identity races. Only their exact frozen configurations were rerun; both passed source identity on retry, and the canonical run evidence contains one identity-valid result per queue rank.')
$md.Add('')
$md.Add('## Discovery Evidence')
$md.Add('')
$md.Add('The frozen gate required both disjoint eras to be profitable, continuous PF at least 1.20, at least 40 trades, DD no greater than 2.50%, positive expected payoff, return/DD at least 1.00, and an adjacent passing profile. No row passed the base gate.')
$md.Add('')
$md.Add('| Candidate | 2015-2018 | 2019-2020 | Continuous | PF | Payoff | Trades | DD | Return/DD | Decision |')
$md.Add('| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |')
foreach($row in $ordered) {
   $md.Add("| ``$($row.Candidate)`` | ``$(Format-Money $row.Older2015To2018Net)`` | ``$(Format-Money $row.Repair2019To2020Net)`` | ``$(Format-Money $row.Continuous2015To2020Net)`` | ``$('{0:N2}' -f $row.ContinuousProfitFactor)`` | ``$('{0:N2}' -f $row.ContinuousExpectedPayoff)`` | ``$($row.ContinuousTrades)`` | ``$('{0:N2}' -f $row.ContinuousMaxDrawdownPercent)%`` | ``$('{0:N2}' -f $row.ContinuousReturnToDrawdown)`` | rejected |")
}
$md.Add('')
$md.Add('The center traded only three times across 2015-2020 and lost $8.04. Relaxing confirmation to zero increased activity to 15 trades, but that row lost $13.46 continuously and $22.00 in 2019-2020. The family is both too sparse and unprofitable at the frozen geometry.')
$md.Add('')
$md.Add('## Decision')
$md.Add('')
$md.Add('- Reject this weekend-gap fade neighborhood; do not tune it on recent data.')
$md.Add('- Skip holdout and Model 4 because the broad pre-2021 gate failed.')
$md.Add('- Do not merge the engine into the frozen forward candidate.')
$md.Add('- Preserve the registered source/profile/binary identity, evidence logs, and hard real-account lock unchanged.')
$md.Add('')
$md.Add('## Evidence')
$md.Add('')
$md.Add('- `outputs/INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_CONTRACT.md`')
$md.Add('- `outputs/INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_RESULTS.csv`')
$md.Add('- `outputs/INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_RUN.csv`')
$md.Add('- `outputs/INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_DECISION.csv`')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status = 'REJECTED'
   Results = $results.Count
   Candidates = $ordered.Count
   GatePasses = @($ordered | Where-Object DiscoveryGatePass -eq $true).Count
   HoldoutRuns = 0
   Model4Runs = 0
   NewBest = $false
}
