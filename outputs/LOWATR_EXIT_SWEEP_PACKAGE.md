# LowATR Exit Sweep Package

Offline package builder only. This does not launch MT5.

- Source hash: `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`
- Base profile: `outputs\CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`
- Window: `2024.01.01` to `2026.07.12`
- Model: `1`
- Configs: `32`

## Variants

| Rank | Candidate | Purpose | Overrides |
| ---: | --- | --- | --- |
| 1 | `lowatr_exit_be08` | Protect winners earlier with break-even at 0.80R. | InpBreakEvenBufferPoints=30<br>InpBreakEvenTriggerR=0.80<br>InpUseBreakEven=true |
| 2 | `lowatr_exit_be06` | More aggressive break-even at 0.60R with smaller buffer. | InpBreakEvenBufferPoints=20<br>InpBreakEvenTriggerR=0.60<br>InpUseBreakEven=true |
| 3 | `lowatr_exit_trail12` | Tighten ATR trailing from the default/profile behavior. | InpTrailATRMultiplier=1.20<br>InpUseATRTrailing=true |
| 4 | `lowatr_exit_trail10` | Very tight ATR trailing to cut high-drawdown paths. | InpTrailATRMultiplier=1.00<br>InpUseATRTrailing=true |
| 5 | `lowatr_exit_mfe_tight` | Tighter MFE giveback and profit lock after trades move in favor. | InpMFEGivebackMaxGivebackR=0.55<br>InpMFEGivebackMinCloseR=0.25<br>InpMFEGivebackStartR=1.00<br>InpMFEProfitLockGivebackR=0.55<br>InpMFEProfitLockMinR=0.30<br>InpMFEProfitLockStartR=1.20<br>InpUseMFEGivebackExit=true<br>InpUseMFEProfitLockMonthFilter=false<br>InpUseMFEProfitLockStop=true |
| 6 | `lowatr_exit_mfe_early` | Exit early when a trade gives back after reaching moderate MFE. | InpEarlyMFEReversalExitR=-0.05<br>InpEarlyMFEReversalStartR=0.60<br>InpUseEarlyMFEReversalExit=true |
| 7 | `lowatr_exit_combo_guard` | Combine earlier break-even, tighter trailing, and tighter MFE lock. | InpBreakEvenBufferPoints=25<br>InpBreakEvenTriggerR=0.80<br>InpMFEGivebackMaxGivebackR=0.60<br>InpMFEGivebackStartR=1.10<br>InpMFEProfitLockGivebackR=0.60<br>InpMFEProfitLockStartR=1.25<br>InpTrailATRMultiplier=1.20<br>InpUseATRTrailing=true<br>InpUseBreakEven=true<br>InpUseMFEGivebackExit=true<br>InpUseMFEProfitLockMonthFilter=false<br>InpUseMFEProfitLockStop=true |
| 8 | `lowatr_exit_loss_scale` | Throttle risk after realized daily/weekly/monthly losses without hard blocking all trades. | InpDailyLossRiskStartFraction=0.25<br>InpMinDailyLossRiskMultiplier=0.35<br>InpMinMonthlyLossRiskMultiplier=0.35<br>InpMinWeeklyLossRiskMultiplier=0.35<br>InpMonthlyLossRiskStartFraction=0.25<br>InpUseDailyLossRiskScaling=true<br>InpUseMonthlyLossRiskScaling=true<br>InpUseWeeklyLossRiskScaling=true<br>InpWeeklyLossRiskStartFraction=0.25 |
| 9 | `lowatr_exit_peak_guard` | Use account profit giveback protection to keep large winning paths from handing too much back. | InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpUseEquityProfitPeakTrail=true |
| 10 | `lowatr_exit_raw_cap6` | Raw locked LowATR with a hard 6% equity drawdown stop. | InpClosePositionsOnRiskLimit=true<br>InpMaxEquityDrawdownPercent=6.00 |
| 11 | `lowatr_exit_mfe_early_cap6` | Early MFE reversal exit plus a hard 6% equity drawdown stop. | InpClosePositionsOnRiskLimit=true<br>InpEarlyMFEReversalExitR=-0.05<br>InpEarlyMFEReversalStartR=0.60<br>InpMaxEquityDrawdownPercent=6.00<br>InpUseEarlyMFEReversalExit=true |
| 12 | `lowatr_exit_loss_scale_cap6` | Loss-scaling plus a hard 6% equity drawdown stop. | InpClosePositionsOnRiskLimit=true<br>InpDailyLossRiskStartFraction=0.25<br>InpMaxEquityDrawdownPercent=6.00<br>InpMinDailyLossRiskMultiplier=0.35<br>InpMinMonthlyLossRiskMultiplier=0.35<br>InpMinWeeklyLossRiskMultiplier=0.35<br>InpMonthlyLossRiskStartFraction=0.25<br>InpUseDailyLossRiskScaling=true<br>InpUseMonthlyLossRiskScaling=true<br>InpUseWeeklyLossRiskScaling=true<br>InpWeeklyLossRiskStartFraction=0.25 |
| 13 | `lowatr_exit_peak_guard_cap6` | Peak-profit guard plus a hard 6% equity drawdown stop. | InpClosePositionsOnRiskLimit=true<br>InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpMaxEquityDrawdownPercent=6.00<br>InpUseEquityProfitPeakTrail=true |
| 14 | `lowatr_exit_peak_guard_cap8` | Peak-profit guard plus a hard 8% equity drawdown stop for a slightly looser research comparison. | InpClosePositionsOnRiskLimit=true<br>InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpMaxEquityDrawdownPercent=8.00<br>InpUseEquityProfitPeakTrail=true |
| 15 | `lowatr_exit_peak_r25` | Peak-profit guard at 0.25% risk to test whether drawdown scales down without a hard stop. | InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpRiskPercent=0.25<br>InpUseEquityProfitPeakTrail=true |
| 16 | `lowatr_exit_peak_r20` | Peak-profit guard at 0.20% risk for the under-6% drawdown boundary. | InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpRiskPercent=0.20<br>InpUseEquityProfitPeakTrail=true |
| 17 | `lowatr_exit_peak_r22` | Peak-profit guard at 0.22% risk for the under-6% drawdown boundary. | InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpRiskPercent=0.22<br>InpUseEquityProfitPeakTrail=true |
| 18 | `lowatr_exit_peak_r24` | Peak-profit guard at 0.24% risk for the under-6% drawdown boundary. | InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpRiskPercent=0.24<br>InpUseEquityProfitPeakTrail=true |
| 19 | `lowatr_exit_peak_r30` | Peak-profit guard at 0.30% risk. | InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpRiskPercent=0.30<br>InpUseEquityProfitPeakTrail=true |
| 20 | `lowatr_exit_peak_r35` | Peak-profit guard at 0.35% risk. | InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpRiskPercent=0.35<br>InpUseEquityProfitPeakTrail=true |
| 21 | `lowatr_exit_peak_r40` | Peak-profit guard at 0.40% risk. | InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpRiskPercent=0.40<br>InpUseEquityProfitPeakTrail=true |
| 22 | `lowatr_exit_peak_r50` | Peak-profit guard at 0.50% risk. | InpEquityProfitPeakTrailGivebackPercent=10.0<br>InpEquityProfitPeakTrailMinProfitPercent=2.00<br>InpRiskPercent=0.50<br>InpUseEquityProfitPeakTrail=true |
| 23 | `lowatr_exit_mfe_early_r25` | Early MFE reversal exit at 0.25% risk. | InpEarlyMFEReversalExitR=-0.05<br>InpEarlyMFEReversalStartR=0.60<br>InpRiskPercent=0.25<br>InpUseEarlyMFEReversalExit=true |
| 24 | `lowatr_exit_mfe_early_r30` | Early MFE reversal exit at 0.30% risk. | InpEarlyMFEReversalExitR=-0.05<br>InpEarlyMFEReversalStartR=0.60<br>InpRiskPercent=0.30<br>InpUseEarlyMFEReversalExit=true |
| 25 | `lowatr_exit_mfe_early_r35` | Early MFE reversal exit at 0.35% risk. | InpEarlyMFEReversalExitR=-0.05<br>InpEarlyMFEReversalStartR=0.60<br>InpRiskPercent=0.35<br>InpUseEarlyMFEReversalExit=true |
| 26 | `lowatr_exit_mfe_early_r40` | Early MFE reversal exit at 0.40% risk. | InpEarlyMFEReversalExitR=-0.05<br>InpEarlyMFEReversalStartR=0.60<br>InpRiskPercent=0.40<br>InpUseEarlyMFEReversalExit=true |
| 27 | `lowatr_exit_mfe_early_r50` | Early MFE reversal exit at 0.50% risk. | InpEarlyMFEReversalExitR=-0.05<br>InpEarlyMFEReversalStartR=0.60<br>InpRiskPercent=0.50<br>InpUseEarlyMFEReversalExit=true |
| 28 | `lowatr_exit_loss_scale_r25` | Loss-scaling at 0.25% risk. | InpDailyLossRiskStartFraction=0.25<br>InpMinDailyLossRiskMultiplier=0.35<br>InpMinMonthlyLossRiskMultiplier=0.35<br>InpMinWeeklyLossRiskMultiplier=0.35<br>InpMonthlyLossRiskStartFraction=0.25<br>InpRiskPercent=0.25<br>InpUseDailyLossRiskScaling=true<br>InpUseMonthlyLossRiskScaling=true<br>InpUseWeeklyLossRiskScaling=true<br>InpWeeklyLossRiskStartFraction=0.25 |
| 29 | `lowatr_exit_loss_scale_r30` | Loss-scaling at 0.30% risk. | InpDailyLossRiskStartFraction=0.25<br>InpMinDailyLossRiskMultiplier=0.35<br>InpMinMonthlyLossRiskMultiplier=0.35<br>InpMinWeeklyLossRiskMultiplier=0.35<br>InpMonthlyLossRiskStartFraction=0.25<br>InpRiskPercent=0.30<br>InpUseDailyLossRiskScaling=true<br>InpUseMonthlyLossRiskScaling=true<br>InpUseWeeklyLossRiskScaling=true<br>InpWeeklyLossRiskStartFraction=0.25 |
| 30 | `lowatr_exit_loss_scale_r35` | Loss-scaling at 0.35% risk. | InpDailyLossRiskStartFraction=0.25<br>InpMinDailyLossRiskMultiplier=0.35<br>InpMinMonthlyLossRiskMultiplier=0.35<br>InpMinWeeklyLossRiskMultiplier=0.35<br>InpMonthlyLossRiskStartFraction=0.25<br>InpRiskPercent=0.35<br>InpUseDailyLossRiskScaling=true<br>InpUseMonthlyLossRiskScaling=true<br>InpUseWeeklyLossRiskScaling=true<br>InpWeeklyLossRiskStartFraction=0.25 |
| 31 | `lowatr_exit_loss_scale_r40` | Loss-scaling at 0.40% risk. | InpDailyLossRiskStartFraction=0.25<br>InpMinDailyLossRiskMultiplier=0.35<br>InpMinMonthlyLossRiskMultiplier=0.35<br>InpMinWeeklyLossRiskMultiplier=0.35<br>InpMonthlyLossRiskStartFraction=0.25<br>InpRiskPercent=0.40<br>InpUseDailyLossRiskScaling=true<br>InpUseMonthlyLossRiskScaling=true<br>InpUseWeeklyLossRiskScaling=true<br>InpWeeklyLossRiskStartFraction=0.25 |
| 32 | `lowatr_exit_loss_scale_r50` | Loss-scaling at 0.50% risk. | InpDailyLossRiskStartFraction=0.25<br>InpMinDailyLossRiskMultiplier=0.35<br>InpMinMonthlyLossRiskMultiplier=0.35<br>InpMinWeeklyLossRiskMultiplier=0.35<br>InpMonthlyLossRiskStartFraction=0.25<br>InpRiskPercent=0.50<br>InpUseDailyLossRiskScaling=true<br>InpUseMonthlyLossRiskScaling=true<br>InpUseWeeklyLossRiskScaling=true<br>InpWeeklyLossRiskStartFraction=0.25 |

## Files

- Queue manifest: `outputs\LOWATR_EXIT_SWEEP_QUEUE.csv`
- Runner manifest: `outputs\LOWATR_EXIT_SWEEP_PACKAGE_MANIFEST.csv`
- Package dir: `outputs\lowatr_exit_sweep_package`
