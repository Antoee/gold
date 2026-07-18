param(
   [string]$QueuePath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_MANIFEST.csv",
   [string]$ReportDir = "outputs\rdmc_signal_range_gate_repair_model1_package\reports_here",
   [string]$InitialRunGlob = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_PORTABLE_*.csv",
   [string]$RetryRunGlob = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_RERUN_*.csv",
   [string]$RawResultsPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_RAW_RESULTS.csv",
   [string]$ResultsPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_RESULTS.csv",
   [string]$RunPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_RUN.csv",
   [string]$SummaryPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_SUMMARY.csv",
   [string]$MarkdownPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_METRICS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "32DE39C13DBE06A6AE2BD733ED2183D7103C003884F08DD13024FDEE18BAD241"
$expectedBaseProfileHash = "BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC"
$expectedContractHash = "F8864C26088E63494D16E0606DE04C66BB46E99FFC798FE0D40C83AA20AA643C"
$expectedProfileHashes = @{
   srg_control = "A3A44284F53A16466CB046E0DAD284129B95E51A5F23062EC087196CC38D6CBF"
   srg_min100 = "2EBC9550A2D80286E168EC432DBF8A300188323A8AE25AC1ED5ABCBE6E106948"
   srg_min125_center = "1074719B19AE512A72AC4320F656226A791A346FB6ADD910439BA654B3CF8F80"
   srg_min150 = "2C05FA664997A34685EB747C4BDB9A241FD7EB36EDDC664CF51D1606E36BD75C"
}

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
   return [IO.Path]::GetFullPath((Join-Path $repo $Path))
}

function Import-RunGlob([string]$Pattern) {
   $leaf = Split-Path -Leaf $Pattern
   $rawParent = Split-Path -Parent $Pattern
   if([string]::IsNullOrWhiteSpace($rawParent)) { $rawParent = '.' }
   $parent = Resolve-RepoPath $rawParent
   if(!(Test-Path -LiteralPath $parent -PathType Container)) { return @() }
   return @(Get-ChildItem -LiteralPath $parent -Filter $leaf -File -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime, Name |
      ForEach-Object { Import-Csv -LiteralPath $_.FullName })
}

function Convert-ToRepoRelative([string]$Path) {
   $full = [IO.Path]::GetFullPath($Path)
   if(!$full.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Path is outside the repository: $Path"
   }
   return $full.Substring($repo.Length + 1)
}

$queuePathFull = Resolve-RepoPath $QueuePath
$manifestPathFull = Resolve-RepoPath $ManifestPath
$reportRoot = Resolve-RepoPath $ReportDir
$packageRoot = Split-Path -Parent $reportRoot
$queue = @(Import-Csv -LiteralPath $queuePathFull)
$manifest = @(Import-Csv -LiteralPath $manifestPathFull)

if($queue.Count -ne 8 -or $manifest.Count -ne 8) { throw "Expected eight frozen signal-range Model1 rows." }
if(@($queue.QueueRank | Sort-Object -Unique).Count -ne 8) { throw "Queue ranks are not unique." }
if((@($queue.Candidate | Sort-Object -Unique) -join ',') -ne 'srg_control,srg_min100,srg_min125_center,srg_min150') {
   throw "Unexpected candidate family."
}
if((@($queue.Window | Sort-Object -Unique) -join ',') -ne 'year_2019,year_2022') { throw "Unexpected repair windows." }
if(@($queue | Where-Object { $_.Model -ne "1" -or $_.Deposit -ne "10000" }).Count -gt 0) { throw "Unexpected model or deposit." }
if(@($queue | Where-Object SourceSha256 -ne $expectedSourceHash).Count -gt 0) { throw "Queue source identity mismatch." }
if(@($queue | Where-Object BaseProfileSha256 -ne $expectedBaseProfileHash).Count -gt 0) { throw "Queue base-profile identity mismatch." }
if(@($queue | Where-Object ContractSha256 -ne $expectedContractHash).Count -gt 0) { throw "Queue contract identity mismatch." }

