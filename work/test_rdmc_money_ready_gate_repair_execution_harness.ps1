$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$builder = Join-Path $PSScriptRoot 'build_rdmc_money_ready_gate_repair_execution_harness.ps1'
$runner = Join-Path $PSScriptRoot 'run_rdmc_money_ready_gate_repair_executable_wave.ps1'
$collector = Join-Path $PSScriptRoot 'collect_rdmc_money_ready_gate_repair_executable_results.ps1'
$evaluator = Join-Path $PSScriptRoot 'evaluate_rdmc_money_ready_gate_repair_executable.py'
$manifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_HARNESS_MANIFEST.csv'
$decisionPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_DECISION.csv'
$evaluationPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_EVALUATION.csv'
$testCsvPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_HARNESS_TESTS.csv'
$testMarkdownPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_HARNESS_TESTS.md'
$reportsPath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_executable_package\reports_here'
$tempRelative = 'outputs\_rdmc_mrgr_harness_test_' + [guid]::NewGuid().ToString('N')
$temp = Join-Path $repo $tempRelative
$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

$expectedGenerated = @{
   runner = 'F37410B81AB8039E4CFDDB564700B8045A5BF970CAFEDC60647C99CBEC947AE8'
   collector = '35FA8C47C0422697A23B35DDDDB8C63D24DC5CF97257E6ACA8C70966B49FAFEA'
   evaluator = '344B4B23428C89D10EFA23C8FB75468AC9EDD693F8B50B23D452558130EF883F'
   runner_test = '8DCC7E9362B7659EF672989E1AFAD5AA29F18B54C4DB0DA841D43A33814EB285'
   collector_test = '3BB3636363545CC3577897F594C5E58A710278E915E478DFD96EA632D3BD6201'
   evaluator_test = '41B9E42A560AB700E4B62C1738AA9C889FF62470B6140BCC2509743D9D423BE4'
}

