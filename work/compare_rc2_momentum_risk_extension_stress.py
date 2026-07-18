#!/usr/bin/env python3
"""Apply the frozen RC2 MRE stress method to the unchanged 0.15% control ledger."""

from __future__ import annotations

import csv
import importlib.util
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "work" / "analyze_rc2_momentum_risk_extension_stress.py"
CANONICAL_CONTROL_LEDGER = (
    ROOT
    / "release"
    / "transferable-portfolio-v0.1"
    / "evidence"
    / "TRANSFERABLE_PORTFOLIO_MODEL4_TRADES.csv"
)
CONTROL_LEDGER = (
    CANONICAL_CONTROL_LEDGER
    if CANONICAL_CONTROL_LEDGER.exists()
    else ROOT / "outputs" / "TRANSFERABLE_PORTFOLIO_MODEL4_TRADES.csv"
)
OUT_CSV = ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_STRESS_CONTROL_COMPARISON.csv"
OUT_MD = ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_STRESS_CONTROL_COMPARISON.md"
CONTROL_HASH = "2F7A8A8854F8F33325498AE0F194202E7BB15F28F2644FC4F9B08DE8B740413B"

SPEC = importlib.util.spec_from_file_location("mre_stress_comparison", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Could not load frozen stress analyzer")
MRE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MRE
SPEC.loader.exec_module(MRE)


def write_csv(rows: list[dict[str, object]]) -> None:
    with OUT_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def money(value: float) -> str:
    return f"{'+' if value >= 0 else '-'}${abs(value):,.2f}"


def main() -> int:
    center = MRE.load_trades()
    control = MRE.load_trade_file(CONTROL_LEDGER, CONTROL_HASH, 362, 1615.36)
    rows: list[dict[str, object]] = []
    for label, trades in (("control_mo015", control), ("center_mo020", center)):
        for result in MRE.run_monte_carlo(trades):
            rows.append({"Profile": label, **result})
    write_csv(rows)
    lines = [
        "# RC2 Momentum-Risk Stress Control Comparison",
        "",
        "Diagnostic comparison using the already frozen bootstrap method and seeds. This is not a new selection gate.",
        "",
        f"- Control ledger SHA-256: `{CONTROL_HASH}`",
        f"- Center ledger SHA-256: `{MRE.EXPECTED_LEDGER_SHA256}`",
        "",
        "| Profile | Scenario | P05 net | Median net | Median PF | P95 DD | P95 loss run | Red trials | Gate |",
        "|---|---|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in rows:
        lines.append(
            f"| {row['Profile']} | {row['Scenario']} | {money(float(row['P05NetProfit']))} | "
            f"{money(float(row['MedianNetProfit']))} | {float(row['MedianProfitFactor']):.3f} | "
            f"{float(row['P95MaxClosedDrawdownPercent']):.3f}% | "
            f"{float(row['P95MaxConsecutiveLosses']):.0f} | {float(row['RedTrialPercent']):.3f}% | "
            f"{row['GatePass']} |"
        )
    lines.extend(
        [
            "",
            "Because the two profiles share signals but have different realized lot steps, this comparison isolates whether the increased momentum allocation improves or weakens the same stress method.",
        ]
    )
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"RC2_MOMENTUM_RISK_STRESS_COMPARISON rows={len(rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
