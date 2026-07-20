# Momentum Same-Side Exit Cooldown Model 4 Stress Decision

**Status: STRESS GATE PASSED. This is historical stress evidence, not real-money approval.**

- Exact trades: `400`; base net: `+$2,492.25`
- Hard-risk audit: `True`; selective reversion lot cap: `True`
- Maximum reversion volume: `0.15` lots; maximum conservative portfolio initial risk: `0.5869%`
- Cost gate: `True`; order-aware Monte Carlo gate: `True`
- Source: `B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E`; EX5: `D85336B07A8C34C4567537D5C9BD7CDC0F31D0B8ED67B73BAC1088B19E126123`
- Report: `470C44F1B2426768379BF70706CE164F25A572F6B92CFEEBE54F0B3A1513EDF4`; ledger: `6D880F634BD792281DAB72C5ACC6BF9F2C617888184881BD9AFA2D84DCEFAC40`

## Added Execution Cost

| Scenario | Added R/trade | Extra cost | Net | PF | Closed DD | Older | Middle | Recent | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| base | 0.00R | $0.00 | +$2,492.25 | 1.927 | 0.997% | +$1,014.54 | +$788.91 | +$688.80 | True |
| light | 0.02R | $125.61 | +$2,366.64 | 1.859 | 1.047% | +$960.56 | +$746.37 | +$659.71 | True |
| moderate | 0.05R | $314.03 | +$2,178.22 | 1.764 | 1.125% | +$879.60 | +$682.55 | +$616.07 | True |
| severe | 0.10R | $628.06 | +$1,864.19 | 1.616 | 1.259% | +$744.65 | +$576.20 | +$543.34 | True |

## Order-Aware Monte Carlo

| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 DD | P95 loss run | Red trials | Gate |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| moving_block_08 | standard | 10000 | +$1,019.57 | +$1,877.29 | 1.655 | 2.953% | 12 | 0.000% | True |
| moving_block_08 | severe | 10000 | +$442.80 | +$1,258.35 | 1.409 | 4.100% | 16 | 0.440% | True |
| moving_block_16 | standard | 10000 | +$1,028.95 | +$1,869.74 | 1.653 | 2.621% | 11 | 0.000% | True |
| moving_block_16 | severe | 10000 | +$466.59 | +$1,262.06 | 1.410 | 3.752% | 15 | 0.410% | True |
| moving_block_24 | standard | 10000 | +$1,073.20 | +$1,881.92 | 1.660 | 2.249% | 11 | 0.000% | True |
| moving_block_24 | severe | 10000 | +$477.34 | +$1,264.41 | 1.410 | 3.393% | 14 | 0.260% | True |
| calendar_year | standard | 10000 | +$1,208.24 | +$1,909.88 | 1.669 | 1.942% | 10 | 0.000% | True |
| calendar_year | severe | 10000 | +$595.16 | +$1,267.97 | 1.412 | 3.009% | 15 | 0.120% | True |

- Stress preserves local trade clustering and calendar-year regimes; severe paths include worse slippage, delay, spread shocks, and missed winners.
- MT5 equity drawdown remains authoritative; Monte Carlo drawdown is closed-trade path drawdown.
- A second broker/specification and a valid frozen-account forward demo remain unavailable, so historical promotion and live approval stay closed.
