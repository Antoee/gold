# Independent M30 Compression-Expansion Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

The standalone EA required a bounded M30 compression box and a closed expansion candle beyond it, with OHLC range, body, close-location, and expansion-ratio confirmation. Optional tick volume, H1 EMA trend, and ADX gates were isolated variants. Stops sat beyond the breakout candle, were capped at `$8`, used broker-native `OrderCalcProfit` sizing at `0.10%` risk, and never forced minimum volume.

- Source SHA-256: `15F22472BE6FCF3AD195B212727C55EEF1669CD961F25422DD6F6EC397462440`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `45 / 45`; report/source identity: `45 / 45`
- Invalid stale-executable batch: quarantined locally and excluded from all metrics
- Empty M0 exports reproduced unchanged: `4`; all final reports contain the correct source identity
- Discovery profiles with at least one continuous trade: `2 / 15`
- Numeric gate passes: `0 / 15`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `m30ce_box8` | +$6.66 | 1.77 | 2 | +$41.51 | 5.16 | 5 | +$48.17 | 0.08% | 3.59 | 7 | 0.22% | REJECT_BEFORE_HOLDOUT |
| `m30ce_avg055` | -$9.43 | 0.63 | 4 | +$18.48 | 3.21 | 3 | +$9.05 | 0.02% | 1.27 | 7 | 0.39% | REJECT_BEFORE_HOLDOUT |
| `m30ce_exp120` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_exp160` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_h1trend` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_volume105` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_tp200` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_tp150` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_center` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_body45` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_avg035` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_adx14` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_boxmax210` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_boxmax150` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |
| `m30ce_box12` | +$0.00 | 0 | 0 | +$0.00 | 0 | 0 | +$0.00 | 0% | 0 | 0 | 0% | REJECT_BEFORE_HOLDOUT |

The only both-era profitable row was `m30ce_box8`, at `+$48.17` and PF `3.59`, but it placed just `7` trades in six years versus the frozen minimum of `100`. The only other active row, `m30ce_avg055`, made `+$9.05` on `7` trades and lost the older era. Thirteen profiles placed zero trades. This is an activity/generalization failure, not evidence for a sparse profitable system.

The portable runner now binds every package source hash to a compiled portable binary and rejects cached or newly exported reports whose embedded evidence hash does not match. This source-identity correction is retained as infrastructure; it does not improve strategy profit.
