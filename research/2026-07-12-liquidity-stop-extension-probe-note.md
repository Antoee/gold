# Liquidity-Stop Extension Probe

Date: 2026-07-12

## Decision

Rejected.

The current best profile already uses the base liquidity-aware structure stop. Additional stop extensions were tested and did not improve the profile.

Current stability-best remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

## Intent

The goal was to improve stop placement beyond the current base liquidity-aware structure stop by testing:

- Liquidity-cluster stop buffer extension
- Previous-day liquidity levels
- Liquidity-cluster extension plus liquidity-pocket stop shift

## Test Setup

- Model: `4` real ticks
- Windows: 12 weak / flat / guard months
- Configs: 48
- Source: compact tester source
- Hidden MT5 run: yes
- Safety audit after run: `PASS`, `39 / 39`

## Summary

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `lstop_cluster` | `12 / 12` | `3` | `9` | `+387.68` | `0` | `5` | `31.7511` |
| `lstop_cluster_pocket` | `12 / 12` | `3` | `9` | `+122.50` | `0` | `5` | `29.0642` |
| `lstop_prevday` | `12 / 12` | `2` | `10` | `-90.55` | `1` | `2` | `16.4294` |

## What Happened

The cluster and cluster+pocket variants mostly reduced existing winners:

- `2024_05`: current `+214.91`, cluster `+167.95`, cluster+pocket `+29.47`
- `2026_05`: current `+229.11`, cluster `+155.68`, cluster+pocket `+28.98`
- `2026_06`: unchanged at `+64.05`

The previous-day liquidity variant was worse:

- `2026_05`: `-154.60`
- `2026_06`: `+64.05`
- Total: `-90.55`

## Interpretation

The base liquidity-aware stop should stay active. Extra liquidity extensions are too defensive or misplaced for this sample: they either reduce position size / trade quality on winners or introduce a losing stop geometry.

This supports keeping the current structural-liquidity stop layer, but rejecting the extra cluster / previous-day / pocket extensions for now.

## Evidence Files

- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_RESULTS.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_SUMMARY.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_RUN.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_MANIFEST.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_COMPACT_AUDIT.csv`
