param(
   [string]$OutputsDir = "outputs",
   [string]$OutCsv = "outputs\PROMOTION_GATE_STATUS.csv",
   [string]$OutReport = "outputs\PROMOTION_GATE_REPORT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function To-Double {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return 0.0 }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Import-ResultRows {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { return @() }
   try { return @(Import-Csv -LiteralPath $Path) }
   catch { return @() }
}

function Get-NetProfitList {
   param([object[]]$Rows)
   $values = @()
   foreach($row in $Rows) {
      if($row.PSObject.Properties.Name -contains "NetProfit") {
         $values += To-Double $row.NetProfit
      }
   }
   return @($values)
}

function New-Evidence {
   param(
      [string]$Profile,
      [string]$Set,
      [object[]]$Rows,
      [int]$RequiredWindows,
      [string]$Source
   )

   $profits = @(Get-NetProfitList -Rows $Rows)
   $windows = $profits.Count
   $total = if($windows -gt 0) { ($profits | Measure-Object -Sum).Sum } else { 0.0 }
   $worst = if($windows -gt 0) { ($profits | Measure-Object -Minimum).Minimum } else { $null }
   $losing = @($profits | Where-Object { $_ -lt 0 }).Count
   $complete = $windows -ge $RequiredWindows
   $passes = $complete -and $total -gt 0 -and $null -ne $worst -and $worst -ge 0 -and $losing -eq 0

   return [pscustomobject]@{
      Profile = $Profile
      Set = $Set
      Source = $Source
      RequiredWindows = $RequiredWindows
      ObservedWindows = $windows
      Complete = $complete
      TotalNetProfit = [Math]::Round($total, 2)
      WorstWindowNetProfit = if($null -eq $worst) { "" } else { [Math]::Round($worst, 2) }
      LosingWindows = $losing
      PassesSetGate = $passes
   }
}

if(!(Test-Path -LiteralPath $OutputsDir)) {
   throw "Outputs directory not found: $OutputsDir"
}

$profiles = @(
   [pscustomobject]@{
      Name = "promoted_risk160_sl18_tp35"
      Description = "Current promoted robust BOS/sweep profile"
      Full = "BOS_SWEEP_SPLITS_risk1p6_sl18_tp35.csv"
      Split = "BOS_SWEEP_SPLITS_risk1p6_sl18_tp35.csv"
      QuarterMonth = "BOS_SWEEP_WINDOWS_risk1p6_sl18_tp35.csv"
   },
   [pscustomobject]@{
      Name = "risk160_sl18_tp38"
      Description = "Queued TP extension candidate"
      Full = ""
      Split = ""
      QuarterMonth = ""
   },
   [pscustomobject]@{
      Name = "risk160_sl16_tp38"
      Description = "Queued tighter-stop TP extension candidate"
      Full = ""
      Split = ""
      QuarterMonth = ""
   },
   [pscustomobject]@{
      Name = "risk160_sl18_tp35_giveback"
      Description = "Queued profit-giveback guard candidate"
      Full = ""
      Split = ""
      QuarterMonth = ""
   }
)

$evidence = New-Object System.Collections.Generic.List[object]

