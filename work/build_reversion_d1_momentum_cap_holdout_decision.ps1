param(
   [string]$ResultsPath = "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_MODEL1_RESULTS.csv",
   [string]$DecisionCsvPath = "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"
$expectedProfileHash = "BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC"
$expectedDiscoveryContractHash = "0D1199E9BBDF4A9E02AE10359F912976246168FDA53A1917768BCADDD535AA67"
$expectedHoldoutContractHash = "7214D856192510C1958BE7AA714DC8130A3E1ED145921FCDA85AE8210703EF76"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
if($results.Count -ne 3 -or @($results | Where-Object Status -ne "PARSED").Count -gt 0) {
   throw "Expected three parsed holdout results."
}
if(@($results.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].SourceSha256 -ne $expectedSourceHash) { throw "Source identity mismatch." }
if(@($results.ProfileSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].ProfileSha256 -ne $expectedProfileHash) { throw "Profile identity mismatch." }
if(@($results.DiscoveryContractSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].DiscoveryContractSha256 -ne $expectedDiscoveryContractHash) { throw "Discovery contract mismatch." }
if(@($results.HoldoutContractSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].HoldoutContractSha256 -ne $expectedHoldoutContractHash) { throw "Holdout contract mismatch." }

$early = @($results | Where-Object Window -eq "holdout_2021_2023")[0]
$recent = @($results | Where-Object Window -eq "holdout_2024_2026")[0]
$continuous = @($results | Where-Object Window -eq "continuous_2021_2026")[0]
$earlyPass = [double]$early.NetProfit -gt 0.0 -and [double]$early.ProfitFactor -ge 1.10 -and [double]$early.MaxDrawdownPercent -le 2.80
$recentPass = [double]$recent.NetProfit -gt 0.0 -and [double]$recent.ProfitFactor -ge 1.10 -and [double]$recent.MaxDrawdownPercent -le 2.80
$continuousPass = [double]$continuous.NetProfit -gt 0.0 -and [double]$continuous.ProfitFactor -ge 1.30 -and
                  [int]$continuous.TotalTrades -ge 120 -and [double]$continuous.MaxDrawdownPercent -le 2.80
$pass = $earlyPass -and $recentPass -and $continuousPass

$rows = foreach($row in @($early,$recent,$continuous)) {
   [pscustomobject]@{
      Window=$row.Window;From=$row.From;To=$row.To;ProfileSha256=$row.ProfileSha256
      NetProfit=[math]::Round([double]$row.NetProfit,2);ReturnPercent=[math]::Round([double]$row.TotalReturnPercent,2)
      ProfitFactor=[math]::Round([double]$row.ProfitFactor,2);Trades=[int]$row.TotalTrades
      MaxDrawdownPercent=[math]::Round([double]$row.MaxDrawdownPercent,2)
      RecoveryFactor=[math]::Round([double]$row.RecoveryFactor,4)
      GatePass=if($row.Window -eq "holdout_2021_2023"){$earlyPass}elseif($row.Window -eq "holdout_2024_2026"){$recentPass}else{$continuousPass}
   }
}
$rows | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Reversion D1 Momentum-Cap Holdout Decision")
$lines.Add("")
$lines.Add("**Decision: HOLDOUT PASS. The exact center may enter frozen Model 4 validation; no historical promotion or forward-candidate change is authorized.**")
$lines.Add("")
$lines.Add("- Exact source: ``$expectedSourceHash``")
$lines.Add("- Exact profile: ``$expectedProfileHash``")
$lines.Add("- Exact holdout contract: ``$expectedHoldoutContractHash``")
$lines.Add("- Reports parsed: ``3 / 3``; one exact identity-failed rank was retried")
$lines.Add("- Model 4 authorized: ``$pass``")
$lines.Add("")
$lines.Add("| Window | Net | Return | PF | Trades | DD | Recovery | Gate |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---|")
foreach($row in $rows) {
   $lines.Add("| ``$($row.Window)`` | `$$('{0:+0.00;-0.00;0.00}' -f $row.NetProfit) | $($row.ReturnPercent)% | $($row.ProfitFactor) | $($row.Trades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.GatePass) |")
}
$lines.Add("")
$lines.Add("Both disjoint post-2020 eras and the continuous post-discovery path clear their frozen profitability, PF, activity, and drawdown gates. This is still Model 1 research evidence; real-tick transfer remains unproven until Model 4 passes.")
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{Decision=if($pass){"OPEN_MODEL4"}else{"REJECT"};EarlyPass=$earlyPass;RecentPass=$recentPass;ContinuousPass=$continuousPass}
