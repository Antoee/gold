param(
   [string]$ProfilePath = "outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set",
   [string]$RootSourcePath = "Professional_XAUUSD_EA.mq5",
   [string]$MirrorSourcePath = "outputs\Professional_XAUUSD_EA.mq5",
   [string]$CompileStatusPath = "outputs\MT5_COMPILE_STATUS.csv",
   [string]$SafetyAuditPath = "outputs\MT5_LOCAL_SAFETY_AUDIT.csv",
   [string]$ConservativeAuditPath = "outputs\TRADE_READY_CONSERVATIVE_AUDIT.csv",
   [string]$ValidationDecisionPath = "outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv",
   [string]$EfficiencyAuditPath = "outputs\MONEY_READY_EFFICIENCY_AUDIT.csv",
   [string]$TradeQualityPath = "outputs\TRADE_READY_CONSERVATIVE_TRADE_QUALITY.csv",
   [string]$MonteCarloPath = "outputs\TRADE_READY_CONSERVATIVE_MONTE_CARLO.csv",
   [string]$ForwardEvidencePath = "outputs\TRADE_READY_CONSERVATIVE_FORWARD_TEST.csv",
   [string]$SecondBrokerEvidencePath = "outputs\TRADE_READY_CONSERVATIVE_SECOND_BROKER_DECISION.csv",
   [string]$ReproBundleManifestPath = "outputs\TRADE_READY_REPRODUCIBILITY_BUNDLE_MANIFEST.csv",
   [string]$ReproBundleZipPath = "outputs\trade_ready_reproducibility_bundle.zip",
   [string]$GitHubPublicationSyncPath = "outputs\GITHUB_PUBLICATION_SYNC.csv",
   [string]$RepositoryFullName = "Antoee/gold",
   [string]$GitRoot = "",
   [string]$OutCsv = "outputs\TRADE_READY_LIVE_READINESS_DECISION.csv",
   [string]$OutMarkdown = "outputs\TRADE_READY_LIVE_READINESS_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return $Path }
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return (Join-Path $repo $Path)
}

function Read-CsvSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   if(Test-Path -LiteralPath $resolved) { return ,@(Import-Csv -LiteralPath $resolved) }
   return ,@()
}

