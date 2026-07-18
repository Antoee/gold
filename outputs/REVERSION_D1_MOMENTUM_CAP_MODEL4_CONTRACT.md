# Reversion D1 Momentum-Cap Model4 Contract

Frozen on 2026-07-18 before any Model 4 report for this source or profile family was generated or inspected.

## Exact Identities

- Source SHA-256: `8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B`
- Discovery contract SHA-256: `0D1199E9BBDF4A9E02AE10359F912976246168FDA53A1917768BCADDD535AA67`
- Holdout contract SHA-256: `7214D856192510C1958BE7AA714DC8130A3E1ED145921FCDA85AE8210703EF76`
- DI parent profile SHA-256: `9A5C91BCB4013C510D9AB1EB65083D302C7DF27C7FFA5B01C0A8F98C0EF22C66`
- Cap-12 center profile SHA-256: `BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC`
- Cap-14 neighbor profile SHA-256: `0271FB8073C2282D8BDE1FDBC7823C9B6F7F34EA5B44E67A1304C191D806AA7B`

No source or profile field may change.

## Frozen Matrix

Three profiles are tested on Model 4 real ticks:

- `rdmc_di10_parent`
- `rdmc_di10_cap12_center`
- `rdmc_di10_cap14`

Each profile runs:

- 2015-2020 discovery path
- 2021-2023 early holdout
- 2024-2026 YTD recent holdout through 2026-07-16
- 2021-2026 YTD continuous holdout
- 2015-2026 YTD full continuous path

## Model4 Gate

The exact center can become a historical research candidate only if every condition passes:

1. Exact source, profile, contract, and report identities in all 15 reports.
2. Positive net profit and PF at least `1.10` in each disjoint era: 2015-2020, 2021-2023, and 2024-2026 YTD.
3. Full 2015-2026 YTD PF at least `1.40`, at least `300` trades, and maximum equity drawdown no more than `3.50%`.
4. Full-path net profit at least as high as the DI parent, with drawdown no worse than the parent.
5. The fixed cap-14 neighbor independently passes conditions 2-4.

Only a Model4 survivor may enter annual real-tick restarts, execution-cost stress, trade-order/slippage Monte Carlo, and broker-specification review. A pass is historical research evidence only and does not alter the frozen forward candidate or authorize real-money trading.
