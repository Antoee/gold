param(
   [string]$RepositoryFullName = "Antoee/gold",
   [string]$Branch = "main",
   [string]$LocalRoot = "",
   [string]$RemoteRoot = "",
   [string]$ConnectorVerificationPath = "outputs\GITHUB_CONNECTOR_PUBLICATION_VERIFICATION.csv",
   [string]$OutCsv = "outputs\GITHUB_PUBLICATION_SYNC.csv",
   [string]$OutMarkdown = "outputs\GITHUB_PUBLICATION_SYNC.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if([string]::IsNullOrWhiteSpace($LocalRoot)) {
   $LocalRoot = $repo
}
elseif(![IO.Path]::IsPathRooted($LocalRoot)) {
   $LocalRoot = Join-Path $repo $LocalRoot
}

function Resolve-LocalPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $LocalRoot $Path
}

function Resolve-OutPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Ensure-ParentDir {
   param([string]$Path)
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

function ConvertTo-RawPath {
   param([string]$Path)
   $parts = ([string]$Path -replace '\\', '/') -split '/'
   return (($parts | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/')
}

function Get-FileSha256 {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { return "" }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-GitBlobSha {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { return "" }
   $bytes = [IO.File]::ReadAllBytes($Path)
   $prefix = [Text.Encoding]::ASCII.GetBytes(("blob {0}`0" -f $bytes.Length))
   $combined = New-Object byte[] ($prefix.Length + $bytes.Length)
   [Array]::Copy($prefix, 0, $combined, 0, $prefix.Length)
   [Array]::Copy($bytes, 0, $combined, $prefix.Length, $bytes.Length)
   $sha = [Security.Cryptography.SHA1]::Create()
   try {
      $hashBytes = $sha.ComputeHash($combined)
      return ([BitConverter]::ToString($hashBytes)).Replace("-", "").ToLowerInvariant()
   }
   finally {
      $sha.Dispose()
   }
}

function Get-FileLength {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { return 0 }
   return (Get-Item -LiteralPath $Path).Length
}

function Read-ConnectorVerification {
   param([string]$Path)
   $resolved = Resolve-OutPath $Path
   if(!(Test-Path -LiteralPath $resolved)) { return @{} }
   $rows = @(Import-Csv -LiteralPath $resolved)
   $map = @{}
   foreach($row in $rows) {
      $key = [string]$row.RemotePath
      if([string]::IsNullOrWhiteSpace($key)) { $key = [string]$row.Role }
      if(![string]::IsNullOrWhiteSpace($key)) {
         $map[$key] = $row
      }
   }
   return $map
}

function Get-RemoteFileInfo {
   param([string]$RemotePath)

   if(![string]::IsNullOrWhiteSpace($RemoteRoot)) {
      $remoteFull = if([IO.Path]::IsPathRooted($RemoteRoot)) {
         Join-Path $RemoteRoot $RemotePath
      } else {
         Join-Path $repo (Join-Path $RemoteRoot $RemotePath)
      }
      if(!(Test-Path -LiteralPath $remoteFull)) {
         return [pscustomobject]@{
            Exists = $false
            Sha256 = ""
            Bytes = 0
            Location = $remoteFull
            Error = "missing"
         }
      }
      return [pscustomobject]@{
         Exists = $true
         Sha256 = (Get-FileHash -LiteralPath $remoteFull -Algorithm SHA256).Hash
         Bytes = (Get-Item -LiteralPath $remoteFull).Length
         Location = $remoteFull
         Error = ""
      }
   }

   $rawPath = ConvertTo-RawPath $RemotePath
   $url = "https://raw.githubusercontent.com/$RepositoryFullName/$Branch/$rawPath"
   $client = [System.Net.WebClient]::new()
   $client.Headers.Add("User-Agent", "codex-github-publication-sync-audit")
   try {
      $bytes = $client.DownloadData($url)
      $sha = [System.Security.Cryptography.SHA256]::Create()
      $hashBytes = $sha.ComputeHash($bytes)
      $hash = ([BitConverter]::ToString($hashBytes)).Replace("-", "")
      return [pscustomobject]@{
         Exists = $true
         Sha256 = $hash
         Bytes = $bytes.Length
         Location = $url
         Error = ""
      }
   }
   catch [System.Net.WebException] {
      $response = $_.Exception.Response
      $statusCode = if($null -ne $response) { [int]$response.StatusCode } else { 0 }
      $errorText = if($statusCode -eq 404) { "unavailable-or-missing" } else { $_.Exception.Message }
      return [pscustomobject]@{
         Exists = $false
         Sha256 = ""
         Bytes = 0
         Location = $url
         Error = $errorText
      }
   }
   finally {
      $client.Dispose()
   }
}

$artifacts = @(
   [pscustomobject]@{ Role = "root-ea-source"; Required = $true; LocalPath = "Professional_XAUUSD_EA.mq5"; RemotePath = "Professional_XAUUSD_EA.mq5"; Note = "Exact root EA source required for reproducible publication." },
   [pscustomobject]@{ Role = "mirrored-ea-source"; Required = $true; LocalPath = "outputs\Professional_XAUUSD_EA.mq5"; RemotePath = "outputs/Professional_XAUUSD_EA.mq5"; Note = "Mirrored output EA source required for hash identity." },
   [pscustomobject]@{ Role = "trade-ready-conservative-profile"; Required = $true; LocalPath = "outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set"; RemotePath = "outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set"; Note = "Conservative profile used by live-readiness gates." },
   [pscustomobject]@{ Role = "money-ready-profile"; Required = $true; LocalPath = "outputs\CANDIDATE_MONEY_READY_PROFILE.set"; RemotePath = "outputs/CANDIDATE_MONEY_READY_PROFILE.set"; Note = "Money-ready demo/forward-test candidate profile." },
   [pscustomobject]@{ Role = "trade-readiness-alias-profile"; Required = $true; LocalPath = "outputs\CANDIDATE_TRADE_READINESS_PROFILE.set"; RemotePath = "outputs/CANDIDATE_TRADE_READINESS_PROFILE.set"; Note = "Alias profile expected to match money-ready profile." },
   [pscustomobject]@{ Role = "source-manifest"; Required = $true; LocalPath = "outputs\SOURCE_MANIFEST.md"; RemotePath = "outputs/SOURCE_MANIFEST.md"; Note = "Source hash/status manifest." },
   [pscustomobject]@{ Role = "current-research-best"; Required = $true; LocalPath = "outputs\CURRENT_RESEARCH_BEST_PROFILE.md"; RemotePath = "outputs/CURRENT_RESEARCH_BEST_PROFILE.md"; Note = "Current promoted research profile status." },
   [pscustomobject]@{ Role = "readme-dashboard"; Required = $false; LocalPath = "README.md"; RemotePath = "README.md"; Note = "Human-facing repository dashboard." },
   [pscustomobject]@{ Role = "github-status-dashboard"; Required = $false; LocalPath = "outputs\GITHUB_STATUS_DASHBOARD.md"; RemotePath = "outputs/GITHUB_STATUS_DASHBOARD.md"; Note = "Compact GitHub-facing status board." },
   [pscustomobject]@{ Role = "money-ready-refresh"; Required = $false; LocalPath = "outputs\MONEY_READY_REFRESH_STATUS.md"; RemotePath = "outputs/MONEY_READY_REFRESH_STATUS.md"; Note = "Latest one-command refresh status." },
   [pscustomobject]@{ Role = "money-ready-scorecard"; Required = $false; LocalPath = "outputs\MONEY_READY_STATUS_SCORECARD.md"; RemotePath = "outputs/MONEY_READY_STATUS_SCORECARD.md"; Note = "Money-ready scorecard." },
   [pscustomobject]@{ Role = "live-readiness-decision"; Required = $false; LocalPath = "outputs\TRADE_READY_LIVE_READINESS_DECISION.md"; RemotePath = "outputs/TRADE_READY_LIVE_READINESS_DECISION.md"; Note = "Final conservative live-readiness gate." },
   [pscustomobject]@{ Role = "release-candidate-decision"; Required = $false; LocalPath = "outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.md"; RemotePath = "outputs/TRADE_READY_RELEASE_CANDIDATE_DECISION.md"; Note = "Release-candidate gate." },
   [pscustomobject]@{ Role = "first-pass-parallel-lanes"; Required = $false; LocalPath = "outputs\FIRST_PASS_PARALLEL_LANES.md"; RemotePath = "outputs/FIRST_PASS_PARALLEL_LANES.md"; Note = "Fast first-pass lane split." },
   [pscustomobject]@{ Role = "evidence-handoff"; Required = $false; LocalPath = "outputs\MONEY_READY_EVIDENCE_HANDOFF.md"; RemotePath = "outputs/MONEY_READY_EVIDENCE_HANDOFF.md"; Note = "Evidence handoff summary." }
)

$connectorVerification = Read-ConnectorVerification $ConnectorVerificationPath

$rows = foreach($artifact in $artifacts) {
   $localFull = Resolve-LocalPath $artifact.LocalPath
   $localExists = Test-Path -LiteralPath $localFull
   $localHash = Get-FileSha256 $localFull
   $localGitBlobSha = Get-GitBlobSha $localFull
   $localBytes = Get-FileLength $localFull
   $remote = Get-RemoteFileInfo $artifact.RemotePath
   $connector = $null
   if($connectorVerification.ContainsKey($artifact.RemotePath)) {
      $connector = $connectorVerification[$artifact.RemotePath]
   } elseif($connectorVerification.ContainsKey($artifact.Role)) {
      $connector = $connectorVerification[$artifact.Role]
   }
   $connectorExists = if($null -eq $connector) { "" } else { [string]$connector.RemoteExists }
   $connectorBlob = if($null -eq $connector) { "" } else { ([string]$connector.RemoteGitBlobSha).ToLowerInvariant() }
   $connectorStatus = if($localExists -and $connectorExists -eq "True" -and $connectorBlob -eq $localGitBlobSha) {
      "MATCH"
   } elseif($null -ne $connector -and $connectorExists -eq "True" -and ![string]::IsNullOrWhiteSpace($connectorBlob)) {
      "MISMATCH"
   } elseif($null -ne $connector -and $connectorExists -eq "False") {
      "MISSING"
   } else {
      ""
   }

   $status = if(!$localExists) {
      "FAIL"
   } elseif($connectorStatus -eq "MATCH") {
      "PASS"
   } elseif($connectorStatus -eq "MISMATCH" -or $connectorStatus -eq "MISSING") {
      "PENDING"
   } elseif(!$remote.Exists) {
      "PENDING"
   } elseif($localHash -eq $remote.Sha256) {
      "PASS"
   } else {
      "PENDING"
   }
   $detail = if(!$localExists) {
      "LOCAL_MISSING"
   } elseif($connectorStatus -eq "MATCH") {
      "CONNECTOR_BLOB_MATCH"
   } elseif($connectorStatus -eq "MISMATCH") {
      "CONNECTOR_BLOB_MISMATCH"
   } elseif($connectorStatus -eq "MISSING") {
      "CONNECTOR_REMOTE_MISSING"
   } elseif(!$remote.Exists -and $remote.Error -eq "unavailable-or-missing") {
      "REMOTE_UNAVAILABLE_OR_MISSING"
   } elseif(!$remote.Exists) {
      "REMOTE_MISSING"
   } elseif($localHash -eq $remote.Sha256) {
      "MATCH"
   } else {
      "MISMATCH"
   }
   if([string]$artifact.Required -ne "True" -and $status -eq "PENDING" -and [string]::IsNullOrWhiteSpace($connectorStatus) -and !$remote.Exists) {
      $status = "INFO"
      $detail = "OPTIONAL_NOT_VERIFIED"
   }

   [pscustomobject]@{
      Role = $artifact.Role
      Required = [string]$artifact.Required
      Status = $status
      Detail = $detail
      LocalPath = $artifact.LocalPath
      RemotePath = $artifact.RemotePath
      LocalSha256 = $localHash
      LocalGitBlobSha = $localGitBlobSha
      RemoteSha256 = $remote.Sha256
      RemoteGitBlobSha = $connectorBlob
      LocalBytes = $localBytes
      RemoteBytes = $remote.Bytes
      RemoteLocation = $remote.Location
      RemoteError = $remote.Error
      ConnectorVerification = $ConnectorVerificationPath
      Note = $artifact.Note
   }
}

$requiredRows = @($rows | Where-Object { [string]$_.Required -eq "True" })
$requiredPass = @($requiredRows | Where-Object Status -eq "PASS").Count
$requiredPending = @($requiredRows | Where-Object Status -eq "PENDING").Count
$requiredFail = @($requiredRows | Where-Object Status -eq "FAIL").Count
$overall = if($requiredFail -gt 0) { "FAIL" } elseif($requiredPending -gt 0) { "PENDING" } else { "PASS" }

$outCsvFull = Resolve-OutPath $OutCsv
$outMarkdownFull = Resolve-OutPath $OutMarkdown
Ensure-ParentDir $outCsvFull
Ensure-ParentDir $outMarkdownFull
$rows | Export-Csv -LiteralPath $outCsvFull -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# GitHub Publication Sync")
$md.Add("")
$md.Add("Generated offline without launching MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.")
$md.Add("")
$md.Add(("- Overall: **{0}**" -f $overall))
$md.Add(('- Repository: `{0}`' -f $RepositoryFullName))
$md.Add(('- Branch: `{0}`' -f $Branch))
$md.Add(('- Required passing: `{0}`' -f $requiredPass))
$md.Add(('- Required pending: `{0}`' -f $requiredPending))
$md.Add(('- Required failed: `{0}`' -f $requiredFail))
$md.Add("")
if($overall -eq "PASS") {
   $md.Add("Required source/profile/status artifacts match GitHub by SHA-256.")
} elseif($overall -eq "FAIL") {
   $md.Add("At least one required local artifact is missing. Fix local artifacts before publishing.")
} else {
   $md.Add("At least one required artifact is missing, stale, or inaccessible through the raw-file audit. The live-readiness GitHub sync gate must remain pending.")
}
$md.Add("")
$md.Add("## Artifacts")
$md.Add("")
$md.Add("| Role | Required | Status | Detail | Local SHA-256 | Local Git Blob | Remote Git Blob | Note |")
$md.Add("| --- | --- | --- | --- | --- | --- | --- | --- |")
foreach($row in $rows) {
   $localShort = if([string]::IsNullOrWhiteSpace($row.LocalSha256)) { "" } else { $row.LocalSha256.Substring(0, [Math]::Min(12, $row.LocalSha256.Length)) }
   $localBlobShort = if([string]::IsNullOrWhiteSpace($row.LocalGitBlobSha)) { "" } else { $row.LocalGitBlobSha.Substring(0, [Math]::Min(12, $row.LocalGitBlobSha.Length)) }
   $remoteBlobShort = if([string]::IsNullOrWhiteSpace($row.RemoteGitBlobSha)) { "" } else { $row.RemoteGitBlobSha.Substring(0, [Math]::Min(12, $row.RemoteGitBlobSha.Length)) }
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |" -f
      (Escape-MarkdownCell $row.Role),
      (Escape-MarkdownCell $row.Required),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.Detail),
      (Escape-MarkdownCell $localShort),
      (Escape-MarkdownCell $localBlobShort),
      (Escape-MarkdownCell $remoteBlobShort),
      (Escape-MarkdownCell $row.Note)))
}
$md | Set-Content -LiteralPath $outMarkdownFull -Encoding ASCII

[pscustomobject]@{
   Overall = $overall
   RequiredPass = $requiredPass
   RequiredPending = $requiredPending
   RequiredFail = $requiredFail
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
