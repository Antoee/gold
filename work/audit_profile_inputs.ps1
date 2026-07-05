param(
   [string]$SourcePath = "outputs\Professional_XAUUSD_EA.mq5",
   [string]$OutputsDir = "outputs",
   [string]$OutCsv = "outputs\PROFILE_INPUT_AUDIT.csv",
   [string]$OutReport = "outputs\PROFILE_INPUT_AUDIT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if(!(Test-Path -LiteralPath $SourcePath)) {
   throw "EA source not found: $SourcePath"
}
if(!(Test-Path -LiteralPath $OutputsDir)) {
   throw "Outputs directory not found: $OutputsDir"
}

$criticalInputs = @(
   "InpRiskPercent",
   "InpUseDateBuyBlock",
   "InpUseDateBuyBlock2",
   "InpUseDateSellBlock",
   "InpUseEMACrossEntry",
   "InpUseMomentumCandle",
   "InpUseEngulfing",
   "InpUseBOS",
   "InpUseLiquiditySweep",
   "InpMinimumConfirmations",
   "InpUseAdaptiveReverse",
   "InpAdaptiveSlopeThresholdPts",
   "InpMinRiskReward",
   "InpStopATRMultiplier",
   "InpTakeProfitATRMultiplier",
   "InpUseBreakEven",
   "InpUseATRTrailing",
   "InpMaxDailyLossPercent",
   "InpMaxWeeklyLossPercent",
   "InpMaxMonthlyLossPercent",
   "InpMaxEquityDrawdownPercent",
   "InpUseProfitGivebackGuard",
   "InpDailyProfitGivebackPercent",
   "InpWeeklyProfitGivebackPercent",
   "InpMonthlyProfitGivebackPercent",
   "InpMinProfitToProtectPercent",
   "InpShowDashboard",
   "InpDashboardInTester",
   "InpLogLevel",
   "InpTesterFitnessMode",
   "InpTesterMinTrades",
   "InpTesterMaxDrawdownPercent",
   "InpTesterMinProfitFactor",
   "InpTesterDrawdownPenalty",
   "InpTesterTradeCountPenalty"
)

function Get-SourceInputs {
   param([string]$Path)

   $inputs = New-Object System.Collections.Generic.List[object]
   foreach($match in (Select-String -LiteralPath $Path -Pattern '^\s*input\s+(?!group\b).+?\s+(Inp[A-Za-z0-9_]+)\s*=')) {
      $name = $match.Matches[0].Groups[1].Value
      $inputs.Add([pscustomobject]@{
         Name = $name
         Line = $match.LineNumber
         Text = $match.Line.Trim()
      }) | Out-Null
   }
   return $inputs.ToArray()
}

function Get-SetInputs {
   param([string]$Path)

   $inputs = New-Object System.Collections.Generic.List[object]
   $lineNumber = 0
   foreach($line in (Get-Content -LiteralPath $Path)) {
      $lineNumber++
      if($line -notmatch '^(Inp[A-Za-z0-9_]+)=') { continue }
      $parts = $line -split '=', 2
      $value = (($parts[1] -split '\|\|', 2)[0]).Trim()
      $inputs.Add([pscustomobject]@{
         Name = $parts[0]
         Value = $value
         Line = $lineNumber
         Text = $line
      }) | Out-Null
   }
   return $inputs.ToArray()
}

$sourceInputs = Get-SourceInputs -Path $SourcePath
$sourceNames = @($sourceInputs | Select-Object -ExpandProperty Name)
$sourceNameSet = @{}
foreach($name in $sourceNames) { $sourceNameSet[$name] = $true }

$criticalSet = @{}
foreach($name in $criticalInputs) { $criticalSet[$name] = $true }

$profileFiles = @(
   "ROBUST_BOS_SWEEP_PROFILE.set",
   "CANDIDATE_RISK16_SL18_TP38_PROFILE.set",
   "CANDIDATE_RISK16_SL16_TP38_PROFILE.set",
   "CANDIDATE_RISK16_SL18_TP35_GIVEBACK_PROFILE.set"
) | ForEach-Object { Join-Path $OutputsDir $_ } | Where-Object { Test-Path -LiteralPath $_ }

