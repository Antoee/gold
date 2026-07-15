# Broker-Accurate Risk Sizing and Sweep Rejection

## Finding

The previous XAUUSD lot-sizing path used stop distance, tick size, and tick value directly. On the tested MetaQuotes-Demo XAUUSD specification, that calculation did not match the order's realized entry-to-stop P/L. A May 2026 stop lost `-$495.90` from a balance near `$3,411.73`, far beyond the profile's intended risk.

## Change

Source hash `3C738B730A47A089ECE11A53EC9E726DE2E64B63E53866B9731253C5035A114C` replaces the raw calculation with `OrderCalcProfit` and uses the same broker-aware risk value for:

- initial lot sizing;
- open-position risk;
- maximum exposure checks;
- scale-in risk checks;
- historical R calculations.

The source also adds `InpAllowStandaloneLiquiditySweepEntry`, allowing liquidity sweeps to remain confirmations while preventing them from opening a trade by themselves.

Static preflight now requires the `OrderCalcProfit` sizing path and rejects reintroduction of the obsolete raw helper. Hidden MetaEditor compile completed with `0 errors, 0 warnings`.

## Result

All `45 / 45` Model1 reports parsed. Corrected sizing cut the largest control loss to `-$9.18`, but no tested profile was profitable on the continuous 2019-2026 screen. Sweep-on lost `-$38.84`; sweep-off lost `-$1.34`. The sweep-off profile had six losing yearly windows even though 2024 alone made `+$21.37`.

The old high-profit evidence is retained for research history, but it is superseded as live-readiness evidence. No current profile is approved for real-money use.

## Decision

Accept the safety implementation. Reject all five tested profiles. Continue with controlled DGF activity tests, then require real-tick, stress, broker-variation, and frozen forward evidence for any actual survivor.
