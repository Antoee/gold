param(
   [string]$ProfilePath = "outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set",
   [string]$LiveReadinessDecisionPath = "outputs\TRADE_READY_LIVE_READINESS_DECISION.csv",
   [string]$MoneyReadyScorecardPath = "outputs\MONEY_READY_STATUS_SCORECARD.csv",
   [string]$OutCsv = "outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.csv",
   [string]$OutMarkdown = "outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.md",
   [string]$OutLockedProfile = "outputs\TRADE_READY_RELEASE_PROFILE_LOCKED.set",
   [string]$OutManualLiveReviewProfile = "outputs\TRADE_READY_MANUAL_LIVE_REVIEW_PROFILE.set",
   [switch]$GenerateManualLiveReviewProfile,
   [string]$ApprovalCode = "",
   [string]$ApprovalProfileId = "",
   [string]$ApprovalSourceHash = "",
   [string]$ApprovalRunLabel = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return $Path }
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Read-CsvSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   if(Test-Path -LiteralPath $resolved) { return @(Import-Csv -LiteralPath $resolved) }
   return @()
}

function Get-Value {
   param([object]$Row, [string]$Name, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

function Get-SetValue {
   param([string]$ProfileText, [string]$Name)
   $pattern = "(?m)^" + [regex]::Escape($Name) + "=([^\r\n|]*)"
   $match = [regex]::Match($ProfileText, $pattern)
   if(!$match.Success) { return "" }
   return $match.Groups[1].Value
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

function Set-ProfileValue {
   param([string[]]$Lines, [string]$Name, [string]$Value)
   $updated = @($Lines)
   $found = $false
   for($i = 0; $i -lt $updated.Count; $i++) {
      if($updated[$i] -match ("^" + [regex]::Escape($Name) + "=")) {
         $line = [string]$updated[$i]
         $suffix = ""
         $suffixIndex = $line.IndexOf("||")
         if($suffixIndex -ge 0) {
            $suffix = $line.Substring($suffixIndex)
         }
         $updated[$i] = "$Name=$Value$suffix"
         $found = $true
      }
   }
   if(!$found) {
      $updated += "$Name=$Value"
   }
   return @($updated)
}

function Write-ProfileLines {
   param([string]$Path, [string[]]$Lines)
   $resolved = Resolve-RepoPath $Path
   $parent = Split-Path -Parent $resolved
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   $Lines | Set-Content -LiteralPath $resolved -Encoding ASCII
}

function Get-StatusSummary {
   param([object[]]$Rows)
   $fail = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" }).Count
   $pending = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "PENDING" }).Count
   $pass = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "PASS" }).Count
   $status = if($Rows.Count -eq 0) { "PENDING" } elseif($fail -gt 0) { "FAIL" } elseif($pending -gt 0) { "PENDING" } else { "PASS" }
   return [pscustomobject]@{
      Status = $status
      Pass = $pass
      Pending = $pending
      Fail = $fail
      Rows = $Rows.Count
   }
}

$profileFullPath = Resolve-RepoPath $ProfilePath
$profileExists = Test-Path -LiteralPath $profileFullPath
$profileText = if($profileExists) { Get-Content -LiteralPath $profileFullPath -Raw } else { "" }
$profileLines = if($profileExists) { @(Get-Content -LiteralPath $profileFullPath) } else { @() }
$profileHash = if($profileExists) { (Get-FileHash -LiteralPath $profileFullPath -Algorithm SHA256).Hash } else { "" }

$evidenceProfileId = Get-SetValue $profileText "InpEvidenceProfileId"
$evidenceSourceHash = Get-SetValue $profileText "InpEvidenceSourceHash"
$evidenceRunLabel = Get-SetValue $profileText "InpEvidenceRunLabel"

$liveRows = @(Read-CsvSafe $LiveReadinessDecisionPath)
$scoreRows = @(Read-CsvSafe $MoneyReadyScorecardPath)
$liveSummary = Get-StatusSummary $liveRows
$scoreSummary = Get-StatusSummary $scoreRows

$rows = [System.Collections.Generic.List[object]]::new()
function Add-ReleaseRow {
   param(
      [string]$Area,
      [string]$Status,
      [string]$Actual,
      [string]$Required,
      [string]$Evidence,
      [string]$NextAction
   )
   $rows.Add([pscustomobject]@{
      Area = $Area
      Status = $Status
      Actual = $Actual
      Required = $Required
      Evidence = $Evidence
      NextAction = $NextAction
   }) | Out-Null
}

Add-ReleaseRow "profile-source" ($(if($profileExists) { "PASS" } else { "PENDING" })) `
   "exists=$profileExists; hash=$profileHash; evidenceProfile=$evidenceProfileId; evidenceSource=$evidenceSourceHash; evidenceRun=$evidenceRunLabel" `
   "Conservative profile exists with evidence identity" `
   $ProfilePath `
   "Generate the conservative trade-ready profile."

