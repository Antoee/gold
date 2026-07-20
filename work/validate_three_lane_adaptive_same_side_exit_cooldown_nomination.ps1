[CmdletBinding()]
param(
   [string]$ValidationCsv='outputs\THREE_LANE_ADAPTIVE_SAME_SIDE_EXIT_COOLDOWN_VALIDATION.csv',
   [string]$ValidationMarkdown='outputs\THREE_LANE_ADAPTIVE_SAME_SIDE_EXIT_COOLDOWN_VALIDATION.md',
   [string]$DecisionCsv='outputs\THREE_LANE_ADAPTIVE_SAME_SIDE_EXIT_COOLDOWN_NOMINATION_DECISION.csv',
   [string]$DecisionMarkdown='outputs\THREE_LANE_ADAPTIVE_SAME_SIDE_EXIT_COOLDOWN_NOMINATION_DECISION.md'
)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Assert-Hash([string]$Path,[string]$Expected,[string]$Label){$actual=(Get-FileHash (Resolve-RepoPath $Path) -Algorithm SHA256).Hash.ToUpperInvariant();if($actual-ne$Expected){throw "$Label identity changed: $actual"}}
function Number($Value){return [double]::Parse([string]$Value,[Globalization.CultureInfo]::InvariantCulture)}
$analyzer='work\analyze_three_lane_adaptive_same_side_exit_cooldown_ledger.ps1'
$contract='outputs\THREE_LANE_ADAPTIVE_SAME_SIDE_EXIT_COOLDOWN_NOMINATION_CONTRACT.md'
Assert-Hash $analyzer '83C5A5EC6E103E3CA37FA82F4A99ED4819F0C1B3E3C22E0DA06D3B45F86A2C72' 'Analyzer'
Assert-Hash $contract 'FA6284C54AEB36091256654EE91E0734734FD144CDF4E80A3AA776F6C980E6AF' 'Contract'
Assert-Hash 'outputs\THREE_LANE_ADAPTIVE_SAME_SIDE_EXIT_COOLDOWN_TRAINING.csv' '203EA7C1FA219E21E813BF422CE5FE81159F21FF88835C733437F54585CF068B' 'Training CSV'
Assert-Hash 'outputs\THREE_LANE_ADAPTIVE_SAME_SIDE_EXIT_COOLDOWN_TRAINING.md' '15D4B0079A54AE73AD192894FD586FC71206139B38B9CDDFEF03F33B57B4593A' 'Training Markdown'
& (Resolve-RepoPath $analyzer) -FromYear 2019 -ToYear 2020 -OutCsv $ValidationCsv -OutMarkdown $ValidationMarkdown|Out-Null
$rows=@(Import-Csv (Resolve-RepoPath $ValidationCsv));if($rows.Count-ne4){throw "Expected four validation rows, found $($rows.Count)."}
$center=@($rows|Where-Object CooldownMinutes -eq '4320');if($center.Count-ne1){throw 'Frozen 72-hour center is missing.'};$center=$center[0]
$centerPass=(Number $center.AffectedTrades)-ge2-and(Number $center.AffectedNet)-le-10.0-and(Number $center.AffectedProfitFactor)-lt1.0-and(Number $center.OfflineProjectedImprovement)-ge10.0
$neighbors=@($rows|Where-Object CooldownMinutes -in @('2880','5760','7200'))
$neighborPasses=@($neighbors|Where-Object{(Number $_.AffectedNet)-lt0-and(Number $_.AffectedProfitFactor)-lt1.0}).Count
$overall=$centerPass-and$neighborPasses-ge2
$decisionRows=foreach($row in $rows){$isCenter=$row.CooldownMinutes-eq'4320';$pass=if($isCenter){$centerPass}else{(Number $row.AffectedNet)-lt0-and(Number $row.AffectedProfitFactor)-lt1.0};[pscustomobject][ordered]@{CooldownHours=$row.CooldownHours;Role=if($isCenter){'frozen_center'}else{'fixed_sensitivity'};AffectedTrades=$row.AffectedTrades;AffectedNet=$row.AffectedNet;AffectedProfitFactor=$row.AffectedProfitFactor;PortfolioControlNet=$row.PortfolioControlNet;OfflineProjectedPortfolioNet=$row.OfflineProjectedPortfolioNet;OfflineProjectedImprovement=$row.OfflineProjectedImprovement;GatePass=$pass}}
$decisionRows|Export-Csv (Resolve-RepoPath $DecisionCsv) -NoTypeInformation -Encoding ASCII
$validationHash=(Get-FileHash (Resolve-RepoPath $ValidationCsv) -Algorithm SHA256).Hash.ToUpperInvariant();$validationMarkdownHash=(Get-FileHash (Resolve-RepoPath $ValidationMarkdown) -Algorithm SHA256).Hash.ToUpperInvariant()
$lines=@('# Adaptive Same-Side Exit Cooldown Nomination Decision','',$(if($overall){'**Decision: LEDGER VALIDATION PASSED. One default-off pre-2021 executable source fork is permitted; no new best, newer-data run, Model 4 run, forward change, or live approval exists.**'}else{'**Decision: REJECTED IN LEDGER VALIDATION. No EA code, MT5 run, new best, forward change, or live approval is permitted.**'}),'','- Training window: `2015-2018`; validation window: `2019-2020`.','- Frozen center: `72 hours`; fixed sensitivity rows: `48`, `96`, and `120 hours`.','- The analyzer used only symbol, lane, side, exit time, elapsed time, and the current adaptive trade outcome for retrospective scoring. The proposed executable rule cannot read prior outcomes.',"- Validation CSV SHA-256: ``$validationHash``","- Validation Markdown SHA-256: ``$validationMarkdownHash``",'','| Cooldown | Role | Affected trades | Affected net | PF | Portfolio control | Offline projection | Gate |','|---:|---|---:|---:|---:|---:|---:|---|')
foreach($row in $decisionRows){$lines+=('| {0}h | {1} | {2} | {3:+$0.00;-$0.00;$0.00} | {4} | {5:+$0.00;-$0.00;$0.00} | {6:+$0.00;-$0.00;$0.00} | {7} |' -f (Number $row.CooldownHours),$row.Role,(Number $row.AffectedTrades),(Number $row.AffectedNet),(Number $row.AffectedProfitFactor),(Number $row.PortfolioControlNet),(Number $row.OfflineProjectedPortfolioNet),$row.GatePass)}
$lines+=@('','## Frozen Gate','',"- Center pass: ``$centerPass``","- Passing sensitivity rows: ``$neighborPasses/3``; required: ``2/3``",'',$(if($overall){'The same-lane adaptive whipsaw clue transferred to the reserved era strongly enough to justify one executable implementation. The next gate must reproduce the exact disabled control and improve both disjoint pre-2021 eras without weakening PF, drawdown, recovery, or return/drawdown. This ledger projection is not executable performance.'}else{'The adaptive re-entry clue did not transfer with enough event count, loss removal, or fixed-neighbor support. The family is closed without strategy code or tester time.'}),'','The verified momentum same-side exit-cooldown leader and frozen forward candidate remain unchanged. The invalid `$100,000` demo is zero forward evidence, and real-account trading remains disabled.')
$lines|Set-Content (Resolve-RepoPath $DecisionMarkdown) -Encoding ASCII
[pscustomobject]@{Decision=if($overall){'LEDGER_VALIDATION_PASS'}else{'REJECTED'};CenterPass=$centerPass;NeighborPasses=$neighborPasses;EaCodeAllowed=$overall;Post2020Allowed=$false;Model4Allowed=$false;ForwardCandidateChanged=$false;RealAccountApproved=$false}
