$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tempRoot = Join-Path $repo ('work/github_source_upload_plan_test_{0}' -f $PID)

function Assert-True {
   param([bool]$Condition, [string]$Message)
   if(!$Condition) { throw $Message }
}

try {
   New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
   $outCsv = Join-Path $tempRoot 'source-upload-plan.csv'
   $outMd = Join-Path $tempRoot 'source-upload-plan.md'

   & powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $repo 'work/upload_github_required_source_artifacts.ps1') `
      -PlanOnly `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null

   Assert-True (Test-Path -LiteralPath $outCsv) 'Plan CSV should be written'
   Assert-True (Test-Path -LiteralPath $outMd) 'Plan markdown should be written'

   $rows = @(Import-Csv -LiteralPath $outCsv)
   Assert-True ($rows.Count -eq 2) 'Plan should include the two remaining source artifacts'
   Assert-True (@($rows | Where-Object { $_.Status -eq 'UPLOADED' }).Count -eq 0) 'Plan-only mode must not upload'
   Assert-True (@($rows | Where-Object { $_.Status -eq 'FAIL' }).Count -eq 0) 'Plan-only mode should not fail when local source files exist'
   Assert-True (@($rows | Where-Object { [string]::IsNullOrWhiteSpace($_.LocalSha256) }).Count -eq 0) 'Every source row should include a local SHA-256'

   $hashes = @($rows | Select-Object -ExpandProperty LocalSha256 | Sort-Object -Unique)
   Assert-True ($hashes.Count -eq 1) 'Root and mirrored source hashes should match'

   $rootRow = $rows | Where-Object Role -eq 'root-ea-source' | Select-Object -First 1
   $mirrorRow = $rows | Where-Object Role -eq 'mirrored-ea-source' | Select-Object -First 1
   Assert-True ($null -ne $rootRow) 'Plan should include the root EA source row'
   Assert-True ($null -ne $mirrorRow) 'Plan should include the mirrored EA source row'
   if(![string]::IsNullOrWhiteSpace($rootRow.RemoteGitBlobSha)) {
      Assert-True ($rootRow.Action -eq 'WOULD_UPDATE') 'Known stale root source should be marked WOULD_UPDATE'
   }
   Assert-True ($mirrorRow.Action -eq 'WOULD_CREATE') 'Missing mirrored source should be marked WOULD_CREATE'

   $markdown = Get-Content -Raw -LiteralPath $outMd
   Assert-True ($markdown.Contains('Generated offline')) 'Markdown should state that this is offline'
   Assert-True (!$markdown.Contains('Bearer ')) 'Markdown should not expose authorization headers'

   'GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN_SMOKE_PASS'
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
