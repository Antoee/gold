#!/usr/bin/env python3
"""Run identity-bound risk, cost, and clustered Monte Carlo stress for SSLC."""

from __future__ import annotations

import csv
import hashlib
from datetime import datetime
from pathlib import Path

import rdmc_executable_ledger_stress_core as core


ROOT = Path(__file__).resolve().parents[1]
RUN_ATTESTATION = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_RUN_ATTESTATION.csv"
RESULTS = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_RESULTS.csv"
ANNUAL_DECISION = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_DECISION.csv"
PROFILE = ROOT / "outputs" / "three_lane_reversion_strong_signal_lot_cap_model4_package" / "profiles" / "sslc_center015.set"
REPORT_ROOT = ROOT / "outputs" / "three_lane_reversion_strong_signal_lot_cap_model4_package" / "reports_here"
REPORT_NAME = "sslc_center015_continuous_2015_2026_m4"
REPORT = REPORT_ROOT / f"{REPORT_NAME}.htm"
IDENTITY = REPORT_ROOT / f"{REPORT_NAME}.identity.json"
LEDGER = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_CONTINUOUS_TRADES.csv"
RISK_AUDIT = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_RISK_AUDIT.csv"
OUT_COST = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_COST_STRESS.csv"
OUT_MC = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_MONTE_CARLO.csv"
OUT_DECISION_CSV = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_STRESS_DECISION.csv"
OUT_DECISION_MD = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_STRESS_DECISION.md"

EXPECTED_RUN_ATTESTATION_SHA256 = "18CA8E65749C06077E8B4D72EC3C8DF57530CAB9833D8DC94A5FE743E09A6DA3"
EXPECTED_ANNUAL_DECISION_SHA256 = "60E1CD6903B05FA5A6EBAAD4C71AA0242AA9F0DD4FBA321E7750FD3CB5B27767"
EXPECTED_SOURCE_SHA256 = "C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91"
EXPECTED_PROFILE_SHA256 = "A0099C6701311BAE105F29909166358D4D30050593318F340AD8F3B932F65F04"
EXPECTED_BINARY_SHA256 = "A1640E4D0E6892F4E826CA8FC5524C7F3BDB9FABE2121F508F94FD2D7AB7BE7A"
EXPECTED_REPORT_SHA256 = "1B673CD08DC8E3C826AD21EFF895F70EA6A9EBB461158DBE698CBC170B88AAE6"
EXPECTED_TRADES = 404
EXPECTED_NET = 2428.50
REVERSION_LOT_CAP = 0.15


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    require(bool(rows), f"No rows for {path.name}")
    with path.open("w", newline="", encoding="ascii") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def money(value: float) -> str:
    return f"{'+' if value >= 0.0 else '-'}${abs(value):,.2f}"


require(sha256(RUN_ATTESTATION) == EXPECTED_RUN_ATTESTATION_SHA256, "Model 4 run attestation identity changed")
require(sha256(ANNUAL_DECISION) == EXPECTED_ANNUAL_DECISION_SHA256, "Annual decision identity changed")
require(sha256(PROFILE) == EXPECTED_PROFILE_SHA256, "Center profile identity changed")
annual = read_csv(ANNUAL_DECISION)
require(len(annual) == 1 and annual[0]["Status"] == "ANNUAL_GATE_PASSED", "Annual gate is not an exact pass")
require(annual[0]["CostMonteCarloPermitted"] == "True", "Annual gate did not open stress")

attestation_matches = [
    row
    for row in read_csv(RUN_ATTESTATION)
    if row["Candidate"] == "sslc_center015" and row["Window"] == "continuous_2015_2026"
]
require(len(attestation_matches) == 1, "Expected one continuous center run attestation")
attestation = attestation_matches[0]
require(attestation["Status"] == "REPORT_FOUND", "Continuous report was not found")
require(attestation["SourceSha256"] == EXPECTED_SOURCE_SHA256, "Source identity changed")
require(attestation["BinarySha256"] == EXPECTED_BINARY_SHA256, "Attested binary identity changed")
require(attestation["ReportSha256"] == EXPECTED_REPORT_SHA256, "Attested report identity changed")
require(attestation["IdentitySidecarPresent"] == "True", "Identity sidecar was not attested")
require(attestation["PortableExpertRecompiled"] == "False", "Portable expert was recompiled during the run")
identity = core.validate_report_identity(
    REPORT,
    IDENTITY,
    REPORT_NAME,
    attestation["ConfigSha256"],
    EXPECTED_SOURCE_SHA256,
    EXPECTED_BINARY_SHA256,
)
require(sha256(REPORT) == EXPECTED_REPORT_SHA256, "Continuous report identity changed")
require(identity["ReportSha256"] == EXPECTED_REPORT_SHA256, "Report sidecar identity changed")

