#!/usr/bin/env python3
"""Frozen deterministic-cost and bootstrap Monte Carlo stress for the RC2 MRE ledger."""

from __future__ import annotations

import csv
import hashlib
import math
import random
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from statistics import median


ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_MODEL4_TRADES.csv"
COST_CSV = ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_COST_STRESS.csv"
COST_YEARLY_CSV = ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_COST_STRESS_YEARLY.csv"
MC_CSV = ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_MONTE_CARLO.csv"
DECISION_CSV = ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_STRESS_DECISION.csv"
DECISION_MD = ROOT / "outputs" / "RC2_MOMENTUM_RISK_EXTENSION_STRESS_DECISION.md"

EXPECTED_LEDGER_SHA256 = "80E2E741EA508DCC2D048661FF266A72F6708812F4F75EBB96DCB1136247CE59"
EXPECTED_SOURCE_SHA256 = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"
EXPECTED_PROFILE_SHA256 = "06AE8127CF2719D7D3A19FEE069ECA3D50B83B3B0329C04F7B08E5F9135AFA5A"
EXPECTED_TRADES = 362
EXPECTED_NET = 1812.42
INITIAL_BALANCE = 10_000.0
TEST_YEARS = 4214.0 / 365.25

ERA_YEARS = {
    "Older2015To2018": range(2015, 2019),
    "Middle2019To2022": range(2019, 2023),
    "Recent2023To2026": range(2023, 2027),
}

COST_SCENARIOS = (
    ("base", 0.00),
    ("light", 0.02),
    ("moderate", 0.05),
    ("severe", 0.10),
)

MC_SCENARIOS = (
    {
        "name": "standard",
        "trials": 10_000,
        "seed": 26071801,
        "max_slippage_r": 0.04,
        "max_delay_r": 0.06,
        "max_spread_shock_r": 0.08,
        "spread_shock_probability": 0.10,
        "missed_winner_probability": 0.05,
        "min_p05_net": 0.0,
        "min_median_pf": 1.25,
        "max_p95_dd_percent": 6.0,
        "max_red_trial_percent": 5.0,
        "max_p95_loss_run": 14.0,
    },
    {
        "name": "severe",
        "trials": 10_000,
        "seed": 26071802,
        "max_slippage_r": 0.08,
        "max_delay_r": 0.12,
        "max_spread_shock_r": 0.16,
        "spread_shock_probability": 0.20,
        "missed_winner_probability": 0.10,
        "min_p05_net": 0.0,
        "min_median_pf": 1.10,
        "max_p95_dd_percent": 8.0,
        "max_red_trial_percent": 5.0,
        "max_p95_loss_run": 16.0,
    },
)


@dataclass(frozen=True)
class Trade:
    exit_time: datetime
    initial_risk: float
    profit: float


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def load_trade_file(
    path: Path, expected_hash: str, expected_trades: int, expected_net: float
) -> list[Trade]:
    ledger_hash = sha256(path)
    if ledger_hash != expected_hash:
        raise ValueError(f"Ledger identity changed: {ledger_hash}")
    trades: list[Trade] = []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            risk = float(row["InitialRiskMoney"])
            if risk <= 0.0 or not row["RiskR"]:
                raise ValueError("Every trade must have positive initial-risk coverage")
            trades.append(
                Trade(
                    exit_time=datetime.fromisoformat(row["ExitTime"]),
                    initial_risk=risk,
                    profit=float(row["Profit"]),
                )
            )
    trades.sort(key=lambda trade: trade.exit_time)
    net = round(sum(trade.profit for trade in trades), 2)
    if len(trades) != expected_trades or abs(net - expected_net) > 0.001:
        raise ValueError(f"Ledger/report mismatch: trades={len(trades)} net={net:.2f}")
    return trades


def load_trades() -> list[Trade]:
    return load_trade_file(LEDGER, EXPECTED_LEDGER_SHA256, EXPECTED_TRADES, EXPECTED_NET)


def percentile(values: list[float], percent: float) -> float:
    ordered = sorted(values)
    rank = percent / 100.0 * (len(ordered) - 1)
    lower = math.floor(rank)
    upper = math.ceil(rank)
    if lower == upper:
        return ordered[lower]
    weight = rank - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def path_metrics(values: list[float]) -> dict[str, float | int]:
    equity = INITIAL_BALANCE
    peak = INITIAL_BALANCE
    maximum_dd = 0.0
    maximum_dd_percent = 0.0
    gross_profit = 0.0
    gross_loss = 0.0
    current_loss_run = 0
    maximum_loss_run = 0
    for value in values:
        equity += value
        peak = max(peak, equity)
        maximum_dd = max(maximum_dd, peak - equity)
        maximum_dd_percent = max(maximum_dd_percent, 100.0 * (peak - equity) / peak)
        if value > 0.0:
            gross_profit += value
            current_loss_run = 0
        elif value < 0.0:
            gross_loss -= value
            current_loss_run += 1
            maximum_loss_run = max(maximum_loss_run, current_loss_run)
        else:
            current_loss_run = 0
    return {
        "NetProfit": sum(values),
        "ProfitFactor": gross_profit / gross_loss if gross_loss else float("inf"),
        "MaxClosedDrawdownMoney": maximum_dd,
        "MaxClosedDrawdownPercent": maximum_dd_percent,
        "MaxConsecutiveLosses": maximum_loss_run,
    }


