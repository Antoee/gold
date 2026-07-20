# Adaptive Same-Side Exit Cooldown Ledger Screen

- Window: `2019-2020`
- Exact leader ledger SHA-256: `6D880F634BD792281DAB72C5ACC6BF9F2C617888184881BD9AFA2D84DCEFAC40`
- Rule screened: suppress an adaptive-lane entry when the most recent adaptive-lane exit on the same symbol and side occurred within the fixed elapsed-time threshold.
- The screen never reads the prior trade outcome. Offline projected profit is nomination evidence only; executable MT5 behavior can differ because sizing, equity, and exposure paths change.

| Cooldown | Affected trades | Affected net | PF | Portfolio control | Offline projection | Improvement |
|---:|---:|---:|---:|---:|---:|---:|
| 48h | 0 | $0.00 | 0 | +$291.76 | +$291.76 | $0.00 |
| 72h | 1 | +$2.01 | 0 | +$291.76 | +$289.75 | -$2.01 |
| 96h | 1 | +$2.01 | 0 | +$291.76 | +$289.75 | -$2.01 |
| 120h | 1 | +$2.01 | 0 | +$291.76 | +$289.75 | -$2.01 |
