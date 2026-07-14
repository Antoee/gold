$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tempRoot = Join-Path $repo ('work/first_pass_hidden_runner_plan_test_{0}' -f $PID)

function Assert-True {
   param([bool]$Condition, [string]$Message)
   if(!$Condition) { throw $Message }
}

try {
   New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
   $outCsv = Join-Path $tempRoot 'first-pass-hidden-plan.csv'
   $outMd = Join-Path $tempRoot 'first-pass-hidden-plan.md'

   $before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   & powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $repo 'work/run_first_pass_package_hidden.ps1') `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null
   $after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

   Assert-True (Test-Path -LiteralPath $outCsv) 'Plan CSV should be written'
   Assert-True (Test-Path -LiteralPath $outMd) 'Plan markdown should be written'
   Assert-True ($after.Count -le $before.Count) 'Plan mode must not create MT5-family processes'

   $rows = @(Import-Csv -LiteralPath $outCsv)
   $markdown = Get-Content -LiteralPath $outMd -Raw
   Assert-True ($rows.Count -eq 4) 'Current first-pass hidden plan should include 4 configs'
   Assert-True (@($rows | Where-Object { $_.Action -eq 'RUN_HIDDEN' }).Count -eq 0) 'Plan mode must not mark rows as launched'
   Assert-True (@($rows | Where-Object { $_.Status -eq 'REPORT_FOUND' }).Count -eq 0) 'Plan mode should not claim reports'
   Assert-True (@($rows | Where-Object { $_.ConfigExists -ne 'True' }).Count -eq 0) 'Every current first-pass config should exist'
   Assert-True ($markdown.Contains('Plan mode does not launch MT5')) 'Markdown should state that plan mode does not launch MT5'
   Assert-True ($markdown.Contains('MT5 hard lock present')) 'Markdown should show the lock state'

   'FIRST_PASS_HIDDEN_RUNNER_PLAN_SMOKE_PASS'
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
