# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional margin guard:

- `InpUseMarginGuard`
- `InpMinMarginLevelPercent`
- `InpMaxTradeMarginFreePercent`
- `MarginGuardAllows()` checks account margin level, free margin, and estimated required margin before sending an order.
- New entries can be blocked with `margin level`, `free margin`, `insufficient margin`, `margin calculation`, or `trade margin cap`.

This is an execution-risk module intended to prevent overcommitting margin during XAUUSD volatility and to keep risk controls aligned with actual account capacity.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables margin guard with min margin level `300%` and max trade margin `20%` of free margin.
- `pa_full_confluence` enables margin guard with min margin level `350%` and max trade margin `15%` of free margin.
- Generated configs confirmed the guard is enabled in those profiles and pinned disabled in other profiles.

## Quiet Validation Results

- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\sync_ea_source_artifacts.ps1`: PASS
- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `B6A98CBC372738C16FAF28F935C016F1FDFD622CCC480B83E5CA9BB1973416C3`
- `Professional_XAUUSD_EA.mq5`: `B6A98CBC372738C16FAF28F935C016F1FDFD622CCC480B83E5CA9BB1973416C3`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `F8AFB957A1CABCEB3560D3B04095C6003401CE6B32A1455BF943C33D5E2D9D54`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\price_action_strategy_handoff.zip`: `D57BD21C2F769C57FF1338A7774B7DDA0B5E179BDB457C8E2822804ED1302C73`
- `outputs\price_action_parallel_lanes.zip`: `90F202662130BBA9DD402676ACC12B90E3F60C16E568A8B6E5722A0B29E38614`
- `outputs\xauusd_micro_validation_package.zip`: `A156723E42068D82092CAA013B6221BF69390B6C5D390C68FCDE1B8EBDC8D66B`
- `work\test_price_action_strategy_modules.ps1`: `6BA18893D4B79C1ED06309EE82422799B47371459BFD3382A2882F4C7CF4BE4E`
- `work\test_price_action_strategy_batch.ps1`: `4B9B4747F2872AA3617E1804D5610FDB5709664D06F52635B5DF7F393697B0DC`
- `work\build_price_action_strategy_batch.ps1`: `2456D8CC3B45BA9E735B5A2BB1E72E330CA93C19D9294C74F2C0A5104FEB6717`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
