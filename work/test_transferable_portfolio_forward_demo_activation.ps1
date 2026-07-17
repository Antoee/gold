[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$activationPath = Join-Path $PSScriptRoot "activate_transferable_portfolio_forward_demo.ps1"
$registrationPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_REGISTRATION.json"
$sourcePath = Join-Path $workspaceRoot "work\Professional_XAUUSD_Transferable_Portfolio.mq5"
$profilePath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PROFILE.set"
$sentinelSourcePath = Join-Path $workspaceRoot "work\Professional_XAUUSD_Forward_Sentinel.mq5"
$sentinelProfilePath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_FORWARD_SENTINEL_PROFILE.set"
$checks = 0

function Assert-True {
   param([Parameter(Mandatory=$true)][bool]$Condition, [Parameter(Mandatory=$true)][string]$Message)
   if(!$Condition) { throw $Message }
   $script:checks++
}

function Get-Sha256 {
   param([Parameter(Mandatory=$true)][string]$Path)
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$registrationBefore = Get-Content -Raw -LiteralPath $registrationPath
$sourceHashBefore = Get-Sha256 $sourcePath
$profileHashBefore = Get-Sha256 $profilePath
$sentinelSourceHashBefore = Get-Sha256 $sentinelSourcePath
$sentinelProfileHashBefore = Get-Sha256 $sentinelProfilePath

$check = & $activationPath -Phase Check
Assert-True ($null -ne $check) "Activation check did not complete."
Assert-True ($check.ReadyToRegister -eq ($check.CommonGatePass -and $check.TradingDisabled)) "ReadyToRegister is inconsistent with its prerequisite gates."
Assert-True ([double]$check.ActualBalance -gt 0.0 -and [double]$check.ExpectedBalance -gt 0.0) "Activation check did not report usable balance evidence."
Assert-True ([int]$check.EntryEvents -ge 0 -and [int]$check.ClosedTrades -ge 0) "Activation check returned invalid event counts."
if([math]::Abs([double]$check.ActualBalance - [double]$check.ExpectedBalance) -gt 1.0) {
   Assert-True ($check.FailedGates -match "starting-balance") "Observed capital mismatch was not reported by the starting-balance gate."
}

if(!$check.ReadyToRegister) {
   $previousErrorAction = $ErrorActionPreference
   $ErrorActionPreference = "Continue"
   & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $activationPath -Phase Register 2>&1 | Out-Null
   $registerExitCode = $LASTEXITCODE
   $ErrorActionPreference = $previousErrorAction
   Assert-True ($registerExitCode -ne 0) "Register phase did not refuse a not-ready account."
   Assert-True ((Get-Content -Raw -LiteralPath $registrationPath) -ceq $registrationBefore) "Refused activation modified the forward registration."
}
else {
   Assert-True ((Get-Content -Raw -LiteralPath $registrationPath) -ceq $registrationBefore) "Readiness check modified the forward registration."
}
Assert-True ((Get-Sha256 $sourcePath) -eq $sourceHashBefore) "Activation check modified the candidate source."
Assert-True ((Get-Sha256 $profilePath) -eq $profileHashBefore) "Activation check modified the candidate profile."
Assert-True ((Get-Sha256 $sentinelSourcePath) -eq $sentinelSourceHashBefore) "Activation check modified the sentinel source."
Assert-True ((Get-Sha256 $sentinelProfilePath) -eq $sentinelProfileHashBefore) "Activation check modified the sentinel profile."

$activationText = Get-Content -Raw -LiteralPath $activationPath
Assert-True ($activationText -match 'algorithmic-trading-not-disabled') "Activation gate does not require disabled algorithmic trading."
Assert-True ($activationText -match 'starting-equity') "Activation gate does not verify starting equity."
Assert-True ($activationText -match 'flat-account') "Activation gate does not require a flat account."
Assert-True ($activationText -match 'empty-reversion-log' -and $activationText -match 'empty-momentum-log') "Activation gate does not require empty dedicated logs."
Assert-True ($activationText -match 'real-trading-disabled') "Activation gate does not preserve the real-account lock."
Assert-True ($activationText -notmatch 'ACCOUNT_LOGIN') "Activation script accesses the account login."

Write-Output "PASS: $checks forward-demo activation checks"
