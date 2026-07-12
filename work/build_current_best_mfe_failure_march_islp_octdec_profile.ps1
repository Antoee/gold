param(
   [string]$BaseProfilePath = "outputs\CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_PROFILE.set",
   [string]$OutProfilePath = "outputs\CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_OCTDEC_PROFILE.set"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$basePath = Join-Path $repo $BaseProfilePath
$outPath = Join-Path $repo $OutProfilePath

if(!(Test-Path -LiteralPath $basePath)) {
   throw "Base profile missing: $basePath"
}

$settings = [ordered]@{}
Get-Content -LiteralPath $basePath | ForEach-Object {
   if($_ -match '^([^=]+)=(.*)$') {
      $settings[$matches[1]] = $matches[2]
   }
}

$overrides = [ordered]@{
   InpUseInSessionLiquidityPullbackLane = 'true||true||0||0||N'
   InpInSessionLiquidityPullbackMinScore = '6||6||0||0||N'
   InpInSessionLiquidityPullbackRiskMultiplier = '0.40||0.40||0||0||N'
   InpInSessionLiquidityPullbackMaxMonthlyEntries = '8||8||0||0||N'
   InpInSessionLiquidityPullbackSpacingMinutes = '120||120||0||0||N'
   InpInSessionLiquidityPullbackRequireLiquidSession = 'true||true||0||0||N'
   InpInSessionLiquidityPullbackRequireMTFAlignment = 'false||false||0||0||N'
   InpInSessionLiquidityPullbackRequireLiquidity = 'true||true||0||0||N'
   InpInSessionLiquidityPullbackRequireOrderFlow = 'false||false||0||0||N'
   InpInSessionLiquidityPullbackLookbackBars = '10||10||0||0||N'
   InpInSessionLiquidityPullbackMaxPullbackATR = '0.65||0.65||0||0||N'
   InpInSessionLiquidityPullbackMinBodyPercent = '28.0||28.0||0||0||N'
   InpInSessionLiquidityPullbackStopBufferATR = '0.12||0.12||0||0||N'
   InpInSessionLiquidityPullbackStopBufferPoints = '25.0||25.0||0||0||N'
   InpInSessionLiquidityPullbackTakeProfitATR = '1.35||1.35||0||0||N'
   InpInSessionLiquidityPullbackMinRR = '0.85||0.85||0||0||N'
   InpAllowInSessionLiquidityPullbackOutsideMonthFilter = 'true||true||0||0||N'
   InpUseInSessionLiquidityPullbackMonthFilter = 'true||true||0||0||N'
   InpISLPTradeJanuary = 'false||false||0||0||N'
   InpISLPTradeFebruary = 'false||false||0||0||N'
   InpISLPTradeMarch = 'false||false||0||0||N'
   InpISLPTradeApril = 'false||false||0||0||N'
   InpISLPTradeMay = 'false||false||0||0||N'
   InpISLPTradeJune = 'false||false||0||0||N'
   InpISLPTradeJuly = 'false||false||0||0||N'
   InpISLPTradeAugust = 'false||false||0||0||N'
   InpISLPTradeSeptember = 'false||false||0||0||N'
   InpISLPTradeOctober = 'true||true||0||0||N'
   InpISLPTradeNovember = 'true||true||0||0||N'
   InpISLPTradeDecember = 'true||true||0||0||N'
}

foreach($name in $overrides.Keys) {
   $settings[$name] = $overrides[$name]
}

$outDir = Split-Path -Parent $outPath
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$lines = foreach($name in ($settings.Keys | Sort-Object)) {
   "$name=$($settings[$name])"
}
Set-Content -LiteralPath $outPath -Value $lines -Encoding ASCII

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $outPath).Hash
[pscustomobject]@{
   BaseProfile = $BaseProfilePath
   OutProfile = $OutProfilePath
   Settings = $lines.Count
   Sha256 = $hash
}
