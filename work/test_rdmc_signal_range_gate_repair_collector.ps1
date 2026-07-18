Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$collector = Join-Path $repo 'work\collect_rdmc_signal_range_gate_repair_results.ps1'
$fixtureName = '.rdmc_signal_range_collector_' + [guid]::NewGuid().ToString('N')
$fixtureRelative = Join-Path 'outputs' $fixtureName
$fixtureRoot = Join-Path $repo $fixtureRelative
$packageRoot = Join-Path $fixtureRoot 'package'
$reportRoot = Join-Path $packageRoot 'reports_here'
$profileRoot = Join-Path $packageRoot 'profiles'
$sourceProfiles = Join-Path $repo 'outputs\rdmc_signal_range_gate_repair_model1_package\profiles'
$sourceHash = '32DE39C13DBE06A6AE2BD733ED2183D7103C003884F08DD13024FDEE18BAD241'
$checks = [Collections.Generic.List[object]]::new()

function Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{Check=$Name;Pass=$Pass;Evidence=$Evidence}) | Out-Null
   if(!$Pass) { throw "$Name failed: $Evidence" }
}

New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
New-Item -ItemType Directory -Path $profileRoot -Force | Out-Null
try {
   Copy-Item -LiteralPath (Join-Path $sourceProfiles 'srg_control.set') -Destination $profileRoot
   Copy-Item -LiteralPath (Join-Path $sourceProfiles 'srg_min100.set') -Destination $profileRoot
   Copy-Item -LiteralPath (Join-Path $sourceProfiles 'srg_min125_center.set') -Destination $profileRoot
   Copy-Item -LiteralPath (Join-Path $sourceProfiles 'srg_min150.set') -Destination $profileRoot

   $queue = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_QUEUE.csv'))
   $manifest = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_MANIFEST.csv'))
   $queuePath = Join-Path $fixtureRoot 'queue.csv'
   $manifestPath = Join-Path $fixtureRoot 'manifest.csv'
   $queue | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII
   $manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII

   $runRows = foreach($row in $queue) {
      $reportPath = Join-Path $reportRoot ($row.ExpectedReportName + '.htm')
      $net = if($row.Window -eq 'year_2019') { '10.00' } else { '20.00' }
      @"
<html><body>
<div>Source identity: $sourceHash</div>
<div>Initial Deposit: 10000</div>
<div>Total Net Profit: $net</div>
<div>Final Balance: 10030.00</div>
<div>Profit Factor: 1.25</div>
<div>Expected Payoff: 1.50</div>
<div>Sharpe Ratio: 0.20</div>
<div>Total Trades: 20</div>
<div>Equity Drawdown Maximal: 100.00 (1.00%)</div>
<div>Maximum consecutive losses: 3</div>
</body></html>
"@ | Set-Content -LiteralPath $reportPath -Encoding ASCII
      [pscustomobject]@{
         Worker='1';QueueRank=$row.QueueRank;Candidate=$row.Candidate;Window=$row.Window
         Status='REPORT_FOUND';ReportPath=$reportPath;Evidence='Synthetic parser fixture.'
         PackageSourceSha256=$sourceHash;PortableBinarySha256='';PortableExpertRecompiled='False'
         Started='2026-07-18T00:00:00';Finished='2026-07-18T00:00:01'
      }
   }
   $initialRun = Join-Path $fixtureRoot 'initial_01.csv'
   $runRows | Export-Csv -LiteralPath $initialRun -NoTypeInformation -Encoding ASCII

   $args = @{
      QueuePath=(Join-Path $fixtureRelative 'queue.csv')
      ManifestPath=(Join-Path $fixtureRelative 'manifest.csv')
      ReportDir=(Join-Path $fixtureRelative 'package\reports_here')
      InitialRunGlob=(Join-Path $fixtureRelative 'initial_*.csv')
      RetryRunGlob=(Join-Path $fixtureRelative 'retry_*.csv')
      RawResultsPath=(Join-Path $fixtureRelative 'raw.csv')
      ResultsPath=(Join-Path $fixtureRelative 'results.csv')
      RunPath=(Join-Path $fixtureRelative 'run.csv')
      SummaryPath=(Join-Path $fixtureRelative 'summary.csv')
      MarkdownPath=(Join-Path $fixtureRelative 'metrics.md')
   }
   $result = & $collector @args
   Check 'all synthetic reports parsed' ($result.Status -eq 'PARSED' -and [int]$result.Reports -eq 8) "reports=$($result.Reports)"
   $parsed = @(Import-Csv -LiteralPath (Join-Path $fixtureRoot 'results.csv'))
   Check 'identity fields retained' (@($parsed | Where-Object { $_.SourceSha256 -ne $sourceHash -or $_.RunnerStatus -ne 'REPORT_FOUND' }).Count -eq 0) '8 identity-valid rows'
   Check 'canonical paths are relative' (@($parsed | Where-Object { [IO.Path]::IsPathRooted($_.ReportPath) }).Count -eq 0) 'no machine-specific paths'

   $tamperedReport = Join-Path $reportRoot ($queue[0].ExpectedReportName + '.htm')
   (Get-Content -LiteralPath $tamperedReport -Raw).Replace($sourceHash, ('0' * 64)) | Set-Content -LiteralPath $tamperedReport -Encoding ASCII
   $tamperRejected = $false
   try { & $collector @args | Out-Null } catch { $tamperRejected = $_.Exception.Message -match 'Report source identity missing' }
   Check 'stale report rejected' $tamperRejected 'embedded source identity enforced'

   $checks | Format-Table -AutoSize
   "PASS: $($checks.Count) RDMC signal-range collector checks"
}
finally {
   $resolvedOutputs = [IO.Path]::GetFullPath((Join-Path $repo 'outputs'))
   $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
   if($resolvedFixture.StartsWith($resolvedOutputs + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($resolvedFixture).StartsWith('.rdmc_signal_range_collector_')) {
      Remove-Item -LiteralPath $resolvedFixture -Recurse -Force -ErrorAction SilentlyContinue
   }
}
