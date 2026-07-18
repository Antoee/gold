# Reversion D1 Momentum-Cap Annual Model4 Contract

Frozen on 2026-07-18 before any annual Model 4 report for the exact center was generated or inspected.

## Identity

- Source SHA-256: `8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B`
- Center profile SHA-256: `BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC`
- Model4 contract SHA-256: `5CB8F52B08B9883E2BF0CC980C70B8D8ED99194D75508298696C4B009B0ADB4A`

## Matrix

The exact center restarts from `$10,000` for each calendar year from 2015 through 2025. The 2026 row is partial through 2026-07-16. All tests use Model 4 real ticks.

## Annual Gate

Money-readiness stress may continue only if every condition passes:

1. Exact source, profile, contract, and report identities in all 12 reports.
2. No annual restart has negative net profit.
3. At least 10 of 12 annual restarts have strictly positive net profit.
4. Summed annual activity is at least 300 trades.
5. Every annual maximum equity drawdown is no more than `2.50%`.
6. No annual report exceeds eight consecutive losses.

The summed annual net is a robustness score, not a sequential account return. A pass authorizes only execution-cost and Monte Carlo stress; it does not authorize forward substitution or real-money trading.
