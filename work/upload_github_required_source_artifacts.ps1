param(
   [string]$RepositoryFullName = 'Antoee/gold',
   [string]$Branch = 'main',
   [string]$Token = '',
   [string]$TokenFile = '',
   [switch]$ConfirmUpload,
   [switch]$PlanOnly,
   [string]$PublicationSyncCsv = 'outputs/GITHUB_PUBLICATION_SYNC.csv',
   [string]$OutCsv = 'outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.csv',
   [string]$OutMarkdown = 'outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Resolve-RepoPath {
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

function Get-TokenValue {
   if(![string]::IsNullOrWhiteSpace($Token)) { return $Token.Trim() }
   if(![string]::IsNullOrWhiteSpace($TokenFile)) {
      $resolved = Resolve-RepoPath $TokenFile
      if(Test-Path -LiteralPath $resolved) { return ((Get-Content -Raw -LiteralPath $resolved).Trim()) }
   }
   foreach($name in @('GITHUB_TOKEN', 'GH_TOKEN')) {
      $value = [Environment]::GetEnvironmentVariable($name)
      if(![string]::IsNullOrWhiteSpace($value)) { return $value.Trim() }
   }
   return ''
}

function Get-FileSha256 {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { return '' }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-GitBlobSha {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { return '' }
   $bytes = [IO.File]::ReadAllBytes($Path)
   $prefix = [Text.Encoding]::ASCII.GetBytes(('blob {0}' -f $bytes.Length) + [char]0)
   $combined = New-Object byte[] ($prefix.Length + $bytes.Length)
   [Array]::Copy($prefix, 0, $combined, 0, $prefix.Length)
   [Array]::Copy($bytes, 0, $combined, $prefix.Length, $bytes.Length)
   $sha = [Security.Cryptography.SHA1]::Create()
   try { return ([BitConverter]::ToString($sha.ComputeHash($combined))).Replace('-', '').ToLowerInvariant() }
   finally { $sha.Dispose() }
}

function New-Headers {
   param([string]$ResolvedToken)
   return @{
      Authorization = ('Bearer {0}' -f $ResolvedToken)
      Accept = 'application/vnd.github+json'
      'X-GitHub-Api-Version' = '2022-11-28'
      'User-Agent' = 'codex-xauusd-source-artifact-sync'
   }
}

function Get-RepoParts {
   $parts = $RepositoryFullName.Split('/')
   if($parts.Count -ne 2) { throw 'RepositoryFullName must be owner/repo.' }
   return $parts
}

function ConvertTo-ApiPath {
   param([string]$Path)
   return (($Path -replace '\\', '/') -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
}

function Get-RemoteWithToken {
   param([string]$RemotePath, [hashtable]$Headers)
   $parts = Get-RepoParts
   $apiPath = ConvertTo-ApiPath $RemotePath
   $url = 'https://api.github.com/repos/{0}/{1}/contents/{2}?ref={3}' -f $parts[0], $parts[1], $apiPath, ([uri]::EscapeDataString($Branch))
   try {
      $result = Invoke-RestMethod -Method Get -Uri $url -Headers $Headers
      return [pscustomobject]@{ Exists = $true; BlobSha = ([string]$result.sha).ToLowerInvariant(); Size = [int64]$result.size; Error = '' }
   }
   catch {
      $status = 0
      if($null -ne $_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
      if($status -eq 404) { return [pscustomobject]@{ Exists = $false; BlobSha = ''; Size = 0; Error = 'remote-missing' } }
      throw
   }
}

function Get-RemoteFromPublicationSync {
   param([object]$Artifact)
   $syncPath = Resolve-RepoPath $PublicationSyncCsv
   if(!(Test-Path -LiteralPath $syncPath)) { return [pscustomobject]@{ Exists = $false; BlobSha = ''; Size = 0; Error = 'not-checked-no-token' } }
   $row = @(Import-Csv -LiteralPath $syncPath) | Where-Object {
      [string]$_.Role -eq [string]$Artifact.Role -or [string]$_.RemotePath -eq [string]$Artifact.RemotePath -or [string]$_.LocalPath -eq [string]$Artifact.LocalPath
   } | Select-Object -First 1
   if($null -eq $row) { return [pscustomobject]@{ Exists = $false; BlobSha = ''; Size = 0; Error = 'not-checked-no-token' } }
   $blob = ([string]$row.RemoteGitBlobSha).ToLowerInvariant()
   $exists = ![string]::IsNullOrWhiteSpace($blob) -and [string]$row.Detail -ne 'CONNECTOR_REMOTE_MISSING'
   return [pscustomobject]@{ Exists = $exists; BlobSha = $blob; Size = 0; Error = $(if($exists) { 'from-publication-sync' } else { 'remote-missing-from-publication-sync' }) }
}

function Set-RemoteContent {
   param([object]$Artifact, [string]$LocalPath, [string]$RemoteBlobSha, [hashtable]$Headers)
   $parts = Get-RepoParts
   $apiPath = ConvertTo-ApiPath $Artifact.RemotePath
   $url = 'https://api.github.com/repos/{0}/{1}/contents/{2}' -f $parts[0], $parts[1], $apiPath
   $body = @{
      message = $Artifact.Message
      content = [Convert]::ToBase64String([IO.File]::ReadAllBytes($LocalPath))
      branch = $Branch
   }
   if(![string]::IsNullOrWhiteSpace($RemoteBlobSha)) { $body.sha = $RemoteBlobSha }
   $result = Invoke-RestMethod -Method Put -Uri $url -Headers $Headers -Body ($body | ConvertTo-Json -Depth 4) -ContentType 'application/json'
   return [pscustomobject]@{ CommitSha = [string]$result.commit.sha; ContentSha = [string]$result.content.sha }
}

$artifacts = @(
   [pscustomobject]@{ Role = 'root-ea-source'; LocalPath = 'Professional_XAUUSD_EA.mq5'; RemotePath = 'Professional_XAUUSD_EA.mq5'; Message = 'Sync current root EA source artifact' },
   [pscustomobject]@{ Role = 'mirrored-ea-source'; LocalPath = 'outputs/Professional_XAUUSD_EA.mq5'; RemotePath = 'outputs/Professional_XAUUSD_EA.mq5'; Message = 'Sync current mirrored EA source artifact' }
)

$resolvedToken = Get-TokenValue
$hasToken = ![string]::IsNullOrWhiteSpace($resolvedToken)
if(!$PlanOnly -and !$ConfirmUpload) { throw 'Refusing to upload without -ConfirmUpload. Use -PlanOnly to write a non-mutating plan.' }
if(!$PlanOnly -and !$hasToken) { throw 'No GitHub token found. Set GITHUB_TOKEN or GH_TOKEN, pass -Token, or use -TokenFile.' }
$headers = if($hasToken) { New-Headers $resolvedToken } else { @{} }

$hashes = @($artifacts | ForEach-Object { Get-FileSha256 (Resolve-RepoPath $_.LocalPath) } | Where-Object { $_ -ne '' } | Sort-Object -Unique)
if($hashes.Count -gt 1) { throw 'Root and mirrored EA source hashes do not match. Refusing source publication.' }

$rows = foreach($artifact in $artifacts) {
   $localPath = Resolve-RepoPath $artifact.LocalPath
   $localExists = Test-Path -LiteralPath $localPath
   $localSha = Get-FileSha256 $localPath
   $localBlob = Get-GitBlobSha $localPath
   $localBytes = if($localExists) { (Get-Item -LiteralPath $localPath).Length } else { 0 }
   $remote = if($hasToken) { Get-RemoteWithToken $artifact.RemotePath $headers } else { Get-RemoteFromPublicationSync $artifact }
   $status = 'READY'
   $action = if($remote.Exists) { 'WOULD_UPDATE' } else { 'WOULD_CREATE' }
   $detail = if($hasToken) { 'Token available; rerun with -ConfirmUpload to publish.' } else { 'No token available; remote state inferred from publication audit. Set GITHUB_TOKEN or GH_TOKEN, then rerun with -ConfirmUpload.' }
   $commit = ''
   $contentSha = ''
   if(!$localExists) { $status = 'FAIL'; $action = 'LOCAL_MISSING'; $detail = 'Local source artifact is missing.' }
   elseif($remote.Exists -and $remote.BlobSha -eq $localBlob) { $status = 'PASS'; $action = 'SKIP_UP_TO_DATE'; $detail = 'Remote blob already matches local source artifact.' }
   elseif(!$PlanOnly) {
      $upload = Set-RemoteContent $artifact $localPath $remote.BlobSha $headers
      $status = 'UPLOADED'
      $action = if($remote.Exists) { 'UPDATED' } else { 'CREATED' }
      $detail = 'Uploaded exact local bytes through GitHub Contents API.'
      $commit = $upload.CommitSha
      $contentSha = $upload.ContentSha
   }
   [pscustomobject]@{
      Role = $artifact.Role; Status = $status; Action = $action; LocalPath = $artifact.LocalPath; RemotePath = $artifact.RemotePath; LocalExists = [string]$localExists; LocalBytes = $localBytes; LocalSha256 = $localSha; LocalGitBlobSha = $localBlob; RemoteExists = [string]$remote.Exists; RemoteBytes = $remote.Size; RemoteGitBlobSha = $remote.BlobSha; RemoteError = $remote.Error; CommitSha = $commit; ContentSha = $contentSha; Detail = $detail
   }
}

$outCsv = Resolve-RepoPath $OutCsv
$outMd = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $outCsv
Ensure-ParentDir $outMd
$rows | Export-Csv -LiteralPath $outCsv -NoTypeInformation -Encoding ASCII
$fail = @($rows | Where-Object Status -eq 'FAIL').Count
$ready = @($rows | Where-Object Status -eq 'READY').Count
$uploaded = @($rows | Where-Object Status -eq 'UPLOADED').Count
$pass = @($rows | Where-Object Status -eq 'PASS').Count
$overall = if($fail -gt 0) { 'FAIL' } elseif($uploaded -gt 0) { 'UPLOADED' } elseif($ready -gt 0) { 'READY' } else { 'PASS' }
$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# GitHub Source Artifact Upload Plan')
$md.Add('')
$md.Add('Generated offline. This does not launch MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.')
$md.Add('')
$md.Add(('- Overall: **{0}**' -f $overall))
$md.Add(('- Repository: `{0}`' -f $RepositoryFullName))
$md.Add(('- Branch: `{0}`' -f $Branch))
$md.Add(('- Token available: `{0}`' -f $hasToken))
$md.Add(('- Confirm upload: `{0}`' -f ([bool]$ConfirmUpload)))
$md.Add(('- Plan only: `{0}`' -f ([bool]$PlanOnly)))
$md.Add(('- Source SHA-256: `{0}`' -f ($(if($hashes.Count -eq 1) { $hashes[0] } else { '' }))))
$md.Add('')
$md.Add('## Artifacts')
$md.Add('')
$md.Add('| Role | Status | Action | Local Bytes | Local SHA-256 | Remote Blob | Detail |')
$md.Add('| --- | --- | --- | ---: | --- | --- | --- |')
foreach($row in $rows) {
   $localShort = if([string]::IsNullOrWhiteSpace($row.LocalSha256)) { '' } else { $row.LocalSha256.Substring(0, [Math]::Min(12, $row.LocalSha256.Length)) }
   $remoteShort = if([string]::IsNullOrWhiteSpace($row.RemoteGitBlobSha)) { '' } else { $row.RemoteGitBlobSha.Substring(0, [Math]::Min(12, $row.RemoteGitBlobSha.Length)) }
   $md.Add(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} |' -f $row.Role, $row.Status, $row.Action, $row.LocalBytes, $localShort, $remoteShort, $row.Detail))
}
$md.Add('')
if($overall -eq 'READY') { $md.Add('Run with a noninteractive token and `-ConfirmUpload` to publish the two remaining required EA source artifacts.') }
elseif($overall -eq 'UPLOADED') { $md.Add('After upload, run `work/audit_github_publication_sync.ps1` and `work/refresh_money_ready_status.ps1`.') }
$md | Set-Content -LiteralPath $outMd -Encoding ASCII
[pscustomobject]@{ Overall = $overall; Pass = $pass; Ready = $ready; Uploaded = $uploaded; Fail = $fail; OutCsv = $OutCsv; OutMarkdown = $OutMarkdown }