def run_cost_stress(trades: list[Trade]) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    rows: list[dict[str, object]] = []
    yearly_rows: list[dict[str, object]] = []
    for name, added_cost_r in COST_SCENARIOS:
        adjusted = [(trade, trade.profit - added_cost_r * trade.initial_risk) for trade in trades]
        metrics = path_metrics([value for _, value in adjusted])
        yearly: dict[int, dict[str, float | int]] = defaultdict(lambda: {"Trades": 0, "NetProfit": 0.0})
        for trade, value in adjusted:
            year = trade.exit_time.year
            yearly[year]["Trades"] = int(yearly[year]["Trades"]) + 1
            yearly[year]["NetProfit"] = float(yearly[year]["NetProfit"]) + value
        for year in range(2015, 2027):
            yearly_rows.append(
                {
                    "Scenario": name,
                    "Year": year,
                    "Trades": int(yearly[year]["Trades"]),
                    "NetProfit": round(float(yearly[year]["NetProfit"]), 2),
                }
            )
        era_net = {
            era: round(sum(float(yearly[year]["NetProfit"]) for year in years), 2)
            for era, years in ERA_YEARS.items()
        }
        net = float(metrics["NetProfit"])
        pf = float(metrics["ProfitFactor"])
        dd = float(metrics["MaxClosedDrawdownPercent"])
        all_eras_positive = all(value > 0.0 for value in era_net.values())
        if name == "base":
            gate = abs(net - EXPECTED_NET) <= 0.001 and len(trades) == EXPECTED_TRADES
        elif name == "light":
            gate = net > 0.0
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
                "TotalReturnPercent": round(100.0 * net / INITIAL_BALANCE, 3),
                "CagrPercent": round(
                    100.0 * (((INITIAL_BALANCE + net) / INITIAL_BALANCE) ** (1.0 / TEST_YEARS) - 1.0), 3
                ),
                "ProfitFactor": round(pf, 4),
                "MaxClosedDrawdownPercent": round(dd, 4),
                **era_net,
                "AllBroadErasPositive": all_eras_positive,
                "GatePass": gate,
            }
        )
    return rows, yearly_rows


def run_monte_carlo(trades: list[Trade]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    trade_count = len(trades)
    for scenario in MC_SCENARIOS:
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
            metrics = path_metrics(values)
            net_values.append(float(metrics["NetProfit"]))
            pf_values.append(float(metrics["ProfitFactor"]))
            dd_values.append(float(metrics["MaxClosedDrawdownPercent"]))
            loss_run_values.append(float(metrics["MaxConsecutiveLosses"]))
        p05_net = percentile(net_values, 5.0)
        median_pf = median(pf_values)
        p95_dd = percentile(dd_values, 95.0)
        p95_loss_run = percentile(loss_run_values, 95.0)
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
                "P95NetProfit": round(percentile(net_values, 95.0), 2),
                "MedianProfitFactor": round(median_pf, 4),
                "P95MaxClosedDrawdownPercent": round(p95_dd, 4),
                "P95MaxConsecutiveLosses": round(p95_loss_run, 2),
                "RedTrialPercent": round(red_trial_percent, 3),
                "GatePass": gate,
            }
        )
    return rows


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def money(value: float) -> str:
    sign = "+" if value >= 0.0 else "-"
    return f"{sign}${abs(value):,.2f}"


def main() -> int:
    trades = load_trades()
    cost_rows, yearly_rows = run_cost_stress(trades)
    mc_rows = run_monte_carlo(trades)
    write_csv(COST_CSV, cost_rows)
    write_csv(COST_YEARLY_CSV, yearly_rows)
    write_csv(MC_CSV, mc_rows)
    cost_pass = all(bool(row["GatePass"]) for row in cost_rows)
    monte_pass = all(bool(row["GatePass"]) for row in mc_rows)
    status = "STRESS_GATE_PASSED" if cost_pass and monte_pass else "STRESS_GATE_FAILED"
    decision = [
        {
            "Status": status,
            "CostGatePass": cost_pass,
            "MonteCarloGatePass": monte_pass,
            "Trades": len(trades),
            "LedgerSha256": sha256(LEDGER),
            "SourceSha256": EXPECTED_SOURCE_SHA256,
            "ProfileSha256": EXPECTED_PROFILE_SHA256,
            "ForwardCandidateChanged": False,
        }
    ]
    write_csv(DECISION_CSV, decision)

    lines = [
        "# RC2 Momentum-Risk Extension Stress Decision",
        "",
        f"**Decision: {status.replace('_', ' ')}. This does not change the frozen forward candidate or approve real money.**",
        "",
        f"- Exact trades: `{len(trades)}`",
        f"- Ledger SHA-256: `{sha256(LEDGER)}`",
        f"- Cost gate: `{cost_pass}`; Monte Carlo gate: `{monte_pass}`",
        "",
        "## Deterministic Added Cost",
        "",
        "| Scenario | Added R/trade | Extra cost | Net | CAGR | PF | Closed DD | Older | Middle | Recent | Gate |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in cost_rows:
        lines.append(
            f"| {row['Scenario']} | {float(row['AddedCostRPerTrade']):.2f}R | "
            f"${float(row['ExtraCost']):,.2f} | {money(float(row['NetProfit']))} | "
            f"{float(row['CagrPercent']):.3f}%/yr | {float(row['ProfitFactor']):.3f} | "
            f"{float(row['MaxClosedDrawdownPercent']):.3f}% | {money(float(row['Older2015To2018']))} | "
            f"{money(float(row['Middle2019To2022']))} | {money(float(row['Recent2023To2026']))} | "
            f"{row['GatePass']} |"
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
            "Closed-trade drawdown does not include intratrade equity movement. Bootstrap stress measures sensitivity to sampled historical outcomes and execution degradation; it cannot prove future profitability.",
        ]
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"{status} ledger={sha256(LEDGER)} cost={len(cost_rows)} monte={len(mc_rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