result_matches = [
    row
    for row in read_csv(RESULTS)
    if row["Candidate"] == "sslc_center015" and row["Window"] == "continuous_2015_2026"
]
require(len(result_matches) == 1, "Expected one continuous center result")
result = result_matches[0]
require(result["SourceSha256"] == EXPECTED_SOURCE_SHA256, "Result source identity changed")
require(result["ProfileSha256"] == EXPECTED_PROFILE_SHA256, "Result profile identity changed")
require(result["BinarySha256"] == EXPECTED_BINARY_SHA256, "Result binary identity changed")
require(result["ReportSha256"] == EXPECTED_REPORT_SHA256, "Result report identity changed")
require(int(result["TotalTrades"]) == EXPECTED_TRADES, "Result trade count changed")
require(abs(float(result["NetProfit"]) - EXPECTED_NET) <= 0.001, "Result net changed")

ledger_rows = read_csv(LEDGER)
require(len(ledger_rows) == EXPECTED_TRADES, "Ledger trade count differs from exact report")
require(abs(sum(float(row["Profit"]) for row in ledger_rows) - EXPECTED_NET) <= 0.02, "Ledger net differs from exact report")
trades: list[core.Trade] = []
for index, row in enumerate(ledger_rows, start=1):
    profit = float(row["Profit"])
    trades.append(
        core.Trade(
            index=index,
            entry_time=datetime.fromisoformat(row["EntryTime"]),
            exit_time=datetime.fromisoformat(row["ExitTime"]),
            entry_deal=f"ledger-entry-{index}",
            exit_deal=f"ledger-exit-{index}",
            entry_order=f"ledger-entry-order-{index}",
            exit_order=f"ledger-exit-order-{index}",
            symbol=row["Symbol"],
            side=row["Side"],
            volume=float(row["Volume"]),
            entry_price=float(row["EntryPrice"]),
            exit_price=float(row["ExitPrice"]),
            initial_stop=float(row["InitialStop"]),
            initial_target=float(row["InitialTarget"]),
            initial_risk=float(row["InitialRiskMoney"]),
            gross_profit=profit,
            commission=0.0,
            fee=0.0,
            swap=0.0,
            profit=profit,
            entry_comment=row["EntryComment"],
            exit_comment=row["ExitComment"],
        )
    )

risk_rows = read_csv(RISK_AUDIT)
require(len(risk_rows) == EXPECTED_TRADES, "Risk audit does not cover every trade")
risk_pass = all(row["LanePass"] == "True" and row["PortfolioPass"] == "True" for row in risk_rows)
max_portfolio_risk = max(float(row["PortfolioInitialRiskPercent"]) for row in risk_rows)
max_open_positions = max(int(row["OpenPositionsAfterEntry"]) for row in risk_rows)
reversion_rows = [row for row in ledger_rows if row["EntryComment"].startswith("RRO;")]
require(bool(reversion_rows), "No reversion trades exist in the exact ledger")
max_reversion_lots = max(float(row["Volume"]) for row in reversion_rows)
lot_cap_pass = max_reversion_lots <= REVERSION_LOT_CAP + 1e-9

cost_rows = core.cost_stress(trades)
mc_rows = core.monte_carlo_stress(trades, trials=10_000)
write_csv(OUT_COST, cost_rows)
write_csv(OUT_MC, mc_rows)
cost_pass = all(bool(row["GatePass"]) for row in cost_rows)
mc_pass = all(bool(row["GatePass"]) for row in mc_rows)
passed = risk_pass and lot_cap_pass and cost_pass and mc_pass
status = "STRESS_GATE_PASSED" if passed else "REJECTED_IN_STRESS_GATE"

