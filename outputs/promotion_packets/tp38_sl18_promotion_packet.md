# Promotion Packet: tp38_sl18

Generated without launching MT5. This packet uses parsed report metrics only.

- Decision: **MISSING_EVIDENCE**
- Profile priority: 2
- Phase-2 seed: True
- Overrides: `InpMaxEquityDrawdownPercent=4.00;InpTakeProfitATRMultiplier=3.80`
- Guardrail status: REVIEW_REQUIRED
- Guardrail score: 90
- Equity drawdown guard: 4
- Risk flags: ``
- Overfit flags: `adaptive_reverse_requires_walk_forward`
- Phase-1 parsed: 0/8
- Phase-2 parsed: 0/11
- Phase-2 total net profit: 0.00
- Phase-2 split aggregate: 0.00
- Phase-2 worst window: missing
- Phase-2 losing windows: 0
- Phase-2 worst drawdown: missing
- Phase-2 average profit factor: missing

## Gates

| Gate | Status | Evidence | Required |
|---|---|---|---|
| Optimization guardrail tracked | PASS | status=REVIEW_REQUIRED, score=90, equity_dd=4, risk_flags=, overfit_flags=adaptive_reverse_requires_walk_forward | Guardrail audit exists and does not reject promotion |
| Equity drawdown guard active or baseline anchor | PASS | InpMaxEquityDrawdownPercent=4 | Non-baseline candidates must use an equity drawdown guard |
| Complete phase-2 evidence | FAIL | 0/11 parsed, 11 missing, 0 unparsed | Every phase-2 real-tick report parsed |
| Full-period profit beats baseline | FAIL | missing full-period phase-2 report | > 866.59 |
| Split aggregate beats baseline | FAIL | 0.00 | > 2354.65 |
| No losing phase-2 windows | FAIL | 0 losing windows | 0 losing windows |
| Worst window non-negative | FAIL | missing | >= 0.00 |
| Drawdown available for review | FAIL | missing | Parsed maximal drawdown |
| Profit factor available for review | FAIL | missing | Parsed profit factor |

## Rule

Only a PROMOTION_REVIEW packet may be considered for replacing the current default, and even then it still needs human review of drawdown shape, trade count, broker-data quality, and overfitting risk.
