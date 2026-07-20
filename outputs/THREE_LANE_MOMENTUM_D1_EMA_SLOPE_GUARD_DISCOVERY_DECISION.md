# Momentum D1 EMA-Slope Guard Discovery Decision

**Decision: REJECTED IN MODEL 1 NEIGHBORHOOD. No strategy Model 4 run, promotion, forward substitution, or live approval is permitted.**

- Manifest SHA-256: `576A33A2517FAD0E45FEB8F488EC3BC89AC5FC346BEF8CBE9A710C2A4C9F1597`
- Results SHA-256: `17EC6E1E73807B9DA8C7FD6F6F2F63B52B6BFDB5FB334DA768CB7EB255DEE293`
- Reports parsed: `20 / 20`
- Center complete gate: `True`
- Passing neighbors: `0 / 2`

| Candidate | Role | Full net | Delta | PF | Trades | DD | CAGR | 2015-18 | 2019-20 | 2021-23 | 2024-26 | Gate |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `mdes_control` | default_off_control | +$2,660.57 | +$0.00 | 1.98 | 411 | 1.15% | 2.07% | +$1,036.19 | +$370.60 | +$629.61 | +$434.36 | CONTROL |
| `mdes_low075` | lower_neighbor | +$2,612.36 | -$48.21 | 2.63 | 252 | 1.11% | 2.03% | +$885.38 | +$242.67 | +$871.83 | +$341.60 | FAIL |
| `mdes_center100` | center | +$2,746.31 | +$85.74 | 2.61 | 271 | 1.1% | 2.13% | +$955.07 | +$311.57 | +$843.91 | +$360.37 | PASS |
| `mdes_high125` | upper_neighbor | +$2,629.03 | -$31.54 | 2.4 | 292 | 1.11% | 2.05% | +$911.53 | +$327.71 | +$773.22 | +$370.61 | FAIL |

## Why It Stopped

The `1.00 ATR` center improved continuous profit, PF, drawdown, recovery, and return/drawdown while every broad era remained profitable. The neighborhood did not confirm the profit improvement: both `0.75 ATR` and `1.25 ATR` finished below the default-off control. That isolated peak is treated as overfit risk, so the family stops before strategy Model 4 confirmation.

The published historical leader and registered forward identity remain unchanged. The attached demo account still violates the frozen $10,000 contract, and real-account trading remains locked.
