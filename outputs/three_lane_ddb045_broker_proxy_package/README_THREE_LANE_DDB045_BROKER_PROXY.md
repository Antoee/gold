# Three-Lane DDB 0.45 Broker Proxy Package

Offline package only. This does not launch MT5.

- EA source hash: `45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90`
- Base profile hash: `2E02246D24250D71DEC59A42AD1D7DE793614EBECEB309A879FE873D8F886312`
- Configs: `5`
- Initial deposit: `10000` USD

## Purpose

These configs approximate broker variation by tightening spread, commission, slippage, and margin assumptions through EA inputs. They do not replace testing on another broker's actual XAUUSD contract specification.

## Profiles

- `three_lane_ddb045_broker_proxy_base`
- `three_lane_ddb045_broker_proxy_wide_spread`
- `three_lane_ddb045_broker_proxy_high_commission`
- `three_lane_ddb045_broker_proxy_tight_slippage`
- `three_lane_ddb045_broker_proxy_margin_pressure`
