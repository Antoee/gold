# RDMC Executable Ledger Stress Contract

Status: **FROZEN ANALYZER / AWAITING EXECUTABLE MT5 GATE / NOT PROMOTED**

This stage may assess only the executable combined candidate. It cannot use the post-hoc component ledger, a legacy report, or a report outside the frozen 24-row gate.

## Admission Identity

- Executable-gate status must be `EXECUTABLE_MT5_GATE_PASS_PENDING_LEDGER_STRESS` with all 24 canonical result rows present.
- Source SHA-256: `EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F`
- Profile SHA-256: `746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883`
- Manifest SHA-256: `4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A`
- Exactly one wave-4, continuous, Model4 result and its adjacent schema-versioned identity sidecar are admitted.
- Report name, byte count, report hash, config hash, source hash, shared portable-binary hash, and UTC creation time must all match. The frozen source identity must also appear inside the report.

While admission is closed, the analyzer deletes only its three exact stale ledger/stress output paths and writes `AWAITING_EXECUTABLE_MT5_GATE`. It cannot infer trades or claim a stress pass.

## Ledger Rules

- Structured HTML cells are parsed by normalized column headers; report tables are not extracted with regular-expression slicing.
- Every XAUUSD entry and exit deal must exact-match a filled order with matching side, symbol, volume, and chronological open time.
- Every entry must retain a positive initial stop on the protective side. Initial cash risk is derived from fill-to-stop distance, volume, and the frozen XAUUSD contract size.
- Deal gross profit must agree with the entry/exit price path to within two cents.
- Commission, optional fee, and swap are included in net profit.
- Reversals, overlapping entries, partial or oversized exits, and an open lifecycle at report end fail closed.
- Parsed trade count and net must match both the report summary and canonical gate result; report profit factor must match the canonical result.

The frozen profile permits one account position and disables partial/scale-in features, so unsupported lifecycle patterns are evidence failures rather than silently approximated trades.

## Deterministic Cost Gate

| Scenario | Added execution cost | Gate |
|---|---:|---|
| Base | `0.00R/trade` | Positive net and all three broad eras positive |
| Light | `0.02R/trade` | Positive net and all three broad eras positive |
| Moderate | `0.05R/trade` | Positive net, PF at least `1.20`, closed-trade DD at most `6%`, all eras positive |
| Severe | `0.10R/trade` | Positive net, PF at least `1.10`, closed-trade DD at most `8%`, all eras positive |

The broad eras are 2015-2018, 2019-2022, and 2023-2026 YTD. Every row must pass.

## Order-Aware Monte Carlo

- Trials: `10,000` per scenario with frozen deterministic seeds.
- Samplers: circular moving blocks of 8, 16, and 24 trades, plus whole-calendar-year resampling.
- Standard stress randomizes up to `0.04R` slippage, `0.06R` delay, `0.08R` spread shock at 10% probability, and misses 5% of winners.
- Severe stress randomizes up to `0.08R` slippage, `0.12R` delay, `0.16R` spread shock at 20% probability, and misses 10% of winners.
- Standard requires positive P05 net, median PF at least `1.25`, P95 closed-trade DD at most `6%`, red trials at most `5%`, and P95 consecutive losses at most 14.
- Severe requires positive P05 net, median PF at least `1.10`, P95 closed-trade DD at most `8%`, red trials at most `5%`, and P95 consecutive losses at most 16.

All eight sampler/stress rows must pass.

## Hard Boundary

- Monte Carlo drawdown is a closed-trade path statistic. Identity-bound MT5 reports remain authoritative for intratrade equity drawdown.
- A pass is trade-level executable evidence, not proof of future profit and not real-money approval.
- The preregistered `RDMC_SECOND_BROKER_VALIDATION_CONTRACT.md` must pass on genuinely distinct broker data; proxy cost inputs cannot substitute for it.
- Valid forward evidence on the frozen `$10,000` demo contract remains mandatory.
- The registered forward candidate, source/profile/binary/run identity, and real-account lock do not change through this analyzer.
