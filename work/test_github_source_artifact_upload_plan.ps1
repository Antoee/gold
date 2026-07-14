$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tempRoot = Join-Path $repo ("work\github_source_upload_plan_test_{0}" -f $PID)

function Assert-True {
   param([bool]$Condition, [string]$Message)
   if(!$Condition) { throw $Message }
}

try {
   New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
   $outCsv = Join-Path $tempRoot "source-upload-plan.csv"
   $outMd = Join-Path $tempRoot "source-upload-plan.md"

   & powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $repo "work\upload_github_required_source_artifacts.ps1") `
      -PlanOnly `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null

   Assert-True (Test-Path -LiteralPath $outCsv) "Plan CSV should be written"
   Assert-True (Test-Path -LiteralPath $outMd) "Plan markdown should be written"

   $rows = @(Import-Csv -LiteralPath $outCsv)
    Assert-True ($rows.Count -eq 7) "Plan should include every required publication artifact"
    Assert-True (@($rows | Where-Object { $_.Status -eq "UPLOADED" }).Count -eq 0) "Plan-only mode must not upload"
    Assert-True (@($rows | Where-Object { $_.Status -eq "FAIL" }).Count -eq 0) "Plan-only mode should not fail when local source files exist"
    Assert-True (@($rows | Where-Object { [string]::IsNullOrWhiteSpace($_.LocalSha256) }).Count -eq 0) "Every required row should include a local SHA-256"

    $hashes = @($rows | Where-Object { $_.Role -like "*ea-source" } | Select-Object -ExpandProperty LocalSha256 | Sort-Object -Unique)
    Assert-True ($hashes.Count -eq 1) "Root and mirrored source hashes should match"

    $rootRow = $rows | Where-Object Role -eq "root-ea-source" | Select-Object -First 1
    $mirrorRow = $rows | Where-Object Role -eq "mirrored-ea-source" | Select-Object -First 1
    $conservativeProfile = $rows | Where-Object Role -eq "trade-ready-conservative-profile" | Select-Object -First 1
    $moneyReadyProfile = $rows | Where-Object Role -eq "money-ready-profile" | Select-Object -First 1
    $aliasProfile = $rows | Where-Object Role -eq "trade-readiness-alias-profile" | Select-Object -First 1
    $sourceManifest = $rows | Where-Object Role -eq "source-manifest" | Select-Object -First 1
    $currentBest = $rows | Where-Object Role -eq "current-research-best" | Select-Object -First 1
    Assert-True ($null -ne $rootRow) "Plan should include the root EA source row"
    Assert-True ($null -ne $mirrorRow) "Plan should include the mirrored EA source row"
    Assert-True ($null -ne $conservativeProfile) "Plan should include the conservative profile row"
    Assert-True ($null -ne $moneyReadyProfile) "Plan should include the money-ready profile row"
    Assert-True ($null -ne $aliasProfile) "Plan should include the trade-readiness alias row"
    Assert-True ($null -ne $sourceManifest) "Plan should include the source manifest row"
    Assert-True ($null -ne $currentBest) "Plan should include the current research best row"
    if(![string]::IsNullOrWhiteSpace($rootRow.RemoteGitBlobSha)) {
       Assert-True ($rootRow.Action -eq "WOULD_UPDATE") "Known stale root source should be marked WOULD_UPDATE"
    }
    Assert-True ($mirrorRow.Action -eq "WOULD_CREATE") "Missing mirrored source should be marked WOULD_CREATE"
    Assert-True (@("SKIP_UP_TO_DATE", "WOULD_UPDATE") -contains $sourceManifest.Action) "Source manifest should either be skipped when synced or marked for update after local status changes"

    $markdown = Get-Content -Raw -LiteralPath $outMd
    Assert-True ($markdown.Contains("Generated offline")) "Markdown should state that this is offline"
    Assert-True ($markdown.Contains("Required Publication Artifact")) "Markdown should describe the broader required publication plan"
    Assert-True ($markdown.Contains("CURRENT_RESEARCH_BEST_PROFILE.md")) "Markdown should include current research best target"
    Assert-True (!$markdown.Contains("Bearer ")) "Markdown should not expose authorization headers"

   "GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN_SMOKE_PASS"
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
