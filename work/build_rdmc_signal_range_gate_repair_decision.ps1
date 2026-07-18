param(
   [string]$ResultsPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_RESULTS.csv",
   [string]$DecisionCsvPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "32DE39C13DBE06A6AE2BD733ED2183D7103C003884F08DD13024FDEE18BAD241"
$expectedBaseProfileHash = "BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC"
$expectedContractHash = "F8864C26088E63494D16E0606DE04C66BB46E99FFC798FE0D40C83AA20AA643C"
$expectedProfiles = [ordered]@{
   srg_control = @{Role='control';Range='1.25';Hash='A3A44284F53A16466CB046E0DAD284129B95E51A5F23062EC087196CC38D6CBF'}
   srg_min100 = @{Role='loose_neighbor';Range='1.00';Hash='2EBC9550A2D80286E168EC432DBF8A300188323A8AE25AC1ED5ABCBE6E106948'}
   srg_min125_center = @{Role='center';Range='1.25';Hash='1074719B19AE512A72AC4320F656226A791A346FB6ADD910439BA654B3CF8F80'}
   srg_min150 = @{Role='strict_neighbor';Range='1.50';Hash='2C05FA664997A34685EB747C4BDB9A241FD7EB36EDDC664CF51D1606E36BD75C'}
}

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
   return [IO.Path]::GetFullPath((Join-Path $repo $Path))
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
if($results.Count -ne 8) { throw "Expected eight signal-range Model1 results." }
if(@($results | Where-Object { $_.Status -ne 'PARSED' -or $_.RunnerStatus -ne 'REPORT_FOUND' }).Count -gt 0) { throw "Evidence is incomplete or runner-invalid." }
if(@($results | Where-Object SourceSha256 -ne $expectedSourceHash).Count -gt 0) { throw "Source identity mismatch." }
if(@($results | Where-Object BaseProfileSha256 -ne $expectedBaseProfileHash).Count -gt 0) { throw "Base-profile identity mismatch." }
if(@($results | Where-Object ContractSha256 -ne $expectedContractHash).Count -gt 0) { throw "Contract identity mismatch." }
if(@($results | Where-Object { $_.Model -ne '1' -or $_.Deposit -ne '10000' }).Count -gt 0) { throw "Unexpected model or deposit." }
if((@($results.Window | Sort-Object -Unique) -join ',') -ne 'year_2019,year_2022') { throw "Unexpected repair windows." }

foreach($candidate in $expectedProfiles.Keys) {
   $profile = $expectedProfiles[$candidate]
   $candidateRows = @($results | Where-Object Candidate -eq $candidate)
   if($candidateRows.Count -ne 2 -or (@($candidateRows.Window | Sort-Object -Unique) -join ',') -ne 'year_2019,year_2022') {
      throw "Candidate $candidate does not have one result per frozen year."
   }
   if(@($candidateRows | Where-Object { $_.Role -ne $profile.Role -or $_.MinimumSignalRangeATR -ne $profile.Range -or $_.ProfileSha256 -ne $profile.Hash }).Count -gt 0) {
      throw "Candidate identity mismatch for $candidate."
   }
}

$controlCombined = [math]::Round([double](($results | Where-Object Candidate -eq 'srg_control' | Measure-Object NetProfit -Sum).Sum), 2)
$decisionRows = foreach($candidate in $expectedProfiles.Keys) {
   $profile = $expectedProfiles[$candidate]
   $year2019 = $results | Where-Object { $_.Candidate -eq $candidate -and $_.Window -eq 'year_2019' } | Select-Object -First 1
   $year2022 = $results | Where-Object { $_.Candidate -eq $candidate -and $_.Window -eq 'year_2022' } | Select-Object -First 1
   $net2019 = [math]::Round([double]$year2019.NetProfit, 2)
   $net2022 = [math]::Round([double]$year2022.NetProfit, 2)
   $trades2019 = [int]$year2019.TotalTrades
   $trades2022 = [int]$year2022.TotalTrades
   $profitBoth = $net2019 -gt 0.0 -and $net2022 -gt 0.0
   $activityBoth = $trades2019 -ge 18 -and $trades2022 -ge 18
   $combined = [math]::Round($net2019 + $net2022, 2)
   $beatsControl = $candidate -ne 'srg_control' -and $combined -gt $controlCombined
   [pscustomobject]@{
      Candidate=$candidate;Role=$profile.Role;MinimumSignalRangeATR=$profile.Range
      Net2019=$net2019;Trades2019=$trades2019;Profit2019Pass=($net2019 -gt 0.0);Activity2019Pass=($trades2019 -ge 18)
      Net2022=$net2022;Trades2022=$trades2022;Profit2022Pass=($net2022 -gt 0.0);Activity2022Pass=($trades2022 -ge 18)
      CombinedNet=$combined;ProfitBothYears=$profitBoth;ActivityBothYears=$activityBoth
      BeatsControlCombined=$beatsControl;CandidateGatePass=($profitBoth -and $activityBoth -and $beatsControl)
      ProfileSha256=$profile.Hash;SourceSha256=$expectedSourceHash;ContractSha256=$expectedContractHash
   }
}

$center = $decisionRows | Where-Object Candidate -eq 'srg_min125_center' | Select-Object -First 1
$adjacent = @($decisionRows | Where-Object { $_.Candidate -in @('srg_min100','srg_min150') -and $_.CandidateGatePass -eq $true })
$overallPass = $center.CandidateGatePass -eq $true -and $adjacent.Count -ge 1
$decision = if($overallPass) { 'OPEN_MODEL4' } else { 'REJECT_BEFORE_MODEL4' }
$decisionRows | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$headline = if($overallPass) {
   '**Decision: MODEL4 MAY OPEN. This is only an early-gate pass; no candidate is promoted or approved for live money.**'
} else {
   '**Decision: REJECT BEFORE MODEL4. The signal-range repair does not satisfy its preregistered early gate.**'
}
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# RDMC Signal-Range Repair Model1 Decision')
$lines.Add('')
$lines.Add($headline)
$lines.Add('')
$lines.Add("- Exact source: ``$expectedSourceHash``")
$lines.Add("- Exact parent profile: ``$expectedBaseProfileHash``")
$lines.Add("- Exact contract: ``$expectedContractHash``")
$lines.Add("- Control combined net: ``$controlCombined USD``")
$lines.Add("- Center pass: ``$($center.CandidateGatePass)``")
$lines.Add("- Adjacent profiles passing: ``$($adjacent.Count)``")
$lines.Add('')
$lines.Add('| Profile | Role | Min range | 2019 net | 2019 trades | 2022 net | 2022 trades | Combined | Profitable both | Active both | Beats control | Gate |')
$lines.Add('|---|---|---:|---:|---:|---:|---:|---:|---|---|---|---|')
foreach($row in $decisionRows) {
   $lines.Add("| ``$($row.Candidate)`` | $($row.Role) | $($row.MinimumSignalRangeATR) ATR | `$$('{0:+0.00;-0.00;0.00}' -f $row.Net2019) | $($row.Trades2019) | `$$('{0:+0.00;-0.00;0.00}' -f $row.Net2022) | $($row.Trades2022) | `$$('{0:+0.00;-0.00;0.00}' -f $row.CombinedNet) | $($row.ProfitBothYears) | $($row.ActivityBothYears) | $($row.BeatsControlCombined) | $($row.CandidateGatePass) |")
}
$lines.Add('')
$lines.Add('## Frozen Stop Rule')
$lines.Add('')
$lines.Add('- The 1.25 ATR center must be profitable with at least 18 trades in both 2019 and 2022.')
$lines.Add('- At least one adjacent threshold, 1.00 or 1.50 ATR, must satisfy the same test.')
$lines.Add('- Every passing repair profile must beat the unchanged control on combined 2019 plus 2022 net profit.')
$lines.Add('- A pass opens exact Model4 transfer only. It does not open stress testing, forward substitution, or live trading.')
$lines.Add('')
$lines.Add('The registered forward candidate remains unchanged. Real-money trading remains locked. The invalid $100,000 demo attachment is not evidence for this decision.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{Decision=$decision;CenterPass=[bool]$center.CandidateGatePass;AdjacentPassCount=$adjacent.Count;ControlCombinedNet=$controlCombined;RegisteredForwardCandidateChanged=$false;RealMoneyLocked=$true}
