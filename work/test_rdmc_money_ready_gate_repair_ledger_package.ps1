$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$builder = Join-Path $PSScriptRoot 'build_rdmc_money_ready_gate_repair_ledger_stress.ps1'
$analyzer = Join-Path $PSScriptRoot 'analyze_rdmc_money_ready_gate_repair_ledger_stress.py'
$regression = Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_ledger_stress.py'
$core = Join-Path $PSScriptRoot 'rdmc_executable_ledger_stress_core.py'
$manifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_LEDGER_HARNESS_MANIFEST.csv'
$contractPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_STRESS_CONTRACT.md'
$decisionPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_STRESS_DECISION.csv'
$decisionMarkdownPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_STRESS_DECISION.md'
$testCsvPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_LEDGER_HARNESS_TESTS.csv'
$testMarkdownPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_LEDGER_HARNESS_TESTS.md'
$expected = @{
   analyzer = 'E6DBC4878EA7B4360705394F9E659B566EBAD739E7F0C2A6D97BE5D5398DB11B'
   test = '1D94CE66C593122BF425FE6E2B28EB9B484A4FC1A9F34594B6F4C15D53A39440'
   core = '2F9C27E68AA4F02EDCCC54E1950039B42CD01BF763103F8E61B59DB89729E5B7'
   contract = 'FEC6219C1C7FB8A23FC1FB9433D67285485AFB2CF692E5DD8D0016E0FB75FF19'
   executable_manifest = 'EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972'
   source = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
   profile = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
}
$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

