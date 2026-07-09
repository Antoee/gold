# Local MT5 validation update - 2026-07-09 afternoon

Objective: push the XAUUSD EA toward materially higher profit while preserving broad validation across 2024, 2025, 2026 YTD, and weak 2026 months.

## Current primary candidate remains M15 peak liquidity/chop profile

Best broad profile is still `outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`:

- 2024_to_2026: +801.84
- 2026_ytd: +84.72
- 2025_full: +124.51
- 2024_full: +801.84
- Weak 2026 months: Mar -84.88, May -99.55, Jun -70.90

It is profitable but still too sparse and too concentrated in 2024. It does not meet the 2-3% monthly target.

## M5 risk scaling did not solve it

`outputs/LOCAL_MT5_M5_RISK_SUMMARY.csv`:

- `m5_fq_r1`: continuous +190.88, YTD +113.95, weak sum +8.16
- `m5_fq_r150`: continuous -351.98, YTD +810.31, but poor broad robustness
- `m5_fq_r2/r3`: unstable; larger risk created unacceptable losses in older windows

Conclusion: M5 improves some recent slices but is not a primary replacement.

## Opportunity expansion corrected result

After fixing config/compact workflow, extra M15 lanes did not beat base. Many power/session/breakout additions either matched base or reduced robustness.

## Builder bug fixed

A PowerShell builder issue was found: ordered dictionaries were passed into `[hashtable]` parameters, causing overrides to be applied to a converted copy. This made some generated configs silently revert to base values. Fixed in:

- `work/build_tighter_execution_validation_package.ps1`
- `work/build_legacy_candidate_retest_package.ps1`

Corrected configs now preserve overrides like M5 timeframe and tighter ATR stops.

## Corrected tighter execution results

`outputs/LOCAL_MT5_TIGHTER_EXECUTION_RANKED_FIXED.csv`:

- `m5_tight_liq`: continuous +98.63, YTD +249.78, weak sum +173.81, min weak -65.30
- `m5_fast_sessions`: continuous +85.44, YTD +259.70, weak sum -63.82
- Most tighter M15/M5 alternatives were negative broad-profile tests

Conclusion: M5 tight-liquidity improves recent/weak-month behavior, but gives up too much 2024/continuous profit.

## M5 tight-liquidity risk sweep

`outputs/LOCAL_MT5_M5_TLIQ_RISK_RANKED.csv`:

- `m5_tliq_r150_lossguard`: continuous +452.31, YTD +314.05, 2025 +15.87, 2024 +452.31, weak sum -17.57, min weak -143.43
- `m5_tliq_r200`: continuous +430.99 but YTD -278.48 and 2025 -330.99
- `m5_tliq_r1`: continuous +98.63, YTD +249.78, weak sum +173.81

Conclusion: controlled 1.5% risk with loss guard is the best M5 research branch so far, but still below M15 peak continuous profit.

## M5 tight-liquidity regime sweep

`outputs/LOCAL_MT5_M5_TLIQ_REGIME_RANKED.csv`:

- `adx_strong`: continuous +460.70, YTD +315.71, 2025 +15.87, 2024 +460.70, weak sum +197.34, min weak -56.70
- `base_r150_lossguard`: continuous +452.31, YTD +314.05, weak sum -17.57
- `vwap_near`: YTD +368.71 and 2025 +355.34, but 2024 -366.90
- `trend_phase`: weak sum +1393.18 but continuous -542.21; rejected as unstable

Conclusion: `adx_strong` is the best M5 secondary research lane because it improves YTD and weak-month behavior while avoiding the worst drawdown behavior, but it still does not beat the M15 primary candidate on broad continuous profit.

## Promotion decision

No new profile is promoted over the M15 peak candidate yet.

Research branches worth keeping:

- `m5_tliq_r150_lossguard`
- `m5_tliq_adx_strong`

Next useful work:

1. Build a true portfolio/regime controller instead of choosing M15 vs M5 by date.
2. Use M15 trend/structure as the primary lane and M5 tight-liquidity only when ADX/volatility/monthly opportunity conditions justify it.
3. Validate any combined logic on the same 2024_to_2026, 2026_ytd, 2025_full, 2024_full, and weak-month windows.
