$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$baseSourcePath = Join-Path $repo 'outputs\rdmc_diversified_repair_executable_gate_package\source\Professional_XAUUSD_EA.mq5'
$candidateSourcePath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5'
$baseProfilePath = Join-Path $repo 'outputs\rdmc_diversified_repair_executable_gate_package\profiles\rdmc_diversified_repair_restart_safe_v2.set'
$researchProfilePath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_v1.set'
$forwardProfilePath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_forward_demo_v1.set'
$manifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_MANIFEST.csv'
$equivalenceCsvPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EQUIVALENCE.csv'
$equivalenceMarkdownPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EQUIVALENCE.md'
$expectedBaseSourceHash = 'EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F'
$expectedCandidateSourceHash = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
$expectedResearchProfileHash = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
$expectedForwardProfileHash = '816F0FAC4141AB0930A058317C9B5501DC180825B7D8B568BBCE8248D030FA7B'

& (Join-Path $PSScriptRoot 'build_rdmc_money_ready_gate_repair.ps1') | Out-Null

if((Get-FileHash -LiteralPath $baseSourcePath -Algorithm SHA256).Hash -ne $expectedBaseSourceHash) { throw 'Base source hash changed.' }
if((Get-FileHash -LiteralPath $candidateSourcePath -Algorithm SHA256).Hash -ne $expectedCandidateSourceHash) { throw 'Candidate source hash changed.' }
if((Get-FileHash -LiteralPath $researchProfilePath -Algorithm SHA256).Hash -ne $expectedResearchProfileHash) { throw 'Research profile hash changed.' }
if((Get-FileHash -LiteralPath $forwardProfilePath -Algorithm SHA256).Hash -ne $expectedForwardProfileHash) { throw 'Forward profile hash changed.' }

$candidateText = [IO.File]::ReadAllText($candidateSourcePath, [Text.Encoding]::ASCII)
if(([regex]::Matches($candidateText, [regex]::Escape('#property version   "1.32"'))).Count -ne 1) { throw 'Candidate version marker is not exact.' }
if(([regex]::Matches($candidateText, 'bool bandVWAPReversionReady =')).Count -ne 1) { throw 'Conditional Band/VWAP readiness predicate is not unique.' }
if($candidateText.Contains('"experimental band/VWAP reversion lane enabled"')) { throw 'Categorical Band/VWAP rejection survived in the candidate.' }

$newBandPattern = '(?ms)^   bool bandVWAPReversionReady =\r?\n.*?^   AppendTradeReadinessViolation\(!bandVWAPReversionReady,\r?\n                                 "band/VWAP reversion safety contract incomplete", violations\);'
if(([regex]::Matches($candidateText, $newBandPattern)).Count -ne 1) { throw 'Candidate Band/VWAP contract block is not exact.' }
$oldBandBlock = @(
   '   AppendTradeReadinessViolation(InpUseBandVWAPReversionLane,',
   '                                 "experimental band/VWAP reversion lane enabled", violations);'
) -join "`n"
$normalizedText = $candidateText.Replace('#property version   "1.32"', '#property version   "1.31"')
$normalizedText = [regex]::Replace($normalizedText, $newBandPattern, [Text.RegularExpressions.MatchEvaluator]{ param($match) $oldBandBlock }, 1)
$normalizedPath = Join-Path ([IO.Path]::GetTempPath()) "rdmc-money-ready-normalized-$PID.mq5"
[IO.File]::WriteAllText($normalizedPath, $normalizedText, [Text.Encoding]::ASCII)
try {
   if((Get-FileHash -LiteralPath $normalizedPath -Algorithm SHA256).Hash -ne $expectedBaseSourceHash) { throw 'Source diff extends beyond the version and readiness predicate.' }
}
finally {
   Remove-Item -LiteralPath $normalizedPath -Force -ErrorAction SilentlyContinue
}

$base = Import-SetInputs -Path $baseProfilePath
$research = Import-SetInputs -Path $researchProfilePath
$forward = Import-SetInputs -Path $forwardProfilePath
if($base.Keys.Count -ne 589 -or $research.Keys.Count -ne 589 -or $forward.Keys.Count -ne 589) { throw 'Profile input count changed.' }
$researchChanges = @($base.Keys | Where-Object { $base[$_] -ne $research[$_] } | Sort-Object)
$expectedResearchChanges = @('InpEvidenceProfileId','InpEvidenceRunLabel','InpEvidenceSourceHash','InpMaxConsecutiveLosses')
if(Compare-Object -ReferenceObject $expectedResearchChanges -DifferenceObject $researchChanges) { throw "Unexpected research differences: $($researchChanges -join ', ')" }
$forwardChanges = @($research.Keys | Where-Object { $research[$_] -ne $forward[$_] } | Sort-Object)
$expectedForwardChanges = @('InpEvidenceProfileId','InpEvidenceRunLabel','InpLogFileName','InpLogLevel','InpUseResearchTesterOnlyLock','InpUseTradeReadinessSafetyGate')
if(Compare-Object -ReferenceObject $expectedForwardChanges -DifferenceObject $forwardChanges) { throw "Unexpected forward differences: $($forwardChanges -join ', ')" }