foreach($profile in $profiles) {
   $splitRows = @()
   if(![string]::IsNullOrWhiteSpace($profile.Split)) {
      $splitRows = Import-ResultRows -Path (Join-Path $OutputsDir $profile.Split)
   }
   $fullRows = @($splitRows | Where-Object {
      ($_.PSObject.Properties.Name -contains "Window" -and $_.Window -eq "full") -or
      ($_.PSObject.Properties.Name -contains "Name" -and $_.Name -eq "full")
   })
   if($fullRows.Count -eq 0 -and ![string]::IsNullOrWhiteSpace($profile.Full)) {
      $fullRows = @(Import-ResultRows -Path (Join-Path $OutputsDir $profile.Full) | Where-Object {
         ($_.PSObject.Properties.Name -contains "Window" -and $_.Window -eq "full") -or
         ($_.PSObject.Properties.Name -contains "Name" -and $_.Name -eq "full")
      })
   }

   $qmRows = @()
   if(![string]::IsNullOrWhiteSpace($profile.QuarterMonth)) {
      $qmRows = Import-ResultRows -Path (Join-Path $OutputsDir $profile.QuarterMonth)
   }
   $quarterRows = @($qmRows | Where-Object {
      ($_.PSObject.Properties.Name -contains "Set" -and $_.Set -eq "quarter") -or
      ($_.PSObject.Properties.Name -contains "Window" -and $_.Window -match "_Q[1-4]$")
   })
   $monthRows = @($qmRows | Where-Object {
      ($_.PSObject.Properties.Name -contains "Set" -and $_.Set -eq "month") -or
      ($_.PSObject.Properties.Name -contains "Window" -and $_.Window -match "^\d{4}_\d{2}$")
   })

   $evidence.Add((New-Evidence -Profile $profile.Name -Set "full" -Rows $fullRows -RequiredWindows 1 -Source $profile.Full)) | Out-Null
   $evidence.Add((New-Evidence -Profile $profile.Name -Set "split" -Rows $splitRows -RequiredWindows 9 -Source $profile.Split)) | Out-Null
   $evidence.Add((New-Evidence -Profile $profile.Name -Set "quarter" -Rows $quarterRows -RequiredWindows 10 -Source $profile.QuarterMonth)) | Out-Null
   $evidence.Add((New-Evidence -Profile $profile.Name -Set "month" -Rows $monthRows -RequiredWindows 30 -Source $profile.QuarterMonth)) | Out-Null
}

$status = foreach($group in ($evidence | Group-Object Profile)) {
   $rows = @($group.Group)
   $missing = @($rows | Where-Object { -not $_.Complete })
   $failed = @($rows | Where-Object { $_.Complete -and -not $_.PassesSetGate })
   $allPass = $missing.Count -eq 0 -and $failed.Count -eq 0
   $total = ($rows | Where-Object { $_.Set -in @("full", "split", "quarter", "month") } | Measure-Object TotalNetProfit -Sum).Sum
   $worstValues = @($rows | Where-Object { "$($_.WorstWindowNetProfit)" -ne "" } | ForEach-Object { [double]$_.WorstWindowNetProfit })
   $worst = if($worstValues.Count -gt 0) { [Math]::Round(($worstValues | Measure-Object -Minimum).Minimum, 2) } else { "" }
   [pscustomobject]@{
      Profile = $group.Name
      PromotionStatus = if($allPass) { "PASS" } elseif($missing.Count -gt 0) { "MISSING_EVIDENCE" } else { "FAIL" }
      MissingSets = (($missing | Select-Object -ExpandProperty Set) -join ",")
      FailedSets = (($failed | Select-Object -ExpandProperty Set) -join ",")
      EvidenceSetsPassed = @($rows | Where-Object { $_.PassesSetGate }).Count
      EvidenceSetsRequired = 4
      AggregateNetProfitAcrossEvidenceSets = [Math]::Round($total, 2)
      WorstObservedWindow = $worst
   }
}

$status | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Promotion Gate Status") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated from existing local CSV evidence only. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("A profile passes only when full, split, quarter, and month evidence are present; each set must be profitable, have no losing windows, and have a worst window of at least `$0.00`.") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Profile Status") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Profile | Status | Passed Sets | Missing | Failed | Worst Observed |") | Out-Null
$report.Add("| --- | --- | ---: | --- | --- | ---: |") | Out-Null
foreach($row in $status) {
   $report.Add("| ``$($row.Profile)`` | $($row.PromotionStatus) | $($row.EvidenceSetsPassed)/$($row.EvidenceSetsRequired) | $($row.MissingSets) | $($row.FailedSets) | $($row.WorstObservedWindow) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Evidence Detail") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Profile | Set | Windows | Required | Total | Worst | Losing | Pass | Source |") | Out-Null
$report.Add("| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |") | Out-Null
foreach($row in $evidence) {
   $report.Add("| ``$($row.Profile)`` | $($row.Set) | $($row.ObservedWindows) | $($row.RequiredWindows) | $($row.TotalNetProfit) | $($row.WorstWindowNetProfit) | $($row.LosingWindows) | $($row.PassesSetGate) | ``$($row.Source)`` |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Next Action") | Out-Null
$report.Add("") | Out-Null
$report.Add("Keep the promoted profile as default. The TP-extension and giveback candidates still need full/month/quarter/split validation before they can replace it.") | Out-Null

Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8

$status
