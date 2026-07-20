# Three-Lane Momentum Buy Residual-Risk Discovery Decision

**Decision: REJECTED IN DISCOVERY. No recent confirmation, Model 4, promotion, forward change, or live approval is permitted.**

- Exact accepted reports: `18/18`; unchanged identity retry refusals preserved: `1`
- Source SHA-256: `872028C76FDD4183E6266BB0E48125BB6B0F48EA3E77B9663B92A7F68B9ACD04`
- EX5 SHA-256: `0093251D7E6D9EAFBAC1B8B056DBB876CC1C63D462F93BDE5FCDE98BC9162642`
- Manifest SHA-256: `DFF64057A4A8B9969198F3CE517E07E53FCF3A16CE4CFCB198FB79BA772CA53F`
- `$10,000`; MT5 Model 1; 2015-2020 discovery; base momentum risk `0.15%`; portfolio cap `0.75%`; real trading disabled
- Base-lot eligibility was required before residual sizing; architecture was selected from the full leader ledger

| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 | CONTROL |
| Buy 0.16% | +$976.54 | +$361.84 | +$1,332.61 | 13.33% | 2.11%/yr | 1.79 | 265 | 1.11% | 11.3694 | 12.009 | False |
| Buy 0.17% | +$1,027.79 | +$364.91 | +$1,353.19 | 13.53% | 2.14%/yr | 1.78 | 265 | 1.24% | 9.6892 | 10.9113 | False |
| Buy 0.18% | +$1,045.47 | +$352.09 | +$1,427.72 | 14.28% | 2.25%/yr | 1.79 | 265 | 1.33% | 9.5321 | 10.7368 | False |
| Buy 0.19% | +$1,037.38 | +$323.47 | +$1,439.32 | 14.39% | 2.27%/yr | 1.77 | 265 | 1.33% | 9.6096 | 10.8195 | False |
| **Buy 0.20% center** | +$1,072.03 | +$389.01 | +$1,524.39 | 15.24% | 2.39%/yr | 1.78 | 266 | 1.3% | 10.3976 | 11.7231 | False |

## Frozen Gate

- Every disjoint era profitable: `True`
- Center retains 98% of both era controls: `True`
- Center continuous net at least 4% above control: `True`
- Center CAGR at least 0.06 point above control: `True`
- Center retains 97% PF/recovery/return-DD: `False`
- Center drawdown no more than 1.16%: `False`
- Center preserves control trade count: `False`
- Lower rungs passing: `0/4`; required: `3/4`

## Interpretation

The center increased continuous net by `+$170.65`, but drawdown rose from `1.06%` to `1.3%`, PF fell from `1.85` to `1.78`, and recovery fell from `11.4559` to `10.3976`. It also added one trade despite frozen base-lot eligibility. The center therefore fails the efficiency, risk, and trade-count gates.

The best headline row was `mbr_center_buy020` at `+$1,524.39`, but no lower rung passed the full frozen gate. Selecting it after observing the ladder would trade a stable neighborhood for higher drawdown, so newer data and Model 4 remain closed.

An earlier direction-specific prototype produced zero trades because its static preflight metadata used the source default adaptive risk instead of the exact leader profile value. That run is classified as an invalid configuration, excluded from strategy evidence, and not published as a strategy result.

The provisional strong-signal selective reversion lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.
