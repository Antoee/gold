Set-StrictMode -Version Latest

function Get-MT5TickCacheUnionPlan {
   param(
      [Parameter(Mandatory=$true)][object[]]$Inventory,
      [Parameter(Mandatory=$true)][string[]]$AllowedRoots,
      [string[]]$RequiredMonths = @()
   )

   $rootNames = @($AllowedRoots | ForEach-Object { Split-Path -Leaf $_ })
   $rows = [System.Collections.Generic.List[object]]::new()
   $operations = [System.Collections.Generic.List[object]]::new()
   foreach($group in @($Inventory | Group-Object FileName | Sort-Object Name)) {
      if(@($group.Group | Where-Object Mutable).Count -gt 0) {
         $presentNames = @($group.Group | Select-Object -ExpandProperty RootName | Sort-Object -Unique)
         $rows.Add([pscustomobject]@{
            Month = [IO.Path]::GetFileNameWithoutExtension($group.Name)
            FileName = $group.Name
            Bytes = 0
            Sha256 = "SKIPPED_PARTIAL_CUTOFF"
            PresentRoots = $presentNames.Count
            MissingRoots = @($rootNames | Where-Object { $_ -notin $presentNames }).Count
            CopyOperations = 0
            State = "SKIPPED_PARTIAL_CUTOFF"
         }) | Out-Null
         continue
      }
      $hashes = @($group.Group | Select-Object -ExpandProperty Sha256 | Sort-Object -Unique)
      $presentNames = @($group.Group | Select-Object -ExpandProperty RootName | Sort-Object -Unique)
      $missingNames = @($rootNames | Where-Object { $_ -notin $presentNames })
      if($hashes.Count -ne 1) {
         $rows.Add([pscustomobject]@{
            Month = [IO.Path]::GetFileNameWithoutExtension($group.Name)
            FileName = $group.Name
            Bytes = 0
            Sha256 = "CONFLICT"
            PresentRoots = $presentNames.Count
            MissingRoots = $missingNames.Count
            CopyOperations = 0
            State = "HASH_CONFLICT"
         }) | Out-Null
         continue
      }
      $source = @($group.Group | Sort-Object RootName | Select-Object -First 1)[0]
      foreach($missingName in $missingNames) {
         $targetRoot = @($AllowedRoots | Where-Object { (Split-Path -Leaf $_) -eq $missingName })[0]
         $operations.Add([pscustomobject]@{
            FileName = $group.Name
            Source = $source.FullName
            Target = Join-Path $targetRoot ("bases\MetaQuotes-Demo\ticks\XAUUSD\" + $group.Name)
            Bytes = $source.Bytes
            Sha256 = $source.Sha256
         }) | Out-Null
      }
      $rows.Add([pscustomobject]@{
         Month = [IO.Path]::GetFileNameWithoutExtension($group.Name)
         FileName = $group.Name
         Bytes = $source.Bytes
         Sha256 = $source.Sha256
         PresentRoots = $presentNames.Count
         MissingRoots = $missingNames.Count
         CopyOperations = $missingNames.Count
         State = if($missingNames.Count -eq 0) { "SYNCHRONIZED" } else { "COPY_REQUIRED" }
      }) | Out-Null
   }
   $cachedFileNames = @($Inventory | Select-Object -ExpandProperty FileName | Sort-Object -Unique)
   foreach($month in @($RequiredMonths | Sort-Object -Unique)) {
      $fileName = $month + ".tkc"
      if($fileName -in $cachedFileNames) { continue }
      $rows.Add([pscustomobject]@{
         Month = $month
         FileName = $fileName
         Bytes = 0
         Sha256 = "MISSING"
         PresentRoots = 0
         MissingRoots = $rootNames.Count
         CopyOperations = 0
         State = "MISSING_ALL_ROOTS"
      }) | Out-Null
   }
   return [pscustomobject]@{
      Rows = @($rows | Sort-Object FileName)
      Operations = @($operations)
      InventoryFiles = $Inventory.Count
      HashedFiles = @($Inventory | Where-Object { !$_.Mutable }).Count
      CachedMonths = $cachedFileNames.Count
      RequiredMonths = @($RequiredMonths | Sort-Object -Unique).Count
      MissingRequiredMonths = @($rows | Where-Object State -eq "MISSING_ALL_ROOTS").Count
      Conflicts = @($rows | Where-Object State -eq "HASH_CONFLICT").Count
   }
}

function Install-MT5VerifiedMissingTickFile {
   param(
      [Parameter(Mandatory=$true)][string]$Source,
      [Parameter(Mandatory=$true)][string]$Target,
      [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedSha256,
      [scriptblock]$BeforeCommit = {}
   )

   $expectedHash = $ExpectedSha256.ToUpperInvariant()
   if(!(Test-Path -LiteralPath $Source -PathType Leaf)) {
      throw "Tick-cache source disappeared before copy."
   }
   if(Test-Path -LiteralPath $Target) {
      throw "A tick-cache target appeared after planning; refusing overwrite."
   }
   $parent = Split-Path -Parent $Target
   if(!(Test-Path -LiteralPath $parent -PathType Container)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   $temporary = $Target + ".sync.tmp." + [guid]::NewGuid().ToString("N")
   try {
      Copy-Item -LiteralPath $Source -Destination $temporary
      if((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedHash) {
         throw "Temporary tick-cache copy failed SHA-256 verification."
      }
      & $BeforeCommit
      Move-Item -LiteralPath $temporary -Destination $Target
      if((Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedHash) {
         throw "Installed tick-cache copy failed SHA-256 verification."
      }
   }
   finally {
      Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
   }
}
