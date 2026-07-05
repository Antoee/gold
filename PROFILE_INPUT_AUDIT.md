# Profile Input Audit

Generated from the local EA source and active .set profiles. No MT5 process was launched.

- EA source: `outputs\Professional_XAUUSD_EA.mq5`
- Source inputs discovered: 130
- Critical inputs required per active profile: 35

## Profile Status

| Profile | Status | Inputs | Missing Critical | Duplicates | Unknown |
| --- | --- | ---: | --- | --- | --- |
| `ROBUST_BOS_SWEEP_PROFILE.set` | PASS | 35 |  |  |  |
| `CANDIDATE_RISK16_SL18_TP38_PROFILE.set` | PASS | 35 |  |  |  |
| `CANDIDATE_RISK16_SL16_TP38_PROFILE.set` | PASS | 35 |  |  |  |
| `CANDIDATE_RISK16_SL18_TP35_GIVEBACK_PROFILE.set` | PASS | 35 |  |  |  |

## Critical Input Values

| Input | ROBUST | SL18 TP38 | SL16 TP38 | Giveback |
| --- | ---: | ---: | ---: | ---: |
| `InpRiskPercent` | `1.60` | `1.60` | `1.60` | `1.60` |
| `InpUseDateBuyBlock` | `false` | `false` | `false` | `false` |
| `InpUseDateBuyBlock2` | `false` | `false` | `false` | `false` |
| `InpUseDateSellBlock` | `false` | `false` | `false` | `false` |
| `InpUseEMACrossEntry` | `false` | `false` | `false` | `false` |
| `InpUseMomentumCandle` | `false` | `false` | `false` | `false` |
| `InpUseEngulfing` | `false` | `false` | `false` | `false` |
| `InpUseBOS` | `true` | `true` | `true` | `true` |
| `InpUseLiquiditySweep` | `true` | `true` | `true` | `true` |
| `InpMinimumConfirmations` | `2` | `2` | `2` | `2` |
| `InpUseAdaptiveReverse` | `true` | `true` | `true` | `true` |
| `InpAdaptiveSlopeThresholdPts` | `500.0` | `500.0` | `500.0` | `500.0` |
| `InpMinRiskReward` | `1.50` | `1.50` | `1.50` | `1.50` |
| `InpStopATRMultiplier` | `1.80` | `1.80` | `1.60` | `1.80` |
| `InpTakeProfitATRMultiplier` | `3.50` | `3.80` | `3.80` | `3.50` |
| `InpUseBreakEven` | `false` | `false` | `false` | `false` |
| `InpUseATRTrailing` | `true` | `true` | `true` | `true` |
| `InpMaxDailyLossPercent` | `1.00` | `1.00` | `1.00` | `1.00` |
| `InpMaxWeeklyLossPercent` | `2.50` | `2.50` | `2.50` | `2.50` |
| `InpMaxMonthlyLossPercent` | `4.00` | `4.00` | `4.00` | `4.00` |
| `InpMaxEquityDrawdownPercent` | `0.00` | `0.00` | `0.00` | `0.00` |
| `InpUseProfitGivebackGuard` | `false` | `false` | `false` | `true` |
| `InpDailyProfitGivebackPercent` | `35.0` | `35.0` | `35.0` | `35.0` |
| `InpWeeklyProfitGivebackPercent` | `35.0` | `35.0` | `35.0` | `35.0` |
| `InpMonthlyProfitGivebackPercent` | `35.0` | `35.0` | `35.0` | `35.0` |
| `InpMinProfitToProtectPercent` | `0.50` | `0.50` | `0.50` | `0.50` |
| `InpShowDashboard` | `false` | `false` | `false` | `false` |
| `InpDashboardInTester` | `false` | `false` | `false` | `false` |
| `InpLogLevel` | `0` | `0` | `0` | `0` |
| `InpTesterFitnessMode` | `1` | `1` | `1` | `1` |
| `InpTesterMinTrades` | `5` | `5` | `5` | `5` |
| `InpTesterMaxDrawdownPercent` | `25.0` | `25.0` | `25.0` | `25.0` |
| `InpTesterMinProfitFactor` | `1.05` | `1.05` | `1.05` | `1.05` |
| `InpTesterDrawdownPenalty` | `2.0` | `2.0` | `2.0` | `2.0` |
| `InpTesterTradeCountPenalty` | `0.35` | `0.35` | `0.35` | `0.35` |

## Why This Matters

MT5 can reuse cached tester input values when a config omits inputs. This audit ensures the active promoted and queued profiles pin all critical risk, entry, exit, giveback, logging, and optimizer inputs before validation.
