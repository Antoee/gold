[CmdletBinding()]
param(
   [string]$BaseSourcePath = 'work\Professional_XAUUSD_Reversion_D1_Momentum_Cap_Portfolio.mq5',
   [string]$AdaptiveSourcePath = 'work\Professional_XAUUSD_Adaptive_Trend_Breakout_Portfolio.mq5',
   [string]$OutputPath = 'work\Professional_XAUUSD_Three_Lane_Adaptive_Trend_Portfolio.mq5'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Replace-Once([string]$Text,[string]$Old,[string]$New,[string]$Label) {
   $first = $Text.IndexOf($Old,[StringComparison]::Ordinal)
   if($first -lt 0 -or $Text.IndexOf($Old,$first + $Old.Length,[StringComparison]::Ordinal) -ge 0) {
      throw "Expected exactly one $Label marker."
   }
   return $Text.Substring(0,$first) + $New + $Text.Substring($first + $Old.Length)
}

$basePath = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseSourcePath)).Path
$adaptivePath = (Resolve-Path -LiteralPath (Resolve-RepoPath $AdaptiveSourcePath)).Path
$output = Resolve-RepoPath $OutputPath
$expectedBaseHash = '8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B'
$expectedAdaptiveHash = '06CC53B1C22CEC849D5DC02447F1838E2B2C05D62ADE778CBFB4C0C6E36A5D25'
if((Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedBaseHash) {
   throw 'Three-lane base source identity changed.'
}
if((Get-FileHash -LiteralPath $adaptivePath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedAdaptiveHash) {
   throw 'Adaptive trend source identity changed.'
}

$base = Get-Content -LiteralPath $basePath -Raw
$adaptive = Get-Content -LiteralPath $adaptivePath -Raw
$nl = if($base.Contains("`r`n")) { "`r`n" } else { "`n" }
$inputStartMarker = 'input group "Adaptive H4/D1 Trend Breakout Lane"'
$inputEndMarker = 'input group "Evidence and Dashboard"'
$inputStart = $adaptive.IndexOf($inputStartMarker,[StringComparison]::Ordinal)
$inputEnd = $adaptive.IndexOf($inputEndMarker,$inputStart,[StringComparison]::Ordinal)
if($inputStart -lt 0 -or $inputEnd -le $inputStart) { throw 'Adaptive input block markers changed.' }
$adaptiveInputs = $adaptive.Substring($inputStart,$inputEnd - $inputStart)
$adaptiveInputs = $adaptiveInputs.Replace('InpMO','InpATB')
$adaptiveInputs = $adaptiveInputs.Replace('Adaptive H4/D1 Trend Breakout Lane','Independent Adaptive H4/D1 Trend Breakout Lane')
$adaptiveInputs = $adaptiveInputs.Replace('26071761','26071971')
$adaptiveInputs += 'input string InpATBLogFileName = "THREE_LANE_ATB_EVENTS.csv";' + "`r`n`r`n"

$classStartMarker = 'class CMomentumLane'
$classEndMarker = 'CReversionLane g_reversion;'
$classStart = $adaptive.IndexOf($classStartMarker,[StringComparison]::Ordinal)
$classEnd = $adaptive.IndexOf($classEndMarker,$classStart,[StringComparison]::Ordinal)
if($classStart -lt 0 -or $classEnd -le $classStart) { throw 'Adaptive class block markers changed.' }
$adaptiveClass = $adaptive.Substring($classStart,$classEnd - $classStart)
$adaptiveClass = $adaptiveClass.Replace('class CMomentumLane','class CAdaptiveTrendBreakoutLane')
$adaptiveClass = $adaptiveClass.Replace('CMomentumLane()','CAdaptiveTrendBreakoutLane()')
$adaptiveClass = $adaptiveClass.Replace('InpMO','InpATB')
$adaptiveClass = $adaptiveClass.Replace('TLP_MO_RISK_','TLP_ATB_RISK_')

$base = Replace-Once $base $inputEndMarker ($adaptiveInputs + $inputEndMarker) 'evidence-input insertion'
$base = Replace-Once $base $classEndMarker ($adaptiveClass + $classEndMarker) 'adaptive-class insertion'
$base = Replace-Once $base '#property version   "1.21"' '#property version   "1.40"' 'version'
$base = Replace-Once $base '#property description "RC2 portfolio research fork with optional completed-D1 momentum cap"' `
   '#property description "Risk-first three-lane XAUUSD portfolio with capped reversion, original momentum and adaptive H4 trend"' 'description'
$base = Replace-Once $base `
   'return magic == InpPortfolioMagic || magic == InpRVMagicNumber || magic == InpMOMagicNumber;' `
   'return magic == InpPortfolioMagic || magic == InpRVMagicNumber || magic == InpMOMagicNumber || magic == InpATBMagicNumber;' `
   'portfolio magic contract'
$base = Replace-Once $base `
   ('CReversionLane g_reversion;' + $nl + 'CMomentumLane g_momentum;') `
   ('CReversionLane g_reversion;' + $nl + 'CMomentumLane g_momentum;' + $nl + 'CAdaptiveTrendBreakoutLane g_adaptiveTrend;') `
   'global lane declarations'
$base = Replace-Once $base `
   ('InpRVMagicNumber == InpMOMagicNumber ||' + $nl + '      InpPortfolioMagic == InpRVMagicNumber ||' + $nl + '      InpPortfolioMagic == InpMOMagicNumber ||') `
   ('InpRVMagicNumber == InpMOMagicNumber ||' + $nl + '      InpRVMagicNumber == InpATBMagicNumber ||' + $nl + '      InpMOMagicNumber == InpATBMagicNumber ||' + $nl + '      InpPortfolioMagic == InpRVMagicNumber ||' + $nl + '      InpPortfolioMagic == InpMOMagicNumber ||' + $nl + '      InpPortfolioMagic == InpATBMagicNumber ||') `
   'magic uniqueness validation'
$base = Replace-Once $base `
   ('InpRVRiskPercent <= 0.0 || InpRVRiskPercent > 2.0 ||' + $nl + '      InpMORiskPercent <= 0.0 || InpMORiskPercent > 2.0 ||' + $nl + '      InpRVRiskPercent + InpMORiskPercent > InpMaximumPortfolioOpenRiskPercent + 1e-9)') `
   ('InpRVRiskPercent <= 0.0 || InpRVRiskPercent > 2.0 ||' + $nl + '      InpMORiskPercent <= 0.0 || InpMORiskPercent > 2.0 ||' + $nl + '      InpATBRiskPercent <= 0.0 || InpATBRiskPercent > 2.0 ||' + $nl + '      InpRVRiskPercent + InpMORiskPercent + InpATBRiskPercent > InpMaximumPortfolioOpenRiskPercent + 1e-9)') `
   'aggregate requested-risk validation'

$adaptiveValidationStart = $adaptive.IndexOf('   if(InpMOMomentumLookbackBars < 20 ||',[StringComparison]::Ordinal)
$adaptiveValidationEnd = $adaptive.IndexOf('   return true;',$adaptiveValidationStart,[StringComparison]::Ordinal)
if($adaptiveValidationStart -lt 0 -or $adaptiveValidationEnd -le $adaptiveValidationStart) {
   throw 'Adaptive validation block markers changed.'
}
$adaptiveValidation = $adaptive.Substring($adaptiveValidationStart,$adaptiveValidationEnd - $adaptiveValidationStart).Replace('InpMO','InpATB')
$base = Replace-Once $base ('   return true;' + $nl + '}' + $nl + $nl + 'void UpdateDashboard()') `
   ($adaptiveValidation + '   return true;' + $nl + '}' + $nl + $nl + 'void UpdateDashboard()') 'adaptive validation insertion'

$base = Replace-Once $base `
   ('if(!g_momentum.Init())' + $nl + '   {' + $nl + '      g_reversion.Deinit();' + $nl + '      return INIT_FAILED;' + $nl + '   }') `
   ('if(!g_momentum.Init())' + $nl + '   {' + $nl + '      g_reversion.Deinit();' + $nl + '      return INIT_FAILED;' + $nl + '   }' + $nl + '   if(!g_adaptiveTrend.Init())' + $nl + '   {' + $nl + '      g_momentum.Deinit();' + $nl + '      g_reversion.Deinit();' + $nl + '      return INIT_FAILED;' + $nl + '   }') `
   'adaptive initialization'
$base = Replace-Once $base `
   ('g_reversion.Deinit();' + $nl + '   g_momentum.Deinit();') `
   ('g_reversion.Deinit();' + $nl + '   g_momentum.Deinit();' + $nl + '   g_adaptiveTrend.Deinit();') 'adaptive deinitialization'
$base = Replace-Once $base `
   ('g_reversion.OnTick();' + $nl + '   g_momentum.OnTick();') `
   ('g_reversion.OnTick();' + $nl + '   g_momentum.OnTick();' + $nl + '   g_adaptiveTrend.OnTick();') 'adaptive tick dispatch'
$base = Replace-Once $base `
   ('g_reversion.OnTradeTransaction(transaction);' + $nl + '   g_momentum.OnTradeTransaction(transaction);') `
   ('g_reversion.OnTradeTransaction(transaction);' + $nl + '   g_momentum.OnTradeTransaction(transaction);' + $nl + '   g_adaptiveTrend.OnTradeTransaction(transaction);') 'adaptive transaction dispatch'
$base = Replace-Once $base `
   '"% + MOM ", DoubleToString(InpMORiskPercent, 2), "%");' `
   ('"% + MOM ", DoubleToString(InpMORiskPercent, 2),' + $nl + '           "% + ATB ", DoubleToString(InpATBRiskPercent, 2), "%");') 'dashboard lane risk'

$parent = Split-Path -Parent $output
if($parent -and !(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
[IO.File]::WriteAllText($output,$base,[Text.UTF8Encoding]::new($false))
$outputHash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToUpperInvariant()
[pscustomobject]@{
   Status='GENERATED'
   BaseSourceSha256=$expectedBaseHash
   AdaptiveSourceSha256=$expectedAdaptiveHash
   OutputSourceSha256=$outputHash
   OutputPath=$OutputPath
}
