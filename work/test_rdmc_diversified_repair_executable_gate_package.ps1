Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$package = Join-Path $repo "outputs\rdmc_diversified_repair_executable_gate_package"
$source = Join-Path $package "source\Professional_XAUUSD_EA.mq5"
$profile = Join-Path $package "profiles\rdmc_diversified_repair_restart_safe_v2.set"
$configs = Join-Path $package "configs"
$reports = Join-Path $package "reports_here"
$manifestPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv"
$contractPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_CONTRACT.md"
$decisionPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_DECISION.csv"
$decisionMarkdownPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_DECISION.md"
$expectedSourceHash = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
$expectedProfileHash = "746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883"
$expectedManifestHash = "4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A"

$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{ Check=$Name; Pass=$Pass; Evidence=$Evidence })
}

foreach($required in @($source, $profile, $configs, $manifestPath, $contractPath, $decisionPath, $decisionMarkdownPath)) {
   Add-Check "required artifact: $([IO.Path]::GetFileName($required))" (Test-Path -LiteralPath $required) $required
}
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Required executable-gate artifacts are missing."
}

$manifest = @(Import-Csv -LiteralPath $manifestPath)
$contract = Get-Content -LiteralPath $contractPath -Raw
$decision = @(Import-Csv -LiteralPath $decisionPath)
$decisionMarkdown = Get-Content -LiteralPath $decisionMarkdownPath -Raw
$configFiles = @(Get-ChildItem -LiteralPath $configs -Filter "*.ini" -File | Sort-Object Name)
$reportFiles = @(Get-ChildItem -LiteralPath $reports -File -ErrorAction SilentlyContinue)
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$profileHash = (Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash.ToUpperInvariant()
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToUpperInvariant()

Add-Check "source hash frozen" ($sourceHash -eq $expectedSourceHash) $sourceHash
Add-Check "profile hash frozen" ($profileHash -eq $expectedProfileHash) $profileHash
Add-Check "manifest hash frozen" ($manifestHash -eq $expectedManifestHash) $manifestHash
Add-Check "manifest has 24 rows" ($manifest.Count -eq 24) "rows=$($manifest.Count)"
Add-Check "package has 24 configs" ($configFiles.Count -eq 24) "configs=$($configFiles.Count)"
Add-Check "six Model1 rows only" (@($manifest | Where-Object Model -eq "1").Count -eq 6) "model1=$(@($manifest | Where-Object Model -eq '1').Count)"
Add-Check "eighteen Model4 rows" (@($manifest | Where-Object Model -eq "4").Count -eq 18) "model4=$(@($manifest | Where-Object Model -eq '4').Count)"
Add-Check "queue ranks are exact" ((@($manifest.QueueRank) -join ',') -eq ((1..24) -join ',')) (@($manifest.QueueRank) -join ',')
Add-Check "all rows freeze source" (@($manifest | Where-Object SourceSha256 -ne $expectedSourceHash).Count -eq 0) "rows=$($manifest.Count)"
Add-Check "all rows freeze profile" (@($manifest | Where-Object ProfileSha256 -ne $expectedProfileHash).Count -eq 0) "rows=$($manifest.Count)"
Add-Check "all rows freeze 10000 USD" (@($manifest | Where-Object { $_.Deposit -ne '10000' -or $_.InitialDeposit -ne '10000' }).Count -eq 0) "rows=$($manifest.Count)"
Add-Check "all rows remain launch locked" (@($manifest | Where-Object Status -ne "LOCKED_LOCAL_LAUNCH_DISABLED").Count -eq 0) "rows=$($manifest.Count)"
Add-Check "all configs are nonvisual" (@($configFiles | Where-Object { 'Visual=0' -notin @(Get-Content -LiteralPath $_.FullName) }).Count -eq 0) "configs=$($configFiles.Count)"
Add-Check "all configs freeze 589 inputs" (@($configFiles | Where-Object { @((Get-Content -LiteralPath $_.FullName) | Where-Object { $_ -match '^Inp[^=]+=' }).Count -ne 589 }).Count -eq 0) "configs=$($configFiles.Count)"

$hashFailures = foreach($row in $manifest) {
   $config = Join-Path $repo $row.PackageConfig
   if(!(Test-Path -LiteralPath $config -PathType Leaf)) { $row.QueueRank; continue }
   $actual = (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant()
   if($actual -ne $row.ConfigSha256) { $row.QueueRank }
}
Add-Check "every config hash matches manifest" (@($hashFailures).Count -eq 0) "failures=$(@($hashFailures).Count)"

$waveCounts = @(1..5 | ForEach-Object { @($manifest | Where-Object Wave -eq ([string]$_)).Count })
Add-Check "wave counts are 2,4,2,4,12" (($waveCounts -join ',') -eq '2,4,2,4,12') ($waveCounts -join ',')
foreach($wave in 1..5) {
   $wavePath = Join-Path $repo ("outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_WAVE_{0:D2}_MANIFEST.csv" -f $wave)
   $waveRows = if(Test-Path -LiteralPath $wavePath) { @(Import-Csv -LiteralPath $wavePath) } else { @() }
   $combinedRows = @($manifest | Where-Object Wave -eq ([string]$wave))
   Add-Check "wave $wave manifest matches combined queue" (($waveRows.ExpectedReportName -join ',') -eq ($combinedRows.ExpectedReportName -join ',')) "rows=$($waveRows.Count)"
}

$wave1 = @($manifest | Where-Object Wave -eq '1')
$wave3 = @($manifest | Where-Object Wave -eq '3')
$wave4Continuous = @($manifest | Where-Object { $_.Wave -eq '4' -and $_.Role -eq 'continuous' })
$wave5 = @($manifest | Where-Object Wave -eq '5')
Add-Check "Model1 critical years run first" (($wave1.Window -join ',') -eq '2019,2022' -and @($wave1 | Where-Object Model -ne '1').Count -eq 0) ($wave1.Window -join ',')
Add-Check "Model4 critical years precede broad real ticks" (($wave3.Window -join ',') -eq '2019,2022' -and @($wave3 | Where-Object Model -ne '4').Count -eq 0) ($wave3.Window -join ',')
Add-Check "continuous Model4 gate is risk normalized" ($wave4Continuous.Count -eq 1 -and [double]$wave4Continuous[0].MinProfitFactor -eq 1.30 -and [int]$wave4Continuous[0].MinTrades -eq 250 -and [double]$wave4Continuous[0].MaxDrawdownPercent -eq 5.0 -and [double]$wave4Continuous[0].MinRecoveryFactor -eq 3.0 -and [double]$wave4Continuous[0].MinCagrPercent -eq 1.0) "rows=$($wave4Continuous.Count)"
Add-Check "annual real-tick wave covers 12 windows" ($wave5.Count -eq 12 -and $wave5[0].Window -eq '2015' -and $wave5[-1].Window -eq '2026_ytd') "rows=$($wave5.Count)"
Add-Check "annual real-tick rows reject red windows" (@($wave5 | Where-Object { [double]$_.MinNetProfit -le 0.0 -or [double]$_.MaxDrawdownPercent -gt 3.0 }).Count -eq 0) "rows=$($wave5.Count)"
Add-Check "data cutoff is frozen" (@($manifest | Where-Object { $_.To -gt '2026.07.12' }).Count -eq 0) "cutoff=2026.07.12"
Add-Check "no MT5 reports claimed" ($reportFiles.Count -eq 0) "reports=$($reportFiles.Count)"

Add-Check "decision is locked at wave one" ($decision.Count -eq 1 -and $decision[0].Status -eq 'LOCKED_AWAITING_WAVE_01_REPORTS' -and $decision[0].ReportsPresent -eq '0') $(if($decision.Count -eq 1){$decision[0].Status}else{'missing'})
Add-Check "decision keeps candidate unchanged" ($decision[0].ForwardCandidateChanged -eq 'False' -and $decision[0].RealAccountApproved -eq 'False' -and $decision[0].PostHocCollisionScorePromoted -eq 'False') "forward=$($decision[0].ForwardCandidateChanged) real=$($decision[0].RealAccountApproved)"
Add-Check "contract states Model1 reject-only" ($contract.Contains('Model1 only rejects cheaply') -and $contract.Contains('only eight tests are spent before real-tick testing begins')) "boundary present"
Add-Check "contract retains later evidence gates" ($contract.Contains('executable trade ledger') -and $contract.Contains('order-aware Monte Carlo') -and $contract.Contains('broker variation') -and $contract.Contains('valid forward demo')) "boundary present"
Add-Check "contract requires identity-bound report admission" ($contract.Contains('currently admitted wave') -and $contract.Contains('manifest-pinned config and source hashes') -and $contract.Contains('one shared binary identity') -and $contract.Contains('frozen source identity inside every report')) "boundary present"
Add-Check "contract requires fresh complete resumable reports" ($contract.Contains('waits for clean terminal exit') -and $contract.Contains('exactly one fresh, non-empty report') -and $contract.Contains('schema-versioned sidecar') -and $contract.Contains('independently revalidated sidecar/report hash')) "boundary present"
Add-Check "decision does not infer reports" ($decisionMarkdown.Contains('No report is inferred') -and $decisionMarkdown.Contains('Even a five-wave pass is not money-ready')) "boundary present"
Add-Check "repository launch lock remains" (Test-Path -LiteralPath (Join-Path $repo 'work\MT5_LOCAL_LAUNCH_DISABLED.lock')) "present"
Add-Check "outer launch lock remains" (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $repo) 'MT5_LOCAL_LAUNCH_DISABLED.lock')) "present"
$mt5Processes = @(Get-Process -Name terminal64,terminal,metatester64,metaeditor64 -ErrorAction SilentlyContinue)
Add-Check "no MT5 process running" ($mt5Processes.Count -eq 0) "processes=$($mt5Processes.Count)"
Add-Check "no account identifier published" ($contract -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $decisionMarkdown -notmatch '(?i)login\s*[:=]\s*\d{5,}') "public markdown clean"
Add-Check "no GitHub token published" ($contract -notmatch 'github_pat_|gh[pousr]_[A-Za-z0-9]{20,}' -and $decisionMarkdown -notmatch 'github_pat_|gh[pousr]_[A-Za-z0-9]{20,}') "public markdown clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) { throw "FAIL: $($failed.Count) executable-gate package checks failed." }
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC executable-gate package checks"
