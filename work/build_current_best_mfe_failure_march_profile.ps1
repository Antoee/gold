param(
   [string]$BaseProfilePath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE.set",
   [string]$OutProfilePath = "outputs\CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_PROFILE.set"
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
   InpUseMFEFailureExit = 'true||true||0||0||N'
   InpMFEFailureBars = '6||6||0||0||N'
   InpMFEFailureMinMFER = '0.30||0.30||0||0||N'
   InpMFEFailureMaxCurrentR = '0.05||0.05||0||0||N'
   InpUseMFEFailureMonthFilter = 'true||true||0||0||N'
   InpMFEFailureTradeJanuary = 'false||false||0||0||N'
   InpMFEFailureTradeFebruary = 'false||false||0||0||N'
   InpMFEFailureTradeMarch = 'true||true||0||0||N'
   InpMFEFailureTradeApril = 'false||false||0||0||N'
   InpMFEFailureTradeMay = 'false||false||0||0||N'
   InpMFEFailureTradeJune = 'false||false||0||0||N'
   InpMFEFailureTradeJuly = 'false||false||0||0||N'
   InpMFEFailureTradeAugust = 'false||false||0||0||N'
   InpMFEFailureTradeSeptember = 'false||false||0||0||N'
   InpMFEFailureTradeOctober = 'false||false||0||0||N'
   InpMFEFailureTradeNovember = 'false||false||0||0||N'
   InpMFEFailureTradeDecember = 'false||false||0||0||N'
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
