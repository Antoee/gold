param(
   [string]$EvidencePath = "outputs\RC2_MOMENTUM_FEATURE_TELEMETRY_MO_2015_2018.csv",
   [string]$OutputPath = "outputs\RC2_MOMENTUM_FEATURE_TELEMETRY_SELECTION.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$rows = @(Import-Csv -LiteralPath (Resolve-RepoPath $EvidencePath) -Delimiter "`t" `
   -Header Time,Event,Symbol,Ticket,Side,Volume,Price,Stop,Profit,Reason,Profile,SourceHash,RunLabel)
$trades = [Collections.Generic.List[object]]::new()
$entry = $null
foreach($row in $rows) {
   if($row.Event -eq "entry") {
      if($row.Reason -notmatch "atr_pct=([0-9.]+)") { throw "Entry telemetry is missing ATR percent." }
      $entry = [pscustomobject]@{
         Time=[datetime]::ParseExact($row.Time,"yyyy.MM.dd HH:mm:ss",[Globalization.CultureInfo]::InvariantCulture)
         ATRPercent=[double]$Matches[1]
      }
   }
   elseif($row.Event -eq "exit" -and $null -ne $entry) {
      $trades.Add([pscustomobject]@{Time=$entry.Time;ATRPercent=$entry.ATRPercent;Profit=[double]$row.Profit}) | Out-Null
      $entry = $null
   }
}
if($trades.Count -ne 135) { throw "Expected 135 completed telemetry trades, found $($trades.Count)." }

$profiles = @(
   [pscustomobject]@{Name="mac_fixed_control";MaximumATRPercent=999.0},
   [pscustomobject]@{Name="mac_cap024";MaximumATRPercent=0.24},
   [pscustomobject]@{Name="mac_cap026";MaximumATRPercent=0.26},
   [pscustomobject]@{Name="mac_cap028";MaximumATRPercent=0.28}
)
$summary = foreach($profile in $profiles) {
   $kept = @($trades | Where-Object ATRPercent -le $profile.MaximumATRPercent)
   $grossWin = [double](($kept | Where-Object Profit -gt 0 | Measure-Object Profit -Sum).Sum)
   $grossLoss = -[double](($kept | Where-Object Profit -lt 0 | Measure-Object Profit -Sum).Sum)
   [pscustomobject]@{
      Candidate=$profile.Name
      MaximumATRPercent=if($profile.Name -eq "mac_fixed_control") { 2.50 } else { $profile.MaximumATRPercent }
      Trades=$kept.Count
      NetProfit=[math]::Round([double](($kept | Measure-Object Profit -Sum).Sum),2)
      ProfitFactor=[math]::Round($grossWin / $grossLoss,3)
      Net2015=[math]::Round([double](($kept | Where-Object { $_.Time.Year -eq 2015 } | Measure-Object Profit -Sum).Sum),2)
      Net2016=[math]::Round([double](($kept | Where-Object { $_.Time.Year -eq 2016 } | Measure-Object Profit -Sum).Sum),2)
      Net2017=[math]::Round([double](($kept | Where-Object { $_.Time.Year -eq 2017 } | Measure-Object Profit -Sum).Sum),2)
      Net2018=[math]::Round([double](($kept | Where-Object { $_.Time.Year -eq 2018 } | Measure-Object Profit -Sum).Sum),2)
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $OutputPath) -NoTypeInformation -Encoding ASCII
$summary
