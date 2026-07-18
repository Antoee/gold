Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "7E8D680807B0565992ECC9B98E15C636A86AF34742194687DBB64D61CE2EFD7A"
$expectedContractHash = "875BFDDD2F2A3A3A91B9CEA2A621B7854DAFDD71385D209995AED0F13878270B"

$sourceHash = (Get-FileHash -LiteralPath (Join-Path $repo "work\Professional_XAUUSD_Reversion_Long_Distance_Guard_Portfolio.mq5") -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Interaction source identity changed." }
$contractHash = (Get-FileHash -LiteralPath (Join-Path $repo "outputs\REVERSION_DI_DISTANCE_INTERACTION_CONTRACT.md") -Algorithm SHA256).Hash
if($contractHash -ne $expectedContractHash) { throw "Interaction contract identity changed." }

$queue = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_DI_DISTANCE_INTERACTION_DISCOVERY_MODEL1_QUEUE.csv"))
$results = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_DI_DISTANCE_INTERACTION_DISCOVERY_MODEL1_RESULTS.csv"))
$runs = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_DI_DISTANCE_INTERACTION_DISCOVERY_MODEL1_RUN.csv"))
$decision = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_DI_DISTANCE_INTERACTION_DISCOVERY_DECISION.csv"))
if($queue.Count -ne 20 -or $results.Count -ne 20 -or $runs.Count -ne 20 -or $decision.Count -ne 5) {
   throw "Unexpected artifact row count."
}
if(@($queue | Where-Object To -gt "2020.12.31").Count -gt 0) { throw "Post-2020 data leaked into discovery." }
if(@($results | Where-Object Status -ne "PARSED").Count -gt 0) { throw "Unparsed result present." }
if(@($runs | Where-Object Status -ne "REPORT_FOUND").Count -gt 0) { throw "Identity-invalid runner evidence is canonical." }
$center = @($decision | Where-Object Candidate -eq "rddi_di10_m10_center")[0]
if([double]$center.NetProfit2019 -ge 0.0 -or $center.EraGatePass -ne "False") { throw "Losing 2019 gate was not enforced." }
if($center.Decision -ne "REJECT_BEFORE_HOLDOUT") { throw "Rejected center incorrectly opened holdout." }
if(@($decision | Where-Object Decision -eq "OPEN_HOLDOUT").Count -gt 0) { throw "A profile opened holdout after a losing broad year." }
if(!(Test-Path -LiteralPath (Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"))) { throw "MT5 hard lock is missing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock")) { throw "MT5 unlock leaked after testing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock")) { throw "Hidden-desktop acknowledgement leaked after testing." }

Write-Output "PASS: DI and distance interaction artifacts enforce rejection before post-2020 holdout."
