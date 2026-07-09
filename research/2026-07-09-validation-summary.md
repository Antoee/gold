# MT5 XAUUSD Validation Summary - 2026-07-09

Local workspace source artifacts were synced and smoke-tested. The canonical EA source is in `Professional_XAUUSD_EA.mq5` locally and in `outputs/Professional_XAUUSD_EA.mq5`.

## Source checks

- `test_price_action_strategy_modules.ps1`: PASS
- `test_price_action_strategy_batch.ps1`: PASS
- `sync_ea_source_artifacts.ps1`: PASS
- Canonical source hash: `68DD1E86DC71BAB52C0A261B84D0D8F62D5296F707AF8CDDEEE9B067101E5DD7`

## Key MT5 validation results

All tests used XAUUSD M15, $1,000 deposit, local hidden MT5 runs, compact tester sources, and fully pinned tester inputs to avoid MT5 input carryover.

### Regime/path matrix

Best robust-looking branch from the clean matrix was the research-only Q1 date block:

| Profile | 2026 Q1 | 2026 Q2 | 2026 YTD | 2025 Q2 | 2025 Full | 2024 Full |
|---|---:|---:|---:|---:|---:|---:|
| risk10_block_2026q1 | 0.00 | 90.17 | 45.85 | 111.12 | 466.62 | 87.19 |
| risk10_block_2026q1_spread | 0.00 | 90.17 | 45.85 | 111.12 | 496.82 | 87.19 |
| risk10_base | -92.79 | 90.17 | -233.94 | 111.12 | 466.62 | 87.19 |

Important caveat: the Q1 block is date-specific and should be treated as research-only until there is a non-date-based market-regime explanation.

### Candidate verification

| Profile | 2024-2026 Continuous | 2026 YTD | Jan | Feb | Mar | Apr | May | Jun |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| risk10_base | 988.67 | -233.94 | -44.63 | -60.66 | -85.40 | 234.34 | -93.86 | -70.90 |
| risk10_block_2026q1 | 633.09 | 45.85 | 0.00 | 0.00 | 0.00 | 234.34 | -93.86 | -70.90 |
| risk10_recovery_scale | -243.55 | 60.15 | -44.63 | -60.66 | -85.40 | 234.34 | -93.86 | -70.90 |

### Profit protection validation

Q1 block plus account-level profit protection improved 2026 YTD but reduced the continuous multi-year result.

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Apr 2026 | May 2026 | Jun 2026 |
|---|---:|---:|---:|---:|---:|---:|---:|
| block_base | 633.09 | 45.85 | 466.62 | 87.19 | 234.34 | -93.86 | -70.90 |
| block_peak_trail15 | 319.83 | 247.29 | 175.52 | 319.83 | 247.29 | -93.86 | -70.90 |
| block_equity_lock75 | 287.07 | 231.08 | 175.52 | 287.07 | 231.08 | -93.86 | -70.90 |

## Implementation notes

- Added `InpDiagnosticFallbackDebug=false` so fallback entry testing no longer floods MT5 tester logs.
- Config expander now normalizes existing string inputs, preventing bad `InpAllowedSymbol=XAUUSD||...` contamination.
- The strongest profitable results are not yet robust enough for promotion as a live strategy. They either rely on a date-specific block or sacrifice the best continuous multi-year profit.

## Next work

- Replace the Q1 date block with a genuine regime detector if possible.
- Explore profit-protection rules that protect April-style gains without killing 2024-2026 continuous performance.
- Keep all candidate profiles default-off until walk-forward validation supports promotion.
