# Three-Lane Momentum Ridge-Quality Offline Decision

**Decision: REJECTED OFFLINE. No MQL implementation, recent holdout, Model 4, promotion, forward change, or live approval is permitted.**

- Telemetry rows: `246`; exact matched momentum trades: `246 / 249`
- Model: standardized ridge, alpha `25.0`, features `11`, expanding validation folds `3`
- Input hashes: telemetry `EA2A0DB1C38E890291785BB0B474B80586D71352C32EA7C55E7A11D1B698365C`; ATB150 ledger `D784E3F4289E989DDA2E6C686C80A20086825A6586355AFA8556021486373E69`
- The offline replay can remove historical trades but cannot recreate the resulting executable account path.
- Real-account trading: disabled

| Profile | Net | Change | PF | Trades | Removed MO | Min retention | 2017 | 2018 | 2019 | 2020 | 2021 | 2022 | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| ridge_q20 | +$1,109.54 | +5.64% | 1.800 | 221 | 34 | 70.4% | +$162.86 | +$271.00 | +$100.68 | +$167.65 | +$331.51 | +$75.84 | PASS |
| ridge_q25_center | +$1,056.29 | +0.57% | 1.764 | 217 | 38 | 70.4% | +$137.57 | +$274.73 | +$100.68 | +$167.65 | +$331.51 | +$44.15 | FAIL |
| ridge_q30 | +$1,087.85 | +3.57% | 1.808 | 213 | 42 | 68.5% | +$137.57 | +$274.73 | +$114.32 | +$167.65 | +$340.14 | +$53.44 | FAIL |

## Fold Evidence

| Profile | Fold | Retained | Control | Candidate | Change | Kept avg R | Removed avg R | Ranking | Positive years |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| ridge_q20 | fold_2017_2018 | 92.9% | +$403.03 | +$433.86 | +$30.83 | +0.269 | -0.385 | PASS | PASS |
| ridge_q25_center | fold_2017_2018 | 90.5% | +$403.03 | +$412.30 | +$9.27 | +0.253 | -0.078 | PASS | PASS |
| ridge_q30 | fold_2017_2018 | 90.5% | +$403.03 | +$412.30 | +$9.27 | +0.253 | -0.078 | PASS | PASS |
| ridge_q20 | fold_2019_2020 | 70.4% | +$267.36 | +$268.33 | +$0.97 | +0.233 | -0.032 | PASS | PASS |
| ridge_q25_center | fold_2019_2020 | 70.4% | +$267.36 | +$268.33 | +$0.97 | +0.233 | -0.032 | PASS | PASS |
| ridge_q30 | fold_2019_2020 | 68.5% | +$267.36 | +$281.97 | +$14.61 | +0.267 | -0.090 | PASS | PASS |
| ridge_q20 | fold_2021_2022 | 78.9% | +$379.92 | +$407.35 | +$27.43 | -0.184 | -0.221 | PASS | PASS |
| ridge_q25_center | fold_2021_2022 | 75.4% | +$379.92 | +$375.66 | -$4.26 | -0.261 | +0.023 | FAIL | PASS |
| ridge_q30 | fold_2021_2022 | 70.2% | +$379.92 | +$393.58 | +$13.66 | -0.237 | -0.083 | FAIL | PASS |

## Boundary

At least one center or neighbor gate failed. The score family stops here without another feature, ridge penalty, percentile, model, or split search on these trades.

ATB150 remains the historical champion. The registered forward candidate, invalid-account boundary, and real-account lock remain unchanged.
