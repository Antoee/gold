#!/usr/bin/env python3
"""Regression checks for the post-hoc RDMC collision stress triage."""

from __future__ import annotations

import csv
import importlib.util
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "work" / "analyze_rdmc_diversified_repair_collision_stress.py"
SPEC = importlib.util.spec_from_file_location("rdmc_collision_stress", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Could not load RDMC collision stress analyzer")
STRESS = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = STRESS
SPEC.loader.exec_module(STRESS)


def rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


trades = STRESS.load_trades()
assert len(trades) == 368
assert round(sum(trade.profit for trade in trades), 2) == 2067.64
assert all(trade.initial_risk > 0.0 for trade in trades)
assert STRESS.sha256(STRESS.LEDGER) == STRESS.EXPECTED_LEDGER_SHA256
assert STRESS.sha256(STRESS.SUMMARY) == STRESS.EXPECTED_SUMMARY_SHA256
assert STRESS.sha256(STRESS.FROZEN_METHOD) == STRESS.EXPECTED_METHOD_SHA256
assert STRESS.sha256(STRESS.TARGET_SOURCE) == STRESS.EXPECTED_TARGET_SOURCE_SHA256
assert STRESS.sha256(STRESS.TARGET_PROFILE) == STRESS.EXPECTED_TARGET_PROFILE_SHA256

cost = rows(STRESS.COST_CSV)
cost_windows = rows(STRESS.COST_WINDOW_CSV)
monte = rows(STRESS.MC_CSV)
decision = rows(STRESS.DECISION_CSV)
document = STRESS.DECISION_MD.read_text(encoding="ascii")

assert [row["Scenario"] for row in cost] == ["base", "light", "moderate", "severe"]
assert [float(row["AddedCostRPerTrade"]) for row in cost] == [0.0, 0.02, 0.05, 0.10]
assert float(cost[0]["NetProfit"]) == 2067.64
assert len(cost_windows) == 48
assert {row["Window"] for row in cost_windows} == set(STRESS.WINDOWS)
assert [row["Scenario"] for row in monte] == ["standard", "severe"]
assert all(int(row["Trials"]) == 10_000 for row in monte)
assert all(row["BootstrapWithReplacement"] == "True" for row in monte)
assert len(decision) == 1

cost_pass = all(row["GatePass"] == "True" for row in cost)
monte_pass = all(row["GatePass"] == "True" for row in monte)
light = next(row for row in cost if row["Scenario"] == "light")
moderate = next(row for row in cost if row["Scenario"] == "moderate")
severe = next(row for row in cost if row["Scenario"] == "severe")
window_pass = int(light["PositiveWindows"]) == 12
expected_status = "POSTHOC_STRESS_TRIAGE_PASS" if cost_pass and monte_pass and window_pass else "POSTHOC_STRESS_TRIAGE_FAIL"
assert decision[0]["Status"] == expected_status
assert decision[0]["CostGatePass"] == str(cost_pass)
assert decision[0]["MonteCarloGatePass"] == str(monte_pass)
assert decision[0]["LightCostAllWindowsPositive"] == str(window_pass)
assert decision[0]["ModerateCostPositiveWindows"] == "12"
assert decision[0]["SevereCostPositiveWindows"] == "10"
assert decision[0]["SevereCostNoRedWindowGate"] == "False"
assert decision[0]["PostHocOnly"] == "True"
assert decision[0]["ForwardCandidateChanged"] == "False"
assert decision[0]["RealAccountApproved"] == "False"
assert decision[0]["TargetCompileStatus"] == "NOT_RUN_LOCAL_LOCK_ACTIVE"
assert decision[0]["TargetBacktestStatus"] == "NOT_RUN_LOCAL_LOCK_ACTIVE"
assert decision[0]["CollisionLedgerSha256"] == STRESS.EXPECTED_LEDGER_SHA256
assert decision[0]["FrozenStressMethodSha256"] == STRESS.EXPECTED_METHOD_SHA256
assert decision[0]["TargetSourceSha256"] == STRESS.EXPECTED_TARGET_SOURCE_SHA256
assert decision[0]["TargetProfileSha256"] == STRESS.EXPECTED_TARGET_PROFILE_SHA256
assert int(moderate["PositiveWindows"]) == 12
assert int(severe["PositiveWindows"]) == 10
severe_windows = {row["Window"]: float(row["NetProfit"]) for row in cost_windows if row["Scenario"] == "severe"}
assert severe_windows["2019"] == -0.06
assert severe_windows["2022"] == -7.98
assert float(monte[0]["P05NetProfit"]) == 757.31
assert float(monte[1]["P05NetProfit"]) == 255.92
assert float(monte[1]["RedTrialPercent"]) == 1.49
assert "post-hoc triage, not executable MT5 evidence or a new best" in document
assert "The target source is uncompiled and untested" in document
assert "cannot change the registered forward candidate" in document
assert "approve real-account trading" in document
assert "severe cost falls to `10/12`" in document
assert "github_pat_" not in document

print(
    f"RDMC_DIVERSIFIED_REPAIR_COLLISION_STRESS_TEST_PASS status={expected_status} "
    f"cost={cost_pass} monte={monte_pass} light_windows={light['PositiveWindows']}/12"
)
