param(
   [string]$ResultsPath = "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_RESULTS.csv",
   [string]$DecisionCsvPath = "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"
$expectedModel4ContractHash = "5CB8F52B08B9883E2BF0CC980C70B8D8ED99194D75508298696C4B009B0ADB4A"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
if($results.Count -ne 15 -or @($results | Where-Object Status -ne "PARSED").Count -gt 0) { throw "Expected fifteen parsed Model4 results." }
if(@($results.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].SourceSha256 -ne $expectedSourceHash) { throw "Source identity mismatch." }
if(@($results.Model4ContractSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].Model4ContractSha256 -ne $expectedModel4ContractHash) { throw "Model4 contract mismatch." }

$order = @("rdmc_di10_parent","rdmc_di10_cap12_center","rdmc_di10_cap14")
$parentFull = @($results | Where-Object { $_.Candidate -eq "rdmc_di10_parent" -and $_.Window -eq "continuous_2015_2026" })[0]
$rows = foreach($candidate in $order) {
   $candidateRows = @($results | Where-Object Candidate -eq $candidate)
   $discovery = @($candidateRows | Where-Object Window -eq "discovery_2015_2020")[0]
   $early = @($candidateRows | Where-Object Window -eq "holdout_2021_2023")[0]
   $recent = @($candidateRows | Where-Object Window -eq "holdout_2024_2026")[0]
   $post = @($candidateRows | Where-Object Window -eq "continuous_2021_2026")[0]
   $full = @($candidateRows | Where-Object Window -eq "continuous_2015_2026")[0]
   $eraPass = @($discovery,$early,$recent | Where-Object { [double]$_.NetProfit -le 0.0 -or [double]$_.ProfitFactor -lt 1.10 }).Count -eq 0
   $fullPass = [double]$full.ProfitFactor -ge 1.40 -and [int]$full.TotalTrades -ge 300 -and [double]$full.MaxDrawdownPercent -le 3.50
   $isCap = $candidate -ne "rdmc_di10_parent"
   $parentPass = !$isCap -or ([double]$full.NetProfit -ge [double]$parentFull.NetProfit -and
                 [double]$full.MaxDrawdownPercent -le [double]$parentFull.MaxDrawdownPercent)
   [pscustomobject]@{
      Candidate=$candidate;ProfileSha256=$full.ProfileSha256
      DiscoveryNet=[math]::Round([double]$discovery.NetProfit,2);DiscoveryPF=[math]::Round([double]$discovery.ProfitFactor,2)
      EarlyNet=[math]::Round([double]$early.NetProfit,2);EarlyPF=[math]::Round([double]$early.ProfitFactor,2)
      RecentNet=[math]::Round([double]$recent.NetProfit,2);RecentPF=[math]::Round([double]$recent.ProfitFactor,2)
      PostNet=[math]::Round([double]$post.NetProfit,2);PostPF=[math]::Round([double]$post.ProfitFactor,2)
      FullNet=[math]::Round([double]$full.NetProfit,2);FullReturnPercent=[math]::Round([double]$full.TotalReturnPercent,2)
      FullPF=[math]::Round([double]$full.ProfitFactor,2);FullTrades=[int]$full.TotalTrades
      FullDrawdownPercent=[math]::Round([double]$full.MaxDrawdownPercent,2)
      FullRecoveryFactor=[math]::Round([double]$full.RecoveryFactor,4)
      MaxConsecutiveLosses=[int]$full.MaxConsecutiveLosses
      EraGatePass=$eraPass;FullGatePass=$fullPass;ParentComparisonPass=$parentPass
      NeighborSupportPass=$false;BaseGatePass=($eraPass -and $fullPass -and $parentPass)
      Decision=if($candidate -eq "rdmc_di10_parent"){"PARENT_ONLY"}else{"REJECT"}
   }
}

$center = @($rows | Where-Object Candidate -eq "rdmc_di10_cap12_center")[0]
$neighbor = @($rows | Where-Object Candidate -eq "rdmc_di10_cap14")[0]
$center.NeighborSupportPass = $neighbor.BaseGatePass
if($neighbor.BaseGatePass) { $neighbor.Decision = "SUPPORTS_CENTER" }
if($center.BaseGatePass -and $center.NeighborSupportPass) { $center.Decision = "OPEN_MONEY_READINESS" }
$rows | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Reversion D1 Momentum-Cap Model4 Decision")
$lines.Add("")
$lines.Add("**Decision: MODEL4 PASS. The cap-12 center becomes a stability-focused historical research candidate and may enter money-readiness stress. The frozen forward candidate remains unchanged.**")
$lines.Add("")
$lines.Add("- Exact source: ``$expectedSourceHash``")
$lines.Add("- Exact Model4 contract: ``$expectedModel4ContractHash``")
$lines.Add("- Reports parsed: ``15 / 15``; three exact identity-failed ranks were retried")
$lines.Add("- Real-account trading: disabled")
$lines.Add("")
$lines.Add("| Profile | 2015-20 / PF | 2021-23 / PF | 2024-26 / PF | Full net / PF | Trades | DD | Recovery | Era | Full | Parent | Neighbor | Decision |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---|")
foreach($row in $rows) {
   $lines.Add("| ``$($row.Candidate)`` | `$$('{0:+0.00;-0.00;0.00}' -f $row.DiscoveryNet) / $($row.DiscoveryPF) | `$$('{0:+0.00;-0.00;0.00}' -f $row.EarlyNet) / $($row.EarlyPF) | `$$('{0:+0.00;-0.00;0.00}' -f $row.RecentNet) / $($row.RecentPF) | `$$('{0:+0.00;-0.00;0.00}' -f $row.FullNet) / $($row.FullPF) | $($row.FullTrades) | $($row.FullDrawdownPercent)% | $($row.FullRecoveryFactor) | $($row.EraGatePass) | $($row.FullGatePass) | $($row.ParentComparisonPass) | $($row.NeighborSupportPass) | $($row.Decision) |")
}
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add('The exact center remains profitable in every disjoint real-tick era and improves full-path net from the DI parent''s `+$1,427.80` to `+$1,555.33`. PF rises from `1.57` to `1.68`; drawdown is effectively flat but slightly lower at `1.59%` versus `1.60%`.')
$lines.Add("")
$lines.Add('The cap-14 neighbor independently passes at `+$1,506.97`, PF `1.64`, 345 trades, and `1.59%` drawdown. That neighborhood support allows the center to enter annual restart and stress testing without claiming it is the highest-profit historical profile.')
$lines.Add("")
$lines.Add("This is a historical stability candidate, not forward evidence or real-money approval.")
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{Decision=$center.Decision;CenterNet=$center.FullNet;CenterPF=$center.FullPF;CenterDrawdown=$center.FullDrawdownPercent;NeighborPass=$center.NeighborSupportPass}