$rows = New-Object System.Collections.Generic.List[object]
$valueRows = New-Object System.Collections.Generic.List[object]

foreach($file in $profileFiles) {
   $inputs = Get-SetInputs -Path $file
   $names = @($inputs | Select-Object -ExpandProperty Name)
   $duplicates = @($names | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name)
   $unknown = @($names | Where-Object { -not $sourceNameSet.ContainsKey($_) } | Sort-Object -Unique)
   $missingCritical = @($criticalInputs | Where-Object { $names -notcontains $_ })
   $extraNonCritical = @($names | Where-Object { -not $criticalSet.ContainsKey($_) } | Sort-Object -Unique)
   $status = if($duplicates.Count -eq 0 -and $unknown.Count -eq 0 -and $missingCritical.Count -eq 0) { "PASS" } else { "FAIL" }

   $rows.Add([pscustomobject]@{
      ProfileFile = Split-Path $file -Leaf
      Status = $status
      SourceInputCount = $sourceNames.Count
      ProfileInputCount = $names.Count
      CriticalInputsRequired = $criticalInputs.Count
      MissingCriticalInputs = ($missingCritical -join ";")
      DuplicateInputs = ($duplicates -join ";")
      UnknownInputs = ($unknown -join ";")
      ExtraNonCriticalPinnedInputs = ($extraNonCritical -join ";")
   }) | Out-Null

   foreach($input in $inputs) {
      if($criticalSet.ContainsKey($input.Name)) {
         $valueRows.Add([pscustomobject]@{
            ProfileFile = Split-Path $file -Leaf
            Input = $input.Name
            Value = $input.Value
         }) | Out-Null
      }
   }
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Profile Input Audit") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated from the local EA source and active `.set` profiles. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("- EA source: ``$SourcePath``") | Out-Null
$report.Add("- Source inputs discovered: " + $sourceNames.Count) | Out-Null
$report.Add("- Critical inputs required per active profile: " + $criticalInputs.Count) | Out-Null
$report.Add("") | Out-Null
$report.Add("## Profile Status") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Profile | Status | Inputs | Missing Critical | Duplicates | Unknown |") | Out-Null
$report.Add("| --- | --- | ---: | --- | --- | --- |") | Out-Null
foreach($row in $rows) {
   $missing = if([string]::IsNullOrWhiteSpace($row.MissingCriticalInputs)) { "" } else { $row.MissingCriticalInputs }
   $dups = if([string]::IsNullOrWhiteSpace($row.DuplicateInputs)) { "" } else { $row.DuplicateInputs }
   $unknown = if([string]::IsNullOrWhiteSpace($row.UnknownInputs)) { "" } else { $row.UnknownInputs }
   $report.Add("| ``$($row.ProfileFile)`` | $($row.Status) | $($row.ProfileInputCount) | $missing | $dups | $unknown |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Critical Input Values") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Input | ROBUST | SL18 TP38 | SL16 TP38 | Giveback |") | Out-Null
$report.Add("| --- | ---: | ---: | ---: | ---: |") | Out-Null

$byProfile = @{}
foreach($profile in $profileFiles) {
   $leaf = Split-Path $profile -Leaf
   $byProfile[$leaf] = @{}
}
foreach($row in $valueRows) {
   $byProfile[$row.ProfileFile][$row.Input] = $row.Value
}

foreach($name in $criticalInputs) {
   $robust = $byProfile["ROBUST_BOS_SWEEP_PROFILE.set"][$name]
   $sl18 = $byProfile["CANDIDATE_RISK16_SL18_TP38_PROFILE.set"][$name]
   $sl16 = $byProfile["CANDIDATE_RISK16_SL16_TP38_PROFILE.set"][$name]
   $giveback = $byProfile["CANDIDATE_RISK16_SL18_TP35_GIVEBACK_PROFILE.set"][$name]
   $report.Add("| ``$name`` | ``$robust`` | ``$sl18`` | ``$sl16`` | ``$giveback`` |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Why This Matters") | Out-Null
$report.Add("") | Out-Null
$report.Add("MT5 can reuse cached tester input values when a config omits inputs. This audit ensures the active promoted and queued profiles pin all critical risk, entry, exit, giveback, logging, and optimizer inputs before validation.") | Out-Null

Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8

$rows
