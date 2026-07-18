Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$package = Join-Path $repo "outputs\rdmc_money_ready_gate_repair_second_broker_validation_package"
$source = Join-Path $repo "outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5"
$profile = Join-Path $repo "outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_v1.set"
$reports = Join-Path $package "reports_here"
$packageReadme = Join-Path $package "README_RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION.md"
$manifestPath = Join-Path $repo "outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_MANIFEST.csv"
$templatePath = Join-Path $repo "outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_SPECIFICATION_TEMPLATE.csv"
$contractPath = Join-Path $repo "outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_CONTRACT.md"
$decisionPath = Join-Path $repo "outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_DECISION.csv"
$decisionMarkdownPath = Join-Path $repo "outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_DECISION.md"
$builderPath = Join-Path $repo "work\build_rdmc_money_ready_gate_repair_second_broker_validation_gate.ps1"
$evaluatorPath = Join-Path $repo "work\evaluate_rdmc_money_ready_gate_repair_second_broker_validation_gate.py"
$collectorPath = Join-Path $repo "work\collect_rdmc_money_ready_gate_repair_second_broker_validation_results.py"
$testPath = Join-Path $repo "work\test_rdmc_money_ready_gate_repair_second_broker_validation_gate.py"
$expectedSourceHash = "104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8"
$expectedProfileHash = "8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E"
$expectedManifestHash = "30A508459E0C408BFF9A905F5C9AEB01AF9D411C39165734F197CC2928CE6CB5"
$primaryFingerprint = "C9D9B521F3325D6CE4996576CD61C7AA3E860A08B84DC47540C2B30E98924092"

& $builderPath | Out-Null

$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{ Check=$Name; Pass=$Pass; Evidence=$Evidence }) | Out-Null
}

& $builderPath | Out-Null

foreach($required in @($source,$profile,$reports,$packageReadme,$manifestPath,$templatePath,$contractPath,
                        $decisionPath,$decisionMarkdownPath,$builderPath,$evaluatorPath,$collectorPath,$testPath)) {
   Add-Check "required artifact: $([IO.Path]::GetFileName($required))" (Test-Path -LiteralPath $required) $required
}
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Required second-broker artifacts are missing."
}

$manifest = @(Import-Csv -LiteralPath $manifestPath)
$template = @(Import-Csv -LiteralPath $templatePath)
$contract = Get-Content -LiteralPath $contractPath -Raw
$decision = @(Import-Csv -LiteralPath $decisionPath)
$decisionMarkdown = Get-Content -LiteralPath $decisionMarkdownPath -Raw
$evaluator = Get-Content -LiteralPath $evaluatorPath -Raw
$collector = Get-Content -LiteralPath $collectorPath -Raw
$configFiles = @($manifest | ForEach-Object { Get-Item -LiteralPath (Join-Path $repo $_.PackageConfig) } | Sort-Object FullName -Unique)
$reportFiles = @(Get-ChildItem -LiteralPath $reports -File -ErrorAction SilentlyContinue | Where-Object {
   $_.Extension -in @('.htm','.html','.xml') -or $_.Name.EndsWith('.identity.json',[StringComparison]::OrdinalIgnoreCase)
})

Add-Check "source hash frozen" ((Get-FileHash $source -Algorithm SHA256).Hash -eq $expectedSourceHash) $expectedSourceHash
Add-Check "profile hash frozen" ((Get-FileHash $profile -Algorithm SHA256).Hash -eq $expectedProfileHash) $expectedProfileHash
Add-Check "manifest hash frozen" ((Get-FileHash $manifestPath -Algorithm SHA256).Hash -eq $expectedManifestHash) $expectedManifestHash
Add-Check "manifest has 18 rows" ($manifest.Count -eq 18) "rows=$($manifest.Count)"
Add-Check "manifest references 18 frozen configs" ($configFiles.Count -eq 18) "configs=$($configFiles.Count)"
Add-Check "wave counts are 2,4,12" ((@(1..3 | ForEach-Object { @($manifest | Where-Object Wave -eq ([string]$_)).Count }) -join ',') -eq '2,4,12') "waves=2,4,12"
Add-Check "all rows are Model4 only" (@($manifest | Where-Object Model -ne '4').Count -eq 0) "rows=$($manifest.Count)"
Add-Check "queue ranks are exact" ((@($manifest.QueueRank) -join ',') -eq ((1..18) -join ',')) (@($manifest.QueueRank) -join ',')
Add-Check "all rows freeze source/profile" (@($manifest | Where-Object { $_.SourceSha256 -ne $expectedSourceHash -or $_.ProfileSha256 -ne $expectedProfileHash }).Count -eq 0) "rows=$($manifest.Count)"
Add-Check "all rows freeze 10000 USD contract" (@($manifest | Where-Object { $_.Deposit -ne '10000' -or $_.InitialDeposit -ne '10000' }).Count -eq 0) "rows=$($manifest.Count)"
Add-Check "all rows retain prerequisite lock" (@($manifest | Where-Object Status -ne 'PREREQUISITE_LOCKED').Count -eq 0) "rows=$($manifest.Count)"
Add-Check "all rows freeze primary fingerprint" (@($manifest | Where-Object PrimaryCompanyFingerprintSha256 -ne $primaryFingerprint).Count -eq 0) $primaryFingerprint
Add-Check "all configs are nonvisual real ticks" (@($configFiles | Where-Object { $lines=@(Get-Content $_.FullName); 'Model=4' -notin $lines -or 'Visual=0' -notin $lines }).Count -eq 0) "configs=$($configFiles.Count)"
Add-Check "all configs freeze 589 inputs" (@($configFiles | Where-Object { @((Get-Content $_.FullName) | Where-Object { $_ -match '^Inp[^=]+=' }).Count -ne 589 }).Count -eq 0) "configs=$($configFiles.Count)"
$duplicateFiles = @(@('source','profiles','configs') | ForEach-Object {
   $directory = Join-Path $package $_
   if(Test-Path $directory) { Get-ChildItem -LiteralPath $directory -Recurse -File }
})
Add-Check "package does not duplicate frozen source/configs" ($duplicateFiles.Count -eq 0) "references primary package"

