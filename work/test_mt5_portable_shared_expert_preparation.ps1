Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sharedWork = Split-Path -Parent $repo
$preparer = Join-Path $PSScriptRoot "prepare_mt5_portable_shared_expert.ps1"
$source = Join-Path $repo "outputs\rdmc_diversified_repair_executable_gate_package\source\Professional_XAUUSD_EA.mq5"
$sourceHash = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
$roots = @(
   (Join-Path $sharedWork "mt5_portable_research"),
   (Join-Path $sharedWork "mt5_portable_research_w2"),
   (Join-Path $sharedWork "mt5_portable_research_w3"),
   (Join-Path $sharedWork "mt5_portable_research_w4")
)
$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

$plan = & $preparer -SourcePath $source -ExpectedSourceSha256 $sourceHash `
   -PortableRoots $roots -PlanOnly -NoWritePlan
if($plan.Roots -ne 4 -or $plan.RuntimeFailures -ne 0 -or $plan.MQL5Launched -or
   $plan.SourceSha256 -ne $sourceHash -or
   $plan.CurrentSourceIdentities -lt 1 -or $plan.CurrentBinaryIdentities -lt 1 -or
   $plan.Status -notin @("LOCKED_COMPILE_ONCE_REQUIRED","SHARED_BINARY_READY")) {
   throw "Shared expert plan does not match the four-runtime contract."
}

$wrongSourceRejected = $false
try {
   & $preparer -SourcePath $source -ExpectedSourceSha256 ("A" * 64) `
      -PortableRoots $roots -PlanOnly -NoWritePlan | Out-Null
}
catch { $wrongSourceRejected = $_.Exception.Message -match "source identity changed" }
if(!$wrongSourceRejected) { throw "Shared expert plan accepted a changed source identity." }

$duplicateRootsRejected = $false
try {
   & $preparer -SourcePath $source -ExpectedSourceSha256 $sourceHash `
      -PortableRoots @($roots[0],$roots[0]) -PlanOnly -NoWritePlan | Out-Null
}
catch { $duplicateRootsRejected = $_.Exception.Message -match "unique list" }
if(!$duplicateRootsRejected) { throw "Shared expert plan accepted duplicate roots." }

$outsideRootRejected = $false
try {
   & $preparer -SourcePath $source -ExpectedSourceSha256 $sourceHash `
      -PortableRoots @($repo) -PlanOnly -NoWritePlan | Out-Null
}
catch { $outsideRootRejected = $_.Exception.Message -match "outside the exact shared research allowlist" }
if(!$outsideRootRejected) { throw "Shared expert plan accepted a root outside the exact allowlist." }

$hardLockRejected = $false
try {
   & $preparer -SourcePath $source -ExpectedSourceSha256 $sourceHash `
      -PortableRoots $roots -UserAuthorizedFocusRisk -NoWritePlan | Out-Null
}
catch { $hardLockRejected = $_.Exception.Message -match "hard-locked" }
if(!$hardLockRejected) { throw "Shared expert run mode did not honor the hard lock." }

$text = Get-Content -LiteralPath $preparer -Raw
foreach($token in @(
   "assert_mt5_launch_allowed.ps1","HiddenProcess]::StartHidden","0 errors, 0 warnings",
   "Install-ExactFile `$leaderSource `$targetSource `$expectedSourceHash",
   "Install-ExactFile `$leaderBinary `$targetBinary `$binaryHash",
   "Move-Item -LiteralPath `$temporaryIdentity -Destination `$targetIdentity",
   "Shared expert distribution verification failed","Shared compile changed the installed frozen artifacts"
)) {
   if($text -notmatch [regex]::Escape($token)) { throw "Shared expert preparation is missing: $token" }
}
if(([regex]::Matches($text, [regex]::Escape("HiddenProcess]::StartHidden"))).Count -ne 1) {
   throw "Shared expert preparation must have exactly one compiler launch site."
}

$after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if($after.Count -gt $before.Count) { throw "Shared expert preparation test launched an MT5-family process." }

[pscustomobject]@{
   Status = "PASS"
   PlanStatus = $plan.Status
   PortableRoots = $plan.Roots
   SharedBinaryReady = $plan.SharedBinaryReady
   WrongSourceRejected = $wrongSourceRejected
   DuplicateRootsRejected = $duplicateRootsRejected
   OutsideRootRejected = $outsideRootRejected
   HardLockRejected = $hardLockRejected
   CompilerLaunchSites = 1
   MQL5Launched = $false
}
