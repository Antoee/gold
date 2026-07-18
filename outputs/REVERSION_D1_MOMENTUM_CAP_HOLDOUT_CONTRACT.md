# Reversion D1 Momentum-Cap Holdout Contract

Frozen on 2026-07-18 before any post-2020 report for the D1 momentum-cap source or center profile was generated or inspected.

## Exact Candidate

- Source SHA-256: `8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B`
- Discovery contract SHA-256: `0D1199E9BBDF4A9E02AE10359F912976246168FDA53A1917768BCADDD535AA67`
- Exact center profile SHA-256: `BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC`
- Center: DI minimum `-10`, completed-D1 126-bar absolute momentum cap `12%`
- Risk: `0.45%` reversion, `0.15%` momentum, `0.75%` shared open-risk cap

No profile field may change for holdout.

## Frozen Windows

| Window | From | To | Role |
|---|---|---|---|
| `holdout_2021_2023` | 2021-01-01 | 2023-12-31 | Early unseen-era holdout |
| `holdout_2024_2026` | 2024-01-01 | 2026-07-16 | Recent holdout |
| `continuous_2021_2026` | 2021-01-01 | 2026-07-16 | Post-discovery path check |

## Holdout Gate

The exact center can open Model 4 only if every condition passes:

1. Exact source, profile, discovery-contract, holdout-contract, and report identities.
2. Both disjoint holdout windows have positive net profit, PF at least `1.10`, and maximum equity drawdown no more than `2.80%`.
3. Continuous 2021-2026 has positive net profit, PF at least `1.30`, at least `120` trades, and maximum equity drawdown no more than `2.80%`.

No threshold, risk, window, or quality floor may move after results. A pass authorizes only frozen Model 4 validation, not promotion, forward substitution, funding, or real-money trading.
