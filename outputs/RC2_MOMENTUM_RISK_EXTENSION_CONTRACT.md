# RC2 Momentum-Risk Extension Model1 Contract

Date frozen: 2026-07-17, before this package was run.

## Hypothesis

The validated portfolio requests `0.45%` risk for 48 reversion trades but only `0.15%` for 314 momentum trades, leaving `0.15` percentage points unused under the existing `0.75%` shared open-risk cap. Test whether a bounded increase in momentum requested risk produces a stable profit increase without changing strategy behavior or exceeding the released cap.

## Frozen Identity

- RC2 source: `work/Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5`
- Source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Base Model4 profile SHA-256: `5C45D578B42609D3792EA692D5A13A9E0D90C8C14D0376F807E6F6079EC6B827`
- Reversion requested risk: fixed at `0.45%`
- Shared open-risk cap: fixed at `0.75%`
- Starting balance: `$10,000`
- Model: Model1 fast rejection screen

Signals, exits, stops, targets, sessions, dates, account protections, funding checks, dedicated-account checks, and real-account locks remain unchanged. Only `InpMORiskPercent` varies.

## Frozen Neighborhood

| Profile | Momentum risk | Role |
|---|---:|---|
| `mre_mo015_control` | 0.150% | exact control |
| `mre_mo0175` | 0.175% | lower neighbor |
| `mre_mo020_center` | 0.200% | nominated center |
| `mre_mo0225` | 0.225% | upper neighbor |
| `mre_mo025` | 0.250% | shape check |
| `mre_mo0275` | 0.275% | shape check |
| `mre_mo030` | 0.300% | cap boundary |

Each profile is tested on restarted 2015-2018, 2019-2022, and 2023-2026 YTD windows plus continuous 2015-2026 YTD.

## Model1 Gate

The `0.20%` center advances only if:

1. Every report parses with the exact embedded source and profile identity.
2. All three broad windows are profitable and each broad-window net is at least its control net.
3. Continuous net improves at least `10%` over control.
4. Continuous PF is at least `1.50`, trades are at least `350`, maximum equity drawdown is at most `4.00%`, and recovery is at least `4.00`.
5. Both adjacent profiles (`0.175%` and `0.225%`) remain profitable in every broad era, improve continuous net by at least `5%`, keep PF at least `1.45`, drawdown at most `4.25%`, and recovery at least `3.75`.

The higher points describe the response curve only; they cannot replace the nominated center after results are known. A pass permits exact Model4 tests for only the center and its two neighbors. It does not change the released, operational, or forward candidate and does not authorize real-money trading.
