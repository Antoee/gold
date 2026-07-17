Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$testRoot = Join-Path $repo ("outputs\trade_diversification_duplicate_test_{0}" -f $PID)
$analyzer = Join-Path $PSScriptRoot "analyze_trade_level_diversification.ps1"

try {
   New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
   $primaryPath = Join-Path $testRoot "primary.csv"
   $secondaryPath = Join-Path $testRoot "secondary.csv"
   $eventsPath = Join-Path $testRoot "events.csv"
   $monthlyPath = Join-Path $testRoot "monthly.csv"
   $annualPath = Join-Path $testRoot "annual.csv"
   $summaryPath = Join-Path $testRoot "summary.csv"
   $markdownPath = Join-Path $testRoot "screen.md"

   @(
      [pscustomobject]@{ EntryTime="2020-01-01T10:00:00"; ExitTime="2020-01-01T11:00:00"; RiskR="1.0"; Side="buy"; EntrySubtype="primary"; Profit="10" },
      [pscustomobject]@{ EntryTime="2020-02-01T10:00:00"; ExitTime="2020-02-01T11:00:00"; RiskR="-1.0"; Side="sell"; EntrySubtype="primary"; Profit="-10" }
   ) | Export-Csv -LiteralPath $primaryPath -NoTypeInformation -Encoding ASCII

   @(
      [pscustomobject]@{ EntryTime="2020-01-01T10:30:00"; ExitTime="2020-01-01T11:30:00"; RiskR="2.0"; Side="buy"; EntrySubtype="secondary"; Profit="20" },
      [pscustomobject]@{ EntryTime="2020-03-01T10:00:00"; ExitTime="2020-03-01T11:00:00"; RiskR="3.0"; Side="buy"; EntrySubtype="secondary"; Profit="30" }
   ) | Export-Csv -LiteralPath $secondaryPath -NoTypeInformation -Encoding ASCII

   & $analyzer `
      -PrimaryTrades $primaryPath `
      -SecondaryTrades $secondaryPath `
      -PrimaryLabel primary `
      -SecondaryLabel secondary `
      -PrimaryRiskWeight 1.0 `
      -SecondaryRiskWeight 0.5 `
      -StressRPerTrade 0.1 `
      -DuplicateToleranceMinutes 60 `
      -ExcludeSecondaryDuplicates `
      -OutTrades $eventsPath `
      -OutMonthly $monthlyPath `
      -OutAnnual $annualPath `
      -OutSummary $summaryPath `
      -OutMarkdown $markdownPath | Out-Null

   $summary = Import-Csv -LiteralPath $summaryPath
   if($summary.SecondaryInputTrades -ne "2" -or $summary.SecondaryTrades -ne "1") { throw "Duplicate exclusion did not preserve the expected secondary counts." }
   if($summary.ExcludedSecondaryTrades -ne "1" -or $summary.ExactDuplicatePairs -ne "1") { throw "Duplicate evidence was not recorded correctly." }
   if($summary.DuplicateExclusionEnabled -ne "True") { throw "Duplicate exclusion flag was not recorded." }
   if([math]::Abs([double]$summary.CombinedNetWeightedR - 1.25) -gt 0.000001) { throw "Stress-adjusted weighted R is incorrect: $($summary.CombinedNetWeightedR)" }
   if([math]::Abs([double]$summary.StressRPerTrade - 0.1) -gt 0.000001) { throw "Stress setting was not recorded." }
   if(@(Import-Csv -LiteralPath $eventsPath).Count -ne 3) { throw "Excluded duplicate appeared in the accepted event stream." }

   [pscustomobject]@{
      Status = "PASS"
      InputSecondaryTrades = 2
      AcceptedSecondaryTrades = 1
      CombinedNetWeightedR = [double]$summary.CombinedNetWeightedR
      StressRPerTrade = [double]$summary.StressRPerTrade
   }
}
finally {
   if(Test-Path -LiteralPath $testRoot) {
      $resolved = (Resolve-Path -LiteralPath $testRoot).Path
      $outputsRoot = (Resolve-Path -LiteralPath (Join-Path $repo "outputs")).Path
      if($resolved.StartsWith($outputsRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
         Remove-Item -LiteralPath $resolved -Recurse -Force
      }
   }
}
