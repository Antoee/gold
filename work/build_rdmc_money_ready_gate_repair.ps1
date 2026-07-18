[CmdletBinding()]
param(
   [string]$BaseSourcePath = 'outputs\rdmc_diversified_repair_executable_gate_package\source\Professional_XAUUSD_EA.mq5',
   [string]$BaseProfilePath = 'outputs\rdmc_diversified_repair_executable_gate_package\profiles\rdmc_diversified_repair_restart_safe_v2.set',
   [string]$CandidateSourcePath = 'outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5',
   [string]$ResearchProfilePath = 'outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_v1.set',
   [string]$ForwardProfilePath = 'outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_forward_demo_v1.set',
   [string]$ContractPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_CONTRACT.md',
   [string]$ManifestPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_MANIFEST.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedBaseSourceHash = 'EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F'
$expectedBaseProfileHash = '746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883'
$expectedCandidateSourceHash = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
$expectedResearchProfileHash = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
$expectedForwardProfileHash = '816F0FAC4141AB0930A058317C9B5501DC180825B7D8B568BBCE8248D030FA7B'
$researchProfileId = 'rdmc_money_ready_gate_repair_v1'
$forwardProfileId = 'rdmc_money_ready_gate_repair_forward_demo_v1'

function Resolve-RepoPath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo ($Path -replace '/', '\')
}

function Assert-ExpectedHash {
   param([string]$Actual, [string]$Expected, [string]$Label)
   if(![string]::IsNullOrWhiteSpace($Expected) -and $Actual -ne $Expected) { throw "$Label identity changed: $Actual" }
}

$baseSource = Resolve-RepoPath $BaseSourcePath
$baseProfile = Resolve-RepoPath $BaseProfilePath
$candidateSource = Resolve-RepoPath $CandidateSourcePath
$researchProfile = Resolve-RepoPath $ResearchProfilePath
$forwardProfile = Resolve-RepoPath $ForwardProfilePath
$contract = Resolve-RepoPath $ContractPath
$manifest = Resolve-RepoPath $ManifestPath
foreach($directory in @((Split-Path $candidateSource -Parent),(Split-Path $researchProfile -Parent))) {
   New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

if((Get-FileHash -LiteralPath $baseSource -Algorithm SHA256).Hash -ne $expectedBaseSourceHash) { throw 'Frozen base source identity changed.' }
if((Get-FileHash -LiteralPath $baseProfile -Algorithm SHA256).Hash -ne $expectedBaseProfileHash) { throw 'Frozen base profile identity changed.' }

$sourceText = [IO.File]::ReadAllText($baseSource, [Text.Encoding]::ASCII)
$oldVersion = '#property version   "1.31"'
$newVersion = '#property version   "1.32"'
if(([regex]::Matches($sourceText, [regex]::Escape($oldVersion))).Count -ne 1) { throw 'Expected exactly one v1.31 property.' }
$sourceText = $sourceText.Replace($oldVersion, $newVersion)

$oldBandPattern = '(?m)^   AppendTradeReadinessViolation\(InpUseBandVWAPReversionLane,\r?\n                                 "experimental band/VWAP reversion lane enabled", violations\);'
$bandMatches = [regex]::Matches($sourceText, $oldBandPattern)
if($bandMatches.Count -ne 1) { throw "Expected one categorical Band/VWAP readiness block, found $($bandMatches.Count)." }
$newBandBlock = @(
   '   bool bandVWAPReversionReady =',
   '      !InpUseBandVWAPReversionLane ||',
   '      (InpBandVWAPReversionUseIsolatedExecution &&',
   '       InpBandVWAPReversionRiskMultiplier > 0.0 &&',
   '       InpBandVWAPReversionRiskMultiplier <= 0.90 &&',
   '       InpRiskPercent * InpBandVWAPReversionRiskMultiplier <= 0.4500001 &&',
   '       InpBandVWAPReversionMaxMonthlyEntries > 0 &&',
   '       InpBandVWAPReversionMaxMonthlyEntries <= 16 &&',
   '       InpBandVWAPReversionSpacingMinutes >= 240 &&',
   '       InpBandVWAPReversionMaxSpreadATRPercent > 0.0 &&',
   '       InpBandVWAPReversionMaxSpreadATRPercent <= 18.0 &&',
   '       InpBandVWAPReversionMaxStopATR > 0.0 &&',
   '       InpBandVWAPReversionMaxStopATR <= 2.20 &&',
   '       InpBandVWAPReversionMinRR >= 1.20 &&',
   '       InpBandVWAPReversionUseDIEdgeGate &&',
   '       InpBandVWAPReversionMinDIEdge >= -12.0 &&',
   '       InpBandVWAPReversionUseD1MomentumCap &&',
   '       InpBandVWAPReversionMaxAbsoluteD1MomentumPercent > 0.0 &&',
   '       InpBandVWAPReversionMaxAbsoluteD1MomentumPercent <= 12.0);',
   '   AppendTradeReadinessViolation(!bandVWAPReversionReady,',
   '                                 "band/VWAP reversion safety contract incomplete", violations);'
) -join "`r`n"
$sourceText = [regex]::Replace($sourceText, $oldBandPattern, [Text.RegularExpressions.MatchEvaluator]{ param($match) $newBandBlock }, 1)
[IO.File]::WriteAllText($candidateSource, $sourceText, [Text.Encoding]::ASCII)
$candidateSourceHash = (Get-FileHash -LiteralPath $candidateSource -Algorithm SHA256).Hash
Assert-ExpectedHash $candidateSourceHash $expectedCandidateSourceHash 'Generated candidate source'

$base = Import-SetInputs -Path $baseProfile
if($base.Keys.Count -ne 589) { throw "Expected 589 frozen inputs, found $($base.Keys.Count)." }
$research = @{}
foreach($key in $base.Keys) { $research[$key] = $base[$key] }
Set-InputLine $research 'InpMaxConsecutiveLosses' '2'
Set-InputLine $research 'InpEvidenceProfileId' $researchProfileId
Set-InputLine $research 'InpEvidenceRunLabel' 'rdmc_money_ready_gate_repair_v1_executable_locked'
Set-InputLine $research 'InpEvidenceSourceHash' $candidateSourceHash
@($research.Keys | Sort-Object | ForEach-Object { $research[$_] }) | Set-Content -LiteralPath $researchProfile -Encoding ASCII
$researchChanges = @($base.Keys | Where-Object { $base[$_] -ne $research[$_] } | Sort-Object)
$expectedResearchChanges = @('InpEvidenceProfileId','InpEvidenceRunLabel','InpEvidenceSourceHash','InpMaxConsecutiveLosses')
if(Compare-Object -ReferenceObject $expectedResearchChanges -DifferenceObject $researchChanges) { throw "Unexpected research-profile differences: $($researchChanges -join ', ')" }
$researchProfileHash = (Get-FileHash -LiteralPath $researchProfile -Algorithm SHA256).Hash
Assert-ExpectedHash $researchProfileHash $expectedResearchProfileHash 'Generated research profile'

$forward = @{}
foreach($key in $research.Keys) { $forward[$key] = $research[$key] }
Set-InputLine $forward 'InpUseResearchTesterOnlyLock' 'false'
Set-InputLine $forward 'InpUseTradeReadinessSafetyGate' 'true'
Set-InputLine $forward 'InpLogLevel' '2'
Set-InputLine $forward 'InpLogFileName' 'RDMC_MONEY_READY_GATE_REPAIR_FORWARD_TRADES.csv'
Set-InputLine $forward 'InpEvidenceProfileId' $forwardProfileId
Set-InputLine $forward 'InpEvidenceRunLabel' 'rdmc_money_ready_gate_repair_forward_demo_v1'
@($forward.Keys | Sort-Object | ForEach-Object { $forward[$_] }) | Set-Content -LiteralPath $forwardProfile -Encoding ASCII
$forwardChanges = @($research.Keys | Where-Object { $research[$_] -ne $forward[$_] } | Sort-Object)
$expectedForwardChanges = @('InpEvidenceProfileId','InpEvidenceRunLabel','InpLogFileName','InpLogLevel','InpUseResearchTesterOnlyLock','InpUseTradeReadinessSafetyGate')
if(Compare-Object -ReferenceObject $expectedForwardChanges -DifferenceObject $forwardChanges) { throw "Forward profile changed trading/risk fields: $($forwardChanges -join ', ')" }
$forwardProfileHash = (Get-FileHash -LiteralPath $forwardProfile -Algorithm SHA256).Hash
Assert-ExpectedHash $forwardProfileHash $expectedForwardProfileHash 'Generated forward profile'

$staticCsvPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_STATIC_READINESS.csv'
$staticMarkdownPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_STATIC_READINESS.md'
$static = & (Join-Path $PSScriptRoot 'audit_rdmc_forward_demo_profile.ps1') `
   -ProfilePath $ForwardProfilePath -StatusCsvPath $staticCsvPath `
   -StatusMarkdownPath $staticMarkdownPath -AllowValidatedBandVWAPReversion
if(!$static.Pass) { throw "Gate-repair forward profile remains blocked: $($static.FailedRules)" }

@(
   '# RDMC Money-Ready Gate Repair Contract', '',
   '**STATIC ADMISSION CANDIDATE ONLY. NOT COMPILED, BACKTESTED, FORWARD-REGISTERED, OR REAL-MONEY APPROVED.**', '',
   '## Objective', '',
   'Resolve the combined candidate''s two source-level readiness blockers without removing its profitable diversification lane or weakening any risk ceiling. This creates a new source and profile identity that must complete the full executable, stress, distinct-broker, and forward-demo sequence.', '',
   '## Frozen derivation', '',
   "- Base source SHA-256: ``$expectedBaseSourceHash``",
   "- Candidate source SHA-256: ``$candidateSourceHash``",
   "- Base profile SHA-256: ``$expectedBaseProfileHash``",
   "- Research profile SHA-256: ``$researchProfileHash``",
   "- Forward profile SHA-256: ``$forwardProfileHash``", '',
   'The source diff is restricted to the version marker and the Band/VWAP trade-readiness predicate. The research profile changes three evidence fields plus `InpMaxConsecutiveLosses=2`. Signals, entry filters, exits, position sizing, requested lane risk, exposure ceilings, loss percentages, drawdown limits, and trading sessions remain unchanged.', '',
   '## Conditional Band/VWAP admission', '',
   'The lane is admitted only with isolated execution, positive risk multiplier no higher than `0.90`, requested lane risk no higher than `0.45%`, one to 16 monthly entries, at least 240 minutes between entries, spread no higher than `18%` of ATR, stop no wider than `2.20 ATR`, minimum RR `1.20`, DI edge at least `-12`, and an enabled completed-D1 momentum cap no higher than `12%`.', '',
   '## Loss-streak equivalence', '',
   'The only non-evidence research-profile change lowers the streak threshold from four to two. With the frozen 240-minute generic post-loss cooldown, both thresholds block the same valid loss-timestamp states. At streaks two or three with missing timestamp persistence, the new profile blocks while the old profile could continue, so the change is fail-closed rather than permissive.', '',
   '## Evidence boundary', '',
   'Static readiness now passes, but no historical profit transfers to this new identity. It must compile cleanly and pass the complete staged primary executable gate, identity-bound cost and order-aware stress, distinct-broker Model4 validation, and a fresh `$10,000` demo forward registration. Real-account trading remains disabled.'
) | Set-Content -LiteralPath $contract -Encoding ASCII

$artifactPaths = @($candidateSource,$researchProfile,$forwardProfile,(Resolve-RepoPath $staticCsvPath),(Resolve-RepoPath $staticMarkdownPath),$contract)
$rows = foreach($path in $artifactPaths) {
   $resolved = (Resolve-Path -LiteralPath $path).Path
   if(!$resolved.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Artifact outside repository: $resolved" }
   [pscustomobject]@{
      Path = $resolved.Substring($repo.Length + 1).Replace('\','/')
      Bytes = (Get-Item -LiteralPath $resolved).Length
      Sha256 = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
   }
}
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status = 'STATIC_ADMISSION_CANDIDATE'
   CandidateSourceSha256 = $candidateSourceHash
   ResearchProfileSha256 = $researchProfileHash
   ForwardProfileSha256 = $forwardProfileHash
   ResearchProfileChanges = $researchChanges -join ';'
   ForwardOperationalChanges = $forwardChanges -join ';'
   StaticReadinessPass = [bool]$static.Pass
   StaticReadinessChecks = [int]$static.Checks
   Compiled = $false
   MT5Reports = 0
   ForwardRegistered = $false
   RealAccountApproved = $false
}
