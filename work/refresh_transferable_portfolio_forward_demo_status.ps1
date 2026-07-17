[CmdletBinding()]
param(
   [string]$RegistrationPath = "",
   [string]$StatusCsvPath = "",
   [string]$StatusMarkdownPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
if([string]::IsNullOrWhiteSpace($RegistrationPath)) {
   $RegistrationPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_REGISTRATION.json"
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

if(!(Test-Path -LiteralPath $RegistrationPath -PathType Leaf)) {
   throw "Forward registration is missing: $RegistrationPath"
}

$registration = Get-Content -Raw -LiteralPath $RegistrationPath | ConvertFrom-Json
$sourcePath = Resolve-WorkspacePath -Path $registration.sourcePath
$profilePath = Resolve-WorkspacePath -Path $registration.profilePath
$terminalRoot = Join-Path $env:APPDATA "MetaQuotes\Terminal"
$commonFilesRoot = Join-Path $terminalRoot "Common\Files"
$rvLogPath = Join-Path $commonFilesRoot $registration.reversionLogFile
$moLogPath = Join-Path $commonFilesRoot $registration.momentumLogFile

$sourceHash = Get-Sha256 -Path $sourcePath
$profileHash = Get-Sha256 -Path $profilePath
$sourceHashMatch = $sourceHash -eq $registration.sourceSha256
$profileHashMatch = $profileHash -eq $registration.profileSha256

$installedBinaryMatches = [System.Collections.Generic.List[string]]::new()
if(Test-Path -LiteralPath $terminalRoot -PathType Container) {
   foreach($binary in @(Get-ChildItem -LiteralPath $terminalRoot -Recurse -File -Filter "Professional_XAUUSD_Transferable_Portfolio.ex5" -ErrorAction SilentlyContinue)) {
      if((Get-Sha256 -Path $binary.FullName) -eq $registration.installedBinarySha256) {
         [void]$installedBinaryMatches.Add($binary.FullName)
      }
   }
}
$binaryHashMatch = $installedBinaryMatches.Count -gt 0

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
$identityPass = $sourceHashMatch -and $profileHashMatch -and $binaryHashMatch
$evidenceFilesPass = $rvEvidence.Exists -and $moEvidence.Exists
$foreignRows = $rvEvidence.ForeignRows + $moEvidence.ForeignRows
$invalidRows = $rvEvidence.InvalidRows + $moEvidence.InvalidRows
$evidenceIdentityPass = $foreignRows -eq 0
$terminalProcesses = @(Get-Process -Name "terminal64" -ErrorAction SilentlyContinue)
$terminalRunning = $terminalProcesses.Count -gt 0

$profitGatePass = $netProfit -gt 0.0
$profitFactorGatePass = $profitFactor -ge [double]$registration.minimumProfitFactor
$drawdownGatePass = $maximumClosedDrawdownPercent -le [double]$registration.maximumClosedTradeDrawdownPercent
$lossStreakGatePass = $maximumLossStreak -le [int]$registration.maximumConsecutiveLosses

if(!$identityPass -or !$evidenceFilesPass -or !$evidenceIdentityPass) {
   $status = "FAIL"
   $decision = "Freeze identity or evidence integrity failed. Stop the monitor and inspect before continuing."
}
elseif(!$terminalRunning) {
   $status = "ATTENTION"
   $decision = "The frozen evidence is intact, but MT5 is not running. Restart the same demo monitor without changing the profile."
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
   ReversionLogPresent = $rvEvidence.Exists
   MomentumLogPresent = $moEvidence.Exists
   LastEventLocal = $lastEventText
   RealAccountTradingAllowed = [bool]$registration.realAccountTradingAllowed
}

$statusRow | Export-Csv -LiteralPath $StatusCsvPath -NoTypeInformation -Encoding UTF8

$identityStatus = if($identityPass) { "PASS" } else { "FAIL" }
$terminalStatus = if($terminalRunning) { "PASS" } else { "ATTENTION" }
$evidenceStatus = if($evidenceFilesPass -and $evidenceIdentityPass) { "PASS" } else { "FAIL" }
$sampleStatus = if($sampleComplete) { "PASS" } else { "PENDING" }
$performanceStatus = if(!$sampleComplete) { "PENDING" } elseif($profitGatePass -and $profitFactorGatePass -and $drawdownGatePass -and $lossStreakGatePass) { "PASS" } else { "FAIL" }

$markdown = @()
$markdown += "# Transferable Portfolio Forward Demo Status"
$markdown += ""
$markdown += "- **Status:** ``$status``"
$markdown += "- **Updated:** ``$updatedText``"
$markdown += "- **Registered:** ``$($registration.registeredAtLocal)``"
$markdown += "- **Decision:** $decision"
$markdown += "- **Safety:** Demo hedging account only; real-account trading remains disabled. The account identifier is not published."
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