decision: dict[str, object] = {
    "Status": status,
    "Trades": len(trades),
    "NetProfit": round(sum(trade.profit for trade in trades), 2),
    "HardRiskAuditPass": risk_pass,
    "ReversionLotCapPass": lot_cap_pass,
    "MaximumReversionLots": max_reversion_lots,
    "MaximumPortfolioInitialRiskPercent": max_portfolio_risk,
    "MaximumOpenPositions": max_open_positions,
    "CostStressPass": cost_pass,
    "OrderAwareMonteCarloPass": mc_pass,
    "HistoricalPromotionPermitted": False,
    "ForwardCandidateChanged": False,
    "RealAccountTradingAllowed": False,
    "SourceSha256": EXPECTED_SOURCE_SHA256,
    "ProfileSha256": EXPECTED_PROFILE_SHA256,
    "BinarySha256": EXPECTED_BINARY_SHA256,
    "ReportSha256": EXPECTED_REPORT_SHA256,
    "LedgerSha256": sha256(LEDGER),
    "RiskAuditSha256": sha256(RISK_AUDIT),
}
write_csv(OUT_DECISION_CSV, [decision])

lines = [
    "# Strong-Signal Selective Lot-Cap Model 4 Stress Decision",
    "",
    f"**Status: {status.replace('_', ' ')}. This is historical stress evidence, not real-money approval.**",
    "",
    f"- Exact trades: `{len(trades)}`; base net: `{money(float(decision['NetProfit']))}`",
    f"- Hard-risk audit: `{risk_pass}`; selective reversion lot cap: `{lot_cap_pass}`",
    f"- Maximum reversion volume: `{max_reversion_lots:.2f}` lots; maximum conservative portfolio initial risk: `{max_portfolio_risk:.4f}%`",
    f"- Cost gate: `{cost_pass}`; order-aware Monte Carlo gate: `{mc_pass}`",
    f"- Source: `{EXPECTED_SOURCE_SHA256}`; EX5: `{EXPECTED_BINARY_SHA256}`",
    f"- Report: `{EXPECTED_REPORT_SHA256}`; ledger: `{decision['LedgerSha256']}`",
    "",
    "## Added Execution Cost",
    "",
    "| Scenario | Added R/trade | Extra cost | Net | PF | Closed DD | Older | Middle | Recent | Gate |",
    "|---|---:|---:|---:|---:|---:|---:|---:|---:|---|",
]
for row in cost_rows:
    lines.append(
        f"| {row['Scenario']} | {float(row['AddedCostRPerTrade']):.2f}R | ${float(row['ExtraCost']):,.2f} | "
        f"{money(float(row['NetProfit']))} | {float(row['ProfitFactor']):.3f} | "
        f"{float(row['MaxClosedDrawdownPercent']):.3f}% | {money(float(row['Older2015To2018']))} | "
        f"{money(float(row['Middle2019To2022']))} | {money(float(row['Recent2023To2026']))} | {row['GatePass']} |"
    )
lines.extend(
    [
        "",
        "## Order-Aware Monte Carlo",
        "",
        "| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 DD | P95 loss run | Red trials | Gate |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
)
for row in mc_rows:
    lines.append(
        f"| {row['Sampler']} | {row['StressScenario']} | {row['Trials']} | "
        f"{money(float(row['P05NetProfit']))} | {money(float(row['MedianNetProfit']))} | "
        f"{float(row['MedianProfitFactor']):.3f} | {float(row['P95MaxClosedDrawdownPercent']):.3f}% | "
        f"{float(row['P95MaxConsecutiveLosses']):.0f} | {float(row['RedTrialPercent']):.3f}% | {row['GatePass']} |"
    )
lines.extend(
    [
        "",
        "- Stress preserves local trade clustering and calendar-year regimes; severe paths include worse slippage, delay, spread shocks, and missed winners.",
        "- MT5 equity drawdown remains authoritative; Monte Carlo drawdown is closed-trade path drawdown.",
        "- A second broker/specification and a valid frozen-account forward demo remain unavailable, so historical promotion and live approval stay closed.",
    ]
)
OUT_DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")

require(passed, "One or more frozen risk or stress gates failed")
print(
    "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_STRESS_PASS "
    f"trades={len(trades)} cost_rows={len(cost_rows)} mc_rows={len(mc_rows)}"
)
