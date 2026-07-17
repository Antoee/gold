param(
   [string]$QueuePath = "outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\low_activity_diversifier_holdout_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Assert-True([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$queue=@(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$package=Resolve-RepoPath $PackageDir
Assert-True ($queue.Count -eq 9) 'Expected nine holdout rows.'
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 3) 'Expected three profiles.'
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 3) 'Expected three windows.'
Assert-True (@($queue.Model | Where-Object {[int]$_ -ne 1}).Count -eq 0) 'Non-Model1 row found.'
$expected=@{
   fbt_b16_fixed_r200='EFB39ED06E5C7CA3D75C971F24ADB3073E597CC9CB2373257521EC41BDC57990'
   m15sq_break8='A47F7A8ED05916A07A7CCF713340C64B1DFF950504E28744212EA8FD5CA94F29'
   m15vcr_vol130='914C5F3832D61DFD3AD2E4F885C70EFBF35E35B6CFFFFE1B8387EDA96AC56A36'
}
foreach($group in ($queue | Group-Object Candidate)){
   Assert-True ($group.Count -eq 3) "Incomplete windows: $($group.Name)"
   $row=$group.Group[0]
   $source=Join-Path $package "$($group.Name)\source\Professional_XAUUSD_EA.mq5"
   $profile=Join-Path $package $row.ProfileSnapshot
   Assert-True ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -eq $expected[$group.Name]) "Source hash mismatch: $($group.Name)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $row.ProfileSha256) "Profile hash mismatch: $($group.Name)"
   $text=Get-Content -LiteralPath $profile -Raw
   foreach($required in @('InpRiskPercent=0.10','InpAllowRealAccountTrading=false','InpUseRealAccountSafetyLock=true','InpLogTrades=false','InpEvidenceRunLabel=low_activity_diversifier_holdout_model1')){
      Assert-True ($text.Contains($required)) "Profile safety/evidence contract missing: $required"
   }
}
[pscustomobject]@{Status='PASS';Rows=$queue.Count;Profiles=3;Windows=3;HoldoutStart='2021-01-01';RealTradingDefault=$false}
