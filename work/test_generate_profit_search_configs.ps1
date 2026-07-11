param(
   [string]$RepoRoot = (Resolve-Path ".").Path
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

function Get-InputValue {
   param(
      [System.Collections.Specialized.OrderedDictionary]$Settings,
      [string]$Name
   )

   if(!$Settings.Contains($Name)) {
      throw "Missing setting: $Name"
   }
   return ([string]$Settings[$Name] -split "\|\|", 2)[0]
}

function Assert-True {
   param(
      [bool]$Condition,
      [string]$Message
   )
   if(!$Condition) { throw $Message }
}

$outputRel = "work\generated_profit_search_smoke_$([guid]::NewGuid().ToString('N'))"
$outputPath = Join-Path $RepoRoot $outputRel
$baseProfileRel = Join-Path $outputRel "base_profile.set"
$baseProfilePath = Join-Path $RepoRoot $baseProfileRel
$resolvedWork = (Resolve-Path (Join-Path $RepoRoot "work")).Path

try {
   New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
   @(
      "InpMaxEquityDrawdownPercent=0.00"
      "InpRiskPercent=1.60"
      "InpStopATRMultiplier=1.80"
      "InpTakeProfitATRMultiplier=3.50"
      "InpTrailATRMultiplier=1.60"
      "InpMinRiskReward=1.50"
      "InpMaxStopATRMultiplier=3.00"
      "InpUseDateBuyBlock2=false"
      "InpUseProfitGivebackGuard=false"
      "InpDailyProfitGivebackPercent=35.0"
      "InpWeeklyProfitGivebackPercent=35.0"
      "InpMonthlyProfitGivebackPercent=35.0"
      "InpUseBreakEven=false"
      "InpBreakEvenTriggerR=1.00"
      "InpBreakEvenBufferPoints=10"
   ) | Set-Content -LiteralPath $baseProfilePath -Encoding ASCII

   powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot "work\generate_profit_search_configs.ps1") `
      -RepoRoot $RepoRoot `
      -BaseProfile $baseProfileRel `
      -OutputDir $outputRel | Out-Null

   $profilesPath = Join-Path $outputPath "PROFIT_SEARCH_PROFILES.csv"
   $manifestPath = Join-Path $outputPath "PROFIT_SEARCH_CONFIG_MANIFEST.csv"
   Assert-True (Test-Path -LiteralPath $profilesPath) "Generated profiles manifest missing."
   Assert-True (Test-Path -LiteralPath $manifestPath) "Generated config manifest missing."

   $profiles = @(Import-Csv -LiteralPath $profilesPath)
   $manifest = @(Import-Csv -LiteralPath $manifestPath)
   Assert-True ($profiles.Count -eq 22) "Expected 22 profiles, found $($profiles.Count)."
   Assert-True ($manifest.Count -eq 297) "Expected 297 configs, found $($manifest.Count)."

   $phase1 = @($manifest | Where-Object { $_.Phase -eq "phase1_fast_triage" -and $_.Model -eq "2" })
   $phase2 = @($manifest | Where-Object { $_.Phase -eq "phase2_real_tick_validation" -and $_.Model -eq "4" })
   Assert-True ($phase1.Count -eq 198) "Expected 198 phase-1 configs, found $($phase1.Count)."
   Assert-True ($phase2.Count -eq 99) "Expected 99 phase-2 configs, found $($phase2.Count)."

   $baseline = $profiles | Where-Object { $_.Profile -eq "baseline_promoted" } | Select-Object -First 1
   $baselineDd4 = $profiles | Where-Object { $_.Profile -eq "baseline_dd4" } | Select-Object -First 1
   $buyBlock = $profiles | Where-Object { $_.Profile -eq "buyblock2_dd4" } | Select-Object -First 1
   $risk12 = $profiles | Where-Object { $_.Profile -eq "risk12_tp38_sl18" } | Select-Object -First 1
   $maxStop25 = $profiles | Where-Object { $_.Profile -eq "maxstop25_dd4" } | Select-Object -First 1
   $maxStop20 = $profiles | Where-Object { $_.Profile -eq "maxstop20_dd4" } | Select-Object -First 1
   Assert-True ($null -ne $baseline) "baseline_promoted profile missing."
   Assert-True ($null -ne $baselineDd4) "baseline_dd4 profile missing."
   Assert-True ($null -ne $buyBlock) "buyblock2_dd4 profile missing."
   Assert-True ($null -ne $risk12) "risk12_tp38_sl18 profile missing."
   Assert-True ($null -ne $maxStop25) "maxstop25_dd4 profile missing."
   Assert-True ($null -ne $maxStop20) "maxstop20_dd4 profile missing."
   Assert-True ([int]$baseline.Priority -eq 1) "baseline_promoted must remain priority 1."
   Assert-True ([int]$baselineDd4.Priority -eq 2) "baseline_dd4 must remain priority 2."
   Assert-True ([int]$buyBlock.Priority -eq 3) "buyblock2_dd4 must be priority 3."
   Assert-True ([int]$risk12.Priority -eq 4) "risk12_tp38_sl18 must be priority 4."
   Assert-True ($baselineDd4.Phase2Seed -eq "True") "baseline_dd4 must be phase-2 seeded."
   Assert-True ($buyBlock.Phase2Seed -eq "True") "buyblock2_dd4 must be phase-2 seeded."
   Assert-True ($risk12.Phase2Seed -eq "True") "risk12_tp38_sl18 must be phase-2 seeded."
   Assert-True ($maxStop25.Phase2Seed -eq "False") "maxstop25_dd4 must stay phase-1 only until evidence exists."
   Assert-True ($maxStop20.Phase2Seed -eq "False") "maxstop20_dd4 must stay phase-1 only until evidence exists."

   $baselineSettings = Read-Settings -Path (Join-Path $RepoRoot $baseline.Settings)
   $dd4Settings = Read-Settings -Path (Join-Path $RepoRoot $baselineDd4.Settings)
   $buyBlockSettings = Read-Settings -Path (Join-Path $RepoRoot $buyBlock.Settings)
   $risk12Settings = Read-Settings -Path (Join-Path $RepoRoot $risk12.Settings)
   $maxStop25Settings = Read-Settings -Path (Join-Path $RepoRoot $maxStop25.Settings)
   $maxStop20Settings = Read-Settings -Path (Join-Path $RepoRoot $maxStop20.Settings)

   $differentKeys = @()
   foreach($key in $baselineSettings.Keys) {
      Assert-True ($dd4Settings.Contains($key)) "baseline_dd4 is missing baseline key: $key"
      if([string]$baselineSettings[$key] -ne [string]$dd4Settings[$key]) {
         $differentKeys += $key
      }
   }
   foreach($key in $dd4Settings.Keys) {
      Assert-True ($baselineSettings.Contains($key)) "baseline_dd4 has extra key: $key"
   }
   Assert-True (($differentKeys.Count -eq 1) -and ($differentKeys[0] -eq "InpMaxEquityDrawdownPercent")) `
      "baseline_dd4 must only differ by InpMaxEquityDrawdownPercent; found: $($differentKeys -join ', ')"
   Assert-True ((Get-InputValue $baselineSettings "InpMaxEquityDrawdownPercent") -eq "0.00") `
      "baseline_promoted drawdown guard must remain 0.00."
   Assert-True ((Get-InputValue $baselineSettings "InpMaxStopATRMultiplier") -eq "3.00") `
      "baseline_promoted max stop ATR guard must be pinned to 3.00."
   Assert-True ((Get-InputValue $dd4Settings "InpMaxEquityDrawdownPercent") -eq "4.00") `
      "baseline_dd4 drawdown guard must be 4.00."

   $buyBlockDifferentKeys = @()
   foreach($key in $baselineSettings.Keys) {
      Assert-True ($buyBlockSettings.Contains($key)) "buyblock2_dd4 is missing baseline key: $key"
      if([string]$baselineSettings[$key] -ne [string]$buyBlockSettings[$key]) {
         $buyBlockDifferentKeys += $key
      }
   }
   foreach($key in $buyBlockSettings.Keys) {
      Assert-True (($baselineSettings.Contains($key) -or $key -in @("InpBuyBlock2Start", "InpBuyBlock2End"))) "buyblock2_dd4 has unexpected extra key: $key"
   }
   $expectedBuyBlockDiffs = @("InpMaxEquityDrawdownPercent", "InpUseDateBuyBlock2")
   $unexpectedBuyBlockDiffs = @($buyBlockDifferentKeys | Where-Object { $expectedBuyBlockDiffs -notcontains $_ })
   foreach($expectedDiff in $expectedBuyBlockDiffs) {
      Assert-True ($buyBlockDifferentKeys -contains $expectedDiff) "buyblock2_dd4 must differ by $expectedDiff."
   }
   Assert-True ($unexpectedBuyBlockDiffs.Count -eq 0) `
      "buyblock2_dd4 must only differ by drawdown guard and second buy-block dates; found: $($buyBlockDifferentKeys -join ', ')"
   Assert-True ((Get-InputValue $buyBlockSettings "InpMaxEquityDrawdownPercent") -eq "4.00") `
      "buyblock2_dd4 drawdown guard must be 4.00."
   Assert-True ((Get-InputValue $buyBlockSettings "InpUseDateBuyBlock2") -eq "true") `
      "buyblock2_dd4 must enable InpUseDateBuyBlock2."
   Assert-True ((Get-InputValue $buyBlockSettings "InpBuyBlock2Start") -eq "2025.07.01 00:00") `
      "buyblock2_dd4 start date mismatch."
   Assert-True ((Get-InputValue $buyBlockSettings "InpBuyBlock2End") -eq "2025.12.31 23:59") `
      "buyblock2_dd4 end date mismatch."

   $risk12DifferentKeys = @()
   foreach($key in $baselineSettings.Keys) {
      Assert-True ($risk12Settings.Contains($key)) "risk12_tp38_sl18 is missing baseline key: $key"
      if([string]$baselineSettings[$key] -ne [string]$risk12Settings[$key]) {
         $risk12DifferentKeys += $key
      }
   }
   foreach($key in $risk12Settings.Keys) {
      Assert-True ($baselineSettings.Contains($key)) "risk12_tp38_sl18 has extra key: $key"
   }
   $expectedRisk12Diffs = @("InpMaxEquityDrawdownPercent", "InpRiskPercent", "InpTakeProfitATRMultiplier")
   $unexpectedRisk12Diffs = @($risk12DifferentKeys | Where-Object { $expectedRisk12Diffs -notcontains $_ })
   foreach($expectedDiff in $expectedRisk12Diffs) {
      Assert-True ($risk12DifferentKeys -contains $expectedDiff) "risk12_tp38_sl18 must differ by $expectedDiff."
   }
   Assert-True ($unexpectedRisk12Diffs.Count -eq 0) `
      "risk12_tp38_sl18 must only differ by drawdown guard, risk percent, and TP; found: $($risk12DifferentKeys -join ', ')"
   Assert-True ((Get-InputValue $risk12Settings "InpMaxEquityDrawdownPercent") -eq "4.00") `
      "risk12_tp38_sl18 drawdown guard must be 4.00."
   Assert-True ((Get-InputValue $risk12Settings "InpRiskPercent") -eq "1.20") `
      "risk12_tp38_sl18 risk percent must be 1.20."
   Assert-True ((Get-InputValue $risk12Settings "InpTakeProfitATRMultiplier") -eq "3.80") `
      "risk12_tp38_sl18 take-profit ATR multiplier must be 3.80."
   Assert-True ((Get-InputValue $risk12Settings "InpMaxStopATRMultiplier") -eq "3.00") `
      "risk12_tp38_sl18 max stop ATR guard must stay pinned to 3.00."

   Assert-True ((Get-InputValue $maxStop25Settings "InpMaxEquityDrawdownPercent") -eq "4.00") `
      "maxstop25_dd4 drawdown guard must be 4.00."
   Assert-True ((Get-InputValue $maxStop25Settings "InpMaxStopATRMultiplier") -eq "2.50") `
      "maxstop25_dd4 max stop ATR guard must be 2.50."
   Assert-True ((Get-InputValue $maxStop20Settings "InpMaxEquityDrawdownPercent") -eq "4.00") `
      "maxstop20_dd4 drawdown guard must be 4.00."
   Assert-True ((Get-InputValue $maxStop20Settings "InpMaxStopATRMultiplier") -eq "2.00") `
      "maxstop20_dd4 max stop ATR guard must be 2.00."

   $missingConfigFiles = @($manifest | Where-Object { !(Test-Path -LiteralPath (Join-Path $RepoRoot $_.Config)) })
   Assert-True ($missingConfigFiles.Count -eq 0) "Generated manifest references missing config files: $($missingConfigFiles.Count)."

   "GENERATE_PROFIT_SEARCH_CONFIGS_SMOKE_PASS"
}
finally {
   if(Test-Path -LiteralPath $outputPath) {
      $resolvedOutput = (Resolve-Path -LiteralPath $outputPath).Path
      if(!$resolvedOutput.StartsWith($resolvedWork, [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to remove temp output outside work directory: $resolvedOutput"
      }
      Remove-Item -LiteralPath $resolvedOutput -Recurse -Force
   }
}
