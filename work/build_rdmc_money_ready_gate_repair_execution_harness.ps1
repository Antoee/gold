[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_HARNESS_MANIFEST.csv'
$contractPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_HARNESS_CONTRACT.md'
$ascii = [Text.Encoding]::ASCII

$templates = @(
   [pscustomobject]@{
      Kind = 'runner'
      Source = Join-Path $PSScriptRoot 'run_rdmc_diversified_repair_executable_gate_wave.ps1'
      Destination = Join-Path $PSScriptRoot 'run_rdmc_money_ready_gate_repair_executable_wave.ps1'
      ExpectedSha256 = 'BD4B4FB2A06ABB7D44FF0901AEFEA9C56BBCBBED829BA1E70C0ECF7229ACBE4A'
   },
   [pscustomobject]@{
      Kind = 'collector'
      Source = Join-Path $PSScriptRoot 'collect_rdmc_diversified_repair_executable_gate_results.ps1'
      Destination = Join-Path $PSScriptRoot 'collect_rdmc_money_ready_gate_repair_executable_results.ps1'
      ExpectedSha256 = '247EB899D167E702EBA00F06E69F24FD1AC407588A52EAFDAD5DAC7973EFF41B'
   },
   [pscustomobject]@{
      Kind = 'evaluator'
      Source = Join-Path $PSScriptRoot 'evaluate_rdmc_diversified_repair_executable_gate.py'
      Destination = Join-Path $PSScriptRoot 'evaluate_rdmc_money_ready_gate_repair_executable.py'
      ExpectedSha256 = 'C860DA9CCEE39942115E1794EA28AD69D492DD920F5191768686FEDA40CC3A71'
   },
   [pscustomobject]@{
      Kind = 'runner_test'
      Source = Join-Path $PSScriptRoot 'test_rdmc_diversified_repair_executable_gate_wave_runner.ps1'
      Destination = Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_executable_wave_runner.ps1'
      ExpectedSha256 = '4E9F1E8ACF0D14374EF00F215ECDCE04C8C1720A6956762192AEABB714682441'
   },
   [pscustomobject]@{
      Kind = 'collector_test'
      Source = Join-Path $PSScriptRoot 'test_rdmc_diversified_repair_executable_gate_collector.ps1'
      Destination = Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_executable_collector.ps1'
      ExpectedSha256 = '6CE9883A27E18F57CEDD601E9E0CB4D7788BFA9D27E3CD49B8161E2B801C9AE3'
   },
   [pscustomobject]@{
      Kind = 'evaluator_test'
      Source = Join-Path $PSScriptRoot 'test_rdmc_diversified_repair_executable_gate.py'
      Destination = Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_executable.py'
      ExpectedSha256 = '4DCE06FECD9404EB8130D94235AFC625DE9C877ADEA257A46B0686B1446AA2BC'
   }
)

$commonReplacements = @(
   [pscustomobject]@{ Old='4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A'; New='EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972' },
   [pscustomobject]@{ Old='EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F'; New='104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8' },
   [pscustomobject]@{ Old='746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883'; New='8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E' },
   [pscustomobject]@{ Old='outputs\rdmc_diversified_repair_executable_gate_package\source\Professional_XAUUSD_EA.mq5'; New='outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5' },
   [pscustomobject]@{ Old='run_rdmc_diversified_repair_executable_gate_wave.ps1'; New='run_rdmc_money_ready_gate_repair_executable_wave.ps1' },
   [pscustomobject]@{ Old='collect_rdmc_diversified_repair_executable_gate_results.ps1'; New='collect_rdmc_money_ready_gate_repair_executable_results.ps1' },
   [pscustomobject]@{ Old='evaluate_rdmc_diversified_repair_executable_gate.py'; New='evaluate_rdmc_money_ready_gate_repair_executable.py' },
   [pscustomobject]@{ Old='RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE' },
   [pscustomobject]@{ Old='RDMC_EXECUTABLE_GATE'; New='RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE' },
   [pscustomobject]@{ Old='rdmc_diversified_repair_executable_gate_package'; New='rdmc_money_ready_gate_repair_executable_package' },
   [pscustomobject]@{ Old='rdmc_wave04_'; New='rdmc_mrgr_wave04_' },
   [pscustomobject]@{ Old='RDMC Diversified Repair Executable Gate'; New='RDMC Money-Ready Gate Repair Executable' }
)

function Get-UpperSha256([string]$Path) {
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Read-Template([string]$Path) {
   $bytes = [IO.File]::ReadAllBytes($Path)
   if($bytes -contains 13) { throw "Template must remain LF-only: $Path" }
   if(@($bytes | Where-Object { $_ -gt 127 }).Count -gt 0) { throw "Template must remain ASCII: $Path" }
   return $ascii.GetString($bytes)
}

function Apply-RequiredReplacement([string]$Text, [string]$Old, [string]$New, [string]$Label) {
   if($Text.IndexOf($Old, [StringComparison]::Ordinal) -lt 0) { throw "Missing required $Label token: $Old" }
   return $Text.Replace($Old, $New)
}

$manifestRows = [System.Collections.Generic.List[object]]::new()
foreach($template in $templates) {
   if(!(Test-Path -LiteralPath $template.Source -PathType Leaf)) { throw "Missing harness template: $($template.Source)" }
   $templateHash = Get-UpperSha256 $template.Source
   if($templateHash -ne $template.ExpectedSha256) { throw "Reviewed harness template identity changed: $($template.Source)" }
   $text = Read-Template $template.Source

   foreach($replacement in $commonReplacements) {
      if($text.IndexOf($replacement.Old, [StringComparison]::Ordinal) -ge 0) {
         $text = Apply-RequiredReplacement $text $replacement.Old $replacement.New $template.Kind
      }
   }

   if($template.Kind -eq 'evaluator') {
      $decisionNeedle = '        "LaunchLocked": launch_locked,' + "`n" + '        "PostHocCollisionScorePromoted": False,'
      $decisionReplacement = '        "LaunchLocked": launch_locked,' + "`n" + '        "StaticReadinessPass": True,' + "`n" + '        "SourceNormalizedToBase": True,' + "`n" + '        "PostHocCollisionScorePromoted": False,'
      $text = Apply-RequiredReplacement $text $decisionNeedle $decisionReplacement 'successor decision flags'

      $markdownNeedle = '        f"- Launch locked: `{launch_locked}`",' + "`n" + '        f"- Next action: `{decision[''NextAction'']}`",'
      $markdownReplacement = '        f"- Launch locked: `{launch_locked}`",' + "`n" + '        "- Static readiness: `PASS`",' + "`n" + '        "- Source normalization to frozen base: `PASS`",' + "`n" + '        f"- Next action: `{decision[''NextAction'']}`",'
      $text = Apply-RequiredReplacement $text $markdownNeedle $markdownReplacement 'successor markdown flags'
   }

   foreach($forbidden in @(
      'RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE',
      'RDMC_EXECUTABLE_GATE',
      'rdmc_diversified_repair_executable_gate_package',
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
      ManifestSha256 = 'EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972'
      SourceSha256 = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
      ProfileSha256 = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
      LogicOrigin = 'HASH_PINNED_PROVEN_HARNESS'
      LaunchPerformed = $false
   }) | Out-Null
}

$manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII
$contract = @(
   '# RDMC Money-Ready Gate Repair Execution Harness Contract',
   '',
   '**OFFLINE HARNESS BUILD ONLY. EXISTING TESTER EVIDENCE IS PRESERVED; NO PROFIT CLAIM.**',
   '',
   'The runner, collector, evaluator, and their three regression tests are deterministically derived from the reviewed diversified-repair executable harness. The template byte identities are pinned before generation; only candidate identity, package paths, artifact names, and the two static gate-repair decision facts change.',
   '',
   '- Manifest SHA-256: `EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972`',
   '- Source SHA-256: `104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8`',
   '- Profile SHA-256: `8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E`',
   '- Decision facts added by this successor: `StaticReadinessPass=True`, `SourceNormalizedToBase=True`.',
   '',
   'The harness preserves compile-once binary distribution, the two launch locks, explicit focus-risk authorization, wave admission, Model1 reject-only ordering, Wave 4 cache staging, report sidecars, exact report/config/source/binary hashes, and fail-closed thresholds. It cannot promote the registered forward candidate or approve real trading.',
   '',
   'Both launch locks must remain present until a deliberate review. Building or testing this harness never launches MT5 and never deletes existing report evidence.'
) -join "`n"
[IO.File]::WriteAllText($contractPath, $contract + "`n", $ascii)

[pscustomobject]@{
   Status = 'GENERATED_OFFLINE'
   Components = $manifestRows.Count
   ManifestPath = $manifestPath.Substring($repo.Length + 1)
   ContractPath = $contractPath.Substring($repo.Length + 1)
   MQL5Launched = $false
   RealAccountApproved = $false
}
