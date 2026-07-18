Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sharedWork = Split-Path -Parent $repo
$sync = Join-Path $PSScriptRoot "sync_mt5_portable_xauusd_tick_cache.ps1"
$helper = Join-Path $PSScriptRoot "mt5_tick_cache_sync_helpers.ps1"
. $helper
$roots = @(
   (Join-Path $sharedWork "mt5_portable_research"),
   (Join-Path $sharedWork "mt5_portable_research_w2"),
   (Join-Path $sharedWork "mt5_portable_research_w3"),
   (Join-Path $sharedWork "mt5_portable_research_w4")
)
$before = @(Get-Process terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

$plan = & $sync -PortableRoots $roots -NoWritePlan
if($plan.Status -ne "COVERAGE_MISSING" -or $plan.Roots -ne 4 -or
   $plan.CachedMonths -ne 39 -or $plan.RequiredMonths -ne 138 -or $plan.MissingRequiredMonths -ne 100 -or
   $plan.InventoryFiles -ne 156 -or $plan.HashedFiles -ne 152 -or
   $plan.CopyOperations -ne 0 -or $plan.Conflicts -ne 0 -or $plan.MQL5Launched) {
   throw "Current portable XAUUSD tick caches do not match the exact four-root plan."
}

$unauthorizedRejected = $false
try {
   & $sync -PortableRoots $roots -Synchronize -NoWritePlan | Out-Null
}
catch { $unauthorizedRejected = $_.Exception.Message -match "explicit cache-write authorization" }
if(!$unauthorizedRejected) { throw "Tick-cache synchronization accepted an unauthorized write request." }

$coverageRejected = $false
try {
   & $sync -PortableRoots $roots -Synchronize -UserAuthorizedCacheWrite -NoWritePlan | Out-Null
}
catch { $coverageRejected = $_.Exception.Message -match "required complete months are absent" }
if(!$coverageRejected) { throw "Tick-cache synchronization accepted incomplete required-month coverage." }

$duplicateRootsRejected = $false
try {
   & $sync -PortableRoots @($roots[0],$roots[0]) -NoWritePlan | Out-Null
}
catch { $duplicateRootsRejected = $_.Exception.Message -match "unique list" }
if(!$duplicateRootsRejected) { throw "Tick-cache synchronization accepted duplicate roots." }

$outsideRootRejected = $false
try {
   & $sync -PortableRoots @($roots[0],$repo) -NoWritePlan | Out-Null
}
catch { $outsideRootRejected = $_.Exception.Message -match "outside the exact shared research allowlist" }
if(!$outsideRootRejected) { throw "Tick-cache synchronization accepted a root outside the exact allowlist." }

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("mt5_tick_cache_sync_test_" + [guid]::NewGuid().ToString("N"))
$fixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
if(!$fixtureRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe tick-cache fixture path." }
$fixtureCopyPassed = $false
$conflictRejected = $false
$overwriteRejected = $false
$badHashRejected = $false
$commitGuardRejected = $false
try {
   $fixtureA = Join-Path $fixtureRoot "root_a"
   $fixtureB = Join-Path $fixtureRoot "root_b"
   $source = Join-Path $fixtureA "bases\MetaQuotes-Demo\ticks\XAUUSD\202401.tkc"
   New-Item -ItemType Directory -Path (Split-Path -Parent $source) -Force | Out-Null
   [IO.File]::WriteAllBytes($source, [byte[]](1,3,5,7,9,11,13,15))
   $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
   $fixtureInventory = @(
      [pscustomobject]@{ Root=$fixtureA; RootName="root_a"; FileName="202401.tkc"; FullName=$source; Bytes=8; Mutable=$false; Sha256=$sourceHash },
      [pscustomobject]@{ Root=$fixtureA; RootName="root_a"; FileName="209912.tkc"; FullName="mutable-a"; Bytes=8; Mutable=$true; Sha256="SKIPPED_MUTABLE" },
      [pscustomobject]@{ Root=$fixtureB; RootName="root_b"; FileName="209912.tkc"; FullName="mutable-b"; Bytes=9; Mutable=$true; Sha256="SKIPPED_MUTABLE" }
   )
   $fixturePlan = Get-MT5TickCacheUnionPlan -Inventory $fixtureInventory -AllowedRoots @($fixtureA,$fixtureB) -RequiredMonths @("202401")
   if($fixturePlan.Operations.Count -ne 1 -or $fixturePlan.Conflicts -ne 0 -or
      @($fixturePlan.Rows | Where-Object State -eq "SKIPPED_PARTIAL_CUTOFF").Count -ne 1) {
      throw "Disposable cache plan did not isolate one missing complete month and one partial cutoff month."
   }
   $operation = $fixturePlan.Operations[0]
   Install-MT5VerifiedMissingTickFile -Source $operation.Source -Target $operation.Target -ExpectedSha256 $operation.Sha256
   $fixtureCopyPassed = (Get-FileHash -LiteralPath $operation.Target -Algorithm SHA256).Hash.ToUpperInvariant() -eq $sourceHash
   if(!$fixtureCopyPassed) { throw "Disposable verified cache copy did not preserve identity." }

   try {
      Install-MT5VerifiedMissingTickFile -Source $source -Target $operation.Target -ExpectedSha256 $sourceHash
   }
   catch { $overwriteRejected = $_.Exception.Message -match "refusing overwrite" }
   if(!$overwriteRejected) { throw "Verified cache installer accepted an overwrite." }

   $badTarget = Join-Path $fixtureB "bases\MetaQuotes-Demo\ticks\XAUUSD\202402.tkc"
   try {
      Install-MT5VerifiedMissingTickFile -Source $source -Target $badTarget -ExpectedSha256 ("A" * 64)
   }
   catch { $badHashRejected = $_.Exception.Message -match "failed SHA-256 verification" }
   if(!$badHashRejected -or (Test-Path -LiteralPath $badTarget)) {
      throw "Verified cache installer retained or accepted a bad-hash copy."
   }

   $guardedTarget = Join-Path $fixtureB "bases\MetaQuotes-Demo\ticks\XAUUSD\202403.tkc"
   try {
      Install-MT5VerifiedMissingTickFile -Source $source -Target $guardedTarget -ExpectedSha256 $sourceHash `
         -BeforeCommit { throw "fixture process guard" }
   }
   catch { $commitGuardRejected = $_.Exception.Message -match "fixture process guard" }
   if(!$commitGuardRejected -or (Test-Path -LiteralPath $guardedTarget)) {
      throw "Verified cache installer committed a file after its final guard failed."
   }

   $conflictInventory = @(
      [pscustomobject]@{ Root=$fixtureA; RootName="root_a"; FileName="202312.tkc"; FullName="a"; Bytes=8; Mutable=$false; Sha256=("A" * 64) },
      [pscustomobject]@{ Root=$fixtureB; RootName="root_b"; FileName="202312.tkc"; FullName="b"; Bytes=8; Mutable=$false; Sha256=("B" * 64) }
   )
   $conflictPlan = Get-MT5TickCacheUnionPlan -Inventory $conflictInventory -AllowedRoots @($fixtureA,$fixtureB) -RequiredMonths @("202311","202312")
   $conflictRejected = $conflictPlan.Conflicts -eq 1 -and $conflictPlan.MissingRequiredMonths -eq 1 -and $conflictPlan.Operations.Count -eq 0
   if(!$conflictRejected) { throw "Disposable cache plan did not fail closed on a closed-month hash conflict." }
}
finally {
   if(Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

$text = (Get-Content -LiteralPath $sync -Raw) + "`n" + (Get-Content -LiteralPath $helper -Raw)
foreach($token in @(
   "mt5_tick_cache_sync_helpers.ps1","bases\MetaQuotes-Demo\ticks\XAUUSD","^\d{6}\.tkc$","HASH_CONFLICT","SKIPPED_PARTIAL_CUTOFF","MISSING_ALL_ROOTS",
   "Portable MT5 processes must be fully stopped","BeforeCommit","refusing overwrite",
   "sync.tmp.","Get-FileHash -LiteralPath `$temporary","did not produce one exact union",
   "Account, trade, configuration, source, binary, and report files are outside this operation"
)) {
   if($text -notmatch [regex]::Escape($token)) { throw "Tick-cache synchronization is missing: $token" }
}
foreach($forbidden in @("Start-Process","Start-MT5Hidden","HiddenProcess]::StartHidden")) {
   if($text -match [regex]::Escape($forbidden)) { throw "Tick-cache synchronization may not launch processes: $forbidden" }
}

$after = @(Get-Process terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if($after.Count -gt $before.Count) { throw "Tick-cache synchronization test launched an MT5-family process." }

[pscustomobject]@{
   Status = "PASS"
   PortableRoots = $plan.Roots
   CachedMonths = $plan.CachedMonths
   RequiredMonths = $plan.RequiredMonths
   MissingRequiredMonths = $plan.MissingRequiredMonths
   InventoryFiles = $plan.InventoryFiles
   HashedFiles = $plan.HashedFiles
   HashConflicts = $plan.Conflicts
   UnauthorizedRejected = $unauthorizedRejected
   IncompleteCoverageRejected = $coverageRejected
   DuplicateRootsRejected = $duplicateRootsRejected
   OutsideRootRejected = $outsideRootRejected
   FixtureCopyPassed = $fixtureCopyPassed
   HistoricalConflictRejected = $conflictRejected
   OverwriteRejected = $overwriteRejected
   BadHashRejected = $badHashRejected
   CommitGuardRejected = $commitGuardRejected
   MQL5Launched = $false
}