$consecutiveUsages = @([regex]::Matches($candidateText, '\bInpMaxConsecutiveLosses\b'))
if($consecutiveUsages.Count -ne 4) { throw "Expected one declaration, two references in the runtime condition, and one readiness reference for InpMaxConsecutiveLosses; found $($consecutiveUsages.Count)." }

function Test-TradingAllowedLossState {
   param([int]$Threshold, [int]$Streak, [ValidateSet('missing','recent','elapsed')][string]$LastLossState)
   $cooldownMinutes = 240
   $lastLossPresent = $LastLossState -ne 'missing'
   $ageMinutes = if($LastLossState -eq 'recent') { 60 } elseif($LastLossState -eq 'elapsed') { 300 } else { 0 }
   if($Threshold -gt 0 -and $Streak -ge $Threshold) {
      if($cooldownMinutes -le 0 -or !$lastLossPresent) { return $false }
      if($ageMinutes -lt $cooldownMinutes) { return $false }
   }
   if($lastLossPresent -and $ageMinutes -lt $cooldownMinutes) { return $false }
   return $true
}

$truthRows = [System.Collections.Generic.List[object]]::new()
foreach($streak in 0..6) {
   foreach($state in @('missing','recent','elapsed')) {
      $oldAllows = Test-TradingAllowedLossState -Threshold 4 -Streak $streak -LastLossState $state
      $newAllows = Test-TradingAllowedLossState -Threshold 2 -Streak $streak -LastLossState $state
      $validTimestampState = $state -ne 'missing'
      $equivalentWhenValid = !$validTimestampState -or $oldAllows -eq $newAllows
      $neverLooser = !(!$oldAllows -and $newAllows)
      [void]$truthRows.Add([pscustomobject]@{
         Streak=$streak; LastLossState=$state; OldAllows=$oldAllows; NewAllows=$newAllows
         EquivalentWhenTimestampValid=$equivalentWhenValid; NewNeverLooser=$neverLooser
      })
   }
}
if(@($truthRows | Where-Object { !$_.EquivalentWhenTimestampValid }).Count -gt 0) { throw 'Loss-streak change alters a valid timestamp state.' }
if(@($truthRows | Where-Object { !$_.NewNeverLooser }).Count -gt 0) { throw 'Loss-streak change permits an old-blocked state.' }
$stricterStates = @($truthRows | Where-Object { $_.OldAllows -and !$_.NewAllows })
if($stricterStates.Count -ne 2 -or @($stricterStates | Where-Object { $_.LastLossState -ne 'missing' -or $_.Streak -notin @(2,3) }).Count -gt 0) {
   throw 'Unexpected fail-closed streak-state differences.'
}

$testDir = Join-Path ([IO.Path]::GetTempPath()) "rdmc-money-ready-band-contract-$PID"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
$negativeCases = @(
   @{Case='isolated_execution_disabled';Name='InpBandVWAPReversionUseIsolatedExecution';Value='false'},
   @{Case='risk_multiplier_zero';Name='InpBandVWAPReversionRiskMultiplier';Value='0.0'},
   @{Case='risk_multiplier_too_high';Name='InpBandVWAPReversionRiskMultiplier';Value='0.91'},
   @{Case='requested_lane_risk_too_high';Name='InpRiskPercent';Value='0.51'},
   @{Case='monthly_entries_too_high';Name='InpBandVWAPReversionMaxMonthlyEntries';Value='17'},
   @{Case='spacing_too_short';Name='InpBandVWAPReversionSpacingMinutes';Value='239'},
   @{Case='spread_atr_too_high';Name='InpBandVWAPReversionMaxSpreadATRPercent';Value='18.1'},
   @{Case='stop_atr_too_high';Name='InpBandVWAPReversionMaxStopATR';Value='2.21'},
   @{Case='rr_too_low';Name='InpBandVWAPReversionMinRR';Value='1.19'},
   @{Case='di_gate_disabled';Name='InpBandVWAPReversionUseDIEdgeGate';Value='false'},
   @{Case='di_edge_too_loose';Name='InpBandVWAPReversionMinDIEdge';Value='-12.1'},
   @{Case='d1_cap_disabled';Name='InpBandVWAPReversionUseD1MomentumCap';Value='false'},
   @{Case='d1_cap_too_high';Name='InpBandVWAPReversionMaxAbsoluteD1MomentumPercent';Value='12.1'}
)
$negativeRows = [System.Collections.Generic.List[object]]::new()
foreach($case in $negativeCases) {
   $inputs = @{}
   foreach($key in $forward.Keys) { $inputs[$key] = $forward[$key] }
   Set-InputLine $inputs $case.Name $case.Value
   $profilePath = Join-Path $testDir "$($case.Case).set"
   $csvPath = Join-Path $testDir "$($case.Case).csv"
   $markdownPath = Join-Path $testDir "$($case.Case).md"
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $result = & (Join-Path $PSScriptRoot 'audit_rdmc_forward_demo_profile.ps1') -ProfilePath $profilePath -StatusCsvPath $csvPath -StatusMarkdownPath $markdownPath -AllowValidatedBandVWAPReversion
   $bandBlocked = !$result.Pass -and ([string]$result.FailedRules -split ';') -contains 'band-vwap-reversion-safety-contract'
   if(!$bandBlocked) { throw "Band/VWAP negative case was admitted: $($case.Case)" }
   [void]$negativeRows.Add([pscustomobject]@{Scenario=$case.Case;Input=$case.Name;Value=$case.Value;BandContractBlocked=$bandBlocked})
}

