param(
   [string]$BaseProfilePath = "outputs\CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_PROFILE.set",
   [string]$OutProfilePath = "outputs\CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_PROFILE.set"
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
   InpUseSpreadRegimeGuard      = 'true||true||0||0||N'
   InpSpreadRegimeLookbackBars  = '24||24||0||0||N'
   InpMaxSpreadRegimeRatio      = '1.35||1.35||0||0||N'
   InpMinSpreadRegimePoints     = '30.0||30.0||0||0||N'
   InpUseM1SpreadShockGuard     = 'true||true||0||0||N'
   InpM1SpreadShockLookbackBars = '30||30||0||0||N'
   InpM1SpreadShockMaxRatio     = '1.60||1.60||0||0||N'
   InpM1SpreadShockMinPoints    = '35.0||35.0||0||0||N'
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
