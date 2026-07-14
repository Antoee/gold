# LowATR R20 Opportunity Sweep Package

Offline package builder only. This does not launch MT5.

- Base profile: `outputs\lowatr_exit_sweep_package\profiles\lowatr_exit_peak_r20.set`
- Source hash: `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`
- Base profile hash: `8F8C1395084BFBC23472D97A93C6E32FCB0AAC526C6AFE9BB53604F085FDD678`
- Model: `1`
- Variants: `33`

## Hypotheses

- `peak_r20_base`: Baseline R20 profile for direct comparison in the same package.
- `peak_r20_diag_2025`: Base R20 with block-reason diagnostics enabled for the weak 2025 split.
- `peak_r20_may_full`: Let May trade past day 10 while keeping the rest of the R20 safety stack.
- `peak_r20_may_full_spread22`: Relax May day window and spread cap modestly to see if quality May trades were excluded.
- `peak_r20_aug_risk60`: Slightly less throttled August risk, testing whether the safe branch is under-sizing good August setups.
- `peak_r20_may31_aug60`: Combined May window relaxation plus modest August risk restoration.
- `peak_r20_islp_may_aug`: Allow the existing ISLP lane to evaluate May and August signals at low risk.
- `peak_r20_islp_broad_lowrisk`: Broader ISLP month coverage with low lane risk and existing month-filter bypass.
- `peak_r20_octnov_main_lowrisk`: Test October/November as primary months but with explicit low month risk.
- `peak_r20_fmlr_strict`: Enable strict flat-month liquidity reclaim as a small-risk standalone opportunity lane.
- `peak_r20_fmlr_sweep_bos`: Require sweep-displacement/BOS style reclaim before a tiny-risk liquidity-reclaim entry.
- `peak_r20_fmlr_fvg_ob`: Tiny-risk liquidity reclaim using FVG/order-block/CHoCH retest components as extra price-action evidence.
- `peak_r20_soft_weak_gate`: Slightly soften weak-regime gate while leaving the gate enabled.
- `peak_r20_no_day_window_lowrisk`: Disable the month-day window, offset by lower base risk, to test whether timing gates are the bottleneck.
- `peak_r20_no_peaktrail`: Disable equity profit peak trail to test whether the safe branch can keep trading after early gains.
- `peak_r20_no_peaktrail_r15`: No equity peak trail with lower base risk to keep later-year participation under control.
- `peak_r20_no_peaktrail_r10`: No equity peak trail with half-sized base risk and existing month multipliers.
- `peak_r20_no_peaktrail_r10_norm`: No equity peak trail with normalized month risk to reduce May multiplier concentration.
- `peak_r20_no_peaktrail_loss_scale`: Replace the hard equity peak blocker with loss-based risk scaling after drawdown starts.
- `peak_r20_no_peaktrail_cap6`: No equity peak trail with a hard 6% equity drawdown safety stop.
- `peak_r20_no_peaktrail_r08_floor05`: No equity peak trail with lower risk and an explicit 0.05% reduced-risk floor.
- `peak_r20_no_peaktrail_r10_floor05`: No equity peak trail at 0.10% base risk with a lower reduced-risk floor.
- `peak_r20_no_peaktrail_r12_floor05`: No equity peak trail at 0.12% base risk with a lower reduced-risk floor.
- `peak_r20_no_peaktrail_r14_floor05`: No equity peak trail at 0.14% base risk with a lower reduced-risk floor.
- `peak_r20_no_peaktrail_r16_floor05`: No equity peak trail at 0.16% base risk with a lower reduced-risk floor.
- `peak_r20_all_nodec_r05_norm`: Trade every month except December at very low normalized risk after diagnostics showed many primary signals blocked by month filter.
- `peak_r20_all_nodec_r08_norm`: All non-December months at normalized 0.08% risk.
- `peak_r20_all_nodec_r10_norm`: All non-December months at normalized 0.10% risk.
- `peak_r20_all_nodec_r12_norm`: All non-December months at normalized 0.12% risk.
- `peak_r20_all_nodec_r08_conf2`: All non-December months at 0.08% risk, requiring two confirmations instead of one.
- `peak_r20_all_nodec_r10_conf2`: All non-December months at 0.10% risk, requiring two confirmations instead of one.
- `peak_r20_all_nodec_r08_weighted`: All non-December months with weighted entry score gate at low risk.
- `peak_r20_all_nodec_r08_diagq`: All non-December months while forcing diagnostic fallback signals to show structure and execution quality.

## Files

- Queue manifest: `outputs\LOWATR_R20_OPPORTUNITY_SWEEP_QUEUE.csv`
- Runner manifest: `outputs\LOWATR_R20_OPPORTUNITY_SWEEP_PACKAGE_MANIFEST.csv`
- Package dir: `outputs\lowatr_r20_opportunity_sweep_package`
