# Profit Search Report Metrics

Generated from exported MT5 report files only. No MT5 process was launched.

- Manifest: `work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv`
- Report name template: `profit_search_{PhaseShort}_{Profile}_{Set}_{Window}`
- Expected reports: 183
- Parsed reports: 0
- Missing reports: 183
- Unparsed reports: 0

## Summary

The profit-search pack contains 16 candidate profiles:

- 128 phase-1 fast triage configs using `Model=2`.
- 55 phase-2 real-tick validation configs using `Model=4`.

No candidate can be promoted from phase 1 alone. Promotion still requires real-tick validation, no losing robustness windows, drawdown/profit-factor review, and the promotion gate.
