Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "test_independent_m15_volume_climax_reversal_discovery_package.ps1") `
   -QueueManifestPath "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_MODEL1_QUEUE.csv" `
   -PackageDir "outputs\independent_m15_volume_climax_reversal_activity_discovery_model1_package"
