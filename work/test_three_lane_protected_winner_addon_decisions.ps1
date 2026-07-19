$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$checks=[Collections.Generic.List[object]]::new()
function Check([string]$Name,[bool]$Pass,[string]$Evidence){$checks.Add([pscustomobject]@{Check=$Name;Pass=$Pass;Evidence=$Evidence})|Out-Null}
$sourceTest=& (Join-Path $PSScriptRoot 'test_three_lane_protected_winner_addon_source.ps1')
Check 'research source safety passes' ($sourceTest.Status-eq'PASS') $sourceTest.SourceSha256
$discoveryPackage=& (Join-Path $PSScriptRoot 'test_three_lane_protected_winner_addon_discovery_package.ps1') -PackageDir 'outputs\three_lane_protected_winner_addon_discovery_exact_model1_package' -ManifestPath 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_EXACT_MODEL1_PACKAGE_MANIFEST.csv'
Check 'sealed discovery package passes' ($discoveryPackage.Status-eq'PASS'-and$discoveryPackage.MaximumDate-eq'2020-12-31') "rows=$($discoveryPackage.Rows)"
$holdoutPackage=& (Join-Path $PSScriptRoot 'test_three_lane_protected_winner_addon_holdout_package.ps1')
Check 'frozen holdout package passes' ($holdoutPackage.Status-eq'PASS'-and$holdoutPackage.EarliestDate-eq'2021-01-01') "rows=$($holdoutPackage.Rows)"
$discoveryRun=@(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_PWA_DISCOVERY_EXACT_1.csv'))
$holdoutRun=@(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_PWA_HOLDOUT_EXACT_1.csv'))
$expectedBinary='3334836C955F4F97C5769FF2CF87B7ACB9A9C7BF38ECE70BC692A6149376311D'
Check 'discovery exact run complete' ($discoveryRun.Count-eq30-and@($discoveryRun|Where-Object {$_.Status -ne 'REPORT_FOUND'}).Count-eq0) '30/30'
Check 'discovery exact binary uniform' (@($discoveryRun.PortableBinarySha256|Sort-Object -Unique).Count-eq1-and$discoveryRun[0].PortableBinarySha256-eq$expectedBinary) $expectedBinary
Check 'holdout exact run complete' ($holdoutRun.Count-eq8-and@($holdoutRun|Where-Object {$_.Status -ne 'REPORT_FOUND'}).Count-eq0) '8/8'
Check 'holdout exact binary uniform' (@($holdoutRun.PortableBinarySha256|Sort-Object -Unique).Count-eq1-and$holdoutRun[0].PortableBinarySha256-eq$expectedBinary) $expectedBinary
$publishedControl=(Get-FileHash (Join-Path $repo 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_CONTROL.set') -Algorithm SHA256).Hash
$publishedSelected=(Get-FileHash (Join-Path $repo 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_SELECTED_TRIGGER100.set') -Algorithm SHA256).Hash
Check 'published control profile exact' ($publishedControl-eq'65A3228E1C705BFE1DC97ADE7CEF94D3F5AE49C63E4E8E92708DCE699E7B6BCD') $publishedControl
Check 'published selected profile exact' ($publishedSelected-eq'50CC443F2FE19D53EA38B15D10CD92242D7A291452B603EC4B2B7A67F0C78F42') $publishedSelected
$discovery=@(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_DECISION.csv'))[0]
$holdout=@(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_DECISION.csv'))[0]
Check 'discovery survivor is frozen trigger100' ($discovery.Status-eq'DISCOVERY_SURVIVOR'-and$discovery.SelectedCandidate-eq'pwa_trigger100'-and$discovery.NewBest-eq'False') $discovery.SelectedProfileSha256
Check 'holdout rejects candidate' ($holdout.Status-eq'REJECTED_IN_HOLDOUT'-and$holdout.HoldoutPassed-eq'False') "difference=$($holdout.NetDifference)"
Check 'Model4 remains closed' ($holdout.Model4Permitted-eq'False'-and$holdout.Model4Opened-eq'False') 'closed'
Check 'no new best' ($holdout.NewBest-eq'False') 'ATB150 unchanged'
$holdoutSummary=@(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_MODEL1_SUMMARY.csv'))
$candidateContinuous=@($holdoutSummary|Where-Object{$_.Candidate-eq'pwa_trigger100'-and$_.Window-eq'continuous_2021_2026'})
Check 'holdout has no completed add-ons' ($candidateContinuous.Count-eq1-and[int]$candidateContinuous[0].AddOnEntries-eq0) "entries=$($candidateContinuous[0].AddOnEntries)"
Check 'holdout candidate underperforms control' ([double]$holdout.CandidateContinuousNet-lt[double]$holdout.ControlContinuousNet-and[double]$holdout.NetDifference-eq-15.22) "candidate=$($holdout.CandidateContinuousNet) control=$($holdout.ControlContinuousNet)"
$atbSource=Get-FileHash (Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5') -Algorithm SHA256
$atbProfile=Get-FileHash (Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set') -Algorithm SHA256
Check 'ATB150 source unchanged' ($atbSource.Hash-eq'2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158') $atbSource.Hash
Check 'ATB150 profile unchanged' ($atbProfile.Hash-eq'705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E') $atbProfile.Hash
Check 'repository launch lock present' (Test-Path (Join-Path $repo 'work\MT5_LOCAL_LAUNCH_DISABLED.lock')) 'present'
Check 'outer launch lock present' (Test-Path (Join-Path (Split-Path -Parent $repo) 'MT5_LOCAL_LAUNCH_DISABLED.lock')) 'present'
Check 'MT5 processes absent' (@(Get-Process terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count-eq0) '0'
$csv=Join-Path $repo 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_STATIC_SAFETY.csv';$md=Join-Path $repo 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_STATIC_SAFETY.md';$checks | Export-Csv $csv -NoTypeInformation -Encoding ASCII
$failed=@($checks|Where-Object{!$_.Pass});$lines=[Collections.Generic.List[string]]::new();$lines.Add('# Three-Lane Protected Winner Add-On Static Safety');$lines.Add('');$lines.Add("**Status: $(if($failed.Count-eq0){'PASS'}else{'FAIL'}). $($checks.Count-$failed.Count)/$($checks.Count) checks passed.**");$lines.Add('');$lines.Add('| Check | Status | Evidence |');$lines.Add('|---|---|---|');foreach($c in $checks){$lines.Add("| $($c.Check) | $(if($c.Pass){'PASS'}else{'FAIL'}) | $($c.Evidence) |")};$lines | Set-Content $md -Encoding ASCII
if($failed.Count){throw"Protected winner add-on safety failed: $($failed.Count)"};"THREE_LANE_PROTECTED_WINNER_ADDON_STATIC_SAFETY_PASS checks=$($checks.Count)"
