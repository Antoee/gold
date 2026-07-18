param(
   [string]$SourcePath = "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5",
   [string]$BaseProfilePath = "outputs\operational_hardening_rc2_model4_package\profiles\operational_hardening_rc2_rv045_mo015_model4.set",
   [string]$ForwardProfilePath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_DEMO_PROFILE.set"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source = (Resolve-Path -LiteralPath (Join-Path $repo $SourcePath)).Path
$base = (Resolve-Path -LiteralPath (Join-Path $repo $BaseProfilePath)).Path
$forward = Join-Path $repo $ForwardProfilePath
$expectedSourceHash = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"
$expectedBaseHash = "5C45D578B42609D3792EA692D5A13A9E0D90C8C14D0376F807E6F6079EC6B827"

$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$baseHash = (Get-FileHash -LiteralPath $base -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "RC2 source identity changed: $sourceHash" }
if($baseHash -ne $expectedBaseHash) { throw "RC2 Model4 profile identity changed: $baseHash" }

$inputs = Import-SetInputs -Path $base
if($inputs.Keys.Count -ne 105) { throw "Expected 105 rc2 inputs, found $($inputs.Keys.Count)." }
$inputs["InpRVLogFileName"] = "InpRVLogFileName=OPERATIONAL_HARDENING_RC2_FORWARD_RV_EVENTS.csv"
$inputs["InpMOLogFileName"] = "InpMOLogFileName=OPERATIONAL_HARDENING_RC2_FORWARD_MO_EVENTS.csv"
$inputs["InpEvidenceRunLabel"] = "InpEvidenceRunLabel=operational_hardening_rc2_forward_frozen"
$inputs["InpShowDashboard"] = "InpShowDashboard=true||true||0||0||N"
@($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
   Set-Content -LiteralPath $forward -Encoding ASCII

$changed = @($inputs.Keys | Where-Object {
   (Import-SetInputs -Path $base)[$_] -ne $inputs[$_]
})
$expectedChanges = @("InpEvidenceRunLabel", "InpMOLogFileName", "InpRVLogFileName", "InpShowDashboard")
if(Compare-Object -ReferenceObject $expectedChanges -DifferenceObject @($changed | Sort-Object)) {
   throw "Forward profile changed fields outside the evidence/dashboard contract: $($changed -join ', ')"
}

[pscustomobject]@{
   Status="READY"; Inputs=$inputs.Keys.Count; ChangedFields=($changed -join ";")
   SourceSha256=$sourceHash; BaseProfileSha256=$baseHash
   ForwardProfileSha256=(Get-FileHash -LiteralPath $forward -Algorithm SHA256).Hash
}
