#!/usr/bin/env python3
"""Post-hoc architecture screen for an RDMC diversified repair.

The component union is not an executable MT5 portfolio. It combines exact
historical trade streams to decide whether a costly implementation is worth a
frozen tester gate. Entry path, capital, simultaneous-risk, and source-version
interactions remain unresolved until that gate is run.
"""

from __future__ import annotations

import argparse
import bisect
import csv
import hashlib
import math
import struct
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DAILY_CACHE = (
    ROOT.parent
    / "mt5_portable_research"
    / "Bases"
    / "MetaQuotes-Demo"
    / "history"
    / "XAUUSD"
    / "cache"
    / "Daily.hc"
)
EXPECTED_HASHES = {
    "daily_cache": "7DAE08D3C1FFBA81E74C31C4AFC1C3B4774EFCDC9BC0F9F45490690A18F5FBA2",
    "annual_candidate": "6BC726AB9D2C1BBC022419B1AEEB2F62C1D9E2EA7435B59F7BADD03539F22576",
    "rc2_trades": "80E2E741EA508DCC2D048661FF266A72F6708812F4F75EBB96DCB1136247CE59",
    "selection": "2AD2F51239B740822E8824B69C3441C1BCFFC74A2E62C038593CB187749E8A35",
    "r20_source": "2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D",
    "r20_profile": "3E6B806E2941A993579756C8E503B7886E06891F077A104D39428704E48545BC",
}
WINDOWS = (
    "2015", "2016", "2017", "2018", "2019", "2020",
    "2021", "2022", "2023", "2024", "2025", "2026_ytd",
)


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


def read_daily_cache(path: Path) -> tuple[tuple[int, ...], tuple[float, ...]]:
    data = path.read_bytes()
    require(struct.unpack_from("<I", data, 0)[0] == 502, "Unexpected Daily HC version.")
    cursor = 428
    arrays: dict[str, tuple] = {}
    counts: list[int] = []
    for name, code in (
        ("times", "q"), ("opens", "d"), ("highs", "d"), ("lows", "d"),
        ("closes", "d"), ("tick_volumes", "q"), ("spreads", "I"), ("real_volumes", "q"),
    ):
        count = struct.unpack_from("<I", data, cursor)[0]
        cursor += 4
        size = struct.calcsize("<" + code)
        require(cursor + count * size <= len(data), f"Truncated Daily HC {name} array.")
        arrays[name] = struct.unpack_from(f"<{count}{code}", data, cursor)
        cursor += count * size
        counts.append(count)
    require(len(set(counts)) == 1 and counts[0] >= 4_000, f"Daily HC counts changed: {counts}")
    require(all(a < b for a, b in zip(arrays["times"], arrays["times"][1:])), "Daily times are not increasing.")
    return arrays["times"], arrays["closes"]


def parse_time(value: str) -> datetime:
    for pattern in ("%Y-%m-%dT%H:%M:%S", "%Y.%m.%d %H:%M:%S"):
        try:
            return datetime.strptime(value, pattern).replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    raise ValueError(f"Unsupported timestamp: {value}")


def d1_momentum_percent(entry_time: str, times: tuple[int, ...], closes: tuple[float, ...]) -> float:
    current = bisect.bisect_right(times, int(parse_time(entry_time).timestamp())) - 1
    recent = current - 1
    past = recent - 126
    require(past >= 0, f"Insufficient D1 history for {entry_time}")
    return 100.0 * abs(closes[recent] - closes[past]) / closes[past]


def profit_factor(profits: list[float]) -> float:
    gross_profit = sum(value for value in profits if value > 0.0)
    gross_loss = -sum(value for value in profits if value < 0.0)
    return gross_profit / gross_loss if gross_loss > 0.0 else math.inf


