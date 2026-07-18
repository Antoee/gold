param(
   [string]$ManifestPath = "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_MODEL1_MANIFEST.csv",
   [string]$ResultsPath = "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_MODEL1_RESULTS.csv",
   [string]$DecisionCsvPath = "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "7E8D680807B0565992ECC9B98E15C636A86AF34742194687DBB64D61CE2EFD7A"
$expectedContractHash = "6477C8F3D87B355F5AF397B5B6EE47D058108978EA8BAB95B3366A9D1C7278DE"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
if($manifest.Count -ne 8 -or $raw.Count -ne 8) { throw "Expected eight manifest and result rows." }
if(@($raw | Where-Object Status -ne "PARSED").Count -gt 0) { throw "Every report must parse before decision." }
if(@($manifest.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $manifest[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected source identity."
}
if(@($manifest.ContractSha256 | Sort-Object -Unique).Count -ne 1 -or $manifest[0].ContractSha256 -ne $expectedContractHash) {
   throw "Unexpected contract identity."
}

$joined = foreach($item in $manifest) {
   $matches = @($raw | Where-Object ExpectedReportName -eq $item.ExpectedReportName)
   if($matches.Count -ne 1) { throw "Result missing or ambiguous: $($item.ExpectedReportName)" }
   [pscustomobject]@{
      Candidate=$item.Candidate;Window=$item.Window;ProfileSha256=$item.ProfileSha256
      NetProfit=[double]$matches[0].NetProfit;ProfitFactor=[double]$matches[0].ProfitFactor
      TotalTrades=[int]$matches[0].TotalTrades;MaxDrawdownPercent=[double]$matches[0].MaxDrawdownPercent
      TotalReturnPercent=[double]$matches[0].TotalReturnPercent;RecoveryFactor=[double]$matches[0].RecoveryFactor
   }
}

$controlContinuous = @($joined | Where-Object { $_.Candidate -eq "rld_fixed_control" -and $_.Window -eq "continuous_2015_2020" })[0]
$order = @("rld_fixed_control","rld_m12","rld_m10","rld_m8")
$rows = foreach($candidate in $order) {
   $repair = @($joined | Where-Object { $_.Candidate -eq $candidate -and $_.Window -eq "repair_2019_2020" })[0]
   $continuous = @($joined | Where-Object { $_.Candidate -eq $candidate -and $_.Window -eq "continuous_2015_2020" })[0]
   $basic = $repair.NetProfit -gt 0.0 -and $continuous.ProfitFactor -ge 1.45 -and
            $continuous.TotalTrades -ge 180 -and $continuous.MaxDrawdownPercent -le 2.80
   $quality = $continuous.NetProfit -ge $controlContinuous.NetProfit -and
              $continuous.MaxDrawdownPercent -le $controlContinuous.MaxDrawdownPercent
   [pscustomobject]@{
      Candidate=$candidate;ProfileSha256=$continuous.ProfileSha256
      RepairNetProfit=[math]::Round($repair.NetProfit,2)
      ContinuousNetProfit=[math]::Round($continuous.NetProfit,2)
      ContinuousReturnPercent=[math]::Round($continuous.TotalReturnPercent,2)
      ContinuousProfitFactor=[math]::Round($continuous.ProfitFactor,2)
      ContinuousTrades=$continuous.TotalTrades
      ContinuousMaxDrawdownPercent=[math]::Round($continuous.MaxDrawdownPercent,2)
      ContinuousRecoveryFactor=[math]::Round($continuous.RecoveryFactor,4)
      BasicGatePass=$basic;QualityGatePass=$quality;AdjacentPass=$false
      Decision=if($candidate -eq "rld_fixed_control") { "CONTROL_ONLY" } else { "REJECT_BEFORE_HOLDOUT" }
   }
}

for($i = 1; $i -lt $rows.Count; ++$i) {
   $neighbors = @()
   if($i -gt 1) { $neighbors += $rows[$i - 1] }
   if($i -lt $rows.Count - 1) { $neighbors += $rows[$i + 1] }
   $rows[$i].AdjacentPass = @($neighbors | Where-Object { $_.BasicGatePass -and $_.QualityGatePass }).Count -gt 0
}

$rows | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Reversion Long-Distance Guard Repair Decision")
$lines.Add("")
$lines.Add("**Decision: REJECTED IN REPAIR. The frozen forward candidate and real-account lock are unchanged.**")
$lines.Add("")
$lines.Add("- Exact source: ``$expectedSourceHash``")
$lines.Add("- Exact contract: ``$expectedContractHash``")
$lines.Add("- Reports parsed: ``8 / 8``; no identity retry")
$lines.Add("- Repair-eligible profiles: ``0``")
$lines.Add("")
$lines.Add("| Profile | 2019-20 net | Continuous net | Return | PF | Trades | DD | Recovery | Basic | Quality | Neighbor | Decision |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|")
foreach($row in $rows) {
   $lines.Add("| ``$($row.Candidate)`` | `$$('{0:+0.00;-0.00;0.00}' -f $row.RepairNetProfit) | `$$('{0:+0.00;-0.00;0.00}' -f $row.ContinuousNetProfit) | $($row.ContinuousReturnPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.ContinuousRecoveryFactor) | $($row.BasicGatePass) | $($row.QualityGatePass) | $($row.AdjacentPass) | $($row.Decision) |")
}
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add('The `-10` and `-8 ATR` guards removed one 2019-2020 reversion stop-out and improved that window by `$39.30`, but both still lost `-$66.15`. The `-12 ATR` neighbor changed no weak-era trade. A better continuous PF cannot override a losing protected era.')
$lines.Add("")
$lines.Add("The family is closed before post-2020 holdout and Model 4. No threshold may be moved after this result.")
$lines.Add("")
$lines.Add("This rejection is research evidence, not forward evidence or real-money approval.")
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Decision="REJECT_BEFORE_HOLDOUT";Reports=$raw.Count;Eligible=0
   BestRepairNet=($rows | Where-Object Candidate -ne "rld_fixed_control" | Measure-Object RepairNetProfit -Maximum).Maximum
}
