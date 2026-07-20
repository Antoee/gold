# Adaptive-Exit to Momentum Same-Side Cooldown Ledger Screen

- Window: `2015-2018`
- Exact leader ledger SHA-256: `6D880F634BD792281DAB72C5ACC6BF9F2C617888184881BD9AFA2D84DCEFAC40`
- Rule screened: suppress a momentum entry when the most recent adaptive-lane exit on the same symbol and side occurred within the fixed elapsed-time threshold.
- The screen never reads the prior trade outcome. Offline projected profit is nomination evidence only; executable MT5 behavior can differ because sizing, equity, and exposure paths change.

| Cooldown | Affected trades | Affected net | PF | Portfolio control | Offline projection | Improvement |
|---:|---:|---:|---:|---:|---:|---:|
| 24h | 4 | -$24.53 | 0 | +$999.09 | +$1023.62 | +$24.53 |
| 36h | 4 | -$24.53 | 0 | +$999.09 | +$1023.62 | +$24.53 |
| 48h | 7 | -$2.58 | 0.9312 | +$999.09 | +$1001.67 | +$2.58 |
| 72h | 9 | -$18.50 | 0.6538 | +$999.09 | +$1017.59 | +$18.50 |
