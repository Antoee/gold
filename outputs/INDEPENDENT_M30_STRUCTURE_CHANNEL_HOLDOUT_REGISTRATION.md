# Independent M30 Structure-Channel Holdout Registration

Frozen before any 2021-2026 result was generated for this strategy family. This is a strategy-specific holdout, not globally unseen market data for the project.

- Source SHA-256: `4A524A8C6565B669FE9D68E84B4EE9B8C2AEAB49E0A7173FE6750A930B4594BB`
- Holdout end: `2026-07-12`
- Candidates: `4`
- Configurations: `36`

| Candidate | Frozen profile SHA-256 | Discovery net | PF | Trades | DD |
|---|---|---:|---:|---:|---:|
| `m30sc_72_36_tp20` | `7578B6ED37A0ADCD48BACA4ADE8263202662141E8C799D1480B2133024B13B78` | `+547.52` | `1.49` | `239` | `2.34%` |
| `m30sc_48_24_channel` | `F100A61CCD03E9F01BD4A195C2A0DAD04B6B5607CA8E67F65C3C7A2BFB7788F0` | `+379.99` | `1.29` | `289` | `2.62%` |
| `m30sc_48_24_tp25` | `D1B23375C7A9C9E8DCF771B584289830279F2F5E0A975671DE8DB5ACE39188D7` | `+374.64` | `1.28` | `291` | `2.62%` |
| `m30sc_48_24_stop5` | `5460333BA4FB630AC7383BF716866E89446D9F0794596153EDA0A0597EEE4470` | `+306.61` | `1.32` | `226` | `1.69%` |

Frozen holdout: require both broad holdout eras positive, continuous PF at least 1.20, at least 150 trades, DD at or below 5%, no completed year below -1.50%, and no more than two red completed years before Model4.

No threshold or profile may be changed after holdout inspection. A failure rejects this frozen family rather than starting another holdout-tuned sweep.
