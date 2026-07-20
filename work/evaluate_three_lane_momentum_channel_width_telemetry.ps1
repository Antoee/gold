[CmdletBinding()]
param(
   [string]$LedgerPath = 'outputs\THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_TRADES.csv',
   [string]$NominationPath = 'outputs\THREE_LANE_MOMENTUM_CHANNEL_WIDTH_NOMINATION.md',
   [string]$ValidationPath = 'outputs\THREE_LANE_MOMENTUM_CHANNEL_WIDTH_VALIDATION.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_MOMENTUM_CHANNEL_WIDTH_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_MOMENTUM_CHANNEL_WIDTH_DECISION.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedLedgerHash = 'B3913BD8667C8552937D921197E4949DCA5822075A943F5F8C0032DE77542A3F'
$expectedNominationHash = '5618C9E77EBD9F33A46FBD4A52067D3C408F05D4D929422F3EAC15436FD36C2F'
$portfolioControlNet = 1379.93
$minimumFullImprovement = 0.02 * $portfolioControlNet

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Sum-Profit([object[]]$Rows) {
   if($Rows.Count -eq 0) { return 0.0 }
   return [double](($Rows | Measure-Object Profit -Sum).Sum)
}
function Profit-Factor([object[]]$Rows) {
   $grossProfit = Sum-Profit @($Rows | Where-Object { [double]$_.Profit -gt 0.0 })
   $grossLoss = [math]::Abs((Sum-Profit @($Rows | Where-Object { [double]$_.Profit -lt 0.0 })))
   if($grossLoss -le 0.0) { return 0.0 }
   return $grossProfit / $grossLoss
}
function Format-Money([double]$Value) {
   return $(if($Value -ge 0.0) { '+' } else { '-' }) + '$' +
          [math]::Abs($Value).ToString('N2', [Globalization.CultureInfo]::InvariantCulture)
}

$ledger = Resolve-RepoPath $LedgerPath
$nomination = Resolve-RepoPath $NominationPath
if((Get-FileHash -LiteralPath $ledger -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedLedgerHash) {
   throw 'Momentum telemetry ledger identity changed.'
}
if((Get-FileHash -LiteralPath $nomination -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedNominationHash) {
   throw 'Frozen channel-width nomination identity changed.'
}

$all = @(Import-Csv -LiteralPath $ledger)
$training = @($all | Where-Object Era -eq 'training_2015_2018')
$validation = @($all | Where-Object Era -eq 'validation_2019_2020')
if($all.Count -ne 194 -or $training.Count -ne 133 -or $validation.Count -ne 61) {
   throw "Unexpected telemetry populations: all=$($all.Count), training=$($training.Count), validation=$($validation.Count)."
}

$controlTrainingNet = Sum-Profit $training
$controlValidationNet = Sum-Profit $validation
$controlValidationPf = Profit-Factor $validation
$control2019 = Sum-Profit @($validation | Where-Object { [int]$_.Year -eq 2019 })
$control2020 = Sum-Profit @($validation | Where-Object { [int]$_.Year -eq 2020 })
$profiles = @(
   [pscustomobject]@{Name='mcw_control';Role='disabled_control';Enabled=$false;Maximum=0.0},
   [pscustomobject]@{Name='mcw_max600';Role='lower_neighbor';Enabled=$true;Maximum=6.0},
   [pscustomobject]@{Name='mcw_center';Role='center';Enabled=$true;Maximum=6.5},
   [pscustomobject]@{Name='mcw_max700';Role='upper_neighbor';Enabled=$true;Maximum=7.0}
)

$rows = [Collections.Generic.List[object]]::new()
foreach($profile in $profiles) {
   $keptTraining = if($profile.Enabled) {
      @($training | Where-Object { [double]$_.ChannelWidthATR -le $profile.Maximum })
   } else { $training }
   $keptValidation = if($profile.Enabled) {
      @($validation | Where-Object { [double]$_.ChannelWidthATR -le $profile.Maximum })
   } else { $validation }
   $validation2019 = @($keptValidation | Where-Object { [int]$_.Year -eq 2019 })
   $validation2020 = @($keptValidation | Where-Object { [int]$_.Year -eq 2020 })
   $trainingNet = Sum-Profit $keptTraining
   $validationNet = Sum-Profit $keptValidation
   $validationPf = Profit-Factor $keptValidation
   $net2019 = Sum-Profit $validation2019
   $net2020 = Sum-Profit $validation2020
   $fullImprovement = ($trainingNet - $controlTrainingNet) + ($validationNet - $controlValidationNet)
   $behaviorChanged = $keptValidation.Count -lt $validation.Count
   $profilePass = $profile.Enabled -and $behaviorChanged -and
      $keptValidation.Count -ge 46 -and
      $controlValidationNet - $validationNet -le 0.0 -and
      $control2019 - $net2019 -le 0.0 -and
      $control2020 - $net2020 -le 0.0 -and
      $validationPf -ge 0.98 * $controlValidationPf -and
      $fullImprovement -ge $minimumFullImprovement
   $rows.Add([pscustomobject][ordered]@{
      Candidate=$profile.Name;Role=$profile.Role;FeatureEnabled=$profile.Enabled
      MaximumChannelWidthATR=$(if($profile.Enabled){$profile.Maximum}else{'disabled'})
      TrainingTrades=$keptTraining.Count;TrainingNet=[math]::Round($trainingNet,2)
      ValidationTrades=$keptValidation.Count;ValidationNet=[math]::Round($validationNet,2)
      ValidationProfitFactor=[math]::Round($validationPf,4)
      Net2019=[math]::Round($net2019,2);Net2020=[math]::Round($net2020,2)
      RemovedValidationNet=[math]::Round($controlValidationNet-$validationNet,2)
      Removed2019Net=[math]::Round($control2019-$net2019,2)
      Removed2020Net=[math]::Round($control2020-$net2020,2)
      FullPeriodMomentumImprovement=[math]::Round($fullImprovement,2)
      ProjectedPortfolioNet=[math]::Round($portfolioControlNet+$fullImprovement,2)
      BehaviorChanged=$behaviorChanged;FrozenGate=$(if(!$profile.Enabled){'CONTROL'}elseif($profilePass){'PASS'}else{'FAIL'})
   }) | Out-Null
}

$center = $rows | Where-Object Candidate -eq 'mcw_center' | Select-Object -First 1
$passing = @($rows | Where-Object FrozenGate -eq 'PASS')
$passingNames = @($passing | Select-Object -ExpandProperty Candidate)
$centerPass = $center.FrozenGate -eq 'PASS'
$passed = $centerPass -and $passing.Count -ge 2
$rows | Export-Csv -LiteralPath (Resolve-RepoPath $ValidationPath) -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status=$(if($passed){'TELEMETRY_VALIDATION_PASSED'}else{'REJECTED_IN_TELEMETRY_VALIDATION'})
   TelemetryTrades=$all.Count;TrainingTrades=$training.Count;ValidationTrades=$validation.Count
   CenterPass=$centerPass;PassingProfiles=$passing.Count;RequiredPassingProfiles=2
   PassingProfileNames=($passingNames -join ';')
   StrategyImplementationPermitted=$passed;Pre2021Model1Permitted=$passed
   Post2020Permitted=$false;Model4Permitted=$false;PromotionPermitted=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
   LedgerSha256=$expectedLedgerHash;NominationSha256=$expectedNominationHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [Collections.Generic.List[string]]::new()
$md.Add('# Momentum Channel-Width Telemetry Decision'); $md.Add('')
$md.Add($(if($passed){
   '**Decision: TELEMETRY VALIDATION PASSED. A default-off implementation may enter paired pre-2021 Model 1 testing only.**'
}else{
   '**Decision: REJECTED IN TELEMETRY VALIDATION. No strategy implementation, MT5 rerun, post-2020 test, Model 4 run, promotion, forward substitution, or live approval is permitted.**'
})); $md.Add('')
$md.Add("- Frozen nomination SHA-256: ``$expectedNominationHash``")
$md.Add("- Exact telemetry ledger SHA-256: ``$expectedLedgerHash``")
$md.Add("- Populations: ``$($training.Count)`` training trades and ``$($validation.Count)`` reserved validation trades")
$md.Add('')
$md.Add('| Profile | Max width | Training net | Validation trades | Validation net | Validation PF | Removed 2019 | Removed 2020 | Full improvement | Projected portfolio | Gate |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $rows) {
   $md.Add("| ``$($row.Candidate)`` | $($row.MaximumChannelWidthATR) | $(Format-Money $row.TrainingNet) | $($row.ValidationTrades) | $(Format-Money $row.ValidationNet) | $($row.ValidationProfitFactor) | $(Format-Money $row.Removed2019Net) | $(Format-Money $row.Removed2020Net) | $(Format-Money $row.FullPeriodMomentumImprovement) | $(Format-Money $row.ProjectedPortfolioNet) | $($row.FrozenGate) |")
}
$md.Add(''); $md.Add('## Frozen Gate'); $md.Add('')
$md.Add("- Center complete gate: ``$centerPass``")
$md.Add("- Passing enabled profiles: ``$($passing.Count) / 3``; required ``2``; names: ``$($passingNames -join ';')``")
$md.Add("- Strategy implementation permitted: ``$passed``")
$md.Add('')
$md.Add('The published historical leader, registered forward identity, invalid-account boundary, and real-account lock remain unchanged.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

$decision
