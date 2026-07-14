param(
   [string]$RepositoryFullName = "Antoee/gold",
   [string]$Branch = "main",
   [string]$Token = "",
   [string]$TokenFile = "",
   [switch]$ConfirmUpload,
   [switch]$PlanOnly,
   [string]$PublicationSyncCsv = "outputs\GITHUB_PUBLICATION_SYNC.csv",
   [string]$OutCsv = "outputs\GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.csv",
   [string]$OutMarkdown = "outputs\GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
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

function ConvertTo-ApiPath {
   param([string]$Path)
   $parts = ([string]$Path -replace '\\', '/') -split '/'
   return (($parts | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/')
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
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

function Get-Token {
   if(![string]::IsNullOrWhiteSpace($Token)) { return $Token.Trim() }
   if(![string]::IsNullOrWhiteSpace($TokenFile)) {
      $resolved = Resolve-RepoPath $TokenFile
      if(Test-Path -LiteralPath $resolved) {
         return ((Get-Content -Raw -LiteralPath $resolved).Trim())
      }
   }
   $envToken = [Environment]::GetEnvironmentVariable("GITHUB_TOKEN")
   if(![string]::IsNullOrWhiteSpace($envToken)) { return $envToken.Trim() }
   $envToken = [Environment]::GetEnvironmentVariable("GH_TOKEN")
   if(![string]::IsNullOrWhiteSpace($envToken)) { return $envToken.Trim() }
   return ""
}

function New-Headers {
   param([string]$ResolvedToken)
   return @{
      "Authorization" = "Bearer $ResolvedToken"
      "Accept" = "application/vnd.github+json"
      "X-GitHub-Api-Version" = "2022-11-28"
      "User-Agent" = "codex-xauusd-source-artifact-sync"
   }
}

function Get-RemoteContentInfo {
   param(
      [string]$RemotePath,
      [hashtable]$Headers
   )
   $repoParts = $RepositoryFullName.Split("/")
   if($repoParts.Count -ne 2) { throw "RepositoryFullName must be owner/repo." }
   $apiPath = ConvertTo-ApiPath $RemotePath
   $url = "https://api.github.com/repos/$($repoParts[0])/$($repoParts[1])/contents/$apiPath`?ref=$([uri]::EscapeDataString($Branch))"
   try {
      $result = Invoke-RestMethod -Method Get -Uri $url -Headers $Headers
      return [pscustomobject]@{
         Exists = $true
         BlobSha = [string]$result.sha
         Size = [int64]$result.size
         Error = ""
      }
   }
   catch {
      $status = 0
      if($null -ne $_.Exception.Response) {
         $status = [int]$_.Exception.Response.StatusCode
      }
      if($status -eq 404) {
         return [pscustomobject]@{
            Exists = $false
            BlobSha = ""
            Size = 0
            Error = "remote-missing"
         }
      }
      throw
   }
}

function Get-RemoteContentInfoFromPublicationSync {
   param([object]$Artifact)

   $syncFull = Resolve-RepoPath $PublicationSyncCsv
   if(!(Test-Path -LiteralPath $syncFull)) {
      return [pscustomobject]@{
         Exists = $false
         BlobSha = ""
         Size = 0
         Error = "not-checked-no-token"
      }
   }

   $syncRows = @(Import-Csv -LiteralPath $syncFull)
   $row = $syncRows | Where-Object {
      [string]$_.Role -eq [string]$Artifact.Role -or
      [string]$_.RemotePath -eq [string]$Artifact.RemotePath -or
      [string]$_.LocalPath -eq [string]$Artifact.LocalPath
   } | Select-Object -First 1

   if($null -eq $row) {
      return [pscustomobject]@{
         Exists = $false
         BlobSha = ""
         Size = 0
         Error = "not-checked-no-token"
      }
   }

   $remoteBlob = ([string]$row.RemoteGitBlobSha).ToLowerInvariant()
   $detail = [string]$row.Detail
   $exists = ![string]::IsNullOrWhiteSpace($remoteBlob) -and $detail -ne "CONNECTOR_REMOTE_MISSING"
   return [pscustomobject]@{
      Exists = $exists
      BlobSha = $remoteBlob
      Size = if([string]::IsNullOrWhiteSpace([string]$row.RemoteBytes)) { 0 } else { [int64]$row.RemoteBytes }
      Error = if($exists) { "from-publication-sync" } else { "remote-missing-from-publication-sync" }
   }
}

function Set-RemoteContent {
   param(
      [string]$RemotePath,
      [string]$LocalPath,
      [string]$RemoteBlobSha,
      [hashtable]$Headers,
      [string]$Message
   )
   $repoParts = $RepositoryFullName.Split("/")
   $apiPath = ConvertTo-ApiPath $RemotePath
   $url = "https://api.github.com/repos/$($repoParts[0])/$($repoParts[1])/contents/$apiPath"
   $bytes = [IO.File]::ReadAllBytes($LocalPath)
   $body = @{
      message = $Message
      content = [Convert]::ToBase64String($bytes)
      branch = $Branch
   }
   if(![string]::IsNullOrWhiteSpace($RemoteBlobSha)) {
      $body.sha = $RemoteBlobSha
   }
   $json = $body | ConvertTo-Json -Depth 5
   $result = Invoke-RestMethod -Method Put -Uri $url -Headers $Headers -Body $json -ContentType "application/json"
   return [pscustomobject]@{
      CommitSha = [string]$result.commit.sha
      ContentSha = [string]$result.content.sha
   }
}

function ConvertTo-Bool {
   param([object]$Value)
   $text = ([string]$Value).Trim()
   return ($text -eq "True" -or $text -eq "true" -or $text -eq "1")
}

function Get-DefaultPublicationArtifacts {
   return @(
      [pscustomobject]@{ Role = "root-ea-source"; Required = $true; LocalPath = "Professional_XAUUSD_EA.mq5"; RemotePath = "Professional_XAUUSD_EA.mq5"; Note = "Exact root EA source required for reproducible publication." },
      [pscustomobject]@{ Role = "mirrored-ea-source"; Required = $true; LocalPath = "outputs\Professional_XAUUSD_EA.mq5"; RemotePath = "outputs/Professional_XAUUSD_EA.mq5"; Note = "Mirrored output EA source required for hash identity." },
      [pscustomobject]@{ Role = "trade-ready-conservative-profile"; Required = $true; LocalPath = "outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set"; RemotePath = "outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set"; Note = "Conservative profile used by live-readiness gates." },
      [pscustomobject]@{ Role = "money-ready-profile"; Required = $true; LocalPath = "outputs\CANDIDATE_MONEY_READY_PROFILE.set"; RemotePath = "outputs/CANDIDATE_MONEY_READY_PROFILE.set"; Note = "Money-ready demo/forward-test candidate profile." },
      [pscustomobject]@{ Role = "trade-readiness-alias-profile"; Required = $true; LocalPath = "outputs\CANDIDATE_TRADE_READINESS_PROFILE.set"; RemotePath = "outputs/CANDIDATE_TRADE_READINESS_PROFILE.set"; Note = "Alias profile expected to match money-ready profile." },
      [pscustomobject]@{ Role = "source-manifest"; Required = $true; LocalPath = "outputs\SOURCE_MANIFEST.md"; RemotePath = "outputs/SOURCE_MANIFEST.md"; Note = "Source hash/status manifest." },
      [pscustomobject]@{ Role = "current-research-best"; Required = $true; LocalPath = "outputs\CURRENT_RESEARCH_BEST_PROFILE.md"; RemotePath = "outputs/CURRENT_RESEARCH_BEST_PROFILE.md"; Note = "Current promoted research profile status." }
   )
}

function Get-RequiredPublicationArtifacts {
   $syncFull = Resolve-RepoPath $PublicationSyncCsv
   if(Test-Path -LiteralPath $syncFull) {
      $syncRows = @(Import-Csv -LiteralPath $syncFull)
      $requiredRows = @($syncRows | Where-Object { ConvertTo-Bool $_.Required })
      if($requiredRows.Count -gt 0) {
         return @($requiredRows | ForEach-Object {
            [pscustomobject]@{
               Role = [string]$_.Role
               Required = $true
               LocalPath = [string]$_.LocalPath
               RemotePath = [string]$_.RemotePath
               Note = [string]$_.Note
            }
         })
      }
   }
   return Get-DefaultPublicationArtifacts
}

$artifacts = @(Get-RequiredPublicationArtifacts)

$resolvedToken = Get-Token
$hasToken = ![string]::IsNullOrWhiteSpace($resolvedToken)
if(!$PlanOnly -and !$ConfirmUpload) {
   throw "Refusing to upload without -ConfirmUpload. Use -PlanOnly to write a non-mutating plan."
}
if(!$PlanOnly -and !$hasToken) {
   throw "No GitHub token found. Set GITHUB_TOKEN or GH_TOKEN, pass -Token, or use -TokenFile."
}

$headers = if($hasToken) { New-Headers $resolvedToken } else { @{} }

$localSourceHashes = @()
foreach($artifact in @($artifacts | Where-Object { [string]$_.Role -like "*ea-source" })) {
   $localFull = Resolve-RepoPath $artifact.LocalPath
   if(Test-Path -LiteralPath $localFull) {
      $localSourceHashes += (Get-FileSha256 $localFull)
   }
}
$uniqueSourceHashes = @($localSourceHashes | Sort-Object -Unique)
if($uniqueSourceHashes.Count -gt 1) {
   throw "Root and mirrored EA source hashes do not match. Refusing source publication."
}

$rows = foreach($artifact in $artifacts) {
   $localFull = Resolve-RepoPath $artifact.LocalPath
   $localExists = Test-Path -LiteralPath $localFull
   $localSha = Get-FileSha256 $localFull
   $localBlob = Get-GitBlobSha $localFull
   $localBytes = if($localExists) { (Get-Item -LiteralPath $localFull).Length } else { 0 }
   $remote = if($hasToken) {
      Get-RemoteContentInfo -RemotePath $artifact.RemotePath -Headers $headers
   } else {
      Get-RemoteContentInfoFromPublicationSync -Artifact $artifact
   }

   $status = "PLAN_ONLY"
   $action = "NO_MUTATION"
   $detail = ""
   $commitSha = ""
   $contentSha = ""

   if(!$localExists) {
      $status = "FAIL"
      $action = "LOCAL_MISSING"
      $detail = "Local required artifact is missing."
   }
   elseif($remote.Exists -and ([string]$remote.BlobSha).ToLowerInvariant() -eq $localBlob) {
      $status = "PASS"
      $action = "SKIP_UP_TO_DATE"
      $detail = "Remote blob already matches local required artifact."
   }
   elseif($PlanOnly) {
      $status = "READY"
      $action = if($remote.Exists) { "WOULD_UPDATE" } else { "WOULD_CREATE" }
      $detail = if($hasToken) { "Token available; rerun with -ConfirmUpload to publish." } else { "No token available; remote state inferred from publication audit. Set GITHUB_TOKEN or GH_TOKEN, then rerun with -ConfirmUpload." }
   }
   else {
      $message = "Sync required publication artifact: $($artifact.Role)"
      $upload = Set-RemoteContent -RemotePath $artifact.RemotePath -LocalPath $localFull -RemoteBlobSha $remote.BlobSha -Headers $headers -Message $message
      $status = "UPLOADED"
      $action = if($remote.Exists) { "UPDATED" } else { "CREATED" }
      $detail = "Uploaded exact local bytes through GitHub Contents API."
      $commitSha = $upload.CommitSha
      $contentSha = $upload.ContentSha
   }

   [pscustomobject]@{
      Role = $artifact.Role
      Status = $status
      Action = $action
      LocalPath = $artifact.LocalPath
      RemotePath = $artifact.RemotePath
      LocalExists = [string]$localExists
      LocalBytes = $localBytes
      LocalSha256 = $localSha
      LocalGitBlobSha = $localBlob
      RemoteExists = [string]$remote.Exists
      RemoteBytes = $remote.Size
      RemoteGitBlobSha = ([string]$remote.BlobSha).ToLowerInvariant()
      RemoteError = $remote.Error
      CommitSha = $commitSha
      ContentSha = $contentSha
      Note = [string]$artifact.Note
      Detail = $detail
   }
}

$outCsvFull = Resolve-OutPath $OutCsv
$outMarkdownFull = Resolve-OutPath $OutMarkdown
Ensure-ParentDir $outCsvFull
Ensure-ParentDir $outMarkdownFull
$rows | Export-Csv -LiteralPath $outCsvFull -NoTypeInformation -Encoding ASCII

$fail = @($rows | Where-Object Status -eq "FAIL").Count
$uploaded = @($rows | Where-Object Status -eq "UPLOADED").Count
$ready = @($rows | Where-Object Status -eq "READY").Count
$pass = @($rows | Where-Object Status -eq "PASS").Count
$overall = if($fail -gt 0) { "FAIL" } elseif($uploaded -gt 0) { "UPLOADED" } elseif($ready -gt 0) { "READY" } else { "PASS" }

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# GitHub Required Publication Artifact Upload Plan")
$md.Add("")
$md.Add("Generated offline. This does not launch MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.")
$md.Add("")
$md.Add(("- Overall: **{0}**" -f $overall))
$md.Add(('- Repository: `{0}`' -f $RepositoryFullName))
$md.Add(('- Branch: `{0}`' -f $Branch))
$md.Add(('- Token available: `{0}`' -f $hasToken))
$md.Add(('- Confirm upload: `{0}`' -f ([bool]$ConfirmUpload)))
$md.Add(('- Plan only: `{0}`' -f ([bool]$PlanOnly)))
$md.Add(('- Required artifacts planned: `{0}`' -f $rows.Count))
$md.Add(('- Source SHA-256: `{0}`' -f ($(if($uniqueSourceHashes.Count -eq 1) { $uniqueSourceHashes[0] } else { "" }))))
$md.Add("")
$md.Add("## Artifacts")
$md.Add("")
$md.Add("| Role | Remote Path | Status | Action | Local Bytes | Local SHA-256 | Remote Blob | Detail |")
$md.Add("| --- | --- | --- | --- | ---: | --- | --- | --- |")
foreach($row in $rows) {
   $localShort = if([string]::IsNullOrWhiteSpace($row.LocalSha256)) { "" } else { $row.LocalSha256.Substring(0, [Math]::Min(12, $row.LocalSha256.Length)) }
   $remoteShort = if([string]::IsNullOrWhiteSpace($row.RemoteGitBlobSha)) { "" } else { $row.RemoteGitBlobSha.Substring(0, [Math]::Min(12, $row.RemoteGitBlobSha.Length)) }
   $md.Add(("| {0} | `{1}` | {2} | {3} | {4} | {5} | {6} | {7} |" -f
      (Escape-MarkdownCell $row.Role),
      (Escape-MarkdownCell $row.RemotePath),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.Action),
      $row.LocalBytes,
      (Escape-MarkdownCell $localShort),
      (Escape-MarkdownCell $remoteShort),
      (Escape-MarkdownCell $row.Detail)))
}
$md.Add("")
if($overall -eq "READY") {
   $md.Add("Run with a noninteractive token and `-ConfirmUpload` to publish the required artifacts still marked `READY`. Rows marked `PASS` are skipped.")
}
elseif($overall -eq "UPLOADED") {
   $md.Add("After upload, run `work\audit_github_publication_sync.ps1` and `work\refresh_money_ready_status.ps1`.")
}
$md | Set-Content -LiteralPath $outMarkdownFull -Encoding ASCII

[pscustomobject]@{
   Overall = $overall
   Pass = $pass
   Ready = $ready
   Uploaded = $uploaded
   Fail = $fail
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
