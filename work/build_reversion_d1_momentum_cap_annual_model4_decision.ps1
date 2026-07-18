param(
   [string]$ResultsPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_RESULTS.csv",
   [string]$DecisionCsvPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"
$expectedProfileHash = "BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC"
$expectedAnnualContractHash = "77AF52DAD7DF99F2AC4BD4340A3B20AD78F4DCB89EAAE59F941F0384402F4087"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
if($results.Count -ne 12 -or @($results | Where-Object Status -ne "PARSED").Count -gt 0) { throw "Expected twelve parsed annual Model4 results." }
if(@($results.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].SourceSha256 -ne $expectedSourceHash) { throw "Source identity mismatch." }
if(@($results.ProfileSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].ProfileSha256 -ne $expectedProfileHash) { throw "Profile identity mismatch." }
if(@($results.AnnualContractSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].AnnualContractSha256 -ne $expectedAnnualContractHash) { throw "Annual contract mismatch." }

$rows = foreach($result in $results | Sort-Object From) {
   [pscustomobject]@{
      Window=$result.Window;From=$result.From;To=$result.To
      NetProfit=[math]::Round([double]$result.NetProfit,2)
      ReturnPercent=[math]::Round([double]$result.TotalReturnPercent,2)
      ProfitFactor=[math]::Round([double]$result.ProfitFactor,2)
      Trades=[int]$result.TotalTrades
      MaxDrawdownPercent=[math]::Round([double]$result.MaxDrawdownPercent,2)
      MaxConsecutiveLosses=[int]$result.MaxConsecutiveLosses
      RecoveryFactor=[math]::Round([double]$result.RecoveryFactor,4)
      NonNegativePass=([double]$result.NetProfit -ge 0.0)
      DrawdownPass=([double]$result.MaxDrawdownPercent -le 2.50)
      LossStreakPass=([int]$result.MaxConsecutiveLosses -le 8)
   }
}
$positiveYears = @($rows | Where-Object NetProfit -gt 0.0).Count
$negativeYears = @($rows | Where-Object NetProfit -lt 0.0).Count
$summedTrades = [int](($rows | Measure-Object Trades -Sum).Sum)
$summedNet = [math]::Round([double](($rows | Measure-Object NetProfit -Sum).Sum),2)
$noNegativePass = $negativeYears -eq 0
$positiveCountPass = $positiveYears -ge 10
$activityPass = $summedTrades -ge 300
$drawdownPass = @($rows | Where-Object DrawdownPass -eq $false).Count -eq 0
$lossStreakPass = @($rows | Where-Object LossStreakPass -eq $false).Count -eq 0
$overallPass = $noNegativePass -and $positiveCountPass -and $activityPass -and $drawdownPass -and $lossStreakPass
$rows | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Reversion D1 Momentum-Cap Annual Model4 Decision")
$lines.Add("")
$lines.Add("**Decision: MONEY-READINESS FAIL. The stability candidate is retained for research, but cost and Monte Carlo stress remain closed and the forward candidate is unchanged.**")
$lines.Add("")
$lines.Add("- Exact source: ``$expectedSourceHash``")
$lines.Add("- Exact profile: ``$expectedProfileHash``")
$lines.Add("- Exact annual contract: ``$expectedAnnualContractHash``")
$lines.Add("- Reports parsed: ``12 / 12``; one exact identity-failed rank was retried")
$lines.Add("- Positive years: ``$positiveYears / 12``")
$lines.Add("- Negative years: ``$negativeYears / 12``")
$lines.Add("- Summed annual robustness score: ``$summedNet USD`` on ``$summedTrades`` trades")
$lines.Add("")
$lines.Add("| Year | Net | Return | PF | Trades | DD | Loss streak | Recovery | Non-red |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---:|---|")
foreach($row in $rows) {
   $lines.Add("| ``$($row.Window)`` | `$$('{0:+0.00;-0.00;0.00}' -f $row.NetProfit) | $($row.ReturnPercent)% | $($row.ProfitFactor) | $($row.Trades) | $($row.MaxDrawdownPercent)% | $($row.MaxConsecutiveLosses) | $($row.RecoveryFactor) | $($row.NonNegativePass) |")
}
$lines.Add("")
$lines.Add("## Gate")
$lines.Add("")
$lines.Add("- No negative year: ``$noNegativePass``")
$lines.Add("- At least 10 positive years: ``$positiveCountPass``")
$lines.Add("- At least 300 summed trades: ``$activityPass``")
$lines.Add("- Every annual drawdown no more than 2.50%: ``$drawdownPass``")
$lines.Add("- Every annual loss streak no more than eight: ``$lossStreakPass``")
$lines.Add("")
$lines.Add('The center is unusually stable on the continuous path and passes Model 1 holdout plus Model 4 transfer, but annual restarts expose `-$3.77` in 2019 and `-$92.78` in 2022. Better aggregate profit cannot override the frozen no-red-year requirement.')
$lines.Add("")
$lines.Add("This profile is not money-ready and is not substituted into the registered forward run.")
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{Decision=if($overallPass){"OPEN_STRESS"}else{"STOP_MONEY_READINESS"};PositiveYears=$positiveYears;NegativeYears=$negativeYears;SummedNet=$summedNet;SummedTrades=$summedTrades}
