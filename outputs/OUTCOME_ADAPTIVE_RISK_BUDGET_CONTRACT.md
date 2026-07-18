# Outcome-Adaptive Risk-Budget Discovery Contract

Date frozen: 2026-07-17, before running this screen.

## Purpose

Test whether the validated two-lane portfolio can use its existing unused risk capacity more efficiently without changing a signal, stop, target, trading date, month, session, or account safety limit.

This is an analytical implementation gate. It cannot promote a bot by itself. A passing center must still be implemented in a separate RC2 research fork and reproduce its benefit in exact MT5 Model1 and Model4 tests.

## Frozen Evidence

- Trade ledger: `release/transferable-portfolio-v0.1/evidence/TRANSFERABLE_PORTFOLIO_MODEL4_TRADES.csv`
- Trade-ledger SHA-256: `2F7A8A8854F8F33325498AE0F194202E7BB15F28F2644FC4F9B08DE8B740413B`
- RC2 source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Model4 profile SHA-256: `5C45D578B42609D3792EA692D5A13A9E0D90C8C14D0376F807E6F6079EC6B827`
- Starting balance: `$10,000`
- Trades: `362` (`48` reversion, `314` momentum)
- Test history: 2015-01-01 through 2026-07-16

## No-Lookahead Rule

At a trade entry, the multiplier may use only already closed trades from the same lane. Open trades, future exits, calendar identity, and other-lane outcomes are unavailable. Each restarted window begins with empty history and a `1.00x` multiplier.

After the minimum history is available:

- `cold`: rolling mean R is at or below zero, or cumulative lane drawdown reaches the configured cold threshold;
- `hot`: rolling mean R reaches the configured hot threshold while cumulative lane drawdown is no more than `1.0R`;
- otherwise: `normal`.

The center uses `0.50x / 1.00x / 1.25x` cold/normal/hot multipliers. Maximum simultaneous requested risk remains `0.75%`, equal to the released account-wide open-risk cap. The screen may reduce or redistribute risk but cannot expand that cap.

## Frozen Variants

| Variant | Lookback | Hot mean | Cold multiplier | Cold drawdown |
|---|---:|---:|---:|---:|
| `oarb_center_n12_h15_c50_dd25` | 12 | 0.15R | 0.50x | 2.5R |
| `oarb_n08_h15_c50_dd25` | 8 | 0.15R | 0.50x | 2.5R |
| `oarb_n16_h15_c50_dd25` | 16 | 0.15R | 0.50x | 2.5R |
| `oarb_n12_h10_c50_dd25` | 12 | 0.10R | 0.50x | 2.5R |
| `oarb_n12_h20_c50_dd25` | 12 | 0.20R | 0.50x | 2.5R |
| `oarb_n12_h15_c75_dd25` | 12 | 0.15R | 0.75x | 2.5R |
| `oarb_n12_h15_c50_dd20` | 12 | 0.15R | 0.50x | 2.0R |
| `oarb_n12_h15_c50_dd30` | 12 | 0.15R | 0.50x | 3.0R |

The fixed-risk released behavior is always included as `fixed_control`.

## Frozen Windows And Stress

- Discovery restart: 2015-2020
- Later chronological restart: 2021-2026 YTD
- Broad restarts: 2015-2018, 2019-2022, and 2023-2026 YTD
- Continuous: 2015-2026 YTD
- Cost stress: deduct `0.05R` and `0.10R` from every trade

The later window is chronological validation for this rule, but it is not pristine market data: the repository has used those years in prior strategy research.

## Promotion Gate

The center advances to MQL implementation only if every condition passes:

1. The fixed control analytically reproduces the ledger's `+$1,615.36` net within one cent and all `362` trades.
2. Discovery net improves at least `5%` over its fixed control.
3. Later chronological net improves at least `3%` over its fixed control.
4. Continuous net improves at least `7.5%` over fixed control.
5. Under `0.05R` cost stress, continuous net improves at least `5%` over stressed control.
6. Every broad restart is profitable.
7. Continuous PF is at least `1.50` and no more than `0.05` below control.
8. Conservative risk-floor drawdown is at most `4.0%` and no more than `0.50` percentage points above control.
9. Red calendar years do not exceed the fixed control.
10. Hot and cold states are both active; hot entries remain between `5%` and `60%` of trades.
11. At least `5 / 7` neighboring variants remain profitable in all broad restarts, do not lose under `0.05R` cost stress, do not exceed `4.0%` risk-floor drawdown, and match or beat full-period fixed-control net.

Failing any gate rejects the family before EA implementation. A pass authorizes only an exact-source research fork and MT5 validation, never forward or real-money promotion.