$build = & $builder
if($build.Status -ne 'GENERATED_AWAITING_EXECUTABLE_MT5_GATE' -or $build.Components -ne 2 -or
   $build.EvidenceInherited -or $build.MQL5Launched -or $build.RealAccountApproved) {
   throw 'Ledger builder overclaimed evidence or changed the offline boundary.'
}
$manifest = @(Import-Csv -LiteralPath $manifestPath)
if($manifest.Count -ne 2) { throw 'Ledger harness manifest must contain analyzer and regression rows.' }
foreach($row in $manifest) {
   $generated = Join-Path $repo $row.GeneratedPath
   $template = Join-Path $repo $row.TemplatePath
   $actual = (Get-FileHash -LiteralPath $generated -Algorithm SHA256).Hash.ToUpperInvariant()
   if(!$expected.ContainsKey($row.Component) -or $actual -ne $expected[$row.Component] -or $actual -ne $row.GeneratedSha256) {
      throw "Generated ledger component identity changed: $($row.Component)"
   }
   if((Get-FileHash -LiteralPath $template -Algorithm SHA256).Hash.ToUpperInvariant() -ne $row.TemplateSha256) {
      throw "Reviewed ledger template identity changed: $($row.Component)"
   }
   if($row.SharedCoreSha256 -ne $expected.core -or $row.ExecutableManifestSha256 -ne $expected.executable_manifest -or
      $row.SourceSha256 -ne $expected.source -or $row.ProfileSha256 -ne $expected.profile -or
      $row.EvidenceInherited -ne 'False' -or $row.LaunchPerformed -ne 'False') {
      throw "Ledger harness manifest lost its identity/evidence boundary: $($row.Component)"
   }
   $bytes = [IO.File]::ReadAllBytes($generated)
   if($bytes -contains 13 -or @($bytes | Where-Object { $_ -gt 127 }).Count -gt 0) {
      throw "Generated ledger component is not ASCII LF-only: $($row.Component)"
   }
}
if((Get-FileHash -LiteralPath $core -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expected.core) { throw 'Shared ledger core identity changed.' }
if((Get-FileHash -LiteralPath $contractPath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expected.contract) { throw 'Successor ledger contract identity changed.' }

$analyzerText = Get-Content -LiteralPath $analyzer -Raw
foreach($required in @(
   'RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_MANIFEST.csv',
   'RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RESULTS.csv',
   'RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_DECISION.csv',
   'rdmc_money_ready_gate_repair_executable_package',
   'len(results) == 24',
   'report.resolve().parent == REPORT_ROOT.resolve()',
   'identity_path.resolve() == expected_identity_path.resolve()',
   'StaticReadinessPass',
   'SourceNormalizedToBase',
   'PostHocCollisionScorePromoted'
)) {
   if($analyzerText.IndexOf($required, [StringComparison]::Ordinal) -lt 0) { throw "Successor ledger admission check missing: $required" }
}
foreach($forbidden in @('RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE','rdmc_diversified_repair_executable_gate_package','EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F')) {
   if($analyzerText.IndexOf($forbidden, [StringComparison]::Ordinal) -ge 0) { throw "Successor analyzer retains old identity: $forbidden" }
}

& python $regression
if($LASTEXITCODE -ne 0) { throw 'Successor ledger regression failed.' }
$decision = @(Import-Csv -LiteralPath $decisionPath)
if($decision.Count -ne 1 -or $decision[0].Status -ne 'AWAITING_EXECUTABLE_MT5_GATE' -or
   $decision[0].CurrentExecutableGateStatus -ne 'LOCKED_AWAITING_WAVE_01_REPORTS' -or
   $decision[0].ExecutableGatePass -ne 'False' -or $decision[0].ExecutableLedgerPresent -ne 'False' -or
   $decision[0].CostGatePass -ne 'False' -or $decision[0].OrderAwareMonteCarloPass -ne 'False' -or
   $decision[0].StaticReadinessPass -ne 'True' -or $decision[0].SourceNormalizedToBase -ne 'True' -or
   $decision[0].PostHocCollisionScorePromoted -ne 'False' -or $decision[0].ForwardCandidateChanged -ne 'False' -or
   $decision[0].RealAccountApproved -ne 'False' -or $decision[0].ManifestSha256 -ne $expected.executable_manifest -or
   $decision[0].SourceSha256 -ne $expected.source -or $decision[0].ProfileSha256 -ne $expected.profile) {
   throw 'Successor ledger decision overclaims evidence or lost frozen identity.'
}
$decisionMarkdown = Get-Content -LiteralPath $decisionMarkdownPath -Raw
foreach($boundary in @('No executable ledger exists and no stress pass is claimed','Post-hoc component ledgers cannot substitute','Static readiness: `PASS`','Source normalization to frozen base: `PASS`')) {
   if($decisionMarkdown.IndexOf($boundary, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Ledger decision boundary missing: $boundary" }
}
$contract = Get-Content -LiteralPath $contractPath -Raw
foreach($boundary in @('NO OLDER PROFIT OR STRESS EVIDENCE IS INHERITED','all 24 canonical result rows','0.00R/trade','0.10R/trade','Trials: `10,000`','All eight sampler/stress rows must pass','Valid forward evidence')) {
   if($contract.IndexOf($boundary, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Ledger contract boundary missing: $boundary" }
}
foreach($stale in @(
   'RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_TRADES.csv',
   'RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_COST_STRESS.csv',
   'RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_ORDER_AWARE_MONTE_CARLO.csv'
)) {
   if(Test-Path -LiteralPath (Join-Path $repo "outputs\$stale")) { throw "Unadmitted successor stress output exists: $stale" }
}
if(!(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock')) -or
   !(Test-Path -LiteralPath (Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'))) { throw 'A local launch lock is absent.' }
$after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if($after.Count -gt $before.Count) { throw 'Ledger package test launched an MT5-family process.' }

$result = [pscustomobject][ordered]@{
   Status = 'PASS'
   GeneratedComponents = $manifest.Count
   FailClosedCases = 12
   CostScenarios = 4
   MonteCarloRows = 8
   ReportsPresent = 0
   ExecutableLedgerPresent = $false
   EvidenceInherited = $false
   MQL5Launched = $false
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
$result | Export-Csv -LiteralPath $testCsvPath -NoTypeInformation -Encoding ASCII
$markdown = @(
   '# RDMC Money-Ready Gate Repair Ledger Harness Tests',
   '',
   '**PASS. The exact successor identity is bound to the trade-ledger stress gate, but admission remains closed.**',
   '',
   '- Generated components: `2`',
   '- Fail-closed regression cases: `12/12`',
   '- Frozen added-cost scenarios: `4`',
   '- Frozen order-aware Monte Carlo rows: `8`',
   '- Executable reports present: `0/24`',
   '- Executable ledger present: `False`',
   '- Older profit/stress evidence inherited: `False`',
   '- MT5 launched: `False`',
   '- Forward candidate changed: `False`',
   '- Real-account approval: `False`',
   '',
   'The older 127-trade report used by the regression is parser-format evidence only. It is never admitted as successor performance or stress evidence.'
) -join "`n"
[IO.File]::WriteAllText($testMarkdownPath, $markdown + "`n", [Text.Encoding]::ASCII)
$result
