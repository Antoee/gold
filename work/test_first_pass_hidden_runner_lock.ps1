$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tempRoot = Join-Path $repo ("work\first_pass_hidden_runner_lock_test_{0}" -f $PID)
$hardLockPath = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$unlockPath = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenAckPath = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"

function Assert-True {
   param([bool]$Condition, [string]$Message)
   if(!$Condition) { throw $Message }
}

try {
   New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
   New-Item -ItemType File -Path $hardLockPath -Force | Out-Null
   Remove-Item -LiteralPath $unlockPath,$hiddenAckPath -Force -ErrorAction SilentlyContinue

   $outCsv = Join-Path $tempRoot "first-pass-hidden-run.csv"
   $outMd = Join-Path $tempRoot "first-pass-hidden-run.md"
   $stdoutPath = Join-Path $tempRoot "runner.stdout.txt"
   $stderrPath = Join-Path $tempRoot "runner.stderr.txt"

   $before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   $runnerProcess = Start-Process -FilePath "powershell.exe" `
      -ArgumentList @(
         "-NoProfile",
         "-NonInteractive",
         "-ExecutionPolicy",
         "Bypass",
         "-File",
         (Join-Path $repo "work\run_first_pass_package_hidden.ps1"),
         "-Run",
         "-TerminalPath",
         "C:\DefinitelyMissing\MetaTrader5\terminal64.exe",
         "-OutCsv",
         $outCsv,
         "-OutMarkdown",
         $outMd
      ) `
      -Wait `
      -PassThru `
      -WindowStyle Hidden `
      -RedirectStandardOutput $stdoutPath `
      -RedirectStandardError $stderrPath
   $exitCode = $runnerProcess.ExitCode
   $after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   $outputText = @(
      if(Test-Path -LiteralPath $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw }
      if(Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw }
   ) -join "`n"

   Assert-True ($exitCode -ne 0) "Runner -Run should fail closed while MT5_LOCAL_LAUNCH_DISABLED.lock is present."
   Assert-True ($outputText -match "hard-locked") "Runner -Run failure should explain the hard lock."
   Assert-True (!(Test-Path -LiteralPath $outCsv)) "Locked -Run should stop before writing a run CSV."
   Assert-True (!(Test-Path -LiteralPath $outMd)) "Locked -Run should stop before writing run markdown."
   Assert-True ($after.Count -le $before.Count) "Locked -Run must not create MT5-family processes."

   "FIRST_PASS_HIDDEN_RUNNER_LOCK_SMOKE_PASS"
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
