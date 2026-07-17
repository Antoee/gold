# Independent M15 Dual-Regime Portfolio Holdout Decision

**Decision: REJECTED IN THE UNTOUCHED 2021-2026 HOLDOUT. No Model 4 escalation, new best, or live approval was opened.**

The EA combines a trend-phase M15 volatility-squeeze continuation lane with a range-phase M15 volume-climax VWAP-reversion lane under one risk manager and one-position cap. Lane-specific comments preserve lane-specific exits. The compact neighborhood changes only previously screened lane settings and includes two diagnostic engine-only controls that cannot be promoted. Stops are capped at `$6`, use broker-native `OrderCalcProfit` sizing at `0.10%` risk, and never force minimum volume.

- Source SHA-256: `DEA3B16FB2D14E4A1253B422CCE80AEC4CB49DCF03067EDBCE96008F694FA5E1`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `36 / 36`; report/source identity: `36 / 36`
- Stale portable exports reproduced unchanged on alternate workers: `1`; all final reports contain the correct source identity
- Holdout profiles with at least one continuous trade: `12 / 12`
- Numeric gate passes: `0 / 12`
- Eligible profiles with a passing adjacent neighbor: `0 / 12`

| Candidate | 2021-23 | PF | Trades | 2024-26 YTD | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `m15drp_vcr150` | +$181.94 | 1.35 | 120 | -$66.41 | 0.76 | 54 | +$115.53 | 0.21% | 1.15 | 174 | 1.01% | REJECT_BEFORE_MODEL4 |
| `m15drp_kc160` | +$142.64 | 1.22 | 148 | -$36.59 | 0.91 | 82 | +$105.94 | 0.19% | 1.1 | 230 | 1.37% | REJECT_BEFORE_MODEL4 |
| `m15drp_vcr140` | +$151.84 | 1.28 | 123 | -$56.15 | 0.8 | 58 | +$95.69 | 0.17% | 1.12 | 181 | 1.05% | REJECT_BEFORE_MODEL4 |
| `m15drp_trend200` | +$148.07 | 1.28 | 122 | -$83.47 | 0.73 | 60 | +$59.60 | 0.11% | 1.07 | 182 | 1.14% | REJECT_BEFORE_MODEL4 |
| `m15drp_maxtrades3` | +$133.43 | 1.23 | 130 | -$97.21 | 0.71 | 65 | +$31.22 | 0.06% | 1.03 | 195 | 1.28% | REJECT_BEFORE_MODEL4 |
| `m15drp_center` | +$133.43 | 1.23 | 130 | -$99.41 | 0.7 | 65 | +$29.02 | 0.05% | 1.03 | 195 | 1.28% | REJECT_BEFORE_MODEL4 |
| `m15drp_sqbreak10` | +$94.14 | 1.18 | 117 | -$85.45 | 0.72 | 61 | +$3.69 | 0.01% | 1 | 178 | 1.38% | REJECT_BEFORE_MODEL4 |
| `m15drp_session22` | +$97.96 | 1.15 | 146 | -$95.97 | 0.73 | 70 | -$3.01 | -0.01% | 1 | 216 | 1.36% | REJECT_BEFORE_MODEL4 |
| `m15drp_trend50` | +$69.95 | 1.1 | 156 | -$98.62 | 0.73 | 70 | -$28.67 | -0.05% | 0.97 | 226 | 1.42% | REJECT_BEFORE_MODEL4 |
| `m15drp_noextreme` | +$57.64 | 1.08 | 152 | -$116.55 | 0.67 | 67 | -$58.91 | -0.11% | 0.94 | 219 | 1.66% | REJECT_BEFORE_MODEL4 |
| `m15drp_kc140` | +$26.88 | 1.06 | 99 | -$97.43 | 0.64 | 50 | -$70.55 | -0.13% | 0.9 | 149 | 1.44% | REJECT_BEFORE_MODEL4 |
| `m15drp_session18` | +$14.16 | 1.03 | 112 | -$113.78 | 0.63 | 58 | -$99.62 | -0.18% | 0.88 | 170 | 1.52% | REJECT_BEFORE_MODEL4 |

The highest continuous row was `m15drp_vcr150` at +$115.53, PF `1.15`, `174` trades, and `1.01%` drawdown. It did not satisfy the frozen holdout contract, so Model 4 cannot be opened to rescue it.
