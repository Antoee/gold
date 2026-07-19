# RDMC Lane Isolation Rewrite v2 Wave 1 Lane Attribution

**Terminal result: rejected. The ownership repair is structurally valid, but the restored MTSM signal remained unprofitable and its lane-local loss sizing created a minimum-lot activity deadlock.**

| Window | Lane | Trades | Net | Outcome |
|---|---|---:|---:|---|
| 2019 | MTSM | 2 | -$8.96 | Losing |
| 2019 | DDB | 1 | +$4.91 | Profitable |
| 2019 | RRO | 0 | $0.00 | Inactive |
| 2019 | Primary | 0 | $0.00 | Inactive |
| 2022 | MTSM | 4 | -$17.37 | Losing |
| 2022 | RRO | 2 | -$0.90 | Losing |
| 2022 | DDB | 0 | $0.00 | Inactive |
| 2022 | Primary | 0 | $0.00 | Inactive |

The v2 source correctly removes RRO/DDB exits from primary soft-loss state and excludes isolated positions from shared basket management. Those changes do not weaken portfolio hard limits. They also do not repair the critical-year economics: both years lost money at PF `0.55` and activity fell to 3/6 total trades.

The exact trade sequence exposes the next architecture defect. MTSM starts at `0.10%` risk, but the existing lane-local `0.5^n` loss-size reduction remains in force until a winning MTSM exit resets the streak. After two losses, its requested risk can fall below XAUUSD's broker-minimum 0.01-lot risk. No new trade can then produce the winner required to reset the streak. The next identity must make this soft reduction expire after its configured cooldown while preserving all account-wide hard limits and the `0.10%` base cap.
