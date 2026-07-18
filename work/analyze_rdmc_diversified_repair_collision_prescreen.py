#!/usr/bin/env python3
"""Replay frozen RDMC component ledgers under one-position portfolio priority.

This remains a post-hoc approximation. It can reject a weak architecture before
MT5, but it cannot promote one because blocked trades alter later strategy state.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import itertools
import math
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
WINDOWS = (
    "2015", "2016", "2017", "2018", "2019", "2020",
    "2021", "2022", "2023", "2024", "2025", "2026_ytd",
)
COMPONENTS = (
    "MTSM_CAP12_ANNUAL",
    "R20_CURRENT_SOURCE_ANNUAL",
    "RRO_DI12_CAP12_CONTINUOUS",
    "DDB045_ANNUAL_RESTART",
)
SOURCE_PRIORITY = COMPONENTS
EXPECTED_HASHES = {
    "annual_candidate": "6BC726AB9D2C1BBC022419B1AEEB2F62C1D9E2EA7435B59F7BADD03539F22576",
    "rc2_trades": "80E2E741EA508DCC2D048661FF266A72F6708812F4F75EBB96DCB1136247CE59",
    "offline_union": "08790F29DF4320EEA7A4625646D6D276E4E62A3CA25446A53E20B8C32D428DE4",
    "ddb_trades": "0D638F4A797CAC65122C9E094C87D8DFCB7895EC3120533075776139799DAC5B",
    "r20_trades": "AC62D6B9CD59503C92D6129CF1B817EF797E46D6C0BDDD61CAD77603EAFD073E",
    "combined_source": "4740338598E290360946FE414CC6F2FE0CF3B704006860514367DCB996A8D2B5",
    "combined_profile": "12588915C76A9C7E29B84EC8C5AE79E64E3FDBFBA41221D77E490B3EB15364EC",
}


@dataclass(frozen=True)
class Trade:
    window: str
    component: str
    entry: datetime
    exit: datetime
    profit: float
    risk_money: float
    risk_r: float
    source: str


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: Iterable[dict], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def parse_time(value: str) -> datetime:
    for pattern in ("%Y-%m-%dT%H:%M:%S", "%Y.%m.%d %H:%M:%S"):
        try:
            return datetime.strptime(value, pattern).replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    raise ValueError(f"Unsupported timestamp: {value}")


def window_for_year(year: int) -> str:
    return "2026_ytd" if year == 2026 else str(year)


def profit_factor(profits: list[float]) -> float:
    gross_profit = sum(value for value in profits if value > 0.0)
    gross_loss = -sum(value for value in profits if value < 0.0)
    return gross_profit / gross_loss if gross_loss > 0.0 else math.inf


def max_closed_drawdown(profits: list[float], starting_balance: float = 10_000.0) -> tuple[float, float]:
    equity = starting_balance
    peak = starting_balance
    max_money = 0.0
    max_percent = 0.0
    for profit in profits:
        equity += profit
        peak = max(peak, equity)
        drawdown = peak - equity
        max_money = max(max_money, drawdown)
        if peak > 0.0:
            max_percent = max(max_percent, 100.0 * drawdown / peak)
    return max_money, max_percent


def load_components(args: argparse.Namespace) -> list[Trade]:
    annual = read_csv(args.annual_candidate)
    rc2 = read_csv(args.rc2_trades)
    offline = read_csv(args.offline_union)
    ddb = read_csv(args.ddb_trades)
    r20 = read_csv(args.r20_trades)

    trades: list[Trade] = []
    for row in annual:
        if not row["EntryComment"].startswith("MTSM_"):
            continue
        trades.append(Trade(
            row["TestWindow"], "MTSM_CAP12_ANNUAL",
            parse_time(row["EntryTime"]), parse_time(row["ExitTime"]),
            float(row["Profit"]), float(row["InitialRiskMoney"]), float(row["RiskR"]),
            "RDMC_CAP12_MODEL4_ANNUAL_TRADES",
        ))

    rc2_rro = {
        row["EntryTime"]: row
        for row in rc2
        if row["EntryComment"].startswith("RRO;")
    }
    offline_rro = [row for row in offline if row["Component"] == "RRO_DI12_CAP12_CONTINUOUS"]
    require(len(offline_rro) == 38, f"Expected 38 capped RRO trades, found {len(offline_rro)}.")
    for selected in offline_rro:
        row = rc2_rro.get(selected["EntryTime"])
        require(row is not None, f"Capped RRO trade missing from exact RC2 ledger: {selected['EntryTime']}")
        require(abs(float(row["Profit"]) - float(selected["Profit"])) <= 0.011, "RRO profit join changed.")
        trades.append(Trade(
            window_for_year(int(row["EntryYear"])), "RRO_DI12_CAP12_CONTINUOUS",
            parse_time(row["EntryTime"]), parse_time(row["ExitTime"]),
            float(row["Profit"]), float(row["InitialRiskMoney"]), float(row["RiskR"]),
            "RC2_MOMENTUM_RISK_EXTENSION_MODEL4_TRADES",
        ))

    for row in ddb:
        trades.append(Trade(
            row["TestWindow"], "DDB045_ANNUAL_RESTART",
            parse_time(row["EntryTime"]), parse_time(row["ExitTime"]),
            float(row["Profit"]), float(row["InitialRiskMoney"]), float(row["RiskR"]),
            f"DDB_REPORT_SHA256_{row['ReportSha256']}",
        ))

    for row in r20:
        trades.append(Trade(
            row["TestWindow"], "R20_CURRENT_SOURCE_ANNUAL",
            parse_time(row["EntryTime"]), parse_time(row["ExitTime"]),
            float(row["Profit"]), float(row["InitialRiskMoney"]), float(row["RiskR"]),
            f"R20_REPORT_SHA256_{row['ReportSha256']}",
        ))

    counts = defaultdict(int)
    for trade in trades:
        counts[trade.component] += 1
        require(trade.exit >= trade.entry, f"Negative duration: {trade}")
        require(trade.window in WINDOWS, f"Unexpected window: {trade.window}")
    require(len(trades) == 376, f"Expected 376 component trades, found {len(trades)}.")
    require(dict(counts) == {
        "MTSM_CAP12_ANNUAL": 313,
        "RRO_DI12_CAP12_CONTINUOUS": 38,
        "DDB045_ANNUAL_RESTART": 3,
        "R20_CURRENT_SOURCE_ANNUAL": 22,
    }, f"Component counts changed: {dict(counts)}")
    return trades


def replay(trades: list[Trade], priority_order: tuple[str, ...]) -> list[dict]:
    priority = {component: index for index, component in enumerate(priority_order)}
    ordered = sorted(trades, key=lambda trade: (trade.entry, priority[trade.component], trade.exit))
    active: Trade | None = None
    rows: list[dict] = []
    for trade in ordered:
        accepted = active is None or trade.entry >= active.exit
        blocker = None if accepted else active
        if accepted:
            active = trade
        rows.append({
            "TestWindow": trade.window,
            "Component": trade.component,
            "EntryTime": trade.entry.strftime("%Y-%m-%dT%H:%M:%S"),
            "ExitTime": trade.exit.strftime("%Y-%m-%dT%H:%M:%S"),
            "Profit": f"{trade.profit:.2f}",
            "InitialRiskMoney": f"{trade.risk_money:.6f}",
            "RiskR": f"{trade.risk_r:.6f}",
            "Decision": "ACCEPT" if accepted else "BLOCK_OVERLAP",
            "BlockedByComponent": "" if blocker is None else blocker.component,
            "BlockedByEntryTime": "" if blocker is None else blocker.entry.strftime("%Y-%m-%dT%H:%M:%S"),
            "BlockedByExitTime": "" if blocker is None else blocker.exit.strftime("%Y-%m-%dT%H:%M:%S"),
            "SourceEvidence": trade.source,
        })
    return rows


def summarize(rows: list[dict]) -> tuple[list[dict], dict]:
    summary: list[dict] = []
    accepted_all: list[float] = []
    by_window: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        by_window[row["TestWindow"]].append(row)
    for window in WINDOWS:
        window_rows = by_window[window]
        accepted = [float(row["Profit"]) for row in window_rows if row["Decision"] == "ACCEPT"]
        blocked = [float(row["Profit"]) for row in window_rows if row["Decision"] == "BLOCK_OVERLAP"]
        accepted_all.extend(accepted)
        pf = profit_factor(accepted)
        summary.append({
            "TestWindow": window,
            "CollisionAdjustedNet": f"{sum(accepted):.2f}",
            "CollisionAdjustedProfitFactor": "INF" if math.isinf(pf) else f"{pf:.4f}",
            "AcceptedTrades": str(len(accepted)),
            "BlockedTrades": str(len(blocked)),
            "BlockedOpportunityNet": f"{sum(blocked):.2f}",
            "PositiveWindow": str(sum(accepted) > 0.0),
        })
    max_dd_money, max_dd_percent = max_closed_drawdown(accepted_all)
    aggregate_pf = profit_factor(accepted_all)
    broad = {}
    for name, members in {
        "Older2015_2018": WINDOWS[0:4],
        "Middle2019_2022": WINDOWS[4:8],
        "Recent2023_2026": WINDOWS[8:12],
    }.items():
        broad[name] = sum(
            float(row["Profit"])
            for row in rows
            if row["Decision"] == "ACCEPT" and row["TestWindow"] in members
        )
    aggregate = {
        "Net": sum(accepted_all),
        "ProfitFactor": aggregate_pf,
        "AcceptedTrades": len(accepted_all),
        "BlockedTrades": sum(row["Decision"] == "BLOCK_OVERLAP" for row in rows),
        "MaxClosedDrawdownMoney": max_dd_money,
        "MaxClosedDrawdownPercent": max_dd_percent,
        "PositiveWindows": sum(row["PositiveWindow"] == "True" for row in summary),
        "MinimumWindowNet": min(float(row["CollisionAdjustedNet"]) for row in summary),
        **broad,
    }
    return summary, aggregate


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--annual-candidate", type=Path, default=ROOT / "outputs" / "RDMC_CAP12_MODEL4_ANNUAL_TRADES.csv")
    parser.add_argument("--rc2-trades", type=Path, default=ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_MODEL4_TRADES.csv")
    parser.add_argument("--offline-union", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_OFFLINE_TRADES.csv")
    parser.add_argument("--ddb-trades", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_DDB_ANNUAL_TRADES.csv")
    parser.add_argument("--r20-trades", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_R20_ANNUAL_TRADES.csv")
    parser.add_argument("--combined-source", type=Path, default=ROOT / "outputs" / "rdmc_diversified_repair_model1_package" / "source" / "Professional_XAUUSD_EA.mq5")
    parser.add_argument("--combined-profile", type=Path, default=ROOT / "outputs" / "rdmc_diversified_repair_model1_package" / "profiles" / "rdmc_diversified_repair_v1.set")
    parser.add_argument("--trades-out", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_TRADES.csv")
    parser.add_argument("--summary-out", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_SUMMARY.csv")
    parser.add_argument("--priority-out", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_PRIORITY_STRESS.csv")
    parser.add_argument("--markdown-out", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_PRESCREEN.md")
    args = parser.parse_args()

    identities = {
        "annual_candidate": args.annual_candidate,
        "rc2_trades": args.rc2_trades,
        "offline_union": args.offline_union,
        "ddb_trades": args.ddb_trades,
        "r20_trades": args.r20_trades,
        "combined_source": args.combined_source,
        "combined_profile": args.combined_profile,
    }
    for name, path in identities.items():
        require(path.is_file(), f"Required input missing: {path}")
        actual = sha256(path)
        require(actual == EXPECTED_HASHES[name], f"{name} identity mismatch: {actual}")

    trades = load_components(args)
    actual_rows = replay(trades, SOURCE_PRIORITY)
    actual_summary, actual = summarize(actual_rows)

    priority_rows = []
    for order in itertools.permutations(COMPONENTS):
        _, aggregate = summarize(replay(trades, order))
        priority_rows.append({
            "PriorityOrder": ">".join(order),
            "IsSourceOrder": str(order == SOURCE_PRIORITY),
            "NetProfit": f"{aggregate['Net']:.2f}",
            "ProfitFactor": "INF" if math.isinf(aggregate["ProfitFactor"]) else f"{aggregate['ProfitFactor']:.4f}",
            "AcceptedTrades": str(aggregate["AcceptedTrades"]),
            "BlockedTrades": str(aggregate["BlockedTrades"]),
            "PositiveWindows": str(aggregate["PositiveWindows"]),
            "MinimumWindowNet": f"{aggregate['MinimumWindowNet']:.2f}",
            "Older2015_2018Net": f"{aggregate['Older2015_2018']:.2f}",
            "Middle2019_2022Net": f"{aggregate['Middle2019_2022']:.2f}",
            "Recent2023_2026Net": f"{aggregate['Recent2023_2026']:.2f}",
            "MaxClosedDrawdownPercent": f"{aggregate['MaxClosedDrawdownPercent']:.4f}",
        })

    priority_rows.sort(key=lambda row: (-float(row["NetProfit"]), row["PriorityOrder"]))
    best = priority_rows[0]
    worst = priority_rows[-1]
    robust_positive_windows = min(int(row["PositiveWindows"]) for row in priority_rows)
    broad_positive = all(actual[name] > 0.0 for name in (
        "Older2015_2018", "Middle2019_2022", "Recent2023_2026",
    ))
    gate_pass = (
        actual["Net"] > 0.0
        and actual["ProfitFactor"] >= 1.25
        and actual["PositiveWindows"] == 12
        and actual["MinimumWindowNet"] >= 0.0
        and broad_positive
    )
    status = "POSTHOC_COLLISION_GATE_PASS_NOT_A_NEW_BEST" if gate_pass else "POSTHOC_COLLISION_GATE_FAIL"

    collision_matrix: dict[tuple[str, str], dict[str, float]] = defaultdict(lambda: {"Count": 0, "Net": 0.0})
    blocked_by_component: dict[str, dict[str, float]] = defaultdict(lambda: {"Count": 0, "Net": 0.0})
    for row in actual_rows:
        if row["Decision"] != "BLOCK_OVERLAP":
            continue
        key = (row["BlockedByComponent"], row["Component"])
        collision_matrix[key]["Count"] += 1
        collision_matrix[key]["Net"] += float(row["Profit"])
        blocked_by_component[row["Component"]]["Count"] += 1
        blocked_by_component[row["Component"]]["Net"] += float(row["Profit"])

    write_csv(args.trades_out, actual_rows, list(actual_rows[0].keys()))
    write_csv(args.summary_out, actual_summary, list(actual_summary[0].keys()))
    write_csv(args.priority_out, priority_rows, list(priority_rows[0].keys()))

    lines = [
        "# RDMC Diversified Repair Collision Pre-Screen",
        "",
        f"**Status: {status}. This remains post-hoc and cannot promote the combined EA.**",
        "",
        "The replay applies the frozen source order (MTSM, primary R20/DGF, capped RRO, then independent DDB) and permits only one open account position. A standalone trade whose entry occurs before the accepted trade exits is marked blocked and contributes no profit or loss.",
        "",
        f"- Collision-adjusted net: `${actual['Net']:+,.2f}`; PF `{actual['ProfitFactor']:.4f}`; accepted `{actual['AcceptedTrades']}`; blocked `{actual['BlockedTrades']}`",
        f"- Positive annual/YTD windows: `{actual['PositiveWindows']} / 12`; minimum window net `${actual['MinimumWindowNet']:+,.2f}`",
        f"- Broad nets: older `${actual['Older2015_2018']:+,.2f}`, middle `${actual['Middle2019_2022']:+,.2f}`, recent `${actual['Recent2023_2026']:+,.2f}`",
        f"- Approximate closed-trade drawdown on `$10,000`: `${actual['MaxClosedDrawdownMoney']:,.2f}` / `{actual['MaxClosedDrawdownPercent']:.4f}%`",
        f"- Across all 24 lane-priority permutations: best `${float(best['NetProfit']):+,.2f}`, worst `${float(worst['NetProfit']):+,.2f}`, minimum positive windows `{robust_positive_windows} / 12`",
        "",
        "| Window | Adjusted net | PF | Accepted | Blocked | Blocked opportunity net | Positive |",
        "|---|---:|---:|---:|---:|---:|---|",
    ]
    for row in actual_summary:
        lines.append(
            f"| `{row['TestWindow']}` | ${float(row['CollisionAdjustedNet']):+,.2f} | "
            f"{row['CollisionAdjustedProfitFactor']} | {row['AcceptedTrades']} | {row['BlockedTrades']} | "
            f"${float(row['BlockedOpportunityNet']):+,.2f} | {row['PositiveWindow']} |"
        )
    lines.extend([
        "",
        "## Blocked Trades By Lane",
        "",
        "| Blocked lane | Trades | Opportunity net removed |",
        "|---|---:|---:|",
    ])
    for component in COMPONENTS:
        item = blocked_by_component[component]
        lines.append(f"| `{component}` | {int(item['Count'])} | ${item['Net']:+,.2f} |")
    lines.extend([
        "",
        "## Collision Pairs",
        "",
        "| Active lane | Blocked lane | Trades | Blocked opportunity net |",
        "|---|---|---:|---:|",
    ])
    for (active_component, blocked_component), item in sorted(collision_matrix.items()):
        lines.append(
            f"| `{active_component}` | `{blocked_component}` | {int(item['Count'])} | ${item['Net']:+,.2f} |"
        )
    lines.extend([
        "",
        "## Hard Boundary",
        "",
        "- This replay uses historical standalone trades. Blocking an entry changes cooldowns, daily limits, monthly caps, and future signals, so later ledger rows are not a valid executable path.",
        "- Component reports came from different source versions and starting balances. Raw observed dollar P/L is retained without rescaling.",
        "- Intrabar order timing, spread, slippage, margin, equity-based lot sizing, and open drawdown are not recomputed.",
        "- Failure years were already inspected when this architecture was selected. This is not untouched out-of-sample evidence.",
        "- Only a clean compile and frozen MT5 Model1/Model4 runs can establish a combined result. The registered forward candidate remains unchanged and real-money trading remains locked.",
    ])
    args.markdown_out.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(
        f"{status} net={actual['Net']:.2f} pf={actual['ProfitFactor']:.4f} "
        f"accepted={actual['AcceptedTrades']} blocked={actual['BlockedTrades']} "
        f"positive_windows={actual['PositiveWindows']} min_window={actual['MinimumWindowNet']:.2f}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
