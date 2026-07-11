param(
   [string]$BaseSetPath = "outputs\CANDIDATE_MARCH110_MAY325_MAYCAP17_LOT040_PROFILE.set",
   [string]$OutSetPath = "outputs\CANDIDATE_MARCH110_MAY325_MAYCAP17_LOT040_QTPMARCH_PROFILE.set",
   [string]$OutOverridesPath = "outputs\CANDIDATE_MARCH110_MAY325_MAYCAP17_LOT040_QTPMARCH_PROFILE_OVERRIDES.set",
   [string]$OutStatePath = "outputs\EA_CANDIDATE_STATE_2026-07-11_MARCH110_MAY325_MAYCAP17_LOT040_QTPMARCH.txt"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$inputs = Import-SetInputs $BaseSetPath

Set-InputLine -Inputs $inputs -Name "InpUseQualityTakeProfitScaling" -Value "true"
Set-InputLine -Inputs $inputs -Name "InpQualityTPMinScore" -Value "8"
Set-InputLine -Inputs $inputs -Name "InpQualityTPFullScore" -Value "13"
Set-InputLine -Inputs $inputs -Name "InpMinQualityTPMultiplier" -Value "0.95"
Set-InputLine -Inputs $inputs -Name "InpMaxQualityTPMultiplier" -Value "1.30"
Set-InputLine -Inputs $inputs -Name "InpUseQualityTPMonthFilter" -Value "true"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeJanuary" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeFebruary" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeMarch" -Value "true"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeApril" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeMay" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeJune" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeJuly" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeAugust" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeSeptember" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeOctober" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeNovember" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpQualityTPTradeDecember" -Value "false"

Set-Content -LiteralPath $OutSetPath -Value ($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) -Encoding ASCII

$overrideNames = @(
   "InpUseMonthRiskMultipliers",
   "InpMarchRiskMultiplier",
   "InpMayRiskMultiplier",
   "InpUseMonthSpreadCaps",
   "InpMayMaxSpreadPoints",
   "InpMaxPositionLots",
   "InpUseQualityTakeProfitScaling",
   "InpQualityTPMinScore",
   "InpQualityTPFullScore",
   "InpMinQualityTPMultiplier",
   "InpMaxQualityTPMultiplier",
   "InpUseQualityTPMonthFilter",
   "InpQualityTPTradeJanuary",
   "InpQualityTPTradeFebruary",
   "InpQualityTPTradeMarch",
   "InpQualityTPTradeApril",
   "InpQualityTPTradeMay",
   "InpQualityTPTradeJune",
   "InpQualityTPTradeJuly",
   "InpQualityTPTradeAugust",
   "InpQualityTPTradeSeptember",
   "InpQualityTPTradeOctober",
   "InpQualityTPTradeNovember",
   "InpQualityTPTradeDecember"
)
$overrideNames | ForEach-Object { $inputs[$_] } | Set-Content -LiteralPath $OutOverridesPath -Encoding ASCII

$hash = (Get-FileHash -LiteralPath $OutSetPath -Algorithm SHA256).Hash
$sourceHash = (Get-FileHash -LiteralPath "outputs\Professional_XAUUSD_EA.mq5" -Algorithm SHA256).Hash

$state = @(
   "Candidate: CANDIDATE_MARCH110_MAY325_MAYCAP17_LOT040_QTPMARCH_PROFILE",
   "Created: 2026-07-11",
   "SourceHash: $sourceHash",
   "ProfileHash: $hash",
   "Base: CANDIDATE_MARCH110_MAY325_MAYCAP17_LOT040_PROFILE",
   "Key changes:",
   "- Enables quality-based take-profit scaling only in March",
   "- InpQualityTPMinScore=8",
   "- InpQualityTPFullScore=13",
   "- InpMinQualityTPMultiplier=0.95",
   "- InpMaxQualityTPMultiplier=1.30",
   "- Non-March months retain baseline take-profit behavior",
   "Validation:",
   "- Broad: TotalNet 7331.11, Continuous 793.69, YTD 1560.04, Full2025 219.66, Full2024 793.69, WorstWindow 0, LosingWindows 0",
   "- Monthly: TotalNet 7571.04, Parsed 30/30, WorstWindow 0, LosingWindows 0",
   "- Current base comparison: Broad TotalNet 6346.38, Monthly TotalNet 7083.94",
   "Risk note:",
   "- This improves total net by exploiting a March-specific TP response. It passes the current gates, but it is more curve-fit-prone than broad structural improvements and should get additional walk-forward/OOS scrutiny before live use.",
   "Decision: Promoted as a higher-profit research candidate, not a final live recommendation."
)
$state | Set-Content -LiteralPath $OutStatePath -Encoding ASCII

[pscustomobject]@{
   SetPath = $OutSetPath
   OverridesPath = $OutOverridesPath
   StatePath = $OutStatePath
   ProfileHash = $hash
   SourceHash = $sourceHash
}
