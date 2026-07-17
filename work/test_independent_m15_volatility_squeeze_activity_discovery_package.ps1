Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "test_independent_m15_volatility_squeeze_discovery_package.ps1") `
   -QueueManifestPath "outputs\INDEPENDENT_M15_VOLATILITY_SQUEEZE_ACTIVITY_DISCOVERY_MODEL1_QUEUE.csv" `
   -PackageDir "outputs\independent_m15_volatility_squeeze_activity_discovery_model1_package"