Add-ReleaseRow "live-readiness-decision" $liveSummary.Status `
   "rows=$($liveSummary.Rows); pass=$($liveSummary.Pass); pending=$($liveSummary.Pending); fail=$($liveSummary.Fail)" `
   "Final live-readiness decision has zero pending and zero failed gates" `
   $LiveReadinessDecisionPath `
   "Close every live-readiness gate before release review."

Add-ReleaseRow "money-ready-scorecard" $scoreSummary.Status `
   "rows=$($scoreSummary.Rows); pass=$($scoreSummary.Pass); pending=$($scoreSummary.Pending); fail=$($scoreSummary.Fail)" `
   "Money-ready scorecard has zero pending and zero failed rows" `
   $MoneyReadyScorecardPath `
   "Regenerate the scorecard after proof gates pass."

$approvalMatches = (
   $ApprovalCode -eq "ALLOW_REAL_ACCOUNT_TRADING" -and
   ![string]::IsNullOrWhiteSpace($ApprovalProfileId) -and
   ![string]::IsNullOrWhiteSpace($ApprovalSourceHash) -and
   ![string]::IsNullOrWhiteSpace($ApprovalRunLabel) -and
   $ApprovalProfileId -eq $evidenceProfileId -and
   $ApprovalSourceHash -eq $evidenceSourceHash
)

$evidenceFailed = ($liveSummary.Status -eq "FAIL" -or $scoreSummary.Status -eq "FAIL")
$evidencePending = (!$profileExists -or $liveSummary.Status -eq "PENDING" -or $scoreSummary.Status -eq "PENDING")

if($profileExists) {
   $lockedLines = @($profileLines)
   $lockedLines = Set-ProfileValue $lockedLines "InpAllowRealAccountTrading" "false"
   $lockedLines = Set-ProfileValue $lockedLines "InpRealAccountApprovalCode" "DISABLED"
   $lockedLines = Set-ProfileValue $lockedLines "InpRealAccountApprovalProfileId" "DISABLED"
   $lockedLines = Set-ProfileValue $lockedLines "InpRealAccountApprovalSourceHash" "DISABLED"
   Write-ProfileLines $OutLockedProfile $lockedLines
   Add-ReleaseRow "locked-release-profile" "PASS" "written=$OutLockedProfile" "A locked profile is always written for paper/demo use" $OutLockedProfile "Use this profile only for demo/paper or tester work."
} else {
   Add-ReleaseRow "locked-release-profile" "PENDING" "profile missing" "A locked profile is always written for paper/demo use" $OutLockedProfile "Generate the profile first."
}

$releaseVerdict = if($evidenceFailed) {
   "NOT_RELEASEABLE_FAILED"
} elseif($evidencePending) {
   "NOT_RELEASEABLE_PENDING_EVIDENCE"
} elseif(!$GenerateManualLiveReviewProfile) {
   "MANUAL_APPROVAL_READY_LOCKED"
} elseif(!$approvalMatches) {
   "NOT_RELEASEABLE_APPROVAL_INVALID"
} else {
   "MANUAL_LIVE_REVIEW_PROFILE_WRITTEN"
}

if($releaseVerdict -eq "NOT_RELEASEABLE_APPROVAL_INVALID") {
   Add-ReleaseRow "approval-identity" "FAIL" `
      "code=$ApprovalCode; profile=$ApprovalProfileId; source=$ApprovalSourceHash; runLabel=$ApprovalRunLabel; expectedProfile=$evidenceProfileId; expectedSource=$evidenceSourceHash" `
      "Explicit approval code, profile id, source hash, and run label match the evidence identity" `
      "command parameters" `
      "Supply a matching approval identity only after all evidence gates pass."
} elseif($GenerateManualLiveReviewProfile -and $approvalMatches) {
   Add-ReleaseRow "approval-identity" "PASS" `
      "code=$ApprovalCode; profile=$ApprovalProfileId; source=$ApprovalSourceHash; runLabel=$ApprovalRunLabel" `
      "Explicit approval identity is present and matches evidence identity" `
      "command parameters" `
      "Review the generated manual live-review profile before any real use."
} elseif($evidencePending -or $evidenceFailed) {
   Add-ReleaseRow "approval-identity" "PENDING" `
      "evidence not complete; live approval ignored" `
      "Approval identity is only considered after evidence gates pass" `
      "command parameters" `
      "Finish proof gates first."
} else {
   Add-ReleaseRow "approval-identity" "PENDING" `
      "GenerateManualLiveReviewProfile=false" `
      "Explicit approval switch and matching identity are required to write a live-review profile" `
      "command parameters" `
      "Run again with explicit approval parameters only if you intentionally want a manual review profile."
}