def window_for_year(year: int) -> str:
    return "2026_ytd" if year == 2026 else str(year)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--daily-cache", type=Path, default=DEFAULT_DAILY_CACHE)
    parser.add_argument("--annual-candidate", type=Path, default=ROOT / "outputs" / "RDMC_CAP12_MODEL4_ANNUAL_TRADES.csv")
    parser.add_argument("--rc2-trades", type=Path, default=ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_MODEL4_TRADES.csv")
    parser.add_argument("--selection", type=Path, default=ROOT / "outputs" / "RC2_REVERSION_D1_MOMENTUM_CAP_SELECTION_TRADES.csv")
    parser.add_argument("--r20-trades", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_R20_ANNUAL_TRADES.csv")
    parser.add_argument("--ddb-trades", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_DDB_ANNUAL_TRADES.csv")
    parser.add_argument("--r20-source", type=Path, default=ROOT / "outputs" / "peak_r20_regime_combo_model4_yearly_package" / "source" / "Professional_XAUUSD_EA.mq5")
    parser.add_argument("--r20-profile", type=Path, default=ROOT / "outputs" / "peak_r20_regime_combo_model4_yearly_package" / "profiles" / "r10_pg40_atr085_adapt7.set")
    parser.add_argument("--trades-out", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_OFFLINE_TRADES.csv")
    parser.add_argument("--summary-out", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_OFFLINE_SUMMARY.csv")
    parser.add_argument("--markdown-out", type=Path, default=ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_OFFLINE_PRESCREEN.md")
    args = parser.parse_args()

    identity_paths = {
        "daily_cache": args.daily_cache,
        "annual_candidate": args.annual_candidate,
        "rc2_trades": args.rc2_trades,
        "selection": args.selection,
        "r20_source": args.r20_source,
        "r20_profile": args.r20_profile,
    }
    for name, path in identity_paths.items():
        require(path.is_file(), f"Required {name} input is missing: {path}")
        actual = sha256(path)
        require(actual == EXPECTED_HASHES[name], f"{name} identity mismatch: {actual}")
    for path in (args.r20_trades, args.ddb_trades):
        require(path.is_file(), f"Required extracted component ledger is missing: {path}")

    times, closes = read_daily_cache(args.daily_cache)
    selection = read_csv(args.selection)
    selection_errors = [
        abs(d1_momentum_percent(row["EntryTime"], times, closes) - float(row["AbsD1MomentumPercent"]))
        for row in selection
    ]
    require(len(selection_errors) == 17 and max(selection_errors) <= 0.0000005, "D1 cache alignment failed.")

    annual = read_csv(args.annual_candidate)
    rc2 = read_csv(args.rc2_trades)
    r20 = read_csv(args.r20_trades)
    ddb = read_csv(args.ddb_trades)
    require(len(r20) == 22 and round(sum(float(row["Profit"]) for row in r20), 2) == 263.72, "R20 ledger changed.")
    require(len(ddb) == 3 and round(sum(float(row["Profit"]) for row in ddb), 2) == 19.36, "DDB ledger changed.")

    components: list[dict] = []
    for row in annual:
        if not row["EntryComment"].startswith("MTSM_"):
            continue
        components.append({
            "TestWindow": row["TestWindow"], "Component": "MTSM_CAP12_ANNUAL",
            "EntryTime": row["EntryTime"], "Profit": float(row["Profit"]),
            "InitialRiskMoney": row["InitialRiskMoney"], "RiskR": row["RiskR"],
            "D1AbsMomentumPercent": "", "SourceEvidence": "RDMC_CAP12_MODEL4_ANNUAL_TRADES",
        })

    for row in rc2:
        if not row["EntryComment"].startswith("RRO;"):
            continue
        displacement = d1_momentum_percent(row["EntryTime"], times, closes)
        if displacement > 12.0:
            continue
        components.append({
            "TestWindow": window_for_year(int(row["EntryYear"])), "Component": "RRO_DI12_CAP12_CONTINUOUS",
            "EntryTime": row["EntryTime"], "Profit": float(row["Profit"]),
            "InitialRiskMoney": row["InitialRiskMoney"], "RiskR": row["RiskR"],
            "D1AbsMomentumPercent": f"{displacement:.6f}", "SourceEvidence": "RC2_MOMENTUM_RISK_EXTENSION_MODEL4_TRADES",
        })

    for row in ddb:
        components.append({
            "TestWindow": row["TestWindow"], "Component": "DDB045_ANNUAL_RESTART",
            "EntryTime": row["EntryTime"], "Profit": float(row["Profit"]),
            "InitialRiskMoney": row["InitialRiskMoney"], "RiskR": row["RiskR"],
            "D1AbsMomentumPercent": "", "SourceEvidence": f"DDB_REPORT_SHA256_{row['ReportSha256']}",
        })

    for row in r20:
        components.append({
            "TestWindow": row["TestWindow"], "Component": "R20_CURRENT_SOURCE_ANNUAL",
            "EntryTime": row["EntryTime"], "Profit": float(row["Profit"]),
            "InitialRiskMoney": row["InitialRiskMoney"], "RiskR": row["RiskR"],
            "D1AbsMomentumPercent": "", "SourceEvidence": f"R20_REPORT_SHA256_{row['ReportSha256']}",
        })

    order = {window: index for index, window in enumerate(WINDOWS)}
    components.sort(key=lambda row: (order[row["TestWindow"]], row["EntryTime"], row["Component"]))
    require(len(components) == 376, f"Unexpected component trade count: {len(components)}")

    summary: list[dict] = []
    by_component: dict[tuple[str, str], list[float]] = defaultdict(list)
    for row in components:
        by_component[(row["TestWindow"], row["Component"])].append(float(row["Profit"]))
    component_names = (
        "MTSM_CAP12_ANNUAL", "RRO_DI12_CAP12_CONTINUOUS",
        "DDB045_ANNUAL_RESTART", "R20_CURRENT_SOURCE_ANNUAL",
    )
    for window in WINDOWS:
        profits = [float(row["Profit"]) for row in components if row["TestWindow"] == window]
        nets = {name: sum(by_component[(window, name)]) for name in component_names}
        summary.append({
            "TestWindow": window,
            "MomentumNet": f"{nets['MTSM_CAP12_ANNUAL']:.2f}",
            "RRODI12Cap12Net": f"{nets['RRO_DI12_CAP12_CONTINUOUS']:.2f}",
            "DDB045Net": f"{nets['DDB045_ANNUAL_RESTART']:.2f}",
            "R20Net": f"{nets['R20_CURRENT_SOURCE_ANNUAL']:.2f}",
            "PostHocNetProfit": f"{sum(profits):.2f}",
            "PostHocProfitFactor": "INF" if math.isinf(profit_factor(profits)) else f"{profit_factor(profits):.4f}",
            "PostHocTrades": str(len(profits)),
            "PositiveYear": str(sum(profits) > 0.0),
            "NetFloor25": str(sum(profits) >= 25.0),
            "ProfitFactorFloor110": str(profit_factor(profits) >= 1.10),
        })

    all_profits = [float(row["Profit"]) for row in components]
    aggregate_net = sum(all_profits)
    aggregate_pf = profit_factor(all_profits)
    no_red_years = all(row["PositiveYear"] == "True" for row in summary)
    minimum_net = min(float(row["PostHocNetProfit"]) for row in summary)
    minimum_finite_pf = min(
        float(row["PostHocProfitFactor"])
        for row in summary
        if row["PostHocProfitFactor"] != "INF"
    )
    diagnostic_gate = (
        no_red_years and minimum_net >= 25.0 and minimum_finite_pf >= 1.10
        and aggregate_net >= 2_000.0 and aggregate_pf >= 1.50 and len(components) >= 350
    )
    require(diagnostic_gate, "The post-hoc diversified architecture gate did not pass.")
    require(next(row for row in summary if row["TestWindow"] == "2019")["PostHocNetProfit"] == "45.41", "2019 result changed.")
    require(next(row for row in summary if row["TestWindow"] == "2022")["PostHocNetProfit"] == "53.53", "2022 result changed.")

    trade_rows = []
    for row in components:
        trade_rows.append({
            **row,
            "Profit": f"{float(row['Profit']):.2f}",
        })
    write_csv(args.trades_out, trade_rows, list(trade_rows[0].keys()))
    write_csv(args.summary_out, summary, list(summary[0].keys()))

    lines = [
        "# RDMC Diversified Repair Offline Pre-Screen",
        "",
        "**Status: POSTHOC_ARCHITECTURE_GATE_PASS_NOT_A_NEW_BEST. No combined EA or MT5 result exists.**",
        "",
        "The screen replaces the weak signal-range repair with four historical components: annual Model4 MTSM trades from the cap candidate, DI `-12` RC2 reversion trades filtered by the completed-D1 `12%` cap, annual DDB045 restart trades, and the exact R20 current-source annual report stream.",
        "",
        f"- Projected aggregate net: `${aggregate_net:+,.2f}`; PF `{aggregate_pf:.4f}`; trades `{len(components)}`",
        f"- Positive annual/YTD windows: `{sum(row['PositiveYear'] == 'True' for row in summary)} / {len(summary)}`",
        f"- Minimum projected annual net: `${minimum_net:+.2f}`; minimum finite PF `{minimum_finite_pf:.4f}`",
        f"- Daily cache SHA-256: `{EXPECTED_HASHES['daily_cache']}`; selection alignment `{len(selection_errors)} / {len(selection_errors)}`, maximum error `{max(selection_errors):.9f}`",
        f"- Exact R20 source SHA-256: `{EXPECTED_HASHES['r20_source']}`; profile SHA-256: `{EXPECTED_HASHES['r20_profile']}`",
        "",
        "| Window | Momentum | DI12 + cap12 RRO | DDB045 | R20 | Post-hoc net | PF | Trades |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in summary:
        lines.append(
            f"| `{row['TestWindow']}` | ${float(row['MomentumNet']):+,.2f} | "
            f"${float(row['RRODI12Cap12Net']):+,.2f} | ${float(row['DDB045Net']):+,.2f} | "
            f"${float(row['R20Net']):+,.2f} | ${float(row['PostHocNetProfit']):+,.2f} | "
            f"{row['PostHocProfitFactor']} | {row['PostHocTrades']} |"
        )
    lines.extend([
        "",
        "## Hard Boundary",
        "",
        "- This is a union of observed trades, not a combined executable or a recomputed equity curve.",
        "- Filtering RC2 reversion trades can expose later entries, so the DI12 plus D1-cap path must be rerun in MT5.",
        "- R20 reports used a `$1,000` starting deposit while the other components used `$10,000`; absolute trade P/L is retained without scaling. A new `$10,000` risk contract must be tested.",
        "- Simultaneous positions, account-wide open-risk limits, daily-loss controls, margin, and drawdown interactions are not modeled.",
        "- R20 contributes tested evidence only from 2019 through 2026 YTD; no zero-trade claim is made for 2015-2018.",
        "- The failure years were inspected while choosing this architecture, so this is not untouched out-of-sample evidence.",
        "",
        "The result only justifies freezing a combined source/profile and opening a small annual MT5 gate. It does not alter the registered forward candidate. The invalid `$100,000` demo still contributes zero evidence, and real-money trading remains locked.",
    ])
    args.markdown_out.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(
        "POSTHOC_ARCHITECTURE_GATE_PASS_NOT_A_NEW_BEST "
        f"net={aggregate_net:.2f} pf={aggregate_pf:.4f} trades={len(components)} "
        f"min_year={minimum_net:.2f} min_pf={minimum_finite_pf:.4f}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
