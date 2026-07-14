param(
   [string]$ProfilePath = "outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set",
   [string]$LiveReadinessPath = "outputs\TRADE_READY_LIVE_READINESS_DECISION.csv",
   [string]$ConservativeAuditPath = "outputs\TRADE_READY_CONSERVATIVE_AUDIT.csv",
   [string]$ValidationDecisionPath = "outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv",
   [string]$EfficiencyAuditPath = "outputs\MONEY_READY_EFFICIENCY_AUDIT.csv",
   [string]$FirstPassRefreshPath = "outputs\FIRST_PASS_REFRESH_STATUS.csv",
   [string]$SafetyAuditPath = "outputs\MT5_LOCAL_SAFETY_AUDIT.csv",
   [string]$OutCsv = "outputs\MONEY_READY_STATUS_SCORECARD.csv",
   [string]$OutMarkdown = "outputs\MONEY_READY_STATUS_SCORECARD.md"
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

function Get-Value {
   param([object]$Row, [string]$Name, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

function Get-SetValue {
   param([string]$ProfileText, [string]$Name)
   $pattern = "(?m)^" + [regex]::Escape($Name) + "=([^\r\n|]*)"
   $match = [regex]::Match($ProfileText, $pattern)
   if(!$match.Success) { return "" }
   return $match.Groups[1].Value
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

function Add-ScoreRow {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Area,
      [string]$Status,
      [string]$Actual,
      [string]$Required,
      [string]$Evidence,
      [string]$NextAction
   )

   $Rows.Add([pscustomobject]@{
      Area = $Area
      Status = $Status
      Actual = $Actual
      Required = $Required
      Evidence = $Evidence
      NextAction = $NextAction
   }) | Out-Null
}

$profileFullPath = Resolve-RepoPath $ProfilePath
$profileExists = Test-Path -LiteralPath $profileFullPath
$profileText = if($profileExists) { Get-Content -LiteralPath $profileFullPath -Raw } else { "" }
$profileHash = if($profileExists) { (Get-FileHash -LiteralPath $profileFullPath -Algorithm SHA256).Hash } else { "" }
$sourceHash = if(Test-Path -LiteralPath (Join-Path $repo "Professional_XAUUSD_EA.mq5")) { (Get-FileHash -LiteralPath (Join-Path $repo "Professional_XAUUSD_EA.mq5") -Algorithm SHA256).Hash } else { "" }

$liveRows = @(Read-CsvSafe $LiveReadinessPath)
$auditRows = @(Read-CsvSafe $ConservativeAuditPath)
$validationRows = @(Read-CsvSafe $ValidationDecisionPath)
$efficiencyRows = @(Read-CsvSafe $EfficiencyAuditPath)
$firstPassRows = @(Read-CsvSafe $FirstPassRefreshPath)
$safetyRows = @(Read-CsvSafe $SafetyAuditPath)

$rows = [System.Collections.Generic.List[object]]::new()

Add-ScoreRow $rows "candidate" ($(if($profileExists) { "PASS" } else { "FAIL" })) `
   "profileHash=$profileHash; sourceHash=$sourceHash" `
   "Strict conservative trade-ready profile exists and hashes are captured" `
   $ProfilePath `
   "Generate the conservative profile before evaluating readiness."

$allowReal = Get-SetValue $profileText "InpAllowRealAccountTrading"
$approvalCode = Get-SetValue $profileText "InpRealAccountApprovalCode"
$approvalProfile = Get-SetValue $profileText "InpRealAccountApprovalProfileId"
$approvalSource = Get-SetValue $profileText "InpRealAccountApprovalSourceHash"
$realLockPass = ($allowReal -eq "false" -and $approvalCode -eq "DISABLED" -and $approvalProfile -eq "DISABLED" -and $approvalSource -eq "DISABLED")
Add-ScoreRow $rows "real-account-lock" ($(if($profileExists -and $realLockPass) { "PASS" } elseif(!$profileExists) { "PENDING" } else { "FAIL" })) `
   "allowReal=$allowReal; approvalCode=$approvalCode; approvalProfile=$approvalProfile; approvalSource=$approvalSource" `
   "Real-account trading disabled until separate explicit approval identity is created" `
   $ProfilePath `
   "Keep disabled while validation and forward evidence are pending."

$riskActual = "risk=$(Get-SetValue $profileText 'InpRiskPercent'); openRisk=$(Get-SetValue $profileText 'InpMaxOpenRiskPercent'); lots=$(Get-SetValue $profileText 'InpMaxPositionLots'); dailyLoss=$(Get-SetValue $profileText 'InpMaxDailyLossPercent'); weeklyLoss=$(Get-SetValue $profileText 'InpMaxWeeklyLossPercent'); monthlyLoss=$(Get-SetValue $profileText 'InpMaxMonthlyLossPercent'); equityDD=$(Get-SetValue $profileText 'InpMaxEquityDrawdownPercent')"
Add-ScoreRow $rows "risk-shape" ($(if($profileExists) { "PASS" } else { "PENDING" })) `
   $riskActual `
   "0.10% risk, 0.20% open risk, 0.01 lots, 0.20/0.60/1.25% loss caps, 3.00% equity DD cap" `
   $ProfilePath `
   "Do not loosen these caps before proof gates pass."

$safetyFail = @($safetyRows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" -or [string](Get-Value $_ "Passed") -eq "False" }).Count
$safetyStatus = if($safetyRows.Count -eq 0) { "PENDING" } elseif($safetyFail -gt 0) { "FAIL" } else { "PASS" }
Add-ScoreRow $rows "local-pc-safety" $safetyStatus `
   "rows=$($safetyRows.Count); failures=$safetyFail" `
   "MT5/GitHub/local-launch safety audit has zero failures" `
   $SafetyAuditPath `
   "Fix local safety audit before running tester work."

$auditFail = @($auditRows | Where-Object Status -eq "FAIL").Count
$auditOpen = @($auditRows | Where-Object Status -eq "OPEN").Count
$auditPass = @($auditRows | Where-Object Status -eq "PASS").Count
$auditStatus = if($auditRows.Count -eq 0) { "PENDING" } elseif($auditFail -gt 0) { "FAIL" } elseif($auditOpen -gt 0) { "PENDING" } else { "PASS" }
Add-ScoreRow $rows "guardrail-audit" $auditStatus `
   "pass=$auditPass; open=$auditOpen; fail=$auditFail" `
   "Profile audit has 0 FAIL and 0 OPEN proof gaps" `
   $ConservativeAuditPath `
   "Close open proof gaps; do not promote while any remain."

$validationFail = @($validationRows | Where-Object Status -eq "FAIL").Count
$validationPending = @($validationRows | Where-Object Status -eq "PENDING").Count
$validationPass = @($validationRows | Where-Object Status -eq "PASS").Count
$validationStatus = if($validationRows.Count -eq 0) { "PENDING" } elseif($validationFail -gt 0) { "FAIL" } elseif($validationPending -gt 0) { "PENDING" } else { "PASS" }
Add-ScoreRow $rows "model4-validation" $validationStatus `
   "pass=$validationPass; pending=$validationPending; fail=$validationFail" `
   "All validation, stress, and broker-proxy result gates pass" `
   $ValidationDecisionPath `
   "Return MT5 reports and rerun the importer/decision gate."

foreach($gateName in @("exact-continuous-return-floor", "exact-continuous-return-drawdown-efficiency", "profit-factor-floor", "recovery-factor-floor", "drawdown-within-cap")) {
   $gate = $validationRows | Where-Object Gate -eq $gateName | Select-Object -First 1
   $status = if($null -eq $gate) { "PENDING" } else { [string]$gate.Status }
   $actual = if($null -eq $gate) { "missing" } else { [string]$gate.Actual }
   $required = if($null -eq $gate) { "gate present and passing" } else { [string]$gate.Required }
   Add-ScoreRow $rows "quality:$gateName" $status $actual $required $ValidationDecisionPath `
      "This quality gate must pass before live approval review."
}

$efficiencyFail = @($efficiencyRows | Where-Object Status -eq "FAIL").Count
$efficiencyPending = @($efficiencyRows | Where-Object Status -eq "PENDING").Count
$efficiencyPass = @($efficiencyRows | Where-Object Status -eq "PASS").Count
$efficiencyStatus = if($efficiencyRows.Count -eq 0) { "PENDING" } elseif($efficiencyFail -gt 0) { "FAIL" } elseif($efficiencyPending -gt 0) { "PENDING" } else { "PASS" }
Add-ScoreRow $rows "money-ready-efficiency-audit" $efficiencyStatus `
   "rows=$($efficiencyRows.Count); pass=$efficiencyPass; pending=$efficiencyPending; fail=$efficiencyFail" `
   "Efficiency audit has 0 FAIL and 0 PENDING gates; broad evidence must clear growth, return/drawdown, drawdown, no-red-window, PF, recovery, recent-data, and broker/stress targets" `
   $EfficiencyAuditPath `
   "Return full exported MT5 reports and require the bot to be profitable enough for the risk before live approval review."

foreach($liveGateName in @("current-source-compile", "trade-quality-decision", "monte-carlo-trade-stress", "forward-paper-demo", "second-broker-validation", "local-reproducibility-freeze", "reproducible-github-sync")) {
   $gate = $liveRows | Where-Object Gate -eq $liveGateName | Select-Object -First 1
   $status = if($null -eq $gate) { "PENDING" } else { [string]$gate.Status }
   $actual = if($null -eq $gate) { "missing" } else { [string]$gate.Actual }
   $required = if($null -eq $gate) { "gate present and passing" } else { [string]$gate.Required }
   $next = if($null -eq $gate) { "Regenerate live-readiness decision." } else { [string]$gate.NextAction }
   Add-ScoreRow $rows "live:$liveGateName" $status $actual $required $LiveReadinessPath $next
}

$firstPassOverall = $firstPassRows | Where-Object Area -eq "first_pass_trusted_decision" | Select-Object -First 1
$firstPassBatch = $firstPassRows | Where-Object Area -eq "next_run_batch" | Select-Object -First 1
Add-ScoreRow $rows "first-pass-refresh" ($(if($null -eq $firstPassOverall) { "PENDING" } else { [string]$firstPassOverall.Status })) `
   "$(if($firstPassOverall) { $firstPassOverall.Actual } else { 'missing' }); nextBatch=$(if($firstPassBatch) { $firstPassBatch.Status } else { 'missing' })" `
   "Trusted first-pass evidence is PASS before spending full tester time" `
   $FirstPassRefreshPath `
   "Run the current first-pass next package, import reports, then refresh."

$failCount = @($rows | Where-Object Status -eq "FAIL").Count
$pendingCount = @($rows | Where-Object Status -eq "PENDING").Count
$passCount = @($rows | Where-Object Status -eq "PASS").Count
$verdict = if($failCount -gt 0) {
   "NOT_READY_FAILED"
} elseif($pendingCount -gt 0) {
   "NOT_READY_PENDING_EVIDENCE"
} else {
   "MANUAL_LIVE_REVIEW_READY"
}

$outCsvPath = Resolve-RepoPath $OutCsv
$outMarkdownPath = Resolve-RepoPath $OutMarkdown
foreach($path in @($outCsvPath, $outMarkdownPath)) {
   $parent = Split-Path -Parent $path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

$rows | Export-Csv -LiteralPath $outCsvPath -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Money-Ready Status Scorecard")
$md.Add("")
$md.Add("Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.")
$md.Add("")
$md.Add("- Verdict: **$verdict**")
$md.Add('- Best current candidate: `trade_ready_conservative`')
$md.Add(('- Profile hash: `{0}`' -f $profileHash))
$md.Add(('- Source hash: `{0}`' -f $sourceHash))
$md.Add(('- Passing rows: `{0}`' -f $passCount))
$md.Add(('- Pending rows: `{0}`' -f $pendingCount))
$md.Add(('- Failed rows: `{0}`' -f $failCount))
$md.Add("")
if($verdict -eq "MANUAL_LIVE_REVIEW_READY") {
   $md.Add("All automated gates passed. Real-account trading is still not unlocked automatically; a separate live profile would require explicit approval.")
} elseif($verdict -eq "NOT_READY_FAILED") {
   $md.Add("At least one required gate failed. Do not trade live.")
} else {
   $md.Add("The bot is not money-ready yet because required evidence is still missing or stale. Real-account trading remains locked.")
}
$md.Add("")
$md.Add("## Scorecard")
$md.Add("")
$md.Add("| Area | Status | Actual | Required | Evidence | Next Action |")
$md.Add("| --- | --- | --- | --- | --- | --- |")
foreach($row in $rows) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} |" -f
      (Escape-MarkdownCell $row.Area),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.Actual),
      (Escape-MarkdownCell $row.Required),
      (Escape-MarkdownCell $row.Evidence),
      (Escape-MarkdownCell $row.NextAction)))
}

$md | Set-Content -LiteralPath $outMarkdownPath -Encoding ASCII

[pscustomobject]@{
   Verdict = $verdict
   Pass = $passCount
   Pending = $pendingCount
   Fail = $failCount
   ProfileHash = $profileHash
   SourceHash = $sourceHash
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