if($releaseVerdict -eq "MANUAL_LIVE_REVIEW_PROFILE_WRITTEN") {
   $liveLines = @($profileLines)
   $liveLines = Set-ProfileValue $liveLines "InpAllowRealAccountTrading" "true"
   $liveLines = Set-ProfileValue $liveLines "InpRealAccountApprovalCode" "ALLOW_REAL_ACCOUNT_TRADING"
   $liveLines = Set-ProfileValue $liveLines "InpRealAccountApprovalProfileId" $ApprovalProfileId
   $liveLines = Set-ProfileValue $liveLines "InpRealAccountApprovalSourceHash" $ApprovalSourceHash
   Write-ProfileLines $OutManualLiveReviewProfile $liveLines
   $manualHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $OutManualLiveReviewProfile) -Algorithm SHA256).Hash
   Add-ReleaseRow "manual-live-review-profile" "PASS" `
      "written=$OutManualLiveReviewProfile; hash=$manualHash" `
      "Live-review profile is only written after all evidence gates pass and explicit approval identity matches" `
      $OutManualLiveReviewProfile `
      "Manually review account size, broker terms, and risk before any live use."
} else {
   Add-ReleaseRow "manual-live-review-profile" "PENDING" `
      "not written; verdict=$releaseVerdict" `
      "No live-review profile is written until evidence and explicit approval both pass" `
      $OutManualLiveReviewProfile `
      "Do not create or use a real-account profile yet."
}

$outCsvPath = Resolve-RepoPath $OutCsv
$outMarkdownPath = Resolve-RepoPath $OutMarkdown
foreach($path in @($outCsvPath, $outMarkdownPath)) {
   $parent = Split-Path -Parent $path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

$rows | Export-Csv -LiteralPath $outCsvPath -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Trade-Ready Release Candidate Decision")
$md.Add("")
$md.Add("Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.")
$md.Add("")
$md.Add(("- Verdict: **{0}**" -f $releaseVerdict))
$md.Add(('- Source profile: `{0}`' -f $ProfilePath))
$md.Add(('- Source profile hash: `{0}`' -f $profileHash))
$md.Add(('- Evidence profile id: `{0}`' -f $evidenceProfileId))
$md.Add(('- Evidence source hash: `{0}`' -f $evidenceSourceHash))
$md.Add(('- Locked profile: `{0}`' -f $OutLockedProfile))
$md.Add(('- Manual live-review profile: `{0}`' -f $(if($releaseVerdict -eq "MANUAL_LIVE_REVIEW_PROFILE_WRITTEN") { $OutManualLiveReviewProfile } else { "not written" })))
$md.Add("")
if($releaseVerdict -eq "MANUAL_LIVE_REVIEW_PROFILE_WRITTEN") {
   $md.Add("All automated gates passed and a matching explicit approval identity was supplied. This profile is for manual live review only; it is not a profit guarantee.")
} elseif($releaseVerdict -eq "MANUAL_APPROVAL_READY_LOCKED") {
   $md.Add("All automated gates passed, but no live-review profile was written because explicit approval was not supplied.")
} elseif($releaseVerdict -eq "NOT_RELEASEABLE_FAILED") {
   $md.Add("The candidate is not releaseable because at least one required gate failed.")
} elseif($releaseVerdict -eq "NOT_RELEASEABLE_APPROVAL_INVALID") {
   $md.Add("The candidate passed evidence gates, but the approval identity was missing or did not match the evidence identity.")
} else {
   $md.Add("The candidate is not releaseable yet because required evidence is still missing or stale. Real-account trading remains locked.")
}
$md.Add("")
$md.Add("## Release Checks")
$md.Add("")
$md.Add("| Area | Status | Actual | Required | Evidence | Next Action |")
$md.Add("| --- | --- | --- | --- | --- | --- |")
foreach($row in $rows) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} |" -f
      (Escape-MarkdownCell $row.Area),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.Actual),
      (Escape-MarkdownCell $row.Required),
      (Escape-MarkdownCell $row.Evidence),
      (Escape-MarkdownCell $row.NextAction)))
}

$md | Set-Content -LiteralPath $outMarkdownPath -Encoding ASCII

[pscustomobject]@{
   Verdict = $releaseVerdict
   ProfileHash = $profileHash
   EvidenceProfileId = $evidenceProfileId
   EvidenceSourceHash = $evidenceSourceHash
   LiveStatus = $liveSummary.Status
   ScorecardStatus = $scoreSummary.Status
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
   OutLockedProfile = $OutLockedProfile
   OutManualLiveReviewProfile = $(if($releaseVerdict -eq "MANUAL_LIVE_REVIEW_PROFILE_WRITTEN") { $OutManualLiveReviewProfile } else { "" })
}
