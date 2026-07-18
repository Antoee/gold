$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$generator = Join-Path $PSScriptRoot 'build_rdmc_money_ready_gate_repair_second_broker_validation.ps1'
$pythonTest = Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_second_broker_validation_gate.py'
$packageTest = Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_second_broker_validation_package.ps1'
$harnessManifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_HARNESS_MANIFEST.csv'
$gateManifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_MANIFEST.csv'
$decisionPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_DECISION.csv'
$decisionMarkdownPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_DECISION.md'
$contractPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_CONTRACT.md'
$packageReadmePath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_second_broker_validation_package\README_RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION.md'
$reportsPath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_second_broker_validation_package\reports_here'
$testCsvPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_HARNESS_TESTS.csv'
$testMarkdownPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_HARNESS_TESTS.md'
$expectedGenerated = @{
   builder = 'F018328AF982AF905B17CD6AB6087A99215B2B918B9D5F870AB067AD065EAF2A'
   collector = 'BD48099FB0E7226F1CD9A17954ABFF7792E6DB55C9554C15A40B253D0FFEFFF1'
   evaluator = '28D63FBCBC516C71CE05EDC66DE5B5188E7C3622A51499EEDE1A3B6B83E8E8DC'
   evaluator_test = '43822C93A2BD3DC4D9749BC94CF1EDE02B63110BE83FE1175854CC43353F05D3'
   package_test = '8C9AC7E664A9CB6A2BCE3D1DA0A0B13FA43AAF3D43943ADD90F96D1097DCA8A9'
}
$expectedManifestHash = '30A508459E0C408BFF9A905F5C9AEB01AF9D411C39165734F197CC2928CE6CB5'
$expectedSourceHash = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
$expectedProfileHash = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
$expectedPrimaryFingerprint = 'C9D9B521F3325D6CE4996576CD61C7AA3E860A08B84DC47540C2B30E98924092'
$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