foreach($queued in $queue) {
   if(!$expectedProfileHashes.ContainsKey([string]$queued.Candidate)) { throw "Unexpected candidate $($queued.Candidate)." }
   if($queued.ProfileSha256 -ne $expectedProfileHashes[[string]$queued.Candidate]) { throw "Queue profile identity mismatch at rank $($queued.QueueRank)." }
   $profilePath = Join-Path $packageRoot ([string]$queued.ProfileSnapshot)
   if(!(Test-Path -LiteralPath $profilePath -PathType Leaf)) { throw "Profile snapshot missing at rank $($queued.QueueRank)." }
   if((Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash -ne $queued.ProfileSha256) { throw "Profile bytes changed at rank $($queued.QueueRank)." }

   $manifestRows = @($manifest | Where-Object QueueRank -eq $queued.QueueRank)
   if($manifestRows.Count -ne 1) { throw "Manifest row missing or ambiguous at rank $($queued.QueueRank)." }
   $manifestRow = $manifestRows[0]
   foreach($field in @('Candidate','Window','Model','Deposit','ExpectedReportName','ProfileSha256','SourceSha256','ContractSha256')) {
      if([string]$manifestRow.$field -ne [string]$queued.$field) { throw "Queue/manifest $field mismatch at rank $($queued.QueueRank)." }
   }
}

$initialRuns = @(Import-RunGlob $InitialRunGlob)
$retryRuns = @(Import-RunGlob $RetryRunGlob)
$canonicalRuns = foreach($queued in ($queue | Sort-Object { [int]$_.QueueRank })) {
   $retry = @($retryRuns | Where-Object { $_.QueueRank -eq $queued.QueueRank -and $_.Status -eq "REPORT_FOUND" })
   $initial = @($initialRuns | Where-Object { $_.QueueRank -eq $queued.QueueRank -and $_.Status -eq "REPORT_FOUND" })
   $selected = if($retry.Count -gt 0) { $retry | Select-Object -Last 1 } elseif($initial.Count -gt 0) { $initial | Select-Object -Last 1 } else { $null }
   if($null -eq $selected) { throw "No identity-valid runner result for rank $($queued.QueueRank)." }
   if($selected.PackageSourceSha256 -ne $queued.SourceSha256) { throw "Runner source mismatch at rank $($queued.QueueRank)." }
   if($selected.Candidate -ne $queued.Candidate -or $selected.Window -ne $queued.Window) { throw "Runner row mismatch at rank $($queued.QueueRank)." }

   $reportPath = Resolve-RepoPath ([string]$selected.ReportPath)
   if(!(Test-Path -LiteralPath $reportPath -PathType Leaf)) { throw "Runner report is missing at rank $($queued.QueueRank)." }
   if(!$reportPath.StartsWith($reportRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Runner report is outside the frozen package at rank $($queued.QueueRank)." }
   if([IO.Path]::GetFileNameWithoutExtension($reportPath) -ne $queued.ExpectedReportName) { throw "Runner report name mismatch at rank $($queued.QueueRank)." }
   if((Get-Content -LiteralPath $reportPath -Raw).IndexOf($expectedSourceHash, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Report source identity missing at rank $($queued.QueueRank)." }

   [pscustomobject]@{
      Worker=$selected.Worker;QueueRank=$queued.QueueRank;Candidate=$queued.Candidate;Window=$queued.Window
      Status=$selected.Status;ReportPath=(Convert-ToRepoRelative $reportPath);Evidence=$selected.Evidence
      PackageSourceSha256=$selected.PackageSourceSha256;PortableBinarySha256=$selected.PortableBinarySha256
      PortableExpertRecompiled=$selected.PortableExpertRecompiled;Started=$selected.Started;Finished=$selected.Finished
   }
}
$canonicalRuns | Export-Csv -LiteralPath (Resolve-RepoPath $RunPath) -NoTypeInformation -Encoding ASCII

& (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir `
   -ReportNameTemplate "{ExpectedReportName}" -OutResults $RawResultsPath `
   -OutSummary $SummaryPath -OutMarkdown $MarkdownPath | Out-Null

$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $RawResultsPath))
if($raw.Count -ne 8) { throw "Expected eight parsed signal-range Model1 results." }
$results = foreach($queued in ($queue | Sort-Object { [int]$_.QueueRank })) {
   $matches = @($raw | Where-Object ExpectedReportName -eq $queued.ExpectedReportName)
   if($matches.Count -ne 1) { throw "Result missing or ambiguous at rank $($queued.QueueRank)." }
   $row = $matches[0]
   if($row.Status -ne "PARSED") { throw "Report did not parse at rank $($queued.QueueRank)." }
   $run = @($canonicalRuns | Where-Object QueueRank -eq $queued.QueueRank)
   if($run.Count -ne 1) { throw "Canonical run missing at rank $($queued.QueueRank)." }
   [pscustomobject]@{
      QueueRank=$queued.QueueRank;Candidate=$queued.Candidate;Role=$queued.Role;Window=$queued.Window
      From=$queued.From;To=$queued.To;Model=$queued.Model;Deposit=$queued.Deposit
      ExpectedReportName=$queued.ExpectedReportName;Status=$row.Status;RunnerStatus=$run[0].Status
      ReportPath=$run[0].ReportPath;ProfileSha256=$queued.ProfileSha256;SourceSha256=$queued.SourceSha256
      BaseProfileSha256=$queued.BaseProfileSha256;ContractSha256=$queued.ContractSha256
      SignalRangeGateEnabled=$queued.SignalRangeGateEnabled;MinimumSignalRangeATR=$queued.MinimumSignalRangeATR
      InitialDeposit=$row.InitialDeposit;NetProfit=$row.NetProfit;Balance=$row.Balance
      TotalReturnPercent=$row.TotalReturnPercent;AnnualizedReturnPercent=$row.AnnualizedReturnPercent;CagrPercent=$row.CagrPercent
      ProfitFactor=$row.ProfitFactor;ExpectedPayoff=$row.ExpectedPayoff;SharpeRatio=$row.SharpeRatio
      WinRatePercent=$row.WinRatePercent;TotalTrades=$row.TotalTrades;MaxConsecutiveLosses=$row.MaxConsecutiveLosses
      MaxDrawdownMoney=$row.MaxDrawdownMoney;MaxDrawdownPercent=$row.MaxDrawdownPercent
      BalanceDrawdownMaximal=$row.BalanceDrawdownMaximal;EquityDrawdownMaximal=$row.EquityDrawdownMaximal
      RecoveryFactor=$row.RecoveryFactor
   }
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{Status="PARSED";Reports=$results.Count;Profiles=@($results.Candidate | Sort-Object -Unique).Count;SourceSha256=$expectedSourceHash}
