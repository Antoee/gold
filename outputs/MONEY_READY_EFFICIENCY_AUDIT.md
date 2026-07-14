# Money-Ready Efficiency Audit

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Overall: **PENDING**
- Verdict: **WAITING_FOR_EVIDENCE**
- Passing gates: `0`
- Pending gates: `17`
- Failed gates: `0`
- Continuous annualized return target: `12%`
- Continuous CAGR target: `10%`
- Continuous return/DD target: `3`
- Max equity DD target: `3%`

The efficiency decision is pending because broad exported MT5 evidence is still missing or incomplete.

## Gates

| Gate | Status | Required | Actual | Evidence | Next Action |
| --- | --- | --- | --- | --- | --- |
| full-evidence-coverage | PENDING | all 53 validation and 10 broker-proxy reports are parsed exported MT5 reports | validationRows=53/53; brokerRows=10/10; parsed=0/63; missingOrUnparsed=63 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Return every exported MT5 validation and broker-proxy report before judging efficiency. |
| full-stat-completeness | PENDING | every parsed report has return, annualized, CAGR, PF, expected payoff, Sharpe, win rate, trades, loss streak, drawdown, and recovery stats | parsed=0; missingStats=0 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Export full MT5 tester reports, not screenshots or balance-only snippets. |
| exact-continuous-report-present | PENDING | exact real-tick continuous report is parsed | status=MISSING_REPORT | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv | Return the exact real-tick continuous exported report. |
| growth:continuous-annualized-return | PENDING | continuous annualized return % >= 12 | continuous annualized return %= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv | Do not promote a tiny-profit bot as money-ready. |
| growth:continuous-cagr | PENDING | continuous CAGR % >= 10 | continuous CAGR %= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv | Require compounding growth strong enough to justify the time/risk. |
| efficiency:continuous-return-to-drawdown | PENDING | continuous return % / DD % >= 3 | continuous return % / DD %= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv | Require return to beat drawdown by a wide margin. |
| risk:continuous-drawdown-cap | PENDING | continuous equity DD % <= 3 | continuous equity DD %= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv | Reject candidates whose profit requires too much drawdown. |
| quality:continuous-trade-count | PENDING | continuous trades >= 20 | continuous trades= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv | Avoid trusting too-few-trade luck. |
| robustness:no-red-parsed-windows | PENDING | no parsed validation, stress, or broker-proxy window is net negative | parsed=0; redWindows=0; worst= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Do not promote until broad windows are non-red. |
| quality:min-profit-factor | PENDING | minimum parsed PF >= 1.25 | minimum parsed PF= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Require enough edge across all active parsed reports. |
| quality:min-expected-payoff | PENDING | minimum expected payoff >= 0 | minimum expected payoff= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Avoid profiles whose apparent profit comes with negative expectancy. |
| quality:min-sharpe | PENDING | minimum Sharpe ratio >= 0.1 | minimum Sharpe ratio= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Require positive risk-adjusted behavior. |
| quality:min-win-rate | PENDING | minimum win rate % >= 25 | minimum win rate %= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Avoid extremely brittle win/loss distributions. |
| risk:consecutive-loss-cap | PENDING | worst consecutive losses <= 5 | worst consecutive losses= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Keep loss streaks survivable before any live review. |
| efficiency:min-recovery-factor | PENDING | minimum recovery factor >= 1.5 | minimum recovery factor= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Require profit to recover drawdown efficiently. |
| growth:recent-2026-evidence | PENDING | recent/2026 parsed rows are non-red and annualized return >= 8% | recentRows=0; redRecent=0; minRecentAnnualized= | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Require the bot to still work on newer data, not only older windows. |
| robustness:stress-and-broker-survival | PENDING | stress and broker-proxy parsed rows are non-red and have PF >= 1.25 when trades exist | stressBrokerRows=0; red=0; weakPF=0 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv | Reject profiles that only work under the primary/default test condition. |