$generated = & $generator
if($generated.Status -ne 'GENERATED_AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS' -or $generated.Components -ne 5 -or
   $generated.Rows -ne 18 -or $generated.ManifestSha256 -ne $expectedManifestHash -or
   $generated.EvidenceInherited -or $generated.MQL5Launched -or $generated.RealAccountApproved) {
   throw 'Successor second-broker generator overclaimed evidence or changed its frozen shape.'
}
$harness = @(Import-Csv -LiteralPath $harnessManifestPath)
if($harness.Count -ne 5) { throw 'Second-broker harness manifest must contain five generated components.' }
foreach($row in $harness) {
   $generatedPath = Join-Path $repo $row.GeneratedPath
   $templatePath = Join-Path $repo $row.TemplatePath
   $actual = (Get-FileHash -LiteralPath $generatedPath -Algorithm SHA256).Hash.ToUpperInvariant()
   if(!$expectedGenerated.ContainsKey($row.Component) -or $actual -ne $expectedGenerated[$row.Component] -or $actual -ne $row.GeneratedSha256) {
      throw "Generated second-broker component identity changed: $($row.Component)"
   }
   if((Get-FileHash -LiteralPath $templatePath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $row.TemplateSha256) {
      throw "Reviewed second-broker template identity changed: $($row.Component)"
   }
   if($row.SecondBrokerManifestSha256 -ne $expectedManifestHash -or $row.SourceSha256 -ne $expectedSourceHash -or
      $row.ProfileSha256 -ne $expectedProfileHash -or $row.PrimaryCompanyFingerprintSha256 -ne $expectedPrimaryFingerprint -or
      $row.EvidenceInherited -ne 'False' -or $row.LaunchPerformed -ne 'False') {
      throw "Second-broker harness identity/evidence boundary changed: $($row.Component)"
   }
   $bytes = [IO.File]::ReadAllBytes($generatedPath)
   if($bytes -contains 13 -or @($bytes | Where-Object { $_ -gt 127 }).Count -gt 0) {
      throw "Generated second-broker component is not ASCII LF-only: $($row.Component)"
   }
}
if((Get-FileHash -LiteralPath $gateManifestPath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) { throw 'Second-broker manifest identity changed.' }
if((Get-FileHash -LiteralPath $contractPath -Algorithm SHA256).Hash.ToUpperInvariant() -ne 'F5EEE8455DEA04275C88B3E7D6ABD249F0634A77E66D678D8DCB580A875EF401') { throw 'Second-broker contract identity changed.' }
if((Get-FileHash -LiteralPath $packageReadmePath -Algorithm SHA256).Hash.ToUpperInvariant() -ne 'D1AC6CC6251943D44AE80CF5410727C5C5FE3AA898AD0C03EDB8D257E2C51EBE') { throw 'Second-broker package readme identity changed.' }

& python $pythonTest
if($LASTEXITCODE -ne 0) { throw 'Successor second-broker evaluator regression failed.' }
& $packageTest | Out-Null

$decision = @(Import-Csv -LiteralPath $decisionPath)
if($decision.Count -ne 1 -or $decision[0].Status -ne 'AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS' -or
   $decision[0].CurrentWave -ne '0' -or $decision[0].ReportsPresent -ne '0' -or
   $decision[0].SpecificationPass -ne 'False' -or $decision[0].PrimaryPrerequisitePass -ne 'False' -or
   $decision[0].SecondBrokerGatePass -ne 'False' -or $decision[0].StaticReadinessPass -ne 'True' -or
   $decision[0].SourceNormalizedToBase -ne 'True' -or $decision[0].PostHocCollisionScorePromoted -ne 'False' -or
   $decision[0].ForwardCandidateChanged -ne 'False' -or $decision[0].RealAccountApproved -ne 'False' -or
   $decision[0].ManifestSha256 -ne $expectedManifestHash -or $decision[0].SourceSha256 -ne $expectedSourceHash -or
   $decision[0].ProfileSha256 -ne $expectedProfileHash -or $decision[0].PrimaryCompanyFingerprintSha256 -ne $expectedPrimaryFingerprint) {
   throw 'Successor second-broker decision overclaims evidence or lost frozen identity.'
}
$decisionMarkdown = Get-Content -LiteralPath $decisionMarkdownPath -Raw
$contract = Get-Content -LiteralPath $contractPath -Raw
foreach($boundary in @('none is counted as second-broker evidence','Broker-proxy','account identifiers are excluded','valid frozen $10,000 forward-demo contract')) {
   if($decisionMarkdown.IndexOf($boundary, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Second-broker decision boundary missing: $boundary" }
}
foreach($boundary in @('NO PRIMARY OR OLDER SECOND-BROKER EVIDENCE IS INHERITED','genuinely different XAUUSD broker data','Rows: `18`','After all 18 rows pass','same-broker evidence','real-account safety lock remain unchanged')) {
   if($contract.IndexOf($boundary, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Second-broker contract boundary missing: $boundary" }
}
foreach($absent in @(
   'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_SPECIFICATION.csv',
   'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_RESULTS.csv',
   'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_EVALUATION.csv'
)) {
   if(Test-Path -LiteralPath (Join-Path $repo $absent)) { throw "Unadmitted second-broker evidence exists: $absent" }
}
$reportFiles = @()
if(Test-Path -LiteralPath $reportsPath -PathType Container) {
   $reportFiles = @(Get-ChildItem -LiteralPath $reportsPath -File)
}
if($reportFiles.Count -ne 0) { throw 'Unadmitted second-broker reports exist.' }
if(!(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock')) -or
   !(Test-Path -LiteralPath (Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'))) { throw 'A local launch lock is absent.' }
$after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if($after.Count -gt $before.Count) { throw 'Second-broker harness test launched an MT5-family process.' }

$result = [pscustomobject][ordered]@{
   Status = 'PASS'
   GeneratedComponents = $harness.Count
   EvaluatorCases = 16
   PackageChecks = 48
   Rows = 18
   WaveCounts = '2,4,12'
   ReportsPresent = 0
   SpecificationPresent = $false
   EvidenceInherited = $false
   MQL5Launched = $false
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
$result | Export-Csv -LiteralPath $testCsvPath -NoTypeInformation -Encoding ASCII
$markdown = @(
   '# RDMC Money-Ready Gate Repair Second-Broker Harness Tests',
   '',
   '**PASS. The successor identity is preregistered for distinct-broker validation, but no second-broker evidence exists.**',
   '',
   '- Generated components: `5`',
   '- Evaluator/collector adversarial cases: `16/16`',
   '- Package checks: `48/48`',
   '- Model4 rows: `18` in waves `2,4,12`',
   '- Distinct broker specification present: `False`',
   '- Reports present: `0/18`',
   '- Older or primary evidence inherited: `False`',
   '- MT5 launched: `False`',
   '- Forward candidate changed: `False`',
   '- Real-account approval: `False`',
   '',
   'The current prerequisite is the successor executable gate plus successor executable-ledger stress pass. Primary-broker reports and proxy cost settings cannot satisfy this gate.'
) -join "`n"
[IO.File]::WriteAllText($testMarkdownPath, $markdown + "`n", [Text.Encoding]::ASCII)
$result
