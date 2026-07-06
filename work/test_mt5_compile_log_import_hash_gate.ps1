param(
   [string]$RepoRoot = (Resolve-Path ".").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-CompileLog {
   param([string]$Path, [string]$SourcePath)
   @(
      "2026.07.06 00:00:00.000    information: compiling $SourcePath"
      "Result: 0 errors, 0 warnings, 1559 ms elapsed, cpu='X64 Regular'"
   ) | Set-Content -LiteralPath $Path -Encoding ASCII
}

function Invoke-ImportCase {
   param(
      [string]$CaseName,
      [string]$ExpectedSourceText,
      [string]$CompiledSourceText,
      [bool]$PassCompiledPath,
      [string]$ExpectedStatus,
      [string]$ExpectedHashStatus
   )

   $caseDir = Join-Path $tempRoot $CaseName
   New-Item -ItemType Directory -Path $caseDir -Force | Out-Null
   $expectedSource = Join-Path $caseDir "expected.mq5"
   $compiledSource = Join-Path $caseDir "compiled.mq5"
   $logPath = Join-Path $caseDir "compile.log"
   $outCsv = Join-Path $caseDir "status.csv"
   $outMd = Join-Path $caseDir "status.md"

   $ExpectedSourceText | Set-Content -LiteralPath $expectedSource -Encoding ASCII
   $CompiledSourceText | Set-Content -LiteralPath $compiledSource -Encoding ASCII
   Write-CompileLog $logPath "Z:\external\Professional_XAUUSD_EA.mq5"

   $args = @{
      LogPath = $logPath
      ExpectedSourcePath = $expectedSource
      OutCsv = $outCsv
      OutMarkdown = $outMd
   }
   if($PassCompiledPath) {
      $args.CompiledSourcePath = $compiledSource
   }

   $scriptPath = Join-Path $resolvedRepo "work\import_mt5_compile_log.ps1"
   $failed = $false
   try {
      & $scriptPath @args | Out-Null
   } catch {
      $failed = $true
   }

   $row = Import-Csv -LiteralPath $outCsv | Select-Object -First 1
   if([string]$row.Status -ne $ExpectedStatus) {
      throw "$CaseName expected status $ExpectedStatus but got $($row.Status). Failed=$failed"
   }
   if([string]$row.SourceHashStatus -ne $ExpectedHashStatus) {
      throw "$CaseName expected hash status $ExpectedHashStatus but got $($row.SourceHashStatus)."
   }
}

$resolvedRepo = (Resolve-Path -LiteralPath $RepoRoot).Path
$workRoot = Join-Path $resolvedRepo "work"
$tempRoot = Join-Path $workRoot ("compile_hash_gate_tmp_{0}" -f $PID)

if(Test-Path -LiteralPath $tempRoot) {
   $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
   $resolvedWork = (Resolve-Path -LiteralPath $workRoot).Path
   if(!$resolvedTemp.StartsWith($resolvedWork, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to clean unexpected path: $resolvedTemp"
   }
   Remove-Item -LiteralPath $tempRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
   Invoke-ImportCase "hash_match" "same source" "same source" $true "PASS" "MATCH"
   Invoke-ImportCase "missing_compiled_path" "same source" "same source" $false "STALE" "EXPECTED_ONLY"
   Invoke-ImportCase "hash_mismatch" "expected source" "compiled source" $true "STALE" "MISMATCH"
}
finally {
   if(Test-Path -LiteralPath $tempRoot) {
      $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
      $resolvedWork = (Resolve-Path -LiteralPath $workRoot).Path
      if($resolvedTemp.StartsWith($resolvedWork, [System.StringComparison]::OrdinalIgnoreCase)) {
         Remove-Item -LiteralPath $tempRoot -Recurse -Force
      }
   }
}

"MT5_COMPILE_LOG_IMPORT_HASH_GATE_SMOKE_PASS"
