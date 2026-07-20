param(
   [string]$BuilderPath = "work\build_external_mt5_validation_package.ps1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if(!(Test-Path -LiteralPath $BuilderPath)) {
   throw "External package builder missing: $BuilderPath"
}

$source = Get-Content -LiteralPath $BuilderPath -Raw
$requiredPatterns = @(
   '\$sourceHash = \(Get-FileHash -LiteralPath \$EaSourcePath -Algorithm SHA256\)\.Hash',
   '\$importedSourceHashStatus = Get-RowValue \$compileRow "SourceHashStatus"',
   '\$compileExpectedSourceHash = Get-RowValue \$compileRow "ExpectedSourceHash"',
   'if\(\$compileExpectedSourceHash -eq \$sourceHash\) \{ "MATCH" \} else \{ "MISMATCH" \}',
   'if\(\$compileTrustStatus -eq "FRESH_PASS" -and \$compileSourceHashStatus -eq "MISMATCH"\)',
   'if\(\$compileTrustStatus -eq "FRESH_PASS" -and \$importedSourceHashStatus -ne "MATCH"\)',
   'Area = "Source hash"',
   'Evidence = \$sourceHash',
   'ExpectedValue = \$sourceHash',
   'ReturnAs = "MT5_COMPILE_STATUS\.csv SourceHashStatus=MATCH"'
)

foreach($pattern in $requiredPatterns) {
   if($source -notmatch $pattern) {
      throw "Missing expected source-hash trust pattern: $pattern"
   }
}

$hashIndex = $source.IndexOf('$sourceHash = (Get-FileHash')
$trustIndex = $source.IndexOf('$compileTrustStatus = "STALE"')
$mismatchIndex = $source.IndexOf('$compileSourceHashStatus -eq "MISMATCH"')
$importedMatchIndex = $source.IndexOf('$importedSourceHashStatus -ne "MATCH"')
$statusWriteIndex = $source.IndexOf('$packageStatus | Export-Csv')
if($hashIndex -lt 0 -or $trustIndex -lt 0 -or $mismatchIndex -lt 0 -or
   $importedMatchIndex -lt 0 -or $statusWriteIndex -lt 0) {
   throw "Could not locate source-hash trust ordering."
}
if(!($hashIndex -lt $trustIndex -and $trustIndex -lt $mismatchIndex -and
   $mismatchIndex -lt $importedMatchIndex -and $importedMatchIndex -lt $statusWriteIndex)) {
   throw "Source-hash mismatch checks must run before package status is written."
}

"SOURCE_HASH_STATUS_SMOKE_PASS"
