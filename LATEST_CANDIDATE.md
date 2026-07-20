# Latest Candidate

Updated: 2026-07-20

## Provisional Historical Leader

- Candidate: `Strong-Signal Selective Reversion Lot Cap 0.15`
- Status: provisional research leader; not live-approved and not substituted into the registered forward run
- Test: XAUUSD M15, MT5 Model 4 real ticks, `$10,000`, 2015-01-01 through 2026-07-18
- Net profit: `+$2,428.50`
- Ending balance: `$12,428.50`
- Total increase: `+24.28%`
- CAGR: `+1.90% per year`
- Profit factor: `1.89`
- Maximum equity drawdown: `1.18%`
- Recovery factor: `17.09`
- Trades: `404`
- Improvement over ATB150: `+$323.42`, or `+15.36%` more historical net, with the same trade count

## Validation

- Sealed 2015-2020 discovery: pass
- Feature-level 2021-2026 validation: pass
- Exact 2015-2026 Model 4 broad/continuous gate: pass
- Annual Model 4 restarts: 12/12 profitable, 11/12 no worse than control
- Hard-risk audit: pass; maximum portfolio initial risk `0.5892%` against `0.75%`
- Added-cost stress: pass; severe `0.10R` per trade retained `+$1,798.19`, PF `1.59`
- Clustered Monte Carlo: 8/8 scenarios pass, 10,000 trials each

## Evidence

- `outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_DECISION.md`
- `outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_DECISION.md`
- `outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_STRESS_DECISION.md`
- `outputs/THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_RISK_AUDIT.md`

## Boundary

The attached `$100,000` demo violates the frozen `$10,000` forward contract and contributes zero valid days or trades. A second broker/specification test and valid forward evidence are still required. Real-account trading remains disabled.
