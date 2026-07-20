[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$PackageDir = 'outputs\three_lane_reversion_strong_signal_lot_cap_discovery_model1_package',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set'
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceHash='C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$profileHash='705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E'
$variants=[ordered]@{
   sslc_control=[ordered]@{Selective='false';BaseCap='0.10';StrongCap='0.15'}
   sslc_unconditional015=[ordered]@{Selective='false';BaseCap='0.15';StrongCap='0.15'}
   sslc_low012=[ordered]@{Selective='true';BaseCap='0.10';StrongCap='0.12'}
   sslc_center015=[ordered]@{Selective='true';BaseCap='0.10';StrongCap='0.15'}
   sslc_high018=[ordered]@{Selective='true';BaseCap='0.10';StrongCap='0.18'}
}
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Get-Inputs([string]$Path){$map=[ordered]@{};foreach($line in Get-Content -LiteralPath $Path){if($line -match '^(Inp[^=]+)=(.*)$'){$map[$Matches[1]]=$Matches[2]}};return $map}

& (Join-Path $PSScriptRoot 'test_three_lane_reversion_strong_signal_lot_cap_source.ps1')|Out-Null
$manifest=@(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
$package=(Resolve-Path -LiteralPath (Resolve-RepoPath $PackageDir)).Path
$source=Join-Path $package 'source\Professional_XAUUSD_EA.mq5'
$champion=(Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $sourceHash){throw 'Packaged source identity changed.'}
if((Get-FileHash -LiteralPath $champion -Algorithm SHA256).Hash.ToUpperInvariant() -ne $profileHash){throw 'Champion profile identity changed.'}
if($manifest.Count -ne 15 -or @($manifest.Candidate|Sort-Object -Unique).Count -ne 5 -or @($manifest.Window|Sort-Object -Unique).Count -ne 3){throw 'Manifest topology is not five candidates by three windows.'}
if(@($manifest|Where-Object{$_.SourceSha256 -ne $sourceHash -or [int]$_.Model -ne 1 -or [int]$_.Deposit -ne 10000 -or $_.ReversionRiskPercent -ne '0.45' -or $_.MaximumPortfolioOpenRiskPercent -ne '0.75' -or $_.StrongSignalRiskEnabled -ne 'false' -or $_.StrongSignalBodyRatio -ne '0.25'}).Count -ne 0){throw 'Manifest source/risk contract changed.'}

$championInputs=Get-Inputs $champion
foreach($candidate in $variants.Keys){
   $expected=$variants[$candidate];$profile=Join-Path $package "profiles\$candidate.set";$inputs=Get-Inputs $profile
   if($inputs.Count -ne 183){throw "$candidate profile input count changed."}
   $required=[ordered]@{
      InpRVUseStrongSignalRisk='false||false||0||0||N';InpRVStrongSignalMinimumBodyRatio='0.25||0.25||0||0||N';
      InpRVStrongSignalRiskPercent='0.60||0.60||0||0||N';InpRVUseStrongSignalLotCap="$($expected.Selective)||$($expected.Selective)||0||0||N";
      InpRVMaximumPositionLots="$($expected.BaseCap)||$($expected.BaseCap)||0||0||N";InpRVStrongSignalMaximumPositionLots="$($expected.StrongCap)||$($expected.StrongCap)||0||0||N";
      InpRVRiskPercent='0.45||0.45||0||0||N';InpMORiskPercent='0.15||0.15||0||0||N';InpATBRiskPercent='0.15||0.15||0||0||N';
      InpMaximumPortfolioOpenRiskPercent='0.75||0.75||0||0||N';InpExpectedInitialBalance='10000.0||10000.0||0||0||N';InpAllowRealAccountTrading='false||false||0||0||N'
   }
   foreach($item in $required.GetEnumerator()){if($inputs[$item.Key] -ne $item.Value){throw "$candidate safety value $($item.Key) changed."}}
   foreach($name in $championInputs.Keys){
      if($name -in @('InpRVMaximumPositionLots','InpEvidenceSourceHash','InpEvidenceRunLabel')){continue}
      if($inputs[$name] -ne $championInputs[$name]){throw "$candidate changed forbidden champion input $name."}
   }
}
foreach($row in $manifest){
   $config=Resolve-RepoPath ([string]$row.PackageConfig)
   if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $row.ConfigSha256){throw "Config hash changed at rank $($row.QueueRank)."}
   $expected=$variants[[string]$row.Candidate]
   if($row.SelectiveLotCapEnabled -ne $expected.Selective -or $row.BaseReversionMaximumPositionLots -ne $expected.BaseCap -or $row.StrongSignalMaximumPositionLots -ne $expected.StrongCap){throw "Variant contract changed at rank $($row.QueueRank)."}
}

[pscustomobject][ordered]@{Status='PASS';SourceSha256=$sourceHash;ChampionProfileSha256=$profileHash;Configurations=$manifest.Count;Candidates=$variants.Count;Windows=3;RequestedReversionRiskPercent='0.45';PortfolioOpenRiskCapPercent='0.75';StrongRiskEnabled=$false;RealAccountTradingAllowed=$false}
