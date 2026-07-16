# Independent H4 Channel-Trend Holdout Registration

Frozen before any 2021-2026 result was generated for this strategy family. This is a strategy-specific holdout, not globally unseen market data for the project.

- Source SHA-256: `C27025A3605EEBBA54C5B88D564CE641D00634E2C42C8BAC6D127751ABF58F4A`
- Holdout end: `2026-07-12`
- Candidates: `4`
- Configurations: `36`

| Candidate | Frozen profile SHA-256 | Discovery net | PF | Trades | DD |
|---|---|---:|---:|---:|---:|
| `h4ct_trail_40_20_l20_a25` | `74B5A7AE5797A79F59FEF3DE2453126648125E2834A197BCD5513E0AD2F57FC9` | `+268.97` | `1.73` | `101` | `0.89%` |
| `h4ct_trail_55_20_l20_a25` | `7240A41A5F1D7B7564CFE4D0467E6D198C1819AE520794E956C612707A7E070D` | `+264.96` | `1.94` | `81` | `0.7%` |
| `h4ct_trail_55_20_l20_a30` | `AE842CF1D058CB85D457B220D7EEBF4AC23CEA95776F1062D17CAFBB68C01B2E` | `+328.77` | `2.12` | `76` | `0.76%` |
| `h4ct_trail_80_40_l20_a30` | `C314A3A952BA2F867F0922B5EFECD3AE9B0EE2162B69E3686A4890D9F856468A` | `+314.57` | `2.54` | `61` | `0.62%` |

Frozen holdout: require both broad holdout eras positive, continuous PF at least 1.20, at least 40 trades, DD at or below 3%, no completed year below -0.50%, and no more than two red completed years before Model4.

No threshold or profile may be changed after holdout inspection. A failure rejects this frozen family rather than starting another holdout-tuned sweep.
