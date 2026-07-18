function Test-MT5Sha256Text {
   param([AllowNull()][string]$Value)
   return ![string]::IsNullOrWhiteSpace($Value) -and $Value -match '^[A-Fa-f0-9]{64}$'
}

function Get-MT5FileSha256 {
   param([Parameter(Mandatory=$true)][string]$Path)
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Read-MT5ReportIdentityEvidence {
   param(
      [Parameter(Mandatory=$true)][string]$ReportPath,
      [Parameter(Mandatory=$true)][string]$IdentityPath,
      [Parameter(Mandatory=$true)][string]$ExpectedReportName,
      [Parameter(Mandatory=$true)][string]$ConfigSha256,
      [Parameter(Mandatory=$true)][string]$SourceSha256
   )

   if(!(Test-Path -LiteralPath $ReportPath -PathType Leaf) -or
      !(Test-Path -LiteralPath $IdentityPath -PathType Leaf) -or
      !(Test-MT5Sha256Text $ConfigSha256) -or
      !(Test-MT5Sha256Text $SourceSha256)) {
      return $null
   }

   try {
      $identity = Get-Content -LiteralPath $IdentityPath -Raw | ConvertFrom-Json
      $required = @(
         'SchemaVersion','ExpectedReportName','ConfigSha256','SourceSha256',
         'PortableBinarySha256','ReportSha256','ReportBytes','CreatedUtc'
      )
      foreach($name in $required) {
         if($identity.PSObject.Properties.Name -notcontains $name) { return $null }
      }

      $configHash = $ConfigSha256.ToUpperInvariant()
      $sourceHash = $SourceSha256.ToUpperInvariant()
      $binaryHash = ([string]$identity.PortableBinarySha256).ToUpperInvariant()
      $reportHash = Get-MT5FileSha256 $ReportPath
      $report = Get-Item -LiteralPath $ReportPath
      if([int]$identity.SchemaVersion -ne 1 -or
         [string]$identity.ExpectedReportName -ne $ExpectedReportName -or
         [IO.Path]::GetFileNameWithoutExtension($report.Name) -ne $ExpectedReportName -or
         ([string]$identity.ConfigSha256).ToUpperInvariant() -ne $configHash -or
         ([string]$identity.SourceSha256).ToUpperInvariant() -ne $sourceHash -or
         !(Test-MT5Sha256Text $binaryHash) -or
         !(Test-MT5Sha256Text ([string]$identity.ReportSha256)) -or
         ([string]$identity.ReportSha256).ToUpperInvariant() -ne $reportHash -or
         [long]$identity.ReportBytes -ne $report.Length -or
         $report.Length -le 0) {
         return $null
      }

      $createdUtc = [datetime]::MinValue
      if(![datetime]::TryParse([string]$identity.CreatedUtc,
                               [Globalization.CultureInfo]::InvariantCulture,
                               [Globalization.DateTimeStyles]::RoundtripKind,
                               [ref]$createdUtc)) {
         return $null
      }
      $reportText = Get-Content -LiteralPath $ReportPath -Raw
      if($reportText.IndexOf($sourceHash, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
         return $null
      }

      return [pscustomobject]@{
         SchemaVersion = 1
         ExpectedReportName = $ExpectedReportName
         ConfigSha256 = $configHash
         SourceSha256 = $sourceHash
         PortableBinarySha256 = $binaryHash
         ReportSha256 = $reportHash
         ReportBytes = $report.Length
         CreatedUtc = $createdUtc.ToUniversalTime().ToString('o')
      }
   }
   catch {
      return $null
   }
}

function Write-MT5ReportIdentityEvidence {
   param(
      [Parameter(Mandatory=$true)][string]$ReportPath,
      [Parameter(Mandatory=$true)][string]$IdentityPath,
      [Parameter(Mandatory=$true)][string]$ExpectedReportName,
      [Parameter(Mandatory=$true)][string]$ConfigSha256,
      [Parameter(Mandatory=$true)][string]$SourceSha256,
      [Parameter(Mandatory=$true)][string]$PortableBinarySha256
   )

   if(!(Test-Path -LiteralPath $ReportPath -PathType Leaf)) { throw "Report is missing: $ReportPath" }
   foreach($hash in @($ConfigSha256,$SourceSha256,$PortableBinarySha256)) {
      if(!(Test-MT5Sha256Text $hash)) { throw "Identity evidence contains an invalid SHA-256 value." }
   }
   $report = Get-Item -LiteralPath $ReportPath
   if($report.Length -le 0 -or [IO.Path]::GetFileNameWithoutExtension($report.Name) -ne $ExpectedReportName) {
      throw "Report name or size does not match identity evidence."
   }
   $sourceHash = $SourceSha256.ToUpperInvariant()
   if((Get-Content -LiteralPath $ReportPath -Raw).IndexOf($sourceHash, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "Report does not embed the expected source identity."
   }

   $parent = Split-Path -Parent $IdentityPath
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   $identity = [ordered]@{
      SchemaVersion = 1
      ExpectedReportName = $ExpectedReportName
      ConfigSha256 = $ConfigSha256.ToUpperInvariant()
      SourceSha256 = $sourceHash
      PortableBinarySha256 = $PortableBinarySha256.ToUpperInvariant()
      ReportSha256 = Get-MT5FileSha256 $ReportPath
      ReportBytes = $report.Length
      CreatedUtc = [datetime]::UtcNow.ToString('o')
   }
   $temporary = $IdentityPath + '.tmp.' + [guid]::NewGuid().ToString('N')
   try {
      $identity | ConvertTo-Json | Set-Content -LiteralPath $temporary -Encoding ASCII
      Move-Item -LiteralPath $temporary -Destination $IdentityPath -Force
   }
   finally {
      Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
   }
   return Read-MT5ReportIdentityEvidence -ReportPath $ReportPath -IdentityPath $IdentityPath `
      -ExpectedReportName $ExpectedReportName -ConfigSha256 $ConfigSha256 -SourceSha256 $SourceSha256
}
