param(
   [string]$OutCsv = "outputs\PORTFOLIO_PROFILE_CONTRACT_AUDIT.csv",
   [string]$OutMarkdown = "outputs\PORTFOLIO_PROFILE_CONTRACT_AUDIT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Parse-SourceInputs([string]$Path) {
   $text = Get-Content -LiteralPath $Path -Raw
   $matches = [regex]::Matches($text, '(?m)^\s*input\s+(?!group\b)[A-Za-z_][A-Za-z0-9_]*\s+([A-Za-z_][A-Za-z0-9_]*)\s*=')
   return @($matches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
}
function Parse-Profile([string]$Path) {
   $values = @{}
   foreach($line in (Get-Content -LiteralPath $Path)) {
      if($line -match '^([^=\s]+)=(.*)$') {
         $values[$matches[1]] = $matches[2]
      }
   }
   return $values
}
function First-Value([string]$Text) {
   if([string]::IsNullOrWhiteSpace($Text)) { return "" }
   return ($Text -split '\|\|', 2)[0]
}

$sources = @(
   [pscustomobject]@{ Name = "maintained_A167"; Path = "Professional_XAUUSD_EA.mq5" },
   [pscustomobject]@{ Name = "highprofit_F254"; Path = "outputs\range_elite_dgf_lossblock_highprofit_continuous_model4_package\source\Professional_XAUUSD_EA.mq5" },
   [pscustomobject]@{ Name = "reversion_DI_M12"; Path = "outputs\htf_band_reversion_di_gate_model4_package\source\Professional_XAUUSD_EA.mq5" },
   [pscustomobject]@{ Name = "account_guard_A167_prototype"; Path = "work\Professional_XAUUSD_EA_ACCOUNT_WIDE_GUARD.mq5" }
)
$profiles = @(
   [pscustomobject]@{ Name = "highprofit"; Path = "outputs\CANDIDATE_RANGE_ELITE_HIGHPROFIT_PEAKTRAIL_OFF_CONTINUOUS_PROFILE.set" },
   [pscustomobject]@{ Name = "money_ready"; Path = "outputs\CANDIDATE_MONEY_READY_PROFILE.set" },
   [pscustomobject]@{ Name = "reversion_di_m12"; Path = "outputs\htf_band_reversion_di_gate_model4_package\profiles\htf_band_reversion_di_m12.set" }
)

$sourceInfo = @{}
foreach($source in $sources) {
   $path = Resolve-RepoPath $source.Path
   if(!(Test-Path -LiteralPath $path)) { throw "Source missing: $path" }
   $sourceInfo[$source.Name] = [pscustomobject]@{
      Path = $source.Path
      Hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
      Inputs = @(Parse-SourceInputs $path)
   }
}

$profileInfo = @{}
foreach($profile in $profiles) {
   $path = Resolve-RepoPath $profile.Path
   if(!(Test-Path -LiteralPath $path)) { throw "Profile missing: $path" }
   $values = Parse-Profile $path
   $profileInfo[$profile.Name] = [pscustomobject]@{
      Path = $profile.Path
      Hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
      Values = $values
      Keys = @($values.Keys | Sort-Object)
      EvidenceSourceHash = First-Value ([string]$values["InpEvidenceSourceHash"])
      ProfileId = First-Value ([string]$values["InpEvidenceProfileId"])
      Magic = First-Value ([string]$values["InpMagicNumber"])
   }
}

$rows = [Collections.Generic.List[object]]::new()
foreach($profile in $profiles) {
   $p = $profileInfo[$profile.Name]
   foreach($source in $sources) {
      $s = $sourceInfo[$source.Name]
      $unknown = @($p.Keys | Where-Object { $_ -notin $s.Inputs })
      $defaulted = @($s.Inputs | Where-Object { $_ -notin $p.Keys })
      $identityMatch = $p.EvidenceSourceHash -eq $s.Hash
      $status = if($identityMatch -and $unknown.Count -eq 0) { "EXACT_DECLARED_SOURCE" }
                elseif($unknown.Count -eq 0) { "LOADABLE_SOURCE_DRIFT" }
                else { "INCOMPATIBLE_INPUT_CONTRACT" }
      $rows.Add([pscustomobject]@{
         Profile = $profile.Name
         ProfilePath = $p.Path
         ProfileSha256 = $p.Hash
         ProfileId = $p.ProfileId
         MagicNumber = $p.Magic
         EvidenceSourceSha256 = $p.EvidenceSourceHash
         Executable = $source.Name
         ExecutablePath = $s.Path
         ExecutableSha256 = $s.Hash
         SourceIdentityMatch = $identityMatch
         ProfileInputs = $p.Keys.Count
         ExecutableInputs = $s.Inputs.Count
         UnknownProfileInputs = $unknown.Count
         DefaultedExecutableInputs = $defaulted.Count
         UnknownInputNames = ($unknown -join ';')
         DefaultedInputNames = ($defaulted -join ';')
         Status = $status
         SharedExecutableReady = $false
      }) | Out-Null
   }
}

$rows | Export-Csv -LiteralPath (Resolve-RepoPath $OutCsv) -NoTypeInformation -Encoding ASCII
$duplicateMagics = @($profiles | ForEach-Object {
   [pscustomobject]@{ Profile = $_.Name; Magic = $profileInfo[$_.Name].Magic }
} | Group-Object Magic | Where-Object Count -gt 1)

$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Portfolio Profile Contract Audit") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("Decision: **not ready for a shared executable or multi-instance demo package.**") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("The analytical portfolio combines three separately reproduced streams. This audit checks whether their frozen `.set` files can be loaded into one currently available executable without input or source-identity drift.") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("| Profile | Magic | Executable | Identity | Unknown inputs | Defaults used | Status |") | Out-Null
$lines.Add("|---|---:|---|---:|---:|---:|---|") | Out-Null
foreach($row in $rows) {
   $lines.Add("| $($row.Profile) | $($row.MagicNumber) | $($row.Executable) | $($row.SourceIdentityMatch) | $($row.UnknownProfileInputs) | $($row.DefaultedExecutableInputs) | $($row.Status) |") | Out-Null
}
$lines.Add("") | Out-Null
$lines.Add("## Hard Blockers") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- No available executable is the declared source identity for all three profiles.") | Out-Null
$lines.Add("- High-profit and money-ready both use magic `26070402`; they would share position/history ownership if attached together.") | Out-Null
$lines.Add("- The maintained and account-guard A167 sources do not contain the experimental H1 reversion input contract.") | Out-Null
$lines.Add("- Loading a profile into a source with a different hash applies executable defaults for missing `.set` inputs and is not an exact reproduction.") | Out-Null
$lines.Add("- The account-wide guard prototype compiles, but it is not present in the exact reversion or high-profit executables.") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("Required next: create one frozen portfolio executable, assign unique magic numbers, enable a shared account cap, and reproduce every component before an interaction/demo test.") | Out-Null
$lines | Set-Content -LiteralPath (Resolve-RepoPath $OutMarkdown) -Encoding ASCII

[pscustomobject]@{
   Status = "NOT_READY"
   Rows = $rows.Count
   ExactRows = @($rows | Where-Object Status -eq "EXACT_DECLARED_SOURCE").Count
   SharedReadyRows = @($rows | Where-Object SharedExecutableReady).Count
   DuplicateMagicGroups = $duplicateMagics.Count
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
