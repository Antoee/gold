# Micro Test Handoff

Fast first-pass validation for the top protected candidate against the current promoted baseline.

## Purpose

The full handoff is still the authority for promotion decisions. This micro handoff only answers whether the top candidate deserves more tester time.

## Included Files

- `HANDOFF_MANIFEST.csv`
- `configs/001_tp38_sl18_stress_2024_Q1_phase1_fast_triage.ini`
- `configs/002_baseline_promoted_stress_2024_Q1_phase1_fast_triage.ini`
- `configs/003_tp38_sl18_stress_2024_Q3_phase1_fast_triage.ini`
- `configs/004_baseline_promoted_stress_2024_Q3_phase1_fast_triage.ini`
- `configs/005_tp38_sl18_stress_2025_Q2_phase1_fast_triage.ini`
- `configs/006_baseline_promoted_stress_2025_Q2_phase1_fast_triage.ini`
- `configs/007_tp38_sl18_stress_2025_Q3_phase1_fast_triage.ini`
- `configs/008_baseline_promoted_stress_2025_Q3_phase1_fast_triage.ini`

Each config is non-visual, uses XAUUSD M15, writes a deterministic report name, and shuts MT5 down after the test.

## Prerequisite

The MT5 terminal used for testing must already have `Professional_XAUUSD_EA.ex5` installed in the expected Experts folder. The configs reference that compiled expert directly.

## Test Pairing

Each stress window runs the candidate and baseline back-to-back:

- tp38_sl18 vs baseline_promoted on 2024_Q1
- tp38_sl18 vs baseline_promoted on 2024_Q3
- tp38_sl18 vs baseline_promoted on 2025_Q2
- tp38_sl18 vs baseline_promoted on 2025_Q3

## Decision Rule

If the protected candidate loses any paired stress window, keep the current promoted profile and deprioritize that candidate.

If it matches or improves every paired stress window, continue to the full 24-config handoff and phase-2 real ticks before considering promotion.

## Local Safety

This handoff does not require launching MT5 while the PC is in normal use. Use it only during a controlled tester window or on a separate machine/VM that will not steal focus.
