Set-StrictMode -Version Latest

function Import-SetInputs {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { throw "Set file missing: $Path" }
   $map = @{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if([string]::IsNullOrWhiteSpace($line)) { continue }
      $idx = $line.IndexOf("=")
      if($idx -lt 1) { continue }
      $map[$line.Substring(0, $idx)] = $line
   }
   return $map
}

function Set-InputLine {
   param($Inputs, [string]$Name, [string]$Value)
   if($Name -in @("InpAllowedSymbol", "InpLogFileName", "InpNewsTimesCsv", "InpCorrelationSymbol", "InpBlockReasonDiagnosticsFile", "InpRealAccountApprovalCode", "InpRealAccountApprovalProfileId", "InpRealAccountApprovalSourceHash", "InpEvidenceProfileId", "InpEvidenceSourceHash", "InpEvidenceRunLabel")) {
      $Inputs[$Name] = "$Name=$Value"
      return
   }
   $Inputs[$Name] = "$Name=$Value||$Value||0||0||N"
}

function Merge-Overrides {
   param([hashtable[]]$Maps)
   $merged = @{}
   foreach($map in $Maps) {
      foreach($entry in $map.GetEnumerator()) {
         $merged[$entry.Key] = $entry.Value
      }
   }
   return $merged
}

function New-MonthGate {
   param([int[]]$Months)
   $gate = @{
      InpUseMonthFilter = "true"
      InpTradeJanuary = "false"
      InpTradeFebruary = "false"
      InpTradeMarch = "false"
      InpTradeApril = "false"
      InpTradeMay = "false"
      InpTradeJune = "false"
      InpTradeJuly = "false"
      InpTradeAugust = "false"
      InpTradeSeptember = "false"
      InpTradeOctober = "false"
      InpTradeNovember = "false"
      InpTradeDecember = "false"
   }
   foreach($month in $Months) {
      switch($month) {
         1 { $gate.InpTradeJanuary = "true" }
         2 { $gate.InpTradeFebruary = "true" }
         3 { $gate.InpTradeMarch = "true" }
         4 { $gate.InpTradeApril = "true" }
         5 { $gate.InpTradeMay = "true" }
         6 { $gate.InpTradeJune = "true" }
         7 { $gate.InpTradeJuly = "true" }
         8 { $gate.InpTradeAugust = "true" }
         9 { $gate.InpTradeSeptember = "true" }
         10 { $gate.InpTradeOctober = "true" }
         11 { $gate.InpTradeNovember = "true" }
         12 { $gate.InpTradeDecember = "true" }
      }
   }
   return $gate
}

function New-WeakMfeOverrides {
   return @{
      InpUseMonthStartFilter = "true"
      InpMonthStartMinDay = "3"
      InpUseWeakRegimeEntryBlock = "true"
      InpWeakRegimeLookbackBars = "18"
      InpWeakRegimeMaxNetMoveATR = "0.85"
      InpWeakRegimeMinAlternationPercent = "55.0"
      InpWeakRegimeMaxADX = "20.0"
      InpWeakRegimeSlopeLookbackBars = "8"
      InpWeakRegimeMaxSlopePoints = "55.0"
      InpWeakRegimeMinScore = "3"
      InpWeakRegimeQualityBypassScore = "14"
      InpWeakRegimeBlockDiagnosticFallback = "true"
      InpWeakRegimeAllowLiquiditySweep = "true"
      InpUseMFEGivebackExit = "true"
      InpMFEGivebackStartR = "1.35"
      InpMFEGivebackMaxGivebackR = "0.85"
      InpMFEGivebackMinCloseR = "0.25"
      InpUseRunnerExitPatience = "true"
   }
}

function Write-SeasonalTesterConfig {
   param(
      [string]$Path,
      [string]$ReportRoot,
      [string]$ReportName,
      [string]$From,
      [string]$To,
      $Inputs,
      [int]$Model = 2
   )
   # MT5 command-line tester silently skips report export for absolute Report=
   # paths on this install. Use a plain filename, then the runner collects it
   # from the terminal data root and routes it to the intended package folder.
   $reportFileName = [System.IO.Path]::GetFileName($ReportName)
   $lines = @(
      "[Tester]",
      "Expert=Professional_XAUUSD_EA.ex5",
      "Symbol=XAUUSD",
      "Period=15",
      "Optimization=0",
      "Model=$Model",
      "FromDate=$From",
      "ToDate=$To",
      "ForwardMode=0",
      "Deposit=1000",
      "Currency=USD",
      "ProfitInPips=0",
      "Leverage=100",
      "ExecutionMode=0",
      "OptimizationCriterion=6",
      "Visual=0",
      "Report=$reportFileName",
      "ReplaceReport=1",
      "ShutdownTerminal=1",
      "[TesterInputs]"
   )
   foreach($key in ($Inputs.Keys | Sort-Object)) { $lines += $Inputs[$key] }
   Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII
}
