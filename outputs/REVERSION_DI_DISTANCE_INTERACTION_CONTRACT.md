# Reversion DI and Long-Distance Interaction Contract

Frozen on 2026-07-18 before any report using the simultaneous gate combination was generated or inspected.

## Hypothesis

Two independently preregistered reversion filters addressed different parts of the pre-2021 weakness:

- The fixed DI `-10` center repaired 2020 but left 2019 slightly negative.
- The fixed `-10 ATR` long-distance center removed one weak-era stop-out but did not make 2019-2020 profitable by itself.

The interaction may reject the remaining poor reversion setup without changing either selected threshold. Both filters use completed H1 bars and can only refuse a new reversion entry. Momentum, stops, targets, sizing, exits, account locks, exposure limits, portfolio loss controls, and the frozen forward candidate remain unchanged.

## Frozen Identities

- Research source SHA-256: `7E8D680807B0565992ECC9B98E15C636A86AF34742194687DBB64D61CE2EFD7A`
- Prior clean-compile binary SHA-256: `F97E596B4981E75FBB27146EEBCAC72854B08E7E4CE81C6AA0E84B84E0BFC776`
- Pre-run clean-compile binary SHA-256: `E1234E3AE29F3A6D28D66F39D20A4A56D7A415AD230679627454D4607092FB1B`
- Pre-run compile result: `0 errors, 0 warnings`
- Base RC2 source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`

The exact long-distance source already contains both independently configurable gates. No source behavior is changed for this interaction test; only the frozen input combination is exercised. Recompiling identical source bytes produced a different EX5 hash, so the source hash is the immutable behavior boundary and every portable worker binary is recorded separately in runner evidence.

## Frozen Profiles

| Profile | DI minimum | Distance guard | Minimum aligned distance | Role |
|---|---:|---|---:|---|
| `rddi_released_control` | -12 | off | n/a | Released RC2 reference |
| `rddi_di10_parent` | -10 | off | n/a | Fixed DI parent |
| `rddi_di10_m12` | -10 | on | -12 ATR | Loose neighbor |
| `rddi_di10_m10_center` | -10 | on | -10 ATR | Nominated center |
| `rddi_di10_m8` | -10 | on | -8 ATR | Strict neighbor |

All profiles retain `0.45%` reversion risk, `0.15%` momentum risk, the `0.75%` shared open-risk cap, and a 200-completed-H1-bar long-distance mean.

## Discovery Windows

- Selection-regime preservation: 2015-01-01 through 2018-12-31.
- Weak year one: 2019-01-01 through 2019-12-31.
- Weak year two: 2020-01-01 through 2020-12-31.
- Continuous pre-2021: 2015-01-01 through 2020-12-31.

Post-2020 data remains closed during discovery.

## Promotion Gate

The nominated center can open holdout only if every condition passes:

1. Exact source, profile, contract, and report identities.
2. Positive net profit in 2015-2018, 2019, and 2020 separately.
3. Continuous PF at least `1.50`, at least `180` trades, and maximum equity drawdown no more than `2.80%`.
4. Continuous net profit at least as high as the fixed DI parent, with drawdown no worse than the parent.
5. At least one adjacent distance neighbor independently passes conditions 2-4.

Only a discovery survivor may enter separately reported 2021-2023 and 2024-2026 YTD Model 1 holdouts. Both holdouts must be profitable before Model 4, annual restart, cost, and Monte Carlo validation can open.

No DI or distance threshold may move after discovery. This is research evidence only. It does not modify the registered candidate, profile, binary, run label, evidence logs, invalid demo-account attachment, or real-account hard lock.
