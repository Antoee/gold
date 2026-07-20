# Three-Lane Momentum Buy Payoff Discovery Decision

**Decision: REJECTED IN DISCOVERY. No recent confirmation, Model 4, promotion, forward change, or live approval is permitted.**

- Exact accepted reports: `15/15`; unchanged identity retry refusals preserved: `1`
- Source SHA-256: `52A2C2942931518EB28A8CB1BF1DD72D9C4BF07E6AC18F3C577D4971153A3923`
- EX5 SHA-256: `404C177BD968BFBE5EEC6B875DD324DD037F93F19622ED874490D353250F63B5`
- Manifest SHA-256: `3BD672846E507BE7A31C044FF583F1C2643FC83814D861C84348F0BE5A95C47B`
- `$10,000`; MT5 Model 1; 2015-2020 discovery; momentum risk `0.15%`; sell target `2.0R`; portfolio cap `0.75%`; real trading disabled
- Only the initial target of existing momentum buys changed; architecture was selected from the full leader ledger

| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 | CONTROL |
| Buy 2.25R | +$1,034.03 | +$405.45 | +$1,406.57 | 14.07% | 2.22%/yr | 1.89 | 262 | 1.15% | 10.9367 | 12.2348 | False |
| **Buy 2.50R center** | +$1,061.03 | +$396.16 | +$1,412.34 | 14.12% | 2.23%/yr | 1.9 | 261 | 1.1% | 11.4927 | 12.8364 | False |
| Buy 2.75R | +$1,031.98 | +$410.27 | +$1,397.89 | 13.98% | 2.21%/yr | 1.9 | 261 | 1.19% | 10.5168 | 11.7479 | False |
| Buy 3R | +$1,052.40 | +$449.14 | +$1,449.25 | 14.49% | 2.28%/yr | 1.92 | 261 | 1.16% | 11.0833 | 12.4914 | False |

## Frozen Gate

- Every disjoint era profitable: `True`
- Center retains 98% of both era controls: `True`
- Center continuous net at least 3% above control: `True`
- Center CAGR at least 0.05 point above control: `True`
- Center PF/recovery/return-DD no worse than control: `True`
- Center drawdown no more than 1.14%: `True`
- Center retains at least control minus two trades: `False`
- Non-center enabled neighbors passing: `0/3`; required: `2/3`

## Interpretation

The center increased continuous net by `+$58.60`, improved PF from `1.85` to `1.9`, improved recovery from `11.4559` to `11.4927`, and raised drawdown only from `1.06%` to `1.1%`. It produced `261` trades versus the frozen minimum of `263`, so the center fails only the preregistered trade-retention gate.

The best headline row was `mbp_buy300` at `+$1,449.25`, but no non-center neighbor passed the complete frozen support gate. The 2.50R center is a useful near-miss, not permission to relax the gate after observation, so newer data and Model 4 remain closed.

The provisional strong-signal selective reversion lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.
