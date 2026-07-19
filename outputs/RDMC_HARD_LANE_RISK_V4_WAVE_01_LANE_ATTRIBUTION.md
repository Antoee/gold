# RDMC Hard Lane Risk v4 Wave 1 Lane Attribution

**Terminal result: rejected. The hard cap fixed the known 2022 sizing leak and produced one passing year, but 2019 remained below the frozen PF floor.**

| Window | Lane | Trades | Net | Maximum initial risk | Outcome |
|---|---|---:|---:|---:|---|
| 2019 | MTSM | 24 | -$3.11 | 0.0995% | Losing |
| 2019 | DDB | 1 | +$6.26 | 0.1784% | Profitable |
| 2019 | RRO | 0 | $0.00 | - | Inactive |
| 2019 | Primary | 0 | $0.00 | - | Inactive |
| 2022 | MTSM | 25 | -$48.12 | 0.0996% | Losing |
| 2022 | RRO | 2 | +$87.90 | 0.3087% | Profitable |
| 2022 | DDB | 0 | $0.00 | - | Inactive |
| 2022 | Primary | 0 | $0.00 | - | Inactive |

The 2022 portfolio improved from v3's `+$6.24`, PF `1.0389`, and `1.07%` drawdown to `+$39.78`, PF `1.3157`, and `0.73%` drawdown. All 52 reconstructed entries passed the hard lane-risk audit with no overlapping positions and no minimum-lot overflow.

The unchanged 2019 sequence returned `+$3.15`, but exact PF remained `1.0386` against the preregistered `1.05` floor. The threshold is not relaxed and later waves remain closed. The exact v4 source, profile, manifest, and binary are terminally rejected and may not be rerun or tuned.
