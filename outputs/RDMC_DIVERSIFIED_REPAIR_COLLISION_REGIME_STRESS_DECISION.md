# RDMC Diversified Repair Collision Regime Stress Decision

**Decision: POSTHOC REGIME STRESS TRIAGE PASS. This remains post-hoc triage, not executable MT5 evidence or a new best.**

- Regime Monte Carlo gate: `True` (8/8 scenarios)
- Component concentration gate: `True`
- Largest net contributor: `RRO_DI12_CAP12_CONTINUOUS` at `63.131%` of aggregate net
- Largest risk contributor: `MTSM_CAP12_ANNUAL` at `69.524%` of summed initial risk
- Net without largest contributor: `+$762.32`; all broad eras positive: `True`
- Next action: `RUN_FROZEN_MT5_GATE_WHEN_UNLOCKED`
- Regime analyzer LF-normalized text SHA-256: `ED791EC447DFA037C03A269B8D9CD5B77067FC052B7F5E727D4FD7BE5F0088FA`

## Order-Aware Monte Carlo

| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 closed DD | P95 loss run | Red trials | Gate |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| moving_block_08 | standard | 10000 | +$824.05 | +$1,556.71 | 1.632 | 2.540% | 11 | 0.010% | True |
| moving_block_08 | severe | 10000 | +$342.65 | +$1,044.03 | 1.395 | 3.584% | 13 | 0.640% | True |
| moving_block_16 | standard | 10000 | +$796.17 | +$1,543.95 | 1.629 | 2.289% | 10 | 0.020% | True |
| moving_block_16 | severe | 10000 | +$305.18 | +$1,035.71 | 1.393 | 3.414% | 11 | 0.690% | True |
| moving_block_24 | standard | 10000 | +$778.95 | +$1,543.75 | 1.627 | 2.150% | 9 | 0.030% | True |
| moving_block_24 | severe | 10000 | +$279.20 | +$1,031.18 | 1.391 | 3.322% | 11 | 0.860% | True |
| whole_window | standard | 10000 | +$1,053.55 | +$1,547.80 | 1.633 | 1.591% | 9 | 0.000% | True |
| whole_window | severe | 10000 | +$523.89 | +$1,043.79 | 1.395 | 2.537% | 12 | 0.040% | True |

## Component Concentration

The preregistered concentration gate requires at least three positive components, no more than 70% of net from one component, no more than 75% of summed initial risk from one component, and positive older/middle/recent era net after removing the largest net contributor.

| Component | Trades | Net | Net share | Risk share | Leave-one-out net | Leave-one-out PF | Positive windows | Older | Middle | Recent |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DDB045_ANNUAL_RESTART | 2 | +$14.48 | 0.700% | 0.768% | +$2,053.16 | 1.895 | 12/12 | +$673.03 | +$650.83 | +$729.30 |
| MTSM_CAP12_ANNUAL | 311 | +$484.12 | 23.414% | 69.524% | +$1,583.52 | 3.661 | 12/12 | +$284.21 | +$718.82 | +$580.49 |
| R20_CURRENT_SOURCE_ANNUAL | 22 | +$263.72 | 12.755% | 9.849% | +$1,803.92 | 1.847 | 11/12 | +$687.51 | +$515.68 | +$600.73 |
| RRO_DI12_CAP12_CONTINUOUS | 33 | +$1,305.32 | 63.131% | 19.859% | +$762.32 | 1.397 | 9/12 | +$417.78 | +$67.16 | +$277.38 |

## Hard Boundary

- Moving-block sampling preserves adjacent trade clusters; whole-window sampling preserves each sampled window's internal trade order. Neither recreates an executable combined signal path.
- The source ledgers came from standalone runs. Collision blocking can alter later signals, cooldowns, limits, exits, and equity-based sizing in the actual combined EA.
- Drawdown is closed-trade only. Broker fills, intratrade equity, future regimes, and cross-component state interaction remain untested.
- The target source remains uncompiled and untested while both MT5 launch locks are active.
- Passing can only earn scarce future MT5 gate time. It cannot change the registered forward candidate or approve real-account trading.
