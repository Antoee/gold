# RDMC Diversified Repair Executable Gate Decision

**Status: EXECUTABLE_GATE_REJECTED_WAVE_01. No new best, forward substitution, or real-money approval.**

- Current wave: `1`
- Parsed reports supplied: `2/24`
- Passed row gates: `0/24`
- Launch locked: `True`
- Next action: `REWRITE_ENTRY_OR_REGIME_LOGIC_THEN_RESTART_WAVE_01`
- Manifest SHA-256: `4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A`
- Source SHA-256: `EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F`
- Profile SHA-256: `746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883`

## Failed Wave 1

| Window | Net | PF | Trades | Lane attribution |
|---|---:|---:|---:|---|
| 2019 | -$17.35 | 0.00 | 3 | all three momentum trades lost |
| 2022 | -$34.84 | 0.41 | 7 | momentum remained the main loss; reversion added one winner and one loser |

The aggregate two-window score was `-$52.19`. Model 1 was reject-only, so all remaining broad and Model 4 rows were closed. Subsequent 2015-2022 feature telemetry found no compact one- or two-feature momentum rule that kept all eight portfolio years positive with the frozen activity floors. The next admissible action was therefore a strategy-engine rewrite, not parameter tuning.

## Evidence Boundary

- No report is inferred from a config, static check, or post-hoc component ledger.
- Missing or unparsed reports keep the current wave pending; a failed completed wave rejects later testing.
- Model1 can reject only. Model4 waves must pass before executable trade-ledger stress is admitted.
- Even a five-wave pass is not money-ready: cost stress, order-aware Monte Carlo, broker variation, and valid forward evidence remain required.
- The registered forward candidate and real-account safety lock remain unchanged.
