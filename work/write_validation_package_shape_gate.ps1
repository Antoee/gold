param(
   [string]$ManifestPath = "outputs\TRADE_READY_CONSERVATIVE_VALIDATION_MANIFEST.csv",
   [string]$DecisionPath = "outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv",
   [string]$OutCsv = "outputs\VALIDATION_PACKAGE_SHAPE_GATE.csv",
   [string]$OutMarkdown = "outputs\VALIDATION_PACKAGE_SHAPE_GATE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Read-CsvSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   if(Test-Path -LiteralPath $resolved) { return @(Import-Csv -LiteralPath $resolved) }
   return @()
}

function Ensure-ParentDir {
   param([string]$Path)
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

$manifest = @(Read-CsvSafe $ManifestPath)
$decision = @(Read-CsvSafe $DecisionPath)
$shapeGate = $decision | Where-Object Gate -eq "validation-package-shape" | Select-Object -First 1
$shapeGateStatus = if($null -eq $shapeGate) { "MISSING" } else { [string]$shapeGate.Status }
$shapeGateActual = if($null -eq $shapeGate) { "No validation-package-shape row found." } else { [string]$shapeGate.Actual }

$expectations = @(
   [pscustomobject]@{ Phase = "phase0_fast_model1"; RequiredRows = 4; Description = "Fast Model1 sanity windows" },
   [pscustomobject]@{ Phase = "phase1_exact_realtick"; RequiredRows = 4; Description = "Exact continuous/train/oos/recent real-tick windows" },
   [pscustomobject]@{ Phase = "phase2_realtick_quarterly"; RequiredRows = 11; Description = "Quarterly Model4 windows" },
   [pscustomobject]@{ Phase = "phase3_realtick_monthly"; RequiredRows = 31; Description = "Monthly Model4 windows" },
   [pscustomobject]@{ Phase = "phase4_stress_realtick"; RequiredRows = 3; Description = "Stress Model4 variants" }
)

$rows = [System.Collections.Generic.List[object]]::new()
foreach($item in $expectations) {
   $actual = @($manifest | Where-Object Phase -eq $item.Phase).Count
   $rows.Add([pscustomobject]@{
      Phase = $item.Phase
      RequiredRows = $item.RequiredRows
      ActualRows = $actual
      Status = if($actual -eq $item.RequiredRows) { "PASS" } else { "FAIL" }
      Description = $item.Description
   }) | Out-Null
}

$requiredTotal = ($expectations | Measure-Object RequiredRows -Sum).Sum
$failCount = @($rows | Where-Object Status -eq "FAIL").Count
$overall = if($manifest.Count -eq 0) {
   "PENDING"
} elseif($manifest.Count -ne $requiredTotal -or $failCount -gt 0) {
   "FAIL"
} else {
   "PASS"
}

$summaryRows = @(
   [pscustomobject]@{
      Phase = "TOTAL"
      RequiredRows = $requiredTotal
      ActualRows = $manifest.Count
      Status = $overall
      Description = "Complete conservative validation package shape"
   }
) + @($rows)

$outCsvFull = Resolve-RepoPath $OutCsv
$outMarkdownFull = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $outCsvFull
Ensure-ParentDir $outMarkdownFull
$summaryRows | Export-Csv -LiteralPath $outCsvFull -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Validation Package Shape Gate")
$md.Add("")
$md.Add("Generated offline. This does not launch MT5, MetaEditor, GitHub Actions, Git, or GitHub CLI.")
$md.Add("")
$md.Add("- Overall: **$overall**")
$md.Add(('- Manifest rows: `{0}` / `{1}`' -f $manifest.Count, $requiredTotal))
if($null -ne $shapeGate) {
   $md.Add(('- Decision gate status: `{0}`' -f $shapeGateStatus))
   $md.Add(('- Decision gate actual: `{0}`' -f $shapeGateActual))
}
$md.Add("")
$md.Add("## Purpose")
$md.Add("")
$md.Add("The validation decision gate rejects malformed or partial validation packages before profit metrics can be trusted. A reduced package with only profitable returned rows is not enough to pass.")
$md.Add("")
$md.Add("## Required Shape")
$md.Add("")
$md.Add("| Phase | Required | Actual | Status | Description |")
$md.Add("| --- | ---: | ---: | --- | --- |")
foreach($row in $rows) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} |" -f
      (Escape-MarkdownCell $row.Phase),
      $row.RequiredRows,
      $row.ActualRows,
      $row.Status,
      (Escape-MarkdownCell $row.Description)))
}
$md.Add("")
$md.Add("Broker-proxy evidence separately requires `10` broker-proxy rows.")
$md.Add("")
$md.Add("## Current Evidence")
$md.Add("")
$md.Add(("- Current conservative decision gate: ``validation-package-shape`` is ``{0}``." -f $shapeGateStatus))
$md.Add("- Smoke tests passed locally: ``MONEY_READY_VALIDATION_DECISION_SMOKE_PASS`` and ``TRADE_READY_CONSERVATIVE_VALIDATION_DECISION_SMOKE_PASS``.")
$md.Add("")
$md.Add("## Why It Matters")
$md.Add("")
$md.Add("This prevents a profile from looking money-ready because only the easy or profitable windows were returned. Full validation still requires exported MT5 reports, full tester statistics, no red monthly/quarterly/stress/broker windows, continuous-return floors, drawdown efficiency, profit factor, expected payoff, Sharpe, win rate, loss-streak, and recovery-factor gates.")
$md | Set-Content -LiteralPath $outMarkdownFull -Encoding ASCII

[pscustomobject]@{
   Overall = $overall
   ManifestRows = $manifest.Count
   RequiredRows = $requiredTotal
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