$disabledInputs = @{}
foreach($key in $forward.Keys) { $disabledInputs[$key] = $forward[$key] }
Set-InputLine $disabledInputs 'InpUseBandVWAPReversionLane' 'false'
$disabledProfile = Join-Path $testDir 'lane_disabled.set'
@($disabledInputs.Keys | Sort-Object | ForEach-Object { $disabledInputs[$_] }) | Set-Content -LiteralPath $disabledProfile -Encoding ASCII
$disabledResult = & (Join-Path $PSScriptRoot 'audit_rdmc_forward_demo_profile.ps1') -ProfilePath $disabledProfile -StatusCsvPath (Join-Path $testDir 'lane_disabled.csv') -StatusMarkdownPath (Join-Path $testDir 'lane_disabled.md') -AllowValidatedBandVWAPReversion
if(!$disabledResult.Pass) { throw "Disabled Band/VWAP lane should pass the conditional contract: $($disabledResult.FailedRules)" }

$staticResult = & (Join-Path $PSScriptRoot 'audit_rdmc_forward_demo_profile.ps1') -ProfilePath $forwardProfilePath -StatusCsvPath (Join-Path $testDir 'center.csv') -StatusMarkdownPath (Join-Path $testDir 'center.md') -AllowValidatedBandVWAPReversion
if(!$staticResult.Pass -or $staticResult.Blockers -ne 0 -or $staticResult.Checks -ne 63) { throw 'Center forward profile did not pass all 63 static checks.' }

$manifest = @(Import-Csv -LiteralPath $manifestPath)
if($manifest.Count -ne 6) { throw "Expected six manifest artifacts, found $($manifest.Count)." }
foreach($row in $manifest) {
   $path = Join-Path $repo ($row.Path -replace '/', '\')
   if(!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Manifest artifact missing: $($row.Path)" }
   if((Get-Item -LiteralPath $path).Length -ne [long]$row.Bytes) { throw "Manifest byte mismatch: $($row.Path)" }
   if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $row.Sha256) { throw "Manifest hash mismatch: $($row.Path)" }
}

$truthRows | Export-Csv -LiteralPath $equivalenceCsvPath -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Money-Ready Gate Repair Equivalence', '',
   '**PASS.** The candidate source normalizes byte-for-byte to the frozen source after reversing only the version marker and the readiness predicate.', '',
   "- Source identity: ``$expectedCandidateSourceHash``",
   "- Static readiness: ``$($staticResult.Checks)/$($staticResult.Checks)`` pass",
   "- Adversarial Band/VWAP bounds rejected: ``$($negativeRows.Count)/$($negativeRows.Count)``",
   "- Loss-state truth-table rows: ``$($truthRows.Count)``",
   '- Valid timestamp states changed: `0`',
   '- Previously blocked states newly allowed: `0`',
   "- Missing-timestamp states made stricter: ``$($stricterStates.Count)``", '',
   'The threshold change from four to two is behaviorally equal whenever the frozen loss timestamp is present because the same 240-minute generic cooldown runs after every loss. At missing timestamps with streaks two or three, the new profile blocks instead of allowing another trade.', '',
   'Every conditional Band/VWAP safety input was perturbed across its boundary one at a time. All 13 negative cases were refused by `band-vwap-reversion-safety-contract`; disabling the lane remained valid. This is static equivalence and fail-closed admission evidence only, not MT5 performance evidence.'
) | Set-Content -LiteralPath $equivalenceMarkdownPath -Encoding ASCII

[pscustomobject]@{
   Status = 'PASS'
   SourceNormalizedToBase = $true
   Inputs = $forward.Keys.Count
   ResearchProfileChanges = $researchChanges.Count
   ForwardOperationalChanges = $forwardChanges.Count
   StaticChecks = $staticResult.Checks
   StaticBlockers = $staticResult.Blockers
   BandNegativeCases = $negativeRows.Count
   LossTruthTableRows = $truthRows.Count
   NewlyAllowedLossStates = @($truthRows | Where-Object { !$_.OldAllows -and $_.NewAllows }).Count
   StricterMissingTimestampStates = $stricterStates.Count
   ManifestArtifacts = $manifest.Count
   MT5Launched = $false
   RealAccountApproved = $false
}
