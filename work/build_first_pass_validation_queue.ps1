param(
   [string]$OutDir = "outputs\first_pass_validation_queue",
   [string]$OutManifest = "outputs\FIRST_PASS_VALIDATION_QUEUE.csv",
   [string]$OutMarkdown = "outputs\FIRST_PASS_VALIDATION_QUEUE.md",
   [string[]]$ActiveCandidates = @("trade_ready_conservative")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsDir = Join-Path $repo "outputs"

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$resolvedOutDir = Resolve-RepoPath $OutDir
$resolvedOutManifest = Resolve-RepoPath $OutManifest
$resolvedOutMarkdown = Resolve-RepoPath $OutMarkdown

function Copy-ConfigWithReport {
   param(
      [string]$SourceConfig,
      [string]$DestinationConfig,
      [string]$ReportPath
   )

   $content = Get-Content -LiteralPath $SourceConfig
   $rewritten = foreach($line in $content) {
      if($line -like "Report=*") {
         "Report=$ReportPath"
      } else {
         $line
      }
   }
   $rewritten | Set-Content -LiteralPath $DestinationConfig -Encoding ASCII
}

function Select-ManifestRows {
   param(
      [array]$Rows,
      [int[]]$Ranks
   )
   foreach($rank in $Ranks) {
      $row = $Rows | Where-Object { [int]$_.Rank -eq $rank } | Select-Object -First 1
      if($null -eq $row) {
         throw "Missing manifest rank $rank"
      }
      $row
   }
}

function Read-SetValue {
   param([string]$Path, [string]$Name)
   $prefix = "$Name="
   $line = Get-Content -LiteralPath $Path | Where-Object { $_ -like "$prefix*" } | Select-Object -First 1
   if(!$line) { return "" }
   $value = $line.Substring($prefix.Length)
   if($value.Contains("||")) {
      return ($value -split "\|\|", 2)[0]
   }
   return $value
}

function Assert-SelectedProfilesCurrent {
   param(
      [object[]]$Rows,
      [string]$Package,
      [string]$CandidateName,
      [string]$CurrentSourceHash
   )

   foreach($row in $Rows) {
      $snapshot = [string]$row.ProfileSnapshot
      if([string]::IsNullOrWhiteSpace($snapshot)) {
         throw "Refusing to build first-pass queue for ${CandidateName}: selected row $($row.Rank) has no ProfileSnapshot."
      }

      $profilePath = Join-Path $Package $snapshot
      if(!(Test-Path -LiteralPath $profilePath)) {
         throw "Refusing to build first-pass queue for ${CandidateName}: selected profile snapshot missing for row $($row.Rank): $profilePath"
      }

      $actualHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
      if($actualHash -ne [string]$row.ProfileSha256) {
         throw "Refusing to build first-pass queue for ${CandidateName}: selected row $($row.Rank) profile hash $actualHash does not match manifest hash $($row.ProfileSha256). Rebuild the package first."
      }

      $evidenceSourceHash = Read-SetValue -Path $profilePath -Name "InpEvidenceSourceHash"
      if($evidenceSourceHash -ne $CurrentSourceHash) {
         throw "Refusing to build first-pass queue for ${CandidateName}: selected row $($row.Rank) profile evidence source hash $evidenceSourceHash does not match current source hash $CurrentSourceHash."
      }

      $useSafetyLock = Read-SetValue -Path $profilePath -Name "InpUseRealAccountSafetyLock"
      $allowReal = Read-SetValue -Path $profilePath -Name "InpAllowRealAccountTrading"
      $approval = Read-SetValue -Path $profilePath -Name "InpRealAccountApprovalCode"
      if($useSafetyLock -ne "true" -or $allowReal -ne "false" -or $approval -ne "DISABLED") {
         throw "Refusing to build first-pass queue for ${CandidateName}: selected row $($row.Rank) profile is not real-account locked."
      }
   }
}

if(Test-Path -LiteralPath $resolvedOutDir) {
   $actualOutDir = (Resolve-Path -LiteralPath $resolvedOutDir).Path
   $actualOutputsDir = (Resolve-Path -LiteralPath $outputsDir).Path
   if(!$actualOutDir.StartsWith($actualOutputsDir, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to clean first-pass queue outside outputs: $actualOutDir"
   }
   Remove-Item -LiteralPath $actualOutDir -Recurse -Force
}

New-Item -ItemType Directory -Path $resolvedOutDir -Force | Out-Null

$availableCandidates = @(
   [pscustomobject]@{
      Candidate = "trade_ready_conservative"
      DisplayName = "Conservative Trade-Ready"
      BaseProfile = "outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set"
      ValidationPackage = "outputs\trade_ready_conservative_validation_package"
      ValidationManifest = "outputs\TRADE_READY_CONSERVATIVE_VALIDATION_MANIFEST.csv"
      BrokerPackage = "outputs\trade_ready_conservative_broker_proxy_package"
      BrokerManifest = "outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_MANIFEST.csv"
   },
   [pscustomobject]@{
      Candidate = "money_ready"
      DisplayName = "Money-Ready"
      BaseProfile = "outputs\CANDIDATE_MONEY_READY_PROFILE.set"
      ValidationPackage = "outputs\money_ready_validation_package"
      ValidationManifest = "outputs\MONEY_READY_VALIDATION_MANIFEST.csv"
      BrokerPackage = "outputs\money_ready_broker_proxy_package"
      BrokerManifest = "outputs\MONEY_READY_BROKER_PROXY_MANIFEST.csv"
   },
   [pscustomobject]@{
      Candidate = "lowatr_locked_research"
      DisplayName = "LowATR Locked Research"
      BaseProfile = "outputs\CANDIDATE_LOWATR_LOCKED_RESEARCH_PROFILE.set"
      ValidationPackage = "outputs\lowatr_locked_research_validation_package"
      ValidationManifest = "outputs\LOWATR_LOCKED_RESEARCH_VALIDATION_MANIFEST.csv"
      BrokerPackage = "outputs\lowatr_locked_research_broker_proxy_package"
      BrokerManifest = "outputs\LOWATR_LOCKED_RESEARCH_BROKER_PROXY_MANIFEST.csv"
   },
   [pscustomobject]@{
      Candidate = "lowatr_locked_risk20"
      DisplayName = "LowATR Locked Risk20"
      BaseProfile = "outputs\CANDIDATE_LOWATR_LOCKED_RISK20_PROFILE.set"
      ValidationPackage = "outputs\lowatr_locked_risk20_validation_package"
      ValidationManifest = "outputs\LOWATR_LOCKED_RISK20_VALIDATION_MANIFEST.csv"
      BrokerPackage = "outputs\lowatr_locked_risk20_broker_proxy_package"
      BrokerManifest = "outputs\LOWATR_LOCKED_RISK20_BROKER_PROXY_MANIFEST.csv"
   },
   [pscustomobject]@{
      Candidate = "lowatr_locked_risk23"
      DisplayName = "LowATR Locked Risk23"
      BaseProfile = "outputs\CANDIDATE_LOWATR_LOCKED_RISK23_PROFILE.set"
      ValidationPackage = "outputs\lowatr_locked_risk23_validation_package"
      ValidationManifest = "outputs\LOWATR_LOCKED_RISK23_VALIDATION_MANIFEST.csv"
      BrokerPackage = "outputs\lowatr_locked_risk23_broker_proxy_package"
      BrokerManifest = "outputs\LOWATR_LOCKED_RISK23_BROKER_PROXY_MANIFEST.csv"
   },
   [pscustomobject]@{
      Candidate = "lowatr_locked_risk23pure"
      DisplayName = "LowATR Locked Risk23 Pure"
      BaseProfile = "outputs\CANDIDATE_LOWATR_LOCKED_RISK23PURE_PROFILE.set"
      ValidationPackage = "outputs\lowatr_locked_risk23pure_validation_package"
      ValidationManifest = "outputs\LOWATR_LOCKED_RISK23PURE_VALIDATION_MANIFEST.csv"
      BrokerPackage = "outputs\lowatr_locked_risk23pure_broker_proxy_package"
      BrokerManifest = "outputs\LOWATR_LOCKED_RISK23PURE_BROKER_PROXY_MANIFEST.csv"
   },
   [pscustomobject]@{
      Candidate = "lowatr_locked_risk20pure"
      DisplayName = "LowATR Locked Risk20 Pure"
      BaseProfile = "outputs\CANDIDATE_LOWATR_LOCKED_RISK20PURE_PROFILE.set"
      ValidationPackage = "outputs\lowatr_locked_risk20pure_validation_package"
      ValidationManifest = "outputs\LOWATR_LOCKED_RISK20PURE_VALIDATION_MANIFEST.csv"
      BrokerPackage = "outputs\lowatr_locked_risk20pure_broker_proxy_package"
      BrokerManifest = "outputs\LOWATR_LOCKED_RISK20PURE_BROKER_PROXY_MANIFEST.csv"
   },
   [pscustomobject]@{
      Candidate = "lowatr_locked_risk18pure"
      DisplayName = "LowATR Locked Risk18 Pure"
      BaseProfile = "outputs\CANDIDATE_LOWATR_LOCKED_RISK18PURE_PROFILE.set"
      ValidationPackage = "outputs\lowatr_locked_risk18pure_validation_package"
      ValidationManifest = "outputs\LOWATR_LOCKED_RISK18PURE_VALIDATION_MANIFEST.csv"
      BrokerPackage = "outputs\lowatr_locked_risk18pure_broker_proxy_package"
      BrokerManifest = "outputs\LOWATR_LOCKED_RISK18PURE_BROKER_PROXY_MANIFEST.csv"
   }
)

$requestedCandidates = [System.Collections.Generic.List[string]]::new()
foreach($candidateName in $ActiveCandidates) {
   foreach($candidatePart in ([string]$candidateName -split ",")) {
      $candidatePart = $candidatePart.Trim()
      if($candidatePart -ne "" -and !$requestedCandidates.Contains($candidatePart)) {
         $requestedCandidates.Add($candidatePart) | Out-Null
      }
   }
}
$ActiveCandidates = @($requestedCandidates)

$knownCandidateNames = @($availableCandidates | ForEach-Object { $_.Candidate })
$unknownCandidates = @($ActiveCandidates | Where-Object { $knownCandidateNames -notcontains $_ })
if($unknownCandidates.Count -gt 0) {
   throw "Unknown first-pass active candidate(s): $($unknownCandidates -join ', '). Known candidates: $($knownCandidateNames -join ', ')"
}

$candidates = @($availableCandidates | Where-Object { $ActiveCandidates -contains $_.Candidate })
if($candidates.Count -eq 0) {
   throw "No active first-pass candidates selected."
}

$validationRanks = @(1,2,3,4,5,6,7,8,12,16,18,31,43,51,52,53)
$brokerRanks = @(1,2,3,5,7,9)
$queue = [System.Collections.Generic.List[object]]::new()
$currentSource = Resolve-RepoPath "Professional_XAUUSD_EA.mq5"
if(!(Test-Path -LiteralPath $currentSource)) {
   throw "Current root EA source not found: $currentSource"
}
$currentSourceHash = (Get-FileHash -LiteralPath $currentSource -Algorithm SHA256).Hash

foreach($candidate in $candidates) {
   $candidateDir = Join-Path $resolvedOutDir $candidate.Candidate
   $configDir = Join-Path $candidateDir "configs"
   $reportDir = Join-Path $candidateDir "reports_here"
   $sourceDir = Join-Path $candidateDir "source"
   $profileDir = Join-Path $candidateDir "profiles"
   New-Item -ItemType Directory -Path $configDir, $reportDir, $sourceDir, $profileDir -Force | Out-Null

   $validationPackage = Resolve-RepoPath $candidate.ValidationPackage
   $brokerPackage = Resolve-RepoPath $candidate.BrokerPackage
   $validationManifestPath = Resolve-RepoPath $candidate.ValidationManifest
   $brokerManifestPath = Resolve-RepoPath $candidate.BrokerManifest

    if(!(Test-Path -LiteralPath $validationManifestPath)) { throw "Missing validation manifest: $validationManifestPath" }
    if(!(Test-Path -LiteralPath $brokerManifestPath)) { throw "Missing broker manifest: $brokerManifestPath" }
    $packageSourcePath = Join-Path $validationPackage "source\Professional_XAUUSD_EA.mq5"
    if(!(Test-Path -LiteralPath $packageSourcePath)) { throw "Missing validation package source for $($candidate.Candidate): $packageSourcePath" }
    $packageSourceHash = (Get-FileHash -LiteralPath $packageSourcePath -Algorithm SHA256).Hash
    if($packageSourceHash -ne $currentSourceHash) {
       throw "Refusing to build first-pass queue for $($candidate.Candidate): validation package source hash $packageSourceHash does not match current root source hash $currentSourceHash. Rebuild the validation package first."
    }

    Copy-Item -LiteralPath $packageSourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force
   Get-ChildItem -LiteralPath (Join-Path $validationPackage "profiles") -Filter "*.set" -File | ForEach-Object {
      Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $profileDir $_.Name) -Force
   }
   Get-ChildItem -LiteralPath (Join-Path $brokerPackage "profiles") -Filter "*.set" -File | ForEach-Object {
      Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $profileDir $_.Name) -Force
   }

   $validationRows = @(Import-Csv -LiteralPath $validationManifestPath)
    $brokerRows = @(Import-Csv -LiteralPath $brokerManifestPath)
    $selectedValidation = @(Select-ManifestRows -Rows $validationRows -Ranks $validationRanks)
    $selectedBroker = @(Select-ManifestRows -Rows $brokerRows -Ranks $brokerRanks)
    Assert-SelectedProfilesCurrent -Rows $selectedValidation -Package $validationPackage -CandidateName $candidate.Candidate -CurrentSourceHash $currentSourceHash
    Assert-SelectedProfilesCurrent -Rows $selectedBroker -Package $brokerPackage -CandidateName $candidate.Candidate -CurrentSourceHash $currentSourceHash

   $candidateQueueRank = 0
   foreach($sourceGroup in @(
      [pscustomobject]@{ SourceType = "validation"; Package = $validationPackage; Rows = $selectedValidation },
      [pscustomobject]@{ SourceType = "broker_proxy"; Package = $brokerPackage; Rows = $selectedBroker }
   )) {
      foreach($row in $sourceGroup.Rows) {
         $candidateQueueRank++
         $globalRank = $queue.Count + 1
         $sourceConfig = Join-Path $sourceGroup.Package $row.Config
         $configName = "{0:000}_{1}_{2}_{3}.ini" -f $candidateQueueRank, $candidate.Candidate, $sourceGroup.SourceType, $row.Window
         $destConfig = Join-Path $configDir $configName
         $reportName = "first_pass_{0}_{1:000}_{2}_{3}" -f $candidate.Candidate, $candidateQueueRank, $sourceGroup.SourceType, $row.Window
         $reportPath = Join-Path $reportDir $reportName
         Copy-ConfigWithReport -SourceConfig $sourceConfig -DestinationConfig $destConfig -ReportPath $reportPath

         $phase = [string]$row.Phase
         $stopRule = if($phase -eq "phase0_fast_model1") {
            "Stop this candidate if fast Model1 is red or produces too few trades."
         } elseif($phase -eq "phase1_exact_realtick") {
            "Stop this candidate if exact real-tick full/OOS/recent windows are red or drawdown/PF is unacceptable."
         } elseif($phase -eq "phase2_realtick_quarterly" -or $phase -eq "phase3_realtick_monthly") {
            "Stop this candidate if fragile seasonal windows fail."
         } elseif($phase -eq "phase4_stress_realtick" -or $phase -eq "phase5_broker_proxy_realtick") {
            "Stop this candidate if stress/broker proxy turns red."
         } else {
            "Review before continuing."
         }

         $queue.Add([pscustomobject]@{
            QueueRank = $globalRank
            Candidate = $candidate.Candidate
            CandidateRank = $candidateQueueRank
            SourceType = $sourceGroup.SourceType
            SourceRank = $row.Rank
            Phase = $row.Phase
            Set = $row.Set
            Window = $row.Window
            From = $row.From
            To = $row.To
            Model = $row.Model
            Config = ("{0}\configs\{1}" -f $candidate.Candidate, $configName)
            ExpectedReportName = $reportName
            ProfileSnapshot = $row.ProfileSnapshot
            ProfileSha256 = $row.ProfileSha256
            StopRule = $stopRule
         }) | Out-Null
      }
   }

   $candidateRows = @($queue | Where-Object { $_.Candidate -eq $candidate.Candidate })
   $candidateRows | Export-Csv -LiteralPath (Join-Path $candidateDir "FIRST_PASS_VALIDATION_QUEUE.csv") -NoTypeInformation
}

