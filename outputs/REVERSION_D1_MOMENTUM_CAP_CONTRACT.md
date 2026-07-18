# Reversion D1 Momentum-Cap Contract

Frozen on 2026-07-18 before any filtered 2019, 2020, or continuous report for this source was generated or inspected.

## Hypothesis

The exact 2019 RC2 loss contains two H1 Band/VWAP reversion stop-outs. Behavior-preserving diagnostics show both occurred after an extreme completed-D1 126-bar price displacement of approximately `16.5%` in absolute terms. The profitable 2015-2018 reversion sample never exceeded `11.31%`.

Mean reversion may be less reliable when gold has moved unusually far over roughly six trading months. The proposed guard uses only completed D1 closes, is direction-independent, and can only refuse a new reversion entry. It has no date, month, year, outcome, account-equity, or future-bar input.

## Frozen Identities

- Research source SHA-256: `8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B`
- Research binary SHA-256: `3E6C2D6A15FE39B99B0E1A4BC6CE7AA6105FA2D4FAF647258213D1EC30E99C03`
- Compile result: `0 errors, 0 warnings`
- Base RC2 source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Diagnostic telemetry source SHA-256: `13CF38517BF6859CCD620C3CF658CF278452B3387E5690D44391F4E95B141BC4`

## Selection Evidence

The 2015-2018 reversion sample contains 17 trades and made `+$374.62`, PF `2.97`, with every calendar year profitable. Rounded absolute D1 momentum caps produced:

| Cap | Net | PF | Trades | Rejected | Every year positive |
|---:|---:|---:|---:|---:|---|
| 10% | +$302.42 | 2.59 | 16 | 1 | yes |
| 12% | +$374.62 | 2.97 | 17 | 0 | yes |
| 14% | +$374.62 | 2.97 | 17 | 0 | yes |

The `12%` center is the first even-numbered cap above the observed pre-2019 maximum; `10%` and `14%` are fixed neighbors. The later diagnostic values motivated the mechanism but do not move these rounded pre-2019 thresholds.

## Frozen Profiles

| Profile | DI minimum | D1 cap | Role |
|---|---:|---:|---|
| `rdmc_released_control` | -12 | off | Released RC2 reference |
| `rdmc_di10_parent` | -10 | off | Fixed DI parent |
| `rdmc_di10_cap10` | -10 | 10% | Strict neighbor |
| `rdmc_di10_cap12_center` | -10 | 12% | Nominated center |
| `rdmc_di10_cap14` | -10 | 14% | Loose neighbor |

All profiles retain `0.45%` reversion risk, `0.15%` momentum risk, and the `0.75%` shared open-risk cap. The new lookback is fixed at 126 completed D1 bars.

## Discovery Gate

Model 1 covers six independently restarted calendar years (2015 through 2020) plus continuous 2015-2020. Post-2020 data remains closed unless the nominated center passes every condition:

1. Exact source, profile, contract, and report identities.
2. Positive net profit in every calendar year from 2015 through 2020.
3. Continuous PF at least `1.50`, at least `180` trades, and maximum equity drawdown no more than `2.80%`.
4. Continuous net profit at least as high as the fixed DI parent, with drawdown no worse than the parent.
5. At least one adjacent cap independently passes conditions 2-4.

Only a discovery survivor may enter separately reported 2021-2023 and 2024-2026 YTD Model 1 holdouts. Both holdout eras must be profitable before Model 4, annual restart confirmation, added-cost stress, and Monte Carlo validation can open.

No cap, lookback, DI threshold, or risk allocation may move after discovery. The frozen forward candidate, registration, profile, binary, run label, evidence logs, invalid demo attachment, and real-account hard lock remain unchanged.
