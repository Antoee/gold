[CmdletBinding()]
param(
   [Parameter(Mandatory=$true)][string[]]$PortableRoots,
   [switch]$Synchronize,
   [switch]$UserAuthorizedCacheWrite,
   [switch]$NoWritePlan,
   [ValidatePattern('^\d{6}$')][string]$RequiredFromMonth = "201501",
   [ValidatePattern('^\d{6}$')][string]$RequiredThroughMonth = "202606",
   [ValidatePattern('^\d{6}$')][string]$PartialCutoffMonth = "202607",
   [string]$OutCsv = "outputs\MT5_PORTABLE_XAUUSD_TICK_CACHE_PLAN.csv",
   [string]$OutMarkdown = "outputs\MT5_PORTABLE_XAUUSD_TICK_CACHE_PLAN.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "mt5_tick_cache_sync_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sharedWork = Split-Path -Parent $repo

if($PortableRoots.Count -lt 2 -or @($PortableRoots | Sort-Object -Unique).Count -ne $PortableRoots.Count) {
   throw "Portable roots must be a unique list containing at least two workers."
}
if($Synchronize -and !$UserAuthorizedCacheWrite) {
   throw "Tick-cache synchronization requires explicit cache-write authorization."
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

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Get-PortableProcesses([string[]]$AllowedRoots) {
   return @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      $path = [string]$_.ExecutablePath
      ![string]::IsNullOrWhiteSpace($path) -and @($AllowedRoots | Where-Object {
         $path.StartsWith($_ + "\", [StringComparison]::OrdinalIgnoreCase)
      }).Count -gt 0
   })
}

function Get-OperationBytes([object[]]$Operations) {
   $total = [long]0
   foreach($operation in @($Operations)) { $total += [long]$operation.Bytes }
   return $total
}

function Get-RequiredCompleteMonths([string]$FromMonth, [string]$ThroughMonth) {
   $from = [datetime]::ParseExact($FromMonth, "yyyyMM", [Globalization.CultureInfo]::InvariantCulture)
   $to = [datetime]::ParseExact($ThroughMonth, "yyyyMM", [Globalization.CultureInfo]::InvariantCulture)
   if($from -gt $to) { throw "Required tick-cache month range is reversed." }
   $months = [System.Collections.Generic.List[string]]::new()
   for($cursor=$from; $cursor -le $to; $cursor=$cursor.AddMonths(1)) {
      $months.Add($cursor.ToString("yyyyMM")) | Out-Null
   }
   return @($months)
}

function Get-CacheInventory([string[]]$AllowedRoots, [string]$ExcludedPartialMonth) {
   $entries = [System.Collections.Generic.List[object]]::new()
   foreach($root in $AllowedRoots) {
      $tickDir = Join-Path $root "bases\MetaQuotes-Demo\ticks\XAUUSD"
      if(!(Test-Path -LiteralPath $tickDir -PathType Container)) { continue }
      foreach($file in @(Get-ChildItem -LiteralPath $tickDir -Filter "*.tkc" -File | Sort-Object Name)) {
         if($file.Name -notmatch '^\d{6}\.tkc$') { continue }
         if(($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Tick-cache files may not be reparse points: $($file.FullName)"
         }
         $entries.Add([pscustomobject]@{
            Root = $root
            RootName = Split-Path -Leaf $root
            FileName = $file.Name
            FullName = $file.FullName
            Bytes = [long]$file.Length
            Mutable = ([IO.Path]::GetFileNameWithoutExtension($file.Name) -eq $ExcludedPartialMonth)
            Sha256 = if([IO.Path]::GetFileNameWithoutExtension($file.Name) -eq $ExcludedPartialMonth) {
               "SKIPPED_PARTIAL_CUTOFF"
            } else {
               (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
            }
         }) | Out-Null
      }
   }
   return @($entries)
}

function Write-Plan([object]$Plan, [string]$Status, [string]$Action) {
   if($NoWritePlan) { return }
   $csv = Resolve-RepoPath $OutCsv
   $markdown = Resolve-RepoPath $OutMarkdown
   foreach($path in @($csv,$markdown)) {
      $parent = Split-Path -Parent $path
      if($parent -and !(Test-Path -LiteralPath $parent)) {
         New-Item -ItemType Directory -Path $parent -Force | Out-Null
      }
   }
   $Plan.Rows | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding ASCII
   $copyBytes = Get-OperationBytes $Plan.Operations
   $md = @(
      "# MT5 Portable XAUUSD Tick Cache Plan",
      "",
      "- Status: **$Status**",
      "- Action: ``$Action``",
      "- Portable roots: ``$($roots.Count)``",
      "- Cached months visible: ``$($Plan.CachedMonths)``",
      "- Required complete months: ``$($Plan.RequiredMonths)``",
      "- Excluded partial cutoff month: ``$PartialCutoffMonth``",
      "- Missing required months: ``$($Plan.MissingRequiredMonths)``",
      "- Inventory files inspected: ``$($Plan.InventoryFiles)``",
      "- Complete-month files hashed: ``$($Plan.HashedFiles)``",
      "- Copy operations required: ``$($Plan.Operations.Count)``",
      "- Bytes to copy: ``$copyBytes``",
      "- Hash conflicts: ``$($Plan.Conflicts)``",
      "",
      "Only allowlisted MetaQuotes-Demo XAUUSD TKC (.tkc) files are inventoried. The frozen partial cutoff month is reported but never copied because unused tail ticks may differ between roots. Account, trade, configuration, source, binary, and report files are outside this operation. A complete-month hash conflict fails closed and is never overwritten."
   )
   [IO.File]::WriteAllLines($markdown, $md, [Text.Encoding]::ASCII)
}

$roots = @($PortableRoots | ForEach-Object { Resolve-PortableRoot $_ })
$requiredMonths = @(Get-RequiredCompleteMonths $RequiredFromMonth $RequiredThroughMonth)
if($requiredMonths.Count -lt 1) { throw "Required tick-cache range contains no complete months." }
if($PartialCutoffMonth -in $requiredMonths) { throw "Partial cutoff month may not be part of the complete-month range." }
$plan = Get-MT5TickCacheUnionPlan -Inventory @(Get-CacheInventory $roots $PartialCutoffMonth) -AllowedRoots $roots -RequiredMonths $requiredMonths
$status = if($plan.Conflicts -gt 0) {
   "HASH_CONFLICT"
} elseif($plan.MissingRequiredMonths -gt 0) {
   "COVERAGE_MISSING"
} elseif($plan.Operations.Count -gt 0) {
   "COPY_REQUIRED"
} else {
   "SYNCHRONIZED"
}
$action = if($plan.Conflicts -gt 0) {
   "STOP_AND_INSPECT"
} elseif($plan.MissingRequiredMonths -gt 0) {
   "RUN_DISJOINT_ERAS_BEFORE_SYNC"
} elseif($plan.Operations.Count -gt 0) {
   "COPY_VERIFIED_MISSING_FILES"
} else {
   "NO_COPY_NEEDED"
}
Write-Plan $plan $status $action

if(!$Synchronize) {
   [pscustomobject]@{
      Status = $status
      Action = $action
      Roots = $roots.Count
      CachedMonths = $plan.CachedMonths
      RequiredMonths = $plan.RequiredMonths
      MissingRequiredMonths = $plan.MissingRequiredMonths
      InventoryFiles = $plan.InventoryFiles
      HashedFiles = $plan.HashedFiles
      CopyOperations = $plan.Operations.Count
      CopyBytes = Get-OperationBytes $plan.Operations
      Conflicts = $plan.Conflicts
      MQL5Launched = $false
   }
   return
}

$running = @(Get-PortableProcesses $roots)
if($running.Count -gt 0) {
   throw "Portable MT5 processes must be fully stopped before tick-cache synchronization."
}
if($plan.Conflicts -gt 0) {
   throw "Tick-cache synchronization refused one or more same-month hash conflicts."
}
if($plan.MissingRequiredMonths -gt 0) {
   throw "Tick-cache synchronization cannot proceed because required complete months are absent from every root."
}
if($plan.Operations.Count -eq 0) {
   [pscustomobject]@{
      Status = "ALREADY_SYNCHRONIZED"
      Roots = $roots.Count
      CachedMonths = $plan.CachedMonths
      RequiredMonths = $plan.RequiredMonths
      FilesCopied = 0
      BytesCopied = 0
      MQL5Launched = $false
   }
   return
}

$copyBytes = Get-OperationBytes $plan.Operations
$driveName = ([IO.Path]::GetPathRoot($roots[0])).Substring(0,1)
$drive = Get-PSDrive -Name $driveName
if([long]$drive.Free -lt ($copyBytes + 2GB)) {
   throw "Insufficient free space for verified tick-cache synchronization."
}

$copied = 0
foreach($operation in $plan.Operations) {
   if(@(Get-PortableProcesses $roots).Count -gt 0) {
      throw "A portable MT5 process started during tick-cache synchronization."
   }
   Install-MT5VerifiedMissingTickFile -Source $operation.Source -Target $operation.Target `
      -ExpectedSha256 $operation.Sha256 -BeforeCommit {
         if(@(Get-PortableProcesses $roots).Count -gt 0) {
            throw "A portable MT5 process started before atomic tick-cache commit."
         }
      }
   $copied++
}

if(@(Get-PortableProcesses $roots).Count -gt 0) {
   throw "A portable MT5 process was present after tick-cache synchronization."
}
$verified = Get-MT5TickCacheUnionPlan -Inventory @(Get-CacheInventory $roots $PartialCutoffMonth) -AllowedRoots $roots -RequiredMonths $requiredMonths
if($verified.Conflicts -gt 0 -or $verified.MissingRequiredMonths -gt 0 -or $verified.Operations.Count -gt 0) {
   throw "Tick-cache synchronization did not produce one exact union on every root."
}
Write-Plan $verified "SYNCHRONIZED" "NO_COPY_NEEDED"

[pscustomobject]@{
   Status = "SYNCHRONIZED_NOW"
   Roots = $roots.Count
   CachedMonths = $verified.CachedMonths
   RequiredMonths = $verified.RequiredMonths
   FilesCopied = $copied
   BytesCopied = $copyBytes
   MQL5Launched = $false
}
