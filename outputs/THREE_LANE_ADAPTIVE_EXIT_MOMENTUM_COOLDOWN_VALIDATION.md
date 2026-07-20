# Adaptive-Exit to Momentum Same-Side Cooldown Ledger Screen

- Window: `2019-2020`
- Exact leader ledger SHA-256: `6D880F634BD792281DAB72C5ACC6BF9F2C617888184881BD9AFA2D84DCEFAC40`
- Rule screened: suppress a momentum entry when the most recent adaptive-lane exit on the same symbol and side occurred within the fixed elapsed-time threshold.
- The screen never reads the prior trade outcome. Offline projected profit is nomination evidence only; executable MT5 behavior can differ because sizing, equity, and exposure paths change.

| Cooldown | Affected trades | Affected net | PF | Portfolio control | Offline projection | Improvement |
|---:|---:|---:|---:|---:|---:|---:|
| 24h | 1 | -$9.46 | 0 | +$291.76 | +$301.22 | +$9.46 |
| 36h | 1 | -$9.46 | 0 | +$291.76 | +$301.22 | +$9.46 |
| 48h | 3 | -$23.85 | 0.0437 | +$291.76 | +$315.61 | +$23.85 |
| 72h | 4 | +$2.49 | 1.0998 | +$291.76 | +$289.27 | -$2.49 |
