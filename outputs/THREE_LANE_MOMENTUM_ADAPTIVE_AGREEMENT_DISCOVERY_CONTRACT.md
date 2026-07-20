# Momentum / Adaptive Agreement Allocation Contract

Frozen before compiling or testing the new code path.

## Premise

The exact provisional leader ledger contains 19 momentum entries opened after an adaptive-trend position was already open in the same direction. Those momentum trades made +$179.27 at PF 5.12 and were profitable in 2015-2018, 2019-2022, and 2023-2026.

This architecture was selected after inspecting the complete historical ledger. The experiment is data-informed and has no pristine historical holdout. Any passing result remains provisional and requires a new forward sample; 2021-2026 may be used only as architecture-seen confirmation.

## Frozen Code Change

- Derive one research source from exact leader source SHA-256 `C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91`.
- Add a default-off momentum agreement allocation input.
- When an otherwise-valid momentum entry is about to size, inspect only already-open positions on the same symbol.
- Agreement is true only when an exact `InpATBMagicNumber` adaptive-trend position is already open in the proposed momentum direction.
- If agreement is true and the feature is enabled, use the frozen agreement risk input instead of base momentum risk.
- Use the selected risk consistently for broker-valued sizing and post-fill reconciliation.
- Add no signal, entry, stop, target, close, stop-modification, retry, martingale, grid, averaging-down, or recovery-sizing path.
- Preserve minimum-lot refusal, exact ownership, maximum position count, post-fill reconciliation, portfolio loss limits, initial-capital contract, and real-account lock.
- The runtime `0.75%` account-wide open-risk check remains authoritative and may refuse an agreement entry.

## Discovery Matrix

- XAUUSD M15, MT5 Model 1, `$10,000` restart.
- Windows: 2015-2018, 2019-2020, and continuous 2015-2020.
- Disabled control: base momentum risk `0.15%`.
- Conservative agreement risk: `0.20%`.
- Lower neighbor: `0.225%`.
- Frozen center: `0.25%`.
- Upper neighbor: `0.275%`.
- Total: 15 exact configurations on one source and EX5 identity.

## Frozen Gate

The center may advance only if all conditions pass:

1. Every center window is profitable and both disjoint eras are no worse than control.
2. Continuous center net is at least 3% above control.
3. Continuous CAGR is at least 0.05 percentage point above control.
4. Profit factor, recovery factor, and return/drawdown are no worse than control.
5. Maximum drawdown is at most 1.20% and no more than 0.10 point above control.
6. Center retains at least control trades minus two.
7. At least two of the three non-center enabled rows are no worse in both disjoint eras, improve continuous net by at least 2%, retain at least 97% of control PF/recovery/return-to-drawdown, keep drawdown at or below 1.25%, and retain at least control trades minus two.
8. Exact source, EX5, config, report, and report-sidecar identities pass; compile has zero errors and zero warnings.

If any condition fails, stop before architecture-seen 2021-2026 confirmation and Model 4. Do not move the center, add thresholds, change the agreement definition, or rescue the family after observing results.

## Escalation Boundary

A discovery pass permits one frozen architecture-seen 2021-2026 confirmation. A historical promotion additionally requires exact Model 4 broad/continuous, annual restart, hard-risk, cost-stress, and clustered Monte Carlo gates. Because the architecture was selected on the full ledger, even a complete historical pass cannot create live approval. A correctly capitalized second-broker test and a new forward demo sample remain mandatory.

The registered forward candidate, its source/profile/binary identity, evidence logs, and real-account lock remain unchanged throughout this research.
