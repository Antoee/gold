# Recent 2026 Fast Triage Status

Updated locally on 2026-07-06.

## Safety

- Local MT5/MetaEditor/Strategy Tester launch remains locked.
- Current work was done with hidden/no-window PowerShell only.
- Final local scan before this status update: no `terminal`, `terminal64`, `metatester`, `metatester64`, `MetaEditor`, or `metaeditor64` processes found.
- Quiet stop marker remains present: `work/STOP_MT5_FOCUS_WATCHDOG`.
- No watchdog process is intentionally running right now; the repo is in quiet no-resident-helper mode.

## Current EA Source

- Canonical source: `outputs/Professional_XAUUSD_EA.mq5`.
- Current synced source SHA256: `4EE1484812ED6148B154D0B0CB2807A110F1A1846C47673083CF7AA8F12E1E34`.
- EA source did not change in this pass.

## Multi-Window Decision Gate Addition

The price-action fast-triage summary now requires explicit recent/stress coverage before a profile can receive `PASS_FAST_TRIAGE`:

- Summary rows now track `RecentParsedWindows`, `StressParsedWindows`, `RecentPassWindows`, `StressPassWindows`, and `CompleteWindowCoverage`.
- `PASS_FAST_TRIAGE` now requires complete parsed coverage across all expected windows.
- `PASS_FAST_TRIAGE` also requires at least one passing recent window and one passing stress window.
- Added `REVIEW_INCOMPLETE_WINDOW_COVERAGE` for candidates that otherwise look acceptable but lack complete parsed recent/stress coverage.
- The markdown summary now displays recent/stress parsed and pass counts.
- The decision smoke now checks that a passing synthetic profile shows both recent and stress pass coverage.

This makes the gate harder to fool with one good recent run. A candidate must survive both recent data and the stress window before it can even pass fast triage, and promotion still requires broader validation.

## Existing Decision Gate Discipline

The offline price-action decision gate also rejects or reviews aggressively on quality metrics:

- `MinTradesPerWindow=5`.
- `MinProfitFactor=1.10`.
- `MinRecoveryFactor=1.00`.
- `MaxProfitFactorDegradation=0.05`.
- Higher net profit alone is not enough when PF, recovery, drawdown, compile proof, report coverage, or recent/stress consistency is weak.

## Current EA Strategy Features

The EA includes optional, independently configurable strategy modules for actual price-action, market-state, tick-tape, intermarket confirmation, weighted setup-quality logic, profit targeting, profit protection, and early loss control:

- CHoCH, FVG, order-block retest, liquidity sweep, previous/session levels, VWAP, candle anatomy, market phase, RSI, MACD, Bollinger, and tick microstructure confirmations.
- Correlated-market confirmation.
- Weighted entry-quality score.
- Quality-based risk scaling.
- Quality-based take-profit scaling.
- Regime-quality confirmation using ADX, EMA slope, and ATR regime.
- ATR-based profit-lock stop.
- Adverse-R early exit.

## Current Decision State

- Overall: `COMPILE_REQUIRED`.
- Decisions: 27.
- Pass: 0.
- Reject: 0.
- Waiting: 27.
- Compile trust: `STALE`.
- No profit claim is made.

## Offline Evidence

- `PRICE_ACTION_STRATEGY_DECISION_SMOKE_PASS`.
- `REPORT_IMPORT_PREFLIGHT_SMOKE_PASS`.
- Full offline refresh: PASS, 39 steps, 0 failed.
- Report import preflight rows:
  - Price-action strategy decision: `COMPILE_REQUIRED`, with 27 waiting report decisions and stale compile trust.
  - Source hash status smoke: PASS.
  - Local safety: PASS, 39 safety checks pass.
  - Compile status: `STALE`.
  - External MT5 package: PASS, 26 package checks pass.
- External MT5 package audit: PASS, 26 checks passed, 0 failed.

## Hashes

- EA source: `4EE1484812ED6148B154D0B0CB2807A110F1A1846C47673083CF7AA8F12E1E34`.
- Price-action decision CSV: `7646F4CD657C3A15DD1ED1E1A8393F6F1F462826FB38793FF6F5D4C88277C00F`.
- Price-action decision report: `ABA5EBBCABF558C3357F1F4E23158972B7A2F21316BAF8936D26B29AE61BFC60`.
- Report import preflight CSV: `FAC97A86AB47EC8429C22E135D7E012173FEEBA4D7CDC1894A8525E7321E29E1`.
- External validation package zip: `EDA3FA7A367BA00B04DCA09AAA4F3148E25E1D63670F9199774916C275C676F6`.
- Decision builder: `E1A3A8D50F74BA748A55A74CB6FF94A5FD7F725FF1C3540FAA6E0FC1849E3AA9`.
- Decision smoke: `B40CB73E4D6E0D80E18E157A13B747AF903807DA7E1DE4979244FD275FED31A8`.
- Report preflight smoke: `F05D46D11B3FBE71FAEDBA475EDAF3BAE7133008FDC0677BA95230DCC6541BB8`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run, then importing reports through this stricter multi-window decision gate.