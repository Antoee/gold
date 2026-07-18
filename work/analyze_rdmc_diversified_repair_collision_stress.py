#!/usr/bin/env python3
"""Post-hoc cost and bootstrap triage for the RDMC collision ledger.

This can reject a fragile architecture before MT5 time is spent. It cannot
promote the combined EA because the ledger was assembled from standalone runs.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import math
import random
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from statistics import median


ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_TRADES.csv"
SUMMARY = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_SUMMARY.csv"
TARGET_SOURCE = (
    ROOT
    / "outputs"
    / "rdmc_diversified_repair_restart_safe_model1_package"
    / "source"
    / "Professional_XAUUSD_EA.mq5"
)
TARGET_PROFILE = (
    ROOT
    / "outputs"
    / "rdmc_diversified_repair_restart_safe_model1_package"
    / "profiles"
    / "rdmc_diversified_repair_restart_safe_v2.set"
)
FROZEN_METHOD = ROOT / "work" / "analyze_rc2_momentum_risk_extension_stress.py"

COST_CSV = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_COST_STRESS.csv"
COST_WINDOW_CSV = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_COST_STRESS_WINDOWS.csv"
MC_CSV = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_MONTE_CARLO.csv"
DECISION_CSV = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_STRESS_DECISION.csv"
DECISION_MD = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_STRESS_DECISION.md"

EXPECTED_LEDGER_SHA256 = "ED51B6648E5B17F738D83CC05238828365EE621872D94AE3D981604C7433C047"
EXPECTED_SUMMARY_SHA256 = "4A408529D650949ACBDF10726899C08CB3B4775E8150F1BD613FC14062D63599"
EXPECTED_TARGET_SOURCE_SHA256 = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
EXPECTED_TARGET_PROFILE_SHA256 = "746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883"
EXPECTED_METHOD_SHA256 = "71B6929E06EDF660F704866EB2931044C799FB2CB2B85ACF8FDEEDCECC1DD33C"
EXPECTED_TOTAL_ROWS = 376
EXPECTED_ACCEPTED_TRADES = 368
EXPECTED_NET = 2067.64
WINDOWS = (
    "2015", "2016", "2017", "2018", "2019", "2020",
    "2021", "2022", "2023", "2024", "2025", "2026_ytd",
)
ERA_WINDOWS = {
    "Older2015To2018": WINDOWS[0:4],
    "Middle2019To2022": WINDOWS[4:8],
    "Recent2023To2026": WINDOWS[8:12],
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def load_frozen_method():
    require(sha256(FROZEN_METHOD) == EXPECTED_METHOD_SHA256, "Frozen stress method identity changed")
    spec = importlib.util.spec_from_file_location("rdmc_frozen_stress_method", FROZEN_METHOD)
    require(spec is not None and spec.loader is not None, "Could not load frozen stress method")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


METHOD = load_frozen_method()


@dataclass(frozen=True)
class Trade:
    window: str
    exit_time: datetime
    initial_risk: float
    profit: float
    component: str


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def load_trades() -> list[Trade]:
    identities = (
        (LEDGER, EXPECTED_LEDGER_SHA256, "collision ledger"),
        (SUMMARY, EXPECTED_SUMMARY_SHA256, "collision summary"),
        (TARGET_SOURCE, EXPECTED_TARGET_SOURCE_SHA256, "target source"),
        (TARGET_PROFILE, EXPECTED_TARGET_PROFILE_SHA256, "target profile"),
    )
    for path, expected, label in identities:
        require(path.is_file(), f"Missing {label}: {path}")
        require(sha256(path) == expected, f"{label} identity changed: {sha256(path)}")

    rows = read_csv(LEDGER)
    require(len(rows) == EXPECTED_TOTAL_ROWS, f"Expected {EXPECTED_TOTAL_ROWS} ledger rows")
    require(all(row["Decision"] in {"ACCEPT", "BLOCK_OVERLAP"} for row in rows), "Unknown collision decision")
    trades: list[Trade] = []
    for row in rows:
        if row["Decision"] != "ACCEPT":
            continue
        risk = float(row["InitialRiskMoney"])
        profit = float(row["Profit"])
        risk_r = float(row["RiskR"])
        require(row["TestWindow"] in WINDOWS, f"Unexpected window: {row['TestWindow']}")
        require(risk > 0.0 and math.isfinite(risk_r), "Accepted trade lacks finite positive risk coverage")
        require(abs(profit / risk - risk_r) <= 0.0001, "Profit/R identity changed")
        trades.append(
            Trade(
                window=row["TestWindow"],
                exit_time=datetime.fromisoformat(row["ExitTime"]),
                initial_risk=risk,
                profit=profit,
                component=row["Component"],
            )
        )
    trades.sort(key=lambda trade: trade.exit_time)
    require(len(trades) == EXPECTED_ACCEPTED_TRADES, f"Expected {EXPECTED_ACCEPTED_TRADES} accepted trades")
    require(abs(round(sum(trade.profit for trade in trades), 2) - EXPECTED_NET) <= 0.001, "Accepted net changed")

    summary_rows = read_csv(SUMMARY)
    require([row["TestWindow"] for row in summary_rows] == list(WINDOWS), "Summary windows changed")
    require(sum(int(row["AcceptedTrades"]) for row in summary_rows) == len(trades), "Summary trade count changed")
    require(
        abs(round(sum(float(row["CollisionAdjustedNet"]) for row in summary_rows), 2) - EXPECTED_NET) <= 0.001,
        "Summary net changed",
    )
    return trades


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    require(bool(rows), f"No rows for {path.name}")
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def run_cost_stress(trades: list[Trade]) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    rows: list[dict[str, object]] = []
    window_rows: list[dict[str, object]] = []
    for name, added_cost_r in METHOD.COST_SCENARIOS:
        adjusted = [(trade, trade.profit - added_cost_r * trade.initial_risk) for trade in trades]
        metrics = METHOD.path_metrics([value for _, value in adjusted])
        by_window: dict[str, dict[str, float | int]] = defaultdict(lambda: {"Trades": 0, "NetProfit": 0.0})
        for trade, value in adjusted:
            item = by_window[trade.window]
            item["Trades"] = int(item["Trades"]) + 1
            item["NetProfit"] = float(item["NetProfit"]) + value
        for window in WINDOWS:
            window_rows.append(
                {
                    "Scenario": name,
                    "Window": window,
                    "Trades": int(by_window[window]["Trades"]),
                    "NetProfit": round(float(by_window[window]["NetProfit"]), 2),
                    "Positive": float(by_window[window]["NetProfit"]) > 0.0,
                }
            )
        era_nets = {
            era: round(sum(float(by_window[window]["NetProfit"]) for window in windows), 2)
            for era, windows in ERA_WINDOWS.items()
        }
        all_eras_positive = all(value > 0.0 for value in era_nets.values())
        positive_windows = sum(float(by_window[window]["NetProfit"]) > 0.0 for window in WINDOWS)
        net = float(metrics["NetProfit"])
        pf = float(metrics["ProfitFactor"])
        dd = float(metrics["MaxClosedDrawdownPercent"])
        if name == "base":
            gate = abs(net - EXPECTED_NET) <= 0.001 and positive_windows == len(WINDOWS)
        elif name == "light":
            gate = net > 0.0 and all_eras_positive and positive_windows == len(WINDOWS)
        elif name == "moderate":
            gate = net > 0.0 and pf >= 1.20 and dd <= 6.0 and all_eras_positive
        else:
            gate = net > 0.0 and pf >= 1.10 and dd <= 8.0
        rows.append(
            {
                "Scenario": name,
                "AddedCostRPerTrade": added_cost_r,
                "Trades": len(trades),
                "ExtraCost": round(sum(added_cost_r * trade.initial_risk for trade in trades), 2),
                "NetProfit": round(net, 2),
                "TotalReturnPercent": round(100.0 * net / METHOD.INITIAL_BALANCE, 3),
                "CagrPercent": round(
                    100.0
                    * (((METHOD.INITIAL_BALANCE + net) / METHOD.INITIAL_BALANCE) ** (1.0 / METHOD.TEST_YEARS) - 1.0),
                    3,
                ),
                "ProfitFactor": round(pf, 4),
                "MaxClosedDrawdownPercent": round(dd, 4),
                **era_nets,
                "PositiveWindows": positive_windows,
                "AllBroadErasPositive": all_eras_positive,
                "GatePass": gate,
            }
        )
    return rows, window_rows


def run_monte_carlo(trades: list[Trade]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    trade_count = len(trades)
    for scenario in METHOD.MC_SCENARIOS:
        rng = random.Random(int(scenario["seed"]))
        net_values: list[float] = []
        pf_values: list[float] = []
        dd_values: list[float] = []
        loss_run_values: list[float] = []
        for _ in range(int(scenario["trials"])):
            values: list[float] = []
            for _ in range(trade_count):
                trade = trades[rng.randrange(trade_count)]
                if trade.profit > 0.0 and rng.random() < float(scenario["missed_winner_probability"]):
                    values.append(0.0)
                    continue
                stress_r = rng.random() * float(scenario["max_slippage_r"])
                stress_r += rng.random() * float(scenario["max_delay_r"])
                if rng.random() < float(scenario["spread_shock_probability"]):
                    stress_r += rng.random() * float(scenario["max_spread_shock_r"])
                values.append(trade.profit - stress_r * trade.initial_risk)
            metrics = METHOD.path_metrics(values)
            net_values.append(float(metrics["NetProfit"]))
            pf_values.append(float(metrics["ProfitFactor"]))
            dd_values.append(float(metrics["MaxClosedDrawdownPercent"]))
            loss_run_values.append(float(metrics["MaxConsecutiveLosses"]))
        p05_net = METHOD.percentile(net_values, 5.0)
        median_pf = median(pf_values)
        p95_dd = METHOD.percentile(dd_values, 95.0)
        p95_loss_run = METHOD.percentile(loss_run_values, 95.0)
        red_trial_percent = 100.0 * sum(value < 0.0 for value in net_values) / len(net_values)
        gate = (
            p05_net > float(scenario["min_p05_net"])
            and median_pf >= float(scenario["min_median_pf"])
            and p95_dd <= float(scenario["max_p95_dd_percent"])
            and red_trial_percent <= float(scenario["max_red_trial_percent"])
            and p95_loss_run <= float(scenario["max_p95_loss_run"])
        )
        rows.append(
            {
                "Scenario": scenario["name"],
                "Trials": scenario["trials"],
                "Seed": scenario["seed"],
                "BootstrapWithReplacement": True,
                "MaxSlippageR": scenario["max_slippage_r"],
                "MaxDelayR": scenario["max_delay_r"],
                "MaxSpreadShockR": scenario["max_spread_shock_r"],
                "SpreadShockProbability": scenario["spread_shock_probability"],
                "MissedWinnerProbability": scenario["missed_winner_probability"],
                "P05NetProfit": round(p05_net, 2),
                "MedianNetProfit": round(median(net_values), 2),
                "P95NetProfit": round(METHOD.percentile(net_values, 95.0), 2),
                "MedianProfitFactor": round(median_pf, 4),
                "P95MaxClosedDrawdownPercent": round(p95_dd, 4),
                "P95MaxConsecutiveLosses": round(p95_loss_run, 2),
                "RedTrialPercent": round(red_trial_percent, 3),
                "GatePass": gate,
            }
        )
    return rows


def money(value: float) -> str:
    return f"{'+' if value >= 0.0 else '-'}${abs(value):,.2f}"


def main() -> int:
    trades = load_trades()
    cost_rows, cost_window_rows = run_cost_stress(trades)
    mc_rows = run_monte_carlo(trades)
    cost_gate = all(bool(row["GatePass"]) for row in cost_rows)
    monte_gate = all(bool(row["GatePass"]) for row in mc_rows)
    light_windows = next(row for row in cost_rows if row["Scenario"] == "light")["PositiveWindows"]
    moderate_windows = next(row for row in cost_rows if row["Scenario"] == "moderate")["PositiveWindows"]
    severe_windows = next(row for row in cost_rows if row["Scenario"] == "severe")["PositiveWindows"]
    window_gate = int(light_windows) == len(WINDOWS)
    triage_pass = cost_gate and monte_gate and window_gate
    status = "POSTHOC_STRESS_TRIAGE_PASS" if triage_pass else "POSTHOC_STRESS_TRIAGE_FAIL"
    next_action = (
        "RUN_FROZEN_MT5_GATE_WHEN_UNLOCKED"
        if triage_pass
        else "REJECT_OR_REPAIR_BEFORE_MT5_GATE"
    )

    write_csv(COST_CSV, cost_rows)
    write_csv(COST_WINDOW_CSV, cost_window_rows)
    write_csv(MC_CSV, mc_rows)
    decision = [
        {
            "Status": status,
            "NextAction": next_action,
            "CostGatePass": cost_gate,
            "MonteCarloGatePass": monte_gate,
            "LightCostAllWindowsPositive": window_gate,
            "ModerateCostPositiveWindows": moderate_windows,
            "SevereCostPositiveWindows": severe_windows,
            "SevereCostNoRedWindowGate": int(severe_windows) == len(WINDOWS),
            "AcceptedTrades": len(trades),
            "PostHocOnly": True,
            "TargetCompileStatus": "NOT_RUN_LOCAL_LOCK_ACTIVE",
            "TargetBacktestStatus": "NOT_RUN_LOCAL_LOCK_ACTIVE",
            "ForwardCandidateChanged": False,
            "RealAccountApproved": False,
            "CollisionLedgerSha256": sha256(LEDGER),
            "FrozenStressMethodSha256": sha256(FROZEN_METHOD),
            "TargetSourceSha256": sha256(TARGET_SOURCE),
            "TargetProfileSha256": sha256(TARGET_PROFILE),
        }
    ]
    write_csv(DECISION_CSV, decision)

    lines = [
        "# RDMC Diversified Repair Collision Stress Decision",
        "",
        f"**Decision: {status.replace('_', ' ')}. This is post-hoc triage, not executable MT5 evidence or a new best.**",
        "",
        f"- Accepted collision-adjusted trades: `{len(trades)}`; base net `{money(EXPECTED_NET)}`",
        f"- Cost gate: `{cost_gate}`; Monte Carlo gate: `{monte_gate}`; light-cost 12-window gate: `{window_gate}`",
        f"- Window warning: moderate cost remains `{moderate_windows}/12` positive; severe cost falls to `{severe_windows}/12` because 2019 and 2022 turn slightly negative",
        f"- Next action: `{next_action}`",
        f"- Collision ledger SHA-256: `{sha256(LEDGER)}`",
        f"- Frozen stress-method SHA-256: `{sha256(FROZEN_METHOD)}`",
        f"- Target source SHA-256: `{sha256(TARGET_SOURCE)}`",
        f"- Target profile SHA-256: `{sha256(TARGET_PROFILE)}`",
        "",
        "## Deterministic Added Cost",
        "",
        "| Scenario | Added R/trade | Extra cost | Net | CAGR | PF | Closed DD | Positive windows | Older | Middle | Recent | Gate |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in cost_rows:
        lines.append(
            f"| {row['Scenario']} | {float(row['AddedCostRPerTrade']):.2f}R | "
            f"${float(row['ExtraCost']):,.2f} | {money(float(row['NetProfit']))} | "
            f"{float(row['CagrPercent']):.3f}%/yr | {float(row['ProfitFactor']):.3f} | "
            f"{float(row['MaxClosedDrawdownPercent']):.3f}% | {row['PositiveWindows']}/12 | "
            f"{money(float(row['Older2015To2018']))} | {money(float(row['Middle2019To2022']))} | "
            f"{money(float(row['Recent2023To2026']))} | {row['GatePass']} |"
        )
    lines.extend(
        [
            "",
            "## Bootstrap Monte Carlo",
            "",
            "| Scenario | Trials | P05 net | Median net | Median PF | P95 closed DD | P95 loss run | Red trials | Gate |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---|",
        ]
    )
    for row in mc_rows:
        lines.append(
            f"| {row['Scenario']} | {row['Trials']} | {money(float(row['P05NetProfit']))} | "
            f"{money(float(row['MedianNetProfit']))} | {float(row['MedianProfitFactor']):.3f} | "
            f"{float(row['P95MaxClosedDrawdownPercent']):.3f}% | "
            f"{float(row['P95MaxConsecutiveLosses']):.0f} | {float(row['RedTrialPercent']):.3f}% | "
            f"{row['GatePass']} |"
        )
    lines.extend(
        [
            "",
            "## Hard Boundary",
            "",
            "- The ledger combines standalone historical runs. Collision blocking can change later signals, cooldowns, limits, and equity-based sizing in the actual EA.",
            "- Bootstrap sampling cannot recreate intratrade drawdown, broker execution, market-regime order, or future market behavior.",
            "- Drawdown here is closed-trade only. Component reports came from different source versions and starting-balance contexts.",
            "- The target source is uncompiled and untested while the local MT5 launch locks are active.",
            "- Passing only earns a future frozen MT5 gate. It cannot change the registered forward candidate or approve real-account trading.",
        ]
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(
        f"{status} accepted={len(trades)} cost={cost_gate} monte={monte_gate} "
        f"light_windows={light_windows}/12"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
