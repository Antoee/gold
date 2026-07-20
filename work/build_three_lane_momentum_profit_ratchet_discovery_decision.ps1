param(
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_PROFIT_RATCHET_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_momentum_profit_ratchet_discovery_model1_package\reports_here',
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Momentum_Profit_Ratchet_Research.mq5',
   [string]$ResultsPath = 'outputs\THREE_LANE_MOMENTUM_PROFIT_RATCHET_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_MOMENTUM_PROFIT_RATCHET_DISCOVERY_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_MOMENTUM_PROFIT_RATCHET_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_MOMENTUM_PROFIT_RATCHET_DISCOVERY_DECISION.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceHash = '04E9A3FA2B85090A53E7B9D769BA536693D7A590794F58AD97F926D5CB2AFAF4'
$expectedBinaryHash = '6B0959FE621763A5137523127BD17B224363D84E2DB3EDBD60B76DDB1B66E321'
$retryRanks = @(1,4)

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Format-Money([double]$Value) {
   return $(if($Value -ge 0.0) { '+' } else { '-' }) + '$' +
          [math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}
function Return-Drawdown([object]$Row) {
   if([double]$Row.MaxDrawdownPercent -le 0.0) { return 0.0 }
   return [math]::Round([double]$Row.TotalReturnPercent / [double]$Row.MaxDrawdownPercent,4)
}

$source = Resolve-RepoPath $SourcePath
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Profit-ratchet source identity changed: $sourceHash" }
$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
if($manifest.Count -ne 24 -or @($manifest.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or
   $manifest[0].SourceSha256 -ne $sourceHash) { throw 'Manifest/source identity or row count failed.' }

$rawResults = Join-Path $repo 'work\MPR_RAW_RESULTS.csv'
$rawSummary = Join-Path $repo 'work\MPR_RAW_SUMMARY.csv'
$rawMetrics = Join-Path $repo 'work\MPR_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir `
   -ReportNameTemplate '{ExpectedReportName}' -OutResults 'work\MPR_RAW_RESULTS.csv' `
   -OutSummary 'work\MPR_RAW_SUMMARY.csv' -OutMarkdown 'work\MPR_RAW_METRICS.md' | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }

$raw = @(Import-Csv -LiteralPath $rawResults)
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$results = [Collections.Generic.List[object]]::new()
foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   if($null -eq $parsed -or $parsed.Status -ne 'PARSED') { throw "Report did not parse: $($item.ExpectedReportName)" }
   $report = Resolve-RepoPath ([string]$parsed.ReportPath)
   $reportText = Get-Content -LiteralPath $report -Raw
   $identity = $reportText.IndexOf($sourceHash,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and
               $reportText.IndexOf('InpMOUseProfitRatchet=',[StringComparison]::Ordinal) -ge 0 -and
               $reportText.IndexOf('InpMOProfitRatchetTriggerR=',[StringComparison]::Ordinal) -ge 0 -and
               $reportText.IndexOf('InpMOProfitRatchetLockR=',[StringComparison]::Ordinal) -ge 0
   if(!$identity) { throw "Report identity failed: $($item.ExpectedReportName)" }
   $identityPath = Join-Path (Split-Path -Parent $report) "$($item.ExpectedReportName).identity.json"
   if(!(Test-Path -LiteralPath $identityPath -PathType Leaf)) { throw "Identity sidecar missing: $($item.ExpectedReportName)" }
   $identityJson = Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json
   if($identityJson.SourceSha256 -ne $sourceHash -or
      $identityJson.PortableBinarySha256 -ne $expectedBinaryHash -or
      $identityJson.ReportSha256 -ne (Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash.ToUpperInvariant()) {
      throw "Identity sidecar mismatch: $($item.ExpectedReportName)"
   }
   $results.Add([pscustomobject][ordered]@{
      QueueRank=$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window
      From=$item.From;To=$item.To;Model=$item.Model;Deposit=$item.Deposit
      FeatureEnabled=$item.FeatureEnabled;RatchetTriggerR=$item.RatchetTriggerR;RatchetLockR=$item.RatchetLockR
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$expectedBinaryHash
      Status=$parsed.Status;ReportDisposition=$(if([int]$item.QueueRank -in $retryRanks){'REPRODUCED_AFTER_IDENTITY_RETRY'}else{'FIRST_VALID_EXPORT'})
      IdentitySidecarVerified=$true;PortableExpertRecompiled=$false
      InitialDeposit=$parsed.InitialDeposit;NetProfit=$parsed.NetProfit;TotalReturnPercent=$parsed.TotalReturnPercent
      CagrPercent=$parsed.CagrPercent;ProfitFactor=$parsed.ProfitFactor;ExpectedPayoff=$parsed.ExpectedPayoff
      SharpeRatio=$parsed.SharpeRatio;WinRatePercent=$parsed.WinRatePercent;TotalTrades=$parsed.TotalTrades
      MaxConsecutiveLosses=$parsed.MaxConsecutiveLosses;MaxDrawdownPercent=$parsed.MaxDrawdownPercent
      RecoveryFactor=$parsed.RecoveryFactor;ReturnDrawdown=(Return-Drawdown $parsed)
      ReportSha256=(Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash.ToUpperInvariant()
   }) | Out-Null
}
if($results.Count -ne 24) { throw "Expected 24 parsed reports; found $($results.Count)." }
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$sets = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $older = $group.Group | Where-Object Window -eq 'discovery_2015_2018' | Select-Object -First 1
   $later = $group.Group | Where-Object Window -eq 'discovery_2019_2020' | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq 'continuous_2015_2020' | Select-Object -First 1
   if(!$older -or !$later -or !$continuous) { throw "Incomplete candidate windows: $($group.Name)" }
   $sets[$group.Name] = [pscustomobject]@{Older=$older;Later=$later;Continuous=$continuous}
}
$control = $sets['mpr_control'].Continuous
$controlReproduced = [math]::Abs([double]$control.NetProfit - 1379.93) -le 0.01 -and
                     [int]$control.TotalTrades -eq 261 -and
                     [math]::Abs([double]$control.ProfitFactor - 1.88) -le 0.01 -and
                     [math]::Abs([double]$control.MaxDrawdownPercent - 1.05) -le 0.01

function Profile-Pass([string]$Name) {
   $set = $sets[$Name]; $row = $set.Continuous
   return [double]$set.Older.NetProfit -ge [double]$sets['mpr_control'].Older.NetProfit -and
      [double]$set.Later.NetProfit -ge [double]$sets['mpr_control'].Later.NetProfit -and
      [double]$row.NetProfit -ge 1.03 * [double]$control.NetProfit -and
      [double]$row.CagrPercent -ge [double]$control.CagrPercent + 0.05 -and
      [double]$row.ProfitFactor -ge [double]$control.ProfitFactor -and
      [double]$row.RecoveryFactor -ge [double]$control.RecoveryFactor -and
      [double]$row.ReturnDrawdown -ge [double]$control.ReturnDrawdown -and
      [double]$row.MaxDrawdownPercent -le [math]::Min(1.20,[double]$control.MaxDrawdownPercent + 0.10) -and
      [int]$row.TotalTrades -ge [math]::Ceiling(0.98 * [int]$control.TotalTrades)
}

$centerPass = Profile-Pass 'mpr_center'
$neighborNames = @('mpr_trigger125','mpr_trigger175','mpr_lock050','mpr_lock100','mpr_conservative','mpr_aggressive')
$passingNeighbors = @($neighborNames | Where-Object { Profile-Pass $_ })
$allReportsProfitable = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$centerChanged = [math]::Abs([double]$sets['mpr_center'].Continuous.NetProfit - [double]$control.NetProfit) -gt 0.01
$passed = $allReportsProfitable -and $controlReproduced -and $centerChanged -and $centerPass -and $passingNeighbors.Count -ge 3

$summary = [Collections.Generic.List[object]]::new()
foreach($name in @('mpr_control','mpr_trigger125','mpr_center','mpr_trigger175','mpr_lock050','mpr_lock100','mpr_conservative','mpr_aggressive')) {
   $set=$sets[$name];$row=$set.Continuous
   $summary.Add([pscustomobject][ordered]@{
      Candidate=$name;Role=$row.Role;RatchetTriggerR=$row.RatchetTriggerR;RatchetLockR=$row.RatchetLockR
      Net2015To2018=$set.Older.NetProfit;Net2019To2020=$set.Later.NetProfit;ContinuousNetProfit=$row.NetProfit
      ImprovementPercent=[math]::Round(100.0*([double]$row.NetProfit-[double]$control.NetProfit)/[double]$control.NetProfit,3)
      TotalReturnPercent=$row.TotalReturnPercent;CagrPercent=$row.CagrPercent;ProfitFactor=$row.ProfitFactor
      Trades=$row.TotalTrades;MaxDrawdownPercent=$row.MaxDrawdownPercent;RecoveryFactor=$row.RecoveryFactor
      ReturnDrawdown=$row.ReturnDrawdown;FrozenGate=$(if($name-eq'mpr_control'){'CONTROL'}elseif(Profile-Pass $name){'PASS'}else{'FAIL'})
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status=$(if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'})
   ReportsParsed=$results.Count;IdentityRetries=$retryRanks.Count;AllReportsProfitable=$allReportsProfitable
   ControlReproduced=$controlReproduced;CenterChangedBehavior=$centerChanged;CenterGatePass=$centerPass
   PassingNeighbors=$passingNeighbors.Count;RequiredNeighbors=3;PassingNeighborNames=($passingNeighbors -join ';')
   Reserved2021To2022Permitted=$passed;Model4Permitted=$false;PromotionPermitted=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
   ControlNetProfit=$control.NetProfit;CenterNetProfit=$sets['mpr_center'].Continuous.NetProfit
   SourceSha256=$sourceHash;BinarySha256=$expectedBinaryHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md=[Collections.Generic.List[string]]::new()
$md.Add('# Momentum Profit Ratchet Discovery Decision');$md.Add('')
$md.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Only the frozen center may enter reserved 2021-2022 Model 1 validation.**'}else{'**Decision: REJECTED IN DISCOVERY. Post-2020 data, Model 4, promotion, forward substitution, and live approval remain closed.**'}));$md.Add('')
$md.Add("- Exact reports: ``$($results.Count) / 24``; unchanged identity retries: ``$($retryRanks.Count)``")
$md.Add("- Source SHA-256: ``$sourceHash``");$md.Add("- EX5 SHA-256: ``$expectedBinaryHash``")
$md.Add('- Entry, initial stop, take-profit distance, position risk, exposure cap, and safety locks were unchanged; only the optional completed-bar second-stage stop ratchet changed.');$md.Add('')
$md.Add('| Profile | 2015-18 | 2019-20 | Continuous | Improvement | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $summary){$md.Add("| ``$($row.Candidate)`` | $(Format-Money $row.Net2015To2018) | $(Format-Money $row.Net2019To2020) | $(Format-Money $row.ContinuousNetProfit) | $($row.ImprovementPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.Trades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) | $($row.FrozenGate) |")}
$md.Add('');$md.Add('## Frozen Gate');$md.Add('')
$md.Add("- Every report profitable: ``$allReportsProfitable``")
$md.Add("- Exact control reproduced: ``$controlReproduced``")
$md.Add("- Center changed behavior: ``$centerChanged``")
$md.Add("- Center complete gate: ``$centerPass``")
$md.Add("- Passing one-factor neighbors: ``$($passingNeighbors.Count) / 6``; required ``3``; names: ``$($passingNeighbors -join ';')``")
$md.Add('');$md.Add('The published historical leader, registered forward identity, invalid-account boundary, and real-account lock remain unchanged.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath $rawResults,$rawSummary,$rawMetrics -Force -ErrorAction SilentlyContinue
$decision
