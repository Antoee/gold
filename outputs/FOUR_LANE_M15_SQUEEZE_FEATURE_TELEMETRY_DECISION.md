# Four-Lane M15 Squeeze Feature-Telemetry Decision

**Decision: NO TRAINING CANDIDATE. No validation outcome, strategy filter, post-2020 test, Model 4 test, promotion, forward change, or real trading is permitted. NO NEW BEST.**

- Exact Model 1 telemetry report: `1/1` accepted with source, EX5, config, report, and sidecar identity.
- Behavior-neutral reproduction: `+$1,695.16`, `+16.95%`, `2.64%/yr` CAGR, PF `1.84`, 391 report trades, `1.10%` drawdown.
- Aggregated squeeze ledger: 88 positions, 129 exit deals, 41 protected partial events, `+$328.66` squeeze net.
- Frozen screen: 15 completed-bar features x two directions x three fixed quantile rungs; 55 training trades from 2015-2018.
- Passing training families: `0/30`. The reserved 33 trades from 2019-2020 were not opened for candidate validation because no family earned that right.

## Closest Training Family

| RangeATR minimum rung | Threshold | Kept | Retention | Improvement | Early half | Late half | PF | Training gate |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| 15% | 0.86847540 | 46/55 | 83.64% | +$45.74 | +$4.53 | +$41.21 | 2.1382 | True |
| 20% center | 0.89390840 | 44/55 | 80% | +$38.8 | +$4.53 | +$34.27 | 2.1634 | True |
| 25% | 0.95404950 | 41/55 | 74.55% | +$36.59 | +$24.33 | +$12.26 | 2.2834 | False |

The RangeATR family was coherent in both training halves, but its 25% neighbor retained only `41/55 = 74.55%`, below the frozen `75%` floor. Changing the retention rule, threshold, or neighbor after seeing this result would be a rescue. The near miss is recorded for independent future research only; it does not open the reserved validation set.

- Source SHA-256: `C6B4BC66F661BB70CC51B92E320A87A5643745454C26791B09766F84DA9C94C4`
- EX5 SHA-256: `EAC3F26DDCE7E7FC59CD02AFFE3F358397FCABF4F9D402F8F0B6D27B8EE3AA9C`
- Ledger SHA-256: `992D32AC8E7608CB24F337E4AB6275AADEA3580861A818EBDB2355A7E323CB84`
- Frozen analyzer SHA-256: `EDD9DC6CE723F111C9C888B321DF76405A0E581AF539C0DD04F566912E7558C8`

The verified Model 4 same-side exit-cooldown leader remains `+$2,492.25`, `+24.92%`, `1.95%/yr` CAGR, PF `1.93`, and `1.18%` drawdown. The invalid `$100,000` demo contributes zero forward evidence and real-account trading remains disabled.
