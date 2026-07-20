# Adaptive Same-Side Exit Cooldown Ledger Screen

- Window: `2015-2018`
- Exact leader ledger SHA-256: `6D880F634BD792281DAB72C5ACC6BF9F2C617888184881BD9AFA2D84DCEFAC40`
- Rule screened: suppress an adaptive-lane entry when the most recent adaptive-lane exit on the same symbol and side occurred within the fixed elapsed-time threshold.
- The screen never reads the prior trade outcome. Offline projected profit is nomination evidence only; executable MT5 behavior can differ because sizing, equity, and exposure paths change.

| Cooldown | Affected trades | Affected net | PF | Portfolio control | Offline projection | Improvement |
|---:|---:|---:|---:|---:|---:|---:|
| 48h | 3 | -$24.19 | 0 | +$999.09 | +$1023.28 | +$24.19 |
| 72h | 4 | -$26.57 | 0 | +$999.09 | +$1025.66 | +$26.57 |
| 96h | 4 | -$26.57 | 0 | +$999.09 | +$1025.66 | +$26.57 |
| 120h | 4 | -$26.57 | 0 | +$999.09 | +$1025.66 | +$26.57 |
