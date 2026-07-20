[CmdletBinding()]
param(
   [Parameter(Mandatory=$true)][string]$SourcePath,
   [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedSourceSha256,
   [Parameter(Mandatory=$true)][string[]]$PortableRoots,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,30)][int]$CompileTimeoutMinutes = 5,
   [switch]$UserAuthorizedFocusRisk,
   [switch]$PlanOnly,
   [switch]$NoWritePlan,
   [string]$OutCsv = "outputs\MT5_PORTABLE_SHARED_EXPERT_PLAN.csv",
   [string]$OutMarkdown = "outputs\MT5_PORTABLE_SHARED_EXPERT_PLAN.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sharedWork = Split-Path -Parent $repo
$sourceCandidate = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
$source = (Resolve-Path -LiteralPath $sourceCandidate).Path
$expectedSourceHash = $ExpectedSourceSha256.ToUpperInvariant()

if(!$source.StartsWith((Join-Path $repo "outputs") + "\", [StringComparison]::OrdinalIgnoreCase) -or
   [IO.Path]::GetFileName($source) -ne "Professional_XAUUSD_EA.mq5") {
   throw "Shared expert source must be the package source under repository outputs."
}
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Shared expert source identity changed." }
if($PortableRoots.Count -lt 1 -or @($PortableRoots | Sort-Object -Unique).Count -ne $PortableRoots.Count) {
   throw "Portable roots must be a non-empty unique list."
}

function Resolve-PortableRoot([string]$Path) {
   $candidate = if([IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $repo $Path }
   $resolved = (Resolve-Path -LiteralPath $candidate).Path.TrimEnd('\')
   $parent = Split-Path -Parent $resolved
   $name = Split-Path -Leaf $resolved
   if(!$parent.Equals($sharedWork, [StringComparison]::OrdinalIgnoreCase) -or
      $name -notmatch '^mt5_portable_research(?:_w\d+)?$') {
      throw "Portable runtime is outside the exact shared research allowlist: $resolved"
   }
   return $resolved
}

function Get-OptionalHash([string]$Path) {
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return "MISSING" }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$roots = @($PortableRoots | ForEach-Object { Resolve-PortableRoot $_ })
$rows = [System.Collections.Generic.List[object]]::new()
foreach($root in $roots) {
   $terminal = Join-Path $root "terminal64.exe"
   $editor = Join-Path $root "MetaEditor64.exe"
   $portableSource = Join-Path $root "MQL5\Experts\Professional_XAUUSD_EA.mq5"
   $portableBinary = Join-Path $root "MQL5\Experts\Professional_XAUUSD_EA.ex5"
   $portableIdentity = Join-Path $root "MQL5\Experts\Professional_XAUUSD_EA.compiled_identity.txt"
   $identityLines = @()
   if(Test-Path -LiteralPath $portableIdentity -PathType Leaf) {
      $identityLines = @(Get-Content -LiteralPath $portableIdentity)
   }
   $installedSourceHash = Get-OptionalHash $portableSource
   $binaryHash = Get-OptionalHash $portableBinary
   $identitySourceHash = if($identityLines.Count -ge 1) { ([string]$identityLines[0]).ToUpperInvariant() } else { "MISSING" }
   $identityBinaryHash = if($identityLines.Count -ge 2) { ([string]$identityLines[1]).ToUpperInvariant() } else { "MISSING" }
   $runtimeReady = (Test-Path -LiteralPath $terminal -PathType Leaf) -and
                   (Test-Path -LiteralPath $editor -PathType Leaf)
   $identityReady = $runtimeReady -and $installedSourceHash -eq $expectedSourceHash -and
                    $binaryHash -ne "MISSING" -and $identitySourceHash -eq $expectedSourceHash -and
                    $identityBinaryHash -eq $binaryHash
   $rows.Add([pscustomobject]@{
      PortableRoot = Split-Path -Leaf $root
      RuntimeReady = $runtimeReady
      TerminalVersion = if(Test-Path -LiteralPath $terminal) { (Get-Item -LiteralPath $terminal).VersionInfo.FileVersion } else { "MISSING" }
      InstalledSourceSha256 = $installedSourceHash
      BinarySha256 = $binaryHash
      IdentitySourceSha256 = $identitySourceHash
      IdentityBinarySha256 = $identityBinaryHash
      ExactSourceReady = ($installedSourceHash -eq $expectedSourceHash)
      IdentityReady = $identityReady
   }) | Out-Null
}

$runtimeFailures = @($rows | Where-Object { !$_.RuntimeReady }).Count
$readyRows = @($rows | Where-Object IdentityReady)
$readyBinaryHashes = @($readyRows | Select-Object -ExpandProperty BinarySha256 | Sort-Object -Unique)
$currentSourceHashes = @($rows | Where-Object InstalledSourceSha256 -ne "MISSING" | Select-Object -ExpandProperty InstalledSourceSha256 | Sort-Object -Unique)
$currentBinaryHashes = @($rows | Where-Object BinarySha256 -ne "MISSING" | Select-Object -ExpandProperty BinarySha256 | Sort-Object -Unique)
$sharedBinaryReady = $runtimeFailures -eq 0 -and $readyRows.Count -eq $rows.Count -and $readyBinaryHashes.Count -eq 1
$repoLock = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$outerLock = Join-Path $sharedWork "MT5_LOCAL_LAUNCH_DISABLED.lock"
$locked = (Test-Path -LiteralPath $repoLock) -or (Test-Path -LiteralPath $outerLock)
$status = if($runtimeFailures -gt 0) {
   "RUNTIME_MISSING"
} elseif($sharedBinaryReady) {
   "SHARED_BINARY_READY"
} elseif($locked) {
   "LOCKED_COMPILE_ONCE_REQUIRED"
} else {
   "COMPILE_ONCE_REQUIRED"
}
$action = if($runtimeFailures -gt 0) { "PROVISION_RUNTIME" } elseif($sharedBinaryReady) { "REUSE_EXACT_SHARED_BINARY" } else { "COMPILE_ON_LEADER_AND_DISTRIBUTE" }

if(!$NoWritePlan) {
   $csv = Resolve-RepoPath $OutCsv
   $markdown = Resolve-RepoPath $OutMarkdown
   foreach($path in @($csv,$markdown)) {
      $parent = Split-Path -Parent $path
      if($parent -and !(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
   }
   $rows | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding ASCII
   $md = @(
      "# MT5 Portable Shared Expert Plan",
      "",
      "- Status: **$status**",
      "- Action: ``$action``",
      "- Expected source SHA-256: ``$expectedSourceHash``",
      "- Portable roots: ``$($rows.Count)``",
      "- Runtime failures: ``$runtimeFailures``",
      "- Exact-source identities ready: ``$($readyRows.Count)``",
      "- Unique ready binary identities: ``$($readyBinaryHashes.Count)``",
      "- Current installed source identities: ``$($currentSourceHashes.Count)``",
      "- Current installed binary identities: ``$($currentBinaryHashes.Count)``",
      "- Repository or outer launch lock present: ``$locked``",
      "",
      "Plan mode is read-only and never launches MetaEditor or MT5. Run mode compiles once on the first allowlisted portable root, then distributes the same source, EX5, and identity file to every worker before parallel testing."
   )
   [IO.File]::WriteAllLines($markdown, $md, [Text.Encoding]::ASCII)
}

$plan = [pscustomobject]@{
   Status = $status
   Action = $action
   SourceSha256 = $expectedSourceHash
   Roots = $rows.Count
   RuntimeFailures = $runtimeFailures
   ReadyRoots = $readyRows.Count
   UniqueReadyBinaries = $readyBinaryHashes.Count
   CurrentSourceIdentities = $currentSourceHashes.Count
   CurrentBinaryIdentities = $currentBinaryHashes.Count
   SharedBinaryReady = $sharedBinaryReady
   MQL5Launched = $false
}
if($PlanOnly) {
   $plan
   return
}
if(!$UserAuthorizedFocusRisk) { throw "Shared expert preparation requires explicit focus-risk authorization." }
if($runtimeFailures -gt 0) { throw "Shared expert preparation cannot run with missing portable runtimes." }
. (Join-Path $PSScriptRoot "assert_mt5_launch_allowed.ps1")
. (Join-Path $PSScriptRoot "mt5_background_helpers.ps1")

if($sharedBinaryReady) {
   [pscustomobject]@{
      Status = "REUSED_SHARED_BINARY"
      SourceSha256 = $expectedSourceHash
      PortableBinarySha256 = $readyBinaryHashes[0]
      Roots = $rows.Count
      Recompiled = $false
   }
   return
}

$mainData = Join-Path $env:APPDATA "MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts"
$mainSource = Join-Path $mainData "Professional_XAUUSD_EA.mq5"
$mainBinary = Join-Path $mainData "Professional_XAUUSD_EA.ex5"
$mainSourceHash = Get-OptionalHash $mainSource
$mainBinaryHash = Get-OptionalHash $mainBinary
$mainTerminalIds = @(Get-Process terminal,terminal64 -ErrorAction SilentlyContinue | Where-Object {
   try { $_.Path.StartsWith("C:\Program Files\MetaTrader 5\", [StringComparison]::OrdinalIgnoreCase) } catch { $false }
} | Select-Object -ExpandProperty Id)

function Get-PortableProcesses {
   return @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      $path = [string]$_.ExecutablePath
      ![string]::IsNullOrWhiteSpace($path) -and @($roots | Where-Object {
         $path.StartsWith($_ + "\", [StringComparison]::OrdinalIgnoreCase)
      }).Count -gt 0
   })
}

function Stop-PortableProcesses {
   foreach($process in (Get-PortableProcesses)) {
      Stop-Process -Id ([int]$process.ProcessId) -Force -ErrorAction SilentlyContinue
   }
}

function Install-ExactFile([string]$From, [string]$To, [string]$ExpectedHash) {
   $temporary = $To + ".shared.tmp." + [guid]::NewGuid().ToString("N")
   try {
      Copy-Item -LiteralPath $From -Destination $temporary -Force
      if((Get-OptionalHash $temporary) -ne $ExpectedHash) {
         throw "Shared expert temporary file identity mismatch: $To"
      }
      Move-Item -LiteralPath $temporary -Destination $To -Force
   }
   finally {
      Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
   }
}

Stop-PortableProcesses
if(@(Get-PortableProcesses).Count -gt 0) { throw "Portable MT5 processes could not be stopped before shared compilation." }

$leader = $roots[0]
$leaderExperts = Join-Path $leader "MQL5\Experts"
$leaderSource = Join-Path $leaderExperts "Professional_XAUUSD_EA.mq5"
$leaderBinary = Join-Path $leaderExperts "Professional_XAUUSD_EA.ex5"
$leaderIdentity = Join-Path $leaderExperts "Professional_XAUUSD_EA.compiled_identity.txt"
$editor = Join-Path $leader "MetaEditor64.exe"
$compileLog = Join-Path $leader "portable_shared_expert_compile.log"
New-Item -ItemType Directory -Path $leaderExperts -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $leaderSource -Force
Remove-Item -LiteralPath $leaderBinary,$leaderIdentity,$compileLog -Force -ErrorAction SilentlyContinue

$editorId = 0
try {
   $arguments = "/portable /compile:`"$leaderSource`" /log:`"$compileLog`""
   $editorId = [Mt5Audio.HiddenProcess]::StartHidden($editor, $arguments)
   $deadline = (Get-Date).AddMinutes($CompileTimeoutMinutes)
   do {
      Start-Sleep -Milliseconds 500
      Set-MT5BackgroundSafe -MaxCpuPercent $MaxCpuPercent
      $editorProcess = Get-Process -Id $editorId -ErrorAction SilentlyContinue
   } while($editorProcess -and (Get-Date) -lt $deadline)
   if($editorProcess) { throw "Shared portable expert compile timed out." }
}
finally {
   if($editorId -gt 0) { Stop-Process -Id $editorId -Force -ErrorAction SilentlyContinue }
   Set-MT5ProcessMute -Muted $true
}

if(!(Test-Path -LiteralPath $compileLog -PathType Leaf)) { throw "Shared portable compile log was not produced." }
$resultLine = Get-Content -LiteralPath $compileLog | Where-Object { $_ -match 'Result:' } | Select-Object -Last 1
if(!$resultLine -or $resultLine -notmatch '0 errors, 0 warnings') {
   throw "Shared portable compile failed or produced warnings: $resultLine"
}
if((Get-OptionalHash $leaderSource) -ne $expectedSourceHash) { throw "Leader source changed during compilation." }
$binaryHash = Get-OptionalHash $leaderBinary
if($binaryHash -eq "MISSING") { throw "Shared compiled binary is missing." }
@($expectedSourceHash,$binaryHash) | Set-Content -LiteralPath $leaderIdentity -Encoding ASCII

foreach($root in $roots) {
   $experts = Join-Path $root "MQL5\Experts"
   New-Item -ItemType Directory -Path $experts -Force | Out-Null
   $targetSource = Join-Path $experts "Professional_XAUUSD_EA.mq5"
   $targetBinary = Join-Path $experts "Professional_XAUUSD_EA.ex5"
   $targetIdentity = Join-Path $experts "Professional_XAUUSD_EA.compiled_identity.txt"
   if($root -ne $leader) {
      Install-ExactFile $leaderSource $targetSource $expectedSourceHash
      Install-ExactFile $leaderBinary $targetBinary $binaryHash
      $temporaryIdentity = $targetIdentity + ".shared.tmp." + [guid]::NewGuid().ToString("N")
      try {
         Copy-Item -LiteralPath $leaderIdentity -Destination $temporaryIdentity -Force
         Move-Item -LiteralPath $temporaryIdentity -Destination $targetIdentity -Force
      }
      finally {
         Remove-Item -LiteralPath $temporaryIdentity -Force -ErrorAction SilentlyContinue
      }
   }
   $identityLines = @(Get-Content -LiteralPath $targetIdentity)
   if((Get-OptionalHash $targetSource) -ne $expectedSourceHash -or
      (Get-OptionalHash $targetBinary) -ne $binaryHash -or
      $identityLines.Count -lt 2 -or $identityLines[0] -ne $expectedSourceHash -or
      $identityLines[1] -ne $binaryHash) {
      throw "Shared expert distribution verification failed for $root"
   }
}

foreach($terminalId in $mainTerminalIds) {
   if(!(Get-Process -Id $terminalId -ErrorAction SilentlyContinue)) { throw "Shared compile interrupted the pre-existing main terminal." }
}
if((Get-OptionalHash $mainSource) -ne $mainSourceHash -or (Get-OptionalHash $mainBinary) -ne $mainBinaryHash) {
   throw "Shared compile changed the installed frozen artifacts."
}

[pscustomobject]@{
   Status = "COMPILED_ONCE_AND_DISTRIBUTED"
   SourceSha256 = $expectedSourceHash
   PortableBinarySha256 = $binaryHash
   Roots = $roots.Count
   Recompiled = $true
}
