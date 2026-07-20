#!/usr/bin/env python3
"""Extract an identity-bound hedging ledger from the pre-2021 squeeze report."""

from __future__ import annotations

import csv
import hashlib
from collections import defaultdict
from pathlib import Path

import rdmc_executable_ledger_stress_core as core


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "outputs" / "four_lane_m15_squeeze_diversifier_discovery_model1_package" / "reports_here" / "sq_center0100_continuous_2015_2020_m1.htm"
IDENTITY = REPORT.with_suffix(".identity.json")
RUNS = ROOT / "outputs" / "FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_RUN_ATTESTATION.csv"
RESULTS = ROOT / "outputs" / "FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_MODEL1_RESULTS.csv"
OUT_TRADES = ROOT / "outputs" / "FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_TRADES.csv"
OUT_SUMMARY = ROOT / "outputs" / "FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_LANE_SUMMARY.csv"
EXPECTED_SOURCE = "5D756F58DDAB31D2DC909B8DD800C8D888582691A7208FFD7FD1E3F597D3A5C6"
EXPECTED_BINARY = "9BC3BAEC7D5BA0945E6974C960AC900D6F019C5A174D217712FF8B7E8137C32A"
EXPECTED_TRADES = 350
EXPECTED_NET = 1575.70
CONTRACT_SIZE = 100.0


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


def lane(comment: str) -> str:
    if comment.startswith("M15SQ_"):
        return "M15_SQUEEZE"
    if comment.startswith("MTSM_"):
        return "MOMENTUM"
    if comment.startswith("ATB_"):
        return "ADAPTIVE_TREND"
    if comment.startswith("RRO;"):
        return "REVERSION"
    raise RuntimeError(f"Unknown entry comment: {comment!r}")


runs = [row for row in read_csv(RUNS) if row["Candidate"] == "sq_center0100" and row["Window"] == "continuous_2015_2020"]
result_rows = [row for row in read_csv(RESULTS) if row["Candidate"] == "sq_center0100" and row["Window"] == "continuous_2015_2020"]
require(len(runs) == 1 and len(result_rows) == 1, "Exact center report identity is missing")
run = runs[0]
result = result_rows[0]
require(run["Status"] == "REPORT_FOUND", "Center report is not identity-valid")
require(run["PackageSourceSha256"] == EXPECTED_SOURCE, "Run source identity changed")
require(run["PortableBinarySha256"] == EXPECTED_BINARY, "Run binary identity changed")
require(run["ReportSha256"] == sha256(REPORT), "Report hash differs from run attestation")
require(result["SourceSha256"] == EXPECTED_SOURCE, "Result source identity changed")
require(int(result["TotalTrades"]) == EXPECTED_TRADES, "Result trade count changed")
require(abs(float(result["NetProfit"]) - EXPECTED_NET) <= 0.001, "Result net changed")

parser = core.ReportRowsParser()
parser.feed(core.decode_report(REPORT))
rows = parser.rows
order_header = core.find_header(rows, {"opentime", "order", "symbol", "type", "volume", "sl", "state"})
deal_header = core.find_header(rows, {"time", "deal", "symbol", "type", "direction", "volume", "profit", "balance"})
orders = core.mapped_rows(rows, order_header, deal_header)
deals = core.mapped_rows(rows, deal_header)
order_map = {row["order"].strip(): row for row in orders if row.get("order", "").strip()}
opened: list[dict[str, object]] = []
trades: list[dict[str, object]] = []

