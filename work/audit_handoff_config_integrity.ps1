param(
   [string]$ManifestPath = "outputs\next_test_handoff\HANDOFF_MANIFEST.csv",
   [string]$OutCsv = "outputs\HANDOFF_CONFIG_INTEGRITY.csv",
   [string]$OutMarkdown = "outputs\HANDOFF_CONFIG_INTEGRITY.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-IniValues {
   param([Parameter(Mandatory = $true)][string]$Path)

   $values = @{}
   $section = ""

   foreach($rawLine in (Get-Content -LiteralPath $Path)) {
      $line = $rawLine.Trim()
      if($line.Length -eq 0 -or $line.StartsWith(";") -or $line.StartsWith("#")) {
         continue
      }

      if($line.StartsWith("[") -and $line.EndsWith("]")) {
         $section = $line.Trim("[", "]")
         continue
      }

      $eq = $line.IndexOf("=")
      if($eq -lt 1) {
         continue
      }

      $key = $line.Substring(0, $eq).Trim()
      $value = $line.Substring($eq + 1).Trim()
      $values["$section.$key"] = $value
   }

   return $values
}

function Add-Check {
   param(
      [System.Collections.Generic.List[object]]$Checks,
      [Parameter(Mandatory = $true)][string]$Name,
      [Parameter(Mandatory = $true)][bool]$Passed,
      [Parameter(Mandatory = $true)][string]$Expected,
      [Parameter(Mandatory = $true)][string]$Actual
   )

   $Checks.Add([pscustomobject]@{
      Check = $Name
      Passed = $Passed
      Expected = $Expected
      Actual = $Actual
   }) | Out-Null
}

function Get-InputValue {
   param(
      [Parameter(Mandatory = $true)][hashtable]$Values,
      [Parameter(Mandatory = $true)][string]$Name
   )

   $key = "TesterInputs.$Name"
   if(!$Values.ContainsKey($key)) {
      return $null
   }

   return ([string]$Values[$key]).Split("||")[0]
}

if(!(Test-Path -LiteralPath $ManifestPath)) {
   throw "Handoff manifest not found: $ManifestPath"
}

$manifest = Import-Csv -LiteralPath $ManifestPath
if($manifest.Count -eq 0) {
   throw "Handoff manifest has no rows: $ManifestPath"
}

$rows = New-Object System.Collections.Generic.List[object]
$criticalInputs = [ordered]@{
   InpRiskPercent = $null
   InpUseDateBuyBlock = "false"
   InpUseDateBuyBlock2 = "false"
   InpUseDateSellBlock = "false"
   InpUseEMACrossEntry = "false"
   InpUseMomentumCandle = "false"
   InpUseEngulfing = "false"
   InpUseBOS = "true"
   InpUseLiquiditySweep = "true"
   InpMinimumConfirmations = "2"
   InpUseAdaptiveReverse = "true"
   InpMinRiskReward = $null
   InpStopATRMultiplier = $null
   InpTakeProfitATRMultiplier = $null
   InpUseBreakEven = $null
   InpUseATRTrailing = "true"
   InpMaxDailyLossPercent = "1.00"
   InpMaxWeeklyLossPercent = "2.50"
   InpMaxMonthlyLossPercent = "4.00"
   InpMaxEquityDrawdownPercent = $null
   InpShowDashboard = "false"
   InpDashboardInTester = "false"
   InpLogLevel = "0"
   InpTesterFitnessMode = "1"
}

