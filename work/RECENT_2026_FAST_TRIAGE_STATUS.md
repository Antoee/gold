# Recent 2026 Fast Triage Status

Updated: 2026-07-07 19:12:33 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added protected runner exit patience to the EA source and enabled it in the protected-aggression research profile. This is a better-logic profit-seeking feature, not just a bigger-risk setting: it gives already-protected winners more room only when the account is in house-money mode, trend-regime conditions are present, and current continuation structure still supports the trade.

Follow-up after reviewing the GitHub-visible `$866.59` / 2.5-year result: that result is not enough for the stated goal. Older local notes show higher historical figures when date-specific buy/sell blocks were used, but those are treated as curve-fit evidence and should not be promoted as live-ready. The next research change keeps the fast batch size unchanged while making `protected_aggression_breakout` more ambitious.

New inputs and logic:

- `InpUseRunnerExitPatience`
- `InpRunnerExitPatienceMinR`
- `InpRunnerExitPatienceMinMFER`
- `InpRunnerExitPatienceRequireHouseMoney`
- `InpRunnerExitPatienceRequireProtectedStop`
- `InpRunnerExitPatienceRequireTrendRegime`
- `InpRunnerExitPatienceRequireContinuation`
- `InpRunnerExitPatienceMFEGivebackMultiplier`
- `RunnerExitPatienceAllows(...)`
- `ContinuationStructureSupports(...)`
- Exit logs can add `runner patience MFE giveback exit ...` when a protected runner receives the wider giveback threshold.

The feature stretches the MFE giveback exit and blocks no-follow-through/stagnation exits only for positions that meet minimum current R, minimum max-favorable R, protected-stop, house-money, trend-regime, and continuation-structure checks. It still keeps the shared safety rails: starting-equity protection, close-on-risk-limit, max equity drawdown, max effective risk cap, open-risk cap, protected-floor gates, house-money gates, spread/cost/margin guards, and no martingale/grid/averaging down.

Protected-aggression upside tuning now applies after shared conservative defaults so it is not overwritten:

- `InpMinimumEntryScore=5`
- `InpBreakoutContinuationMinScore=6`
- `InpBreakoutContinuationRequireRegime=false`
- `InpTakeProfitATRMultiplier=5.50`
- `InpMinRiskReward=1.20`
- `InpMFEGivebackStartR=1.00`
- `InpMFEGivebackMaxGivebackR=0.90`
- `InpMFEGivebackMinCloseR=0.20`
- `InpRunnerExitPatienceMinR=0.25`
- `InpRunnerExitPatienceMinMFER=0.75`
- `InpRunnerExitPatienceRequireTrendRegime=false`
- `InpRunnerExitPatienceMFEGivebackMultiplier=1.80`

## Fast Batch Impact

- Batch size remains 11 profiles / 33 runs.
- Estimated tester runtime remains about 11.55 minutes before platform overhead.
- `protected_aggression_breakout` now enables `InpUseBreakoutContinuationQuality=true`, `InpUseRunnerExitPatience=true`, and higher-upside TP/giveback settings.
- The batch still uses fast no-visual tester configs with `Model=2`, `Visual=0`, `ShutdownTerminal=1`, and `ReplaceReport=1`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `98BE545F7A4631A2BE793242D4A6EBFC8FFE3DACE52D1CFF63A2D6A298F6941A`
- `work\build_price_action_strategy_batch.ps1`: PASS, 11 profiles, 33 runs, estimated 11.55 minutes
- `work\test_open_risk_exposure_guard.ps1`: PASS
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_price_action_strategy_handoff.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 40 steps, 0 failed
- MT5-family process scan: empty
- Stop marker: present at `work\STOP_MT5_FOCUS_WATCHDOG`

## Latest Evidence

- `outputs\Professional_XAUUSD_EA.mq5`: `98BE545F7A4631A2BE793242D4A6EBFC8FFE3DACE52D1CFF63A2D6A298F6941A`
- `Professional_XAUUSD_EA.mq5`: `98BE545F7A4631A2BE793242D4A6EBFC8FFE3DACE52D1CFF63A2D6A298F6941A`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `98BE545F7A4631A2BE793242D4A6EBFC8FFE3DACE52D1CFF63A2D6A298F6941A`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `60A05717313664F656ED02F122FC7C1DCC06AB8C873C27489CDECC1DB50B64D0`
- `outputs\xauusd_micro_validation_package.zip`: `09C066A10B88368142D1ABC51BDA40B70B58CF2435AB0BC4269FFD5B5DB4FCCD`
- `work\build_price_action_strategy_batch.ps1`: `6C13090EC351B86E9378E7A7F2B7AE922CEFB7D0E8D290796B166FDA466C8506`
- `work\test_price_action_strategy_modules.ps1`: `070DC5FB98FD42F479AF5DE759038952D4322E3DCD29542F468E23B31844503C`
- `work\test_price_action_strategy_batch.ps1`: `AF6D6AF1D2BD2CB46F89509DDBE64C57BDB78510EBAE1AB10D157BBCA16F6A7B`
- `work\test_price_action_strategy_handoff.ps1`: `F8B5503E3B72DD32EDAA79630D758693E41E3E851D5B56ED75CC7820C80F9BBF`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `1BD59B253422253BF095B10B2146CD88406F7C2CC06D23FA1A79831947594BD1`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `F8C09D4E83EF47B0811BEACD5BB7E15CDC12178BF45D924886857AA9C180B1BE`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
