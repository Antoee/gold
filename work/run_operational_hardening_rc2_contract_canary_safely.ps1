param(
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [int]$TimeoutMinutes = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$testerLog = Join-Path $env:APPDATA ("MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\logs\{0}.log" -f (Get-Date -Format "yyyyMMdd"))

& (Join-Path $PSScriptRoot "run_single_profile_package_hidden_safely.ps1") `
   -ManifestPath "outputs\OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY_MANIFEST.csv" `
   -QueueManifestPath "outputs\OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY_QUEUE.csv" `
   -OutStem "OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY" `
   -InitialDeposit 100000 `
   -TimeoutMinutesPerConfig $TimeoutMinutes `
   -MaxCpuPercent $MaxCpuPercent `
   -SourcePath "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5" `
   -CompileLogPath "outputs\OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY_COMPILE.log" | Out-Null

if(!(Test-Path -LiteralPath $testerLog -PathType Leaf)) { throw "Tester log missing: $testerLog" }
$tail = @(Get-Content -LiteralPath $testerLog -Tail 240)
$markers = [ordered]@{
   WrongDeposit = "initial deposit 100000.00 USD"
   RunIdentity = "InpEvidenceRunLabel=operational_hardening_rc2_wrong_capital_canary"
   CapitalLock = "SAFETY: initialization blocked by starting-capital contract"
   InitFailure = "tester stopped because OnInit returns non-zero code 1"
}
$evidence = @()
foreach($item in $markers.GetEnumerator()) {
   $match = $tail | Where-Object { $_ -like "*$($item.Value)*" } | Select-Object -Last 1
   if(!$match) { throw "Tester canary marker missing: $($item.Key)" }
   $evidence += [pscustomobject]@{Marker=$item.Key;Expected=$item.Value;Pass=$true}
}
$result = Import-Csv -LiteralPath (Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY_RESULTS.csv")
if([int]$result.TotalTrades -ne 0 -or [double]$result.NetProfit -ne 0.0 -or [double]$result.Balance -ne 100000.0) {
   throw "Wrong-capital report did not remain flat."
}
$evidence += [pscustomobject]@{Marker="FlatReport";Expected="0 trades, 0 net, 100000 balance";Pass=$true}
$evidencePath = Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY_EVIDENCE.csv"
$evidence | Export-Csv -LiteralPath $evidencePath -NoTypeInformation -Encoding ASCII

@(
   "# Operational-Hardening rc2 Account-Contract Canary",
   "",
   "**PASS.** The exact rc2 source rejected a deliberately wrong 100,000 USD tester balance against its frozen 10,000 USD contract.",
   "",
   "- MT5 logged the 100,000 USD initial deposit.",
   "- The embedded run label matched the canary identity.",
   "- The EA logged the starting-capital initialization block.",
   "- MT5 stopped because OnInit returned nonzero.",
   "- The generated report remained flat with zero trades and zero net profit.",
   "",
   "This proves the first-attachment capital lock dynamically. Dedicated-account and post-registration funding-drift paths are additionally compile-checked and source-audited; they still require forward operational observation on a correctly registered demo."
) | Set-Content -LiteralPath (Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY.md") -Encoding ASCII

[pscustomobject]@{
   Status="PASS"; Markers=$evidence.Count; Trades=0; NetProfit=0.0; Balance=100000.0
   EvidenceSha256=(Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256).Hash
}
