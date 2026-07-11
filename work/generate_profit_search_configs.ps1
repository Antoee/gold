param(
   [string]$RepoRoot = (Resolve-Path ".").Path,
   [string]$BaseProfile = "outputs\ROBUST_BOS_SWEEP_PROFILE.set",
   [string]$OutputDir = "work\generated_profit_search"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-Settings {
   param([string]$Path)

   $settings = [ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if([string]::IsNullOrWhiteSpace($line)) { continue }
      if($line.TrimStart().StartsWith(";")) { continue }
      $parts = $line -split "=", 2
      if($parts.Count -ne 2) { continue }
      $settings[$parts[0].Trim()] = $parts[1].Trim()
   }
   return $settings
}

function Set-SettingValue {
   param(
      [System.Collections.Specialized.OrderedDictionary]$Settings,
      [string]$Name,
      [string]$Value
   )

   if($Settings.Contains($Name)) {
      $original = [string]$Settings[$Name]
      $fields = $original -split "\|\|", 5
      if($fields.Count -ge 5) {
         $Settings[$Name] = "$Value||$($fields[1])||$($fields[2])||$($fields[3])||$($fields[4])"
      } else {
         $Settings[$Name] = $Value
      }
   } else {
      $Settings[$Name] = $Value
   }
}

function New-SettingsText {
   param([System.Collections.Specialized.OrderedDictionary]$Settings)

   $lines = New-Object System.Collections.Generic.List[string]
   foreach($key in $Settings.Keys) {
      $lines.Add("$key=$($Settings[$key])") | Out-Null
   }
   return ($lines -join "`r`n")
}

function New-ConfigText {
   param(
      [object]$Candidate,
      [object]$Window,
      [string]$SettingsText,
      [string]$Model,
      [string]$Phase
   )

   $reportPath = Join-Path $RepoRoot ("outputs\profit_search_{0}_{1}_{2}_{3}" -f $Phase, $Candidate.Name, $Window.Set, $Window.Name)
   return @"
[Tester]
Expert=Professional_XAUUSD_EA.ex5
Symbol=XAUUSD
Period=M15
Optimization=0
Model=$Model
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
$SettingsText
"@
}

$basePath = Join-Path $RepoRoot $BaseProfile
if(!(Test-Path -LiteralPath $basePath)) {
   throw "Base profile not found: $basePath"
}

$outputRoot = Join-Path $RepoRoot $OutputDir
$profileRoot = Join-Path $outputRoot "profiles"
$phase1Root = Join-Path $outputRoot "phase1_fast_triage"
$phase2Root = Join-Path $outputRoot "phase2_real_tick_validation"
New-Item -ItemType Directory -Force -Path $profileRoot, $phase1Root, $phase2Root | Out-Null

$candidates = @(
   [pscustomobject]@{ Priority = 1;  Name = "baseline_promoted";               Phase2 = $true;  Overrides = @{} },
   [pscustomobject]@{ Priority = 2;  Name = "baseline_dd4";                    Phase2 = $true;  Overrides = @{} },
   [pscustomobject]@{ Priority = 3;  Name = "buyblock2_dd4";                   Phase2 = $true;  Overrides = @{ InpUseDateBuyBlock2 = "true"; InpBuyBlock2Start = "2025.07.01 00:00"; InpBuyBlock2End = "2025.12.31 23:59" } },
   [pscustomobject]@{ Priority = 4;  Name = "risk12_tp38_sl18";                Phase2 = $true;  Overrides = @{ InpRiskPercent = "1.20"; InpTakeProfitATRMultiplier = "3.80" } },
   [pscustomobject]@{ Priority = 5;  Name = "risk14_tp38_sl18";                Phase2 = $true;  Overrides = @{ InpRiskPercent = "1.40"; InpTakeProfitATRMultiplier = "3.80" } },
   [pscustomobject]@{ Priority = 6;  Name = "tp38_sl18";                       Phase2 = $true;  Overrides = @{ InpTakeProfitATRMultiplier = "3.80" } },
   [pscustomobject]@{ Priority = 7;  Name = "tp42_sl18";                       Phase2 = $true;  Overrides = @{ InpTakeProfitATRMultiplier = "4.20" } },
   [pscustomobject]@{ Priority = 8;  Name = "tp38_sl16";                       Phase2 = $true;  Overrides = @{ InpStopATRMultiplier = "1.60"; InpTakeProfitATRMultiplier = "3.80" } },
   [pscustomobject]@{ Priority = 9;  Name = "tp42_sl16";                       Phase2 = $true;  Overrides = @{ InpStopATRMultiplier = "1.60"; InpTakeProfitATRMultiplier = "4.20" } },
   [pscustomobject]@{ Priority = 10; Name = "tp45_sl18";                       Phase2 = $false; Overrides = @{ InpTakeProfitATRMultiplier = "4.50" } },
   [pscustomobject]@{ Priority = 11; Name = "tp38_sl20";                       Phase2 = $false; Overrides = @{ InpStopATRMultiplier = "2.00"; InpTakeProfitATRMultiplier = "3.80" } },
   [pscustomobject]@{ Priority = 12; Name = "trail14_tp38";                    Phase2 = $false; Overrides = @{ InpTakeProfitATRMultiplier = "3.80"; InpTrailATRMultiplier = "1.40" } },
   [pscustomobject]@{ Priority = 13; Name = "trail18_tp38";                    Phase2 = $false; Overrides = @{ InpTakeProfitATRMultiplier = "3.80"; InpTrailATRMultiplier = "1.80" } },
   [pscustomobject]@{ Priority = 14; Name = "rr18_tp42";                       Phase2 = $false; Overrides = @{ InpMinRiskReward = "1.80"; InpTakeProfitATRMultiplier = "4.20" } },
   [pscustomobject]@{ Priority = 15; Name = "risk18_tp38_sl18";                Phase2 = $false; Overrides = @{ InpRiskPercent = "1.80"; InpTakeProfitATRMultiplier = "3.80" } },
   [pscustomobject]@{ Priority = 16; Name = "risk20_tp38_sl18";                Phase2 = $false; Overrides = @{ InpRiskPercent = "2.00"; InpTakeProfitATRMultiplier = "3.80" } },
   [pscustomobject]@{ Priority = 17; Name = "risk14_tp42_sl16";                Phase2 = $false; Overrides = @{ InpRiskPercent = "1.40"; InpStopATRMultiplier = "1.60"; InpTakeProfitATRMultiplier = "4.20" } },
   [pscustomobject]@{ Priority = 18; Name = "giveback25_tp38";                 Phase2 = $false; Overrides = @{ InpTakeProfitATRMultiplier = "3.80"; InpUseProfitGivebackGuard = "true"; InpDailyProfitGivebackPercent = "25.0"; InpWeeklyProfitGivebackPercent = "25.0"; InpMonthlyProfitGivebackPercent = "25.0" } },
   [pscustomobject]@{ Priority = 19; Name = "giveback35_tp38";                 Phase2 = $false; Overrides = @{ InpTakeProfitATRMultiplier = "3.80"; InpUseProfitGivebackGuard = "true" } },
   [pscustomobject]@{ Priority = 20; Name = "be12_tp38";                       Phase2 = $false; Overrides = @{ InpTakeProfitATRMultiplier = "3.80"; InpUseBreakEven = "true"; InpBreakEvenTriggerR = "1.20"; InpBreakEvenBufferPoints = "20" } },
   [pscustomobject]@{ Priority = 21; Name = "maxstop25_dd4";                   Phase2 = $false; Overrides = @{ InpMaxStopATRMultiplier = "2.50" } },
   [pscustomobject]@{ Priority = 22; Name = "maxstop20_dd4";                   Phase2 = $false; Overrides = @{ InpMaxStopATRMultiplier = "2.00" } }
)

$phase1Windows = @(
   [pscustomobject]@{ Set = "stress"; Name = "2024_Q1"; From = "2024.01.01"; To = "2024.03.31" },
   [pscustomobject]@{ Set = "stress"; Name = "2024_Q3"; From = "2024.07.01"; To = "2024.09.30" },
   [pscustomobject]@{ Set = "stress"; Name = "2025_Q2"; From = "2025.04.01"; To = "2025.06.30" },
   [pscustomobject]@{ Set = "stress"; Name = "2025_Q3"; From = "2025.07.01"; To = "2025.09.30" },
   [pscustomobject]@{ Set = "opportunity"; Name = "2024_Q4"; From = "2024.10.01"; To = "2024.12.31" },
   [pscustomobject]@{ Set = "opportunity"; Name = "2025_Q1"; From = "2025.01.01"; To = "2025.03.31" },
   [pscustomobject]@{ Set = "opportunity"; Name = "2026_Q2"; From = "2026.04.01"; To = "2026.06.30" },
   [pscustomobject]@{ Set = "recent"; Name = "2026_ytd"; From = "2026.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Set = "full"; Name = "full"; From = "2024.01.01"; To = "2026.07.02" }
)

$phase2Windows = @(
   [pscustomobject]@{ Set = "split"; Name = "2024"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Set = "split"; Name = "2025"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Set = "split"; Name = "2026_ytd"; From = "2026.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Set = "split"; Name = "full"; From = "2024.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Set = "quarter"; Name = "2024_Q1"; From = "2024.01.01"; To = "2024.03.31" },
   [pscustomobject]@{ Set = "quarter"; Name = "2024_Q3"; From = "2024.07.01"; To = "2024.09.30" },
   [pscustomobject]@{ Set = "quarter"; Name = "2025_Q2"; From = "2025.04.01"; To = "2025.06.30" },
   [pscustomobject]@{ Set = "quarter"; Name = "2025_Q3"; From = "2025.07.01"; To = "2025.09.30" },
   [pscustomobject]@{ Set = "quarter"; Name = "2024_Q4"; From = "2024.10.01"; To = "2024.12.31" },
   [pscustomobject]@{ Set = "quarter"; Name = "2025_Q1"; From = "2025.01.01"; To = "2025.03.31" },
   [pscustomobject]@{ Set = "quarter"; Name = "2026_Q2"; From = "2026.04.01"; To = "2026.06.30" }
)

$baseSettings = Read-Settings -Path $basePath
$protectedRiskOverrides = [ordered]@{
   InpMaxEquityDrawdownPercent = "4.00"
}
$profileManifest = New-Object System.Collections.Generic.List[object]
$configManifest = New-Object System.Collections.Generic.List[object]

foreach($candidate in ($candidates | Sort-Object Priority)) {
   $settings = [ordered]@{}
   foreach($key in $baseSettings.Keys) {
      $settings[$key] = $baseSettings[$key]
   }
   if($candidate.Name -ne "baseline_promoted") {
      foreach($override in $protectedRiskOverrides.GetEnumerator()) {
         Set-SettingValue -Settings $settings -Name $override.Key -Value ([string]$override.Value)
      }
   }
   foreach($override in $candidate.Overrides.GetEnumerator()) {
      Set-SettingValue -Settings $settings -Name $override.Key -Value ([string]$override.Value)
   }

   $settingsText = New-SettingsText -Settings $settings
   $profilePath = Join-Path $profileRoot ("{0}.set" -f $candidate.Name)
   Set-Content -LiteralPath $profilePath -Value $settingsText -Encoding ASCII

   $profileManifest.Add([pscustomobject]@{
      Priority = $candidate.Priority
      Profile = $candidate.Name
      Phase2Seed = $candidate.Phase2
      Settings = $profilePath.Replace($RepoRoot + "\", "")
      Overrides = (@(
         if($candidate.Name -ne "baseline_promoted") {
            $protectedRiskOverrides.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
         }
         $candidate.Overrides.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key)=$($_.Value)" }
      ) -join ";")
   }) | Out-Null

   foreach($window in $phase1Windows) {
      $setDir = Join-Path (Join-Path $phase1Root $candidate.Name) $window.Set
      New-Item -ItemType Directory -Force -Path $setDir | Out-Null
      $configPath = Join-Path $setDir ("{0}_{1}.ini" -f $candidate.Name, $window.Name)
      New-ConfigText -Candidate $candidate -Window $window -SettingsText $settingsText -Model "2" -Phase "phase1" |
         Set-Content -LiteralPath $configPath -Encoding ASCII

      $configManifest.Add([pscustomobject]@{
         Phase = "phase1_fast_triage"
         Model = 2
         Priority = $candidate.Priority
         Profile = $candidate.Name
         Set = $window.Set
         Window = $window.Name
         From = $window.From
         To = $window.To
         Config = $configPath.Replace($RepoRoot + "\", "")
      }) | Out-Null
   }

   if($candidate.Phase2) {
      foreach($window in $phase2Windows) {
         $setDir = Join-Path (Join-Path $phase2Root $candidate.Name) $window.Set
         New-Item -ItemType Directory -Force -Path $setDir | Out-Null
         $configPath = Join-Path $setDir ("{0}_{1}.ini" -f $candidate.Name, $window.Name)
         New-ConfigText -Candidate $candidate -Window $window -SettingsText $settingsText -Model "4" -Phase "phase2" |
            Set-Content -LiteralPath $configPath -Encoding ASCII

         $configManifest.Add([pscustomobject]@{
            Phase = "phase2_real_tick_validation"
            Model = 4
            Priority = $candidate.Priority
            Profile = $candidate.Name
            Set = $window.Set
            Window = $window.Name
            From = $window.From
            To = $window.To
            Config = $configPath.Replace($RepoRoot + "\", "")
         }) | Out-Null
      }
   }
}

$profileManifest | Export-Csv -LiteralPath (Join-Path $outputRoot "PROFIT_SEARCH_PROFILES.csv") -NoTypeInformation
$configManifest | Export-Csv -LiteralPath (Join-Path $outputRoot "PROFIT_SEARCH_CONFIG_MANIFEST.csv") -NoTypeInformation

$readme = @(
   '# Profit Search Config Pack',
   '',
   'Generated without launching MT5.',
   '',
   'This pack searches for more profit around the current no-date BOS + liquidity-sweep profile while keeping the no-martingale/no-grid/no-averaging design intact.',
   '',
   '## Phase 1',
   '',
   '- Folder: `phase1_fast_triage/`',
   '- Model: `2`, fast tester model.',
   "- Purpose: cheap pruning across $($candidates.Count) candidates and 9 stress/opportunity/recent windows.",
   '- Promotion: never promote from phase 1 alone.',
   '',
   '## Phase 2',
   '',
   '- Folder: `phase2_real_tick_validation/`',
   '- Model: `4`, real ticks.',
   '- Purpose: deeper validation for baseline plus the highest-priority TP/SL and lower-risk capital-protection candidates.',
   '',
   '## Files',
   '',
   '- `PROFIT_SEARCH_PROFILES.csv`',
   '- `PROFIT_SEARCH_CONFIG_MANIFEST.csv`',
   '- `profiles/*.set`',
   '',
   '`baseline_promoted` remains unchanged as a comparison anchor. `baseline_dd4` changes only `InpMaxEquityDrawdownPercent=4.00` so drawdown protection can be tested without changing entry or exit logic. `buyblock2_dd4` keeps the same drawdown guard and enables the previously researched second buy-block window (`InpUseDateBuyBlock2=true`, `2025.07.01` through `2025.12.31`); guardrails mark it research-only until a non-date regime explanation or full out-of-sample evidence exists. `risk12_tp38_sl18` keeps the protected drawdown guard, lowers `InpRiskPercent` to 1.20, and expands TP to 3.80 ATR for a capital-protection/upside test. Other non-baseline profit-search candidates also include `InpMaxEquityDrawdownPercent=4.00` based on prior weak-quarter drawdown guard research.',
   '',
   'Local MT5 launch remains hard-locked by `work\MT5_LOCAL_LAUNCH_DISABLED.lock` unless the user explicitly permits local MT5 testing again.'
)
Set-Content -LiteralPath (Join-Path $outputRoot "README.md") -Value $readme -Encoding UTF8

$configManifest | Group-Object Phase, Model | Select-Object Name, Count
