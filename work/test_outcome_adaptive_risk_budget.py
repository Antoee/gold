from __future__ import annotations

import csv
import importlib.util
import sys
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
MODULE_PATH = ROOT / "work" / "analyze_outcome_adaptive_risk_budget.py"
SPEC = importlib.util.spec_from_file_location("oarb", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Could not load outcome-adaptive analyzer.")
OARB = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = OARB
SPEC.loader.exec_module(OARB)


trades = OARB.load_trades(
    ROOT
    / "release"
    / "transferable-portfolio-v0.1"
    / "evidence"
    / "TRANSFERABLE_PORTFOLIO_MODEL4_TRADES.csv"
)
control = OARB.simulate(
    trades,
    OARB.VARIANTS[0],
    datetime(2015, 1, 1),
    datetime(2026, 7, 17),
    0.0,
)
assert control.trades == 362
assert abs(control.net - 1615.36) <= 0.01
assert control.hot_entries == 0 and control.cold_entries == 0
assert control.capped_entries == 0

center = next(variant for variant in OARB.VARIANTS if variant.name == "oarb_center_n12_h15_c50_dd25")
assert OARB.state_for_entry(center, [], 0.0, 0.0) == ("normal", 1.0)
assert OARB.state_for_entry(center, [1.0] * 11, 11.0, 11.0) == ("normal", 1.0)
assert OARB.state_for_entry(center, [0.5] * 12, 6.0, 6.0) == ("hot", 1.25)
assert OARB.state_for_entry(center, [-0.1] * 12, -1.2, 0.0) == ("cold", 0.50)

gate_path = ROOT / "outputs" / "OUTCOME_ADAPTIVE_RISK_BUDGET_GATES.csv"
with gate_path.open("r", encoding="ascii", newline="") as handle:
    gates = list(csv.DictReader(handle))
assert len(gates) == 11
assert next(row for row in gates if row["Gate"] == "control-reproduction")["Pass"] == "True"
assert next(row for row in gates if row["Gate"] == "continuous-improvement")["Pass"] == "False"
assert next(row for row in gates if row["Gate"] == "neighbor-support")["Evidence"] == "passes=0/7"

decision = (ROOT / "outputs" / "OUTCOME_ADAPTIVE_RISK_BUDGET_DECISION.md").read_text(encoding="ascii")
assert "REJECT BEFORE MQL IMPLEMENTATION" in decision
assert "Fixed-control reproduction: `$1,615.36` across `362` trades" in decision
assert "The operational RC2 candidate" in decision

print("OUTCOME_ADAPTIVE_RISK_BUDGET_TEST_PASS control=1615.36 gates=11 neighbors=0/7")
