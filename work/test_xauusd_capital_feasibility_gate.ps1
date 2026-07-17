param(
   [string]$GateCsv = "outputs\XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_GATE.csv",
   [string]$GateMarkdown = "outputs\XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_GATE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$csvFull = Resolve-RepoPath $GateCsv
$mdFull = Resolve-RepoPath $GateMarkdown
if(!(Test-Path -LiteralPath $csvFull) -or !(Test-Path -LiteralPath $mdFull)) { throw "Capital-feasibility gate outputs are missing." }
$rows = @(Import-Csv -LiteralPath $csvFull)
if($rows.Count -ne 3) { throw "Expected three gate rows, found $($rows.Count)." }
if(@($rows | Where-Object { $_.GateStatus -ne 'FAIL_MINIMUM_LOT_FEASIBILITY' }).Count -ne 0) { throw "Expected every H4 probe to fail minimum-lot feasibility." }
if(@($rows | Where-Object { [int]$_.RecentSignals -lt 30 -or [double]$_.RecentFeasiblePercent -ge 80.0 }).Count -ne 0) { throw "Gate thresholds are not supported by the diagnostic rows." }
$text = Get-Content -LiteralPath $mdFull -Raw
foreach($token in @('Verdict: `FAIL`','Forcing the minimum lot','OrderCalcProfit')) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Gate markdown token missing: $token" }
}
[pscustomobject]@{ Status = "PASS"; Rows = $rows.Count; Failed = 3; RiskOverflowAllowed = $false }
