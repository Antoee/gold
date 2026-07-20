# Three-Lane Reversion Protected Winner Add-On Discovery Decision

**Decision: REJECTED IN DISCOVERY. No holdout, Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `18 / 18` parsed with exact source/binary identity valid
- Attempts: `19`; identity-only retries: `1`
- Exact source SHA-256: `1C28EC85646409F3C82E584AD2DA66E6A4FA936CEFAE142D09846694E5369FE2`
- Exact EX5 SHA-256: `E4F17841780D7C6DCB96FCE88AFAF17626958571AD3D4844B9C55BC804070CFD`
- Mechanism: strong-signal reversion winner only, one add-on maximum, primary stop locked first, locked-profit coverage, minimum remaining reward, and account-wide risk reconciliation
- Frozen risk context: strong-reversion requested risk `0.70%`, adaptive-trend risk `0.15%`, add-on risk `0.10%` to `0.20%`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | Add-ons | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Control (disabled) | +$860.86 | +$330.02 | +$1,191.69 | 1.89%/yr | 1.77 | 265 | 0 | 1.02% | 10.5778 | 11.6863 |
| Trigger 0.75R | +$860.86 | +$330.02 | +$1,191.69 | 1.89%/yr | 1.77 | 265 | 0 | 1.02% | 10.5778 | 11.6863 |
| Center 1.00R / 0.15% | +$860.86 | +$330.02 | +$1,191.69 | 1.89%/yr | 1.77 | 265 | 0 | 1.02% | 10.5778 | 11.6863 |
| Trigger 1.25R | +$845.52 | +$215.16 | +$1,088.37 | 1.74%/yr | 1.69 | 269 | 4 | 1.02% | 9.6607 | 10.6667 |
| Risk 0.10% | +$747.67 | +$214.60 | +$979.05 | 1.57%/yr | 1.64 | 269 | 5 | 1.03% | 8.6903 | 9.5049 |
| Risk 0.20% | +$860.86 | +$330.02 | +$1,191.69 | 1.89%/yr | 1.77 | 265 | 0 | 1.02% | 10.5778 | 11.6863 |

## Frozen Gate

- Every report profitable: `True` (PASS)
- Center no worse than control in every window: `True` (PASS)
- Center growth gate: `False` (FAIL)
- Center CAGR gate: `False` (FAIL)
- Center PF/recovery/return-DD gate: `True` (PASS)
- Center drawdown gate: `True` (PASS)
- Center activity gate: `False` (FAIL)
- Trigger 0.75R neighbor gate: `False` (FAIL)
- Trigger 1.25R neighbor gate: `False` (FAIL)
- Risk 0.10% neighbor gate: `False` (FAIL)
- Risk 0.20% neighbor gate: `False` (FAIL)

## Interpretation

The center, trigger-0.75R, and risk-0.20% variants produced zero add-ons and were behaviorally identical to the control at `+$1,191.69` continuous net. The active trigger-1.25R variant opened `4` add-ons but reduced net to `+$1,088.37` and PF to `1.69`. The active risk-0.10% variant opened `5` add-ons and fell further to `+$979.05` with PF `1.64`.

The protected winner add-on did not improve the pre-2021 portfolio. Active variants materially degraded payoff, so the family is rejected without post-result trigger, lock, risk, coverage, or reward retuning. The 2021-26 holdout and Model 4 remain unopened, and ATB150 remains the historical champion.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
