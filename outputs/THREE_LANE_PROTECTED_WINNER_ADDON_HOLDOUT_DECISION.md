# Three-Lane Protected Winner Add-On Holdout Decision

**Decision: REJECTED_IN_HOLDOUT. Model 4, promotion, forward registration, and real trading remain closed.**

- Exact source SHA-256: `F7AAEFF24C4A0FF8066C906A25F99462E1F2488765AD046364B970277AAD5B46`
- Exact binary SHA-256: `3334836C955F4F97C5769FF2CF87B7ACB9A9C7BF38ECE70BC692A6149376311D`
- Controlled run: `8 / 8` reports, one worker, zero errors, one binary identity
- Frozen ATB150 and frozen forward candidate: unchanged

| Profile | Window | Net | CAGR | PF | Trades | Add-ons | DD |
|---|---|---:|---:|---:|---:|---:|---:|
| `pwa_control` | continuous_2021_2026 | +$944.62 | 1.64% | 2.01 | 142 | 0 | 1.23% |
| `pwa_control` | holdout_2021_2022 | +$345.09 | 1.71% | 1.77 | 66 | 0 | 1.15% |
| `pwa_control` | holdout_2023_2024 | +$403.24 | 2% | 1.97 | 70 | 0 | 1.24% |
| `pwa_control` | holdout_2025_2026 | +$226.11 | 1.46% | 25.96 | 5 | 0 | 1.25% |
| `pwa_trigger100` | continuous_2021_2026 | +$929.40 | 1.62% | 1.99 | 142 | 0 | 1.23% |
| `pwa_trigger100` | holdout_2021_2022 | +$345.09 | 1.71% | 1.77 | 66 | 0 | 1.15% |
| `pwa_trigger100` | holdout_2023_2024 | +$392.69 | 1.95% | 1.95 | 70 | 0 | 1.24% |
| `pwa_trigger100` | holdout_2025_2026 | +$226.11 | 1.46% | 25.96 | 5 | 0 | 1.25% |

## Gate

- Every candidate window positive: `True`
- Continuous PF/DD quality: `True`
- Continuous add-on activity: `False`
- Candidate net and return/DD beat control: `False`
- Continuous selected: +$929.40, PF `1.99`, DD `1.23%`; control: +$944.62, PF `2.01`, DD `1.23%`.

- No holdout report contains a completed add-on entry. Results still changed because v1.51 can tighten the primary winner stop before exact coverage validation later refuses the add-on. This safety-biased side effect is another explicit rejection reason.
- The candidate lost `-$15.22` versus control in the feature-level holdout. The discovery improvement did not transfer, so no Model 4 time is justified.
- ATB150 remains the research best.
