#!/usr/bin/env python3
"""Fail-closed regression checks for the executable MT5 ledger stress gate."""

from __future__ import annotations

import csv
import hashlib
import json
import subprocess
import sys
import tempfile
from dataclasses import replace
from datetime import datetime, timedelta
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "work"))
import rdmc_executable_ledger_stress_core as core  # noqa: E402


SOURCE_SHA256 = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
CONFIG_SHA256 = "C" * 64
BINARY_SHA256 = "B" * 64
LEGACY_REPORT = (
    ROOT
    / "outputs"
    / "returned_mt5_reports"
    / "first_pass_inbox"
    / "lossblock_highprofit_peaktrail_off_continuous_2019_2026_m4.htm"
)


def expect_rejection(action, expected: str) -> None:
    try:
        action()
    except ValueError as exc:
        assert expected.lower() in str(exc).lower(), (expected, str(exc))
    else:
        raise AssertionError(f"Expected rejection containing: {expected}")


def td(cells: list[object]) -> str:
    return "<tr>" + "".join(f"<td>{cell}</td>" for cell in cells) + "</tr>"


def synthetic_report(
    *,
    missing_stop: bool = False,
    overlap: bool = False,
    partial_exit: bool = False,
    price_profit_mismatch: bool = False,
) -> str:
    orders: list[list[object]] = []
    entries: list[list[object]] = []
    exits: list[list[object]] = []
    balance = 10_000.0
    profits: list[float] = []
    trade_index = 0
    for year in range(2015, 2027):
        for month in (1, 3, 5, 7, 9):
            trade_index += 1
            entry_time = datetime(year, month, 2, 10, 0, 0)
            exit_time = entry_time + timedelta(hours=1)
            entry_order = str(100_000 + trade_index * 2)
            exit_order = str(100_001 + trade_index * 2)
            entry_deal = str(200_000 + trade_index * 2)
            exit_deal = str(200_001 + trade_index * 2)
            profit = -40.0 if trade_index % 5 == 0 else 100.0
            exit_price = 1996.0 if profit < 0.0 else 2010.0
            stop = "" if missing_stop and trade_index == 1 else "1995.00"
            orders.append([entry_time.strftime("%Y.%m.%d %H:%M:%S"), entry_order, "XAUUSD", "buy", "0.10 / 0.10", "2000.00", stop, "2010.00", entry_time.strftime("%Y.%m.%d %H:%M:%S"), "filled", "entry"])
            orders.append([exit_time.strftime("%Y.%m.%d %H:%M:%S"), exit_order, "XAUUSD", "sell", "0.10 / 0.10", f"{exit_price:.2f}", "", "", exit_time.strftime("%Y.%m.%d %H:%M:%S"), "filled", "exit"])
            entries.append([entry_time.strftime("%Y.%m.%d %H:%M:%S"), entry_deal, "XAUUSD", "buy", "in", "0.10", "2000.00", entry_order, "0.00", "0.00", "0.00", f"{balance:.2f}", "entry"])
            balance += profit
            exit_volume = "0.05" if partial_exit and trade_index == 1 else "0.10"
            reported_profit = 99.0 if price_profit_mismatch and trade_index == 1 else profit
            exits.append([exit_time.strftime("%Y.%m.%d %H:%M:%S"), exit_deal, "XAUUSD", "sell", "out", exit_volume, f"{exit_price:.2f}", exit_order, "0.00", "0.00", f"{reported_profit:.2f}", f"{balance:.2f}", "exit"])
            profits.append(profit)

    deal_rows: list[list[object]] = []
    for index, (entry, exit_row) in enumerate(zip(entries, exits)):
        deal_rows.append(entry)
        if overlap and index == 0:
            deal_rows.append(entries[1])
        deal_rows.append(exit_row)
        if overlap and index == 1:
            continue

    gross_profit = sum(value for value in profits if value > 0.0)
    gross_loss = -sum(value for value in profits if value < 0.0)
    net = sum(profits)
    lines = [
        "<html><body>",
        f"<div>SourceSha256={SOURCE_SHA256}</div>",
        td(["Total Net Profit:", f"{net:.2f}"]),
        td(["Profit Factor:", f"{gross_profit / gross_loss:.2f}"]),
        td(["Total Trades:", len(profits)]),
        td(["Open Time", "Order", "Symbol", "Type", "Volume", "Price", "S / L", "T / P", "Time", "State", "Comment"]),
    ]
    lines.extend(td(row) for row in orders)
    lines.append(td(["Time", "Deal", "Symbol", "Type", "Direction", "Volume", "Price", "Order", "Commission", "Swap", "Profit", "Balance", "Comment"]))
    lines.extend(td(row) for row in deal_rows)
    lines.append("</body></html>")
    return "\n".join(lines) + "\n"


