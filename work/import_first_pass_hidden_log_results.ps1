param(
   [string]$RunCsv = "outputs\FIRST_PASS_HIDDEN_RUN_PLAN.csv",
   [string]$QueueManifestPath = "outputs\FIRST_PASS_VALIDATION_QUEUE.csv",
   [string]$ExistingResultsPath = "",
   [string[]]$TesterLogPath = @(),
   [string]$TerminalDataId = "D0E8209F77C8CF37AD8BF550E51FF075",
   [string]$OutResults = "outputs\FIRST_PASS_VALIDATION_QUEUE_RESULTS.csv",
   [string]$OutSummary = "outputs\FIRST_PASS_VALIDATION_QUEUE_REPORT_SUMMARY.csv",
   [string]$OutMarkdown = "outputs\FIRST_PASS_VALIDATION_QUEUE_REPORT_METRICS.md",
   [int]$TailLines = 200000,
   [int]$WindowBufferSeconds = 5,
   [double]$InitialDeposit = 1000.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return "" }
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Convert-ToRepoRelative {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return "" }
   $resolved = $Path
   try {
      if(Test-Path -LiteralPath $Path) {
         $resolved = (Resolve-Path -LiteralPath $Path).Path
      }
   } catch {
      $resolved = $Path
   }
   $root = $repo.TrimEnd('\') + '\'
   if($resolved.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
      return $resolved.Substring($root.Length)
   }
   return $resolved
}

function Read-CsvSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   if($resolved -ne "" -and (Test-Path -LiteralPath $resolved)) { return @(Import-Csv -LiteralPath $resolved) }
   return @()
}

