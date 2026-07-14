param(
   [string]$BaseSetPath = "outputs\CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set",
   [string]$OutSetPath = "outputs\CANDIDATE_LOWATR_LOCKED_RESEARCH_PROFILE.set",
   [string]$ProfileId = "lowatr_locked_research",
   [string]$RunLabel = "lowatr_locked_research_validation",
   [string]$RiskPercent = "",
   [string]$MaxEffectiveRiskPercent = "",
   [string]$MaxOpenRiskPercent = "",
   [string]$MaxPositionLots = "",
   [string]$MaxSimultaneousPositions = "",
   [string]$MaxEquityDrawdownPercent = "",
   [string]$MaxDailyLossPercent = "",
   [string]$MaxWeeklyLossPercent = "",
   [string]$MaxMonthlyLossPercent = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedBasePath = if([IO.Path]::IsPathRooted($BaseSetPath)) { $BaseSetPath } else { Join-Path $repo $BaseSetPath }
$resolvedOutPath = if([IO.Path]::IsPathRooted($OutSetPath)) { $OutSetPath } else { Join-Path $repo $OutSetPath }
$sourceHash = (Get-FileHash -LiteralPath (Join-Path $repo "Professional_XAUUSD_EA.mq5") -Algorithm SHA256).Hash

$inputs = Import-SetInputs $resolvedBasePath

$overrides = [ordered]@{
   InpEvidenceProfileId = $ProfileId
   InpEvidenceSourceHash = $sourceHash
   InpEvidenceRunLabel = $RunLabel

   InpAllowedSymbol = "XAUUSD"
   InpSignalTimeframe = "15"
   InpShowDashboard = "false"
   InpDashboardInTester = "false"
   InpLogLevel = "0"
   InpTesterFitnessMode = "1"

   InpUseSymbolSafetyLock = "true"
   InpUseRealAccountSafetyLock = "true"
   InpAllowRealAccountTrading = "false"
   InpRealAccountApprovalCode = "DISABLED"
   InpRealAccountApprovalProfileId = "DISABLED"
   InpRealAccountApprovalSourceHash = "DISABLED"
}

if($RiskPercent -ne "") { $overrides.InpRiskPercent = $RiskPercent }
if($MaxEffectiveRiskPercent -ne "") { $overrides.InpMaxEffectiveRiskPercent = $MaxEffectiveRiskPercent }
if($MaxOpenRiskPercent -ne "") { $overrides.InpMaxOpenRiskPercent = $MaxOpenRiskPercent }
if($MaxPositionLots -ne "") { $overrides.InpMaxPositionLots = $MaxPositionLots }
if($MaxSimultaneousPositions -ne "") { $overrides.InpMaxSimultaneousPositions = $MaxSimultaneousPositions }
if($MaxEquityDrawdownPercent -ne "") { $overrides.InpMaxEquityDrawdownPercent = $MaxEquityDrawdownPercent }
if($MaxDailyLossPercent -ne "") { $overrides.InpMaxDailyLossPercent = $MaxDailyLossPercent }
if($MaxWeeklyLossPercent -ne "") { $overrides.InpMaxWeeklyLossPercent = $MaxWeeklyLossPercent }
if($MaxMonthlyLossPercent -ne "") { $overrides.InpMaxMonthlyLossPercent = $MaxMonthlyLossPercent }
if($MaxEquityDrawdownPercent -ne "" -or $MaxDailyLossPercent -ne "" -or $MaxWeeklyLossPercent -ne "" -or $MaxMonthlyLossPercent -ne "") {
   $overrides.InpClosePositionsOnRiskLimit = "true"
}
if($RiskPercent -ne "" -or $MaxOpenRiskPercent -ne "" -or $MaxPositionLots -ne "") {
   $overrides.InpAllowMinLotRiskOverflow = "false"
   $overrides.InpBlockUnprotectedExposure = "true"
}

foreach($entry in $overrides.GetEnumerator()) {
   Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
}

$outDir = Split-Path -Parent $resolvedOutPath
if($outDir -and !(Test-Path -LiteralPath $outDir)) {
   New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] } | Set-Content -LiteralPath $resolvedOutPath -Encoding ASCII

[pscustomobject]@{
   Profile = $resolvedOutPath
   Sha256 = (Get-FileHash -LiteralPath $resolvedOutPath -Algorithm SHA256).Hash
   SourceHash = $sourceHash
}
