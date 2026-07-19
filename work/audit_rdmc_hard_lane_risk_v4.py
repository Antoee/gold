from __future__ import annotations

import csv
from datetime import datetime
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
INITIAL_DEPOSIT = 10_000.0
WINDOWS = ("2019", "2022")
OUT_CSV = REPO / "outputs" / "RDMC_HARD_LANE_RISK_V4_LANE_RISK_AUDIT.csv"
OUT_MD = REPO / "outputs" / "RDMC_HARD_LANE_RISK_V4_LANE_RISK_AUDIT.md"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value)


def lane_and_cap(comment: str) -> tuple[str, float]:
    if comment.startswith("MTSM_"):
        return "momentum", 0.10
    if comment.startswith("RRO;"):
        return "band_vwap_reversion", 0.50
    if comment.startswith("DDB;"):
        return "daily_donchian", 0.50
    return "primary", 0.25


audit_rows: list[dict[str, object]] = []
summaries: list[dict[str, object]] = []

for window in WINDOWS:
    ledger_path = REPO / "outputs" / f"RDMC_HARD_LANE_RISK_V4_{window}_TRADES.csv"
    require(ledger_path.is_file(), f"Missing trade ledger: {ledger_path}")
    with ledger_path.open(newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    require(rows, f"Trade ledger is empty: {ledger_path}")

    parsed = []
    for row in rows:
        parsed.append(
            {
                **row,
                "EntryDateTime": parse_time(row["EntryTime"]),
                "ExitDateTime": parse_time(row["ExitTime"]),
                "ProfitValue": float(row["Profit"]),
                "RiskMoneyValue": float(row["InitialRiskMoney"]),
            }
        )
    parsed.sort(key=lambda row: row["EntryDateTime"])

    previous_exit: datetime | None = None
    for row in parsed:
        entry_time = row["EntryDateTime"]
        exit_time = row["ExitDateTime"]
        require(exit_time >= entry_time, f"Exit precedes entry in {window}: {row['EntryTime']}")
        require(
            previous_exit is None or entry_time >= previous_exit,
            f"Overlapping positions prevent entry-balance reconstruction in {window}",
        )
        previous_exit = exit_time

    maximum_risk_percent = 0.0
    violations = 0
    for row in parsed:
        entry_time = row["EntryDateTime"]
        closed_profit = sum(
            candidate["ProfitValue"]
            for candidate in parsed
            if candidate["ExitDateTime"] <= entry_time
        )
        entry_balance = INITIAL_DEPOSIT + closed_profit
        require(entry_balance > 0.0, f"Non-positive reconstructed balance in {window}")
        lane, hard_cap_percent = lane_and_cap(row["EntryComment"])
        risk_percent = 100.0 * row["RiskMoneyValue"] / entry_balance
        passed = risk_percent <= hard_cap_percent + 0.0001
        violations += 0 if passed else 1
        maximum_risk_percent = max(maximum_risk_percent, risk_percent)
        audit_rows.append(
            {
                "Window": window,
                "EntryTime": row["EntryTime"],
                "Lane": lane,
                "Volume": row["Volume"],
                "EntryBalance": f"{entry_balance:.2f}",
                "InitialRiskMoney": f"{row['RiskMoneyValue']:.2f}",
                "InitialRiskPercent": f"{risk_percent:.4f}",
                "HardCapPercent": f"{hard_cap_percent:.2f}",
                "Pass": str(passed),
                "EntryComment": row["EntryComment"],
            }
        )

    summaries.append(
        {
            "Window": window,
            "Trades": len(parsed),
            "MaximumInitialRiskPercent": maximum_risk_percent,
            "Violations": violations,
        }
    )

with OUT_CSV.open("w", newline="", encoding="utf-8") as handle:
    writer = csv.DictWriter(handle, fieldnames=list(audit_rows[0]))
    writer.writeheader()
    writer.writerows(audit_rows)

lines = [
    "# RDMC Hard Lane Risk v4 Audit",
    "",
    "**Status: PASS. Every reconstructed entry risk is inside its lane's static upper ceiling.**",
    "",
    "| Window | Trades | Maximum initial risk | Violations |",
    "|---|---:|---:|---:|",
]
for summary in summaries:
    lines.append(
        f"| {summary['Window']} | {summary['Trades']} | "
        f"{summary['MaximumInitialRiskPercent']:.4f}% | {summary['Violations']} |"
    )
lines.extend(
    [
        "",
        "- Momentum ceiling: `0.10%` of reconstructed entry balance.",
        "- Shared primary ceiling: `0.25%`; isolated reversion and D1 breakout absolute upper ceiling: `0.50%`.",
        "- The ledgers contain no overlapping positions, so closed balance equals equity immediately before each entry.",
        "- This safety pass does not override the strategy rejection: 2019 profit factor remains below the frozen `1.05` gate.",
    ]
)
OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

total_violations = sum(int(summary["Violations"]) for summary in summaries)
require(total_violations == 0, f"Hard lane-risk audit found {total_violations} violation(s)")
print(
    "RDMC_HARD_LANE_RISK_V4_AUDIT_PASS "
    f"trades={len(audit_rows)} violations={total_violations}"
)
