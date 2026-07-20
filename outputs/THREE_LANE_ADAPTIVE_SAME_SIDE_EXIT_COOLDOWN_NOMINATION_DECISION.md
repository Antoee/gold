# Adaptive Same-Side Exit Cooldown Nomination Decision

**Decision: REJECTED IN LEDGER VALIDATION. No EA code, MT5 run, new best, forward change, or live approval is permitted.**

- Training window: `2015-2018`; validation window: `2019-2020`.
- Frozen center: `72 hours`; fixed sensitivity rows: `48`, `96`, and `120 hours`.
- The analyzer used only symbol, lane, side, exit time, elapsed time, and the current adaptive trade outcome for retrospective scoring. The proposed executable rule cannot read prior outcomes.
- Validation CSV SHA-256: `0575BF70D820B290ADFD6B289450791559E60D2A840E48FE926D783468A26FB6`
- Validation Markdown SHA-256: `FCFDAE46C3EA783C2550EF05DC577354C416AB237048EA43C05BEA88CCEF15AF`

| Cooldown | Role | Affected trades | Affected net | PF | Portfolio control | Offline projection | Gate |
|---:|---|---:|---:|---:|---:|---:|---|
| 48h | fixed_sensitivity | 0 | $0.00 | 0 | +$291.76 | +$291.76 | False |
| 72h | frozen_center | 1 | +$2.01 | 0 | +$291.76 | +$289.75 | False |
| 96h | fixed_sensitivity | 1 | +$2.01 | 0 | +$291.76 | +$289.75 | False |
| 120h | fixed_sensitivity | 1 | +$2.01 | 0 | +$291.76 | +$289.75 | False |

## Frozen Gate

- Center pass: `False`
- Passing sensitivity rows: `0/3`; required: `2/3`

The adaptive re-entry clue did not transfer with enough event count, loss removal, or fixed-neighbor support. The family is closed without strategy code or tester time.

The verified momentum same-side exit-cooldown leader and frozen forward candidate remain unchanged. The invalid `$100,000` demo is zero forward evidence, and real-account trading remains disabled.
