# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Workflow Change

Strengthened the profit-search analyzer so high net profit is no longer enough for a candidate to receive a promotion grade.

New robust promotion gates in `work\analyze_profit_search.ps1`:

- Minimum trades per parsed window.
- Minimum per-window profit factor.
- Minimum per-window recovery factor.
- Maximum drawdown-to-total-profit ratio.
- Positive recent/2026 net profit.
- Continued requirement for complete evidence, no losing windows, and non-negative worst window.

The analyzer now outputs additional ranking columns:

- `MinProfitFactor`
- `AverageRecoveryFactor`
- `MinRecoveryFactor`
- `MinTrades`
- `DrawdownToProfitRatio`
- `RecentNetProfit`
- `RobustEnough`

Added `work\test_profit_search_robust_ranking.ps1`, which proves that only a profitable candidate with enough trades, acceptable PF/recovery, positive recent profit, and controlled drawdown can receive `PromotionReview`. Positive-profit candidates with weak PF, weak recovery, too few trades, bad drawdown, or weak recent evidence are downgraded to `ProfitButRisky`.

This does not change live trade behavior, but it directly supports the goal by preventing fragile settings from being promoted just because they make more historical money.

## Current Ranking Result

`outputs\PROFIT_SEARCH_RANKING.md` now reports:

- Complete evidence rows: `0`
- Promotion review: no complete robust profitable evidence yet
- Required promotion evidence: complete phase-2 real-tick reports, profit above baseline, zero losing windows, non-negative worst window, minimum trades, minimum PF, minimum recovery, positive recent/2026 net, and acceptable drawdown-to-profit ratio.

## Quiet Validation Results

- `work\test_profit_search_robust_ranking.ps1`: PASS
- `work\analyze_profit_search.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 40 steps, 0 failed
- MT5-family process scan: empty

## Latest Hashes

- `work\analyze_profit_search.ps1`: `639B246B16DBEA0D874E5A7A877C17BEDAE3CF56D60D899ABDD8DBB13691CB0F`
- `work\test_profit_search_robust_ranking.ps1`: `4F741C30A9976FD579A3741CE5DA52CCE6128CBB2ED4C90DABB6C99E35BF551F`
- `work\refresh_offline_validation_state.ps1`: `8FD77D06025D2B4ACB6A080C1B2543EC6DD81543EEE3B4F6F205698E5694D71A`
- `outputs\PROFIT_SEARCH_RANKING.csv`: `E8C92F10D6D471DE829C0FB11008F6E071062C5F0F83A4D3E5DA2B81E9D65A25`
- `outputs\PROFIT_SEARCH_RANKING.md`: `A8E30E1BE68F0AE2C0C0541889877EE139A81AD14E7D49FDFF3E585E973FF474`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `5623AB713CE24358C7A7055C26961F7A6BB51D7BCF7DE130BB3805F6BF495C75`
- `outputs\OFFLINE_VALIDATION_REFRESH.md`: `688A4A9814A88CCCCAABDD180CD97DAC54FFBDAD869159B496823B3456685966`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.