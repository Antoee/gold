param(
   [string]$ManifestPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string[]]$PortableRoots = @(
      "work\mt5_portable_research",
      "work\mt5_portable_research_w2",
      "work\mt5_portable_research_w3",
      "work\mt5_portable_research_w4"
   ),
   [Parameter(Mandatory=$true)][switch]$UserAuthorizedFocusRisk,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [int]$TimeoutMinutesPerConfig = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$genericRunner = Join-Path $PSScriptRoot "run_mt5_portable_parallel_manifest.ps1"
& $genericRunner -ManifestPath $ManifestPath -PortableRoots $PortableRoots `
   -UserAuthorizedFocusRisk -OutputPrefix "M15_TREND_PULLBACK_PORTABLE_WORKER" `
   -MaxCpuPercent $MaxCpuPercent -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig
