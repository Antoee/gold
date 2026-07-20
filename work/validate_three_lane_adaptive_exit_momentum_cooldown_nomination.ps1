[CmdletBinding()]
param(
   [string]$ValidationCsv='outputs\THREE_LANE_ADAPTIVE_EXIT_MOMENTUM_COOLDOWN_VALIDATION.csv',
   [string]$ValidationMarkdown='outputs\THREE_LANE_ADAPTIVE_EXIT_MOMENTUM_COOLDOWN_VALIDATION.md',
   [string]$DecisionCsv='outputs\THREE_LANE_ADAPTIVE_EXIT_MOMENTUM_COOLDOWN_NOMINATION_DECISION.csv',
   [string]$DecisionMarkdown='outputs\THREE_LANE_ADAPTIVE_EXIT_MOMENTUM_COOLDOWN_NOMINATION_DECISION.md'
)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Assert-Hash([string]$Path,[string]$Expected,[string]$Label){$actual=(Get-FileHash (Resolve-RepoPath $Path) -Algorithm SHA256).Hash.ToUpperInvariant();if($actual-ne$Expected){throw "$Label identity changed: $actual"}}
function Number($Value){return [double]::Parse([string]$Value,[Globalization.CultureInfo]::InvariantCulture)}
$analyzer='work\analyze_three_lane_adaptive_exit_momentum_cooldown_ledger.ps1'
$contract='outputs\THREE_LANE_ADAPTIVE_EXIT_MOMENTUM_COOLDOWN_NOMINATION_CONTRACT.md'
Assert-Hash $analyzer '04430AD6B156EEA06D893F7B53A192F68D76511E90D4CF392FB76B826B5B7953' 'Analyzer'
Assert-Hash $contract '0AA422A17E7B0504F2CE7CCD3F53EB0B15BB1DC7B98F632991AF0A59DBA9D067' 'Contract'
Assert-Hash 'outputs\THREE_LANE_ADAPTIVE_EXIT_MOMENTUM_COOLDOWN_TRAINING.csv' '53C16E97C6C35136515871916428118B6D67EE7F054C11E42860B2FBF811054E' 'Training CSV'
Assert-Hash 'outputs\THREE_LANE_ADAPTIVE_EXIT_MOMENTUM_COOLDOWN_TRAINING.md' 'ECBA7E7532D26C9B708D617FBDA415DBBBF5B9A302EF156A00E64ADFCF116195' 'Training Markdown'
& (Resolve-RepoPath $analyzer) -FromYear 2019 -ToYear 2020 -OutCsv $ValidationCsv -OutMarkdown $ValidationMarkdown|Out-Null
$rows=@(Import-Csv (Resolve-RepoPath $ValidationCsv))
if($rows.Count-ne4){throw "Expected four validation rows, found $($rows.Count)."}
$center=@($rows|Where-Object CooldownMinutes -eq '2160');if($center.Count-ne1){throw 'Frozen 36-hour center is missing.'}
$center=$center[0]
$centerPass=(Number $center.AffectedTrades)-ge2-and(Number $center.AffectedNet)-le-10.0-and(Number $center.AffectedProfitFactor)-lt1.0-and(Number $center.OfflineProjectedImprovement)-ge10.0
$neighbors=@($rows|Where-Object CooldownMinutes -in @('1440','2880','4320'))
$neighborPasses=@($neighbors|Where-Object{(Number $_.AffectedNet)-lt0-and(Number $_.AffectedProfitFactor)-lt1.0}).Count
$overall=$centerPass-and$neighborPasses-ge2
$decisionRows=foreach($row in $rows){
   $isCenter=$row.CooldownMinutes-eq'2160'
   $pass=if($isCenter){$centerPass}else{(Number $row.AffectedNet)-lt0-and(Number $row.AffectedProfitFactor)-lt1.0}
   [pscustomobject][ordered]@{CooldownHours=$row.CooldownHours;Role=if($isCenter){'frozen_center'}else{'fixed_sensitivity'};AffectedTrades=$row.AffectedTrades;AffectedNet=$row.AffectedNet;AffectedProfitFactor=$row.AffectedProfitFactor;PortfolioControlNet=$row.PortfolioControlNet;OfflineProjectedPortfolioNet=$row.OfflineProjectedPortfolioNet;OfflineProjectedImprovement=$row.OfflineProjectedImprovement;GatePass=$pass}
}
$decisionRows|Export-Csv (Resolve-RepoPath $DecisionCsv) -NoTypeInformation -Encoding ASCII
$validationHash=(Get-FileHash (Resolve-RepoPath $ValidationCsv) -Algorithm SHA256).Hash.ToUpperInvariant();$validationMarkdownHash=(Get-FileHash (Resolve-RepoPath $ValidationMarkdown) -Algorithm SHA256).Hash.ToUpperInvariant()
$lines=@(
   '# Adaptive-Exit to Momentum Same-Side Cooldown Nomination Decision','',
   $(if($overall){'**Decision: LEDGER VALIDATION PASSED. One default-off pre-2021 executable source fork is permitted; no new best, newer-data run, Model 4 run, forward change, or live approval exists.**'}else{'**Decision: REJECTED IN LEDGER VALIDATION. No EA code, MT5 run, new best, forward change, or live approval is permitted.**'}),'',
   '- Training window: `2015-2018`; validation window: `2019-2020`.',
   '- Frozen center: `36 hours`; fixed sensitivity rows: `24`, `48`, and `72 hours`.',
   '- The analyzer used only symbol, lane, side, exit time, elapsed time, and the current momentum trade outcome for retrospective scoring. The proposed executable rule cannot read prior outcomes.',
   "- Validation CSV SHA-256: ``$validationHash``",
   "- Validation Markdown SHA-256: ``$validationMarkdownHash``",'',
   '| Cooldown | Role | Affected trades | Affected net | PF | Portfolio control | Offline projection | Gate |',
   '|---:|---|---:|---:|---:|---:|---:|---|'
)
foreach($row in $decisionRows){$lines+=('| {0}h | {1} | {2} | {3:+$0.00;-$0.00;$0.00} | {4} | {5:+$0.00;-$0.00;$0.00} | {6:+$0.00;-$0.00;$0.00} | {7} |' -f (Number $row.CooldownHours),$row.Role,(Number $row.AffectedTrades),(Number $row.AffectedNet),(Number $row.AffectedProfitFactor),(Number $row.PortfolioControlNet),(Number $row.OfflineProjectedPortfolioNet),$row.GatePass)}
$lines+=@('','## Frozen Gate','',"- Center pass: ``$centerPass``","- Passing sensitivity rows: ``$neighborPasses/3``; required: ``2/3``",'',$(if($overall){'The cross-lane exhaustion clue transferred to the reserved era strongly enough to justify one executable implementation. The next gate must reproduce the exact disabled control and improve both disjoint pre-2021 eras without weakening PF, drawdown, recovery, or return/drawdown. This ledger projection is not executable performance.'}else{'The cross-lane exhaustion clue did not transfer with enough event count, loss removal, or fixed-neighbor support. The family is closed without strategy code or tester time.'}),'','The verified same-side exit-cooldown leader and frozen forward candidate remain unchanged. The invalid `$100,000` demo is zero forward evidence, and real-account trading remains disabled.')
$lines|Set-Content (Resolve-RepoPath $DecisionMarkdown) -Encoding ASCII
[pscustomobject]@{Decision=if($overall){'LEDGER_VALIDATION_PASS'}else{'REJECTED'};CenterPass=$centerPass;NeighborPasses=$neighborPasses;EaCodeAllowed=$overall;Post2020Allowed=$false;Model4Allowed=$false;ForwardCandidateChanged=$false;RealAccountApproved=$false}
