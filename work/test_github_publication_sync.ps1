$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tempRoot = Join-Path $repo ("work\github_publication_sync_test_{0}" -f $PID)

function Assert-True {
   param([bool]$Condition, [string]$Message)
   if(!$Condition) { throw $Message }
}

function Write-FixtureFile {
   param([string]$Root, [string]$Path, [string]$Content)
   $full = Join-Path $Root $Path
   $parent = Split-Path -Parent $full
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   $Content | Set-Content -LiteralPath $full -Encoding ASCII
}

$requiredPaths = @(
   "Professional_XAUUSD_EA.mq5",
   "outputs\Professional_XAUUSD_EA.mq5",
   "outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set",
   "outputs\CANDIDATE_MONEY_READY_PROFILE.set",
   "outputs\CANDIDATE_TRADE_READINESS_PROFILE.set",
   "outputs\SOURCE_MANIFEST.md",
   "outputs\CURRENT_RESEARCH_BEST_PROFILE.md"
)

try {
   $localRoot = Join-Path $tempRoot "local"
   $remoteRoot = Join-Path $tempRoot "remote"
   New-Item -ItemType Directory -Path $localRoot -Force | Out-Null
   New-Item -ItemType Directory -Path $remoteRoot -Force | Out-Null

   foreach($path in $requiredPaths) {
      Write-FixtureFile $localRoot $path "fixture $path"
      Write-FixtureFile $remoteRoot $path "fixture $path"
   }
   foreach($path in @(
      "README.md",
      "outputs\GITHUB_STATUS_DASHBOARD.md",
      "outputs\MONEY_READY_REFRESH_STATUS.md",
      "outputs\MONEY_READY_STATUS_SCORECARD.md",
      "outputs\TRADE_READY_LIVE_READINESS_DECISION.md",
      "outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.md",
      "outputs\FIRST_PASS_PARALLEL_LANES.md",
      "outputs\MONEY_READY_EVIDENCE_HANDOFF.md"
   )) {
      Write-FixtureFile $localRoot $path "optional $path"
      Write-FixtureFile $remoteRoot $path "optional $path"
   }

   $outCsv = Join-Path $tempRoot "publication.csv"
   $outMd = Join-Path $tempRoot "publication.md"
   $connectorCsv = Join-Path $tempRoot "connector_verification.csv"

   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\audit_github_publication_sync.ps1") `
      -LocalRoot $localRoot `
      -RemoteRoot $remoteRoot `
      -ConnectorVerificationPath $connectorCsv `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null
   $passRows = @(Import-Csv -LiteralPath $outCsv)
   Assert-True (@($passRows | Where-Object { $_.Required -eq "True" -and $_.Status -ne "PASS" }).Count -eq 0) "All required rows should pass when local and remote match"
   Assert-True ((Get-Content -LiteralPath $outMd -Raw).Contains("Overall: **PASS**")) "Markdown should show PASS"

   Write-FixtureFile $remoteRoot "outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set" "stale remote profile"
   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\audit_github_publication_sync.ps1") `
      -LocalRoot $localRoot `
      -RemoteRoot $remoteRoot `
      -ConnectorVerificationPath $connectorCsv `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null
   $mismatchRows = @(Import-Csv -LiteralPath $outCsv)
   Assert-True (@($mismatchRows | Where-Object { $_.Role -eq "trade-ready-conservative-profile" -and $_.Status -eq "PENDING" -and $_.Detail -eq "MISMATCH" }).Count -eq 1) "Stale remote profile should be pending mismatch"
   Assert-True ((Get-Content -LiteralPath $outMd -Raw).Contains("Overall: **PENDING**")) "Markdown should show PENDING for mismatch"

   $git = "C:\Program Files\Git\cmd\git.exe"
   $connectorRows = foreach($path in $requiredPaths) {
      $full = Join-Path $localRoot $path
      [pscustomobject]@{
         Role = ""
         RemotePath = ($path -replace '\\', '/')
         RemoteExists = "True"
         RemoteGitBlobSha = (& $git hash-object --no-filters -- $full)
      }
   }
   $connectorRows | Export-Csv -LiteralPath $connectorCsv -NoTypeInformation -Encoding ASCII
   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\audit_github_publication_sync.ps1") `
      -LocalRoot $localRoot `
      -RemoteRoot $remoteRoot `
      -ConnectorVerificationPath $connectorCsv `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null
   $connectorPassRows = @(Import-Csv -LiteralPath $outCsv)
   Assert-True (@($connectorPassRows | Where-Object { $_.Required -eq "True" -and $_.Status -ne "PASS" }).Count -eq 0) "Connector blob matches should pass required rows even when raw remote fixture is stale"
   Assert-True (@($connectorPassRows | Where-Object { $_.Role -eq "trade-ready-conservative-profile" -and $_.Detail -eq "CONNECTOR_BLOB_MATCH" }).Count -eq 1) "Connector match detail should be visible"

   $connectorRowsText = foreach($path in $requiredPaths) {
      $full = Join-Path $localRoot $path
      $blob = if($path -eq "outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set") {
         $filterPath = $path -replace '\\', '/'
         & $git hash-object "--path=$filterPath" -- $full
      } else {
         & $git hash-object --no-filters -- $full
      }
      [pscustomobject]@{
         Role = ""
         RemotePath = ($path -replace '\\', '/')
         RemoteExists = "True"
         RemoteGitBlobSha = $blob
      }
   }
   $connectorRowsText | Export-Csv -LiteralPath $connectorCsv -NoTypeInformation -Encoding ASCII
   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\audit_github_publication_sync.ps1") `
      -LocalRoot $localRoot `
      -RemoteRoot $remoteRoot `
      -ConnectorVerificationPath $connectorCsv `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null
   $connectorTextRows = @(Import-Csv -LiteralPath $outCsv)
   Assert-True (@($connectorTextRows | Where-Object { $_.Required -eq "True" -and $_.Status -ne "PASS" }).Count -eq 0) "Connector text-normalized blob matches should pass required rows"
   Assert-True (@($connectorTextRows | Where-Object { $_.Role -eq "trade-ready-conservative-profile" -and $_.Detail -eq "CONNECTOR_TEXT_BLOB_MATCH" }).Count -eq 1) "Connector text-normalized match detail should be visible"

   Remove-Item -LiteralPath (Join-Path $localRoot "outputs\CANDIDATE_MONEY_READY_PROFILE.set") -Force
   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\audit_github_publication_sync.ps1") `
      -LocalRoot $localRoot `
      -RemoteRoot $remoteRoot `
      -ConnectorVerificationPath $connectorCsv `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null
   $missingLocalRows = @(Import-Csv -LiteralPath $outCsv)
   Assert-True (@($missingLocalRows | Where-Object { $_.Role -eq "money-ready-profile" -and $_.Status -eq "FAIL" -and $_.Detail -eq "LOCAL_MISSING" }).Count -eq 1) "Missing local required file should fail"
   Assert-True ((Get-Content -LiteralPath $outMd -Raw).Contains("Overall: **FAIL**")) "Markdown should show FAIL for missing local required artifact"

   "GITHUB_PUBLICATION_SYNC_SMOKE_PASS"
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