foreach($item in $manifest) {
   $config = [string]$item.HandoffConfig
   if(!(Test-Path -LiteralPath $config)) {
      $rows.Add([pscustomobject]@{
         Rank = $item.Rank
         Profile = $item.Profile
         Phase = $item.Phase
         Set = $item.Set
         Window = $item.Window
         Config = $config
         Passed = $false
         FailedChecks = "config_exists"
         Sha256 = ""
      }) | Out-Null
      continue
   }

   $values = Read-IniValues -Path $config
   $checks = New-Object System.Collections.Generic.List[object]

   Add-Check $checks "Expert" ($values["Tester.Expert"] -eq "Professional_XAUUSD_EA.ex5") "Professional_XAUUSD_EA.ex5" ([string]$values["Tester.Expert"])
   Add-Check $checks "Symbol" ($values["Tester.Symbol"] -eq "XAUUSD") "XAUUSD" ([string]$values["Tester.Symbol"])
   Add-Check $checks "Period" ($values["Tester.Period"] -eq "M15") "M15" ([string]$values["Tester.Period"])
   Add-Check $checks "Optimization" ($values["Tester.Optimization"] -eq "0") "0" ([string]$values["Tester.Optimization"])
   Add-Check $checks "Visual" ($values["Tester.Visual"] -eq "0") "0" ([string]$values["Tester.Visual"])
   Add-Check $checks "ShutdownTerminal" ($values["Tester.ShutdownTerminal"] -eq "1") "1" ([string]$values["Tester.ShutdownTerminal"])
   Add-Check $checks "Model" ($values["Tester.Model"] -eq [string]$item.Model) ([string]$item.Model) ([string]$values["Tester.Model"])
   Add-Check $checks "FromDate" ($values["Tester.FromDate"] -eq [string]$item.From) ([string]$item.From) ([string]$values["Tester.FromDate"])
   Add-Check $checks "ToDate" ($values["Tester.ToDate"] -eq [string]$item.To) ([string]$item.To) ([string]$values["Tester.ToDate"])
   Add-Check $checks "ReportName" (([string]$values["Tester.Report"]) -like "*$($item.ExpectedReportName)") "*$($item.ExpectedReportName)" ([string]$values["Tester.Report"])
   Add-Check $checks "ReplaceReport" ($values["Tester.ReplaceReport"] -eq "1") "1" ([string]$values["Tester.ReplaceReport"])

   foreach($inputName in $criticalInputs.Keys) {
      $actual = Get-InputValue -Values $values -Name $inputName
      $expected = $criticalInputs[$inputName]
      if($inputName -eq "InpMaxEquityDrawdownPercent") {
         $expected = if([string]$item.Profile -eq "baseline_promoted") { "0.00" } else { "4.00" }
      }
      $exists = $null -ne $actual
      $matches = $exists -and (($null -eq $expected) -or ($actual -eq $expected))
      $expectedLabel = if($null -eq $expected) { "present" } else { $expected }
      $actualLabel = if($exists) { $actual } else { "<missing>" }
      Add-Check $checks $inputName $matches $expectedLabel $actualLabel
   }

   $failed = @($checks | Where-Object { -not $_.Passed })
   $hash = (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash
   $rows.Add([pscustomobject]@{
      Rank = [int]$item.Rank
      Profile = $item.Profile
      Phase = $item.Phase
      Set = $item.Set
      Window = $item.Window
      Config = $config
      Passed = ($failed.Count -eq 0)
      FailedChecks = (($failed | ForEach-Object { "$($_.Check): expected $($_.Expected), got $($_.Actual)" }) -join "; ")
      Sha256 = $hash
   }) | Out-Null
}

$rows | Sort-Object Rank | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$failedRows = @($rows | Where-Object { -not $_.Passed })
$passedCount = ($rows.Count - $failedRows.Count)
$zipPath = "outputs\next_test_handoff.zip"
$zipHash = if(Test-Path -LiteralPath $zipPath) { (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash } else { "" }

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Handoff Config Integrity") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline audit only. This script does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Manifest: ``$ManifestPath``") | Out-Null
$md.Add("- Configs checked: $($rows.Count)") | Out-Null
$md.Add("- Passed: $passedCount") | Out-Null
$md.Add("- Failed: $($failedRows.Count)") | Out-Null
if($zipHash.Length -gt 0) {
   $md.Add("- Handoff zip SHA256: ``$zipHash``") | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Required Safety Settings") | Out-Null
$md.Add("") | Out-Null
$md.Add("- ``Visual=0``") | Out-Null
$md.Add("- ``ShutdownTerminal=1``") | Out-Null
$md.Add("- ``Optimization=0``") | Out-Null
$md.Add("- ``Expert=Professional_XAUUSD_EA.ex5``") | Out-Null
$md.Add("- ``Symbol=XAUUSD``") | Out-Null
$md.Add("- dashboard/log verbosity disabled for tester handoff") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Results") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Rank | Profile | Phase | Set | Window | Passed | SHA256 | Failed Checks |") | Out-Null
$md.Add("|---:|---|---|---|---|---|---|---|") | Out-Null
foreach($row in ($rows | Sort-Object Rank)) {
   $shortHash = if($row.Sha256.Length -ge 12) { $row.Sha256.Substring(0, 12) } else { $row.Sha256 }
   $failedText = if([string]::IsNullOrWhiteSpace($row.FailedChecks)) { "" } else { ($row.FailedChecks -replace '\|', '/') }
   $md.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Phase) | $($row.Set) | $($row.Window) | $($row.Passed) | ``$shortHash`` | $failedText |") | Out-Null
}

Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8

[pscustomobject]@{
   Checked = $rows.Count
   Passed = $passedCount
   Failed = $failedRows.Count
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
   ZipSha256 = $zipHash
}

if($failedRows.Count -gt 0) {
   exit 1
}
