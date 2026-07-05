# Backtest Results

EA: `Professional_XAUUSD_EA`

Symbol/timeframe: `XAUUSD`, `M15`

Main validation period: `2024.01.01` to `2026.07.02`

Deposit: `$1,000`

Leverage: `1:100`

## Current Promoted Robust No-Date Results

The promoted default is the no-date BOS + liquidity-sweep profile at `1.60%` risk with a `1.80` ATR stop and `3.50` ATR take-profit.

Full real-tick period `2024.01.01` to `2026.07.02`:

- Final balance: `$1,866.59`
- Net profit: `+$866.59`

Monthly and quarterly validation:

- Monthly total: `+$744.03`, worst month `$0.00`, 0 losing months.
- Quarterly total: `+$744.03`, worst quarter `$0.00`, 0 losing quarters.
- Split aggregate: `+$2,354.65`, worst split window `$0.00`, 0 losing split windows.

Conclusion: this profile makes much less historical profit than the date-block benchmark, but it is the best validated no-date default so far.

## Promotion Gate Status

Current gate result:

- `promoted_risk160_sl18_tp35`: `PASS`, 4/4 evidence sets, worst observed window `$0.00`.
- `risk160_sl18_tp38`: `MISSING_EVIDENCE`, missing full/split/quarter/month validation.
- `risk160_sl16_tp38`: `MISSING_EVIDENCE`, missing full/split/quarter/month validation.
- `risk160_sl18_tp35_giveback`: `MISSING_EVIDENCE`, missing full/split/quarter/month validation.

## Profile Input Audit Status

Current audit result:

- `ROBUST_BOS_SWEEP_PROFILE.set`: `PASS`, 35/35 critical inputs pinned.
- `CANDIDATE_RISK16_SL18_TP38_PROFILE.set`: `PASS`, 35/35 critical inputs pinned.
- `CANDIDATE_RISK16_SL16_TP38_PROFILE.set`: `PASS`, 35/35 critical inputs pinned.
- `CANDIDATE_RISK16_SL18_TP35_GIVEBACK_PROFILE.set`: `PASS`, 35/35 critical inputs pinned.

## Validation Report Collector Status

`work/collect_validation_results.ps1` parses exported MT5 report files without launching MT5.

Current standard validation collector status:

- Expected reports: 196
- Parsed reports: 0
- Missing reports: 196

The collector normalizes net profit, derived final balance, profit factor, expected payoff, total trades, maximal drawdown, and recovery factor when reports exist.

## Profit Search Pack Status

A controlled profit-search pack was generated around the current robust no-date BOS/sweep profile.

Current generated pack:

- `work/generated_profit_search/`
- 16 candidate `.set` profiles.
- 128 phase-1 fast triage configs using `Model=2`.
- 55 phase-2 real-tick validation configs using `Model=4`.
- `PROFIT_SEARCH_REPORT_METRICS.md` currently shows 183 expected reports, 0 parsed, 183 missing.

This pack searches TP/SL, trailing, risk, break-even, and profit-giveback neighborhoods without adding martingale, grid, averaging down, or date-specific recovery behavior.

Phase 1 is for speed only. No candidate should be promoted from phase 1 results alone.

## Aggressive Date-Block Benchmark

The previous date-block profile made `+$4,153.12` on the full period, but it used date-specific blocks and had 17 losing months out of 30. It remains a benchmark, not the promoted default.

## Local MT5 Safety Note

No new local MT5 validation should run while normal PC use is the priority. Local MT5 launch is hard-locked behind both `ALLOW_MT5_FOCUS_RISK=1` and `work/ALLOW_MT5_LOCAL_LAUNCH.unlock` because `terminal64.exe` can still flash and steal focus on this machine.

## Next Target

Increase profit from the robust BOS/sweep profile without bringing back losing monthly windows.

1. Validate `risk160_sl18_tp38`, `risk160_sl16_tp38`, and `risk160_sl18_tp35_giveback` across monthly, quarterly, yearly, half-year, and full-period windows.
2. Use the profit-search pack to identify higher-profit candidates.
3. Validate survivors with real ticks and the promotion gate.
4. Keep local MT5 tests blocked until the hidden-desktop runner has been deliberately verified.
