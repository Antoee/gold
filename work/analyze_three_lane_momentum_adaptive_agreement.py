#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "outputs" / "THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_CONTINUOUS_TRADES.csv"
SOURCE = ROOT / "work" / "Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Lot_Cap_Research.mq5"
OUT_CSV = ROOT / "outputs" / "THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_ATTRIBUTION.csv"
OUT_MD = ROOT / "outputs" / "THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_ATTRIBUTION.md"
EXPECTED_LEDGER = "F4ABA823765C05FC8B44CAC07AAC168A9D2ABA9F06E344C682D6DC8CBB50EBEA"
EXPECTED_SOURCE = "C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def lane(comment: str) -> str:
    if comment.startswith("MTSM"):
        return "Momentum"
    if comment.startswith("ATB"):
        return "Adaptive"
    if comment.startswith("RRO"):
        return "Reversion"
    return "Other"


def era(year: int) -> str:
    if year <= 2018:
        return "2015-2018"
    if year <= 2022:
        return "2019-2022"
    return "2023-2026"


def summarize(label: str, rows: list[dict[str, object]]) -> dict[str, object]:
    wins = sum(float(row["Profit"]) for row in rows if float(row["Profit"]) > 0.0)
    losses = -sum(float(row["Profit"]) for row in rows if float(row["Profit"]) < 0.0)
    net = sum(float(row["Profit"]) for row in rows)
    return {
        "Group": label,
        "Trades": len(rows),
        "NetProfit": round(net, 2),
        "ProfitFactor": round(wins / losses, 4) if losses else "INF",
        "WinRatePercent": round(100.0 * sum(float(row["Profit"]) > 0.0 for row in rows) / len(rows), 2),
        "AverageRiskR": round(sum(float(row["RiskR"]) for row in rows) / len(rows), 4),
    }


def money(value: float) -> str:
    return f"{'+' if value >= 0.0 else '-'}${abs(value):,.2f}"


def main() -> int:
    if sha256(LEDGER) != EXPECTED_LEDGER or sha256(SOURCE) != EXPECTED_SOURCE:
        raise ValueError("leader source or trade-ledger identity changed")

    trades: list[dict[str, object]] = []
    for raw in read_csv(LEDGER):
        trades.append(
            {
                "Entry": datetime.fromisoformat(raw["EntryTime"]),
                "Exit": datetime.fromisoformat(raw["ExitTime"]),
                "Year": int(raw["EntryYear"]),
                "Side": raw["Side"].lower(),
                "Lane": lane(raw["EntryComment"]),
                "Profit": float(raw["Profit"]),
                "RiskR": float(raw["RiskR"]),
            }
        )
    trades.sort(key=lambda row: row["Entry"])
    if len(trades) != 404 or any(row["Lane"] == "Other" for row in trades):
        raise ValueError("expected the exact 404-trade three-lane ledger")

    overlap: list[dict[str, object]] = []
    for current in trades:
        active = [
            prior
            for prior in trades
            if prior["Entry"] < current["Entry"] < prior["Exit"]
            and prior["Side"] == current["Side"]
        ]
        if not active:
            continue
        existing_lanes = "+".join(sorted({str(prior["Lane"]) for prior in active}))
        overlap.append(
            {
                **current,
                "Pair": f"{current['Lane']} after {existing_lanes}",
                "Era": era(int(current["Year"])),
            }
        )

    selected = [row for row in overlap if row["Pair"] == "Momentum after Adaptive"]
    if len(selected) != 19:
        raise ValueError("selected overlap count changed")

    rows: list[dict[str, object]] = []
    rows.append(summarize("All same-direction cross-lane entries", overlap))
    for pair in sorted({str(row["Pair"]) for row in overlap}):
        rows.append(summarize(pair, [row for row in overlap if row["Pair"] == pair]))
    rows.append(summarize("Selected: Momentum after Adaptive", selected))
    for period in ("2015-2018", "2019-2022", "2023-2026"):
        rows.append(summarize(f"Selected {period}", [row for row in selected if row["Era"] == period]))

    with OUT_CSV.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)

    selected_summary = summarize("Selected", selected)
    lines = [
        "# Momentum / Adaptive Agreement Attribution",
        "",
        "This is retrospective architecture-selection evidence, not a simulated portfolio and not out-of-sample proof.",
        "",
        f"- Exact leader source SHA-256: `{EXPECTED_SOURCE}`",
        f"- Exact Model 4 ledger SHA-256: `{EXPECTED_LEDGER}`",
        "- Ledger: 404 exact leader trades, 2015-01-01 through 2026-07-18",
        "- Rule inspected: a new momentum entry whose direction matched an adaptive-trend position already open before that entry",
        "- The rule uses only position state available at entry; no future bar or trade outcome is used by the proposed EA code",
        "",
        "| Group | Trades | Net | PF | Win rate | Avg R |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for row in rows:
        lines.append(
            f"| {row['Group']} | {row['Trades']} | {money(float(row['NetProfit']))} | "
            f"{row['ProfitFactor']} | {row['WinRatePercent']}% | {row['AverageRiskR']} |"
        )
    lines.extend(
        [
            "",
            f"The selected subset contains `{selected_summary['Trades']}` trades, `{money(float(selected_summary['NetProfit']))}` net, and PF `{selected_summary['ProfitFactor']}`. It was positive in all three broad eras, but the architecture was chosen after inspecting all eras. Therefore 2021-2026 is architecture-seen and cannot be described as a pristine holdout.",
            "",
            "The proposed code may only change requested momentum risk for an otherwise-valid momentum entry while a same-symbol, same-direction, exact-magic adaptive-trend position is already open. Entry eligibility, initial stop geometry, target, exits, loss limits, and the account-wide 0.75% open-risk cap remain unchanged.",
        ]
    )
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(
        f"ATTRIBUTION_PASS selected={selected_summary['Trades']} "
        f"net={selected_summary['NetProfit']} pf={selected_summary['ProfitFactor']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