$configFailures = foreach($row in $manifest) {
   $config = Join-Path $repo $row.PackageConfig
   if(!(Test-Path $config) -or (Get-FileHash $config -Algorithm SHA256).Hash -ne $row.ConfigSha256) { $row.QueueRank }
}
Add-Check "every config hash matches manifest" (@($configFailures).Count -eq 0) "failures=$(@($configFailures).Count)"
$reportNameFailures = foreach($row in $manifest) {
   $config = Join-Path $repo $row.PackageConfig
   if("Report=$($row.ExpectedReportName)" -notin @(Get-Content $config)) { $row.QueueRank }
}
Add-Check "every config report name matches manifest" (@($reportNameFailures).Count -eq 0) "failures=$(@($reportNameFailures).Count)"

Add-Check "specification template is anonymized" ($template.Count -eq 1 -and $template[0].EnvironmentRole -eq 'SECONDARY' -and $template[0].AccountIdentifierPublished -eq 'False' -and $template[0].PrimaryCompanyFingerprintSha256 -eq $primaryFingerprint) "rows=$($template.Count)"
Add-Check "actual second-broker specification absent" (!(Test-Path (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_SPECIFICATION.csv'))) "not supplied"
Add-Check "actual second-broker results absent" (!(Test-Path (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_RESULTS.csv'))) "not supplied"
Add-Check "no second-broker reports claimed" ($reportFiles.Count -eq 0) "reports=$($reportFiles.Count)"
Add-Check "decision waits for primary proof" ($decision.Count -eq 1 -and $decision[0].Status -eq 'AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS' -and $decision[0].ReportsPresent -eq '0' -and $decision[0].SecondBrokerGatePass -eq 'False') $(if($decision.Count -eq 1){$decision[0].Status}else{'missing'})
Add-Check "decision keeps candidate unchanged" ($decision[0].ForwardCandidateChanged -eq 'False' -and $decision[0].RealAccountApproved -eq 'False') "forward=$($decision[0].ForwardCandidateChanged) real=$($decision[0].RealAccountApproved)"
Add-Check "contract rejects proxy and same broker" ($contract.Contains('Broker-proxy input changes') -and $contract.Contains('company fingerprint must differ') -and $contract.Contains('same-broker evidence fails closed')) "boundary present"
Add-Check "contract freezes report metrics" ($contract.Contains('expected payoff') -and $contract.Contains('Sharpe') -and $contract.Contains('equity drawdown') -and $contract.Contains('loss streak') -and $contract.Contains('calculated CAGR')) "boundary present"
Add-Check "evaluator binds report and specification" ($evaluator.Contains('validate_report_identity') -and $evaluator.Contains('ReportCompanyFingerprint=MISMATCH') -and $evaluator.Contains('BrokerSpecificationSha256') -and $evaluator.Contains('BOUND_REPORT_INVALID')) "boundary present"
Add-Check "collector admits only exact current wave" ($collector.Contains('admitted_wave') -and $collector.Contains('Expected one report') -and $collector.Contains('Report identity sidecar is missing') -and $collector.Contains('do not share one compiled binary identity')) "boundary present"
Add-Check "evaluator rejects account identifiers" ($evaluator.Contains('reject_report_account_identifier') -and $evaluator.Contains('prohibited account identifier field')) "boundary present"
Add-Check "collector invokes account-identifier rejection" ($collector.Contains('gate.reject_report_account_identifier(report)')) "boundary present"
Add-Check "decision states one broker only" ($decisionMarkdown.Contains('All 52 stored MT5 reports') -and $decisionMarkdown.Contains('none is counted as second-broker evidence')) "boundary present"
Add-Check "repository launch lock remains" (Test-Path (Join-Path $repo 'work\MT5_LOCAL_LAUNCH_DISABLED.lock')) "present"
Add-Check "outer launch lock remains" (Test-Path (Join-Path (Split-Path -Parent $repo) 'MT5_LOCAL_LAUNCH_DISABLED.lock')) "present"
$mt5 = @(Get-Process terminal64,terminal,metatester64,metaeditor64 -ErrorAction SilentlyContinue)
Add-Check "no MT5 process running" ($mt5.Count -eq 0) "processes=$($mt5.Count)"
Add-Check "no account identifier published" ($contract -notmatch '(?i)(account.?id|login)\s*[:=]\s*\d{5,}' -and $decisionMarkdown -notmatch '(?i)(account.?id|login)\s*[:=]\s*\d{5,}') "public markdown clean"
Add-Check "no GitHub token published" ($contract -notmatch 'github_pat_|gh[pousr]_[A-Za-z0-9]{20,}' -and $decisionMarkdown -notmatch 'github_pat_|gh[pousr]_[A-Za-z0-9]{20,}') "public markdown clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) { throw "FAIL: $($failed.Count) second-broker package checks failed." }
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC second-broker package checks"
