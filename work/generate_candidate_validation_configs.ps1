param(
   [string]$RepoRoot = (Resolve-Path ".").Path,
   [string]$OutputDir = "work\generated_validation"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$outputRoot = Join-Path $RepoRoot $OutputDir
$profiles = @(
   [pscustomobject]@{
      Name = "risk160_sl16_tp38"
      Settings = "outputs\CANDIDATE_RISK16_SL16_TP38_PROFILE.set"
      Priority = 1
   },
   [pscustomobject]@{
      Name = "risk160_sl18_tp38"
      Settings = "outputs\CANDIDATE_RISK16_SL18_TP38_PROFILE.set"
      Priority = 2
   },
   [pscustomobject]@{
      Name = "promoted_risk160_sl18_tp35"
      Settings = "outputs\ROBUST_BOS_SWEEP_PROFILE.set"
      Priority = 3
   }
)

$windows = @(
   [pscustomobject]@{ Set = "split"; Name = "2024"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Set = "split"; Name = "2025"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Set = "split"; Name = "2026_ytd"; From = "2026.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Set = "split"; Name = "2024_H1"; From = "2024.01.01"; To = "2024.06.30" },
   [pscustomobject]@{ Set = "split"; Name = "2024_H2"; From = "2024.07.01"; To = "2024.12.31" },
   [pscustomobject]@{ Set = "split"; Name = "2025_H1"; From = "2025.01.01"; To = "2025.06.30" },
   [pscustomobject]@{ Set = "split"; Name = "2025_H2"; From = "2025.07.01"; To = "2025.12.31" },
   [pscustomobject]@{ Set = "split"; Name = "2026_H1"; From = "2026.01.01"; To = "2026.06.30" },
   [pscustomobject]@{ Set = "split"; Name = "full"; From = "2024.01.01"; To = "2026.07.02" }
)

$quarters = @(
   @("2024_Q1", "2024.01.01", "2024.03.31"),
   @("2024_Q2", "2024.04.01", "2024.06.30"),
   @("2024_Q3", "2024.07.01", "2024.09.30"),
   @("2024_Q4", "2024.10.01", "2024.12.31"),
   @("2025_Q1", "2025.01.01", "2025.03.31"),
   @("2025_Q2", "2025.04.01", "2025.06.30"),
   @("2025_Q3", "2025.07.01", "2025.09.30"),
   @("2025_Q4", "2025.10.01", "2025.12.31"),
   @("2026_Q1", "2026.01.01", "2026.03.31"),
   @("2026_Q2", "2026.04.01", "2026.06.30")
)

foreach($q in $quarters) {
   $windows += [pscustomobject]@{ Set = "quarter"; Name = $q[0]; From = $q[1]; To = $q[2] }
}

for($year = 2024; $year -le 2026; $year++) {
   $lastMonth = if($year -eq 2026) { 6 } else { 12 }
   for($month = 1; $month -le $lastMonth; $month++) {
      $from = Get-Date -Year $year -Month $month -Day 1
      $to = $from.AddMonths(1).AddDays(-1)
      $windows += [pscustomobject]@{
         Set = "month"
         Name = "{0}_{1:00}" -f $year, $month
         From = $from.ToString("yyyy.MM.dd", [Globalization.CultureInfo]::InvariantCulture)
         To = $to.ToString("yyyy.MM.dd", [Globalization.CultureInfo]::InvariantCulture)
      }
   }
}

function New-ConfigText {
   param(
      [object]$Profile,
      [object]$Window,
      [string]$Inputs
   )

   $reportPath = Join-Path $RepoRoot ("outputs\validation_{0}_{1}_{2}" -f $Profile.Name, $Window.Set, $Window.Name)
   return @"
[Tester]
Expert=Professional_XAUUSD_EA.ex5
Symbol=XAUUSD
Period=M15
Optimization=0
Model=4
FromDate=$($Window.From)
ToDate=$($Window.To)
ForwardMode=0
Deposit=1000
Currency=USD
ProfitInPips=0
Leverage=100
ExecutionMode=0
OptimizationCriterion=6
Visual=0
Report=$reportPath
ReplaceReport=1
ShutdownTerminal=1
[TesterInputs]
$Inputs
"@
}

New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
$manifest = New-Object System.Collections.Generic.List[object]

foreach($profile in ($profiles | Sort-Object Priority)) {
   $settingsPath = Join-Path $RepoRoot $profile.Settings
   if(!(Test-Path -LiteralPath $settingsPath)) {
      throw "Settings file not found: $settingsPath"
   }

   $profileDir = Join-Path $outputRoot $profile.Name
   New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
   $inputs = (Get-Content -LiteralPath $settingsPath) -join "`r`n"

   foreach($window in $windows) {
      $setDir = Join-Path $profileDir $window.Set
      New-Item -ItemType Directory -Force -Path $setDir | Out-Null
      $configPath = Join-Path $setDir ("{0}_{1}.ini" -f $profile.Name, $window.Name)
      New-ConfigText -Profile $profile -Window $window -Inputs $inputs |
         Set-Content -LiteralPath $configPath -Encoding ASCII

      $manifest.Add([pscustomobject]@{
         Priority = $profile.Priority
         Profile = $profile.Name
         Set = $window.Set
         Window = $window.Name
         From = $window.From
         To = $window.To
         Config = $configPath.Replace($RepoRoot + "\", "")
      }) | Out-Null
   }
}

$manifestPath = Join-Path $outputRoot "VALIDATION_MANIFEST.csv"
$manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation

$readme = @(
   '# Generated Candidate Validation Configs',
   '',
   'Generated without launching MT5.',
   '',
   'Profiles are ordered for the next safe validation run:',
   '',
   '1. `risk160_sl16_tp38`',
   '2. `risk160_sl18_tp38`',
   '3. `promoted_risk160_sl18_tp35` baseline comparison',
   '',
   'Each profile has `split`, `quarter`, and `month` configs.',
   '',
   'Do not execute these configs locally until the hidden-desktop MT5 launcher has been deliberately verified and `ALLOW_MT5_FOCUS_RISK=1` is set.',
   '',
   'Manifest: `VALIDATION_MANIFEST.csv`'
)

Set-Content -LiteralPath (Join-Path $outputRoot "README.md") -Value $readme -Encoding UTF8

$manifest | Group-Object Profile, Set | Select-Object Name, Count
