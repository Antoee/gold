# Reversion Retracement-Entry Discovery Decision

**Decision: rejected in frozen pre-2021 discovery. No recent holdout, Model 4, promotion, forward change, or live approval is permitted.**

- Exact source SHA-256: `76F0E1B6E7841BAB5B2BCA9D273AE04AD88047F1E90539E3052C0134A0A9A4C8`
- Exact four-worker EX5 SHA-256: `FA97956179F5BBDC6CC1EA7B9A38BFFC9D621003FE9AE8EF887015D2DD19A2B3`
- Frozen manifest SHA-256: `FE174004374EDE1F8C812A475F609828D10BBEE5875AAF6AE14679B5CCBD7CA1`
- Reports: `15 / 15` parsed and identity-valid after two preserved startup identity refusals and one unchanged single-worker recovery.
- Data: `$10,000`, XAUUSD M15, Model 1, 2015-2020 only.
- Disabled control exact reproduction: `True`; enabled-center RRE fills: `13`.

| Profile | Offset | Life | 2015-18 | 2019-20 | Continuous | Change | CAGR | PF | Trades | DD | Recovery | RRE fills | RRE net | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `rre_control` | `0 ATR` | `1` | `+$1,036.19` | `+$370.60` | `+$1,379.93` | `0%` | `2.18%` | `1.88` | `261` | `1.05%` | `11.6775` | `0` | `+$0.00` | `True` |
| `rre_offset10` | `0.1 ATR` | `1` | `+$880.49` | `+$376.99` | `+$1,250.30` | `-9.39%` | `1.98%` | `1.85` | `258` | `1.02%` | `11.098` | `16` | `+$403.21` | `False` |
| `rre_center15` | `0.15 ATR` | `1` | `+$682.44` | `+$384.19` | `+$1,067.56` | `-22.64%` | `1.71%` | `1.75` | `252` | `1.04%` | `9.4759` | `13` | `+$284.35` | `False` |
| `rre_offset20` | `0.2 ATR` | `1` | `+$708.94` | `+$384.13` | `+$1,083.00` | `-21.52%` | `1.73%` | `1.77` | `254` | `1.04%` | `9.613` | `13` | `+$314.12` | `False` |
| `rre_center15_bars2` | `0.15 ATR` | `2` | `+$646.94` | `+$384.19` | `+$1,032.06` | `-25.21%` | `1.65%` | `1.71` | `253` | `1.04%` | `9.1608` | `14` | `+$246.65` | `True` |

## Interpretation

The mechanism was active and behaved as intended, but waiting for a retracement missed too many high-value older-era entries. The least-damaging enabled row, `0.10 ATR`, improved 2019-2020 slightly but reduced continuous net from `+$1,379.93` to `+$1,250.30`. The frozen `0.15 ATR` center fell to `+$1,067.56`, PF `1.75`, and recovery `9.4759`.

The two-bar lifetime retained the center neighborhood but could not repair the underlying loss of older winners. Offsets are not moved closer to zero after observation; that would convert this bounded test into threshold fitting. The family is closed before newer data and real ticks.

- The provisional historical leader remains the 60-minute same-side momentum exit-cooldown profile.
- The registered forward candidate and invalid `$100,000` account boundary remain unchanged.
- Real-account trading remains disabled.
