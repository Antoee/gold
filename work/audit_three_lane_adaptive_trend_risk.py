from __future__ import annotations

import csv
from collections import defaultdict
from datetime import datetime
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
LEDGER = REPO / "outputs" / "THREE_LANE_ADAPTIVE_TREND_MODEL4_CONTINUOUS_TRADES.csv"
OUT_CSV = REPO / "outputs" / "THREE_LANE_ADAPTIVE_TREND_MODEL4_RISK_AUDIT.csv"
OUT_MD = REPO / "outputs" / "THREE_LANE_ADAPTIVE_TREND_MODEL4_RISK_AUDIT.md"
INITIAL_DEPOSIT = 10_000.0
PORTFOLIO_CAP_PERCENT = 0.75
TOLERANCE_PERCENT = 0.005


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def lane_and_cap(comment: str) -> tuple[str, float]:
    if comment.startswith("RRO;"):
        return "reversion", 0.45
    if comment.startswith("MTSM_"):
        return "momentum", 0.15
    if comment.startswith("ATB_"):
        return "adaptive_trend", 0.10
    return "unknown", 0.0


require(LEDGER.is_file(), f"Missing trade ledger: {LEDGER}")
with LEDGER.open(newline="", encoding="utf-8-sig") as handle:
    source_rows = list(csv.DictReader(handle))
require(source_rows, "Continuous trade ledger is empty")

trades: list[dict[str, object]] = []
for index, row in enumerate(source_rows):
    entry_time = datetime.fromisoformat(row["EntryTime"])
    exit_time = datetime.fromisoformat(row["ExitTime"])
    risk_money = float(row["InitialRiskMoney"])
    profit = float(row["Profit"])
    lane, lane_cap = lane_and_cap(row["EntryComment"])
    require(exit_time >= entry_time, f"Exit precedes entry at ledger row {index + 1}")
    require(risk_money > 0.0, f"Missing initial-stop risk at ledger row {index + 1}")
    require(lane != "unknown", f"Unknown lane comment: {row['EntryComment']}")
    trades.append(
        {
            **row,
            "Index": index,
            "EntryDateTime": entry_time,
            "ExitDateTime": exit_time,
            "RiskMoneyValue": risk_money,
            "ProfitValue": profit,
            "Lane": lane,
            "LaneCapPercent": lane_cap,
        }
    )

trades.sort(key=lambda item: (item["EntryDateTime"], item["Index"]))
audit_rows: list[dict[str, object]] = []
lane_stats: dict[str, dict[str, float]] = defaultdict(
    lambda: {"trades": 0.0, "net": 0.0, "max_risk": 0.0, "violations": 0.0}
)
maximum_portfolio_risk_percent = 0.0
maximum_open_positions = 0
portfolio_violations = 0

for position, trade in enumerate(trades):
    entry_time = trade["EntryDateTime"]
    closed_profit = sum(
        float(candidate["ProfitValue"])
        for candidate in trades
        if candidate["ExitDateTime"] <= entry_time
    )
    entry_balance = INITIAL_DEPOSIT + closed_profit
    require(entry_balance > 0.0, f"Non-positive reconstructed balance at {trade['EntryTime']}")

    already_open = [
        candidate
        for candidate in trades[:position]
        if candidate["EntryDateTime"] <= entry_time < candidate["ExitDateTime"]
    ]
    open_risk_money = sum(float(candidate["RiskMoneyValue"]) for candidate in already_open)
    lane_risk_percent = 100.0 * float(trade["RiskMoneyValue"]) / entry_balance
    portfolio_risk_percent = 100.0 * (open_risk_money + float(trade["RiskMoneyValue"])) / entry_balance
    lane_pass = lane_risk_percent <= float(trade["LaneCapPercent"]) + TOLERANCE_PERCENT
    portfolio_pass = portfolio_risk_percent <= PORTFOLIO_CAP_PERCENT + TOLERANCE_PERCENT

    stats = lane_stats[str(trade["Lane"])]
    stats["trades"] += 1
    stats["net"] += float(trade["ProfitValue"])
    stats["max_risk"] = max(stats["max_risk"], lane_risk_percent)
    stats["violations"] += 0 if lane_pass else 1
    portfolio_violations += 0 if portfolio_pass else 1
    maximum_portfolio_risk_percent = max(maximum_portfolio_risk_percent, portfolio_risk_percent)
    maximum_open_positions = max(maximum_open_positions, len(already_open) + 1)

    audit_rows.append(
        {
            "EntryTime": trade["EntryTime"],
            "Lane": trade["Lane"],
            "Volume": trade["Volume"],
            "EntryBalance": f"{entry_balance:.2f}",
            "InitialRiskMoney": f"{float(trade['RiskMoneyValue']):.2f}",
            "LaneRiskPercent": f"{lane_risk_percent:.4f}",
            "LaneCapPercent": f"{float(trade['LaneCapPercent']):.2f}",
            "OpenPositionsAfterEntry": len(already_open) + 1,
            "PortfolioInitialRiskPercent": f"{portfolio_risk_percent:.4f}",
            "PortfolioCapPercent": f"{PORTFOLIO_CAP_PERCENT:.2f}",
            "LanePass": str(lane_pass),
            "PortfolioPass": str(portfolio_pass),
            "EntryComment": trade["EntryComment"],
        }
    )

with OUT_CSV.open("w", newline="", encoding="utf-8") as handle:
    writer = csv.DictWriter(handle, fieldnames=list(audit_rows[0]))
    writer.writeheader()
    writer.writerows(audit_rows)

lane_violations = int(sum(stats["violations"] for stats in lane_stats.values()))
passed = lane_violations == 0 and portfolio_violations == 0
lines = [
    "# Three-Lane Adaptive Trend Risk Audit",
    "",
    f"**Status: {'PASS' if passed else 'FAIL'}.**",
    "",
    "| Lane | Trades | Net | Maximum initial risk | Hard cap | Violations |",
    "|---|---:|---:|---:|---:|---:|",
]
caps = {"reversion": 0.45, "momentum": 0.15, "adaptive_trend": 0.10}
for lane in ("reversion", "momentum", "adaptive_trend"):
    stats = lane_stats[lane]
    lines.append(
        f"| {lane} | {int(stats['trades'])} | ${stats['net']:.2f} | "
        f"{stats['max_risk']:.4f}% | {caps[lane]:.2f}% | {int(stats['violations'])} |"
    )
lines.extend(
    [
        "",
        f"- Maximum conservative portfolio initial risk: `{maximum_portfolio_risk_percent:.4f}%` against a `{PORTFOLIO_CAP_PERCENT:.2f}%` cap.",
        f"- Maximum simultaneously open positions: `{maximum_open_positions}`.",
        f"- Lane-cap violations: `{lane_violations}`; portfolio-cap violations: `{portfolio_violations}`.",
        "- Entry balance is reconstructed from closed report profit. Open-position risk is conservatively held at its full initial-stop amount until exit.",
        "- Initial risk uses the report's entry, initial stop, volume, and the tested XAUUSD contract size of 100.",
    ]
)
OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

require(lane_violations == 0, f"Found {lane_violations} lane risk violation(s)")
require(portfolio_violations == 0, f"Found {portfolio_violations} portfolio risk violation(s)")
print(
    "THREE_LANE_ADAPTIVE_TREND_RISK_AUDIT_PASS "
    f"trades={len(trades)} max_portfolio_risk={maximum_portfolio_risk_percent:.4f}% "
    f"max_positions={maximum_open_positions}"
)
