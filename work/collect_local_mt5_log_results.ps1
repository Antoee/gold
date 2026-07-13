param(
   [string]$RunCsv,
   [string]$ManifestPath,
   [string]$TesterLogPath = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\logs\20260709.log",
   [string]$OutResults = "outputs\LOCAL_MT5_LOG_RESULTS.csv",
   [string]$OutSummary = "outputs\LOCAL_MT5_LOG_SUMMARY.csv",
   [int]$TailLines = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function To-DateTime {
   param([string]$Value)
   return [datetime]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture)
}

function To-Number {
   param([string]$Value)
   return [double]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-Field {
   param([object]$Row, [string]$Name, [object]$Default = "")
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

function Parse-TesterStats {
   param([string]$Line)

   $stats = @{}
   foreach($match in [regex]::Matches($Line, '(?<key>[A-Za-z_]+)=(?<value>[-+]?\d+(?:\.\d+)?)')) {
      $stats[$match.Groups["key"].Value] = $match.Groups["value"].Value
   }
   return $stats
}

function Get-StatField {
   param([hashtable]$Stats, [string]$Name)
   if($null -eq $Stats) { return "" }
   if(!$Stats.ContainsKey($Name)) { return "" }
   return $Stats[$Name]
}

if(!(Test-Path -LiteralPath $RunCsv)) { throw "Run CSV missing: $RunCsv" }
if(!(Test-Path -LiteralPath $ManifestPath)) { throw "Manifest missing: $ManifestPath" }
if(!(Test-Path -LiteralPath $TesterLogPath)) { throw "Tester log missing: $TesterLogPath" }

$runRows = @(Import-Csv -LiteralPath $RunCsv)
$manifestRows = @(Import-Csv -LiteralPath $ManifestPath)
$manifestByRank = @{}
foreach($row in $manifestRows) { $manifestByRank[[string]$row.Rank] = $row }

$minStarted = ($runRows | ForEach-Object { To-DateTime $_.Started } | Measure-Object -Minimum).Minimum.AddSeconds(-2)
$maxFinished = ($runRows | ForEach-Object { To-DateTime $_.Finished } | Measure-Object -Maximum).Maximum.AddSeconds(3)
$datePrefix = $minStarted.ToString("yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture)
$events = New-Object System.Collections.Generic.List[object]
$logMatches = if($TailLines -gt 0) {
   Get-Content -LiteralPath $TesterLogPath -Tail $TailLines | Select-String -Pattern 'final balance|TESTER_STATS'
}
else {
   Select-String -LiteralPath $TesterLogPath -Pattern 'final balance|TESTER_STATS'
}
foreach($matchInfo in $logMatches) {
   $line = [string]$matchInfo.Line
   $timeMatch = [regex]::Match($line, '\b(?<time>\d{2}:\d{2}:\d{2}\.\d{3})\b')
   if(!$timeMatch.Success) { continue }
   $timestamp = [datetime]::ParseExact("$datePrefix $($timeMatch.Groups["time"].Value)", "yyyy-MM-dd HH:mm:ss.fff", [Globalization.CultureInfo]::InvariantCulture)
   if($timestamp -lt $minStarted -or $timestamp -gt $maxFinished) { continue }
   $balanceMatch = [regex]::Match($line, 'final balance\s+(?<balance>[-+]?\d+(?:\.\d+)?)\s+USD', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
   if($balanceMatch.Success) {
      $events.Add([pscustomobject]@{
         Timestamp = $timestamp
         Type = "final_balance"
         Value = $balanceMatch.Groups["balance"].Value
         Line = $line
      }) | Out-Null
   }
   if($line -match 'TESTER_STATS') {
      $events.Add([pscustomobject]@{
         Timestamp = $timestamp
         Type = "tester_stats"
         Value = ""
         Stats = Parse-TesterStats $line
         Line = $line
      }) | Out-Null
   }
}

$results = foreach($run in $runRows) {
   $started = To-DateTime $run.Started
   $finished = To-DateTime $run.Finished
   $windowEvents = @($events | Where-Object { $_.Timestamp -ge $started.AddSeconds(-1) -and $_.Timestamp -le $finished.AddSeconds(2) })
   $balanceEvent = $windowEvents | Where-Object Type -eq "final_balance" | Select-Object -Last 1
   $statsEvent = $windowEvents | Where-Object Type -eq "tester_stats" | Select-Object -Last 1
   $stats = if($statsEvent) { $statsEvent.Stats } else { $null }
   $balance = if($balanceEvent) { To-Number $balanceEvent.Value } else { $null }
   $net = if($null -ne $balance) { [Math]::Round($balance - 1000.0, 2) } else { $null }
   $manifest = $manifestByRank[[string]$run.Rank]

   [pscustomobject]@{
      Rank = $run.Rank
      Priority = Get-Field $manifest "Priority"
      Profile = $run.Profile
      Phase = Get-Field $manifest "Phase"
      Set = Get-Field $manifest "Set"
      Window = $run.Window
      From = $run.From
      To = $run.To
      Status = if($null -ne $balance) { "PARSED_FROM_LOG" } else { $run.Status }
      NetProfit = if($null -ne $net) { $net } else { "" }
      Balance = if($null -ne $balance) { [Math]::Round($balance, 2) } else { "" }
      TesterNetProfit = Get-StatField $stats "net"
      TesterBalance = Get-StatField $stats "balance"
      ProfitFactor = Get-StatField $stats "profit_factor"
      RecoveryFactor = Get-StatField $stats "recovery_factor"
      SharpeRatio = Get-StatField $stats "sharpe"
      EquityDrawdownPct = Get-StatField $stats "equity_dd_pct"
      Trades = Get-StatField $stats "trades"
      LogTimestamp = if($balanceEvent) { $balanceEvent.Timestamp.ToString("s") } else { "" }
      TesterStatsTimestamp = if($statsEvent) { $statsEvent.Timestamp.ToString("s") } else { "" }
      RunnerStatus = $run.Status
      Evidence = $run.Evidence
   }
}

$results | Export-Csv -LiteralPath $OutResults -NoTypeInformation

function Get-WindowProfit {
   param($Rows, [string]$Window)
   $row = $Rows | Where-Object Window -eq $Window | Select-Object -First 1
   if($null -eq $row) { return "" }
   return $row.NetProfit
}

function Get-FirstWindowProfit {
   param($Rows, [string[]]$Windows)
   foreach($window in $Windows) {
      $value = Get-WindowProfit $Rows $window
      if("$value" -ne "") { return $value }
   }
   return ""
}

$summary = foreach($group in ($results | Group-Object Profile)) {
   $parsed = @($group.Group | Where-Object { "$($_.NetProfit)" -ne "" })
   $profits = @($parsed | ForEach-Object { [double]$_.NetProfit })
   $weak = @($parsed | Where-Object { $_.Set -eq "weak" } | ForEach-Object { [double]$_.NetProfit })
   $statsParsed = @($group.Group | Where-Object { "$($_.Trades)" -ne "" })
   $trades = @($statsParsed | ForEach-Object { [double]$_.Trades })
   $drawdowns = @($statsParsed | Where-Object { "$($_.EquityDrawdownPct)" -ne "" } | ForEach-Object { [double]$_.EquityDrawdownPct })
   $profitFactors = @($statsParsed | Where-Object { "$($_.ProfitFactor)" -ne "" } | ForEach-Object { [double]$_.ProfitFactor })
   $nonZeroProfitFactors = @($profitFactors | Where-Object { $_ -gt 0 })
   $recoveryFactors = @($statsParsed | Where-Object { "$($_.RecoveryFactor)" -ne "" } | ForEach-Object { [double]$_.RecoveryFactor })
   $sharpes = @($statsParsed | Where-Object { "$($_.SharpeRatio)" -ne "" } | ForEach-Object { [double]$_.SharpeRatio })
   [pscustomobject]@{
      Profile = $group.Name
      Parsed = $parsed.Count
      Expected = $group.Count
      StatsParsed = $statsParsed.Count
      ActiveWindows = @($statsParsed | Where-Object { "$($_.Trades)" -ne "" -and [double]$_.Trades -gt 0 }).Count
      ZeroTradeWindows = @($statsParsed | Where-Object { "$($_.Trades)" -ne "" -and [double]$_.Trades -eq 0 }).Count
      TotalNet = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Sum).Sum, 2) }
      Continuous = Get-FirstWindowProfit $parsed @("2024_to_2026", "continuous_2024_2026")
      YTD = Get-FirstWindowProfit $parsed @("2026_ytd", "ytd2026")
      Full2025 = Get-FirstWindowProfit $parsed @("2025_full", "full2025")
      Full2024 = Get-FirstWindowProfit $parsed @("2024_full", "full2024")
      WeakSum = if($weak.Count -eq 0) { "" } else { [Math]::Round(($weak | Measure-Object -Sum).Sum, 2) }
      WorstWindow = if($profits.Count -eq 0) { "" } else { [Math]::Round(($profits | Measure-Object -Minimum).Minimum, 2) }
      LosingWindows = @($profits | Where-Object { $_ -lt 0 }).Count
      TotalTrades = if($trades.Count -eq 0) { "" } else { [Math]::Round(($trades | Measure-Object -Sum).Sum, 0) }
      WorstEquityDrawdownPct = if($drawdowns.Count -eq 0) { "" } else { [Math]::Round(($drawdowns | Measure-Object -Maximum).Maximum, 4) }
      MinProfitFactor = if($profitFactors.Count -eq 0) { "" } else { [Math]::Round(($profitFactors | Measure-Object -Minimum).Minimum, 4) }
      AvgProfitFactor = if($profitFactors.Count -eq 0) { "" } else { [Math]::Round(($profitFactors | Measure-Object -Average).Average, 4) }
      ProfitFactorNonZeroSamples = $nonZeroProfitFactors.Count
      MinNonZeroProfitFactor = if($nonZeroProfitFactors.Count -eq 0) { "" } else { [Math]::Round(($nonZeroProfitFactors | Measure-Object -Minimum).Minimum, 4) }
      AvgNonZeroProfitFactor = if($nonZeroProfitFactors.Count -eq 0) { "" } else { [Math]::Round(($nonZeroProfitFactors | Measure-Object -Average).Average, 4) }
      MinRecoveryFactor = if($recoveryFactors.Count -eq 0) { "" } else { [Math]::Round(($recoveryFactors | Measure-Object -Minimum).Minimum, 4) }
      AvgSharpeRatio = if($sharpes.Count -eq 0) { "" } else { [Math]::Round(($sharpes | Measure-Object -Average).Average, 4) }
   }
}

$summary | Sort-Object @{ Expression = "Continuous"; Descending = $true }, @{ Expression = "TotalNet"; Descending = $true } |
   Export-Csv -LiteralPath $OutSummary -NoTypeInformation

$summary | Sort-Object @{ Expression = "Continuous"; Descending = $true }, @{ Expression = "TotalNet"; Descending = $true }
