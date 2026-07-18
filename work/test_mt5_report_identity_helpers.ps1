Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "mt5_report_identity_helpers.ps1")

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("mt5_report_identity_test_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
   $reportName = "identity_bound_report"
   $report = Join-Path $tempRoot ($reportName + ".htm")
   $identity = Join-Path $tempRoot ($reportName + ".identity.json")
   $configHash = "A" * 64
   $sourceHash = "B" * 64
   $binaryHash = "C" * 64
   Set-Content -LiteralPath $report -Encoding ASCII -Value ("<html>source=" + $sourceHash + "</html>")

   $written = Write-MT5ReportIdentityEvidence -ReportPath $report -IdentityPath $identity `
      -ExpectedReportName $reportName -ConfigSha256 $configHash `
      -SourceSha256 $sourceHash -PortableBinarySha256 $binaryHash
   if(!$written -or $written.PortableBinarySha256 -ne $binaryHash -or
      $written.ReportSha256 -ne (Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash) {
      throw "Fresh report identity did not round-trip."
   }

   $read = Read-MT5ReportIdentityEvidence -ReportPath $report -IdentityPath $identity `
      -ExpectedReportName $reportName -ConfigSha256 $configHash -SourceSha256 $sourceHash
   if(!$read -or $read.ReportBytes -ne (Get-Item -LiteralPath $report).Length) {
      throw "Valid report identity was not reusable."
   }

   Add-Content -LiteralPath $report -Encoding ASCII -Value "tampered"
   $tamperedReportRejected = !(Read-MT5ReportIdentityEvidence -ReportPath $report -IdentityPath $identity `
      -ExpectedReportName $reportName -ConfigSha256 $configHash -SourceSha256 $sourceHash)
   if(!$tamperedReportRejected) { throw "Tampered report content was accepted." }

   Set-Content -LiteralPath $report -Encoding ASCII -Value ("<html>source=" + $sourceHash + "</html>")
   Write-MT5ReportIdentityEvidence -ReportPath $report -IdentityPath $identity `
      -ExpectedReportName $reportName -ConfigSha256 $configHash `
      -SourceSha256 $sourceHash -PortableBinarySha256 $binaryHash | Out-Null
   $wrongConfigRejected = !(Read-MT5ReportIdentityEvidence -ReportPath $report -IdentityPath $identity `
      -ExpectedReportName $reportName -ConfigSha256 ("D" * 64) -SourceSha256 $sourceHash)
   $wrongSourceRejected = !(Read-MT5ReportIdentityEvidence -ReportPath $report -IdentityPath $identity `
      -ExpectedReportName $reportName -ConfigSha256 $configHash -SourceSha256 ("E" * 64))
   if(!$wrongConfigRejected -or !$wrongSourceRejected) {
      throw "Config or source identity mismatch was accepted."
   }

   Set-Content -LiteralPath $identity -Encoding ASCII -Value '{"SchemaVersion":1}'
   $incompleteSidecarRejected = !(Read-MT5ReportIdentityEvidence -ReportPath $report -IdentityPath $identity `
      -ExpectedReportName $reportName -ConfigSha256 $configHash -SourceSha256 $sourceHash)
   if(!$incompleteSidecarRejected) { throw "Incomplete identity sidecar was accepted." }

   [pscustomobject]@{
      Status = "PASS"
      ValidRoundTrip = $true
      TamperedReportRejected = $tamperedReportRejected
      WrongConfigRejected = $wrongConfigRejected
      WrongSourceRejected = $wrongSourceRejected
      IncompleteSidecarRejected = $incompleteSidecarRejected
      MQL5Launched = $false
   }
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
