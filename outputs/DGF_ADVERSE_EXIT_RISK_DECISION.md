# DGF Adverse-Exit and Risk Decision

**Decision: rejected before Model 4. No new best and no live candidate.**

This branch began with the exact archived high-profit DGF implementation and added only default-off, source-reproduced research controls. The strongest fast result was attractive in aggregate, but annual and frozen-holdout evidence showed that it was not future-ready.

## Strongest Fast Result

The `darm_r045_risk040` profile used a `-0.45R` adverse exit, `0.40%` base risk, a `$10,000` initial balance, and Model 1.

| Window | Net | Annualized | PF | Trades | Max DD | Loss streak |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2019-2026 continuous | `+$15,023.66` | `+19.94%/yr` | `1.65` | `154` | `14.77%` | `8` |
| 2019-2022 restart | `+$4,967.30` | `+12.43%/yr` | `1.55` | `71` | `14.84%` | `4` |
| 2023-2026 restart | `+$4,877.92` | `+13.83%/yr` | `1.61` | `81` | `14.72%` | `6` |

The broad-window result passed the initial profit, PF, activity, and 15% drawdown screen. It did not pass the loss-streak gate.

## Annual Failure

Restarting each year at `$10,000` exposed three losing completed years:

| Year | Net | PF | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: |
| 2021 | `-$752.15` | `0.42` | `13` | `15.48%` |
| 2023 | `-$787.59` | `0.60` | `22` | `14.46%` |
| 2025 | `-$635.39` | `0.57` | `16` | `11.76%` |

The continuous headline was carried mainly by 2020 and 2024. Model 4 was skipped because Model 1 already contradicted the no-red-year requirement.

## Rejected Repairs

- **Abnormal-loss quarantine:** `8` enabled variants across `3` broad windows produced no full-gate survivor. The variants that reduced reported streaks either created a losing early window or exceeded 15% drawdown.
- **Hard non-DGF liquidity isolation:** continuous drawdown improved to `13.17%` and the streak fell to `5`, but continuous net collapsed to `+$4,992.07`, trades fell from `154` to `70`, and 2019, 2021, and 2022 became negative.
- **Rich feature screen:** logger-only telemetry added `20` market-state fields and reproduced all seven diagnostic years with zero net or trade-count difference. A chronological split was frozen before feature inspection: 2019-2022 discovery and 2023-2025 holdout. Of `220` one-feature thresholds, only one passed discovery; it then failed holdout with a `-$397.62` worst year and `0.53` PF. No feature survived.

## Trade Diagnosis

Across the seven diagnostic years, liquidity-only entries made `+$1,282.72` at PF `1.72` in profitable years but lost `-$3,036.87` at PF `0.23` in failed years. Diagnostic-fallback entries remained positive across both classes. ATR, spread, side, session, and the richer trend/volume/price-action features did not provide a stable one-feature separator.

That is a regime-dependence result, not permission to stack more fitted filters. The feature holdout is now consumed and must not be reused for threshold tuning.

## Exact Evidence

- Loss-path source SHA-256: `D9587667072956C651DC00E6D36B8C4F19FAA02F90BC24773345E6E2AD274FED`
- Telemetry-only source SHA-256: `9072DC3436BFA5578A01C162C916F4E080B79617A5F2BD1F84847F2F79088F59`
- Low-risk profile SHA-256: `D18A6F22F01E5652D5024C2BA6343625203443C8C9E6FC5F3B996D7FFEFA0392`
- Annual results: `outputs/DGF_ADVERSE_R_ANNUAL_MODEL1_RESULTS.csv`
- Quarantine results: `outputs/DGF_LOSS_QUARANTINE_MODEL1_RESULTS.csv`
- Isolation results: `outputs/DGF_LIQUIDITY_ISOLATION_VALIDATION_MODEL1_RESULTS.csv`
- Reconciled trade outcomes: `outputs/DGF_ADVERSE_R_FAILURE_TRADE_OUTCOMES.csv`
- Frozen feature screen: `outputs/DGF_LIQUIDITY_FEATURE_GATE_SCREEN.csv`

The maintained source, installed MT5 build, and real-account locks remain unchanged.
