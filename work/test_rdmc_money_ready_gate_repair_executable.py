#!/usr/bin/env python3
"""Regression checks for the staged RDMC executable-gate evaluator."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "work" / "evaluate_rdmc_money_ready_gate_repair_executable.py"
SPEC = importlib.util.spec_from_file_location("rdmc_executable_gate", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Could not load executable-gate evaluator")
GATE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = GATE
SPEC.loader.exec_module(GATE)


manifest = GATE.load_manifest()
assert len(manifest) == 24
assert [sum(int(row["Wave"]) == wave for row in manifest) for wave in range(1, 6)] == [2, 4, 2, 4, 12]
assert sum(int(row["Model"]) == 1 for row in manifest) == 6
assert sum(int(row["Model"]) == 4 for row in manifest) == 18
assert manifest[0]["Window"] == "2019"
assert manifest[1]["Window"] == "2022"


def passing_result(row: dict[str, str]) -> dict[str, str]:
    net = 100.0
    if row["Role"] == "continuous":
        net = 1200.0
    return {
        "ExpectedReportName": row["ExpectedReportName"],
        "Status": "PARSED",
        "NetProfit": str(net),
        "ProfitFactor": str(float(row["MinProfitFactor"]) + 0.25),
        "TotalTrades": str(int(row["MinTrades"]) + 20),
        "MaxDrawdownPercent": str(max(0.1, float(row["MaxDrawdownPercent"]) / 2.0)),
        "RecoveryFactor": str(float(row["MinRecoveryFactor"]) + 1.0),
        "CagrPercent": str(float(row["MinCagrPercent"]) + 0.5),
    }


all_pass = [passing_result(row) for row in manifest]

decision, details = GATE.evaluate_gate(manifest, [], launch_locked=True)
assert decision["Status"] == "LOCKED_AWAITING_WAVE_01_REPORTS"
assert decision["CurrentWave"] == 1
assert len(details) == 2

wave1 = [result for result, row in zip(all_pass, manifest) if int(row["Wave"]) == 1]
decision, _ = GATE.evaluate_gate(manifest, wave1, launch_locked=False)
assert decision["Status"] == "AWAITING_WAVE_02_REPORTS"
assert decision["CurrentWave"] == 2

wave1_loss = [dict(row) for row in wave1]
wave1_loss[0]["NetProfit"] = "-0.01"
decision, details = GATE.evaluate_gate(manifest, wave1_loss, launch_locked=False)
assert decision["Status"] == "EXECUTABLE_GATE_REJECTED_WAVE_01"
assert decision["TerminalRejection"] is True
assert any("NetProfit" in str(row["Reasons"]) for row in details)

decision, details = GATE.evaluate_gate(manifest, all_pass, launch_locked=False)
assert decision["Status"] == "EXECUTABLE_MT5_GATE_PASS_PENDING_LEDGER_STRESS"
assert decision["ExecutableGatePass"] is True
assert decision["PassedRows"] == 24
assert decision["AnnualToContinuousNetRatio"] == 1.0
assert details[-1]["ExpectedReportName"] == "annual_to_continuous_consistency"
assert details[-1]["GatePass"] is True

divergent = [dict(row) for row in all_pass]
for result, row in zip(divergent, manifest):
    if int(row["Wave"]) == 5:
        result["NetProfit"] = "200"
decision, details = GATE.evaluate_gate(manifest, divergent, launch_locked=False)
assert decision["Status"] == "EXECUTABLE_GATE_REJECTED_WAVE_05_CONSISTENCY"
assert decision["AnnualToContinuousNetRatio"] == 2.0
assert details[-1]["GatePass"] is False

missing_metric = [dict(row) for row in wave1]
missing_metric[0]["ProfitFactor"] = ""
decision, details = GATE.evaluate_gate(manifest, missing_metric, launch_locked=False)
assert decision["Status"] == "EXECUTABLE_GATE_REJECTED_WAVE_01"
assert "ProfitFactor=MISSING" in str(details[0]["Reasons"])

print("RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_TEST_PASS cases=6 rows=24 waves=5")
