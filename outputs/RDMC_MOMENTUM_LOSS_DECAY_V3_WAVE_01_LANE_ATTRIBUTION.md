# RDMC Momentum Loss Decay v3 Wave 1 Lane Attribution

**Terminal result: rejected. The 24-hour decay repaired the minimum-lot activity deadlock, but both frozen years remained below the `1.05` profit-factor floor.**

| Window | Lane | Trades | Net | Outcome |
|---|---|---:|---:|---|
| 2019 | MTSM | 24 | -$3.11 | Losing |
| 2019 | DDB | 1 | +$6.26 | Profitable |
| 2019 | RRO | 0 | $0.00 | Inactive |
| 2019 | Primary | 0 | $0.00 | Inactive |
| 2022 | MTSM | 25 | -$81.66 | Losing |
| 2022 | RRO | 2 | +$87.90 | Profitable |
| 2022 | DDB | 0 | $0.00 | Inactive |
| 2022 | Primary | 0 | $0.00 | Inactive |

Activity recovered from v2's 3/6 total trades to 25/27. Portfolio net became positive at `+$3.15 / +$6.24`, but exact PF was only `1.0386 / 1.0389`, so both rows failed without threshold relaxation.

The trade ledger exposed a separate safety defect: shared dynamic boosts were applied before the momentum lane multiplier, allowing requested `0.10%` momentum risk to reach roughly `0.27%` on several 2022 entries. The exact v3 identity is terminally rejected and cannot be tuned or rerun. Its successor must enforce broker-valued hard risk caps after every multiplier.
