# Independent D1 NR7 / H1 Breakout Decision

Decision date: 2026-07-20

**Verdict: rejected during frozen Model 1 discovery. No 2021-2026 holdout was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Test Contract

- Source: `work/Independent_XAUUSD_D1_NR7_H1_Breakout.mq5`
- Source SHA-256: `BBFC4214F63658B7D2D22109AC0C536D32A23693C471179DB0E07EA70C974880`
- Compiled binary SHA-256: `CC80BEE04EAC8B2669A1BBF44C79C57500C2BC6CF5EA8A9196ECA11778AA7D72`
- Compile: `0 errors, 0 warnings` across four isolated workers
- Discovery data only: 2015-01-01 through 2020-12-31
- Identity-valid reports parsed: `54 / 54`
- Candidate variants: `18`
- Risk per trade: `0.10%`
- 2021-2026 holdout configurations run: `0`
- Model 4 configurations run: `0`

Four initial portable rows hit report-identity export errors. Only those exact frozen queue ranks were rerun; all four passed without changing source or settings, and the canonical evidence contains one identity-valid result per rank.

## Discovery Evidence

The frozen gate required both disjoint eras to be profitable, continuous PF at least 1.25, at least 80 trades, DD no greater than 3.00%, recovery at least 1.50, and support from at least three one-factor variants. No variant passed the base gate.

| Candidate | 2015-2018 | PF | 2019-2020 | PF | Continuous | PF | Trades | DD | Recovery | CAGR | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `dnrb_noema` | `+$25.09` | `2.10` | `-$14.75` | `0.00` | `+$10.34` | `1.28` | `14` | `0.35%` | `0.29` | `0.02%` | rejected |
| `dnrb_nr10` | `+$6.24` | `1.90` | `+$0.00` | `0.00` | `+$6.24` | `1.90` | `5` | `0.21%` | `0.30` | `0.01%` | rejected |
| `dnrb_maxatr070` | `+$1.62` | `1.14` | `-$8.50` | `0.00` | `-$6.88` | `0.66` | `7` | `0.26%` | `-0.27` | `-0.01%` | rejected |
| `dnrb_ema100` | `-$0.20` | `0.99` | `-$11.02` | `0.00` | `-$11.22` | `0.63` | `11` | `0.34%` | `-0.33` | `-0.02%` | rejected |
| `dnrb_tp200` | `-$0.72` | `0.96` | `-$11.02` | `0.00` | `-$11.74` | `0.61` | `10` | `0.34%` | `-0.35` | `-0.02%` | rejected |
| `dnrb_nr5` | `-$6.28` | `0.68` | `-$7.06` | `0.36` | `-$13.34` | `0.56` | `11` | `0.34%` | `-0.40` | `-0.02%` | rejected |
| `dnrb_ema20` | `-$2.65` | `0.82` | `-$11.02` | `0.00` | `-$13.67` | `0.47` | `8` | `0.30%` | `-0.46` | `-0.02%` | rejected |
| `dnrb_buffer000` | `-$4.78` | `0.75` | `-$10.68` | `0.00` | `-$15.46` | `0.49` | `10` | `0.32%` | `-0.48` | `-0.03%` | rejected |
| `dnrb_volume115` | `-$4.46` | `0.75` | `-$11.02` | `0.00` | `-$15.48` | `0.46` | `9` | `0.25%` | `-0.61` | `-0.03%` | rejected |
| `dnrb_no_trail` | `-$14.13` | `0.66` | `-$1.46` | `0.91` | `-$15.59` | `0.73` | `10` | `0.60%` | `-0.26` | `-0.03%` | rejected |
| `dnrb_body025` | `-$5.30` | `0.73` | `-$11.02` | `0.00` | `-$16.32` | `0.46` | `11` | `0.33%` | `-0.50` | `-0.03%` | rejected |
| `dnrb_adx18` | `-$6.28` | `0.68` | `-$11.02` | `0.00` | `-$17.30` | `0.43` | `10` | `0.34%` | `-0.52` | `-0.03%` | rejected |
| `dnrb_tp400` | `-$6.28` | `0.68` | `-$11.02` | `0.00` | `-$17.30` | `0.43` | `10` | `0.34%` | `-0.52` | `-0.03%` | rejected |
| `dnrb_maxatr100` | `-$6.28` | `0.68` | `-$11.02` | `0.00` | `-$17.30` | `0.43` | `10` | `0.34%` | `-0.52` | `-0.03%` | rejected |
| `dnrb_center` | `-$6.28` | `0.68` | `-$11.02` | `0.00` | `-$17.30` | `0.43` | `10` | `0.34%` | `-0.52` | `-0.03%` | rejected |
| `dnrb_buffer010` | `-$13.14` | `0.50` | `-$11.02` | `0.00` | `-$24.16` | `0.35` | `11` | `0.40%` | `-0.60` | `-0.04%` | rejected |
| `dnrb_body045` | `-$13.77` | `0.07` | `-$11.02` | `0.00` | `-$24.79` | `0.04` | `8` | `0.37%` | `-0.67` | `-0.04%` | rejected |
| `dnrb_volume000` | `-$16.29` | `0.45` | `-$11.02` | `0.00` | `-$27.31` | `0.33` | `14` | `0.45%` | `-0.61` | `-0.05%` | rejected |

The center lost `-$17.30` at PF `0.43` with only `10` trades. The highest continuous result, `dnrb_noema`, made only `+$10.34` over six years with `14` trades and lost the 2019-2020 era. The completed-D1 narrow-range / fresh-H1 breakout hypothesis therefore lacks both repeatability and sufficient sample size.

## Decision

- Reject this NR7 / H1 breakout neighborhood; do not tune it on recent data.
- Skip holdout and Model 4 because the broad pre-2021 gate failed.
- Do not merge the engine into the frozen forward candidate.
- Preserve the registered source/profile/binary identity, evidence logs, and hard real-account lock unchanged.

## Evidence

- `outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_PACKAGE.md`
- `outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RUN.csv`
- `outputs/INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_DECISION.csv`
