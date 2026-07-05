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
$resolvedWork = (Resolve-Path (Join-Path $RepoRoot "work")).Path

try {
   powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot "work\generate_profit_search_configs.ps1") `
      -RepoRoot $RepoRoot `
      -OutputDir $outputRel | Out-Null

   $profilesPath = Join-Path $outputPath "PROFIT_SEARCH_PROFILES.csv"
   $manifestPath = Join-Path $outputPath "PROFIT_SEARCH_CONFIG_MANIFEST.csv"
   Assert-True (Test-Path -LiteralPath $profilesPath) "Generated profiles manifest missing."
   Assert-True (Test-Path -LiteralPath $manifestPath) "Generated config manifest missing."

   $profiles = @(Import-Csv -LiteralPath $profilesPath)
   $manifest = @(Import-Csv -LiteralPath $manifestPath)
   Assert-True ($profiles.Count -eq 17) "Expected 17 profiles, found $($profiles.Count)."
   Assert-True ($manifest.Count -eq 202) "Expected 202 configs, found $($manifest.Count)."

   $phase1 = @($manifest | Where-Object { $_.Phase -eq "phase1_fast_triage" -and $_.Model -eq "2" })
   $phase2 = @($manifest | Where-Object { $_.Phase -eq "phase2_real_tick_validation" -and $_.Model -eq "4" })
   Assert-True ($phase1.Count -eq 136) "Expected 136 phase-1 configs, found $($phase1.Count)."
   Assert-True ($phase2.Count -eq 66) "Expected 66 phase-2 configs, found $($phase2.Count)."

   $baseline = $profiles | Where-Object { $_.Profile -eq "baseline_promoted" } | Select-Object -First 1
   $baselineDd4 = $profiles | Where-Object { $_.Profile -eq "baseline_dd4" } | Select-Object -First 1
   Assert-True ($null -ne $baseline) "baseline_promoted profile missing."
   Assert-True ($null -ne $baselineDd4) "baseline_dd4 profile missing."
   Assert-True ([int]$baseline.Priority -eq 1) "baseline_promoted must remain priority 1."
   Assert-True ([int]$baselineDd4.Priority -eq 2) "baseline_dd4 must remain priority 2."
   Assert-True ($baselineDd4.Phase2Seed -eq "True") "baseline_dd4 must be phase-2 seeded."

   $baselineSettings = Read-Settings -Path (Join-Path $RepoRoot $baseline.Settings)
   $dd4Settings = Read-Settings -Path (Join-Path $RepoRoot $baselineDd4.Settings)

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
   Assert-True ((Get-InputValue $dd4Settings "InpMaxEquityDrawdownPercent") -eq "4.00") `
      "baseline_dd4 drawdown guard must be 4.00."

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
