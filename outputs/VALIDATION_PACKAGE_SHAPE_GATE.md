# Validation Package Shape Gate

Generated offline. This does not launch MT5, MetaEditor, GitHub Actions, Git, or GitHub CLI.

## Purpose

The validation decision gate now rejects malformed or partial validation packages before profit metrics can be trusted. A reduced package with only profitable returned rows is not enough to pass.

## Required Shape

The shared validation analyzer requires the staged validation manifest to contain exactly `53` rows:

| Phase | Required Rows |
| --- | ---: |
| `phase0_fast_model1` | `4` |
| `phase1_exact_realtick` | `4` |
| `phase2_realtick_quarterly` | `11` |
| `phase3_realtick_monthly` | `31` |
| `phase4_stress_realtick` | `3` |

Broker-proxy evidence still separately requires `10` broker-proxy rows.

## Current Evidence

- Current conservative decision gate: `validation-package-shape` is `PASS`.
- Current actual shape: `rows=53/53; phase0_fast_model1=4/4; phase1_exact_realtick=4/4; phase2_realtick_quarterly=11/11; phase3_realtick_monthly=31/31; phase4_stress_realtick=3/3`.
- Smoke tests passed locally:
  - `MONEY_READY_VALIDATION_DECISION_SMOKE_PASS`
  - `TRADE_READY_CONSERVATIVE_VALIDATION_DECISION_SMOKE_PASS`

## Why It Matters

This prevents a profile from looking money-ready because only the easy or profitable windows were returned. Full validation still requires exported MT5 reports, full tester statistics, no red monthly/quarterly/stress/broker windows, continuous-return floors, drawdown efficiency, profit factor, expected payoff, Sharpe, win rate, loss-streak, and recovery-factor gates.
