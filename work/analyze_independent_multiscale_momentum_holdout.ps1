param(
   [string]$DiscoveryResultsPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$HoldoutResultsPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_MODEL1_RESULTS.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Format-Dollar([double]$Value) {
   if($Value -lt 0) { return ('-${0:N2}' -f [math]::Abs($Value)) }
   return ('+${0:N2}' -f $Value)
}

$discovery = @(Import-Csv -LiteralPath (Resolve-RepoPath $DiscoveryResultsPath))
$holdout = @(Import-Csv -LiteralPath (Resolve-RepoPath $HoldoutResultsPath))
if($discovery.Count -ne 21) { throw "Expected 21 discovery rows." }
if($holdout.Count -ne 16) { throw "Expected 16 holdout rows." }

$rows = @($holdout | Group-Object Candidate | ForEach-Object {
   $candidate = $_.Name
   $discoveryContinuous = $discovery | Where-Object {$_.Candidate -eq $candidate -and $_.Window -eq "continuous_2015_2020"}
   $early = $_.Group | Where-Object Window -eq "holdout_2021_2023"
   $recent = $_.Group | Where-Object Window -eq "holdout_2024_present"
   $combined = $_.Group | Where-Object Window -eq "holdout_2021_present"
   $full = $_.Group | Where-Object Window -eq "continuous_2015_present"
   if(@($discoveryContinuous).Count -ne 1 -or @($early).Count -ne 1 -or @($recent).Count -ne 1 -or
      @($combined).Count -ne 1 -or @($full).Count -ne 1) { throw "Incomplete evidence for $candidate." }
   $passes = [double]$early.NetProfit -gt 0 -and [double]$recent.NetProfit -gt 0 -and
      [double]$combined.ProfitFactor -ge 1.20 -and [int]$combined.TotalTrades -ge 100 -and
      [double]$combined.MaxDrawdownPercent -le 5.00 -and [double]$full.ProfitFactor -ge 1.20
   [pscustomobject]@{
      Candidate=$candidate
      Discovery2015To2020Net=[double]$discoveryContinuous.NetProfit
      Discovery2015To2020PF=[double]$discoveryContinuous.ProfitFactor
      Holdout2021To2023Net=[double]$early.NetProfit
      Holdout2021To2023PF=[double]$early.ProfitFactor
      Holdout2024To2026Net=[double]$recent.NetProfit
      Holdout2024To2026PF=[double]$recent.ProfitFactor
      Holdout2021To2026Net=[double]$combined.NetProfit
      Holdout2021To2026PF=[double]$combined.ProfitFactor
      HoldoutTrades=[int]$combined.TotalTrades
      HoldoutDrawdownPercent=[double]$combined.MaxDrawdownPercent
      Full2015To2026Net=[double]$full.NetProfit
      Full2015To2026PF=[double]$full.ProfitFactor
      Full2015To2026CAGRPercent=[double]$full.CagrPercent
      Full2015To2026DrawdownPercent=[double]$full.MaxDrawdownPercent
      GatePass=$passes
      Decision=if($passes) { "ADVANCE_TO_MODEL4" } else { "REJECT_BEFORE_MODEL4" }
   }
} | Sort-Object Full2015To2026Net -Descending)

$rows | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$passCount = @($rows | Where-Object GatePass -eq $true).Count
$sourceHash = (Get-FileHash -LiteralPath (Join-Path $repo "work\Independent_XAUUSD_Multiscale_Momentum.mq5") -Algorithm SHA256).Hash
$profileHashes = @($holdout | Group-Object Candidate | ForEach-Object {
   $hashes = @($_.Group | Select-Object -ExpandProperty ProfileSha256 -Unique)
   if($hashes.Count -ne 1) { throw "Profile identity changed within holdout for $($_.Name)." }
   "$($_.Name): $($hashes[0])"
})

$lines = @(
   "# Independent Multiscale Momentum Holdout Decision",
   "",
   "**Decision: REJECTED BEFORE MODEL4.**",
   "",
   "The four-profile plateau passed the registered 2015-2020 discovery gate, then every profile lost money in the disjoint 2021-2023 holdout. All four were profitable in 2024 through July 16, 2026, demonstrating why recent-period profit alone is not evidence of future robustness.",
   "",
   "## Frozen gate",
   "",
   "Before Model4, a profile required positive net profit in both 2021-2023 and 2024-2026, 2021-2026 PF >= 1.20, at least 100 holdout trades, holdout drawdown <= 5%, full-history PF >= 1.20, and an adjacent survivor. Passed: **$passCount of $($rows.Count)**.",
   "",
   "| Profile | 2015-20 net / PF | 2021-23 net / PF | 2024-26 net / PF | 2021-26 net / PF | Full net / PF | Full CAGR | Full DD | Decision |",
   "|---|---:|---:|---:|---:|---:|---:|---:|---|"
)
foreach($row in $rows) {
   $lines += "| ``$($row.Candidate)`` | $(Format-Dollar $row.Discovery2015To2020Net) / $('{0:N2}' -f $row.Discovery2015To2020PF) | $(Format-Dollar $row.Holdout2021To2023Net) / $('{0:N2}' -f $row.Holdout2021To2023PF) | $(Format-Dollar $row.Holdout2024To2026Net) / $('{0:N2}' -f $row.Holdout2024To2026PF) | $(Format-Dollar $row.Holdout2021To2026Net) / $('{0:N2}' -f $row.Holdout2021To2026PF) | $(Format-Dollar $row.Full2015To2026Net) / $('{0:N2}' -f $row.Full2015To2026PF) | $('{0:N2}' -f $row.Full2015To2026CAGRPercent)% | $('{0:N2}' -f $row.Full2015To2026DrawdownPercent)% | $($row.Decision) |"
}
$lines += @(
   "",
   "## Interpretation",
   "",
   "- The recent gold regime favored the logic, but 2021-2023 did not. The family is regime-dependent rather than future-ready.",
   "- The best full-history result was only `$377.10` from a `$10,000` starting balance, or 0.32% CAGR at 0.10% risk per trade.",
   "- Raising risk would multiply both profit and drawdown but would not repair the losing holdout or PF failure.",
   "- No Model4 run is justified because the faster registered gate already failed.",
   "",
   "## Identity",
   "",
   "- Source SHA-256: ``$sourceHash``"
)
foreach($identity in $profileHashes) { $lines += "- $identity" }
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{ Decision="REJECTED_BEFORE_MODEL4"; Profiles=$rows.Count; Passed=$passCount; DecisionCsv=$DecisionCsvPath; DecisionMarkdown=$DecisionMarkdownPath }
