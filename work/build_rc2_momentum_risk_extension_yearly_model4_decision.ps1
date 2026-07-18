param(
   [string]$QueuePath="outputs\RC2_MOMENTUM_RISK_EXTENSION_YEARLY_MODEL4_QUEUE.csv",
   [string]$ReportDir="outputs\rc2_momentum_risk_extension_yearly_model4_package\reports_here",
   [string]$ResultsPath="outputs\RC2_MOMENTUM_RISK_EXTENSION_YEARLY_MODEL4_RESULTS.csv",
   [string]$GatesPath="outputs\RC2_MOMENTUM_RISK_EXTENSION_YEARLY_MODEL4_GATES.csv",
   [string]$DecisionPath="outputs\RC2_MOMENTUM_RISK_EXTENSION_YEARLY_MODEL4_DECISION.md"
)
$ErrorActionPreference="Stop";Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$path){if([IO.Path]::IsPathRooted($path)){return $path};return Join-Path $repo $path}
function Money([double]$v){$(if($v-ge 0){'+'}else{'-'})+'$'+[math]::Abs($v).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}
$rawResults="work\MRE_YEARLY_RAW_RESULTS.csv";$rawSummary="work\MRE_YEARLY_RAW_SUMMARY.csv";$rawMd="work\MRE_YEARLY_RAW.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMd|Out-Null
if($LASTEXITCODE-ne 0){throw "Yearly report collector failed."}
$queue=@(Import-Csv (Resolve-RepoPath $QueuePath));$raw=@(Import-Csv (Resolve-RepoPath $rawResults));$by=@{};foreach($row in $raw){$by[[string]$row.ExpectedReportName]=$row}
$runner=@{};foreach($path in @(Get-ChildItem (Join-Path $repo "outputs") -Filter "RC2_MOMENTUM_RISK_YEARLY_*.csv" -ErrorAction SilentlyContinue|Sort-Object LastWriteTime)){foreach($row in @(Import-Csv $path.FullName)){$runner[[string]$row.QueueRank]=$row}}
$results=[Collections.Generic.List[object]]::new()
foreach($item in ($queue | Sort-Object { [int]$_.QueueRank })) {
   $parsed=$by[[string]$item.ExpectedReportName]
   $run=$runner[[string]$item.QueueRank]
   if($null -eq $parsed -or $null -eq $run) { throw "Missing yearly evidence for rank $($item.QueueRank)." }
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank;Window=$item.Window;CompletedYear=$item.CompletedYear
      Status=$parsed.Status;NetProfit=$parsed.NetProfit;TotalReturnPercent=$parsed.TotalReturnPercent
      CagrPercent=$parsed.CagrPercent;ProfitFactor=$parsed.ProfitFactor;TotalTrades=$parsed.TotalTrades
      MaxDrawdownPercent=$parsed.MaxDrawdownPercent;RecoveryFactor=$parsed.RecoveryFactor
      SourceSha256=$item.SourceSha256;ProfileSha256=$item.ProfileSha256
      RunnerStatus=$run.Status;RunnerEvidence=$run.Evidence
   })|Out-Null
}
if($results.Count -ne 12 -or @($results | Where-Object { $_.Status -ne "PARSED" -or $_.RunnerStatus -ne "REPORT_FOUND" }).Count -ne 0) {
   throw "Expected 12 parsed identity-valid yearly reports."
}
$results|Export-Csv (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$completed=@($results | Where-Object CompletedYear -eq "True" | Sort-Object { [int]$_.Window })
$active=@($results | Where-Object { [int]$_.TotalTrades -gt 0 })
$sum=[double](($results | Measure-Object NetProfit -Sum).Sum)
$positive=@($completed | Where-Object { [double]$_.NetProfit -gt 0 }).Count
$red=@($completed | Where-Object { [double]$_.NetProfit -lt 0 }).Count
$worstPair=[double]::PositiveInfinity
$worstLabel=""
for($i=0;$i -lt $completed.Count-1;$i++) {
   $pair=[double]$completed[$i].NetProfit+[double]$completed[$i+1].NetProfit
   if($pair -lt $worstPair) {
      $worstPair=$pair
      $worstLabel="$($completed[$i].Window)-$($completed[$i+1].Window)"
   }
}
$recent=[double](($results | Where-Object { $_.Window -in @('2023','2024','2025','2026_ytd') } | Measure-Object NetProfit -Sum).Sum)
$gates=[Collections.Generic.List[object]]::new()
function Add-Gate([string]$name,[bool]$pass,[string]$evidence) {
   $gates.Add([pscustomobject]@{Gate=$name;Pass=$pass;Evidence=$evidence})|Out-Null
}
$worstYear=$results | Sort-Object { [double]$_.NetProfit } | Select-Object -First 1
$pfFailures=@($active | Where-Object {
   $pf=[double]$_.ProfitFactor
   ($pf -gt 0 -and $pf -lt 0.85) -or ($pf -eq 0 -and [double]$_.NetProfit -le 0)
})
$minimumFinitePf=$active | Where-Object { [double]$_.ProfitFactor -gt 0 } | Sort-Object { [double]$_.ProfitFactor } | Select-Object -First 1
$allWinnerYears=@($active | Where-Object { [double]$_.ProfitFactor -eq 0 -and [double]$_.NetProfit -gt 0 }).Window
$maximumDd=$active | Sort-Object { [double]$_.MaxDrawdownPercent } -Descending | Select-Object -First 1
Add-Gate "reports" ($results.Count -eq 12) "parsed=$($results.Count)/12"
Add-Gate "annual-loss-floor" (@($results | Where-Object { [double]$_.NetProfit -lt -75 }).Count -eq 0) "worst=$(Money ([double]$worstYear.NetProfit))"
Add-Gate "positive-completed-years" ($positive -ge 8) "positive=$positive/11"
Add-Gate "red-completed-years" ($red -le 3) "red=$red/11"
Add-Gate "adjacent-two-year-floor" ($worstPair -ge -100) "$worstLabel=$(Money $worstPair)"
Add-Gate "restart-net-retention" ($sum -ge 0.80*1812.42) "sum=$(Money $sum);floor=$(Money (0.80*1812.42))"
Add-Gate "active-year-profit-factor" ($pfFailures.Count -eq 0) "minimum-finite=$($minimumFinitePf.ProfitFactor);all-winner-years=$($allWinnerYears -join ',')"
Add-Gate "annual-drawdown" (@($active | Where-Object { [double]$_.MaxDrawdownPercent -gt 4 }).Count -eq 0) "maximum=$($maximumDd.MaxDrawdownPercent)%"
Add-Gate "recent-net" ($recent -gt 0) "2023-2026=$(Money $recent)"
$gates|Export-Csv (Resolve-RepoPath $GatesPath) -NoTypeInformation -Encoding ASCII
$passed=@($gates | Where-Object { !$_.Pass }).Count -eq 0

$md=[Collections.Generic.List[string]]::new()
$md.Add("# RC2 Momentum-Risk Extension Yearly Model4 Decision")
$md.Add("")
$md.Add($(if($passed){"**Decision: ANNUAL RESTART GATE PASSED. This does not change the frozen forward candidate or approve real money.**"}else{"**Decision: ANNUAL RESTART GATE FAILED. The research profile is not money-ready and the frozen forward candidate remains unchanged.**"}))
$md.Add("")
$md.Add("- Reports: ``12 / 12`` parsed and source-identity valid")
$md.Add("- Summed restart net: ``$(Money $sum)``")
$md.Add("- Positive completed years: ``$positive / 11``; red completed years: ``$red / 11``")
$md.Add("- Worst adjacent pair: ``$worstLabel``, ``$(Money $worstPair)``")
$md.Add("")
$md.Add("| Window | Net | Return | PF | Trades | DD | Recovery |")
$md.Add("|---|---:|---:|---:|---:|---:|---:|")
foreach($row in $results) {
   $md.Add("| $($row.Window) | $(Money ([double]$row.NetProfit)) | $($row.TotalReturnPercent)% | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) |")
}
$md.Add("")
$md.Add("## Frozen Gates")
$md.Add("")
$md.Add("| Gate | Pass | Evidence |")
$md.Add("|---|---:|---|")
foreach($gate in $gates) { $md.Add("| $($gate.Gate) | $($gate.Pass) | $($gate.Evidence) |") }
$md.Add("")
$md.Add("These are restart checks over inspected history, not untouched out-of-sample proof.")
$md|Set-Content (Resolve-RepoPath $DecisionPath) -Encoding ASCII

[pscustomobject]@{
   Status=$(if($passed){"ANNUAL_GATE_PASSED"}else{"ANNUAL_GATE_FAILED"})
   Reports=12;PositiveYears=$positive;RedYears=$red;RestartNet=[math]::Round($sum,2)
   WorstPair=[math]::Round($worstPair,2);GatesPassed=@($gates|Where-Object Pass).Count
   GatesTotal=$gates.Count;ForwardCandidateChanged=$false
}
