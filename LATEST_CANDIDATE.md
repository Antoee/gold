# Latest Candidate

Updated: 2026-07-20

## Provisional Historical Leader

- Candidate: `Momentum Same-Side Exit Cooldown 60`
- Status: provisional research leader; not live-approved and not substituted into the registered forward run
- Test: XAUUSD M15, MT5 Model 4 real ticks, `$10,000`, 2015-01-01 through 2026-07-12
- Net profit: `+$2,492.25`
- Ending balance: `$12,492.25`
- Total increase: `+24.92%`
- CAGR: `+1.95% per year`
- Profit factor: `1.93`
- Maximum equity drawdown: `1.18%`
- Recovery factor: `17.54`
- Return/drawdown: `21.12`
- Trades: `400`
- Improvement over the previous leader: `+$63.75`, `+0.64` return point, and `+0.05` CAGR point with the same rounded drawdown
- Improvement over ATB150: `+$387.17`, or `+18.39%` more historical net

## Validation

- Frozen 2015-2020 Model 1 discovery: pass; 90- and 120-minute neighbors support the 60-minute center
- Paired 2021-2026 Model 1 confirmation: pass
- Exact 2015-2026 Model 4 broad/continuous gate: pass in all three disjoint eras
- Annual Model 4 restarts: 12/12 profitable, 12/12 no worse, 3/12 strictly improved
- Hard-risk audit: pass; maximum portfolio initial risk `0.5869%` against `0.75%`
- Added-cost stress: pass; severe `0.10R` per trade retained `+$1,864.19`, PF `1.616`
- Clustered Monte Carlo: 8/8 scenarios pass, 10,000 trials each

## Evidence

- `outputs/THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_DECISION.md`
- `outputs/THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_DECISION.md`
- `outputs/THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_STRESS_DECISION.md`
- `outputs/THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_RISK_AUDIT.md`
- `release/three-lane-momentum-same-side-exit-cooldown-provisional/README.md`

## Strategy Change

After a momentum position exits, block only a new momentum entry on the same symbol, magic number, and position side for 60 elapsed minutes. The rule never reads whether the prior trade won or lost. Entry signals, stops, targets, risk, lot caps, portfolio guards, and real-account protections remain unchanged.

## Boundary

This is strong historical evidence, not proof of future profit. The attached `$100,000` demo violates the frozen `$10,000` forward contract and contributes zero valid days or trades. A second broker/specification test and valid forward evidence are still required. Real-account trading remains disabled.
