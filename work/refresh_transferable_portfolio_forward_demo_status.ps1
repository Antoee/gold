[CmdletBinding()]
param(
   [string]$RegistrationPath = "",
   [string]$SentinelRegistrationPath = "",
   [string]$StatusCsvPath = "",
   [string]$StatusMarkdownPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
if([string]::IsNullOrWhiteSpace($RegistrationPath)) {
   $RegistrationPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_REGISTRATION.json"
}
if([string]::IsNullOrWhiteSpace($SentinelRegistrationPath)) {
   $SentinelRegistrationPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_FORWARD_SENTINEL_REGISTRATION.json"
}
if([string]::IsNullOrWhiteSpace($StatusCsvPath)) {
   $StatusCsvPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.csv"
}
if([string]::IsNullOrWhiteSpace($StatusMarkdownPath)) {
   $StatusMarkdownPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.md"
}

function Resolve-WorkspacePath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([System.IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $workspaceRoot ($Path -replace '/', '\')
}

function Get-Sha256 {
   param([Parameter(Mandatory=$true)][string]$Path)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return "MISSING" }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Format-Number {
   param([double]$Value, [int]$Digits = 2)
   return $Value.ToString("F$Digits", [System.Globalization.CultureInfo]::InvariantCulture)
}

function Format-Percent {
   param([double]$Value, [int]$Digits = 2)
   return (Format-Number -Value $Value -Digits $Digits) + "%"
}

function Parse-EvidenceFile {
   param(
      [Parameter(Mandatory=$true)][string]$Path,
      [Parameter(Mandatory=$true)][string]$Lane,
      [Parameter(Mandatory=$true)][string]$ExpectedProfile,
      [Parameter(Mandatory=$true)][string]$ExpectedSourceHash,
      [Parameter(Mandatory=$true)][string]$ExpectedRunLabel
   )

   $rows = [System.Collections.Generic.List[object]]::new()
   $invalidRows = 0
   $foreignRows = 0
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) {
      return [pscustomobject]@{ Exists=$false; Rows=$rows; InvalidRows=0; ForeignRows=0; Length=0; LastWriteTime=$null }
   }

   $item = Get-Item -LiteralPath $Path
   foreach($line in @(Get-Content -LiteralPath $Path -ErrorAction Stop)) {
      if([string]::IsNullOrWhiteSpace($line)) { continue }
      $fields = $line -split "`t", 13
      if($fields.Count -ne 13) {
         $invalidRows++
         continue
      }

      $timestamp = [datetime]::MinValue
      $profit = 0.0
      $timestampOk = [datetime]::TryParseExact(
         $fields[0],
         "yyyy.MM.dd HH:mm:ss",
         [System.Globalization.CultureInfo]::InvariantCulture,
         [System.Globalization.DateTimeStyles]::AssumeLocal,
         [ref]$timestamp)
      $profitOk = [double]::TryParse(
         $fields[8],
         [System.Globalization.NumberStyles]::Float,
         [System.Globalization.CultureInfo]::InvariantCulture,
         [ref]$profit)
      if(!$timestampOk -or !$profitOk -or $fields[1] -notin @("entry", "exit")) {
         $invalidRows++
         continue
      }

      if($fields[10] -ne $ExpectedProfile -or
         $fields[11].ToUpperInvariant() -ne $ExpectedSourceHash.ToUpperInvariant() -or
         $fields[12] -ne $ExpectedRunLabel) {
         $foreignRows++
         continue
      }

      [void]$rows.Add([pscustomobject]@{
         Timestamp = $timestamp
         Event = $fields[1]
         Symbol = $fields[2]
         Ticket = $fields[3]
         Side = $fields[4]
         Volume = $fields[5]
         Price = $fields[6]
         StopLoss = $fields[7]
         Profit = $profit
         Reason = $fields[9]
         Profile = $fields[10]
         SourceHash = $fields[11]
         RunLabel = $fields[12]
         Lane = $Lane
      })
   }

   return [pscustomobject]@{
      Exists = $true
      Rows = $rows
      InvalidRows = $invalidRows
      ForeignRows = $foreignRows
      Length = $item.Length
      LastWriteTime = $item.LastWriteTime
   }
}

function Parse-SentinelHeartbeat {
   param([Parameter(Mandatory=$true)][string]$Path)

   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) {
      return [pscustomobject]@{ Exists=$false; Valid=$false; Length=0; LastWriteTime=$null; Row=$null; Error="missing" }
   }

   $item = Get-Item -LiteralPath $Path
   try {
      $rows = @(Import-Csv -LiteralPath $Path -Delimiter "`t")
      if($rows.Count -ne 1) {
         return [pscustomobject]@{ Exists=$true; Valid=$false; Length=$item.Length; LastWriteTime=$item.LastWriteTime; Row=$null; Error="expected one heartbeat row" }
      }
      $row = $rows[0]
      $required = @(
         "local_time", "server_time", "run_label", "source_sha256", "profile_sha256",
         "account_trade_mode", "margin_mode", "connected", "terminal_trade_allowed",
         "account_trade_allowed", "account_expert_allowed", "mql_trade_allowed",
         "expected_symbol", "balance", "equity", "all_positions", "candidate_positions",
         "all_unprotected_positions", "candidate_unprotected_positions",
         "candidate_open_risk_percent"
      )
      foreach($name in $required) {
         if($row.PSObject.Properties.Name -notcontains $name) {
            return [pscustomobject]@{ Exists=$true; Valid=$false; Length=$item.Length; LastWriteTime=$item.LastWriteTime; Row=$null; Error="missing field $name" }
         }
      }

      $localTime = [datetime]::MinValue
      if(![datetime]::TryParseExact($row.local_time, "yyyy.MM.dd HH:mm:ss",
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeLocal, [ref]$localTime)) {
         return [pscustomobject]@{ Exists=$true; Valid=$false; Length=$item.Length; LastWriteTime=$item.LastWriteTime; Row=$null; Error="invalid local_time" }
      }
      $balance = 0.0
      $equity = 0.0
      $openRisk = 0.0
      $allPositions = 0
      $candidatePositions = 0
      $allUnprotected = 0
      $candidateUnprotected = 0
      $culture = [System.Globalization.CultureInfo]::InvariantCulture
      $numberStyle = [System.Globalization.NumberStyles]::Float
      $integerStyle = [System.Globalization.NumberStyles]::Integer
      $numericPass = [double]::TryParse($row.balance, $numberStyle, $culture, [ref]$balance) -and
                     [double]::TryParse($row.equity, $numberStyle, $culture, [ref]$equity) -and
                     [double]::TryParse($row.candidate_open_risk_percent, $numberStyle, $culture, [ref]$openRisk) -and
                     [int]::TryParse($row.all_positions, $integerStyle, $culture, [ref]$allPositions) -and
                     [int]::TryParse($row.candidate_positions, $integerStyle, $culture, [ref]$candidatePositions) -and
                     [int]::TryParse($row.all_unprotected_positions, $integerStyle, $culture, [ref]$allUnprotected) -and
                     [int]::TryParse($row.candidate_unprotected_positions, $integerStyle, $culture, [ref]$candidateUnprotected)
      if(!$numericPass) {
         return [pscustomobject]@{ Exists=$true; Valid=$false; Length=$item.Length; LastWriteTime=$item.LastWriteTime; Row=$null; Error="invalid numeric field" }
      }

      $typed = [pscustomobject]@{
         LocalTime = $localTime
         ServerTime = $row.server_time
         RunLabel = $row.run_label
         SourceHash = $row.source_sha256.ToUpperInvariant()
         ProfileHash = $row.profile_sha256.ToUpperInvariant()
         AccountTradeMode = $row.account_trade_mode
         MarginMode = $row.margin_mode
         Connected = $row.connected -eq "true"
         TerminalTradeAllowed = $row.terminal_trade_allowed -eq "true"
         AccountTradeAllowed = $row.account_trade_allowed -eq "true"
         AccountExpertAllowed = $row.account_expert_allowed -eq "true"
         MqlTradeAllowed = $row.mql_trade_allowed -eq "true"
         ExpectedSymbol = $row.expected_symbol
         Balance = $balance
         Equity = $equity
         AllPositions = $allPositions
         CandidatePositions = $candidatePositions
         AllUnprotectedPositions = $allUnprotected
         CandidateUnprotectedPositions = $candidateUnprotected
         CandidateOpenRiskPercent = $openRisk
      }
      return [pscustomobject]@{ Exists=$true; Valid=$true; Length=$item.Length; LastWriteTime=$item.LastWriteTime; Row=$typed; Error="" }
   }
   catch {
      return [pscustomobject]@{ Exists=$true; Valid=$false; Length=$item.Length; LastWriteTime=$item.LastWriteTime; Row=$null; Error=$_.Exception.Message }
   }
}

if(!(Test-Path -LiteralPath $RegistrationPath -PathType Leaf)) {
   throw "Forward registration is missing: $RegistrationPath"
}
if(!(Test-Path -LiteralPath $SentinelRegistrationPath -PathType Leaf)) {
   throw "Sentinel registration is missing: $SentinelRegistrationPath"
}

$registration = Get-Content -Raw -LiteralPath $RegistrationPath | ConvertFrom-Json
$sentinelRegistration = Get-Content -Raw -LiteralPath $SentinelRegistrationPath | ConvertFrom-Json
$sourcePath = Resolve-WorkspacePath -Path $registration.sourcePath
$profilePath = Resolve-WorkspacePath -Path $registration.profilePath
$sentinelSourcePath = Resolve-WorkspacePath -Path $sentinelRegistration.sourcePath
$sentinelProfilePath = Resolve-WorkspacePath -Path $sentinelRegistration.profilePath
$terminalRoot = Join-Path $env:APPDATA "MetaQuotes\Terminal"
$commonFilesRoot = Join-Path $terminalRoot "Common\Files"
$rvLogPath = Join-Path $commonFilesRoot $registration.reversionLogFile
$moLogPath = Join-Path $commonFilesRoot $registration.momentumLogFile
$sentinelHeartbeatPath = Join-Path $commonFilesRoot $sentinelRegistration.heartbeatFile

$sourceHash = Get-Sha256 -Path $sourcePath
$profileHash = Get-Sha256 -Path $profilePath
$sourceHashMatch = $sourceHash -eq $registration.sourceSha256
$profileHashMatch = $profileHash -eq $registration.profileSha256
$sentinelSourceHash = Get-Sha256 -Path $sentinelSourcePath
$sentinelProfileHash = Get-Sha256 -Path $sentinelProfilePath
$sentinelSourceHashMatch = $sentinelSourceHash -eq $sentinelRegistration.sourceSha256
$sentinelProfileHashMatch = $sentinelProfileHash -eq $sentinelRegistration.profileSha256

$installedBinaryMatches = [System.Collections.Generic.List[string]]::new()
if(Test-Path -LiteralPath $terminalRoot -PathType Container) {
   foreach($binary in @(Get-ChildItem -LiteralPath $terminalRoot -Recurse -File -Filter "Professional_XAUUSD_Transferable_Portfolio.ex5" -ErrorAction SilentlyContinue)) {
      if((Get-Sha256 -Path $binary.FullName) -eq $registration.installedBinarySha256) {
         [void]$installedBinaryMatches.Add($binary.FullName)
      }
   }
}
$binaryHashMatch = $installedBinaryMatches.Count -gt 0
$installedSentinelBinaryMatches = [System.Collections.Generic.List[string]]::new()
if(Test-Path -LiteralPath $terminalRoot -PathType Container) {
   foreach($binary in @(Get-ChildItem -LiteralPath $terminalRoot -Recurse -File -Filter "Professional_XAUUSD_Forward_Sentinel.ex5" -ErrorAction SilentlyContinue)) {
      if((Get-Sha256 -Path $binary.FullName) -eq $sentinelRegistration.installedBinarySha256) {
         [void]$installedSentinelBinaryMatches.Add($binary.FullName)
      }
   }
}
$sentinelBinaryHashMatch = $installedSentinelBinaryMatches.Count -gt 0
$sentinelHeartbeat = Parse-SentinelHeartbeat -Path $sentinelHeartbeatPath

$rvEvidence = Parse-EvidenceFile -Path $rvLogPath -Lane "reversion" -ExpectedProfile "tlp_rv_m12" `
   -ExpectedSourceHash $registration.sourceSha256 -ExpectedRunLabel $registration.runLabel
$moEvidence = Parse-EvidenceFile -Path $moLogPath -Lane "momentum" -ExpectedProfile "tlp_mom_e20" `
   -ExpectedSourceHash $registration.sourceSha256 -ExpectedRunLabel $registration.runLabel

$allRows = @($rvEvidence.Rows) + @($moEvidence.Rows)
$entries = @($allRows | Where-Object Event -eq "entry" | Sort-Object Timestamp)
$exits = @($allRows | Where-Object Event -eq "exit" | Sort-Object Timestamp)
$wins = @($exits | Where-Object Profit -gt 0.0)
$losses = @($exits | Where-Object Profit -lt 0.0)
$breakeven = @($exits | Where-Object Profit -eq 0.0)
$netProfit = if($exits.Count -gt 0) { [double](($exits | Measure-Object -Property Profit -Sum).Sum) } else { 0.0 }
$grossProfit = if($wins.Count -gt 0) { [double](($wins | Measure-Object -Property Profit -Sum).Sum) } else { 0.0 }
$grossLoss = if($losses.Count -gt 0) { [math]::Abs([double](($losses | Measure-Object -Property Profit -Sum).Sum)) } else { 0.0 }
$profitFactor = if($grossLoss -gt 0.0) { $grossProfit / $grossLoss } elseif($grossProfit -gt 0.0) { [double]::PositiveInfinity } else { 0.0 }
$winRate = if($exits.Count -gt 0) { 100.0 * $wins.Count / $exits.Count } else { 0.0 }
$expectancy = if($exits.Count -gt 0) { $netProfit / $exits.Count } else { 0.0 }

$currentLossStreak = 0
$maximumLossStreak = 0
$equity = [double]$registration.startingBalance
$peakEquity = $equity
$maximumClosedDrawdownPercent = 0.0
foreach($exit in $exits) {
   if($exit.Profit -lt 0.0) {
      $currentLossStreak++
      if($currentLossStreak -gt $maximumLossStreak) { $maximumLossStreak = $currentLossStreak }
   }
   else {
      $currentLossStreak = 0
   }

   $equity += $exit.Profit
   if($equity -gt $peakEquity) { $peakEquity = $equity }
   if($peakEquity -gt 0.0) {
      $drawdownPercent = 100.0 * ($peakEquity - $equity) / $peakEquity
      if($drawdownPercent -gt $maximumClosedDrawdownPercent) {
         $maximumClosedDrawdownPercent = $drawdownPercent
      }
   }
}

$now = Get-Date
$registeredAt = [datetimeoffset]::Parse($registration.registeredAtLocal, [System.Globalization.CultureInfo]::InvariantCulture)
$calendarDays = [math]::Max(0.0, ([datetimeoffset]$now - $registeredAt).TotalDays)
$minimumDaysMet = $calendarDays -ge [double]$registration.minimumCalendarDays
$minimumTradesMet = $exits.Count -ge [int]$registration.minimumClosedTrades
$sampleComplete = $minimumDaysMet -and $minimumTradesMet
$candidateIdentityPass = $sourceHashMatch -and $profileHashMatch -and $binaryHashMatch
$sentinelRegistrationIdentityPass =
   $sentinelRegistration.candidateSourceSha256 -eq $registration.sourceSha256 -and
   $sentinelRegistration.candidateProfileSha256 -eq $registration.profileSha256 -and
   $sentinelRegistration.runLabel -eq $registration.runLabel -and
   $sentinelRegistration.expectedSymbol -eq $registration.symbol
$sentinelCodeIdentityPass = $sentinelSourceHashMatch -and $sentinelProfileHashMatch -and `
   $sentinelBinaryHashMatch -and $sentinelRegistrationIdentityPass
$identityPass = $candidateIdentityPass -and $sentinelCodeIdentityPass
$evidenceFilesPass = $rvEvidence.Exists -and $moEvidence.Exists
$foreignRows = $rvEvidence.ForeignRows + $moEvidence.ForeignRows
$invalidRows = $rvEvidence.InvalidRows + $moEvidence.InvalidRows
$evidenceIdentityPass = $foreignRows -eq 0
$terminalProcesses = @(Get-Process -Name "terminal64" -ErrorAction SilentlyContinue)
$terminalRunning = $terminalProcesses.Count -gt 0

$sentinelHeartbeatValid = $sentinelHeartbeat.Valid
$sentinelHeartbeatFresh = $false
$sentinelHeartbeatAgeSeconds = -1.0
$sentinelHeartbeatIdentityPass = $false
$accountTradeMode = "unknown"
$marginMode = "unknown"
$connected = $false
$terminalTradeAllowed = $false
$accountTradeAllowed = $false
$accountExpertAllowed = $false
$mqlTradeAllowed = $false
$actualBalance = [double]::NaN
$actualEquity = [double]::NaN
$allPositions = -1
$candidatePositions = -1
$allUnprotectedPositions = -1
$candidateUnprotectedPositions = -1
$candidateOpenRiskPercent = [double]::NaN
$expectedBalance = [double]$registration.startingBalance + $netProfit
$accountModePass = $false
$balanceContractPass = $false
$positionIsolationPass = $false
$protectionPass = $false
$openRiskPass = $false
$operationalPass = $false
$accountContractPass = $false

if($sentinelHeartbeatValid) {
   $heartbeatRow = $sentinelHeartbeat.Row
   $sentinelHeartbeatAgeSeconds = [math]::Max(0.0, ($now - $heartbeatRow.LocalTime).TotalSeconds)
   $sentinelHeartbeatFresh = $sentinelHeartbeatAgeSeconds -le [double]$sentinelRegistration.maximumHeartbeatAgeSeconds
   $sentinelHeartbeatIdentityPass =
      $heartbeatRow.RunLabel -eq $sentinelRegistration.runLabel -and
      $heartbeatRow.SourceHash -eq $sentinelRegistration.candidateSourceSha256 -and
      $heartbeatRow.ProfileHash -eq $sentinelRegistration.candidateProfileSha256 -and
      $heartbeatRow.ExpectedSymbol -eq $sentinelRegistration.expectedSymbol

   $accountTradeMode = $heartbeatRow.AccountTradeMode
   $marginMode = $heartbeatRow.MarginMode
   $connected = $heartbeatRow.Connected
   $terminalTradeAllowed = $heartbeatRow.TerminalTradeAllowed
   $accountTradeAllowed = $heartbeatRow.AccountTradeAllowed
   $accountExpertAllowed = $heartbeatRow.AccountExpertAllowed
   $mqlTradeAllowed = $heartbeatRow.MqlTradeAllowed
   $actualBalance = $heartbeatRow.Balance
   $actualEquity = $heartbeatRow.Equity
   $allPositions = $heartbeatRow.AllPositions
   $candidatePositions = $heartbeatRow.CandidatePositions
   $allUnprotectedPositions = $heartbeatRow.AllUnprotectedPositions
   $candidateUnprotectedPositions = $heartbeatRow.CandidateUnprotectedPositions
   $candidateOpenRiskPercent = $heartbeatRow.CandidateOpenRiskPercent

   $accountModePass = $accountTradeMode -eq "demo" -and $marginMode -eq "hedging"
   $balanceContractPass = [math]::Abs($actualBalance - $expectedBalance) -le 1.0
   $positionIsolationPass = $allPositions -eq $candidatePositions
   $protectionPass = $allUnprotectedPositions -eq 0 -and $candidateUnprotectedPositions -eq 0
   $openRiskPass = $candidateOpenRiskPercent -le ([double]$registration.maximumPortfolioOpenRiskPercent + 0.000001)
   $operationalPass = $connected -and $terminalTradeAllowed -and $accountTradeAllowed -and `
      $accountExpertAllowed -and $mqlTradeAllowed
   $accountContractPass = $accountModePass -and $balanceContractPass -and `
      $positionIsolationPass -and $protectionPass -and $openRiskPass
}

$profitGatePass = $netProfit -gt 0.0
$profitFactorGatePass = $profitFactor -ge [double]$registration.minimumProfitFactor
$drawdownGatePass = $maximumClosedDrawdownPercent -le [double]$registration.maximumClosedTradeDrawdownPercent
$lossStreakGatePass = $maximumLossStreak -le [int]$registration.maximumConsecutiveLosses

if(!$identityPass -or !$evidenceFilesPass -or !$evidenceIdentityPass) {
   $status = "FAIL"
   $decision = "Frozen candidate, sentinel, or evidence identity failed. Stop the monitor and inspect before continuing."
}
elseif($sentinelHeartbeatValid -and !$sentinelHeartbeatIdentityPass) {
   $status = "FAIL"
   $decision = "The sentinel heartbeat does not belong to the frozen forward run. Stop and restore the registered monitor identity."
}
elseif($sentinelHeartbeatValid -and !$accountContractPass) {
   $status = "FAIL"
   if(!$balanceContractPass) {
      $decision = "The live demo balance does not match the frozen starting-capital contract. This sample is invalid; move the unchanged candidate to a correctly capitalized demo before any trades occur."
   }
   else {
      $decision = "The demo account mode, position isolation, stop protection, or open-risk contract failed. This sample is invalid until the frozen safety conditions are restored."
   }
}
elseif(!$terminalRunning -or !$sentinelHeartbeatValid -or !$sentinelHeartbeatFresh -or !$operationalPass) {
   $status = "ATTENTION"
   $decision = "The frozen evidence is intact, but MT5 or its read-only sentinel is not currently healthy. Restore the same registered monitor without changing the profile."
}
elseif(!$sampleComplete) {
   $status = "PENDING"
   $decision = "Keep the profile frozen. No performance conclusion is allowed before both the time and trade-count gates are met."
}
elseif($profitGatePass -and $profitFactorGatePass -and $drawdownGatePass -and $lossStreakGatePass) {
   $status = "PASS"
   $decision = "The first forward gate passed. This supports a second-broker demo and does not authorize real-money trading."
}
else {
   $status = "FAIL"
   $decision = "The completed forward sample failed at least one preregistered performance gate. Do not retune this run; retire or separately research a new version."
}

$lastEvent = if($allRows.Count -gt 0) { ($allRows | Sort-Object Timestamp | Select-Object -Last 1).Timestamp } else { $null }
$profitFactorText = if([double]::IsPositiveInfinity($profitFactor)) { "INF" } else { Format-Number -Value $profitFactor -Digits 2 }
$lastEventText = if($null -eq $lastEvent) { "none" } else { $lastEvent.ToString("yyyy-MM-dd HH:mm:ss") }
$updatedText = $now.ToString("yyyy-MM-dd HH:mm:ss zzz")

$statusRow = [pscustomobject]@{
   UpdatedLocal = $updatedText
   Status = $status
   RegisteredAtLocal = $registration.registeredAtLocal
   CalendarDays = [math]::Round($calendarDays, 3)
   MinimumCalendarDays = [int]$registration.minimumCalendarDays
   EntryEvents = $entries.Count
   ClosedTrades = $exits.Count
   MinimumClosedTrades = [int]$registration.minimumClosedTrades
   NetProfit = [math]::Round($netProfit, 2)
   ProfitFactor = $profitFactorText
   WinRatePercent = [math]::Round($winRate, 2)
   Expectancy = [math]::Round($expectancy, 2)
   MaximumClosedDrawdownPercent = [math]::Round($maximumClosedDrawdownPercent, 3)
   MaximumConsecutiveLosses = $maximumLossStreak
   ReversionEntries = @($rvEvidence.Rows | Where-Object Event -eq "entry").Count
   ReversionExits = @($rvEvidence.Rows | Where-Object Event -eq "exit").Count
   MomentumEntries = @($moEvidence.Rows | Where-Object Event -eq "entry").Count
   MomentumExits = @($moEvidence.Rows | Where-Object Event -eq "exit").Count
   InvalidRows = $invalidRows
   ForeignIdentityRows = $foreignRows
   TerminalRunning = $terminalRunning
   SourceHashMatch = $sourceHashMatch
   ProfileHashMatch = $profileHashMatch
   InstalledBinaryHashMatch = $binaryHashMatch
   SentinelSourceHashMatch = $sentinelSourceHashMatch
   SentinelProfileHashMatch = $sentinelProfileHashMatch
   SentinelInstalledBinaryHashMatch = $sentinelBinaryHashMatch
   SentinelCodeIdentityPass = $sentinelCodeIdentityPass
   SentinelHeartbeatPresent = $sentinelHeartbeat.Exists
   SentinelHeartbeatValid = $sentinelHeartbeatValid
   SentinelHeartbeatFresh = $sentinelHeartbeatFresh
   SentinelHeartbeatAgeSeconds = [math]::Round($sentinelHeartbeatAgeSeconds, 1)
   SentinelHeartbeatIdentityPass = $sentinelHeartbeatIdentityPass
   AccountTradeMode = $accountTradeMode
   MarginMode = $marginMode
   Connected = $connected
   TerminalTradeAllowed = $terminalTradeAllowed
   AccountTradeAllowed = $accountTradeAllowed
   AccountExpertAllowed = $accountExpertAllowed
   MqlTradeAllowed = $mqlTradeAllowed
   ActualBalance = if([double]::IsNaN($actualBalance)) { "" } else { [math]::Round($actualBalance, 2) }
   ActualEquity = if([double]::IsNaN($actualEquity)) { "" } else { [math]::Round($actualEquity, 2) }
   ExpectedBalance = [math]::Round($expectedBalance, 2)
   AccountModePass = $accountModePass
   BalanceContractPass = $balanceContractPass
   AllPositions = $allPositions
   CandidatePositions = $candidatePositions
   AllUnprotectedPositions = $allUnprotectedPositions
   CandidateUnprotectedPositions = $candidateUnprotectedPositions
   CandidateOpenRiskPercent = if([double]::IsNaN($candidateOpenRiskPercent)) { "" } else { [math]::Round($candidateOpenRiskPercent, 4) }
   MaximumPortfolioOpenRiskPercent = [double]$registration.maximumPortfolioOpenRiskPercent
   PositionIsolationPass = $positionIsolationPass
   ProtectionPass = $protectionPass
   OpenRiskPass = $openRiskPass
   AccountContractPass = $accountContractPass
   OperationalPass = $operationalPass
   ReversionLogPresent = $rvEvidence.Exists
   MomentumLogPresent = $moEvidence.Exists
   LastEventLocal = $lastEventText
   RealAccountTradingAllowed = [bool]$registration.realAccountTradingAllowed
}

$statusRow | Export-Csv -LiteralPath $StatusCsvPath -NoTypeInformation -Encoding UTF8

$identityStatus = if($identityPass) { "PASS" } else { "FAIL" }
$terminalStatus = if($terminalRunning) { "PASS" } else { "ATTENTION" }
$evidenceStatus = if($evidenceFilesPass -and $evidenceIdentityPass) { "PASS" } else { "FAIL" }
$heartbeatStatus = if(!$sentinelHeartbeatValid -or !$sentinelHeartbeatFresh) { "ATTENTION" } elseif($sentinelHeartbeatIdentityPass) { "PASS" } else { "FAIL" }
$accountStatus = if($accountContractPass) { "PASS" } else { "FAIL" }
$operationalStatus = if($operationalPass) { "PASS" } else { "ATTENTION" }
$sampleStatus = if($sampleComplete) { "PASS" } else { "PENDING" }
$performanceStatus = if(!$sampleComplete) { "PENDING" } elseif($profitGatePass -and $profitFactorGatePass -and $drawdownGatePass -and $lossStreakGatePass) { "PASS" } else { "FAIL" }

$markdown = @()
$markdown += "# Transferable Portfolio Forward Demo Status"
$markdown += ""
$markdown += "- **Status:** ``$status``"
$markdown += "- **Updated:** ``$updatedText``"
$markdown += "- **Registered:** ``$($registration.registeredAtLocal)``"
$markdown += "- **Decision:** $decision"
$markdown += "- **Safety:** Demo hedging account only; real-account trading remains disabled. The read-only sentinel cannot trade, and the account identifier is not published by either registration or heartbeat."
$markdown += ""
$markdown += "## Account Contract"
$markdown += ""
$markdown += "| Metric | Current | Required | Status |"
$markdown += "|---|---:|---:|---|"
$markdown += "| Trade mode | $accountTradeMode | demo | $(if($accountModePass) { 'PASS' } else { 'FAIL' }) |"
$markdown += "| Margin mode | $marginMode | hedging | $(if($accountModePass) { 'PASS' } else { 'FAIL' }) |"
$markdown += "| Balance | $(if([double]::IsNaN($actualBalance)) { 'unavailable' } else { '$' + (Format-Number -Value $actualBalance -Digits 2) }) | `$$((Format-Number -Value $expectedBalance -Digits 2)) +/- `$1.00 | $(if($balanceContractPass) { 'PASS' } else { 'FAIL' }) |"
$markdown += "| Equity | $(if([double]::IsNaN($actualEquity)) { 'unavailable' } else { '$' + (Format-Number -Value $actualEquity -Digits 2) }) | information only | - |"
$markdown += "| All / candidate positions | $allPositions / $candidatePositions | equal | $(if($positionIsolationPass) { 'PASS' } else { 'FAIL' }) |"
$markdown += "| All / candidate unprotected | $allUnprotectedPositions / $candidateUnprotectedPositions | 0 / 0 | $(if($protectionPass) { 'PASS' } else { 'FAIL' }) |"
$markdown += "| Candidate open risk | $(if([double]::IsNaN($candidateOpenRiskPercent)) { 'unavailable' } else { Format-Percent -Value $candidateOpenRiskPercent -Digits 4 }) | <= $(Format-Percent -Value ([double]$registration.maximumPortfolioOpenRiskPercent) -Digits 2) | $(if($openRiskPass) { 'PASS' } else { 'FAIL' }) |"
$markdown += ""
$markdown += "## Progress"
$markdown += ""
$markdown += "| Metric | Current | Required |"
$markdown += "|---|---:|---:|"
$markdown += "| Calendar days | $(Format-Number -Value $calendarDays -Digits 2) | $($registration.minimumCalendarDays) |"
$markdown += "| Closed trades | $($exits.Count) | $($registration.minimumClosedTrades) |"
$markdown += "| Entry events | $($entries.Count) | information only |"
$markdown += "| Net profit | `$$((Format-Number -Value $netProfit -Digits 2)) | > `$0 after sample completes |"
$markdown += "| Profit factor | $profitFactorText | >= $(Format-Number -Value ([double]$registration.minimumProfitFactor) -Digits 2) after sample completes |"
$markdown += "| Win rate | $(Format-Percent -Value $winRate -Digits 2) | information only |"
$markdown += "| Expectancy | `$$((Format-Number -Value $expectancy -Digits 2)) | > `$0 after sample completes |"
$markdown += "| Closed-trade drawdown | $(Format-Percent -Value $maximumClosedDrawdownPercent -Digits 3) | <= $(Format-Percent -Value ([double]$registration.maximumClosedTradeDrawdownPercent) -Digits 2) |"
$markdown += "| Consecutive losses | $maximumLossStreak | <= $($registration.maximumConsecutiveLosses) |"
$markdown += "| Last event | $lastEventText | information only |"
$markdown += ""
$markdown += "## Integrity"
$markdown += ""
$markdown += "| Gate | Status | Evidence |"
$markdown += "|---|---|---|"
$markdown += "| Frozen source, profile, and installed binary hashes | $identityStatus | source=$sourceHashMatch; profile=$profileHashMatch; binary=$binaryHashMatch |"
$markdown += "| Read-only sentinel code identity | $(if($sentinelCodeIdentityPass) { 'PASS' } else { 'FAIL' }) | source=$sentinelSourceHashMatch; profile=$sentinelProfileHashMatch; binary=$sentinelBinaryHashMatch |"
$markdown += "| Sentinel heartbeat freshness and identity | $heartbeatStatus | present=$($sentinelHeartbeat.Exists); valid=$sentinelHeartbeatValid; fresh=$sentinelHeartbeatFresh; age=$(Format-Number -Value $sentinelHeartbeatAgeSeconds -Digits 1)s; identity=$sentinelHeartbeatIdentityPass |"
$markdown += "| Demo account and capital contract | $accountStatus | mode=$accountTradeMode/$marginMode; actual=$(if([double]::IsNaN($actualBalance)) { 'unavailable' } else { '$' + (Format-Number -Value $actualBalance -Digits 2) }); expected=`$$((Format-Number -Value $expectedBalance -Digits 2)) |"
$markdown += "| Connection and trading permissions | $operationalStatus | connected=$connected; terminal=$terminalTradeAllowed; account=$accountTradeAllowed; expert=$accountExpertAllowed; MQL=$mqlTradeAllowed |"
$markdown += "| MT5 process running | $terminalStatus | process count=$($terminalProcesses.Count) |"
$markdown += "| Dedicated evidence logs and identity | $evidenceStatus | RV=$($rvEvidence.Exists); MO=$($moEvidence.Exists); foreign rows=$foreignRows; invalid rows=$invalidRows |"
$markdown += "| Minimum observation sample | $sampleStatus | days=$(Format-Number -Value $calendarDays -Digits 2)/$($registration.minimumCalendarDays); trades=$($exits.Count)/$($registration.minimumClosedTrades) |"
$markdown += "| Preregistered performance gates | $performanceStatus | evaluated only after both sample requirements pass |"
$markdown += ""
$markdown += "## Lane Activity"
$markdown += ""
$markdown += "| Lane | Entries | Exits | Log bytes |"
$markdown += "|---|---:|---:|---:|"
$markdown += "| H1 Band/VWAP reversion | $(@($rvEvidence.Rows | Where-Object Event -eq 'entry').Count) | $(@($rvEvidence.Rows | Where-Object Event -eq 'exit').Count) | $($rvEvidence.Length) |"
$markdown += "| Multiscale momentum | $(@($moEvidence.Rows | Where-Object Event -eq 'entry').Count) | $(@($moEvidence.Rows | Where-Object Event -eq 'exit').Count) | $($moEvidence.Length) |"
$markdown += ""
$markdown += "This file is generated by ``work/refresh_transferable_portfolio_forward_demo_status.ps1``. Refreshing the status does not modify the EA or its settings. Closed-trade drawdown excludes intratrade equity excursions and is not a substitute for a full MT5 report."

$markdown -join [Environment]::NewLine | Set-Content -LiteralPath $StatusMarkdownPath -Encoding UTF8
Write-Output "STATUS=$status"
Write-Output "DAYS=$(Format-Number -Value $calendarDays -Digits 3)"
Write-Output "CLOSED_TRADES=$($exits.Count)"
Write-Output "NET_PROFIT=$(Format-Number -Value $netProfit -Digits 2)"
Write-Output "TERMINAL_RUNNING=$terminalRunning"
Write-Output "IDENTITY_PASS=$identityPass"
Write-Output "EVIDENCE_PASS=$($evidenceFilesPass -and $evidenceIdentityPass)"
Write-Output "SENTINEL_HEARTBEAT_PASS=$($sentinelHeartbeatValid -and $sentinelHeartbeatFresh -and $sentinelHeartbeatIdentityPass)"
Write-Output "ACCOUNT_CONTRACT_PASS=$accountContractPass"
