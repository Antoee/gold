# Reversion D1 Momentum-Cap Discovery Decision

**Decision: DISCOVERY PASS. The exact 12% center may enter post-2020 Model 1 holdout; no promotion or forward-candidate change is authorized.**

- Exact source: `8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B`
- Exact contract: `0D1199E9BBDF4A9E02AE10359F912976246168FDA53A1917768BCADDD535AA67`
- Reports parsed: `35 / 35`; two exact identity-failed ranks were retried
- Latest discovery data: `2020-12-31`
- Holdout-eligible profiles: `1`

| Profile | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | Continuous / PF | Trades | DD | Annual | Quality | Parent | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---|
| `rdmc_released_control` | $+154.88 | $+213.83 | $+150.44 | $+244.89 | $-4.98 | $-100.47 | $+694.13 / 1.42 | 225 | 2.77% | False | False | True | False | CONTROL_ONLY |
| `rdmc_di10_parent` | $+85.54 | $+161.03 | $+173.84 | $+227.15 | $-4.98 | $+66.30 | $+719.25 / 1.51 | 216 | 1.49% | False | True | True | False | PARENT_ONLY |
| `rdmc_di10_cap10` | $+85.54 | $+161.03 | $+173.84 | $+154.95 | $+47.22 | $+169.66 | $+787.15 / 1.61 | 211 | 1.09% | True | True | True | False | SUPPORTS_CENTER |
| `rdmc_di10_cap12_center` | $+85.54 | $+161.03 | $+173.84 | $+227.15 | $+47.22 | $+169.66 | $+875.84 / 1.68 | 212 | 1.09% | True | True | True | True | OPEN_HOLDOUT |
| `rdmc_di10_cap14` | $+85.54 | $+161.03 | $+173.84 | $+227.15 | $+47.22 | $+169.66 | $+875.84 / 1.68 | 212 | 1.09% | True | True | True | False | SUPPORTS_CENTER |

## Interpretation

The `12%` center and both fixed neighbors made money in every independently restarted discovery year. The center changed 2019 from `-$4.98` to `+$47.22` and 2020 from `+$66.30` to `+$169.66`.

Continuous 2015-2020 improved from the DI parent's `+$719.25`, PF `1.51`, and `1.49%` drawdown to `+$875.84`, PF `1.68`, and `1.09%` drawdown. The `14%` neighbor exactly reproduced the center, while the stricter `10%` neighbor also passed at `+$787.15`, PF `1.61`, and `1.09%` drawdown.

Only the exact center profile hash may enter the two frozen post-2020 holdouts. Discovery success is not a historical-best promotion, forward evidence, or real-money approval.
