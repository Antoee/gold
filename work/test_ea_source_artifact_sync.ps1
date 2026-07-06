param(
   [string]$RepoRoot = (Resolve-Path ".").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Equal {
   param([object]$Actual, [object]$Expected, [string]$Label)
   if([string]$Actual -ne [string]$Expected) {
      throw "$Label expected '$Expected' but got '$Actual'"
   }
}

$resolvedRepo = (Resolve-Path -LiteralPath $RepoRoot).Path
$workRoot = Join-Path $resolvedRepo "work"
$tempRoot = Join-Path $workRoot ("ea_source_sync_tmp_{0}" -f $PID)

if(Test-Path -LiteralPath $tempRoot) {
   $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
   $resolvedWork = (Resolve-Path -LiteralPath $workRoot).Path
   if(!$resolvedTemp.StartsWith($resolvedWork, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to clean unexpected path: $resolvedTemp"
   }
   Remove-Item -LiteralPath $tempRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
   $canonical = Join-Path $tempRoot "outputs\Professional_XAUUSD_EA.mq5"
   $rootSource = Join-Path $tempRoot "Professional_XAUUSD_EA.mq5"
   $packageSource = Join-Path $tempRoot "outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5"
   $outCsv = Join-Path $tempRoot "outputs\sync.csv"
   $outMd = Join-Path $tempRoot "outputs\sync.md"

   New-Item -ItemType Directory -Path (Split-Path -Parent $canonical) -Force | Out-Null
   @(
      "// fixture EA"
      "input double InpRiskPercent = 1.0;"
      "void OnTick() {}"
   ) | Set-Content -LiteralPath $canonical -Encoding ASCII

   & (Join-Path $resolvedRepo "work\sync_ea_source_artifacts.ps1") `
      -CanonicalSource $canonical `
      -RootSource $rootSource `
      -PackageSource $packageSource `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null

   $rows = @(Import-Csv -LiteralPath $outCsv)
   Assert-Equal $rows.Count 3 "sync row count"
   foreach($row in $rows) {
      Assert-Equal $row.Exists "True" "$($row.Role) exists"
      Assert-Equal $row.MatchesCanonical "True" "$($row.Role) hash match"
   }
   Assert-Equal (Test-Path -LiteralPath $rootSource) "True" "root source copied"
   Assert-Equal (Test-Path -LiteralPath $packageSource) "True" "package source copied"
}
finally {
   if(Test-Path -LiteralPath $tempRoot) {
      $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
      $resolvedWork = (Resolve-Path -LiteralPath $workRoot).Path
      if($resolvedTemp.StartsWith($resolvedWork, [System.StringComparison]::OrdinalIgnoreCase)) {
         Remove-Item -LiteralPath $tempRoot -Recurse -Force
      }
   }
}

"EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS"