for deal in deals:
    direction = deal.get("direction", "").strip().lower()
    side = deal.get("type", "").strip().lower()
    symbol = deal.get("symbol", "").strip()
    if direction not in {"in", "out"} or side not in {"buy", "sell"}:
        continue
    timestamp = core.report_time(deal["time"])
    volume = core.report_number(deal["volume"])
    price = core.report_number(deal["price"])
    commission = core.report_number(deal.get("commission", ""))
    fee = core.report_number(deal.get("fee", ""))
    swap = core.report_number(deal.get("swap", ""))
    order_id = deal.get("order", "").strip()
    require(order_id in order_map, f"Deal lacks exact order row: {deal.get('deal', '')}")
    order = order_map[order_id]

    if direction == "in":
        order_volume = core.report_number(order.get("volume", "").split("/")[0])
        require(abs(order_volume - volume) <= 1e-8, "Entry order/deal volume mismatch")
        stop = core.report_number(order.get("sl", ""))
        target = core.report_number(order.get("tp", ""))
        require(stop > 0.0, "Entry lacks initial stop")
        opened.append({
            "time": timestamp, "deal": deal["deal"], "order": order_id, "symbol": symbol,
            "side": side, "volume": volume, "price": price, "stop": stop, "target": target,
            "risk": abs(price - stop) * volume * CONTRACT_SIZE,
            "commission": commission, "fee": fee, "swap": swap,
            "comment": deal.get("comment", ""),
        })
        continue

    gross = core.report_number(deal.get("profit", ""))
    candidates: list[tuple[float, int, dict[str, object]]] = []
    for index, entry in enumerate(opened):
        if entry["symbol"] != symbol or entry["side"] == side or abs(float(entry["volume"]) - volume) > 1e-8:
            continue
        multiplier = 1.0 if entry["side"] == "buy" else -1.0
        calculated = (price - float(entry["price"])) * volume * CONTRACT_SIZE * multiplier
        difference = abs(calculated - gross)
        if difference <= 0.021:
            candidates.append((difference, index, entry))
    require(bool(candidates), f"No price-path match for exit deal {deal.get('deal', '')}")
    candidates.sort(key=lambda row: (row[0], row[2]["time"]))
    require(len(candidates) == 1 or candidates[0][0] + 1e-9 < candidates[1][0], f"Ambiguous exit deal {deal.get('deal', '')}")
    _, entry_index, entry = candidates[0]
    opened.pop(entry_index)
    net = gross + float(entry["commission"]) + float(entry["fee"]) + float(entry["swap"]) + commission + fee + swap
    risk = float(entry["risk"])
    trades.append({
        "Trade": len(trades) + 1,
        "Lane": lane(str(entry["comment"])),
        "EntryTime": entry["time"].isoformat(),
        "ExitTime": timestamp.isoformat(),
        "EntryYear": entry["time"].year,
        "EntryHour": entry["time"].hour,
        "Side": entry["side"],
        "Volume": entry["volume"],
        "EntryPrice": entry["price"],
        "ExitPrice": price,
        "InitialStop": entry["stop"],
        "InitialTarget": entry["target"],
        "InitialRiskMoney": round(risk, 4),
        "RiskR": round(net / risk, 6),
        "HoldMinutes": round((timestamp - entry["time"]).total_seconds() / 60.0, 2),
        "Profit": round(net, 2),
        "EntryComment": entry["comment"],
        "ExitComment": deal.get("comment", ""),
    })

require(not opened, f"Report ends with {len(opened)} unmatched positions")
require(len(trades) == EXPECTED_TRADES, f"Parsed {len(trades)} trades, expected {EXPECTED_TRADES}")
require(abs(sum(float(row["Profit"]) for row in trades) - EXPECTED_NET) <= 0.02, "Ledger net differs from report")

summary: list[dict[str, object]] = []
for name in sorted({str(row["Lane"]) for row in trades}):
    lane_rows = [row for row in trades if row["Lane"] == name]
    wins = sum(float(row["Profit"]) for row in lane_rows if float(row["Profit"]) > 0.0)
    losses = abs(sum(float(row["Profit"]) for row in lane_rows if float(row["Profit"]) < 0.0))
    summary.append({
        "Lane": name,
        "Trades": len(lane_rows),
        "NetProfit": round(sum(float(row["Profit"]) for row in lane_rows), 2),
        "ProfitFactor": round(wins / losses, 4) if losses > 0.0 else "INF",
        "WinRatePercent": round(100.0 * sum(float(row["Profit"]) > 0.0 for row in lane_rows) / len(lane_rows), 2),
        "AverageRiskR": round(sum(float(row["RiskR"]) for row in lane_rows) / len(lane_rows), 4),
    })

write_csv(OUT_TRADES, trades)
write_csv(OUT_SUMMARY, summary)
print(f"PASS trades={len(trades)} net={sum(float(row['Profit']) for row in trades):.2f} report={sha256(REPORT)}")
for row in summary:
    print(" ".join(f"{key}={value}" for key, value in row.items()))
