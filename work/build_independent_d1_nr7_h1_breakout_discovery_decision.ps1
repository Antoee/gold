param(
   [string]$ResultsPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueuePath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$RunPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RUN.csv",
   [string]$CompileEvidencePath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_COMPILE_AUDIT.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = 'BBFC4214F63658B7D2D22109AC0C536D32A23693C471179DB0E07EA70C974880'
$expectedBinaryHash = 'CC80BEE04EAC8B2669A1BBF44C79C57500C2BC6CF5EA8A9196ECA11778AA7D72'

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Format-Money([double]$Value) {
   if($Value -ge 0) { return ('+${0:N2}' -f $Value) }
   return ('-${0:N2}' -f [math]::Abs($Value))
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$runs = @(Import-Csv -LiteralPath (Resolve-RepoPath $RunPath))
$compile = @(Import-Csv -LiteralPath (Resolve-RepoPath $CompileEvidencePath))
if($results.Count -ne 54 -or $queue.Count -ne 54 -or $runs.Count -ne 54) {
   throw "Expected 54 results, queue rows, and canonical run rows."
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
if($compile.Count -ne 1 -or $compile[0].SourceSha256 -ne $expectedSourceHash -or
   $compile[0].PortableBinarySha256 -ne $expectedBinaryHash -or
   [int]$compile[0].CompileErrors -ne 0 -or [int]$compile[0].CompileWarnings -ne 0 -or
   $compile[0].Status -ne 'COMPILE_PASS') {
   throw "Compile evidence is not clean or identity-matched."
}
foreach($row in $results) {
   $queued = @($queue | Where-Object QueueRank -eq $row.QueueRank)
   $run = @($runs | Where-Object QueueRank -eq $row.QueueRank)
   if($queued.Count -ne 1 -or $run.Count -ne 1 -or
      $row.ProfileSha256 -ne $queued[0].ProfileSha256 -or
      $row.SourceSha256 -ne $expectedSourceHash -or
      $run[0].PackageSourceSha256 -ne $expectedSourceHash -or
      $run[0].PortableBinarySha256 -ne $expectedBinaryHash) {
      throw "Result, queue, runner, or binary identity mismatch at rank $($row.QueueRank)."
   }
}

$baseRows = [System.Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   if($group.Count -ne 3) { throw "Candidate $($group.Name) does not have three discovery windows." }
   $older = @($group.Group | Where-Object Window -eq 'older_2015_2018')
   $recent = @($group.Group | Where-Object Window -eq 'discovery_2019_2020')
   $continuous = @($group.Group | Where-Object Window -eq 'continuous_2015_2020')
   if($older.Count -ne 1 -or $recent.Count -ne 1 -or $continuous.Count -ne 1) {
      throw "Candidate $($group.Name) has an unexpected window set."
   }

   $olderNet = [double]$older[0].NetProfit
   $recentNet = [double]$recent[0].NetProfit
   $continuousNet = [double]$continuous[0].NetProfit
   $pf = [double]$continuous[0].ProfitFactor
   $trades = [int]$continuous[0].TotalTrades
   $dd = [double]$continuous[0].MaxDrawdownPercent
   $recovery = [double]$continuous[0].RecoveryFactor
   $basePass = $olderNet -gt 0.0 -and $recentNet -gt 0.0 -and $continuousNet -gt 0.0 -and
               $pf -ge 1.25 -and $trades -ge 80 -and $dd -le 3.0 -and $recovery -ge 1.5
   $baseRows.Add([pscustomobject]@{
      Candidate = $group.Name
      Older2015To2018Net = [math]::Round($olderNet, 2)
      Older2015To2018ProfitFactor = [math]::Round([double]$older[0].ProfitFactor, 4)
      Discovery2019To2020Net = [math]::Round($recentNet, 2)
      Discovery2019To2020ProfitFactor = [math]::Round([double]$recent[0].ProfitFactor, 4)
      Continuous2015To2020Net = [math]::Round($continuousNet, 2)
      ContinuousProfitFactor = [math]::Round($pf, 4)
      ContinuousTrades = $trades
      ContinuousMaxDrawdownPercent = [math]::Round($dd, 2)
      ContinuousRecoveryFactor = [math]::Round($recovery, 4)
      ContinuousCagrPercent = [math]::Round([double]$continuous[0].CagrPercent, 4)
      BothDisjointErasPositive = $olderNet -gt 0.0 -and $recentNet -gt 0.0
      ProfitFactorAtLeast125 = $pf -ge 1.25
      TradesAtLeast80 = $trades -ge 80
      DrawdownAtMost300 = $dd -le 3.0
      RecoveryAtLeast150 = $recovery -ge 1.5
      BaseGatePass = $basePass
   }) | Out-Null
}

$basePassCount = @($baseRows | Where-Object BaseGatePass -eq $true).Count
$familySupport = $basePassCount -ge 3
$decisionRows = foreach($row in $baseRows) {
   $gatePass = $row.BaseGatePass -and $familySupport
   [pscustomobject]@{
      Candidate = $row.Candidate
      Older2015To2018Net = $row.Older2015To2018Net
      Older2015To2018ProfitFactor = $row.Older2015To2018ProfitFactor
      Discovery2019To2020Net = $row.Discovery2019To2020Net
      Discovery2019To2020ProfitFactor = $row.Discovery2019To2020ProfitFactor
      Continuous2015To2020Net = $row.Continuous2015To2020Net
      ContinuousProfitFactor = $row.ContinuousProfitFactor
      ContinuousTrades = $row.ContinuousTrades
      ContinuousMaxDrawdownPercent = $row.ContinuousMaxDrawdownPercent
      ContinuousRecoveryFactor = $row.ContinuousRecoveryFactor
      ContinuousCagrPercent = $row.ContinuousCagrPercent
      BothDisjointErasPositive = $row.BothDisjointErasPositive
      ProfitFactorAtLeast125 = $row.ProfitFactorAtLeast125
      TradesAtLeast80 = $row.TradesAtLeast80
      DrawdownAtMost300 = $row.DrawdownAtMost300
      RecoveryAtLeast150 = $row.RecoveryAtLeast150
      BaseGatePass = $row.BaseGatePass
      ThreeVariantFamilySupport = $familySupport
      DiscoveryGatePass = $gatePass
      Decision = if($gatePass) { 'OPEN_FROZEN_HOLDOUT' } else { 'REJECTED_NO_HOLDOUT_NO_MODEL4' }
   }
}
$ordered = @($decisionRows | Sort-Object Continuous2015To2020Net -Descending)
if($ordered.Count -ne 18) { throw "Expected 18 candidate decisions." }
if(@($ordered | Where-Object DiscoveryGatePass -eq $true).Count -gt 0) {
   throw "A profile passed; revise the rejection-only publication before use."
}
$ordered | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$center = @($ordered | Where-Object Candidate -eq 'dnrb_center')[0]
$best = $ordered[0]
$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# Independent D1 NR7 / H1 Breakout Decision')
$md.Add('')
$md.Add("Decision date: $((Get-Date).ToString('yyyy-MM-dd'))")
$md.Add('')
$md.Add('**Verdict: rejected during frozen Model 1 discovery. No 2021-2026 holdout was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**')
$md.Add('')
$md.Add('## Test Contract')
$md.Add('')
$md.Add('- Source: `work/Independent_XAUUSD_D1_NR7_H1_Breakout.mq5`')
$md.Add("- Source SHA-256: ``$expectedSourceHash``")
$md.Add("- Compiled binary SHA-256: ``$expectedBinaryHash``")
$md.Add('- Compile: `0 errors, 0 warnings` across four isolated workers')
$md.Add('- Discovery data only: 2015-01-01 through 2020-12-31')
$md.Add('- Identity-valid reports parsed: `54 / 54`')
$md.Add('- Candidate variants: `18`')
$md.Add('- Risk per trade: `0.10%`')
$md.Add('- 2021-2026 holdout configurations run: `0`')
$md.Add('- Model 4 configurations run: `0`')
$md.Add('')
$md.Add('Four initial portable rows hit report-identity export errors. Only those exact frozen queue ranks were rerun; all four passed without changing source or settings, and the canonical evidence contains one identity-valid result per rank.')
$md.Add('')
$md.Add('## Discovery Evidence')
$md.Add('')
$md.Add('The frozen gate required both disjoint eras to be profitable, continuous PF at least 1.25, at least 80 trades, DD no greater than 3.00%, recovery at least 1.50, and support from at least three one-factor variants. No variant passed the base gate.')
$md.Add('')
$md.Add('| Candidate | 2015-2018 | PF | 2019-2020 | PF | Continuous | PF | Trades | DD | Recovery | CAGR | Decision |')
$md.Add('| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |')
foreach($row in $ordered) {
   $md.Add("| ``$($row.Candidate)`` | ``$(Format-Money $row.Older2015To2018Net)`` | ``$('{0:N2}' -f $row.Older2015To2018ProfitFactor)`` | ``$(Format-Money $row.Discovery2019To2020Net)`` | ``$('{0:N2}' -f $row.Discovery2019To2020ProfitFactor)`` | ``$(Format-Money $row.Continuous2015To2020Net)`` | ``$('{0:N2}' -f $row.ContinuousProfitFactor)`` | ``$($row.ContinuousTrades)`` | ``$('{0:N2}' -f $row.ContinuousMaxDrawdownPercent)%`` | ``$('{0:N2}' -f $row.ContinuousRecoveryFactor)`` | ``$('{0:N2}' -f $row.ContinuousCagrPercent)%`` | rejected |")
}
$md.Add('')
$md.Add("The center lost ``$(Format-Money $center.Continuous2015To2020Net)`` at PF ``$('{0:N2}' -f $center.ContinuousProfitFactor)`` with only ``$($center.ContinuousTrades)`` trades. The highest continuous result, ``$($best.Candidate)``, made only ``$(Format-Money $best.Continuous2015To2020Net)`` over six years with ``$($best.ContinuousTrades)`` trades and lost the 2019-2020 era. The completed-D1 narrow-range / fresh-H1 breakout hypothesis therefore lacks both repeatability and sufficient sample size.")
$md.Add('')
$md.Add('## Decision')
$md.Add('')
$md.Add('- Reject this NR7 / H1 breakout neighborhood; do not tune it on recent data.')
$md.Add('- Skip holdout and Model 4 because the broad pre-2021 gate failed.')
$md.Add('- Do not merge the engine into the frozen forward candidate.')
$md.Add('- Preserve the registered source/profile/binary identity, evidence logs, and hard real-account lock unchanged.')
$md.Add('')
$md.Add('## Evidence')
$md.Add('')
$md.Add('- `outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_PACKAGE.md`')
$md.Add('- `outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RESULTS.csv`')
$md.Add('- `outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RUN.csv`')
$md.Add('- `outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_DECISION.csv`')
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
