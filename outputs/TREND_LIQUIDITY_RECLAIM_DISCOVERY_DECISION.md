# Trend-Liquidity Reclaim Discovery Decision

Decision date: 2026-07-17

**Verdict: rejected during the frozen pre-2021 Model 1 screen. No post-2020 holdout or Model 4 configuration was opened, no new best was promoted, and the registered candidate remains unchanged.**

## Evidence Boundary

- Source SHA-256: `67167ACC0BFEA04357EE17195C30320342DEE0D566F2C94E01CC1BF521F26002`
- Binary SHA-256: `4C994BED00F214361978D7585B4813FE22DCD0AEA4646235D049F91DBEC8226B`
- Compile: `0 errors, 0 warnings`
- Identity-valid reports: `28 / 28`
- Profiles: `7`
- Latest data: `2020-12-31`
- Post-2020 runs: `0`
- Model 4 runs: `0`
- Real-account trading: disabled

Three initial portable rows hit source-identity startup races. Only those exact frozen ranks were rerun; all passed, leaving one canonical identity-valid result per rank.

## Results

| Profile | Role | Lookback | Body | Quarantine | 2015-2018 / PF | 2019 / PF | 2020 / PF | Continuous / PF | Trades | DD | Return/DD | Failed gates |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `tlr_q07` | quarantine_neighbor | `12` | `20%` | `7d` | `-$144.44 / 0.38` | `+$21.78 / 1.31` | `+$88.04 / 2.16` | `-$31.32 / 0.92` | `69` | `1.78%` | `-0.18` | `older-net;older-pf;continuous-net;continuous-pf;payoff;return-dd` |
| `tlr_lookback08` | structural_neighbor | `8` | `20%` | `14d` | `-$83.04 / 0.60` | `+$21.29 / 1.30` | `-$2.39 / 0.97` | `-$64.14 / 0.82` | `67` | `1.33%` | `-0.48` | `older-net;older-pf;2020-net;2020-pf;continuous-net;continuous-pf;payoff;return-dd` |
| `tlr_q21` | quarantine_neighbor | `12` | `20%` | `21d` | `-$121.28 / 0.36` | `+$49.83 / 2.17` | `+$5.83 / 1.10` | `-$65.62 / 0.77` | `54` | `1.56%` | `-0.42` | `older-net;older-pf;continuous-net;continuous-pf;payoff;trades;return-dd` |
| `tlr_control_q0` | control | `12` | `20%` | `0d` | `-$171.96 / 0.38` | `+$11.88 / 1.15` | `+$70.76 / 1.75` | `-$85.36 / 0.81` | `79` | `1.89%` | `-0.45` | `older-net;older-pf;continuous-net;continuous-pf;payoff;return-dd` |
| `tlr_center_q14` | center | `12` | `20%` | `14d` | `-$118.75 / 0.42` | `+$31.16 / 1.51` | `-$3.09 / 0.95` | `-$90.68 / 0.73` | `61` | `1.60%` | `-0.57` | `older-net;older-pf;2020-net;2020-pf;continuous-net;continuous-pf;payoff;return-dd` |
| `tlr_lookback20` | structural_neighbor | `20` | `20%` | `14d` | `-$125.25 / 0.23` | `+$39.04 / 1.74` | `-$32.10 / 0.45` | `-$118.31 / 0.57` | `50` | `1.35%` | `-0.88` | `older-net;older-pf;2020-net;2020-pf;continuous-net;continuous-pf;payoff;trades;return-dd` |
| `tlr_body30` | structural_neighbor | `12` | `30%` | `14d` | `-$98.71 / 0.35` | `-$39.39 / 0.36` | `+$12.25 / 1.23` | `-$122.55 / 0.53` | `47` | `1.57%` | `-0.78` | `older-net;older-pf;2019-net;2019-pf;continuous-net;continuous-pf;payoff;trades;return-dd` |

## Interpretation

The no-quarantine control lost `-$85.36` at PF `0.81`. The 14-day center lost `-$90.68` at PF `0.73`. The least-bad 7-day neighbor still lost `-$31.32` at PF `0.92`.

Every row lost in 2015-2018 and continuously. Quarantine reduced some losses but did not create an edge, while body and lookback neighbors failed as well. The earlier high-PF session result therefore does not survive extraction into this clean date-independent mechanism; importing the old monolithic strategy would not be justified by transferable evidence.

## Decision

- Reject this trend-liquidity reclaim family without tuning it on recent data.
- Skip holdout, Model 4, annual, cost, and Monte Carlo testing for this branch.
- Do not merge the old session engine into RC2 based on its historical headline.
- Preserve the forward identity, account contract, evidence logs, and hard real-account lock.

## Evidence

- `outputs/TREND_LIQUIDITY_RECLAIM_DISCOVERY_CONTRACT.md`
- `outputs/TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_RUN.csv`
- `outputs/TREND_LIQUIDITY_RECLAIM_DISCOVERY_DECISION.csv`