def write_identity(report: Path, identity: Path, *, created_utc: str = "2026-07-18T12:00:00+00:00") -> None:
    payload = {
        "SchemaVersion": 1,
        "ExpectedReportName": report.stem,
        "ConfigSha256": CONFIG_SHA256,
        "SourceSha256": SOURCE_SHA256,
        "PortableBinarySha256": BINARY_SHA256,
        "ReportSha256": hashlib.sha256(report.read_bytes()).hexdigest().upper(),
        "ReportBytes": report.stat().st_size,
        "CreatedUtc": created_utc,
    }
    identity.write_text(json.dumps(payload), encoding="ascii")


legacy_trades, legacy_metrics = core.parse_mt5_report(LEGACY_REPORT)
assert len(legacy_trades) == 127
assert round(sum(trade.profit for trade in legacy_trades), 2) == 1915.83
assert legacy_metrics == {"NetProfit": 1915.83, "ProfitFactor": 1.72, "TotalTrades": 127.0}
assert min(trade.initial_risk for trade in legacy_trades) > 0.0

with tempfile.TemporaryDirectory(prefix="rdmc_ledger_stress_") as temporary:
    temp = Path(temporary)
    report = temp / "synthetic_continuous_m4.htm"
    identity = temp / "synthetic_continuous_m4.identity.json"
    report.write_text(synthetic_report(), encoding="utf-8")
    write_identity(report, identity)
    accepted_identity = core.validate_report_identity(
        report, identity, report.stem, CONFIG_SHA256, SOURCE_SHA256, BINARY_SHA256
    )
    assert accepted_identity["ReportSha256"] == hashlib.sha256(report.read_bytes()).hexdigest().upper()
    trades, metrics = core.parse_mt5_report(report)
    assert len(trades) == 60 and metrics["NetProfit"] == 4320.0
    assert all(trade.entry_order and trade.exit_order for trade in trades)

    report.write_text(synthetic_report() + "tampered\n", encoding="utf-8")
    expect_rejection(
        lambda: core.validate_report_identity(report, identity, report.stem, CONFIG_SHA256, SOURCE_SHA256, BINARY_SHA256),
        "report hash identity mismatch",
    )
    report.write_text(synthetic_report(), encoding="utf-8")
    write_identity(report, identity, created_utc="2026-07-18T12:00:00")
    expect_rejection(
        lambda: core.validate_report_identity(report, identity, report.stem, CONFIG_SHA256, SOURCE_SHA256, BINARY_SHA256),
        "lacks a UTC offset",
    )

    report.write_text(synthetic_report(missing_stop=True), encoding="utf-8")
    expect_rejection(lambda: core.parse_mt5_report(report), "initial stop")
    report.write_text(synthetic_report(overlap=True), encoding="utf-8")
    expect_rejection(lambda: core.parse_mt5_report(report), "overlapping entries")
    report.write_text(synthetic_report(partial_exit=True), encoding="utf-8")
    expect_rejection(lambda: core.parse_mt5_report(report), "partial or oversized exits")
    report.write_text(synthetic_report(price_profit_mismatch=True), encoding="utf-8")
    expect_rejection(lambda: core.parse_mt5_report(report), "gross profit differs from its price path")

cost_rows = core.cost_stress(trades)
assert len(cost_rows) == 4 and all(row["GatePass"] for row in cost_rows)
weak = [replace(trade, gross_profit=-20.0, profit=-20.0) for trade in trades]
assert not all(row["GatePass"] for row in core.cost_stress(weak))
mc_first = core.monte_carlo_stress(trades, trials=300)
mc_second = core.monte_carlo_stress(trades, trials=300)
assert mc_first == mc_second
assert len(mc_first) == 8 and all(row["GatePass"] for row in mc_first)

run = subprocess.run(
    [sys.executable, str(ROOT / "work" / "analyze_rdmc_executable_trade_ledger_stress.py")],
    cwd=ROOT,
    check=True,
    capture_output=True,
    text=True,
)
assert "AWAITING_EXECUTABLE_MT5_GATE" in run.stdout
with (ROOT / "outputs" / "RDMC_EXECUTABLE_LEDGER_STRESS_DECISION.csv").open(encoding="utf-8-sig", newline="") as handle:
    decision = list(csv.DictReader(handle))
assert len(decision) == 1 and decision[0]["Status"] == "AWAITING_EXECUTABLE_MT5_GATE"
for stale_name in (
    "RDMC_EXECUTABLE_LEDGER_TRADES.csv",
    "RDMC_EXECUTABLE_LEDGER_COST_STRESS.csv",
    "RDMC_EXECUTABLE_LEDGER_ORDER_AWARE_MONTE_CARLO.csv",
):
    assert not (ROOT / "outputs" / stale_name).exists()

print("RDMC_EXECUTABLE_LEDGER_STRESS_TEST_PASS cases=12 legacy_trades=127 synthetic_trades=60 mc_trials=300x8")
