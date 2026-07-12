# Score7 Regime Trade Diagnosis Note - 2026-07-12

## Summary

A focused Model=1 trade-log diagnostic reran the continuous `2024.01.01` to `2026.07.12` window with unique trade-log files for the prior Score7 profile and the Score7 Regime profile.

The diagnostic reproduced the exact Model=1 net-profit delta:

- Score7: `7970.70`
- Score7 Regime: `9753.58`
- Delta: `1782.88`

## Evidence Files

- `outputs/MODEL1_SCORE7_REGIME_TRADE_DIAG_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_TRADE_DIAG_SUMMARY.csv`

Common-files source logs:

- `Diag_score7_model1_continuous.csv`
- `Diag_score7_regime_model1_continuous.csv`

## Trade-Level Findings

Both profiles took the same number of trades:

- Entries: `63` versus `63`
- Closed deals: `63` versus `63`

The Regime profile did not improve by reducing trade count. It improved by changing the timing and sizing of later trades after spread-regime/M1-spread-shock filtering changed the path around August 2024.

The first material divergence appears in August 2024:

- Ticket `43`: Regime delayed a sell from `07:30` to `10:15`, reducing volume from `0.50` to `0.31`, but the delayed entry lost more: `-113.15` versus `-55.00`.
- Ticket `55`: Regime delayed a buy from `07:00` to `08:00`, entered at a better price/spread profile, and improved profit from `108.54` to `362.02`.
- Ticket `57`: Score7 bought at `08:00` and lost `-123.84`; Regime waited until `13:15`, sold instead, and won `226.72`.

The largest positive delta came later because the improved path compounded into larger profitable position sizing:

- Ticket `141`: Regime profit `3373.14` versus Score7 `2810.95`, delta `562.19`.

The largest negative delta was also later due to larger sizing:

- Ticket `143`: Regime loss `-1651.66` versus Score7 `-1375.36`, delta `-276.30`.

## Interpretation

The Model=1 edge is not a reporting artifact: the trade log reproduces the same `1782.88` delta and shows actual trade-timing differences.

However, the prior Model=0 confirmation was neutral. That means the spread-regime edge is still model-sensitive. It should remain documented as a research-best candidate, but not treated as production-grade until another independent model/source confirms the timing advantage.

## Next Gate

Run another independent validation source/model or broker history before raising risk. If that confirms the timing advantage, the next optimization target should be a controlled version of the spread-timing behavior rather than simply increasing risk.
