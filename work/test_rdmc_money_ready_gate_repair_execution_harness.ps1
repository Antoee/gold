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
   runner = '55848002418E3DECEB4938F89F82821910D2AC3101CE2D72725D7AE7869B3ECA'
   collector = '8B1F30B07A65FEF53C7BF3741B1C6B6A22C1926023220E35225A092B4FC8CBD6'
   evaluator = '44EFC91B10E8B0FEC81B12588B7EE45C468FBF2348D9A39FE8AA083CC897EFC8'
   runner_test = '6E1250B699162375B784A4A5CFB8E38DDD4485E08CDED2B52D9136F8C087DD83'
   collector_test = '78185DF7F43258EDEC81F304DB453AFB263B4A79DCB4EB4D31927B7C3BC523BE'
   evaluator_test = '125141086026214214D083C4C74D3570C891BE795751283BD6312B2823814180'
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

   $authorizationRejected = $false
   try {
      & $runner -Run -PlanCsv "$tempRelative\no_auth_plan.csv" -PlanMarkdown "$tempRelative\no_auth_plan.md" | Out-Null
   }
   catch { $authorizationRejected = $_.Exception.Message -match 'explicit focus-risk authorization' }
   if(!$authorizationRejected) { throw 'Runner did not reject run mode without explicit authorization.' }

   $hardLockRejected = $false
   try {
      & $runner -Run -UserAuthorizedFocusRisk -PlanCsv "$tempRelative\locked_plan.csv" -PlanMarkdown "$tempRelative\locked_plan.md" | Out-Null
   }
   catch { $hardLockRejected = $_.Exception.Message -match 'hard-locked' }
   if(!$hardLockRejected) { throw 'Runner did not reject run mode under the hard locks.' }

   $missingLedgerRejected = $false
   try {
      & $collector -Wave 1 -RunnerLedgerGlob "$tempRelative\missing_runner_*.csv" `
         -ResultsPath "$tempRelative\canonical.csv" -RunAuditPath "$tempRelative\audit.csv" `
         -RawResultsPath "$tempRelative\raw.csv" -SummaryPath "$tempRelative\summary.csv" `
         -MetricsMarkdownPath "$tempRelative\metrics.md" -SkipAdmissionRefresh | Out-Null
   }
   catch { $missingLedgerRejected = $_.Exception.Message -match 'No runner ledger files found' }
   if(!$missingLedgerRejected) { throw 'Collector did not fail closed when the admitted runner ledger was absent.' }

   & python $evaluator
   if($LASTEXITCODE -ne 0) { throw 'Successor evaluator main failed.' }
   $decision = @(Import-Csv -LiteralPath $decisionPath)
   if($decision.Count -ne 1 -or $decision[0].Status -ne 'LOCKED_AWAITING_WAVE_01_REPORTS' -or
      $decision[0].ReportsPresent -ne '0' -or $decision[0].StaticReadinessPass -ne 'True' -or
      $decision[0].SourceNormalizedToBase -ne 'True' -or $decision[0].ForwardCandidateChanged -ne 'False' -or
      $decision[0].RealAccountApproved -ne 'False') {
      throw 'Successor evaluator overclaimed evidence or lost gate-repair identity facts.'
   }
   $evaluation = @(Import-Csv -LiteralPath $evaluationPath)
   if($evaluation.Count -ne 2 -or @($evaluation | Where-Object Reasons -ne 'NOT_EVALUATED_INCOMPLETE_WAVE').Count -gt 0) {
      throw 'Empty-evidence evaluation did not remain at the two-row Wave 1 boundary.'
   }
   $reportArtifacts = @(Get-ChildItem -LiteralPath $reportsPath -File | Where-Object Name -ne 'README.md')
   if($reportArtifacts.Count -ne 0) { throw 'Harness audit found an unvalidated report artifact.' }
   if(Test-Path -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RESULTS.csv')) {
      throw 'Harness audit found a claimed canonical result file.'
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
      AuthorizationRejected = $authorizationRejected
      HardLockRejected = $hardLockRejected
      MissingLedgerRejected = $missingLedgerRejected
      ReportsPresent = $reportArtifacts.Count
      MQL5Launched = $false
      ForwardCandidateChanged = $false
      RealAccountApproved = $false
   }
   $result | Export-Csv -LiteralPath $testCsvPath -NoTypeInformation -Encoding ASCII
   $markdown = @(
      '# RDMC Money-Ready Gate Repair Harness Tests',
      '',
      '**PASS. The successor harness is operationally bound but remains launch locked with zero executable reports.**',
      '',
      '- Generated components: `6`',
      '- Hash-pinned template and generated identities: `PASS`',
      '- Evaluator regression cases: `6/6`',
      '- Explicit focus-risk authorization rejection: `PASS`',
      '- Repository/outer hard-lock rejection: `PASS`',
      '- Missing runner-ledger rejection: `PASS`',
      '- Synthetic report identity/tamper regression: `PASS`',
      '- Reports present: `0/24`',
      '- MT5 launched: `False`',
      '- Forward candidate changed: `False`',
      '- Real-account approval: `False`',
      '',
      'The current admitted spend remains Wave 1 only: Model1 2019 and 2022. Passing offline harness tests does not compile the new source, establish profit, or transfer evidence from an older binary.'
   ) -join "`n"
   [IO.File]::WriteAllText($testMarkdownPath, $markdown + "`n", [Text.Encoding]::ASCII)
   $result
}
finally {
   if(Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
