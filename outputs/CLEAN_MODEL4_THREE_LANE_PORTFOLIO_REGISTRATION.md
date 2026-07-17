# Clean Model4 Three-Lane Portfolio Registration

Registered on 2026-07-17 before calculating this screen.

## Hypothesis

The independently tested daily Donchian channel-exit stream may improve the current real-tick reversion-plus-momentum portfolio as a small, low-correlation diversifier. It is not expected to qualify by merely increasing gross risk. Each allocation is compared with an otherwise identical two-lane benchmark.

## Frozen Evidence

| Lane | File | SHA-256 |
|---|---|---|
| Daily Donchian | `outputs/DAILY_DONCHIAN_REALTICK_TRADES.csv` | `C93538E5BED6CDF1AA1AC93CCB209C54287EBBBBBF7A2DF487E3420F251013B9` |
| H1 Band/VWAP reversion | `outputs/H1_BAND_VWAP_DI_M12_COMPACT_MODEL4_TRADES.csv` | `E4FABDE5C1D1420FC437123F50C7D1D991511F4AB8E284DC2F84F732932EBA19` |
| E20 multiscale momentum | `outputs/MTSM_M126_E20_R200_MODEL4_TRADES.csv` | `1FD616E6E163AA1F020A146C8A94037D720D10FC22334A60574CCDE195F4668C` |

All three streams come from MT5 Model 4 real-tick reports. The screen is an exact chronological realized-R simulation, not a combined-EA backtest.

## Frozen Grid

- Donchian requested risk: `0.05%`, `0.10%`, `0.15%`
- Reversion requested risk: `0.35%`, `0.40%`, `0.45%`, `0.50%`
- Momentum requested risk: `0.10%`, `0.15%`, `0.20%`
- Rows: `36`
- Shared open-risk cap: `0.75%`
- Per-lane lifetime drawdown lock: `5.00%`
- Execution stress: `0.00R`, `0.05R`, and `0.10R` deducted from every closed trade
- Predeclared center: `dd_0.10_rv_0.45_mom_0.15`

## Row Gate

Every eligible row must:

1. Keep all three broad eras positive at base, `0.05R`, and `0.10R` stress.
2. Trigger no historical lane lock at any stress level.
3. Close at least 380 trades and add at least 30 trades over its identical two-lane benchmark.
4. Remain active in every calendar year.
5. Keep PF at or above `1.45`, `1.30`, and `1.20` across the three stress levels.
6. Keep risk-floor drawdown at or below `5%`, `6%`, and `7%` across the three stress levels.
7. Keep the maximum loss streak at or below `14`, `15`, and `16` trades.
8. Keep worst-year net at or above `-$150`, `-$200`, and `-$250`.
9. Keep the largest profitable-year contribution at or below `35%` of net.
10. Add at least `5%` base net, `3%` stressed-0.05R net, and no less stressed-0.10R net versus the identical two-lane allocation.
11. Match or improve base return divided by drawdown.
12. Add no red years at any stress level and worsen worst rolling 12-month net by no more than `$50`.

## Advance Gate

The center must pass its row gate, at least two of the three Donchian weights at the center reversion/momentum allocation must pass, and at least four of seven one-step structural neighbors must pass. Passing only authorizes implementation in a separate combined EA followed by schedule-fidelity, Model 1, Model 4, and cost validation. It does not replace the frozen forward demo or authorize real-money trading.
