param(
   [Parameter(Mandatory=$true)][string]$PortableRoot,
   [Parameter(Mandatory=$true)][string]$ConfigPath,
   [Parameter(Mandatory=$true)][switch]$UserAuthorizedFocusRisk,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [int]$TimeoutMinutes = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "mt5_background_helpers.ps1")

if(!$UserAuthorizedFocusRisk) { throw "Explicit focus-risk authorization is required." }
. (Join-Path $PSScriptRoot "assert_mt5_launch_allowed.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$portable = (Resolve-Path -LiteralPath $PortableRoot).Path.TrimEnd('\')
$config = (Resolve-Path -LiteralPath $ConfigPath).Path
$terminal = Join-Path $portable "terminal64.exe"
$metaEditor = Join-Path $portable "MetaEditor64.exe"
$portableExperts = Join-Path $portable "MQL5\Experts"
$portableSource = Join-Path $portableExperts "Professional_XAUUSD_EA.mq5"
$portableBinary = Join-Path $portableExperts "Professional_XAUUSD_EA.ex5"
$portableIdentity = Join-Path $portableExperts "Professional_XAUUSD_EA.compiled_identity.txt"
$mainData = Join-Path $env:APPDATA "MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts"
$mainSource = Join-Path $mainData "Professional_XAUUSD_EA.mq5"
$mainBinary = Join-Path $mainData "Professional_XAUUSD_EA.ex5"

if(!(Test-Path -LiteralPath $terminal -PathType Leaf)) { throw "Portable terminal missing: $terminal" }
if(!(Test-Path -LiteralPath $metaEditor -PathType Leaf)) { throw "Portable MetaEditor missing: $metaEditor" }
$sharedWork = Split-Path -Parent $repo
$portableParent = Split-Path -Parent $portable
$portableName = Split-Path -Leaf $portable
$repoLocalPortable = $portable.StartsWith($repo + "\work\", [StringComparison]::OrdinalIgnoreCase)
$sharedResearchPortable = (
   $portableParent.Equals($sharedWork, [StringComparison]::OrdinalIgnoreCase) -and
   $portableName -match '^mt5_portable_research(?:_w\d+)?$'
)
if(!$repoLocalPortable -and !$sharedResearchPortable) { throw "Portable runtime is outside the workspace work directory." }
if(!$config.StartsWith($repo + "\", [StringComparison]::OrdinalIgnoreCase)) { throw "Tester config is outside the workspace." }
$configDir = Split-Path -Parent $config
$packageRoot = Split-Path -Parent $configDir
$packageSource = Join-Path $packageRoot "source\Professional_XAUUSD_EA.mq5"
if(!(Test-Path -LiteralPath $packageSource -PathType Leaf)) { throw "Package source is missing: $packageSource" }
if(!$packageSource.StartsWith($repo + "\outputs\", [StringComparison]::OrdinalIgnoreCase)) { throw "Package source is outside workspace outputs." }

function Get-OptionalHash([string]$Path) {
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return "MISSING" }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-PortableProcesses {
   return @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      ![string]::IsNullOrWhiteSpace([string]$_.ExecutablePath) -and
      ([string]$_.ExecutablePath).StartsWith($portable + "\", [StringComparison]::OrdinalIgnoreCase)
   })
}

function Stop-PortableProcesses {
   foreach($item in (Get-PortableProcesses)) {
      Stop-Process -Id ([int]$item.ProcessId) -Force -ErrorAction SilentlyContinue
   }
}

function Set-PortableLowImpact {
   $mask = Get-MT5ProcessorAffinityMask -MaxCpuPercent $MaxCpuPercent
   foreach($item in (Get-PortableProcesses)) {
      $process = Get-Process -Id ([int]$item.ProcessId) -ErrorAction SilentlyContinue
      if(!$process) { continue }
      try { $process.PriorityClass = [Diagnostics.ProcessPriorityClass]::BelowNormal } catch {}
      try { $process.ProcessorAffinity = $mask } catch {}
   }
   Set-MT5ProcessMute
}

function Install-PortablePackageExpert {
   if(!(Test-Path -LiteralPath $portableExperts -PathType Container)) {
      New-Item -ItemType Directory -Path $portableExperts -Force | Out-Null
   }
   $sourceHash = (Get-FileHash -LiteralPath $packageSource -Algorithm SHA256).Hash.ToUpperInvariant()
   $binaryHash = Get-OptionalHash $portableBinary
   $identityMatches = $false
   if(Test-Path -LiteralPath $portableIdentity -PathType Leaf) {
      $identity = @(Get-Content -LiteralPath $portableIdentity)
      $identityMatches = $identity.Count -ge 2 -and $identity[0] -eq $sourceHash -and
                         $identity[1] -eq $binaryHash -and $binaryHash -ne "MISSING" -and
                         (Get-OptionalHash $portableSource) -eq $sourceHash
   }
   if($identityMatches) {
      return [pscustomobject]@{ SourceSha256=$sourceHash; BinarySha256=$binaryHash; Recompiled=$false }
   }

   Stop-PortableProcesses
   Copy-Item -LiteralPath $packageSource -Destination $portableSource -Force
   Remove-Item -LiteralPath $portableBinary -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath $portableIdentity -Force -ErrorAction SilentlyContinue
   $compileLog = Join-Path $portable "portable_package_compile.log"
   Remove-Item -LiteralPath $compileLog -Force -ErrorAction SilentlyContinue
   $arguments = "/portable /compile:`"$portableSource`" /log:`"$compileLog`""
   $editorId = [Mt5Audio.HiddenProcess]::StartHidden($metaEditor, $arguments)
   $compileDeadline = (Get-Date).AddMinutes([Math]::Min(5, [Math]::Max(1, $TimeoutMinutes)))
   do {
      Start-Sleep -Milliseconds 500
      Set-PortableLowImpact
      $editor = Get-Process -Id $editorId -ErrorAction SilentlyContinue
   } while($editor -and (Get-Date) -lt $compileDeadline)
   if($editor) {
      Stop-Process -Id $editorId -Force -ErrorAction SilentlyContinue
      throw "Portable package compile timed out."
   }
   if(!(Test-Path -LiteralPath $compileLog -PathType Leaf)) { throw "Portable compile log was not produced." }
   $resultLine = Get-Content -LiteralPath $compileLog | Where-Object { $_ -match "Result:" } | Select-Object -Last 1
   if(!$resultLine -or $resultLine -notmatch "0 errors, 0 warnings") {
      throw "Portable package compile failed or produced warnings: $resultLine"
   }
   if(!(Test-Path -LiteralPath $portableBinary -PathType Leaf)) { throw "Portable compiled binary is missing." }
   if((Get-OptionalHash $portableSource) -ne $sourceHash) { throw "Portable source hash does not match package source." }
   $binaryHash = (Get-FileHash -LiteralPath $portableBinary -Algorithm SHA256).Hash.ToUpperInvariant()
   @($sourceHash, $binaryHash) | Set-Content -LiteralPath $portableIdentity -Encoding ASCII
   return [pscustomobject]@{ SourceSha256=$sourceHash; BinarySha256=$binaryHash; Recompiled=$true }
}

$configText = Get-Content -LiteralPath $config
$reportLine = $configText | Where-Object { $_ -match '^Report=' } | Select-Object -First 1
if(!$reportLine) { throw "Tester config has no Report setting." }
$reportName = ($reportLine -replace '^Report=', '').Trim()
$reportCandidates = @(".htm", ".html", ".xml") | ForEach-Object { Join-Path $portable ($reportName + $_) }
foreach($candidate in $reportCandidates) { Remove-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue }

$mainInstall = "C:\Program Files\MetaTrader 5\"
$mainTerminalIds = @(Get-Process terminal,terminal64 -ErrorAction SilentlyContinue | Where-Object {
   try { $_.Path.StartsWith($mainInstall, [StringComparison]::OrdinalIgnoreCase) } catch { $false }
} | Select-Object -ExpandProperty Id)
$mainSourceHash = Get-OptionalHash $mainSource
$mainBinaryHash = Get-OptionalHash $mainBinary
Stop-PortableProcesses
$portableExpert = Install-PortablePackageExpert

$processId = [Mt5Audio.HiddenProcess]::StartHidden($terminal, "/portable /config:`"$config`"")
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$report = $null
do {
   Start-Sleep -Milliseconds 750
   Set-PortableLowImpact
   $report = $reportCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
   $running = Get-Process -Id $processId -ErrorAction SilentlyContinue
   if(!$running -and !$report) {
      Start-Sleep -Seconds 1
      $report = $reportCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
      break
   }
} while(!$report -and (Get-Date) -lt $deadline)

if(!$report) {
   $report = Get-ChildItem -LiteralPath $portable -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.BaseName -eq $reportName -and $_.Extension -in @('.htm','.html','.xml') } |
      Select-Object -ExpandProperty FullName -First 1
}
Stop-PortableProcesses

if(!$report -or !(Test-Path -LiteralPath $report -PathType Leaf)) { throw "Portable tester produced no report for $reportName." }
if((Get-Item -LiteralPath $report).Length -le 0) { throw "Portable tester produced an empty report." }
foreach($terminalId in $mainTerminalIds) {
   if(!(Get-Process -Id $terminalId -ErrorAction SilentlyContinue)) { throw "Portable tester interrupted the pre-existing terminal." }
}
if((Get-OptionalHash $mainSource) -ne $mainSourceHash -or (Get-OptionalHash $mainBinary) -ne $mainBinaryHash) {
   throw "Portable tester changed the installed frozen artifacts."
}

[pscustomobject]@{
   Status = "REPORT_FOUND"
   PortableRoot = $portable
   Config = $config
   Report = $report
   ReportBytes = (Get-Item -LiteralPath $report).Length
   PackageSourceSha256 = $portableExpert.SourceSha256
   PortableBinarySha256 = $portableExpert.BinarySha256
   PortableExpertRecompiled = $portableExpert.Recompiled
   PreservedMainTerminalProcesses = $mainTerminalIds.Count
   InstalledFrozenArtifactsUnchanged = $true
}
