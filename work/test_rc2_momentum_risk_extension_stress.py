#!/usr/bin/env python3
"""Regression checks for the frozen RC2 MRE cost and bootstrap stress evidence."""

from __future__ import annotations

import csv
import importlib.util
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "work" / "analyze_rc2_momentum_risk_extension_stress.py"
SPEC = importlib.util.spec_from_file_location("mre_stress", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Could not load stress analyzer")
MRE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MRE
SPEC.loader.exec_module(MRE)

trades = MRE.load_trades()
assert len(trades) == 362
assert round(sum(trade.profit for trade in trades), 2) == 1812.42
assert all(trade.initial_risk > 0 for trade in trades)

cost_rows = list(csv.DictReader(MRE.COST_CSV.open("r", encoding="utf-8-sig", newline="")))
mc_rows = list(csv.DictReader(MRE.MC_CSV.open("r", encoding="utf-8-sig", newline="")))
decision = list(csv.DictReader(MRE.DECISION_CSV.open("r", encoding="utf-8-sig", newline="")))
assert [row["Scenario"] for row in cost_rows] == ["base", "light", "moderate", "severe"]
assert [float(row["AddedCostRPerTrade"]) for row in cost_rows] == [0.0, 0.02, 0.05, 0.10]
assert float(cost_rows[0]["NetProfit"]) == 1812.42
assert [row["Scenario"] for row in mc_rows] == ["standard", "severe"]
assert all(int(row["Trials"]) == 10_000 for row in mc_rows)
assert all(row["BootstrapWithReplacement"] == "True" for row in mc_rows)
assert len(decision) == 1
expected_status = (
    "STRESS_GATE_PASSED"
    if all(row["GatePass"] == "True" for row in cost_rows + mc_rows)
    else "STRESS_GATE_FAILED"
)
assert decision[0]["Status"] == expected_status
assert decision[0]["LedgerSha256"] == MRE.EXPECTED_LEDGER_SHA256
assert decision[0]["SourceSha256"] == MRE.EXPECTED_SOURCE_SHA256
assert decision[0]["ProfileSha256"] == MRE.EXPECTED_PROFILE_SHA256
assert decision[0]["ForwardCandidateChanged"] == "False"
print(f"RC2_MOMENTUM_RISK_EXTENSION_STRESS_TEST_PASS status={expected_status}")
