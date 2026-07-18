#!/usr/bin/env python3
"""Regression checks for the RDMC collision regime-stress triage."""

from __future__ import annotations

import csv
import importlib.util
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "work" / "analyze_rdmc_diversified_repair_collision_regime_stress.py"
SPEC = importlib.util.spec_from_file_location("rdmc_collision_regime_stress", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Could not load RDMC collision regime-stress analyzer")
REGIME = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = REGIME
SPEC.loader.exec_module(REGIME)


def rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


trades = REGIME.BASE.load_trades()
regime = rows(REGIME.REGIME_MC_CSV)
concentration = rows(REGIME.CONCENTRATION_CSV)
decision = rows(REGIME.DECISION_CSV)
document = REGIME.DECISION_MD.read_text(encoding="ascii")

assert len(trades) == 368
assert len(regime) == 8
assert len(concentration) == 4
assert len(decision) == 1
assert {row["Sampler"] for row in regime} == {item["name"] for item in REGIME.SAMPLERS}
assert {row["StressScenario"] for row in regime} == {"standard", "severe"}
assert all(int(row["Trials"]) == 10_000 for row in regime)
assert all(row["PreservesLocalOrder"] == "True" for row in regime)
assert all(float(row["MedianTradeCount"]) > 0.0 for row in regime)
assert all(float(row["MaxSlippageR"]) > 0.0 for row in regime)
assert all(float(row["MaxDelayR"]) > 0.0 for row in regime)
expected_p05 = {
    ("moving_block_08", "standard"): 824.05,
    ("moving_block_08", "severe"): 342.65,
    ("moving_block_16", "standard"): 796.17,
    ("moving_block_16", "severe"): 305.18,
    ("moving_block_24", "standard"): 778.95,
    ("moving_block_24", "severe"): 279.20,
    ("whole_window", "standard"): 1053.55,
    ("whole_window", "severe"): 523.89,
}
assert {
    (row["Sampler"], row["StressScenario"]): float(row["P05NetProfit"])
    for row in regime
} == expected_p05
assert max(float(row["RedTrialPercent"]) for row in regime) == 0.86
assert sum(int(row["Trades"]) for row in concentration) == len(trades)
assert round(sum(float(row["NetProfit"]) for row in concentration), 2) == 2067.64
assert round(sum(float(row["NetSharePercent"]) for row in concentration), 2) == 100.0
assert round(sum(float(row["RiskSharePercent"]) for row in concentration), 2) == 100.0
assert sum(row["IsLargestNetContributor"] == "True" for row in concentration) == 1
assert sum(row["IsLargestRiskContributor"] == "True" for row in concentration) == 1

regime_pass = all(row["GatePass"] == "True" for row in regime)
positive_components = sum(float(row["NetProfit"]) > 0.0 for row in concentration)
largest_net = next(row for row in concentration if row["IsLargestNetContributor"] == "True")
largest_risk = next(row for row in concentration if row["IsLargestRiskContributor"] == "True")
assert largest_net["Component"] == "RRO_DI12_CAP12_CONTINUOUS"
assert float(largest_net["NetSharePercent"]) == 63.131
assert float(largest_net["LeaveOneOutNetProfit"]) == 762.32
assert int(largest_net["LeaveOneOutPositiveWindows"]) == 9
assert largest_risk["Component"] == "MTSM_CAP12_ANNUAL"
assert float(largest_risk["RiskSharePercent"]) == 69.524
concentration_pass = (
    positive_components >= REGIME.MIN_POSITIVE_COMPONENTS
    and float(largest_net["NetSharePercent"]) <= REGIME.MAX_NET_SHARE_PERCENT
    and float(largest_risk["RiskSharePercent"]) <= REGIME.MAX_RISK_SHARE_PERCENT
    and float(largest_net["LeaveOneOutNetProfit"]) > 0.0
    and float(largest_net["LeaveOneOutOlder2015To2018"]) > 0.0
    and float(largest_net["LeaveOneOutMiddle2019To2022"]) > 0.0
    and float(largest_net["LeaveOneOutRecent2023To2026"]) > 0.0
)
expected_status = (
    "POSTHOC_REGIME_STRESS_TRIAGE_PASS"
    if regime_pass and concentration_pass
    else "POSTHOC_REGIME_STRESS_TRIAGE_FAIL"
)
assert decision[0]["Status"] == expected_status
assert decision[0]["RegimeMonteCarloGatePass"] == str(regime_pass)
assert decision[0]["ConcentrationGatePass"] == str(concentration_pass)
assert int(decision[0]["PassedRegimeScenarios"]) == sum(row["GatePass"] == "True" for row in regime)
assert int(decision[0]["TotalRegimeScenarios"]) == len(regime)
assert decision[0]["PostHocOnly"] == "True"
assert decision[0]["ExecutableCombinedPath"] == "False"
assert decision[0]["ForwardCandidateChanged"] == "False"
assert decision[0]["RealAccountApproved"] == "False"
assert decision[0]["TargetCompileStatus"] == "NOT_RUN_LOCAL_LOCK_ACTIVE"
assert decision[0]["TargetBacktestStatus"] == "NOT_RUN_LOCAL_LOCK_ACTIVE"
assert decision[0]["CollisionLedgerSha256"] == REGIME.BASE.EXPECTED_LEDGER_SHA256
assert decision[0]["AnalyzerIdentityMode"] == "LF_NORMALIZED_TEXT_SHA256"
assert decision[0]["RegimeAnalyzerSha256"] == REGIME.normalized_text_sha256(REGIME.REGIME_ANALYZER)
assert decision[0]["BaseAnalyzerSha256"] == REGIME.EXPECTED_BASE_ANALYZER_SHA256
assert decision[0]["IidDecisionSha256"] == REGIME.EXPECTED_IID_DECISION_SHA256
assert decision[0]["IidMonteCarloSha256"] == REGIME.EXPECTED_IID_MONTE_CARLO_SHA256
assert decision[0]["FrozenStressMethodSha256"] == REGIME.BASE.EXPECTED_METHOD_SHA256
assert decision[0]["TargetSourceSha256"] == REGIME.BASE.EXPECTED_TARGET_SOURCE_SHA256
assert decision[0]["TargetProfileSha256"] == REGIME.BASE.EXPECTED_TARGET_PROFILE_SHA256
assert int(decision[0]["MinimumPositiveComponents"]) == REGIME.MIN_POSITIVE_COMPONENTS
assert float(decision[0]["MaximumNetSharePercent"]) == REGIME.MAX_NET_SHARE_PERCENT
assert float(decision[0]["MaximumRiskSharePercent"]) == REGIME.MAX_RISK_SHARE_PERCENT
assert "post-hoc triage, not executable MT5 evidence or a new best" in document
assert "cannot change the registered forward candidate" in document
assert "approve real-account trading" in document
assert "github_pat_" not in document

print(
    f"RDMC_DIVERSIFIED_REPAIR_COLLISION_REGIME_STRESS_TEST_PASS status={expected_status} "
    f"regime={sum(row['GatePass'] == 'True' for row in regime)}/{len(regime)} "
    f"concentration={concentration_pass}"
)
