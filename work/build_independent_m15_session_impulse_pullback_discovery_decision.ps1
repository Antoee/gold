param(
   [string]$QueuePath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$ReportDir = "outputs\independent_m15_session_impulse_pullback_discovery_model1_package\reports_here",
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$AttestationPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_RUN_ATTESTATION.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_DECISION.md",
   [string]$MetricsPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_METRICS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Format-Money([object]$Value) {
   $number = [double]$Value
   return $(if($number -ge 0.0) { "+" } else { "-" }) + '$' + [Math]::Abs($number).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}

$rawResults = Join-Path $repo "work\M15SIP_RAW_RESULTS.csv"
$rawSummary = Join-Path $repo "work\M15SIP_RAW_SUMMARY.csv"
$rawMarkdown = Join-Path $repo "work\M15SIP_RAW_METRICS.md"

try {
   & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
      -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
      -OutResults "work\M15SIP_RAW_RESULTS.csv" -OutSummary "work\M15SIP_RAW_SUMMARY.csv" `
      -OutMarkdown "work\M15SIP_RAW_METRICS.md" | Out-Null
   if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

   $queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
   $packageManifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath))
   $raw = @(Import-Csv -LiteralPath $rawResults)
   $rawByReport = @{}
   foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
   $packageByReport = @{}
   foreach($row in $packageManifest) { $packageByReport[[string]$row.ExpectedReportName] = $row }

   $reportRoot = Resolve-RepoPath $ReportDir
   $results = [Collections.Generic.List[object]]::new()
   $attestations = [Collections.Generic.List[object]]::new()
   foreach($item in ($queue | Sort-Object { [int]$_.QueueRank })) {
      $reportName = [string]$item.ExpectedReportName
      if(!$rawByReport.ContainsKey($reportName)) { throw "Collector row missing: $reportName" }
      if(!$packageByReport.ContainsKey($reportName)) { throw "Package manifest row missing: $reportName" }

      $parsed = $rawByReport[$reportName]
      $packageRow = $packageByReport[$reportName]
      $identityPath = Join-Path $reportRoot ($reportName + ".identity.json")
      if(!(Test-Path -LiteralPath $identityPath -PathType Leaf)) { throw "Report identity missing: $reportName" }
      $identity = Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json

      $reportPath = Resolve-RepoPath ([string]$parsed.ReportPath)
      if(!(Test-Path -LiteralPath $reportPath -PathType Leaf)) { throw "Report missing: $reportName" }
      $reportHash = (Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash.ToUpperInvariant()
      if($reportHash -ne ([string]$identity.ReportSha256).ToUpperInvariant()) { throw "Report hash mismatch: $reportName" }
      if((Get-Item -LiteralPath $reportPath).Length -ne [long]$identity.ReportBytes) { throw "Report byte count mismatch: $reportName" }

      $configPath = Resolve-RepoPath ([string]$packageRow.PackageConfig)
      if(!(Test-Path -LiteralPath $configPath -PathType Leaf)) { throw "Package config missing: $reportName" }
      $configHash = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant()
      if($configHash -ne ([string]$identity.ConfigSha256).ToUpperInvariant()) { throw "Config identity mismatch: $reportName" }
      if(([string]$identity.SourceSha256).ToUpperInvariant() -ne ([string]$item.SourceSha256).ToUpperInvariant()) {
         throw "Source identity mismatch: $reportName"
      }

      $attestations.Add([pscustomobject]@{
         QueueRank=$item.QueueRank; Candidate=$item.Candidate; Window=$item.Window
         ExpectedReportName=$reportName; Status="REPORT_FOUND"; ConfigSha256=$configHash
         SourceSha256=([string]$identity.SourceSha256).ToUpperInvariant()
         PortableBinarySha256=([string]$identity.PortableBinarySha256).ToUpperInvariant()
         ReportSha256=$reportHash; ReportBytes=[long]$identity.ReportBytes
         IdentityCreatedUtc=$identity.CreatedUtc
         Evidence="Exact portable report identity sidecar and report hash verified."
      }) | Out-Null

      $results.Add([pscustomobject]@{
         QueueRank=$item.QueueRank; Candidate=$item.Candidate; CandidateRank=$item.CandidateRank
         SourceType=$item.SourceType; SourceRank=$item.SourceRank; Phase=$item.Phase; Set=$item.Set
         Window=$item.Window; From=$item.From; To=$item.To; Model=$item.Model; Deposit=$item.Deposit
         Config=$item.Config; ExpectedReportName=$reportName; ProfileSnapshot=$item.ProfileSnapshot
         ProfileSha256=$item.ProfileSha256; SourceSha256=$item.SourceSha256
         SignalTimeframe=$item.SignalTimeframe; ObservationEndHour=$item.ObservationEndHour
         MinimumImpulseATR=$item.MinimumImpulseATR; MinimumEfficiency=$item.MinimumEfficiency
         MinimumDirectionalBarsPercent=$item.MinimumDirectionalBarsPercent
         MinimumPullbackRetracement=$item.MinimumPullbackRetracement
         MaximumPullbackRetracement=$item.MaximumPullbackRetracement
         PullbackLookbackBars=$item.PullbackLookbackBars; TakeProfitR=$item.TakeProfitR; StopRule=$item.StopRule
         Status=$parsed.Status; ReportPath=$parsed.ReportPath; ReportSha256=$reportHash
         ConfigSha256=$configHash; IdentityPath=$identityPath.Replace($repo + "\", "")
         IdentityCreatedUtc=$identity.CreatedUtc; PortableBinarySha256=$identity.PortableBinarySha256
         InitialDeposit=$parsed.InitialDeposit; CalendarDays=$parsed.CalendarDays; Years=$parsed.Years
         NetProfit=$parsed.NetProfit; Balance=$parsed.Balance; TotalReturnPercent=$parsed.TotalReturnPercent
         AnnualizedReturnPercent=$parsed.AnnualizedReturnPercent; CagrPercent=$parsed.CagrPercent
         ProfitFactor=$parsed.ProfitFactor; ExpectedPayoff=$parsed.ExpectedPayoff; SharpeRatio=$parsed.SharpeRatio
         WinRatePercent=$parsed.WinRatePercent; TotalTrades=$parsed.TotalTrades
         MaxConsecutiveLosses=$parsed.MaxConsecutiveLosses; MaxDrawdownMoney=$parsed.MaxDrawdownMoney
         MaxDrawdownPercent=$parsed.MaxDrawdownPercent; BalanceDrawdownMaximal=$parsed.BalanceDrawdownMaximal
         EquityDrawdownMaximal=$parsed.EquityDrawdownMaximal; RecoveryFactor=$parsed.RecoveryFactor
      }) | Out-Null
   }

   if($results.Count -ne 45 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) {
      throw "Expected 45 parsed discovery reports."
   }
   if(@($results | Where-Object { [int]$_.Model -ne 1 -or [double]$_.Deposit -ne 10000.0 }).Count -ne 0) {
      throw "Discovery contains a non-Model1 report or a deposit other than 10000."
   }
   $allowedWindows = @("older_2015_2018","discovery_2019_2020","continuous_2015_2020")
   if(@($results | Where-Object { $_.Window -notin $allowedWindows }).Count -ne 0) {
      throw "Discovery contains an unsealed or post-2020 window."
   }
   $sourceHashes = @($results.SourceSha256 | Sort-Object -Unique)
   $binaryHashes = @($results.PortableBinarySha256 | Sort-Object -Unique)
   if($sourceHashes.Count -ne 1 -or $binaryHashes.Count -ne 1) { throw "Exact source/binary identity is not uniform." }
   $sourcePath = Join-Path $PSScriptRoot "Independent_XAUUSD_M15_Session_Impulse_Pullback.mq5"
   if((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $sourceHashes[0].ToUpperInvariant()) {
      throw "Current source no longer matches the tested source identity."
   }
   $attestations | Export-Csv -LiteralPath (Resolve-RepoPath $AttestationPath) -NoTypeInformation -Encoding ASCII
   $results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

   $adjacency = @{
      sip_center=@('sip_end8','sip_end10','sip_impulse40','sip_impulse80','sip_eff35','sip_eff55','sip_dir45','sip_dir65','sip_minret10','sip_minret30','sip_maxret45','sip_maxret75','sip_lookback4','sip_lookback8')
      sip_end8=@('sip_center','sip_end10'); sip_end10=@('sip_center','sip_end8')
      sip_impulse40=@('sip_center','sip_impulse80'); sip_impulse80=@('sip_center','sip_impulse40')
      sip_eff35=@('sip_center','sip_eff55'); sip_eff55=@('sip_center','sip_eff35')
      sip_dir45=@('sip_center','sip_dir65'); sip_dir65=@('sip_center','sip_dir45')
      sip_minret10=@('sip_center','sip_minret30'); sip_minret30=@('sip_center','sip_minret10')
      sip_maxret45=@('sip_center','sip_maxret75'); sip_maxret75=@('sip_center','sip_maxret45')
      sip_lookback4=@('sip_center','sip_lookback8'); sip_lookback8=@('sip_center','sip_lookback4')
   }
   $numericPass = @{}
   $candidateRows = @{}
   foreach($group in ($results | Group-Object Candidate)) {
      $older = $group.Group | Where-Object Window -eq "older_2015_2018" | Select-Object -First 1
      $later = $group.Group | Where-Object Window -eq "discovery_2019_2020" | Select-Object -First 1
      $continuous = $group.Group | Where-Object Window -eq "continuous_2015_2020" | Select-Object -First 1
      if(!$older -or !$later -or !$continuous) { throw "Incomplete candidate windows: $($group.Name)" }
      $returnDrawdown = if([double]$continuous.MaxDrawdownMoney -gt 0.0) {
         [double]$continuous.NetProfit / [double]$continuous.MaxDrawdownMoney
      } else { 0.0 }
      $pass = [double]$older.NetProfit -gt 0.0 -and [double]$later.NetProfit -gt 0.0 -and `
              [double]$continuous.ProfitFactor -ge 1.20 -and [int]$continuous.TotalTrades -ge 80 -and `
              [double]$continuous.MaxDrawdownPercent -le 3.0 -and [double]$continuous.ExpectedPayoff -gt 0.0 -and `
              $returnDrawdown -ge 1.0
      $numericPass[$group.Name] = $pass
      $candidateRows[$group.Name] = [pscustomobject]@{ Older=$older; Later=$later; Continuous=$continuous; ReturnDrawdown=$returnDrawdown }
   }

   $summary = [Collections.Generic.List[object]]::new()
   foreach($candidate in ($candidateRows.Keys | Sort-Object)) {
      $set = $candidateRows[$candidate]
      $passingNeighbors = @($adjacency[$candidate] | Where-Object { $numericPass[$_] })
      $adjacentPass = $passingNeighbors.Count -gt 0
      $eligible = $numericPass[$candidate] -and $adjacentPass
      $summary.Add([pscustomobject]@{
         Candidate=$candidate; OlderNetProfit=$set.Older.NetProfit; OlderProfitFactor=$set.Older.ProfitFactor
         OlderTrades=$set.Older.TotalTrades; LaterNetProfit=$set.Later.NetProfit
         LaterProfitFactor=$set.Later.ProfitFactor; LaterTrades=$set.Later.TotalTrades
         ContinuousNetProfit=$set.Continuous.NetProfit; ContinuousCagrPercent=$set.Continuous.CagrPercent
         ContinuousProfitFactor=$set.Continuous.ProfitFactor; ContinuousTrades=$set.Continuous.TotalTrades
         ContinuousMaxDrawdownPercent=$set.Continuous.MaxDrawdownPercent
         ContinuousExpectedPayoff=$set.Continuous.ExpectedPayoff
         ReturnDrawdown=$set.ReturnDrawdown.ToString('F2',[Globalization.CultureInfo]::InvariantCulture)
         NumericPass=$numericPass[$candidate]; AdjacentPass=$adjacentPass
         PassingNeighbors=($passingNeighbors -join ';')
         Decision=$(if($eligible) { "DISCOVERY_ELIGIBLE" } else { "REJECT_BEFORE_HOLDOUT" })
      }) | Out-Null
   }
   $summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

   $numericPasses = @($summary | Where-Object NumericPass -eq $true)
   $eligibleRows = @($summary | Where-Object Decision -eq "DISCOVERY_ELIGIBLE")
   if($numericPasses.Count -ne 0 -or $eligibleRows.Count -ne 0) {
      throw "A profile unexpectedly passed; freeze it and review before opening holdout."
   }
   $resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash.ToUpperInvariant()
   $attestationHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $AttestationPath) -Algorithm SHA256).Hash.ToUpperInvariant()
   $decision = [pscustomobject]@{
      Status="REJECTED_IN_DISCOVERY"; Candidates=$summary.Count; ReportsParsed=$results.Count
      NumericPasses=0; DiscoveryEligible=0; HoldoutPermitted=$false; Model4Opened=$false; NewBest=$false
      SourceSha256=$sourceHashes[0]; PortableBinarySha256=$binaryHashes[0]
      ResultsSha256=$resultsHash; RunAttestationSha256=$attestationHash
   }
   $decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

   $md = [Collections.Generic.List[string]]::new()
   $md.Add("# Independent M15 Session Impulse-Pullback Discovery Decision")
   $md.Add("")
   $md.Add("**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**")
   $md.Add("")
   $md.Add('This standalone EA measured a fixed morning-session impulse using ATR magnitude, auction-path efficiency, directional-bar share, and close location. It then required a bounded pullback and completed M15 reclaim before entry. It retained broker-native risk sizing, minimum-lot refusal, a `$10,000` contract, account-wide exposure limits, daily/equity loss locks, one trade per day, and disabled real trading.')
   $md.Add("")
   $md.Add("- Source SHA-256: ``$($sourceHashes[0])``")
   $md.Add("- Exact report binary SHA-256: ``$($binaryHashes[0])``")
   $md.Add('- Controlled evidence: `45 / 45` Model 1 reports, one exact binary, zero report-hash failures')
   $md.Add('- Risk per accepted trade: `0.10%` on a `$10,000` test deposit')
   $md.Add('- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`')
   $md.Add('- Numeric gate passes: `0 / 15`')
   $md.Add('- Maximum continuous activity: `18` trades versus the required `80`')
   $md.Add("")
   $md.Add('| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |')
   $md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
   foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
      $md.Add("| ``$($row.Candidate)`` | $(Format-Money $row.OlderNetProfit) | $($row.OlderProfitFactor) | $($row.OlderTrades) | $(Format-Money $row.LaterNetProfit) | $($row.LaterProfitFactor) | $($row.LaterTrades) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.Decision) |")
   }
   $md.Add("")
   $md.Add("## Interpretation")
   $md.Add("")
   $md.Add('- The only profitable continuous variant, `sip_end8`, earned `+$33.91` but lost `-$15.08` in 2019-2020 and placed only `18` trades across six years.')
   $md.Add('- Twelve continuous variants lost money and two were flat. Signal inactivity is intrinsic to this frozen rule set, not a position-sizing or minimum-lot failure.')
   $md.Add('- Reject this family without inspecting 2021-2026 or spending real-tick time on it. Keep Three-Lane Trade-Ready RC2 ATB150 as the research best.')
   $md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

   @(
      '# Independent M15 Session Impulse-Pullback Discovery Metrics','',
      "- Parsed reports: ``$($results.Count) / $($queue.Count)``",
      "- Results SHA-256: ``$resultsHash``",
      "- Run attestation SHA-256: ``$attestationHash``",
      "- Source SHA-256: ``$($sourceHashes[0])``",
      "- Portable binary SHA-256: ``$($binaryHashes[0])``",
      '- Exact source identities: `1`','- Exact binary identities: `1`',
      '- Starting deposit: `$10,000` in every report','- Holdout opened: `NO`',
      '- Model 4 opened: `NO`','- New best: `NO`'
   ) | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII

   $decision
} finally {
   Remove-Item -LiteralPath $rawResults,$rawSummary,$rawMarkdown -Force -ErrorAction SilentlyContinue
}