$queue | Export-Csv -LiteralPath $resolvedOutManifest -NoTypeInformation

$firstCandidateName = [string]$candidates[0].Candidate
$sourceHash = (Get-FileHash -LiteralPath (Join-Path $resolvedOutDir "$firstCandidateName\source\Professional_XAUUSD_EA.mq5") -Algorithm SHA256).Hash
$activeCandidateNames = (($candidates | ForEach-Object { $_.Candidate }) -join ", ")
$availableCandidateNames = ($knownCandidateNames -join ", ")
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# First-Pass Validation Queue")
$md.Add("")
$md.Add("Offline queue only. This does not launch MT5.")
$md.Add("")
$md.Add("- EA source hash: ``$sourceHash``")
$md.Add("- Total configs: ``$($queue.Count)``")
$md.Add("- Per candidate: ``22``")
$md.Add("- Active candidates: ``$activeCandidateNames``")
$md.Add("- Available candidates: ``$availableCandidateNames``")
$md.Add("")
$md.Add("## Purpose")
$md.Add("")
$md.Add("Run this queue before the full 53-config validation packages. It is designed to reject weak candidates faster without weakening the full live-readiness gate. By default it focuses on the current scorecard candidate; pass ``-ActiveCandidates trade_ready_conservative,money_ready`` only when a deliberate comparison run is worth the extra tester time.")
$md.Add("")
$md.Add("## Run Order")
$md.Add("")
$md.Add("1. Fast Model1 sanity: ranks 1-4 from the full package.")
$md.Add("2. Exact real-tick proof: continuous, 2024 train, 2025 OOS, and 2026 YTD.")
$md.Add("3. Fragile seasonal checks: Q4 2024, Q4 2025, Q2 2026, December 2024, and December 2025.")
$md.Add("4. Stress checks: spread, cost, and tight-execution full-period stress.")
$md.Add("5. Broker proxy checks: base full/recent plus wide-spread, high-commission, tight-slippage, and margin-pressure full-period proxies.")
$md.Add("")
$md.Add("## Rule")
$md.Add("")
$md.Add("Passing this queue is not live approval. It only earns the right to spend time on the full validation packages.")
$md.Add("")
$md.Add("## Report Import And Decision")
$md.Add("")
$md.Add("After MT5 exports the queued reports into each candidate's ``reports_here`` folder, run:")
$md.Add("")
$md.Add("``````powershell")
$md.Add("powershell -NoProfile -ExecutionPolicy Bypass -File work\import_first_pass_validation_queue_reports.ps1")
$md.Add("``````")
$md.Add("")
$md.Add("Then read ``outputs/FIRST_PASS_VALIDATION_QUEUE_DECISION.md`` and ``outputs/FIRST_PASS_VALIDATION_QUEUE_CANDIDATE_RANKING.csv``. Use ``work\select_first_pass_next_run_batch.ps1`` to write ``outputs/FIRST_PASS_NEXT_RUN_BATCH.md`` after every import, so only the next useful stage is run. A passing first-pass decision is still not live approval; it only permits the slower full validation packages.")
$md.Add("")
$md.Add("| Rank | Candidate | Source | Phase | Window | Model | Config | Stop Rule |")
$md.Add("| ---: | --- | --- | --- | --- | ---: | --- | --- |")
foreach($row in $queue) {
   $md.Add("| $($row.QueueRank) | $($row.Candidate) | $($row.SourceType) | $($row.Phase) | $($row.Window) | $($row.Model) | ``$($row.Config)`` | $($row.StopRule) |")
}
$md | Set-Content -LiteralPath $resolvedOutMarkdown -Encoding ASCII

[pscustomobject]@{
   Status = "PASS"
   Rows = $queue.Count
   PerCandidate = 22
   ActiveCandidates = $activeCandidateNames
   OutDir = $OutDir
   OutManifest = $OutManifest
   OutMarkdown = $OutMarkdown
}
