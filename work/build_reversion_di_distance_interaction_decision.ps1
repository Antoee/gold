param(
   [string]$ManifestPath = "outputs\REVERSION_DI_DISTANCE_INTERACTION_DISCOVERY_MODEL1_MANIFEST.csv",
   [string]$ResultsPath = "outputs\REVERSION_DI_DISTANCE_INTERACTION_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DecisionCsvPath = "outputs\REVERSION_DI_DISTANCE_INTERACTION_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\REVERSION_DI_DISTANCE_INTERACTION_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "7E8D680807B0565992ECC9B98E15C636A86AF34742194687DBB64D61CE2EFD7A"
$expectedContractHash = "875BFDDD2F2A3A3A91B9CEA2A621B7854DAFDD71385D209995AED0F13878270B"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
if($manifest.Count -ne 20 -or $raw.Count -ne 20) { throw "Expected twenty manifest and result rows." }
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

$parentContinuous = @($joined | Where-Object { $_.Candidate -eq "rddi_di10_parent" -and $_.Window -eq "continuous_2015_2020" })[0]
$order = @("rddi_released_control","rddi_di10_parent","rddi_di10_m12","rddi_di10_m10_center","rddi_di10_m8")
$rows = foreach($candidate in $order) {
   $older = @($joined | Where-Object { $_.Candidate -eq $candidate -and $_.Window -eq "older_2015_2018" })[0]
   $y2019 = @($joined | Where-Object { $_.Candidate -eq $candidate -and $_.Window -eq "repair_2019" })[0]
   $y2020 = @($joined | Where-Object { $_.Candidate -eq $candidate -and $_.Window -eq "repair_2020" })[0]
   $continuous = @($joined | Where-Object { $_.Candidate -eq $candidate -and $_.Window -eq "continuous_2015_2020" })[0]
   $eraPass = $older.NetProfit -gt 0.0 -and $y2019.NetProfit -gt 0.0 -and $y2020.NetProfit -gt 0.0
   $qualityPass = $continuous.ProfitFactor -ge 1.50 -and $continuous.TotalTrades -ge 180 -and
                  $continuous.MaxDrawdownPercent -le 2.80
   $isInteraction = $candidate -like "rddi_di10_m*"
   $parentPass = !$isInteraction -or ($continuous.NetProfit -ge $parentContinuous.NetProfit -and
                 $continuous.MaxDrawdownPercent -le $parentContinuous.MaxDrawdownPercent)
   [pscustomobject]@{
      Candidate=$candidate;ProfileSha256=$continuous.ProfileSha256
      OlderNetProfit=[math]::Round($older.NetProfit,2)
      NetProfit2019=[math]::Round($y2019.NetProfit,2);ProfitFactor2019=[math]::Round($y2019.ProfitFactor,2)
      NetProfit2020=[math]::Round($y2020.NetProfit,2);ProfitFactor2020=[math]::Round($y2020.ProfitFactor,2)
      ContinuousNetProfit=[math]::Round($continuous.NetProfit,2)
      ContinuousReturnPercent=[math]::Round($continuous.TotalReturnPercent,2)
      ContinuousProfitFactor=[math]::Round($continuous.ProfitFactor,2)
      ContinuousTrades=$continuous.TotalTrades
      ContinuousMaxDrawdownPercent=[math]::Round($continuous.MaxDrawdownPercent,2)
      ContinuousRecoveryFactor=[math]::Round($continuous.RecoveryFactor,4)
      EraGatePass=$eraPass;QualityGatePass=$qualityPass;ParentComparisonPass=$parentPass
      AdjacentSupportPass=$false;BaseGatePass=($eraPass -and $qualityPass -and $parentPass)
      Decision="REJECT_BEFORE_HOLDOUT"
   }
}

$center = @($rows | Where-Object Candidate -eq "rddi_di10_m10_center")[0]
$neighbors = @($rows | Where-Object { $_.Candidate -in @("rddi_di10_m12","rddi_di10_m8") })
$center.AdjacentSupportPass = @($neighbors | Where-Object BaseGatePass).Count -gt 0
$rows[0].Decision = "CONTROL_ONLY"
$rows[1].Decision = "PARENT_ONLY"
if($center.BaseGatePass -and $center.AdjacentSupportPass) { $center.Decision = "OPEN_HOLDOUT" }

$rows | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$eligible = @($rows | Where-Object Decision -eq "OPEN_HOLDOUT").Count
$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Reversion DI and Distance Interaction Discovery Decision")
$lines.Add("")
$lines.Add("**Decision: REJECTED BEFORE HOLDOUT. The frozen forward candidate and real-account lock are unchanged.**")
$lines.Add("")
$lines.Add("- Exact source: ``$expectedSourceHash``")
$lines.Add("- Exact contract: ``$expectedContractHash``")
$lines.Add("- Reports parsed: ``20 / 20``; three exact identity-failed ranks were retried")
$lines.Add("- Post-2020 reports opened: ``0``")
$lines.Add("- Holdout-eligible profiles: ``$eligible``")
$lines.Add("")
$lines.Add("| Profile | 2015-18 | 2019 / PF | 2020 / PF | Continuous / PF | Trades | DD | Era | Quality | Parent | Neighbor | Decision |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---|---|---|---|---|")
foreach($row in $rows) {
   $lines.Add("| ``$($row.Candidate)`` | `$$('{0:+0.00;-0.00;0.00}' -f $row.OlderNetProfit) | `$$('{0:+0.00;-0.00;0.00}' -f $row.NetProfit2019) / $($row.ProfitFactor2019) | `$$('{0:+0.00;-0.00;0.00}' -f $row.NetProfit2020) / $($row.ProfitFactor2020) | `$$('{0:+0.00;-0.00;0.00}' -f $row.ContinuousNetProfit) / $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.EraGatePass) | $($row.QualityGatePass) | $($row.ParentComparisonPass) | $($row.AdjacentSupportPass) | $($row.Decision) |")
}
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add('The fixed interaction improved the nominated center to `+$819.95`, PF `1.61`, and `1.47%` drawdown over continuous 2015-2020. It also kept 2020 profitable at `+$105.60`.')
$lines.Add("")
$lines.Add('It did not repair the other protected year: the center and both distance neighbors each returned exactly `-$4.98`, PF `0.98`, in 2019. The contract requires every broad era to be profitable, so better continuous statistics cannot open newer data.')
$lines.Add("")
$lines.Add("The family is closed before post-2020 holdout and Model 4. Neither threshold may move after this result.")
$lines.Add("")
$lines.Add("This rejection is research evidence, not forward evidence or real-money approval.")
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{Decision="REJECT_BEFORE_HOLDOUT";Reports=$raw.Count;Eligible=$eligible;Center2019Net=$center.NetProfit2019}
