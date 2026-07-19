# Three-Lane Protected Winner Add-On Discovery Decision

**Decision: DISCOVERY SURVIVOR. A frozen 2021+ holdout is permitted only for `pwa_trigger100`; Model 4, promotion, forward registration, and real trading remain closed.**

- Exact source SHA-256: `F7AAEFF24C4A0FF8066C906A25F99462E1F2488765AD046364B970277AAD5B46`
- Exact portable binary SHA-256: `3334836C955F4F97C5769FF2CF87B7ACB9A9C7BF38ECE70BC692A6149376311D`
- Controlled run: `30 / 30` reports, one worker, zero errors, one binary identity
- Starting deposit: `$10,000`; real-account trading: disabled
- Frozen ATB150 and frozen forward candidate: unchanged

| Profile | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | Add-ons | DD | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `pwa_trigger100` | +$905.85 | +$343.23 | +$1,248.56 | 1.98% | 1.8 | 272 | 9 | 1.02% | 12.2451 | DISCOVERY_ELIGIBLE |
| `pwa_lookback4` | +$871.40 | +$343.23 | +$1,215.44 | 1.93% | 1.79 | 269 | 6 | 1.02% | 11.9118 | DISCOVERY_ELIGIBLE |
| `pwa_lookback8` | +$871.40 | +$343.23 | +$1,215.44 | 1.93% | 1.79 | 269 | 6 | 1.02% | 11.9118 | DISCOVERY_ELIGIBLE |
| `pwa_center` | +$871.40 | +$343.23 | +$1,215.44 | 1.93% | 1.79 | 269 | 6 | 1.02% | 11.9118 | DISCOVERY_ELIGIBLE |
| `pwa_coverage100` | +$871.40 | +$343.23 | +$1,215.44 | 1.93% | 1.79 | 269 | 6 | 1.02% | 11.9118 | DISCOVERY_ELIGIBLE |
| `pwa_coverage150` | +$879.69 | +$330.02 | +$1,209.19 | 1.92% | 1.79 | 267 | 4 | 1.02% | 11.8529 | DISCOVERY_ELIGIBLE |
| `pwa_trigger150` | +$861.40 | +$343.23 | +$1,205.44 | 1.92% | 1.78 | 269 | 5 | 1.02% | 11.8137 | DISCOVERY_ELIGIBLE |
| `pwa_risk060` | +$850.44 | +$343.23 | +$1,194.48 | 1.9% | 1.77 | 270 | 6 | 1.02% | 11.7059 | DISCOVERY_ELIGIBLE |
| `pwa_control` | +$860.86 | +$330.02 | +$1,191.69 | 1.89% | 1.77 | 265 | 0 | 1.02% | 11.6863 | CONTROL_ONLY |
| `pwa_risk025` | +$858.35 | +$330.02 | +$1,189.18 | 1.89% | 1.77 | 266 | 1 | 1.02% | 11.6569 | REJECT_BEFORE_HOLDOUT |

## Interpretation

- Selected discovery profile `pwa_trigger100` improved continuous net by +$56.87 versus the disabled-feature control, with PF `1.8` and DD `1.02%`.
- The result is a small research improvement, not a new best. Only an untouched 2021-2026 holdout can determine whether the gain transfers.
- The add-on is winner-only and requires broker-valued stop-locked profit to cover its full initial risk. It never adds to a loser.
- ATB150 remains the research best until every later gate passes.
