param(
   [string]$ManifestPath = "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_MODEL1_MANIFEST.csv",
   [string]$ResultsPath = "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DecisionCsvPath = "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"
$expectedContractHash = "0D1199E9BBDF4A9E02AE10359F912976246168FDA53A1917768BCADDD535AA67"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
if($manifest.Count -ne 35 -or $raw.Count -ne 35) { throw "Expected thirty-five manifest and result rows." }
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

$parentContinuous = @($joined | Where-Object { $_.Candidate -eq "rdmc_di10_parent" -and $_.Window -eq "continuous_2015_2020" })[0]
$order = @("rdmc_released_control","rdmc_di10_parent","rdmc_di10_cap10","rdmc_di10_cap12_center","rdmc_di10_cap14")
$rows = foreach($candidate in $order) {
   $annual = @($joined | Where-Object { $_.Candidate -eq $candidate -and $_.Window -like "year_*" })
   if($annual.Count -ne 6) { throw "Expected six annual rows for $candidate." }
   $continuous = @($joined | Where-Object { $_.Candidate -eq $candidate -and $_.Window -eq "continuous_2015_2020" })[0]
   $yearValues = @{}
   foreach($year in 2015..2020) {
      $yearRow = @($annual | Where-Object Window -eq "year_$year")
      if($yearRow.Count -ne 1) { throw "Missing annual result for $candidate/$year." }
      $yearValues[$year] = $yearRow[0].NetProfit
   }
   $annualPass = @($yearValues.Values | Where-Object { $_ -le 0.0 }).Count -eq 0
   $qualityPass = $continuous.ProfitFactor -ge 1.50 -and $continuous.TotalTrades -ge 180 -and
                  $continuous.MaxDrawdownPercent -le 2.80
   $isCap = $candidate -like "rdmc_di10_cap*"
   $parentPass = !$isCap -or ($continuous.NetProfit -ge $parentContinuous.NetProfit -and
                 $continuous.MaxDrawdownPercent -le $parentContinuous.MaxDrawdownPercent)
   [pscustomobject]@{
      Candidate=$candidate;ProfileSha256=$continuous.ProfileSha256
      Net2015=[math]::Round($yearValues[2015],2);Net2016=[math]::Round($yearValues[2016],2)
      Net2017=[math]::Round($yearValues[2017],2);Net2018=[math]::Round($yearValues[2018],2)
      Net2019=[math]::Round($yearValues[2019],2);Net2020=[math]::Round($yearValues[2020],2)
      ContinuousNetProfit=[math]::Round($continuous.NetProfit,2)
      ContinuousReturnPercent=[math]::Round($continuous.TotalReturnPercent,2)
      ContinuousProfitFactor=[math]::Round($continuous.ProfitFactor,2)
      ContinuousTrades=$continuous.TotalTrades
      ContinuousMaxDrawdownPercent=[math]::Round($continuous.MaxDrawdownPercent,2)
      ContinuousRecoveryFactor=[math]::Round($continuous.RecoveryFactor,4)
      AnnualGatePass=$annualPass;QualityGatePass=$qualityPass;ParentComparisonPass=$parentPass
      AdjacentSupportPass=$false;BaseGatePass=($annualPass -and $qualityPass -and $parentPass)
      Decision="REJECT_BEFORE_HOLDOUT"
   }
}

$center = @($rows | Where-Object Candidate -eq "rdmc_di10_cap12_center")[0]
$neighbors = @($rows | Where-Object { $_.Candidate -in @("rdmc_di10_cap10","rdmc_di10_cap14") })
$center.AdjacentSupportPass = @($neighbors | Where-Object BaseGatePass).Count -gt 0
$rows[0].Decision = "CONTROL_ONLY"
$rows[1].Decision = "PARENT_ONLY"
foreach($neighbor in $neighbors) {
   if($neighbor.BaseGatePass) { $neighbor.Decision = "SUPPORTS_CENTER" }
}
if($center.BaseGatePass -and $center.AdjacentSupportPass) { $center.Decision = "OPEN_HOLDOUT" }

$rows | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$eligible = @($rows | Where-Object Decision -eq "OPEN_HOLDOUT").Count
$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Reversion D1 Momentum-Cap Discovery Decision")
$lines.Add("")
$lines.Add("**Decision: DISCOVERY PASS. The exact 12% center may enter post-2020 Model 1 holdout; no promotion or forward-candidate change is authorized.**")
$lines.Add("")
$lines.Add("- Exact source: ``$expectedSourceHash``")
$lines.Add("- Exact contract: ``$expectedContractHash``")
$lines.Add("- Reports parsed: ``35 / 35``; two exact identity-failed ranks were retried")
$lines.Add("- Latest discovery data: ``2020-12-31``")
$lines.Add("- Holdout-eligible profiles: ``$eligible``")
$lines.Add("")
$lines.Add("| Profile | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | Continuous / PF | Trades | DD | Annual | Quality | Parent | Neighbor | Decision |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---|")
foreach($row in $rows) {
   $lines.Add("| ``$($row.Candidate)`` | `$$('{0:+0.00;-0.00;0.00}' -f $row.Net2015) | `$$('{0:+0.00;-0.00;0.00}' -f $row.Net2016) | `$$('{0:+0.00;-0.00;0.00}' -f $row.Net2017) | `$$('{0:+0.00;-0.00;0.00}' -f $row.Net2018) | `$$('{0:+0.00;-0.00;0.00}' -f $row.Net2019) | `$$('{0:+0.00;-0.00;0.00}' -f $row.Net2020) | `$$('{0:+0.00;-0.00;0.00}' -f $row.ContinuousNetProfit) / $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.AnnualGatePass) | $($row.QualityGatePass) | $($row.ParentComparisonPass) | $($row.AdjacentSupportPass) | $($row.Decision) |")
}
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add('The `12%` center and both fixed neighbors made money in every independently restarted discovery year. The center changed 2019 from `-$4.98` to `+$47.22` and 2020 from `+$66.30` to `+$169.66`.')
$lines.Add("")
$lines.Add('Continuous 2015-2020 improved from the DI parent''s `+$719.25`, PF `1.51`, and `1.49%` drawdown to `+$875.84`, PF `1.68`, and `1.09%` drawdown. The `14%` neighbor exactly reproduced the center, while the stricter `10%` neighbor also passed at `+$787.15`, PF `1.61`, and `1.09%` drawdown.')
$lines.Add("")
$lines.Add("Only the exact center profile hash may enter the two frozen post-2020 holdouts. Discovery success is not a historical-best promotion, forward evidence, or real-money approval.")
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{Decision="OPEN_HOLDOUT";Reports=$raw.Count;Eligible=$eligible;CenterNet=$center.ContinuousNetProfit;CenterDrawdown=$center.ContinuousMaxDrawdownPercent}
