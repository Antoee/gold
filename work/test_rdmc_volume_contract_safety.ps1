Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourcePath = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package\source\Professional_XAUUSD_EA.mq5"
$profilePath = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package\profiles\rdmc_diversified_repair_restart_safe_v2.set"

$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{ Check = $Name; Pass = $Pass; Evidence = $Evidence })
}

function Get-Section([string]$Text, [string]$Start, [string]$End) {
   $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
   $endIndex = if($startIndex -ge 0) { $Text.IndexOf($End, $startIndex, [StringComparison]::Ordinal) } else { -1 }
   if($startIndex -lt 0 -or $endIndex -le $startIndex) { return "" }
   return $Text.Substring($startIndex, $endIndex - $startIndex)
}

function Read-Profile([string]$Path) {
   $values = @{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -match '^([^;=]+)=([^|]*)(.*)$') { $values[$matches[1]] = $matches[2] }
   }
   return $values
}

function Get-StepDigits([double]$Step) {
   if($Step -le 0.0) { return 2 }
   $tolerance = [Math]::Max(0.000000000001, [Math]::Abs($Step) * 0.00000001)
   for($digits = 0; $digits -le 8; $digits++) {
      if([Math]::Abs([Math]::Round($Step, $digits) - $Step) -le $tolerance) { return $digits }
   }
   return 8
}

function Normalize-VolumeDown([double]$Volume, [double]$Step) {
   if($Volume -le 0.0 -or $Step -le 0.0) { return 0.0 }
   $units = [Math]::Floor($Volume / $Step + 0.00000001)
   if($units -le 0.0) { return 0.0 }
   return [Math]::Round($units * $Step, (Get-StepDigits $Step))
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Volume-contract audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$digits = Get-Section $source "int VolumeDigitsForStep(const double step)" "double NormalizeVolumeDown(const double volume, const double step)"
$normalize = Get-Section $source "double NormalizeVolumeDown(const double volume, const double step)" "string TradeResultEvidence(CTrade &executor)"
$riskLots = Get-Section $source "double NormalizeLots(const double lots)" "double LotsForRisk("
$basketPartial = Get-Section $source "void OpenBasketPartialHarvest()" "void Manage(const ENUM_TRADE_BIAS currentSignalBias)"
$positionManage = Get-Section $source "void Manage(const ENUM_TRADE_BIAS currentSignalBias)" "class CMomentumLane"
$marginLots = Get-Section $source "double MarginAwareCappedLots(" "double MoneyForDistanceLots("
$riskNormalizeCalls = [regex]::Matches($riskLots, 'NormalizeVolumeDown\(').Count
$partialNormalizeCalls = [regex]::Matches($positionManage, 'closeLots = NormalizeVolumeDown\(closeLots, step\);').Count
$allNormalizeCalls = [regex]::Matches($source, 'NormalizeVolumeDown\(').Count

Add-Check "source version is 1.27" ($source.Contains('#property version   "1.27"')) "version"
Add-Check "step precision supports zero through eight decimals" ($digits.Contains('for(int digits = 0; digits <= 8; ++digits)')) "0..8"
Add-Check "step precision uses tolerance rather than exact floating equality" ($digits.Contains('MathAbs(NormalizeDouble(step, digits) - step) <= tolerance')) "tolerant precision"
Add-Check "normalizer rejects non-positive values" ($normalize.Contains('volume <= 0.0 || step <= 0.0')) "invalid volume blocked"
Add-Check "normalizer rounds down in broker step units" ($normalize.Contains('MathFloor(volume / step + 0.00000001)')) "floor by step"
Add-Check "normalizer derives precision from broker step" ($normalize.Contains('NormalizeDouble(units * step, VolumeDigitsForStep(step))')) "step precision"
Add-Check "risk lot sizing uses shared step normalizer" ($riskNormalizeCalls -eq 2) "calls=$riskNormalizeCalls"
Add-Check "risk lot sizing has no hardcoded two-decimal normalization" (!$riskLots.Contains('NormalizeDouble(normalized, 2)')) "no fixed precision"
Add-Check "margin cap normalizes initial binary-search volume" ($marginLots.Contains('NormalizeVolumeDown(MathMin(lots, maxLot), step)')) "initial cap"
Add-Check "margin cap normalizes each search probe" ($marginLots.Contains('NormalizeVolumeDown(mid, step)')) "probe cap"
Add-Check "margin cap normalizes best and every minimum-lot result" ($marginLots.Contains('NormalizeVolumeDown(best, step)') -and [regex]::Matches($marginLots, 'NormalizeVolumeDown\(minLot, step\)').Count -eq 2) "result cap"
Add-Check "margin cap has no fixed two-decimal lot return" ($marginLots -notmatch 'NormalizeDouble\([^\r\n]+, 2\)') "no fixed precision"
Add-Check "basket partial close uses shared step normalizer" ($basketPartial.Contains('closeLots = NormalizeVolumeDown(closeLots, step);')) "basket partial"
Add-Check "all three standard partial paths use shared normalizer" ($partialNormalizeCalls -eq 3) "calls=$partialNormalizeCalls"
Add-Check "all source volume normalization routes are centralized" ($allNormalizeCalls -eq 14) "calls=$allNormalizeCalls"
Add-Check "no lot path retains hardcoded two-decimal normalization" ($source -notmatch 'NormalizeDouble\((?:normalized|cappedLots|best|minLot|closeLots), 2\)') "fixed volume precision absent"

$scenarios = @(
   @{ Name='gold hundredth step'; Volume=0.237; Step=0.01; Expected=0.23 },
   @{ Name='fine thousandth step'; Volume=0.2379; Step=0.001; Expected=0.237 },
   @{ Name='whole-lot step'; Volume=2.9; Step=1.0; Expected=2.0 },
   @{ Name='tenth-lot step'; Volume=0.29; Step=0.1; Expected=0.2 },
   @{ Name='quarter-lot step'; Volume=0.76; Step=0.25; Expected=0.75 },
   @{ Name='exact floating tenth'; Volume=0.3; Step=0.1; Expected=0.3 },
   @{ Name='below minimum step'; Volume=0.009; Step=0.01; Expected=0.0 },
   @{ Name='zero volume'; Volume=0.0; Step=0.01; Expected=0.0 },
   @{ Name='invalid zero step'; Volume=0.1; Step=0.0; Expected=0.0 }
)
foreach($scenario in $scenarios) {
   $actual = Normalize-VolumeDown $scenario.Volume $scenario.Step
   Add-Check "volume model: $($scenario.Name)" ([Math]::Abs($actual - $scenario.Expected) -lt 0.000000001) "actual=$actual expected=$($scenario.Expected)"
   Add-Check "volume model never rounds upward: $($scenario.Name)" ($actual -le $scenario.Volume + 0.000000001) "actual=$actual input=$($scenario.Volume)"
}

foreach($contract in @{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
   InpAllowMinLotRiskOverflow = 'false'
   InpUseMarginAwareLotCap = 'true'
}.GetEnumerator()) {
   Add-Check "volume profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC volume-contract checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC volume-contract checks"
