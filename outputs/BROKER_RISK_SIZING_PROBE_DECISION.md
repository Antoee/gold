# Broker-Accurate Risk Sizing Probe Decision

Generated from current source hash `3C738B730A47A089ECE11A53EC9E726DE2E64B63E53866B9731253C5035A114C` after `45 / 45` hidden local Model1 reports parsed successfully.

## Verdict

**Safety fix accepted. All tested strategy profiles rejected. No new best.**

The EA now uses `OrderCalcProfit` to estimate exact entry-to-stop loss for lot sizing, open-risk accounting, exposure checks, scale-ins, and historical R calculations. This is the professional broker-aware calculation required for XAUUSD contract specifications.

The former DGF high-profit headline is no longer valid money-readiness evidence. Its continuous Model4 report included a `-$495.90` stop on a balance of about `$3,411.73`, even though the configured effective risk was approximately `1.40%`. The old raw tick-value calculation understated actual order risk by roughly an order of magnitude on the tested broker specification.

## Corrected Fast Screen

| Candidate | Continuous Net | PF | Trades | Max DD | Losing Years | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `brs_uncapped_sweep_on` | `-$38.84` | `0.55` | `55` | `4.30%` | `7` | Rejected. |
| `brs_cap100_sweep_on` | `-$42.98` | `0.53` | `55` | `4.71%` | `6` | Rejected. |
| `brs_uncapped_sweep_off` | `-$1.34` | `0.91` | `11` | `1.13%` | `6` | Rejected. |
| `brs_cap100_sweep_off` | `-$1.34` | `0.91` | `11` | `1.13%` | `6` | Rejected. |
| `brs_cap075_sweep_off` | `-$1.34` | `0.91` | `11` | `1.13%` | `6` | Rejected. |

The corrected sweep-on control's largest loss fell from `-$495.90` in the legacy report to `-$9.18` in this fast screen. That confirms the risk defect is fixed. It also exposes that the old profit curve was not a trustworthy strategy edge under the intended risk budget.

Standalone liquidity sweeps were independently harmful: in the corrected sweep-on continuous report they contributed `-$39.09` across `39` trades, while DGF contributed approximately breakeven results. Disabling standalone sweeps reduced loss and drawdown but did not create profitability.

## Future-Robustness Warning

The sweep-off profile made `+$21.37` in the isolated 2024 fast window, but lost in 2019, 2020, 2021, 2022, 2023, and 2025. Continuous 2019-2026 net was `-$1.34`. The 2024 behavior must not be locked in or presented as evidence that the strategy will work in future regimes.

## Evidence

- Results: `outputs/BROKER_RISK_SIZING_PROBE_RESULTS.csv`
- Summary: `outputs/BROKER_RISK_SIZING_PROBE_SUMMARY.csv`
- Metrics: `outputs/BROKER_RISK_SIZING_PROBE_METRICS.md`
- Run status: `outputs/BROKER_RISK_SIZING_PROBE_CURRENT_SOURCE_STATUS.md`
- Compile proof: `outputs/MT5_HIDDEN_COMPILE_BROKER_RISK_SIZING.log`

## Next

Keep broker-accurate sizing permanently. Reject standalone liquidity-sweep entries for this branch. Test whether the DGF no-cushion loss block is suppressing a legitimate edge at controlled risk, using continuous and 2019-2026 yearly gates before any real-tick follow-up.