function Get-Field {
   param([object]$Row, [string[]]$Names, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   foreach($name in $Names) {
      $property = $Row.PSObject.Properties[$name]
      if($null -ne $property -and "$($property.Value)" -ne "") { return $property.Value }
   }
   return $Default
}

function To-DateTimeOrNull {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
   $parsed = [DateTime]::MinValue
   if([DateTime]::TryParse([string]$Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeLocal, [ref]$parsed)) {
      return $parsed
   }
   return $null
}

function To-DoubleOrNull {
   param([object]$Value)
   if($null -eq $Value -or "$Value" -eq "") { return $null }
   $text = ([string]$Value).Trim().Replace("%", "")
   $number = 0.0
   if([double]::TryParse($text, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
      return $number
   }
   return $null
}

function Convert-ManifestDate {
   param([AllowNull()][string]$Value)

   if([string]::IsNullOrWhiteSpace($Value)) { return $null }
   $clean = ([string]$Value).Trim()
   $formats = @("yyyy.MM.dd", "yyyy-MM-dd", "yyyy/MM/dd", "yyyyMMdd")
   $culture = [Globalization.CultureInfo]::InvariantCulture
   $styles = [Globalization.DateTimeStyles]::AssumeLocal
   $parsed = [DateTime]::MinValue
   foreach($format in $formats) {
      if([DateTime]::TryParseExact($clean, $format, $culture, $styles, [ref]$parsed)) {
         return $parsed.Date
      }
   }
   if([DateTime]::TryParse($clean, $culture, $styles, [ref]$parsed)) {
      return $parsed.Date
   }
   return $null
}

function Get-CalendarDays {
   param([AllowNull()][string]$From, [AllowNull()][string]$To)

   $fromDate = Convert-ManifestDate $From
   $toDate = Convert-ManifestDate $To
   if($null -eq $fromDate -or $null -eq $toDate) { return $null }
   $days = ($toDate - $fromDate).TotalDays
   if($days -lt 0) { return $null }
   if($days -eq 0) { return 1 }
   return [int][Math]::Round($days, 0)
}

function Get-ReturnMetrics {
   param(
      [AllowNull()][object]$NetProfit,
      [AllowNull()][object]$Balance,
      [double]$InitialDepositValue,
      [AllowNull()][object]$CalendarDays
   )

   $years = $null
   if($null -ne $CalendarDays -and [double]$CalendarDays -gt 0) {
      $years = [double]$CalendarDays / 365.25
   }

   $totalReturnPercent = $null
   if($null -ne $NetProfit -and $InitialDepositValue -gt 0) {
      $totalReturnPercent = ([double]$NetProfit / $InitialDepositValue) * 100.0
   }

   $annualizedReturnPercent = $null
   if($null -ne $totalReturnPercent -and $null -ne $years -and $years -gt 0) {
      $annualizedReturnPercent = $totalReturnPercent / $years
   }

   $cagrPercent = $null
   if($null -ne $Balance -and $InitialDepositValue -gt 0 -and $null -ne $years -and $years -gt 0) {
      $balanceDouble = [double]$Balance
      if($balanceDouble -gt 0) {
         $cagrPercent = ([Math]::Pow(($balanceDouble / $InitialDepositValue), (1.0 / $years)) - 1.0) * 100.0
      } elseif($balanceDouble -eq 0) {
         $cagrPercent = -100.0
      }
   }

   return [pscustomobject]@{
      Years = $years
      TotalReturnPercent = $totalReturnPercent
      AnnualizedReturnPercent = $annualizedReturnPercent
      CagrPercent = $cagrPercent
   }
}

function Parse-TesterStats {
   param([string]$Line)

   $stats = @{}
   foreach($match in [regex]::Matches($Line, '(?<key>[A-Za-z_]+)=(?<value>[-+]?\d+(?:\.\d+)?)')) {
      $stats[$match.Groups["key"].Value] = $match.Groups["value"].Value
   }
   return $stats
}

function Parse-TradeOutcome {
   param([string]$Line)

   $match = [regex]::Match(
      $Line,
      '\b(?<sim>\d{4}\.\d{2}\.\d{2}\s+\d{2}:\d{2}:\d{2})\s+(?<trigger>stop loss|take profit) triggered #\d+\s+(?<side>buy|sell)\s+(?<lots>[-+]?\d+(?:\.\d+)?)\s+XAUUSD\s+(?<entry>[-+]?\d+(?:\.\d+)?).*?\[#\d+\s+(?:buy|sell)\s+[-+]?\d+(?:\.\d+)?\s+XAUUSD at\s+(?<close>[-+]?\d+(?:\.\d+)?)\]',
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
   if(!$match.Success) { return $null }

   $side = $match.Groups["side"].Value.ToLowerInvariant()
   $entry = To-DoubleOrNull $match.Groups["entry"].Value
   $close = To-DoubleOrNull $match.Groups["close"].Value
   if($null -eq $entry -or $null -eq $close) { return $null }

   $points = if($side -eq "buy") { [double]$close - [double]$entry } else { [double]$entry - [double]$close }
   $result = if($points -gt 0) { "WIN" } elseif($points -lt 0) { "LOSS" } else { "FLAT" }

   [pscustomobject]@{
      SimulatedTime = $match.Groups["sim"].Value
      Trigger = $match.Groups["trigger"].Value.ToLowerInvariant()
      Side = $side
      Entry = $entry
      Close = $close
      Points = $points
      Result = $result
   }
}

function Get-StatNumber {
   param([hashtable]$Stats, [string]$Name)
   if($null -eq $Stats -or !$Stats.ContainsKey($Name)) { return $null }
   return To-DoubleOrNull $Stats[$Name]
}

function Get-LogDateFromPath {
   param([string]$Path)
   $stem = [IO.Path]::GetFileNameWithoutExtension($Path)
   $parsed = [DateTime]::MinValue
   if([DateTime]::TryParseExact($stem, "yyyyMMdd", [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeLocal, [ref]$parsed)) {
      return $parsed.Date
   }
   return $null
}

function Get-DefaultLogPaths {
   param([datetime[]]$Dates)

   $paths = [System.Collections.Generic.List[string]]::new()
   $terminalLogDir = Join-Path (Join-Path (Join-Path $env:APPDATA "MetaQuotes\Terminal") $TerminalDataId) "Tester\logs"
   $agentRoot = Join-Path (Join-Path (Join-Path $env:APPDATA "MetaQuotes\Tester") $TerminalDataId) ""
   $candidateDirs = [System.Collections.Generic.List[string]]::new()
   if(Test-Path -LiteralPath $terminalLogDir) { $candidateDirs.Add($terminalLogDir) | Out-Null }
   if(Test-Path -LiteralPath $agentRoot) {
      Get-ChildItem -LiteralPath $agentRoot -Directory -Filter "Agent-*" -ErrorAction SilentlyContinue |
         ForEach-Object {
            $logs = Join-Path $_.FullName "logs"
            if(Test-Path -LiteralPath $logs) { $candidateDirs.Add($logs) | Out-Null }
         }
   }

   foreach($date in ($Dates | Sort-Object -Unique)) {
      $name = $date.ToString("yyyyMMdd", [Globalization.CultureInfo]::InvariantCulture) + ".log"
      foreach($dir in $candidateDirs) {
         $path = Join-Path $dir $name
         if(Test-Path -LiteralPath $path -PathType Leaf) {
            $paths.Add((Resolve-Path -LiteralPath $path).Path) | Out-Null
         }
      }
   }

   return @($paths | Sort-Object -Unique)
}

function Read-LogEvents {
   param([string[]]$Paths, [datetime]$MinStarted, [datetime]$MaxFinished)

   $events = [System.Collections.Generic.List[object]]::new()
   foreach($path in $Paths) {
      if(!(Test-Path -LiteralPath $path -PathType Leaf)) { continue }
      $logDate = Get-LogDateFromPath $path
      if($null -eq $logDate) { continue }

      $lines = if($TailLines -gt 0) {
         Get-Content -LiteralPath $path -Tail $TailLines
      } else {
         Get-Content -LiteralPath $path
      }

      $ordinal = 0
      foreach($lineObj in $lines) {
         $ordinal++
         $line = [string]$lineObj
         if($line -notmatch 'TESTER_STATS|final balance|(?:stop loss|take profit) triggered') { continue }
         $timeMatch = [regex]::Match($line, '\b(?<time>\d{2}:\d{2}:\d{2}\.\d{3})\b')
         if(!$timeMatch.Success) { continue }
         $timestamp = [DateTime]::ParseExact(
            ($logDate.ToString("yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture) + " " + $timeMatch.Groups["time"].Value),
            "yyyy-MM-dd HH:mm:ss.fff",
            [Globalization.CultureInfo]::InvariantCulture)
         if($timestamp -lt $MinStarted.AddSeconds(-1 * $WindowBufferSeconds) -or $timestamp -gt $MaxFinished.AddSeconds($WindowBufferSeconds)) {
            continue
         }

         $balanceMatch = [regex]::Match($line, 'final balance\s+(?<balance>[-+]?\d+(?:\.\d+)?)\s+USD', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
         if($balanceMatch.Success) {
            $events.Add([pscustomobject]@{
               Timestamp = $timestamp
               Type = "final_balance"
               Balance = To-DoubleOrNull $balanceMatch.Groups["balance"].Value
               Stats = $null
               TradeOutcome = $null
               Ordinal = $ordinal
               LogPath = $path
               Line = $line
            }) | Out-Null
         }

         if($line -match 'TESTER_STATS') {
            $events.Add([pscustomobject]@{
               Timestamp = $timestamp
               Type = "tester_stats"
               Balance = $null
               Stats = Parse-TesterStats $line
               TradeOutcome = $null
               Ordinal = $ordinal
               LogPath = $path
               Line = $line
            }) | Out-Null
         }

         $tradeOutcome = Parse-TradeOutcome -Line $line
         if($null -ne $tradeOutcome) {
            $events.Add([pscustomobject]@{
               Timestamp = $timestamp
               Type = "trade_outcome"
               Balance = $null
               Stats = $null
               TradeOutcome = $tradeOutcome
               Ordinal = $ordinal
               LogPath = $path
               Line = $line
            }) | Out-Null
         }
      }
   }

   return @($events | Sort-Object Timestamp)
}

function Test-ParsedExistingReport {
   param([object]$Row)
   if($null -eq $Row) { return $false }
   return ([string](Get-Field -Row $Row -Names @("Status") -Default "") -eq "PARSED")
}

function Test-ExistingMatchesManifest {
   param([object]$Row, [object]$ManifestRow)
   if($null -eq $Row -or $null -eq $ManifestRow) { return $false }

   $identityFields = @(
      "Candidate",
      "CandidateRank",
      "SourceType",
      "SourceRank",
      "Phase",
      "Set",
      "Window",
      "From",
      "To",
      "Model",
      "Config",
      "ExpectedReportName",
      "ProfileSnapshot",
      "ProfileSha256"
   )

   foreach($field in $identityFields) {
      $existingValue = [string](Get-Field -Row $Row -Names @($field) -Default "")
      $manifestValue = [string](Get-Field -Row $ManifestRow -Names @($field) -Default "")
      if($existingValue -ne $manifestValue) {
         return $false
      }
   }

   return $true
}

function New-MissingRow {
   param([object]$ManifestRow, [string]$Status = "MISSING_REPORT", [string]$ReportPath = "")

   $from = [string]$ManifestRow.From
   $to = [string]$ManifestRow.To
   $calendarDays = Get-CalendarDays -From $from -To $to
   [pscustomobject]@{
      QueueRank = $ManifestRow.QueueRank
      Candidate = $ManifestRow.Candidate
      CandidateRank = $ManifestRow.CandidateRank
      SourceType = $ManifestRow.SourceType
      SourceRank = $ManifestRow.SourceRank
      Phase = $ManifestRow.Phase
      Set = $ManifestRow.Set
      Window = $ManifestRow.Window
      From = $from
      To = $to
      Model = $ManifestRow.Model
      Config = $ManifestRow.Config
      ExpectedReportName = $ManifestRow.ExpectedReportName
      ProfileSnapshot = $ManifestRow.ProfileSnapshot
      ProfileSha256 = $ManifestRow.ProfileSha256
      StopRule = $ManifestRow.StopRule
      Status = $Status
      ReportPath = $ReportPath
      InitialDeposit = $InitialDeposit
      CalendarDays = if($null -eq $calendarDays) { "" } else { $calendarDays }
      Years = ""
      NetProfit = ""
      Balance = ""
      TotalReturnPercent = ""
      AnnualizedReturnPercent = ""
      CagrPercent = ""
      ProfitFactor = ""
      ExpectedPayoff = ""
      SharpeRatio = ""
      WinRatePercent = ""
      TotalTrades = ""
      MaxConsecutiveLosses = ""
      MaxDrawdownMoney = ""
      MaxDrawdownPercent = ""
      BalanceDrawdownMaximal = ""
      EquityDrawdownMaximal = ""
      RecoveryFactor = ""
      RunnerStatus = ""
      RunnerEvidence = ""
      LogTimestamp = ""
      TesterStatsTimestamp = ""
   }
}

function New-LogResultRow {
   param([object]$ManifestRow, [object]$RunRow, [object]$BalanceEvent, [object]$StatsEvent, [object[]]$TradeEvents = @())

   $stats = if($StatsEvent) { $StatsEvent.Stats } else { $null }
   $balance = if($BalanceEvent -and $null -ne $BalanceEvent.Balance) { $BalanceEvent.Balance } else { Get-StatNumber -Stats $stats -Name "balance" }
   $net = Get-StatNumber -Stats $stats -Name "net"
   if($null -eq $net -and $null -ne $balance) { $net = [Math]::Round($balance - $InitialDeposit, 2) }
   if($null -eq $balance -and $null -ne $net) { $balance = [Math]::Round($InitialDeposit + $net, 2) }

   $trades = Get-StatNumber -Stats $stats -Name "trades"
   $profitFactor = Get-StatNumber -Stats $stats -Name "profit_factor"
   $recoveryFactor = Get-StatNumber -Stats $stats -Name "recovery_factor"
   $sharpe = Get-StatNumber -Stats $stats -Name "sharpe"
   $drawdownPct = Get-StatNumber -Stats $stats -Name "equity_dd_pct"
   $expectedPayoff = $null
   if($null -ne $trades -and $trades -gt 0 -and $null -ne $net) {
      $expectedPayoff = $net / $trades
   } elseif($null -ne $trades -and $trades -eq 0) {
      $expectedPayoff = 0.0
   }
   $tradeOutcomes = @($TradeEvents | Sort-Object Timestamp, Ordinal | ForEach-Object { $_.TradeOutcome } | Where-Object { $null -ne $_ -and $_.Result -in @("WIN", "LOSS", "FLAT") })
   $winRate = if($null -ne $trades -and $trades -eq 0) { 0.0 } else { $null }
   $lossStreak = if($null -ne $trades -and $trades -eq 0) { 0 } else { $null }
   if($tradeOutcomes.Count -gt 0) {
      $wins = @($tradeOutcomes | Where-Object Result -eq "WIN").Count
      $losses = @($tradeOutcomes | Where-Object Result -eq "LOSS").Count
      $completed = $wins + $losses + @($tradeOutcomes | Where-Object Result -eq "FLAT").Count
      if($completed -gt 0) {
         $winRate = ($wins / $completed) * 100.0
      }

      $currentLossRun = 0
      $maxLossRun = 0
      foreach($outcome in $tradeOutcomes) {
         if($outcome.Result -eq "LOSS") {
            $currentLossRun++
            if($currentLossRun -gt $maxLossRun) { $maxLossRun = $currentLossRun }
         } elseif($outcome.Result -eq "WIN") {
            $currentLossRun = 0
         }
      }
      $lossStreak = $maxLossRun
   }
   $maxDrawdownMoney = if($null -ne $drawdownPct -and $null -ne $balance) { [Math]::Round(([Math]::Max($InitialDeposit, [double]$balance) * ([double]$drawdownPct / 100.0)), 2) } else { $null }

   $from = [string]$ManifestRow.From
   $to = [string]$ManifestRow.To
   $calendarDays = Get-CalendarDays -From $from -To $to
   $returnMetrics = Get-ReturnMetrics -NetProfit $net -Balance $balance -InitialDepositValue $InitialDeposit -CalendarDays $calendarDays
   $logPath = if($StatsEvent) { $StatsEvent.LogPath } elseif($BalanceEvent) { $BalanceEvent.LogPath } else { "" }

   [pscustomobject]@{
      QueueRank = $ManifestRow.QueueRank
      Candidate = $ManifestRow.Candidate
      CandidateRank = $ManifestRow.CandidateRank
      SourceType = $ManifestRow.SourceType
      SourceRank = $ManifestRow.SourceRank
      Phase = $ManifestRow.Phase
      Set = $ManifestRow.Set
      Window = $ManifestRow.Window
      From = $from
      To = $to
      Model = $ManifestRow.Model
      Config = $ManifestRow.Config
      ExpectedReportName = $ManifestRow.ExpectedReportName
      ProfileSnapshot = $ManifestRow.ProfileSnapshot
      ProfileSha256 = $ManifestRow.ProfileSha256
      StopRule = $ManifestRow.StopRule
      Status = if($null -ne $net) { "PARSED_FROM_LOG" } else { "UNPARSED" }
      ReportPath = Convert-ToRepoRelative $logPath
      InitialDeposit = $InitialDeposit
      CalendarDays = if($null -eq $calendarDays) { "" } else { $calendarDays }
      Years = if($null -eq $returnMetrics.Years) { "" } else { [Math]::Round($returnMetrics.Years, 4) }
      NetProfit = if($null -eq $net) { "" } else { [Math]::Round($net, 2) }
      Balance = if($null -eq $balance) { "" } else { [Math]::Round($balance, 2) }
      TotalReturnPercent = if($null -eq $returnMetrics.TotalReturnPercent) { "" } else { [Math]::Round($returnMetrics.TotalReturnPercent, 2) }
      AnnualizedReturnPercent = if($null -eq $returnMetrics.AnnualizedReturnPercent) { "" } else { [Math]::Round($returnMetrics.AnnualizedReturnPercent, 2) }
      CagrPercent = if($null -eq $returnMetrics.CagrPercent) { "" } else { [Math]::Round($returnMetrics.CagrPercent, 2) }
      ProfitFactor = if($null -eq $profitFactor) { "" } else { [Math]::Round($profitFactor, 4) }
      ExpectedPayoff = if($null -eq $expectedPayoff) { "" } else { [Math]::Round($expectedPayoff, 4) }
      SharpeRatio = if($null -eq $sharpe) { "" } else { [Math]::Round($sharpe, 4) }
      WinRatePercent = if($null -eq $winRate) { "" } else { [Math]::Round($winRate, 2) }
      TotalTrades = if($null -eq $trades) { "" } else { [int][Math]::Round($trades, 0) }
      MaxConsecutiveLosses = if($null -eq $lossStreak) { "" } else { [int]$lossStreak }
      MaxDrawdownMoney = if($null -eq $maxDrawdownMoney) { "" } else { [Math]::Round($maxDrawdownMoney, 2) }
      MaxDrawdownPercent = if($null -eq $drawdownPct) { "" } else { [Math]::Round($drawdownPct, 2) }
      BalanceDrawdownMaximal = if($null -eq $maxDrawdownMoney) { "" } else { [Math]::Round($maxDrawdownMoney, 2) }
      EquityDrawdownMaximal = if($null -eq $maxDrawdownMoney) { "" } else { [Math]::Round($maxDrawdownMoney, 2) }
      RecoveryFactor = if($null -eq $recoveryFactor) { "" } else { [Math]::Round($recoveryFactor, 4) }
      RunnerStatus = Get-Field -Row $RunRow -Names @("Status") -Default ""
      RunnerEvidence = Get-Field -Row $RunRow -Names @("Evidence") -Default ""
      LogTimestamp = if($BalanceEvent) { $BalanceEvent.Timestamp.ToString("s") } elseif($StatsEvent) { $StatsEvent.Timestamp.ToString("s") } else { "" }
      TesterStatsTimestamp = if($StatsEvent) { $StatsEvent.Timestamp.ToString("s") } else { "" }
   }
}

function Write-CsvRows {
   param([object[]]$Rows, [string]$Path)
   $resolved = Resolve-RepoPath $Path
   $parent = Split-Path -Parent $resolved
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   $Rows | Export-Csv -LiteralPath $resolved -NoTypeInformation -Encoding ASCII
}

function Write-TextLines {
   param([string[]]$Lines, [string]$Path)
   $resolved = Resolve-RepoPath $Path
   $parent = Split-Path -Parent $resolved
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   $Lines | Set-Content -LiteralPath $resolved -Encoding ASCII
}

$resolvedRunCsv = Resolve-RepoPath $RunCsv
$resolvedManifest = Resolve-RepoPath $QueueManifestPath
if(!(Test-Path -LiteralPath $resolvedRunCsv)) { throw "First-pass hidden run CSV missing: $resolvedRunCsv" }
if(!(Test-Path -LiteralPath $resolvedManifest)) { throw "First-pass queue manifest missing: $resolvedManifest" }

$runRows = @(Import-Csv -LiteralPath $resolvedRunCsv)
$manifestRows = @(Import-Csv -LiteralPath $resolvedManifest)
$existingRows = if([string]::IsNullOrWhiteSpace($ExistingResultsPath)) { @() } else { Read-CsvSafe $ExistingResultsPath }

$runRowsWithTimes = @($runRows | Where-Object {
   $null -ne (To-DateTimeOrNull (Get-Field -Row $_ -Names @("Started") -Default "")) -and
   $null -ne (To-DateTimeOrNull (Get-Field -Row $_ -Names @("Finished") -Default ""))
})

$events = @()
$logPaths = @()
if($runRowsWithTimes.Count -gt 0) {
   $starts = @($runRowsWithTimes | ForEach-Object { To-DateTimeOrNull (Get-Field -Row $_ -Names @("Started") -Default "") })
   $finishes = @($runRowsWithTimes | ForEach-Object { To-DateTimeOrNull (Get-Field -Row $_ -Names @("Finished") -Default "") })
   $minStarted = ($starts | Measure-Object -Minimum).Minimum
   $maxFinished = ($finishes | Measure-Object -Maximum).Maximum
   $dates = [System.Collections.Generic.List[datetime]]::new()
   $cursor = $minStarted.Date
   while($cursor -le $maxFinished.Date) {
      $dates.Add($cursor) | Out-Null
      $cursor = $cursor.AddDays(1)
   }
   $logPaths = @(if($TesterLogPath.Count -gt 0) {
      @($TesterLogPath | ForEach-Object { Resolve-RepoPath $_ } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Sort-Object -Unique)
   } else {
      Get-DefaultLogPaths -Dates @($dates)
   })
   if($logPaths.Count -gt 0) {
      $events = @(Read-LogEvents -Paths $logPaths -MinStarted $minStarted -MaxFinished $maxFinished)
   }
}

$runByRank = @{}
foreach($run in $runRows) {
   $rank = [string](Get-Field -Row $run -Names @("QueueRank", "Rank") -Default "")
   if($rank -ne "") { $runByRank[$rank] = $run }
}

$existingByRank = @{}
foreach($row in $existingRows) {
   $rank = [string](Get-Field -Row $row -Names @("QueueRank", "Rank") -Default "")
   if($rank -ne "") { $existingByRank[$rank] = $row }
}

$results = [System.Collections.Generic.List[object]]::new()
foreach($manifest in ($manifestRows | Sort-Object { [int](Get-Field -Row $_ -Names @("QueueRank") -Default 0) })) {
   $rank = [string]$manifest.QueueRank
   $existing = if($existingByRank.ContainsKey($rank)) { $existingByRank[$rank] } else { $null }
   if($null -ne $existing -and !(Test-ExistingMatchesManifest -Row $existing -ManifestRow $manifest)) {
      $existing = $null
   }
   if(Test-ParsedExistingReport $existing) {
      $results.Add($existing) | Out-Null
      continue
   }

   $run = if($runByRank.ContainsKey($rank)) { $runByRank[$rank] } else { $null }
   $started = To-DateTimeOrNull (Get-Field -Row $run -Names @("Started") -Default "")
   $finished = To-DateTimeOrNull (Get-Field -Row $run -Names @("Finished") -Default "")
   if($null -eq $run -or $null -eq $started -or $null -eq $finished) {
      if($null -ne $existing) { $results.Add($existing) | Out-Null } else { $results.Add((New-MissingRow -ManifestRow $manifest)) | Out-Null }
      continue
   }

   $windowEvents = @($events | Where-Object {
      $_.Timestamp -ge $started.AddSeconds(-1 * $WindowBufferSeconds) -and
      $_.Timestamp -le $finished.AddSeconds($WindowBufferSeconds)
   })
   $balanceEvent = $windowEvents | Where-Object Type -eq "final_balance" | Select-Object -Last 1
   $statsEvent = $windowEvents | Where-Object Type -eq "tester_stats" | Select-Object -Last 1
   $tradeEvents = @($windowEvents | Where-Object Type -eq "trade_outcome")
   if($balanceEvent -or $statsEvent) {
      $results.Add((New-LogResultRow -ManifestRow $manifest -RunRow $run -BalanceEvent $balanceEvent -StatsEvent $statsEvent -TradeEvents $tradeEvents)) | Out-Null
   } elseif($null -ne $existing) {
      $results.Add($existing) | Out-Null
   } else {
      $status = [string](Get-Field -Row $run -Names @("Status") -Default "MISSING_REPORT")
      if($status -eq "NO_REPORT") { $status = "MISSING_REPORT" }
      $results.Add((New-MissingRow -ManifestRow $manifest -Status $status)) | Out-Null
   }
}

Write-CsvRows -Rows @($results) -Path $OutResults

$summary = foreach($group in ($results | Group-Object Candidate, SourceType, Phase)) {
   $rows = @($group.Group)
   $parsedReports = @($rows | Where-Object Status -eq "PARSED")
   $parsedLogs = @($rows | Where-Object Status -eq "PARSED_FROM_LOG")
   $parsed = @($parsedReports + $parsedLogs)
   $profits = @($parsed | Where-Object { "$($_.NetProfit)" -ne "" } | ForEach-Object { [double]$_.NetProfit })
   $dds = @($parsed | Where-Object { "$($_.MaxDrawdownPercent)" -ne "" } | ForEach-Object { [double]$_.MaxDrawdownPercent })
   $pfs = @($parsed | Where-Object { "$($_.ProfitFactor)" -ne "" } | ForEach-Object { [double]$_.ProfitFactor })
   $trades = @($parsed | Where-Object { "$($_.TotalTrades)" -ne "" } | ForEach-Object { [int]$_.TotalTrades })
   $annualizedReturns = @($parsed | Where-Object { "$($_.AnnualizedReturnPercent)" -ne "" } | ForEach-Object { [double]$_.AnnualizedReturnPercent })
   $cagrs = @($parsed | Where-Object { "$($_.CagrPercent)" -ne "" } | ForEach-Object { [double]$_.CagrPercent })
   $parts = $group.Name -split ', '
   [pscustomobject]@{
      Candidate = $parts[0]
      SourceType = $parts[1]
      Phase = $parts[2]
      Expected = $rows.Count
      ParsedReports = $parsedReports.Count
      ParsedLogs = $parsedLogs.Count
      ParsedTotal = $parsed.Count
      Missing = @($rows | Where-Object Status -eq "MISSING_REPORT").Count
      Unparsed = @($rows | Where-Object { $_.Status -match "UNPARSED" }).Count
      TotalNetProfit = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Sum).Sum, 2) }
      WorstNetProfit = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Minimum).Minimum, 2) }
      AverageAnnualizedReturnPercent = if($annualizedReturns.Count -eq 0) { "" } else { [Math]::Round(($annualizedReturns | Measure-Object -Average).Average, 2) }
      WorstAnnualizedReturnPercent = if($annualizedReturns.Count -eq 0) { "" } else { [Math]::Round(($annualizedReturns | Measure-Object -Minimum).Minimum, 2) }
      AverageCagrPercent = if($cagrs.Count -eq 0) { "" } else { [Math]::Round(($cagrs | Measure-Object -Average).Average, 2) }
      WorstCagrPercent = if($cagrs.Count -eq 0) { "" } else { [Math]::Round(($cagrs | Measure-Object -Minimum).Minimum, 2) }
      WorstDrawdownPercent = if($dds.Count -eq 0) { "" } else { [Math]::Round(($dds | Measure-Object -Maximum).Maximum, 2) }
      MinProfitFactor = if($pfs.Count -eq 0) { "" } else { [Math]::Round(($pfs | Measure-Object -Minimum).Minimum, 4) }
      TotalTrades = if($trades.Count -eq 0) { "" } else { ($trades | Measure-Object -Sum).Sum }
   }
}
Write-CsvRows -Rows @($summary) -Path $OutSummary

$parsedReportCount = @($results | Where-Object Status -eq "PARSED").Count
$parsedLogCount = @($results | Where-Object Status -eq "PARSED_FROM_LOG").Count
$missingCount = @($results | Where-Object Status -eq "MISSING_REPORT").Count
$unparsedCount = @($results | Where-Object { $_.Status -match "UNPARSED" }).Count

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# First-Pass Validation Log Metrics")
$md.Add("")
$md.Add("Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.")
$md.Add("")
$md.Add("- Queue manifest: ``$QueueManifestPath``")
$md.Add("- Hidden run CSV: ``$RunCsv``")
$md.Add("- Log files scanned: ``$($logPaths.Count)``")
$md.Add("- Expected rows: ``$($results.Count)``")
$md.Add("- Parsed exported reports: ``$parsedReportCount``")
$md.Add("- Parsed from tester log: ``$parsedLogCount``")
$md.Add("- Missing reports/results: ``$missingCount``")
$md.Add("- Unparsed log rows: ``$unparsedCount``")
$md.Add("")
$md.Add("Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.")
$md.Add("")
$md.Add("## Summary By Candidate")
$md.Add("")
$md.Add("| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |")
$md.Add("| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
foreach($row in ($summary | Sort-Object Candidate, SourceType, Phase)) {
   $md.Add("| ``$($row.Candidate)`` | $($row.SourceType) | $($row.Phase) | $($row.ParsedReports) | $($row.ParsedLogs) | $($row.Expected) | $($row.TotalNetProfit) | $($row.WorstNetProfit) | $($row.AverageAnnualizedReturnPercent) | $($row.WorstAnnualizedReturnPercent) | $($row.WorstDrawdownPercent) | $($row.MinProfitFactor) | $($row.TotalTrades) |")
}
$md.Add("")
$md.Add("## Missing Or Unparsed")
$md.Add("")
$issues = @($results | Where-Object { $_.Status -ne "PARSED" -and $_.Status -ne "PARSED_FROM_LOG" } | Sort-Object { [int](Get-Field -Row $_ -Names @("QueueRank") -Default 0) })
if($issues.Count -eq 0) {
   $md.Add("All queued rows have report or log evidence.")
} else {
   $md.Add("| Rank | Candidate | Phase | Window | Status |")
   $md.Add("| ---: | --- | --- | --- | --- |")
   foreach($issue in ($issues | Select-Object -First 80)) {
      $md.Add("| $($issue.QueueRank) | ``$($issue.Candidate)`` | $($issue.Phase) | $($issue.Window) | $($issue.Status) |")
   }
   if($issues.Count -gt 80) {
      $md.Add("")
      $md.Add("Showing first 80 of $($issues.Count) missing/unparsed rows.")
   }
}
Write-TextLines -Lines $md -Path $OutMarkdown

[pscustomobject]@{
   Results = $OutResults
   Expected = $results.Count
   ParsedReports = $parsedReportCount
   ParsedFromLog = $parsedLogCount
   Missing = $missingCount
   Unparsed = $unparsedCount
   LogFilesScanned = $logPaths.Count
}
