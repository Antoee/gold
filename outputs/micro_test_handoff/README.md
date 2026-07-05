# Micro Test Handoff

Fast first-pass validation for the top protected candidate against the current promoted baseline.

## Purpose

The full handoff is still the authority for promotion decisions. This micro handoff only answers whether the top candidate deserves more tester time.

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
