# Three-Lane Momentum Breakout-Failure Exit Discovery Decision

**Decision: REJECTED IN DISCOVERY. No holdout, Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `18 / 18` parsed with exact source, EX5, config, and report identity
- Attempts: `20`; source-identity refusals: `2` (preserved and excluded)
- Exact source SHA-256: `CBC2309B98AE3EC4969E52B4ADBD5E8A4EFCE8780E0654F5F9B1E9A36AD25EE4`
- Exact EX5 SHA-256: `412C2F81D9C6A0B4159AEBA677EF640BCE168E01FEC66AAA4F5DA1672EDEBA22`
- Starting balance: `$10,000`; discovery data: `2015-01-01` through `2020-12-31`; model: MT5 Model 1
- Real-account trading: disabled

| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Control (disabled) | +$860.86 | +$330.02 | +$1,191.69 | 11.92% | 1.89%/yr | 1.77 | 265 | 1.02% | 10.5778 | 11.6863 |
| 2 bars / 0.05 ATR | +$690.54 | +$274.42 | +$1,003.40 | 10.03% | 1.61%/yr | 1.77 | 261 | 1.36% | 7.0183 | 7.375 |
| Center: 3 bars / 0.05 ATR | +$639.41 | +$260.89 | +$943.30 | 9.43% | 1.51%/yr | 1.74 | 261 | 1.31% | 6.894 | 7.1985 |
| 4 bars / 0.05 ATR | +$639.41 | +$265.88 | +$948.29 | 9.48% | 1.52%/yr | 1.75 | 261 | 1.31% | 6.9304 | 7.2366 |
| 3 bars / 0.00 ATR | +$646.81 | +$274.50 | +$965.06 | 9.65% | 1.55%/yr | 1.77 | 262 | 1.31% | 7.012 | 7.3664 |
| 3 bars / 0.10 ATR | +$686.04 | +$264.55 | +$989.03 | 9.89% | 1.58%/yr | 1.77 | 261 | 1.4% | 6.7451 | 7.0643 |

## Frozen Gate

- Every report profitable: `True` (PASS)
- Center no worse in both disjoint eras: `False` (FAIL)
- Center continuous growth: `False` (FAIL)
- Center CAGR improvement: `False` (FAIL)
- Center PF/recovery/return-DD: `False` (FAIL)
- Center drawdown: `False` (FAIL)
- Center trade count: `False` (FAIL)
- Center changed behavior: `True` (PASS)
- mobfe_bars2 neighbor: `False` (FAIL)
- mobfe_bars4 neighbor: `False` (FAIL)
- mobfe_buffer000 neighbor: `False` (FAIL)
- mobfe_buffer010 neighbor: `False` (FAIL)

## Interpretation

The frozen center reduced continuous net by `-$248.39` (`-20.84%`) versus control and raised drawdown from `1.02%` to `1.31%`. It also reduced PF, recovery, return/drawdown, and trade count.

The best enabled neighbor was `mobfe_bars2` at `+$1,003.40`, still below the disabled control at `+$1,191.69`. The mechanism appears to cut recoverable momentum trades too early, so the entire family is rejected without opening 2021-2026 or spending Model 4 time.

ATB150 remains the historical champion. The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