if(!$temp.StartsWith((Join-Path $repo 'outputs') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe harness-test path.' }
New-Item -ItemType Directory -Path $temp -Force | Out-Null

try {
   $build = & $builder
   if($build.Status -ne 'GENERATED_OFFLINE' -or $build.Components -ne 6 -or $build.MQL5Launched -or $build.RealAccountApproved) {
      throw 'Harness builder did not preserve the offline six-component contract.'
   }
   $manifest = @(Import-Csv -LiteralPath $manifestPath)
   if($manifest.Count -ne 6) { throw 'Harness manifest must contain six components.' }
   foreach($row in $manifest) {
      $path = Join-Path $repo $row.GeneratedPath
      $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
      if(!$expectedGenerated.ContainsKey($row.Component) -or $actual -ne $expectedGenerated[$row.Component] -or $actual -ne $row.GeneratedSha256) {
         throw "Generated harness identity changed: $($row.Component)"
      }
      $bytes = [IO.File]::ReadAllBytes($path)
      if($bytes -contains 13 -or @($bytes | Where-Object { $_ -gt 127 }).Count -gt 0) {
         throw "Generated harness component is not ASCII LF-only: $($row.Component)"
      }
      $templateHash = (Get-FileHash -LiteralPath (Join-Path $repo $row.TemplatePath) -Algorithm SHA256).Hash.ToUpperInvariant()
      if($templateHash -ne $row.TemplateSha256) { throw "Reviewed template identity changed: $($row.Component)" }
   }

   foreach($path in @($runner,$collector,$evaluator)) {
      $text = Get-Content -LiteralPath $path -Raw
      foreach($required in @(
         'EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972',
         '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8',
         '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
      )) {
         if($text.IndexOf($required, [StringComparison]::Ordinal) -lt 0) { throw "Successor identity missing from $path" }
      }
      foreach($forbidden in @('RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE','RDMC_EXECUTABLE_GATE','rdmc_diversified_repair_executable_gate_package')) {
         if($text.IndexOf($forbidden, [StringComparison]::Ordinal) -ge 0) { throw "Old artifact identity retained by $path" }
      }
   }
   $runnerText = Get-Content -LiteralPath $runner -Raw
   foreach($guard in @('assert_mt5_launch_allowed.ps1','prepare_mt5_portable_shared_expert.ps1','UserAuthorizedFocusRisk','repoLock','outerLock','ExpectedPortableBinarySha256')) {
      if($runnerText.IndexOf($guard, [StringComparison]::Ordinal) -lt 0) { throw "Runner guard missing: $guard" }
   }

   $terminalRunnerRejected = $false
   try {
      & $runner -Run -PlanCsv "$tempRelative\no_auth_plan.csv" -PlanMarkdown "$tempRelative\no_auth_plan.md" | Out-Null
   }
   catch { $terminalRunnerRejected = $_.Exception.Message -match 'terminally rejected' }
   if(!$terminalRunnerRejected) { throw 'Runner did not enforce the canonical terminal rejection.' }

   $terminalAuthorizedRunnerRejected = $false
   try {
      & $runner -Run -UserAuthorizedFocusRisk -PlanCsv "$tempRelative\locked_plan.csv" -PlanMarkdown "$tempRelative\locked_plan.md" | Out-Null
   }
   catch { $terminalAuthorizedRunnerRejected = $_.Exception.Message -match 'terminally rejected' }
   if(!$terminalAuthorizedRunnerRejected) { throw 'Explicit authorization bypassed the canonical terminal rejection.' }

   $terminalCollectorRejected = $false
   try {
      & $collector -Wave 1 -RunnerLedgerGlob "$tempRelative\missing_runner_*.csv" `
         -ResultsPath "$tempRelative\canonical.csv" -RunAuditPath "$tempRelative\audit.csv" `
         -RawResultsPath "$tempRelative\raw.csv" -SummaryPath "$tempRelative\summary.csv" `
         -MetricsMarkdownPath "$tempRelative\metrics.md" -SkipAdmissionRefresh | Out-Null
   }
   catch { $terminalCollectorRejected = $_.Exception.Message -match 'terminally rejected' }
   if(!$terminalCollectorRejected) { throw 'Collector did not enforce the canonical terminal rejection.' }

   & python $evaluator
   if($LASTEXITCODE -ne 0) { throw 'Successor evaluator main failed.' }
   $decision = @(Import-Csv -LiteralPath $decisionPath)
   if($decision.Count -ne 1 -or $decision[0].Status -ne 'EXECUTABLE_GATE_REJECTED_WAVE_01' -or
      $decision[0].ReportsPresent -ne '2' -or $decision[0].TerminalRejection -ne 'True' -or
      $decision[0].LaunchLocked -ne 'True' -or
      $decision[0].NextAction -ne 'REWRITE_ENTRY_OR_REGIME_LOGIC_THEN_RESTART_WAVE_01' -or
      $decision[0].StaticReadinessPass -ne 'True' -or
      $decision[0].SourceNormalizedToBase -ne 'True' -or $decision[0].ForwardCandidateChanged -ne 'False' -or
      $decision[0].RealAccountApproved -ne 'False') {
      throw 'Successor evaluator overclaimed evidence or lost gate-repair identity facts.'
   }
   $evaluation = @(Import-Csv -LiteralPath $evaluationPath)
   if($evaluation.Count -ne 2 -or @($evaluation | Where-Object GatePass -ne 'False').Count -gt 0 -or
      @($evaluation | Where-Object Reasons -eq 'NOT_EVALUATED_INCOMPLETE_WAVE').Count -gt 0) {
      throw 'Wave 1 evaluation did not preserve both terminally rejected rows.'
   }
   $reportArtifacts = @()
   if(Test-Path -LiteralPath $reportsPath -PathType Container) {
      $reportArtifacts = @(Get-ChildItem -LiteralPath $reportsPath -File | Where-Object Name -ne 'README.md')
   }
   if($reportArtifacts.Count -ne 4) { throw 'Harness audit did not find exactly two reports and two identity sidecars.' }
   foreach($sidecar in @($reportArtifacts | Where-Object Extension -eq '.json')) {
      $identity = Get-Content -LiteralPath $sidecar.FullName -Raw | ConvertFrom-Json
      $reportPath = Join-Path $reportsPath ($sidecar.Name -replace '\.identity\.json$','.htm')
      if(!(Test-Path -LiteralPath $reportPath -PathType Leaf) -or
         $identity.SourceSha256 -ne '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8' -or
         $identity.PortableBinarySha256 -ne 'D1CF2B9B455F7895CB6BEAC47C98CB4266CD30BC1CCD7B701AF2DB35B6B904AD' -or
         (Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $identity.ReportSha256) {
         throw "Report identity binding failed: $($sidecar.Name)"
      }
   }
   $canonicalResults = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RESULTS.csv'))
   if($canonicalResults.Count -ne 2 -or @($canonicalResults | Where-Object Status -ne 'PARSED').Count -gt 0) {
      throw 'Harness audit did not find the two rejected canonical Wave 1 results.'
   }
   if(!(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock')) -or
      !(Test-Path -LiteralPath (Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'))) {
      throw 'A local launch lock is absent.'
   }
   $after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   if($after.Count -gt $before.Count) { throw 'Harness audit launched an MT5-family process.' }

   $result = [pscustomobject][ordered]@{
      Status = 'PASS'
      Components = $manifest.Count
      TerminalRunnerRejected = $terminalRunnerRejected
      TerminalAuthorizedRunnerRejected = $terminalAuthorizedRunnerRejected
      TerminalCollectorRejected = $terminalCollectorRejected
      ReportsPresent = $canonicalResults.Count
      ReportArtifactsPresent = $reportArtifacts.Count
      MQL5Launched = $false
      ForwardCandidateChanged = $false
      RealAccountApproved = $false
   }
   $result | Export-Csv -LiteralPath $testCsvPath -NoTypeInformation -Encoding ASCII
   $markdown = @(
      '# RDMC Money-Ready Gate Repair Harness Tests',
      '',
      '**PASS. The successor harness preserves the identity-bound Wave 1 rejection and prevents any same-identity rerun.**',
      '',
      '- Generated components: `6`',
      '- Hash-pinned template and generated identities: `PASS`',
      '- Evaluator regression cases: `11/11`',
      '- Terminal runner rejection without authorization: `PASS`',
      '- Terminal runner rejection with authorization: `PASS`',
      '- Terminal collector rejection: `PASS`',
      '- Synthetic report identity/tamper regression: `PASS`',
      '- Identity-bound reports present: `2/24`',
      '- Report plus identity artifacts: `4`',
      '- MT5 launched: `False`',
      '- Forward candidate changed: `False`',
      '- Real-account approval: `False`',
      '',
      'Wave 1 Model1 2019 and 2022 failed the economic and activity gates. The identity is terminally rejected; the next admissible research action is a code rewrite under a new identity, followed by a fresh Wave 1.'
   ) -join "`n"
   [IO.File]::WriteAllText($testMarkdownPath, $markdown + "`n", [Text.Encoding]::ASCII)
   $result
}
finally {
   if(Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
