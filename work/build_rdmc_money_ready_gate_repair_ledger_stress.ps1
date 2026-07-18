[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ascii = [Text.Encoding]::ASCII
$manifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_LEDGER_HARNESS_MANIFEST.csv'
$contractPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_STRESS_CONTRACT.md'
$corePath = Join-Path $PSScriptRoot 'rdmc_executable_ledger_stress_core.py'
$expectedCoreHash = '2F9C27E68AA4F02EDCCC54E1950039B42CD01BF763103F8E61B59DB89729E5B7'

$templates = @(
   [pscustomobject]@{
      Kind = 'analyzer'
      Source = Join-Path $PSScriptRoot 'analyze_rdmc_executable_trade_ledger_stress.py'
      Destination = Join-Path $PSScriptRoot 'analyze_rdmc_money_ready_gate_repair_ledger_stress.py'
      ExpectedSha256 = 'DEC8A8C0B0CC6F3188157B12290258A4D7BFC23F9E76417A045F730A1159601B'
   },
   [pscustomobject]@{
      Kind = 'test'
      Source = Join-Path $PSScriptRoot 'test_rdmc_executable_trade_ledger_stress.py'
      Destination = Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_ledger_stress.py'
      ExpectedSha256 = 'D9D6008109B5BBB010940AB36181C507C5BB07F67271FC46BD68A16C0762869C'
   }
)

$replacements = @(
   [pscustomobject]@{ Old='4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A'; New='EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972' },
   [pscustomobject]@{ Old='EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F'; New='104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8' },
   [pscustomobject]@{ Old='746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883'; New='8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E' },
   [pscustomobject]@{ Old='RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_MANIFEST.csv' },
   [pscustomobject]@{ Old='RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_RESULTS.csv'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RESULTS.csv' },
   [pscustomobject]@{ Old='RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_DECISION.csv'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_DECISION.csv' },
   [pscustomobject]@{ Old='rdmc_diversified_repair_executable_gate_package'; New='rdmc_money_ready_gate_repair_executable_package' },
   [pscustomobject]@{ Old='analyze_rdmc_executable_trade_ledger_stress.py'; New='analyze_rdmc_money_ready_gate_repair_ledger_stress.py' },
   [pscustomobject]@{ Old='RDMC_EXECUTABLE_LEDGER'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER' },
   [pscustomobject]@{ Old='RDMC Executable Ledger Stress'; New='RDMC Money-Ready Gate Repair Executable Ledger Stress' }
)

function Get-UpperSha256([string]$Path) {
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Read-AsciiLf([string]$Path) {
   $bytes = [IO.File]::ReadAllBytes($Path)
   if($bytes -contains 13) { throw "Template must remain LF-only: $Path" }
   if(@($bytes | Where-Object { $_ -gt 127 }).Count -gt 0) { throw "Template must remain ASCII: $Path" }
   return $ascii.GetString($bytes)
}

function Replace-Required([string]$Text, [string]$Old, [string]$New, [string]$Label) {
   if($Text.IndexOf($Old, [StringComparison]::Ordinal) -lt 0) { throw "Missing required $Label token: $Old" }
   return $Text.Replace($Old, $New)
}

if(!(Test-Path -LiteralPath $corePath -PathType Leaf) -or (Get-UpperSha256 $corePath) -ne $expectedCoreHash) {
   throw 'Reviewed ledger-stress core identity changed.'
}

$manifestRows = [System.Collections.Generic.List[object]]::new()
foreach($template in $templates) {
   if(!(Test-Path -LiteralPath $template.Source -PathType Leaf)) { throw "Missing ledger template: $($template.Source)" }
   $templateHash = Get-UpperSha256 $template.Source
   if($templateHash -ne $template.ExpectedSha256) { throw "Reviewed ledger template identity changed: $($template.Source)" }
   $text = Read-AsciiLf $template.Source
   foreach($replacement in $replacements) {
      if($text.IndexOf($replacement.Old, [StringComparison]::Ordinal) -ge 0) {
         $text = Replace-Required $text $replacement.Old $replacement.New $template.Kind
      }
   }

   if($template.Kind -eq 'analyzer') {
      $decisionNeedle = '        "LaunchLocked": launch_locked,'
      $decisionReplacement = $decisionNeedle + "`n" + '        "StaticReadinessPass": True,' + "`n" + '        "SourceNormalizedToBase": True,' + "`n" + '        "PostHocCollisionScorePromoted": False,'
      $occurrences = ([regex]::Matches($text, [regex]::Escape($decisionNeedle))).Count
      if($occurrences -ne 2) { throw "Expected two successor decision insertion points, found $occurrences." }
      $text = $text.Replace($decisionNeedle, $decisionReplacement)

      $markdownNeedle = '        f"- Launch locked: `{launch_locked}`",'
      $markdownReplacement = $markdownNeedle + "`n" + '        "- Static readiness: `PASS`",' + "`n" + '        "- Source normalization to frozen base: `PASS`",'
      $text = Replace-Required $text $markdownNeedle $markdownReplacement 'successor waiting markdown'
   }

   foreach($forbidden in @(
      'RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE',
      'rdmc_diversified_repair_executable_gate_package',
      'RDMC_EXECUTABLE_LEDGER',
      'EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F',
      '746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883',
      '4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A'
   )) {
      if($text.IndexOf($forbidden, [StringComparison]::Ordinal) -ge 0) { throw "Generated $($template.Kind) retains old identity token: $forbidden" }
   }
   if($text.IndexOf("`r", [StringComparison]::Ordinal) -ge 0) { throw "Generated $($template.Kind) contains CR bytes." }
   [IO.File]::WriteAllText($template.Destination, $text, $ascii)
   $manifestRows.Add([pscustomobject][ordered]@{
      Component = $template.Kind
      GeneratedPath = $template.Destination.Substring($repo.Length + 1)
      GeneratedSha256 = Get-UpperSha256 $template.Destination
      TemplatePath = $template.Source.Substring($repo.Length + 1)
      TemplateSha256 = $templateHash
      SharedCorePath = $corePath.Substring($repo.Length + 1)
      SharedCoreSha256 = $expectedCoreHash
      ExecutableManifestSha256 = 'EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972'
      SourceSha256 = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
      ProfileSha256 = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
      EvidenceInherited = $false
      LaunchPerformed = $false
   }) | Out-Null
}

$baseContract = Join-Path $repo 'outputs\RDMC_EXECUTABLE_LEDGER_STRESS_CONTRACT.md'
$expectedContractHash = '7DDBCAF76530503FCA92F562C932650ADA48C415C73EE2302DAEE87DD23CE785'
if(!(Test-Path -LiteralPath $baseContract -PathType Leaf) -or (Get-UpperSha256 $baseContract) -ne $expectedContractHash) {
   throw 'Reviewed ledger-stress contract identity changed.'
}
$contract = Read-AsciiLf $baseContract
foreach($replacement in $replacements) {
   if($contract.IndexOf($replacement.Old, [StringComparison]::Ordinal) -ge 0) {
      $contract = Replace-Required $contract $replacement.Old $replacement.New 'contract'
   }
}
$statusNeedle = 'Status: **FROZEN ANALYZER / AWAITING EXECUTABLE MT5 GATE / NOT PROMOTED**'
$statusReplacement = $statusNeedle + "`n`n" + '**SUCCESSOR-SPECIFIC IDENTITY. ZERO EXECUTABLE REPORTS. NO OLDER PROFIT OR STRESS EVIDENCE IS INHERITED.**'
$contract = Replace-Required $contract $statusNeedle $statusReplacement 'contract evidence boundary'
[IO.File]::WriteAllText($contractPath, $contract, $ascii)
$manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status = 'GENERATED_AWAITING_EXECUTABLE_MT5_GATE'
   Components = $manifestRows.Count
   SharedCoreSha256 = $expectedCoreHash
   EvidenceInherited = $false
   MQL5Launched = $false
   RealAccountApproved = $false
}
