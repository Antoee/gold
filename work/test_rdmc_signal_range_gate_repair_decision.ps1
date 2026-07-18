Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$builder = Join-Path $repo 'work\build_rdmc_signal_range_gate_repair_decision.ps1'
$queue = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_QUEUE.csv'))
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testRoot = Join-Path $tempRoot ('rdmc_signal_range_decision_' + [guid]::NewGuid().ToString('N'))
$checks = [Collections.Generic.List[object]]::new()

function Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{Check=$Name;Pass=$Pass;Evidence=$Evidence}) | Out-Null
   if(!$Pass) { throw "$Name failed: $Evidence" }
}

function New-Fixture([hashtable]$Nets, [hashtable]$Trades, [string]$Path) {
   $rows = foreach($item in $queue) {
      $key = "$($item.Candidate)|$($item.Window)"
      [pscustomobject]@{
         QueueRank=$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window
         From=$item.From;To=$item.To;Model=$item.Model;Deposit=$item.Deposit
         ExpectedReportName=$item.ExpectedReportName;Status='PARSED';RunnerStatus='REPORT_FOUND'
         ReportPath="outputs\fixture\$($item.ExpectedReportName).htm";ProfileSha256=$item.ProfileSha256
         SourceSha256=$item.SourceSha256;BaseProfileSha256=$item.BaseProfileSha256;ContractSha256=$item.ContractSha256
         SignalRangeGateEnabled=$item.SignalRangeGateEnabled;MinimumSignalRangeATR=$item.MinimumSignalRangeATR
         InitialDeposit='10000';NetProfit=[string]$Nets[$key];Balance=[string](10000 + [double]$Nets[$key])
         TotalReturnPercent='0';AnnualizedReturnPercent='0';CagrPercent='0';ProfitFactor='1.2'
         ExpectedPayoff='1';SharpeRatio='0.1';WinRatePercent='50';TotalTrades=[string]$Trades[$key]
         MaxConsecutiveLosses='3';MaxDrawdownMoney='100';MaxDrawdownPercent='1';BalanceDrawdownMaximal='100'
         EquityDrawdownMaximal='100';RecoveryFactor='1'
      }
   }
   $rows | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding ASCII
}

function Invoke-Fixture([string]$Name, [hashtable]$Nets, [hashtable]$Trades) {
   $inputPath = Join-Path $testRoot "$Name.csv"
   $decisionPath = Join-Path $testRoot "$Name.decision.csv"
   $markdownPath = Join-Path $testRoot "$Name.md"
   New-Fixture -Nets $Nets -Trades $Trades -Path $inputPath
   $result = & $builder -ResultsPath $inputPath -DecisionCsvPath $decisionPath -DecisionMarkdownPath $markdownPath
   return [pscustomobject]@{Result=$result;Input=$inputPath;Decision=$decisionPath;Markdown=$markdownPath}
}

$defaultTrades = @{}
$queue | ForEach-Object { $defaultTrades["$($_.Candidate)|$($_.Window)"] = 20 }
$baseNets = @{
   'srg_control|year_2019'=-3.77;'srg_control|year_2022'=-92.78
   'srg_min100|year_2019'=10;'srg_min100|year_2022'=15
   'srg_min125_center|year_2019'=20;'srg_min125_center|year_2022'=30
   'srg_min150|year_2019'=-1;'srg_min150|year_2022'=25
}

New-Item -ItemType Directory -Path $testRoot | Out-Null
try {
   $pass = Invoke-Fixture -Name 'pass' -Nets $baseNets -Trades $defaultTrades
   Check 'pass branch opens Model4 only' ($pass.Result.Decision -eq 'OPEN_MODEL4' -and $pass.Result.RealMoneyLocked -eq $true -and $pass.Result.RegisteredForwardCandidateChanged -eq $false) ([string]$pass.Result.Decision)
   $passMarkdown = Get-Content -LiteralPath $pass.Markdown -Raw
   Check 'pass text forbids promotion' ($passMarkdown -match 'no candidate is promoted' -and $passMarkdown -match 'Real-money trading remains locked') 'explicit research-only language'

   $centerFailNets = @{} + $baseNets
   $centerFailNets['srg_min125_center|year_2019'] = -0.01
   $centerFail = Invoke-Fixture -Name 'center_fail' -Nets $centerFailNets -Trades $defaultTrades
   Check 'losing center rejects before Model4' ($centerFail.Result.Decision -eq 'REJECT_BEFORE_MODEL4') ([string]$centerFail.Result.Decision)

   $neighborFailNets = @{} + $baseNets
   $neighborFailNets['srg_min100|year_2019'] = -0.01
   $neighborFailNets['srg_min150|year_2022'] = -0.01
   $neighborFail = Invoke-Fixture -Name 'neighbor_fail' -Nets $neighborFailNets -Trades $defaultTrades
   Check 'no passing neighbor rejects' ($neighborFail.Result.Decision -eq 'REJECT_BEFORE_MODEL4') ([string]$neighborFail.Result.Decision)

   $activityFailTrades = @{} + $defaultTrades
   $activityFailTrades['srg_min100|year_2022'] = 17
   $activityFailTrades['srg_min150|year_2019'] = 17
   $activityFail = Invoke-Fixture -Name 'activity_fail' -Nets $baseNets -Trades $activityFailTrades
   Check 'insufficient activity rejects' ($activityFail.Result.Decision -eq 'REJECT_BEFORE_MODEL4') ([string]$activityFail.Result.Decision)

   $tamperInput = Join-Path $testRoot 'identity_tamper.csv'
   New-Fixture -Nets $baseNets -Trades $defaultTrades -Path $tamperInput
   $tampered = @(Import-Csv -LiteralPath $tamperInput)
   $tampered[0].SourceSha256 = ('0' * 64)
   $tampered | Export-Csv -LiteralPath $tamperInput -NoTypeInformation -Encoding ASCII
   $identityRejected = $false
   try {
      & $builder -ResultsPath $tamperInput -DecisionCsvPath (Join-Path $testRoot 'tamper.decision.csv') -DecisionMarkdownPath (Join-Path $testRoot 'tamper.md') | Out-Null
   } catch { $identityRejected = $_.Exception.Message -match 'Source identity mismatch' }
   Check 'source tamper rejected' $identityRejected 'exact source hash enforced'

   Check 'decision rows emitted' (@(Import-Csv -LiteralPath $pass.Decision).Count -eq 4) 'four profile summaries'
   $checks | Format-Table -AutoSize
   "PASS: $($checks.Count) RDMC signal-range decision checks"
}
finally {
   $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
   if($resolvedTestRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($resolvedTestRoot).StartsWith('rdmc_signal_range_decision_')) {
      Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force -ErrorAction SilentlyContinue
   }
}
