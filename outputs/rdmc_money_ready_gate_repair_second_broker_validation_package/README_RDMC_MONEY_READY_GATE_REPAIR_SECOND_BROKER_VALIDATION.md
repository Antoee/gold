# RDMC Money-Ready Gate Repair Second-Broker Validation Package

Status: **PREREQUISITE LOCKED**

This package references the exact frozen source/profile and 18 Model4-only XAUUSD configs already stored in `outputs/rdmc_money_ready_gate_repair_package`; it does not duplicate those large artifacts. Do not run it until the primary executable gate and primary ledger stress both pass.

- Wave 1: two critical-year rejection tests.
- Wave 2: three disjoint broad eras plus continuous.
- Wave 3: 12 annual/YTD restart tests.
- Starting balance/currency: `10,000 USD`.
- Workers: one by default.
- Reports: place only identity-bound secondary reports in `reports_here`.

Before reports can be admitted, populate `outputs/RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_SPECIFICATION.csv` from the supplied template without publishing an account identifier or raw company/server name. The company fingerprint must differ from the frozen primary fingerprint.

When a wave is admitted and its reports/sidecars are present, run `python work/collect_rdmc_money_ready_gate_repair_second_broker_validation_results.py`. The collector rejects noncurrent waves, duplicate report extensions, changed identities, metric disagreement, mixed binaries, and account-number fields before refreshing the evaluator.

See `outputs/RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_CONTRACT.md` and `outputs/RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_DECISION.md` for the complete evidence boundary.

Successor evidence boundary: no report, result, broker specification, or pass from the older candidate is inherited.
