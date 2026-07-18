$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$policyPath = Join-Path $repo 'outputs\RDMC_STRATEGY_REWRITE_ESCALATION_POLICY.csv'
$testsCsvPath = Join-Path $repo 'outputs\RDMC_STRATEGY_REWRITE_ESCALATION_POLICY_TESTS.csv'
$testsMarkdownPath = Join-Path $repo 'outputs\RDMC_STRATEGY_REWRITE_ESCALATION_POLICY_TESTS.md'
$beforeProcesses = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if($beforeProcesses.Count -ne 0) { throw 'Rewrite-policy tests require zero MT5-family processes.' }

$rows = @(Import-Csv -LiteralPath $policyPath)
$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check {
   param([string]$Check, [bool]$Pass, [string]$Evidence)
   if(!$Pass) { throw "Rewrite escalation policy failed: $Check ($Evidence)" }
   $checks.Add([pscustomobject]@{Check=$Check;Pass=$Pass;Evidence=$Evidence}) | Out-Null
}

Add-Check 'five-wave-shape' ($rows.Count -eq 5 -and ($rows.Wave -join ',') -eq '1,2,3,4,5') "rows=$($rows.Count); waves=$($rows.Wave -join ',')"
Add-Check 'cumulative-test-budget' (($rows.CumulativeValidReports -join ',') -eq '2,6,8,12,24') "cumulative=$($rows.CumulativeValidReports -join ',')"
Add-Check 'same-identity-metric-reruns-forbidden' (@($rows | Where-Object SameIdentityMetricRerunAllowed -ne 'False').Count -eq 0) 'Every valid metric failure rejects the frozen identity.'
Add-Check 'invalid-evidence-reruns-allowed' (@($rows | Where-Object InvalidEvidenceRerunAllowed -ne 'True').Count -eq 0) 'Evidence defects may be repaired without misclassifying strategy performance.'
Add-Check 'wave-one-single-activity-exception' ($rows[0].Disposition -eq 'CONDITIONAL_REWRITE' -and $rows[0].SettingsOnlyRepairBudget -eq '1_ACTIVITY_ONLY' -and $rows[0].RequiredNextAction -match 'only minimum trade count fails') 'Exactly one one-factor activity-only repair is possible under a new identity.'
Add-Check 'later-waves-force-code-rewrite' (@($rows | Select-Object -Skip 1 | Where-Object { $_.Disposition -ne 'CODE_REWRITE_REQUIRED' -or $_.SettingsOnlyRepairBudget -ne '0' }).Count -eq 0) 'Waves 2-5 do not permit settings-only rescue.'
Add-Check 'real-tick-substitution-forbidden' (@($rows | Where-Object Wave -eq '3' | Where-Object ForbiddenShortcut -match 'Model1 profit').Count -eq 1) 'Model1 cannot replace Model4 evidence.'
Add-Check 'broad-era-deletion-forbidden' (@($rows | Where-Object Wave -eq '4' | Where-Object ForbiddenShortcut -match 'dropping a losing broad era').Count -eq 1) 'All broad eras remain mandatory.'
Add-Check 'posthoc-calendar-blocks-forbidden' (@($rows | Where-Object Wave -eq '5' | Where-Object ForbiddenShortcut -match 'one or two losing observations').Count -eq 1) 'Calendar exclusions require independent evidence, not one or two losses.'

$afterProcesses = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
Add-Check 'no-mt5-launch' ($afterProcesses.Count -eq 0) 'MT5-family processes before/after: 0/0.'

$checks | Export-Csv -LiteralPath $testsCsvPath -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Strategy Rewrite Escalation Policy Tests', '',
   '**PASS. Ten checks bind the candidate test budget to deterministic settings-versus-code decisions.**', '',
   '- Decision checkpoints: `2,6,8,12,24` valid reports',
   '- Hard Wave 1 performance failure: `CODE_REWRITE`',
   '- Wave 1 activity-only exception: `ONE NEW-IDENTITY ONE-FACTOR REPAIR`',
   '- Valid Waves 2-5 failure: `CODE_REWRITE`',
   '- Same-identity metric rerun: `FORBIDDEN`',
   '- Invalid-evidence rerun: `ALLOWED`',
   '- MT5 launched: `False`', '',
   '| Check | Pass | Evidence |',
   '|---|---:|---|'
) + @($checks | ForEach-Object { "| $($_.Check) | $($_.Pass) | $($_.Evidence) |" }) |
   Set-Content -LiteralPath $testsMarkdownPath -Encoding ASCII

[pscustomobject][ordered]@{
   Status = 'PASS'
   Checks = $checks.Count
   FirstDecisionAfterValidReports = 2
   FullCandidateBudget = 24
   SameIdentityMetricRerunAllowed = $false
   MQL5Launched = $false
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
