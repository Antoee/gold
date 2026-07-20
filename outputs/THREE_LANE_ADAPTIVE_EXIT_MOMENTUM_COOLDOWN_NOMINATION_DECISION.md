# Adaptive-Exit to Momentum Same-Side Cooldown Nomination Decision

**Decision: REJECTED IN LEDGER VALIDATION. No EA code, MT5 run, new best, forward change, or live approval is permitted.**

- Training window: `2015-2018`; validation window: `2019-2020`.
- Frozen center: `36 hours`; fixed sensitivity rows: `24`, `48`, and `72 hours`.
- The analyzer used only symbol, lane, side, exit time, elapsed time, and the current momentum trade outcome for retrospective scoring. The proposed executable rule cannot read prior outcomes.
- Validation CSV SHA-256: `54E3BCED8337C49D386B35526AFC091995CB1ED360A508A50EB1B9241B2321DA`
- Validation Markdown SHA-256: `F57AFB55BE70BC03663B04A522905BC2FA4D2856FDBC83D75AE6AB24C0B47D14`

| Cooldown | Role | Affected trades | Affected net | PF | Portfolio control | Offline projection | Gate |
|---:|---|---:|---:|---:|---:|---:|---|
| 24h | fixed_sensitivity | 1 | -$9.46 | 0 | +$291.76 | +$301.22 | True |
| 36h | frozen_center | 1 | -$9.46 | 0 | +$291.76 | +$301.22 | False |
| 48h | fixed_sensitivity | 3 | -$23.85 | 0.0437 | +$291.76 | +$315.61 | True |
| 72h | fixed_sensitivity | 4 | +$2.49 | 1.0998 | +$291.76 | +$289.27 | False |

## Frozen Gate

- Center pass: `False`
- Passing sensitivity rows: `2/3`; required: `2/3`

The cross-lane exhaustion clue did not transfer with enough event count, loss removal, or fixed-neighbor support. The family is closed without strategy code or tester time.

The verified same-side exit-cooldown leader and frozen forward candidate remain unchanged. The invalid `$100,000` demo is zero forward evidence, and real-account trading remains disabled.
