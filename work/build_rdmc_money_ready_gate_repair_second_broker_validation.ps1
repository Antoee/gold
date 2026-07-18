[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ascii = [Text.Encoding]::ASCII
$expectedSuccessorManifestHash = '30A508459E0C408BFF9A905F5C9AEB01AF9D411C39165734F197CC2928CE6CB5'
$harnessManifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_HARNESS_MANIFEST.csv'

$templates = @(
   [pscustomobject]@{ Kind='builder'; Source=(Join-Path $PSScriptRoot 'build_rdmc_second_broker_validation_gate.ps1'); Destination=(Join-Path $PSScriptRoot 'build_rdmc_money_ready_gate_repair_second_broker_validation_gate.ps1'); ExpectedSha256='C2880B735BC6DE122D3B0B1F1616C16AB04B3749D4827470A4EA7C57E96C5E32' },
   [pscustomobject]@{ Kind='collector'; Source=(Join-Path $PSScriptRoot 'collect_rdmc_second_broker_validation_results.py'); Destination=(Join-Path $PSScriptRoot 'collect_rdmc_money_ready_gate_repair_second_broker_validation_results.py'); ExpectedSha256='39B0B5F502441DB5C69B814F2B94F150FB8A48F85583DB1EB1AEF50218B5AF8A' },
   [pscustomobject]@{ Kind='evaluator'; Source=(Join-Path $PSScriptRoot 'evaluate_rdmc_second_broker_validation_gate.py'); Destination=(Join-Path $PSScriptRoot 'evaluate_rdmc_money_ready_gate_repair_second_broker_validation_gate.py'); ExpectedSha256='E0D602000D37CEEFF8CA982FBEF756898B0E89708AABB6C45491F763BADBCCBE' },
   [pscustomobject]@{ Kind='evaluator_test'; Source=(Join-Path $PSScriptRoot 'test_rdmc_second_broker_validation_gate.py'); Destination=(Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_second_broker_validation_gate.py'); ExpectedSha256='BC0C047B5CF24334464A453ED1CDD20B018980EB46665005BE9CDBC78A84B790' },
   [pscustomobject]@{ Kind='package_test'; Source=(Join-Path $PSScriptRoot 'test_rdmc_second_broker_validation_package.ps1'); Destination=(Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_second_broker_validation_package.ps1'); ExpectedSha256='78F72CFE616B0D434BA5D47AFE4385D9FF3028AF559518E7144D63BB1E66BC16' }
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

function Apply-Replacements([string]$Text, [object[]]$Replacements) {
   foreach($replacement in $Replacements) {
      if($Text.IndexOf($replacement.Old, [StringComparison]::Ordinal) -ge 0) {
         $Text = Replace-Required $Text $replacement.Old $replacement.New 'second-broker generation'
      }
   }
   return $Text
}

$baseReplacements = @(
   [pscustomobject]@{ Old='4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A'; New='EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972' },
   [pscustomobject]@{ Old='EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F'; New='104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8' },
   [pscustomobject]@{ Old='746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883'; New='8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E' },
   [pscustomobject]@{ Old='RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_MANIFEST.csv' },
   [pscustomobject]@{ Old='RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_DECISION.csv'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_DECISION.csv' },
   [pscustomobject]@{ Old='RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_RESULTS.csv'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RESULTS.csv' },
   [pscustomobject]@{ Old='RDMC_EXECUTABLE_LEDGER_STRESS_DECISION.csv'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_STRESS_DECISION.csv' },
   [pscustomobject]@{ Old='outputs\rdmc_diversified_repair_executable_gate_package\source\Professional_XAUUSD_EA.mq5'; New='outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5' },
   [pscustomobject]@{ Old='outputs\rdmc_diversified_repair_executable_gate_package\profiles\rdmc_diversified_repair_restart_safe_v2.set'; New='outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_v1.set' },
   [pscustomobject]@{ Old='rdmc_diversified_repair_executable_gate_package'; New='rdmc_money_ready_gate_repair_package' },
   [pscustomobject]@{ Old='rdmc_diversified_repair_restart_safe_v2'; New='rdmc_money_ready_gate_repair_v1' },
   [pscustomobject]@{ Old='rdmc_diversified_repair_restart_safe_v2.set'; New='rdmc_money_ready_gate_repair_v1.set' },
   [pscustomobject]@{ Old='build_rdmc_second_broker_validation_gate.ps1'; New='build_rdmc_money_ready_gate_repair_second_broker_validation_gate.ps1' },
   [pscustomobject]@{ Old='collect_rdmc_second_broker_validation_results.py'; New='collect_rdmc_money_ready_gate_repair_second_broker_validation_results.py' },
   [pscustomobject]@{ Old='evaluate_rdmc_second_broker_validation_gate.py'; New='evaluate_rdmc_money_ready_gate_repair_second_broker_validation_gate.py' },
   [pscustomobject]@{ Old='test_rdmc_second_broker_validation_gate.py'; New='test_rdmc_money_ready_gate_repair_second_broker_validation_gate.py' },
   [pscustomobject]@{ Old='test_rdmc_second_broker_validation_package.ps1'; New='test_rdmc_money_ready_gate_repair_second_broker_validation_package.ps1' },
   [pscustomobject]@{ Old='collect_rdmc_second_broker_validation_results'; New='collect_rdmc_money_ready_gate_repair_second_broker_validation_results' },
   [pscustomobject]@{ Old='evaluate_rdmc_second_broker_validation_gate'; New='evaluate_rdmc_money_ready_gate_repair_second_broker_validation_gate' },
   [pscustomobject]@{ Old='rdmc_second_broker_validation_package'; New='rdmc_money_ready_gate_repair_second_broker_validation_package' },
   [pscustomobject]@{ Old='RDMC_SECOND_BROKER_VALIDATION'; New='RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION' },
   [pscustomobject]@{ Old='RDMC_SECOND_BROKER_SPECIFICATION'; New='RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_SPECIFICATION' },
   [pscustomobject]@{ Old='RDMC_SECOND_BROKER_GATE'; New='RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_GATE' },
   [pscustomobject]@{ Old='RDMC Second-Broker Validation'; New='RDMC Money-Ready Gate Repair Second-Broker Validation' }
)

foreach($template in $templates) {
   if(!(Test-Path -LiteralPath $template.Source -PathType Leaf) -or (Get-UpperSha256 $template.Source) -ne $template.ExpectedSha256) {
      throw "Reviewed second-broker template identity changed: $($template.Source)"
   }
}

$builderTemplate = $templates | Where-Object Kind -eq 'builder'
$builderText = Apply-Replacements (Read-AsciiLf $builderTemplate.Source) $baseReplacements
[IO.File]::WriteAllText($builderTemplate.Destination, $builderText, $ascii)
& $builderTemplate.Destination | Out-Null

$successorManifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_MANIFEST.csv'
if(!(Test-Path -LiteralPath $successorManifestPath -PathType Leaf)) { throw 'Successor second-broker manifest was not generated.' }
$successorManifestHash = Get-UpperSha256 $successorManifestPath
if($expectedSuccessorManifestHash -and $successorManifestHash -ne $expectedSuccessorManifestHash) {
   throw "Successor second-broker manifest identity changed: $successorManifestHash"
}
$allReplacements = @($baseReplacements) + @(
   [pscustomobject]@{ Old='5334471DE730CA25B1028B85BCC7DACF0FC5C23BCDDB8541AED75EC320DDEC04'; New=$successorManifestHash }
)

foreach($template in @($templates | Where-Object Kind -ne 'builder')) {
   $text = Apply-Replacements (Read-AsciiLf $template.Source) $allReplacements
   if($template.Kind -eq 'evaluator') {
      $needle = '        "LaunchLocked": launch_locked,'
      $replacement = $needle + "`n" + '        "StaticReadinessPass": True,' + "`n" + '        "SourceNormalizedToBase": True,' + "`n" + '        "PostHocCollisionScorePromoted": False,'
      $text = Replace-Required $text $needle $replacement 'successor decision flags'
   }
   if($template.Kind -eq 'package_test') {
      $needle = '$checks = [System.Collections.Generic.List[object]]::new()'
      $replacement = '& $builderPath | Out-Null' + "`n`n" + $needle
      $text = Replace-Required $text $needle $replacement 'clean-checkout package preparation'
   }
   foreach($forbidden in @(
      'collect_rdmc_second_broker_validation_results',
      'evaluate_rdmc_second_broker_validation_gate',
      'RDMC_SECOND_BROKER_VALIDATION',
      'RDMC_SECOND_BROKER_SPECIFICATION',
      'EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F',
      '746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883',
      '5334471DE730CA25B1028B85BCC7DACF0FC5C23BCDDB8541AED75EC320DDEC04'
   )) {
      if($text.IndexOf($forbidden, [StringComparison]::Ordinal) -ge 0) { throw "Generated $($template.Kind) retains old identity token: $forbidden" }
   }
   [IO.File]::WriteAllText($template.Destination, $text, $ascii)
}

$baseContract = Join-Path $repo 'outputs\RDMC_SECOND_BROKER_VALIDATION_CONTRACT.md'
$baseReadme = Join-Path $repo 'outputs\rdmc_second_broker_validation_package\README_RDMC_SECOND_BROKER_VALIDATION.md'
if((Get-UpperSha256 $baseContract) -ne '785DEA21D8E6EBB71DCC168B1A873E148B0B76D2E47630B9A2A3344EC1575699' -or
   (Get-UpperSha256 $baseReadme) -ne '7544410A8C146E5D01D43828B318F90C3508B8323E09B8A490AE0709B3D307B7') {
   throw 'Reviewed second-broker documentation identity changed.'
}
$contract = Apply-Replacements (Read-AsciiLf $baseContract) $allReplacements
$contractNeedle = 'Status: **PREREGISTERED / PRIMARY PREREQUISITE LOCKED / ZERO SECOND-BROKER REPORTS / NOT PROMOTED**'
$contractReplacement = $contractNeedle + "`n`n" + '**SUCCESSOR-SPECIFIC IDENTITY. NO PRIMARY OR OLDER SECOND-BROKER EVIDENCE IS INHERITED.**'
$contract = Replace-Required $contract $contractNeedle $contractReplacement 'successor evidence boundary'
$contractPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_CONTRACT.md'
[IO.File]::WriteAllText($contractPath, $contract, $ascii)

$readme = Apply-Replacements (Read-AsciiLf $baseReadme) $allReplacements
$readme = $readme + "`nSuccessor evidence boundary: no report, result, broker specification, or pass from the older candidate is inherited.`n"
$packageReadmePath = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_second_broker_validation_package\README_RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION.md'
[IO.File]::WriteAllText($packageReadmePath, $readme, $ascii)

$evaluator = ($templates | Where-Object Kind -eq 'evaluator').Destination
& python $evaluator | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Successor second-broker evaluator failed.' }

$manifestRows = foreach($template in $templates) {
   [pscustomobject][ordered]@{
      Component = $template.Kind
      GeneratedPath = $template.Destination.Substring($repo.Length + 1)
      GeneratedSha256 = Get-UpperSha256 $template.Destination
      TemplatePath = $template.Source.Substring($repo.Length + 1)
      TemplateSha256 = Get-UpperSha256 $template.Source
      SecondBrokerManifestSha256 = $successorManifestHash
      SourceSha256 = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
      ProfileSha256 = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
      PrimaryCompanyFingerprintSha256 = 'C9D9B521F3325D6CE4996576CD61C7AA3E860A08B84DC47540C2B30E98924092'
      EvidenceInherited = $false
      LaunchPerformed = $false
   }
}
$manifestRows | Export-Csv -LiteralPath $harnessManifestPath -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status = 'GENERATED_AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS'
   Components = @($manifestRows).Count
   Rows = @(Import-Csv -LiteralPath $successorManifestPath).Count
   ManifestSha256 = $successorManifestHash
   EvidenceInherited = $false
   MQL5Launched = $false
   RealAccountApproved = $false
}