function Get-Value {
   param([object]$Row, [string]$Name, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

function Get-SetValue {
   param([string]$ProfileText, [string]$Name)
   $pattern = "(?m)^" + [regex]::Escape($Name) + "=([^\r\n|]*)"
   $match = [regex]::Match($ProfileText, $pattern)
   if(!$match.Success) { return "" }
   return $match.Groups[1].Value
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

function Invoke-GitText {
   param(
      [string]$WorkingDirectory,
      [string[]]$Arguments
   )

   $git = Get-Command git -ErrorAction SilentlyContinue
   if($null -eq $git) {
      $windowsGit = "C:\Program Files\Git\cmd\git.exe"
      if(Test-Path -LiteralPath $windowsGit) {
         $git = [pscustomobject]@{ Source = $windowsGit }
      }
   }
   if($null -eq $git) {
      return [pscustomobject]@{ Success = $false; Text = ""; Error = "git-not-found" }
   }
   if(!(Test-Path -LiteralPath $WorkingDirectory)) {
      return [pscustomobject]@{ Success = $false; Text = ""; Error = "git-root-missing" }
   }

   $previousErrorActionPreference = $ErrorActionPreference
   $ErrorActionPreference = "Continue"
   try {
      $output = @(& $git.Source -C $WorkingDirectory @Arguments 2>&1)
      $exitCode = $LASTEXITCODE
   }
   catch {
      $output = @($_.Exception.Message)
      $exitCode = 1
   }
   finally {
      $ErrorActionPreference = $previousErrorActionPreference
   }
   $text = ($output | ForEach-Object { [string]$_ }) -join "`n"
   return [pscustomobject]@{
      Success = ($exitCode -eq 0)
      Text = $text.Trim()
      Error = if($exitCode -eq 0) { "" } else { $text.Trim() }
   }
}

function Test-OriginMatchesRepository {
   param([string]$Origin, [string]$Repository)
   if([string]::IsNullOrWhiteSpace($Origin) -or [string]::IsNullOrWhiteSpace($Repository)) { return $false }
   $originText = ([string]$Origin).Trim().Replace("\", "/").ToLowerInvariant()
   $repoText = ([string]$Repository).Trim().Replace("\", "/").ToLowerInvariant()
   $repoPattern = [regex]::Escape($repoText)
   return ($originText -match "(^|[:/])$repoPattern(\.git)?/?$")
}

function Convert-ToGitRelativePath {
   param([string]$TopLevel, [string]$Path)
   $resolved = Resolve-RepoPath $Path
   if([string]::IsNullOrWhiteSpace($resolved)) { return "" }
   $full = [IO.Path]::GetFullPath($resolved)
   $top = [IO.Path]::GetFullPath($TopLevel)
   if(!$top.EndsWith([IO.Path]::DirectorySeparatorChar)) {
      $top = $top + [IO.Path]::DirectorySeparatorChar
   }
   if(!$full.StartsWith($top, [StringComparison]::OrdinalIgnoreCase)) {
      return ""
   }
   return ([IO.Path]::GetRelativePath($top, $full)).Replace("\", "/")
}

function Get-GitPublicationState {
   param(
      [string]$WorkingDirectory,
      [string]$Repository,
      [string[]]$RequiredPaths
   )

   $state = [ordered]@{
      GitAvailable = $false
      InsideWorkTree = $false
      HeadPresent = $false
      OriginMatches = $false
      UpstreamPresent = $false
      AheadCount = ""
      RequiredTracked = $false
      RequiredClean = $false
      Valid = $false
      Detail = ""
   }

   $inside = Invoke-GitText $WorkingDirectory @("rev-parse", "--is-inside-work-tree")
   if($inside.Error -eq "git-not-found") {
      $state.Detail = "git-not-found"
      return [pscustomobject]$state
   }
   $state.GitAvailable = $true
   if(!$inside.Success -or $inside.Text -ne "true") {
      $state.Detail = if([string]::IsNullOrWhiteSpace($inside.Error)) { "not-a-git-worktree" } else { $inside.Error }
      return [pscustomobject]$state
   }
   $state.InsideWorkTree = $true

   $head = Invoke-GitText $WorkingDirectory @("rev-parse", "--verify", "HEAD")
   $state.HeadPresent = ($head.Success -and ![string]::IsNullOrWhiteSpace($head.Text))

   $origin = Invoke-GitText $WorkingDirectory @("config", "--get", "remote.origin.url")
   $state.OriginMatches = ($origin.Success -and (Test-OriginMatchesRepository $origin.Text $Repository))

   $upstream = Invoke-GitText $WorkingDirectory @("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
   $state.UpstreamPresent = ($upstream.Success -and ![string]::IsNullOrWhiteSpace($upstream.Text))

   $branch = Invoke-GitText $WorkingDirectory @("status", "--porcelain=v2", "--branch", "--untracked-files=no")
   if($branch.Success) {
      $abMatch = [regex]::Match($branch.Text, "(?m)^# branch\.ab \+(\d+) -(\d+)")
      if($abMatch.Success) {
         $state.AheadCount = $abMatch.Groups[1].Value
      } elseif($state.UpstreamPresent) {
         $state.AheadCount = "0"
      }
   }

   $topLevel = Invoke-GitText $WorkingDirectory @("rev-parse", "--show-toplevel")
   $requiredTracked = $true
   $requiredClean = $true
   if(!$topLevel.Success -or [string]::IsNullOrWhiteSpace($topLevel.Text)) {
      $requiredTracked = $false
      $requiredClean = $false
   } else {
      foreach($requiredPath in $RequiredPaths) {
         $relative = Convert-ToGitRelativePath $topLevel.Text $requiredPath
         if([string]::IsNullOrWhiteSpace($relative)) {
            $requiredTracked = $false
            $requiredClean = $false
            continue
         }
         $tracked = Invoke-GitText $WorkingDirectory @("ls-files", "--error-unmatch", "--", $relative)
         if(!$tracked.Success) {
            $requiredTracked = $false
            $requiredClean = $false
            continue
         }
         $status = Invoke-GitText $WorkingDirectory @("status", "--porcelain=v1", "--", $relative)
         if(!$status.Success -or ![string]::IsNullOrWhiteSpace($status.Text)) {
            $requiredClean = $false
         }
      }
   }
   $state.RequiredTracked = $requiredTracked
   $state.RequiredClean = $requiredClean

   $aheadOkay = ($state.AheadCount -eq "0")
   $state.Valid = ($state.InsideWorkTree -and $state.HeadPresent -and $state.OriginMatches -and $state.UpstreamPresent -and $aheadOkay -and $state.RequiredTracked -and $state.RequiredClean)
   $state.Detail = "inside=$($state.InsideWorkTree); head=$($state.HeadPresent); originMatch=$($state.OriginMatches); upstream=$($state.UpstreamPresent); ahead=$($state.AheadCount); requiredTracked=$($state.RequiredTracked); requiredClean=$($state.RequiredClean)"
   return [pscustomobject]$state
}

$rows = New-Object System.Collections.Generic.List[object]

function Add-Gate {
   param(
      [string]$Gate,
      [string]$Status,
      [string]$Required,
      [string]$Actual,
      [string]$Evidence,
      [string]$NextAction
   )

   $rows.Add([pscustomobject]@{
      Gate = $Gate
      Status = $Status
      Required = $Required
      Actual = $Actual
      Evidence = $Evidence
      NextAction = $NextAction
   }) | Out-Null
}

function Add-DecisionCsvGate {
   param(
      [string]$Gate,
      [string]$Path,
      [string]$Required,
      [string]$NextAction
   )

   $decisionRows = Read-CsvSafe $Path
   if($decisionRows.Count -eq 0) {
      Add-Gate $Gate "PENDING" $Required "rows=0" $Path $NextAction
      return
   }

   $fail = @($decisionRows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" }).Count
   $pending = @($decisionRows | Where-Object { [string](Get-Value $_ "Status") -eq "PENDING" }).Count
   $pass = @($decisionRows | Where-Object { [string](Get-Value $_ "Status") -eq "PASS" }).Count
   $status = if($fail -gt 0) { "FAIL" } elseif($pending -gt 0) { "PENDING" } else { "PASS" }
   Add-Gate $Gate $status $Required "rows=$($decisionRows.Count); pass=$pass; pending=$pending; fail=$fail" $Path $NextAction
}

function Add-SingleStatusGate {
   param(
      [string]$Gate,
      [string]$Path,
      [string]$Required,
      [string]$ActualDetails,
      [string]$NextAction
   )

   $statusRows = Read-CsvSafe $Path
   if($statusRows.Count -eq 0) {
      Add-Gate $Gate "PENDING" $Required "rows=0" $Path $NextAction
      return
   }

   $row = $statusRows | Select-Object -First 1
   $rowStatus = [string](Get-Value $row "Status" "PENDING")
   $status = if($rowStatus -eq "PASS") { "PASS" } elseif($rowStatus -eq "FAIL") { "FAIL" } else { "PENDING" }
   $actual = if([string]::IsNullOrWhiteSpace($ActualDetails)) { "status=$rowStatus" } else { "status=$rowStatus; $ActualDetails" }
   Add-Gate $Gate $status $Required $actual $Path $NextAction
}

$profileFullPath = Resolve-RepoPath $ProfilePath
$rootSourceFullPath = Resolve-RepoPath $RootSourcePath
$mirrorSourceFullPath = Resolve-RepoPath $MirrorSourcePath

$profileText = if(Test-Path -LiteralPath $profileFullPath) { Get-Content -LiteralPath $profileFullPath -Raw } else { "" }
$rootSourceHash = if(Test-Path -LiteralPath $rootSourceFullPath) { (Get-FileHash -LiteralPath $rootSourceFullPath -Algorithm SHA256).Hash } else { "" }
$mirrorSourceHash = if(Test-Path -LiteralPath $mirrorSourceFullPath) { (Get-FileHash -LiteralPath $mirrorSourceFullPath -Algorithm SHA256).Hash } else { "" }
$profileHash = if(Test-Path -LiteralPath $profileFullPath) { (Get-FileHash -LiteralPath $profileFullPath -Algorithm SHA256).Hash } else { "" }

Add-Gate "profile-artifact" ($(if(Test-Path -LiteralPath $profileFullPath) { "PASS" } else { "PENDING" })) `
   "Conservative trade-ready profile exists" `
   ($(if(Test-Path -LiteralPath $profileFullPath) { "hash=$profileHash" } else { "missing" })) `
   $ProfilePath `
   "Generate outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set."

$sourceStatus = if($rootSourceHash -ne "" -and $rootSourceHash -eq $mirrorSourceHash) { "PASS" } elseif($rootSourceHash -eq "" -or $mirrorSourceHash -eq "") { "PENDING" } else { "FAIL" }
Add-Gate "source-artifact-sync" $sourceStatus `
   "Root EA source and mirrored output source have the same SHA-256" `
   "root=$rootSourceHash; mirror=$mirrorSourceHash" `
   "$RootSourcePath + $MirrorSourcePath" `
   "Sync source artifacts before compiling or testing."

if([string]::IsNullOrWhiteSpace($profileText)) {
   Add-Gate "real-account-lock" "PENDING" "Real-account trading remains blocked until final manual approval" "profile missing" $ProfilePath "Generate/read the conservative profile."
} else {
   $useLock = Get-SetValue $profileText "InpUseRealAccountSafetyLock"
   $allowReal = Get-SetValue $profileText "InpAllowRealAccountTrading"
   $approval = Get-SetValue $profileText "InpRealAccountApprovalCode"
   $approvalProfileId = Get-SetValue $profileText "InpRealAccountApprovalProfileId"
   $approvalSourceHash = Get-SetValue $profileText "InpRealAccountApprovalSourceHash"
   $status = if($useLock -eq "true" -and $allowReal -eq "false" -and $approval -eq "DISABLED" -and $approvalProfileId -eq "DISABLED" -and $approvalSourceHash -eq "DISABLED") { "PASS" } else { "FAIL" }
   Add-Gate "real-account-lock" $status `
      "InpUseRealAccountSafetyLock=true, InpAllowRealAccountTrading=false, InpRealAccountApprovalCode=DISABLED, InpRealAccountApprovalProfileId=DISABLED, InpRealAccountApprovalSourceHash=DISABLED" `
      "InpUseRealAccountSafetyLock=$useLock; InpAllowRealAccountTrading=$allowReal; InpRealAccountApprovalCode=$approval; InpRealAccountApprovalProfileId=$approvalProfileId; InpRealAccountApprovalSourceHash=$approvalSourceHash" `
      $ProfilePath `
      "Keep real-account trading blocked until every proof gate passes and the user explicitly approves a separate live profile."
}

$safetyRows = Read-CsvSafe $SafetyAuditPath
if($safetyRows.Count -eq 0) {
   Add-Gate "local-pc-safety" "PENDING" "MT5 local safety audit exists with zero failed checks" "rows=0" $SafetyAuditPath "Run work\audit_mt5_local_safety.ps1."
} else {
   $failedSafety = @($safetyRows | Where-Object {
      [string](Get-Value $_ "Passed") -eq "False" -or [string](Get-Value $_ "Status") -eq "FAIL"
   }).Count
   Add-Gate "local-pc-safety" ($(if($failedSafety -eq 0) { "PASS" } else { "FAIL" })) `
      "MT5 local safety audit exists with zero failed checks" `
      "rows=$($safetyRows.Count); failures=$failedSafety" `
      $SafetyAuditPath `
      "Fix local safety audit failures before any tester/live work."
}

$compileRows = Read-CsvSafe $CompileStatusPath
if($compileRows.Count -eq 0) {
   Add-Gate "current-source-compile" "PENDING" "Current mirrored EA source compiles with 0 errors/warnings, SourceHashStatus=MATCH, and currentSourceStatus=CURRENT" "rows=0" $CompileStatusPath "Import a fresh MetaEditor compile log for the exact current source."
} else {
   $compile = $compileRows | Select-Object -First 1
   $compileStatus = [string](Get-Value $compile "Status")
   $sourceHashStatus = [string](Get-Value $compile "SourceHashStatus")
   $expectedSourceHash = [string](Get-Value $compile "ExpectedSourceHash")
   $errors = [string](Get-Value $compile "Errors")
   $warnings = [string](Get-Value $compile "Warnings")
   $currentSourceStatus = if([string]::IsNullOrWhiteSpace($expectedSourceHash) -or [string]::IsNullOrWhiteSpace($mirrorSourceHash)) {
      "UNKNOWN"
   } elseif($expectedSourceHash -eq $mirrorSourceHash) {
      "CURRENT"
   } else {
      "STALE"
   }
   $isCurrent = ($compileStatus -eq "PASS" -and $sourceHashStatus -eq "MATCH" -and $currentSourceStatus -eq "CURRENT" -and $errors -eq "0" -and $warnings -eq "0")
   $status = if($compileStatus -eq "FAIL") { "FAIL" } elseif($isCurrent) { "PASS" } else { "PENDING" }
   Add-Gate "current-source-compile" $status `
      "Current mirrored EA source compiles with 0 errors/warnings, SourceHashStatus=MATCH, and currentSourceStatus=CURRENT" `
      "status=$compileStatus; hashStatus=$sourceHashStatus; currentSourceStatus=$currentSourceStatus; compileHash=$expectedSourceHash; currentHash=$mirrorSourceHash; errors=$errors; warnings=$warnings" `
      $CompileStatusPath `
      "Import a fresh compile log for the exact current source hash before trusting tester/live evidence."
}

$auditRows = Read-CsvSafe $ConservativeAuditPath
if($auditRows.Count -eq 0) {
   Add-Gate "conservative-audit" "PENDING" "Conservative profile audit exists with 0 FAIL and 0 OPEN rows" "rows=0" $ConservativeAuditPath "Run work\write_trade_ready_conservative_audit.ps1."
} else {
   $auditFail = @($auditRows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" }).Count
   $auditOpen = @($auditRows | Where-Object { [string](Get-Value $_ "Status") -eq "OPEN" }).Count
   $auditPass = @($auditRows | Where-Object { [string](Get-Value $_ "Status") -eq "PASS" }).Count
   $status = if($auditFail -gt 0) { "FAIL" } elseif($auditOpen -gt 0) { "PENDING" } else { "PASS" }
   Add-Gate "conservative-audit" $status `
      "Conservative profile audit exists with 0 FAIL and 0 OPEN rows" `
      "pass=$auditPass; open=$auditOpen; fail=$auditFail" `
      $ConservativeAuditPath `
      "Close every open proof gap before live approval."
}

Add-DecisionCsvGate "model4-validation-decision" $ValidationDecisionPath `
   "Conservative validation decision has 0 FAIL and 0 PENDING gates" `
   "Return and import all staged Model4/fast/stress/broker-proxy reports."

Add-DecisionCsvGate "money-ready-efficiency-audit" $EfficiencyAuditPath `
   "Money-ready efficiency audit has 0 FAIL and 0 PENDING gates: broad evidence clears growth, return/drawdown, drawdown, no-red-window, PF, recovery, recent-data, and broker/stress targets" `
   "Return full exported MT5 reports and require the strategy to be both safe and worth the capital/time before live review."

$tradeRows = Read-CsvSafe $TradeQualityPath
$tradeActual = ""
if($tradeRows.Count -gt 0) {
   $trade = $tradeRows | Select-Object -First 1
   $tradeActual = "trades=$([string](Get-Value $trade 'Trades')); pending=$([string](Get-Value $trade 'GatePending')); fail=$([string](Get-Value $trade 'GateFail'))"
}
Add-SingleStatusGate "trade-quality-decision" $TradeQualityPath `
   "Trade-quality analyzer status is PASS with enough closed trades and acceptable PF/expectancy/loss/R/spread evidence" `
   $tradeActual `
   "Return conservative closed-trade logs and rerun work\analyze_trade_ready_conservative_trade_quality.ps1."

$monteRows = Read-CsvSafe $MonteCarloPath
$monteActual = ""
if($monteRows.Count -gt 0) {
   $monte = $monteRows | Select-Object -First 1
   $monteActual = "trials=$([string](Get-Value $monte 'Trials')); rTrades=$([string](Get-Value $monte 'RTrades')); pending=$([string](Get-Value $monte 'GatePending')); fail=$([string](Get-Value $monte 'GateFail')); failureRate=$([string](Get-Value $monte 'FailureRatePercent'))"
}
Add-SingleStatusGate "monte-carlo-trade-stress" $MonteCarloPath `
   "Monte Carlo trade-stress analyzer status is PASS under seeded slippage/delay/spread/missed-winner stress" `
   $monteActual `
   "Return conservative closed-trade logs with realized R and rerun work\analyze_trade_ready_conservative_monte_carlo.ps1."

$forwardRows = Read-CsvSafe $ForwardEvidencePath
$forwardActual = ""
if($forwardRows.Count -gt 0) {
   $forward = $forwardRows | Select-Object -First 1
   $forwardActual = "rows=$([string](Get-Value $forward 'Rows')); parsed=$([string](Get-Value $forward 'ParsedRows')); pending=$([string](Get-Value $forward 'GatePending')); fail=$([string](Get-Value $forward 'GateFail'))"
}
Add-SingleStatusGate "forward-paper-demo" $ForwardEvidencePath `
   "Forward paper/demo evidence status is PASS on a sufficiently long non-red sample" `
   $forwardActual `
   "Export paper/demo evidence to outputs\TRADE_READY_CONSERVATIVE_FORWARD_TEST_EVIDENCE.csv, then rerun work\analyze_trade_ready_conservative_forward_test.ps1."

$secondBrokerRows = Read-CsvSafe $SecondBrokerEvidencePath
$secondBrokerActual = ""
if($secondBrokerRows.Count -gt 0) {
   $secondBroker = $secondBrokerRows | Select-Object -First 1
   $secondBrokerActual = "rows=$([string](Get-Value $secondBroker 'Rows')); parsed=$([string](Get-Value $secondBroker 'ParsedRows')); pending=$([string](Get-Value $secondBroker 'GatePending')); fail=$([string](Get-Value $secondBroker 'GateFail'))"
}
Add-SingleStatusGate "second-broker-validation" $SecondBrokerEvidencePath `
   "Second-broker XAUUSD validation status is PASS on broker-specific symbol conditions" `
   $secondBrokerActual `
   "Export second-broker evidence to outputs\TRADE_READY_CONSERVATIVE_SECOND_BROKER_EVIDENCE.csv, then rerun work\analyze_trade_ready_conservative_second_broker.ps1."

$reproRows = Read-CsvSafe $ReproBundleManifestPath
$reproZipFullPath = Resolve-RepoPath $ReproBundleZipPath
$reproZipExists = Test-Path -LiteralPath $reproZipFullPath
if($reproRows.Count -eq 0) {
   Add-Gate "local-reproducibility-freeze" "PENDING" `
      "Local reproducibility bundle manifest exists, zip exists, required checks pass, and every bundle row is PASS" `
      "rows=0; zipExists=$reproZipExists" `
      "$ReproBundleManifestPath + $ReproBundleZipPath" `
      "Run work\build_trade_ready_reproducibility_bundle.ps1 after source/profile/status changes."
} else {
   $reproFail = @($reproRows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" }).Count
   $reproPending = @($reproRows | Where-Object { [string](Get-Value $_ "Status") -eq "PENDING" }).Count
   $reproPass = @($reproRows | Where-Object { [string](Get-Value $_ "Status") -eq "PASS" }).Count
   $requiredReproChecks = @(
      "source-root-mirror-hash-match",
      "conservative-evidence-identity",
      "conservative-real-account-lock",
      "money-ready-real-account-lock",
      "money-ready-alias-hash-match"
   )
   $missingRequiredReproChecks = @($requiredReproChecks | Where-Object {
      $checkName = $_
      @($reproRows | Where-Object {
         [string](Get-Value $_ "Kind") -eq "check" -and
         [string](Get-Value $_ "Role") -eq $checkName -and
         [string](Get-Value $_ "Status") -eq "PASS"
      }).Count -eq 0
   })
   $reproStatus = if($reproFail -gt 0 -or $missingRequiredReproChecks.Count -gt 0) {
      "FAIL"
   } elseif($reproPending -gt 0 -or !$reproZipExists) {
      "PENDING"
   } else {
      "PASS"
   }
   Add-Gate "local-reproducibility-freeze" $reproStatus `
      "Local reproducibility bundle manifest exists, zip exists, required checks pass, and every bundle row is PASS" `
      "rows=$($reproRows.Count); pass=$reproPass; pending=$reproPending; fail=$reproFail; zipExists=$reproZipExists; missingRequiredChecks=$($missingRequiredReproChecks.Count)" `
      "$ReproBundleManifestPath + $ReproBundleZipPath" `
      "Keep rebuilding the bundle after every source/profile/status change; this local freeze does not replace GitHub/source-publication sync."
}

$resolvedGitRoot = if([string]::IsNullOrWhiteSpace($GitRoot)) { $repo } else { Resolve-RepoPath $GitRoot }
$gitRequiredPaths = @($RootSourcePath, $MirrorSourcePath, $ProfilePath)
$gitState = Get-GitPublicationState $resolvedGitRoot $RepositoryFullName $gitRequiredPaths
$gitValid = [bool]$gitState.Valid
$publicationRows = Read-CsvSafe $GitHubPublicationSyncPath
$requiredPublicationRows = @($publicationRows | Where-Object { [string](Get-Value $_ "Required") -eq "True" })
$publicationPass = @($requiredPublicationRows | Where-Object { [string](Get-Value $_ "Status") -eq "PASS" }).Count
$publicationPending = @($requiredPublicationRows | Where-Object { [string](Get-Value $_ "Status") -eq "PENDING" }).Count
$publicationFail = @($requiredPublicationRows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" }).Count
$githubStatus = if($gitValid -or ($requiredPublicationRows.Count -gt 0 -and $publicationPending -eq 0 -and $publicationFail -eq 0)) {
   "PASS"
} elseif($publicationFail -gt 0) {
   "FAIL"
} else {
   "PENDING"
}
$githubActual = "gitValid=$gitValid; gitDetail=$($gitState.Detail); publicationRows=$($requiredPublicationRows.Count); publicationPass=$publicationPass; publicationPending=$publicationPending; publicationFail=$publicationFail"
Add-Gate "reproducible-github-sync" $githubStatus `
   "Either workspace is a clean pushed GitHub checkout with tracked required source/profile artifacts, or required source/profile artifacts match GitHub by SHA-256 through connector publication audit" `
   $githubActual `
   ".git + $GitHubPublicationSyncPath" `
   "Restore a valid Git checkout or publish exact source/profile artifacts through the connector until outputs\GITHUB_PUBLICATION_SYNC.md has zero required pending/fail rows."

$failed = @($rows | Where-Object Status -eq "FAIL")
$pending = @($rows | Where-Object Status -eq "PENDING")
$passed = @($rows | Where-Object Status -eq "PASS")
$overall = if($failed.Count -gt 0) { "FAIL" } elseif($pending.Count -gt 0) { "PENDING" } else { "PASS" }

$summary = [pscustomobject]@{
   Profile = "trade_ready_conservative"
   Status = $overall
   GatePass = $passed.Count
   GatePending = $pending.Count
   GateFail = $failed.Count
   ProfileHash = $profileHash
   SourceHash = $rootSourceHash
   PendingGates = (($pending | ForEach-Object { $_.Gate }) -join "; ")
   FailureGates = (($failed | ForEach-Object { $_.Gate }) -join "; ")
}

$outCsvPath = Resolve-RepoPath $OutCsv
$outMarkdownPath = Resolve-RepoPath $OutMarkdown
foreach($path in @($outCsvPath, $outMarkdownPath)) {
   $dir = Split-Path -Parent $path
   if($dir -and !(Test-Path -LiteralPath $dir)) {
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
   }
}

$rows | Export-Csv -LiteralPath $outCsvPath -NoTypeInformation -Encoding ASCII

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Trade-Ready Live Readiness Decision")
$md.Add("")
$md.Add(("Generated: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))
$md.Add("")
$md.Add(("- Overall: **{0}**" -f $overall))
$md.Add(('- Passing gates: `{0}`' -f $passed.Count))
$md.Add(('- Pending gates: `{0}`' -f $pending.Count))
$md.Add(('- Failed gates: `{0}`' -f $failed.Count))
$md.Add(('- Profile hash: `{0}`' -f $profileHash))
$md.Add(('- Source hash: `{0}`' -f $rootSourceHash))
$md.Add("")
$md.Add("This is the final approval gate for the conservative candidate. It does not launch MT5 and it does not unlock real-account trading.")
$md.Add("")
$md.Add("| Gate | Status | Required | Actual | Evidence | Next Action |")
$md.Add("| --- | --- | --- | --- | --- | --- |")
foreach($row in $rows) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} |" -f
      (Escape-MarkdownCell $row.Gate),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.Required),
      (Escape-MarkdownCell $row.Actual),
      (Escape-MarkdownCell $row.Evidence),
      (Escape-MarkdownCell $row.NextAction)))
}

$md.Add("")
$md.Add("## Bottom Line")
$md.Add("")
if($overall -eq "PASS") {
   $md.Add("The conservative profile has enough evidence for manual live-approval review. A separate real-account profile would still require explicit user approval.")
}
elseif($overall -eq "FAIL") {
   $md.Add("The conservative profile is not live-ready because at least one required gate failed.")
}
else {
   $md.Add("The conservative profile is not live-ready yet. Missing or stale proof remains, so real-account trading stays blocked.")
}

$md | Set-Content -LiteralPath $outMarkdownPath -Encoding ASCII

$summary
