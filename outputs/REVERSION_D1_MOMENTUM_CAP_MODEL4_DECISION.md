# Reversion D1 Momentum-Cap Model4 Decision

**Decision: MODEL4 PASS. The cap-12 center becomes a stability-focused historical research candidate and may enter money-readiness stress. The frozen forward candidate remains unchanged.**

- Exact source: `8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B`
- Exact Model4 contract: `5CB8F52B08B9883E2BF0CC980C70B8D8ED99194D75508298696C4B009B0ADB4A`
- Reports parsed: `15 / 15`; three exact identity-failed ranks were retried
- Real-account trading: disabled

| Profile | 2015-20 / PF | 2021-23 / PF | 2024-26 / PF | Full net / PF | Trades | DD | Recovery | Era | Full | Parent | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---|
| `rdmc_di10_parent` | $+751.75 / 1.56 | $+414.94 / 1.62 | $+222.30 / 1.62 | $+1427.80 / 1.57 | 350 | 1.6% | 8.0065 | True | True | True | False | PARENT_ONLY |
| `rdmc_di10_cap12_center` | $+818.86 / 1.64 | $+414.94 / 1.62 | $+301.64 / 2.45 | $+1555.33 / 1.68 | 344 | 1.59% | 8.7216 | True | True | True | True | OPEN_MONEY_READINESS |
| `rdmc_di10_cap14` | $+818.86 / 1.64 | $+414.94 / 1.62 | $+242.82 / 1.96 | $+1506.97 / 1.64 | 345 | 1.59% | 8.4505 | True | True | True | False | SUPPORTS_CENTER |

## Interpretation

The exact center remains profitable in every disjoint real-tick era and improves full-path net from the DI parent's `+$1,427.80` to `+$1,555.33`. PF rises from `1.57` to `1.68`; drawdown is effectively flat but slightly lower at `1.59%` versus `1.60%`.

The cap-14 neighbor independently passes at `+$1,506.97`, PF `1.64`, 345 trades, and `1.59%` drawdown. That neighborhood support allows the center to enter annual restart and stress testing without claiming it is the highest-profit historical profile.

This is a historical stability candidate, not forward evidence or real-money approval.
