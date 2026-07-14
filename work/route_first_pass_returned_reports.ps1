param(
   [string]$InboxDir = "outputs\returned_mt5_reports\first_pass_inbox",
   [string]$ManifestPath = "outputs\FIRST_PASS_NEXT_RUN_PACKAGE_MANIFEST.csv",
   [string]$OutCsv = "outputs\FIRST_PASS_RETURNED_REPORT_ROUTING.csv",
   [string]$OutMarkdown = "outputs\FIRST_PASS_RETURNED_REPORT_ROUTING.md",
   [switch]$Move
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$allowedExtensions = @(".htm", ".html", ".xml")

function Resolve-RepoPath {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return $Path }
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Convert-ToRepoRelative {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   $root = $repo.TrimEnd('\') + '\'
   if($resolved.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
      return $resolved.Substring($root.Length)
   }
   return $resolved
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

function Ensure-ParentDir {
   param([string]$Path)
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

function Test-ReportTextPattern {
   param([string]$Text, [string[]]$Patterns)
   foreach($pattern in $Patterns) {
      if($Text -match $pattern) { return $true }
   }
   return $false
}

function Test-ReportFile {
   param([string]$Path)
   $item = Get-Item -LiteralPath $Path
   if($item.Length -le 0) {
      return [pscustomobject]@{ Status = "INVALID_REPORT"; Detail = "Report file is empty." }
   }

   $sample = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
   if([string]::IsNullOrWhiteSpace($sample)) {
      return [pscustomobject]@{ Status = "INVALID_REPORT"; Detail = "Report file contains only whitespace." }
   }

   $normalized = [System.Net.WebUtility]::HtmlDecode($sample)
   $requiredGroups = @(
      [pscustomobject]@{ Name = "net profit"; Patterns = @("Total\s+Net\s+Profit", "Net\s+Profit") },
      [pscustomobject]@{ Name = "profit factor"; Patterns = @("Profit\s+Factor") },
      [pscustomobject]@{ Name = "expected payoff"; Patterns = @("Expected\s+Payoff") },
      [pscustomobject]@{ Name = "Sharpe ratio"; Patterns = @("Sharpe\s+Ratio") },
      [pscustomobject]@{ Name = "total trades"; Patterns = @("Total\s+Trades") },
      [pscustomobject]@{ Name = "win rate/profit trades"; Patterns = @("Profit\s+Trades\s*\(%\s*of\s*total\)", "Win\s*Rate") },
      [pscustomobject]@{ Name = "max consecutive losses"; Patterns = @("Maximal\s+consecutive\s+losses", "Max\s+Consecutive\s+Losses") },
      [pscustomobject]@{ Name = "drawdown"; Patterns = @("Equity\s+Drawdown\s+Maximal", "Balance\s+Drawdown\s+Maximal") },
      [pscustomobject]@{ Name = "recovery factor"; Patterns = @("Recovery\s+Factor") }
   )

   $missing = @()
   foreach($group in $requiredGroups) {
      if(!(Test-ReportTextPattern $normalized $group.Patterns)) {
         $missing += $group.Name
      }
   }
   if($missing.Count -gt 0) {
      return [pscustomobject]@{
         Status = "INVALID_REPORT"
         Detail = "Report is missing required tester stat label(s): $($missing -join ', '). Export the full MT5 tester report, not a screenshot, balance-only report, or log excerpt."
      }
   }

   return [pscustomobject]@{ Status = "VALID"; Detail = "bytes=$($item.Length)" }
}

$resolvedInbox = Resolve-RepoPath $InboxDir
$resolvedManifest = Resolve-RepoPath $ManifestPath

if(!(Test-Path -LiteralPath $resolvedManifest)) {
   throw "First-pass report routing manifest not found: $resolvedManifest"
}
if(!(Test-Path -LiteralPath $resolvedInbox)) {
   New-Item -ItemType Directory -Path $resolvedInbox -Force | Out-Null
}

$manifest = @(Import-Csv -LiteralPath $resolvedManifest)

$inboxFiles = @(Get-ChildItem -LiteralPath $resolvedInbox -File -Recurse | Where-Object {
   $allowedExtensions -contains $_.Extension.ToLowerInvariant()
})

$expectedByName = @{}
foreach($row in $manifest) {
   $expectedByName[[string]$row.ExpectedReportName] = $true
}

$matchedFullNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$rows = [System.Collections.Generic.List[object]]::new()

foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $expected = [string]$item.ExpectedReportName
   $matches = @($inboxFiles | Where-Object { $_.BaseName -ieq $expected })
   $destinationBase = [string]$item.ReportDestination
   if([string]::IsNullOrWhiteSpace($destinationBase)) {
      $candidate = [string]$item.Candidate
      $destinationBase = Join-Path (Join-Path (Resolve-RepoPath "outputs\first_pass_validation_queue") $candidate) ("reports_here\" + $expected)
   }
   $destinationBase = Resolve-RepoPath $destinationBase

   if($matches.Count -eq 0) {
      $rows.Add([pscustomobject]@{
         QueueRank = $item.QueueRank
         Candidate = $item.Candidate
         Window = $item.Window
         Model = $item.Model
         ExpectedReportName = $expected
         Status = "MISSING_IN_INBOX"
         SourcePath = ""
         DestinationPath = $destinationBase
         Action = "Drop an exported .htm/.html/.xml report into the inbox with this exact base name."
      }) | Out-Null
      continue
   }

   if($matches.Count -gt 1) {
      foreach($match in $matches) { [void]$matchedFullNames.Add($match.FullName) }
      $rows.Add([pscustomobject]@{
         QueueRank = $item.QueueRank
         Candidate = $item.Candidate
         Window = $item.Window
         Model = $item.Model
         ExpectedReportName = $expected
         Status = "DUPLICATE_IN_INBOX"
         SourcePath = (($matches | ForEach-Object { Convert-ToRepoRelative $_.FullName }) -join "; ")
         DestinationPath = $destinationBase
         Action = "Remove duplicate report files for this expected report name, then rerun the router."
      }) | Out-Null
      continue
   }

   $source = $matches[0]
   [void]$matchedFullNames.Add($source.FullName)

   $preflight = Test-ReportFile -Path $source.FullName
   if($preflight.Status -ne "VALID") {
      $rows.Add([pscustomobject]@{
         QueueRank = $item.QueueRank
         Candidate = $item.Candidate
         Window = $item.Window
         Model = $item.Model
         ExpectedReportName = $expected
         Status = $preflight.Status
         SourcePath = Convert-ToRepoRelative $source.FullName
         DestinationPath = $destinationBase
         Action = $preflight.Detail
      }) | Out-Null
      continue
   }

   $destination = $destinationBase + $source.Extension.ToLowerInvariant()
   Ensure-ParentDir $destination
   if($Move) {
      Move-Item -LiteralPath $source.FullName -Destination $destination -Force
      $action = "Moved to reports_here"
   } else {
      Copy-Item -LiteralPath $source.FullName -Destination $destination -Force
      $action = "Copied to reports_here"
   }

   $rows.Add([pscustomobject]@{
      QueueRank = $item.QueueRank
      Candidate = $item.Candidate
      Window = $item.Window
      Model = $item.Model
      ExpectedReportName = $expected
      Status = "ROUTED"
      SourcePath = Convert-ToRepoRelative $source.FullName
      DestinationPath = Convert-ToRepoRelative $destination
      Action = $action
   }) | Out-Null
}

foreach($file in $inboxFiles | Sort-Object FullName) {
   if($matchedFullNames.Contains($file.FullName)) { continue }
   $status = if($expectedByName.ContainsKey($file.BaseName)) { "UNUSED_MATCHABLE" } else { "UNMATCHED_IN_INBOX" }
   $rows.Add([pscustomobject]@{
      QueueRank = ""
      Candidate = ""
      Window = ""
      Model = ""
      ExpectedReportName = $file.BaseName
      Status = $status
      SourcePath = Convert-ToRepoRelative $file.FullName
      DestinationPath = ""
      Action = "File name does not match the active first-pass package manifest."
   }) | Out-Null
}

$resolvedOutCsv = Resolve-RepoPath $OutCsv
$resolvedOutMarkdown = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $resolvedOutCsv
Ensure-ParentDir $resolvedOutMarkdown

$rows | Export-Csv -LiteralPath $resolvedOutCsv -NoTypeInformation -Encoding ASCII

$routed = @($rows | Where-Object Status -eq "ROUTED").Count
$missing = @($rows | Where-Object Status -eq "MISSING_IN_INBOX").Count
$duplicates = @($rows | Where-Object Status -eq "DUPLICATE_IN_INBOX").Count
$invalid = @($rows | Where-Object Status -eq "INVALID_REPORT").Count
$unmatched = @($rows | Where-Object Status -eq "UNMATCHED_IN_INBOX").Count
$readyToImport = ($missing -eq 0 -and $duplicates -eq 0 -and $invalid -eq 0 -and $unmatched -eq 0)

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# First-Pass Returned Report Routing")
$md.Add("")
$md.Add("Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.")
$md.Add("")
$md.Add(('- Inbox: `{0}`' -f $InboxDir))
$md.Add(('- Manifest: `{0}`' -f $ManifestPath))
$md.Add(('- Active expected reports: `{0}`' -f $manifest.Count))
$md.Add(('- Routed reports: `{0}`' -f $routed))
$md.Add(('- Missing expected reports: `{0}`' -f $missing))
$md.Add(('- Duplicate expected reports: `{0}`' -f $duplicates))
$md.Add(('- Invalid expected reports: `{0}`' -f $invalid))
$md.Add(('- Unmatched inbox files: `{0}`' -f $unmatched))
$md.Add(('- Ready to import: `{0}`' -f $readyToImport))
$md.Add("- Required tester-stat labels: `Total Net Profit`, `Profit Factor`, `Expected Payoff`, `Sharpe Ratio`, `Total Trades`, `Profit Trades (% of total)` or `Win Rate`, `Maximal consecutive losses`, `Balance/Equity Drawdown Maximal`, and `Recovery Factor`.")
$md.Add("")
if($readyToImport) {
   if($manifest.Count -eq 0) {
      $md.Add("No active first-pass reports are currently expected. The next-run package is empty.")
   } else {
      $md.Add("All active first-pass reports are routed. Run `work\refresh_first_pass_validation_state.ps1` to import and evaluate them.")
   }
} else {
   $md.Add("The inbox is not ready for import yet. Fix missing, duplicate, invalid, or unmatched files below, then rerun this router.")
}
$md.Add("")
$md.Add("## Routing Rows")
$md.Add("")
$md.Add("| Rank | Candidate | Window | Model | Expected Report | Status | Source | Destination | Action |")
$md.Add("| ---: | --- | --- | --- | --- | --- | --- | --- | --- |")
foreach($row in $rows) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |" -f
      (Escape-MarkdownCell $row.QueueRank),
      (Escape-MarkdownCell $row.Candidate),
      (Escape-MarkdownCell $row.Window),
      (Escape-MarkdownCell $row.Model),
      (Escape-MarkdownCell $row.ExpectedReportName),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.SourcePath),
      (Escape-MarkdownCell $row.DestinationPath),
      (Escape-MarkdownCell $row.Action)))
}

$md | Set-Content -LiteralPath $resolvedOutMarkdown -Encoding ASCII

[pscustomobject]@{
   Inbox = $InboxDir
   Manifest = $ManifestPath
   Routed = $routed
   Missing = $missing
   Duplicates = $duplicates
   Invalid = $invalid
   Unmatched = $unmatched
   ReadyToImport = $readyToImport
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
