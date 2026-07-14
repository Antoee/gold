# Range-Elite Current-Source Model4 Rejection Note

Date: 2026-07-14

The older `range_elite_micro` profile was rerun against the current EA source using exported MT5 Model4 yearly reports. This was important because the historical notes showed much larger profit, but those numbers came from older source/tooling and needed current-source real-tick proof.

Result: keep as a research lead, reject as trade-ready.

Evidence:

- Full MT5 reports parsed: `8 / 8`
- Log fallback rows: `0`
- Source hash: `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`
- Profile hash: `3690755F9F97B3556222E8FACA784294A6BADF41BEDCAB5CC5CEB4EE7B12F836`
- Metrics file: `outputs/RANGE_ELITE_MODEL4_YEARLY_METRICS.md`
- Decision file: `outputs/RANGE_ELITE_MODEL4_CURRENT_SOURCE_DECISION.md`

Current-source Model4 result:

| Window | Net | Annualized Return | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: |
| 2019 | `-$83.32` | `-8.36%/yr` | `3` | `11.33%` |
| 2020 | `+$88.75` | `+8.88%/yr` | `2` | `13.26%` |
| 2021 | `-$62.11` | `-6.23%/yr` | `2` | `20.85%` |
| 2022 | `+$9.59` | `+0.96%/yr` | `2` | `23.77%` |
| 2023 | `-$131.33` | `-13.18%/yr` | `17` | `18.02%` |
| 2024 | `+$2,174.47` | `+217.60%/yr` | `21` | `24.25%` |
| 2025 | `+$214.30` | `+21.50%/yr` | `3` | `11.97%` |
| 2026 YTD | `+$742.92` | `+141.33%/yr` | `11` | `27.87%` |

The profile has a stronger profit engine than the current stability lead, but the risk is not acceptable for a trade-ready label. The key failures are three red yearly windows, a nearly flat 2022, concentration in 2024, and 2026 YTD drawdown near `28%`.

Do not promote this by raising risk, disabling losing years, or treating aggregate profit as proof. The next test should be a failure-specific regime filter or entry-quality filter aimed at 2019/2021/2023 and high-drawdown 2026 behavior.
