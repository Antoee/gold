#!/usr/bin/env python3
"""Order-aware post-hoc stress triage for the RDMC collision ledger.

Moving-block and whole-window bootstrap paths preserve more regime clustering
than the existing IID bootstrap. This can reject a fragile architecture, but
it cannot promote a ledger assembled from standalone MT5 runs.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import random
import sys
from collections import defaultdict
from pathlib import Path
from statistics import median


ROOT = Path(__file__).resolve().parents[1]
REGIME_ANALYZER = Path(__file__).resolve()
BASE_ANALYZER = ROOT / "work" / "analyze_rdmc_diversified_repair_collision_stress.py"
IID_DECISION = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_STRESS_DECISION.csv"
IID_MONTE_CARLO = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_MONTE_CARLO.csv"

REGIME_MC_CSV = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_REGIME_MONTE_CARLO.csv"
CONCENTRATION_CSV = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_COMPONENT_CONCENTRATION.csv"
DECISION_CSV = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_REGIME_STRESS_DECISION.csv"
DECISION_MD = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_COLLISION_REGIME_STRESS_DECISION.md"

EXPECTED_BASE_ANALYZER_SHA256 = "05640197D3850365C8D31DAF9F0A152418CC1E47C79D3C5FFC3622E5067CA551"
EXPECTED_IID_DECISION_SHA256 = "C9E4DF18B49A33ADDD7144CFD252857EB508FD56CECB10F46018735D0052680F"
EXPECTED_IID_MONTE_CARLO_SHA256 = "4B16F0E132B4421AB79B99E26343446D6F9E335118EA31B9C515D7551FB30944"

TRIALS = 10_000
MAX_NET_SHARE_PERCENT = 70.0
MAX_RISK_SHARE_PERCENT = 75.0
MIN_POSITIVE_COMPONENTS = 3

SAMPLERS = (
    {"name": "moving_block_08", "kind": "moving_block", "block_length": 8},
    {"name": "moving_block_16", "kind": "moving_block", "block_length": 16},
    {"name": "moving_block_24", "kind": "moving_block", "block_length": 24},
    {"name": "whole_window", "kind": "whole_window", "block_length": 0},
)
SEEDS = {
    ("moving_block_08", "standard"): 26071821,
    ("moving_block_08", "severe"): 26071822,
    ("moving_block_16", "standard"): 26071823,
    ("moving_block_16", "severe"): 26071824,
    ("moving_block_24", "standard"): 26071825,
    ("moving_block_24", "severe"): 26071826,
    ("whole_window", "standard"): 26071827,
    ("whole_window", "severe"): 26071828,
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def normalized_text_sha256(path: Path) -> str:
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\r", "\n")
    return hashlib.sha256(text.encode("utf-8")).hexdigest().upper()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    require(bool(rows), f"No rows for {path.name}")
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def load_base_module():
    require(
        normalized_text_sha256(BASE_ANALYZER) == EXPECTED_BASE_ANALYZER_SHA256,
        "Base analyzer normalized-text identity changed",
    )
    require(sha256(IID_DECISION) == EXPECTED_IID_DECISION_SHA256, "IID decision identity changed")
    require(sha256(IID_MONTE_CARLO) == EXPECTED_IID_MONTE_CARLO_SHA256, "IID output identity changed")
    iid_rows = read_csv(IID_DECISION)
    require(len(iid_rows) == 1, "Expected one IID decision row")
    require(iid_rows[0]["Status"] == "POSTHOC_STRESS_TRIAGE_PASS", "IID stress triage no longer passes")

    spec = importlib.util.spec_from_file_location("rdmc_collision_stress_base", BASE_ANALYZER)
    require(spec is not None and spec.loader is not None, "Could not load base analyzer")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


BASE = load_base_module()


def sample_moving_blocks(trades: list[object], block_length: int, rng: random.Random) -> list[object]:
    sampled: list[object] = []
    count = len(trades)
    while len(sampled) < count:
        start = rng.randrange(count)
        for offset in range(block_length):
            sampled.append(trades[(start + offset) % count])
            if len(sampled) == count:
                break
    return sampled


def sample_whole_windows(
    by_window: dict[str, list[object]], rng: random.Random
) -> list[object]:
    sampled: list[object] = []
    for _ in BASE.WINDOWS:
        sampled.extend(by_window[BASE.WINDOWS[rng.randrange(len(BASE.WINDOWS))]])
    return sampled


def stress_values(trades: list[object], rng: random.Random, scenario: dict[str, object]) -> list[float]:
    values: list[float] = []
    for trade in trades:
        if trade.profit > 0.0 and rng.random() < float(scenario["missed_winner_probability"]):
            values.append(0.0)
            continue
        stress_r = rng.random() * float(scenario["max_slippage_r"])
        stress_r += rng.random() * float(scenario["max_delay_r"])
        if rng.random() < float(scenario["spread_shock_probability"]):
            stress_r += rng.random() * float(scenario["max_spread_shock_r"])
        values.append(trade.profit - stress_r * trade.initial_risk)
    return values


def run_regime_monte_carlo(trades: list[object]) -> list[dict[str, object]]:
    by_window: dict[str, list[object]] = defaultdict(list)
    for trade in trades:
        by_window[trade.window].append(trade)
    require(all(by_window[window] for window in BASE.WINDOWS), "Every source window must contain trades")

    rows: list[dict[str, object]] = []
    for sampler in SAMPLERS:
        for frozen_scenario in BASE.METHOD.MC_SCENARIOS:
            scenario = dict(frozen_scenario)
            stress_name = str(scenario["name"])
            seed = SEEDS[(str(sampler["name"]), stress_name)]
            rng = random.Random(seed)
            net_values: list[float] = []
            pf_values: list[float] = []
            dd_values: list[float] = []
            loss_run_values: list[float] = []
            trade_counts: list[float] = []
            for _ in range(TRIALS):
                if sampler["kind"] == "moving_block":
                    sampled = sample_moving_blocks(trades, int(sampler["block_length"]), rng)
                else:
                    sampled = sample_whole_windows(by_window, rng)
                values = stress_values(sampled, rng, scenario)
                metrics = BASE.METHOD.path_metrics(values)
                trade_counts.append(float(len(sampled)))
                net_values.append(float(metrics["NetProfit"]))
                pf_values.append(float(metrics["ProfitFactor"]))
                dd_values.append(float(metrics["MaxClosedDrawdownPercent"]))
                loss_run_values.append(float(metrics["MaxConsecutiveLosses"]))

            p05_net = BASE.METHOD.percentile(net_values, 5.0)
            median_pf = median(pf_values)
            p95_dd = BASE.METHOD.percentile(dd_values, 95.0)
            p95_loss_run = BASE.METHOD.percentile(loss_run_values, 95.0)
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
                    "Sampler": sampler["name"],
                    "StressScenario": stress_name,
                    "Trials": TRIALS,
                    "Seed": seed,
                    "BlockLength": sampler["block_length"],
                    "PreservesLocalOrder": True,
                    "MaxSlippageR": scenario["max_slippage_r"],
                    "MaxDelayR": scenario["max_delay_r"],
                    "MaxSpreadShockR": scenario["max_spread_shock_r"],
                    "SpreadShockProbability": scenario["spread_shock_probability"],
                    "MissedWinnerProbability": scenario["missed_winner_probability"],
                    "P05TradeCount": round(BASE.METHOD.percentile(trade_counts, 5.0), 2),
                    "MedianTradeCount": round(median(trade_counts), 2),
                    "P95TradeCount": round(BASE.METHOD.percentile(trade_counts, 95.0), 2),
                    "P05NetProfit": round(p05_net, 2),
                    "MedianNetProfit": round(median(net_values), 2),
                    "P95NetProfit": round(BASE.METHOD.percentile(net_values, 95.0), 2),
                    "MedianProfitFactor": round(median_pf, 4),
                    "P95MaxClosedDrawdownPercent": round(p95_dd, 4),
                    "P95MaxConsecutiveLosses": round(p95_loss_run, 2),
                    "RedTrialPercent": round(red_trial_percent, 3),
                    "GatePass": gate,
                }
            )
    return rows


def component_concentration(trades: list[object]) -> tuple[list[dict[str, object]], dict[str, object]]:
    components = sorted({trade.component for trade in trades})
    total_net = sum(trade.profit for trade in trades)
    total_risk = sum(trade.initial_risk for trade in trades)
    own_net = {component: sum(trade.profit for trade in trades if trade.component == component) for component in components}
    own_risk = {
        component: sum(trade.initial_risk for trade in trades if trade.component == component)
        for component in components
    }
    largest_net_component = max(components, key=lambda component: own_net[component])
    largest_risk_component = max(components, key=lambda component: own_risk[component])
    rows: list[dict[str, object]] = []
    largest_leave_eras: dict[str, float] = {}
    largest_leave_net = 0.0

    for component in components:
        own = [trade for trade in trades if trade.component == component]
        leave = [trade for trade in trades if trade.component != component]
        own_metrics = BASE.METHOD.path_metrics([trade.profit for trade in own])
        leave_metrics = BASE.METHOD.path_metrics([trade.profit for trade in leave])
        leave_by_window: dict[str, float] = defaultdict(float)
        for trade in leave:
            leave_by_window[trade.window] += trade.profit
        leave_eras = {
            era: sum(leave_by_window[window] for window in windows)
            for era, windows in BASE.ERA_WINDOWS.items()
        }
        if component == largest_net_component:
            largest_leave_net = float(leave_metrics["NetProfit"])
            largest_leave_eras = leave_eras
        rows.append(
            {
                "Component": component,
                "Trades": len(own),
                "TradeSharePercent": round(100.0 * len(own) / len(trades), 3),
                "NetProfit": round(own_net[component], 2),
                "NetSharePercent": round(100.0 * own_net[component] / total_net, 3),
                "InitialRiskSum": round(own_risk[component], 2),
                "RiskSharePercent": round(100.0 * own_risk[component] / total_risk, 3),
                "ComponentProfitFactor": round(float(own_metrics["ProfitFactor"]), 4),
                "IsLargestNetContributor": component == largest_net_component,
                "IsLargestRiskContributor": component == largest_risk_component,
                "LeaveOneOutNetProfit": round(float(leave_metrics["NetProfit"]), 2),
                "LeaveOneOutProfitFactor": round(float(leave_metrics["ProfitFactor"]), 4),
                "LeaveOneOutMaxClosedDrawdownPercent": round(
                    float(leave_metrics["MaxClosedDrawdownPercent"]), 4
                ),
                "LeaveOneOutPositiveWindows": sum(
                    leave_by_window[window] > 0.0 for window in BASE.WINDOWS
                ),
                "LeaveOneOutOlder2015To2018": round(leave_eras["Older2015To2018"], 2),
                "LeaveOneOutMiddle2019To2022": round(leave_eras["Middle2019To2022"], 2),
                "LeaveOneOutRecent2023To2026": round(leave_eras["Recent2023To2026"], 2),
            }
        )

    largest_net_share = 100.0 * own_net[largest_net_component] / total_net
    largest_risk_share = 100.0 * own_risk[largest_risk_component] / total_risk
    positive_components = sum(value > 0.0 for value in own_net.values())
    concentration_gate = (
        len(components) >= MIN_POSITIVE_COMPONENTS
        and positive_components >= MIN_POSITIVE_COMPONENTS
        and largest_net_share <= MAX_NET_SHARE_PERCENT
        and largest_risk_share <= MAX_RISK_SHARE_PERCENT
        and largest_leave_net > 0.0
        and all(value > 0.0 for value in largest_leave_eras.values())
    )
    summary = {
        "Components": len(components),
        "PositiveComponents": positive_components,
        "LargestNetContributor": largest_net_component,
        "LargestNetSharePercent": round(largest_net_share, 3),
        "LargestRiskContributor": largest_risk_component,
        "LargestRiskSharePercent": round(largest_risk_share, 3),
        "LeaveLargestNetProfit": round(largest_leave_net, 2),
        "LeaveLargestAllBroadErasPositive": all(value > 0.0 for value in largest_leave_eras.values()),
        "ConcentrationGatePass": concentration_gate,
    }
    return rows, summary


def money(value: float) -> str:
    return f"{'+' if value >= 0.0 else '-'}${abs(value):,.2f}"


def main() -> int:
    trades = BASE.load_trades()
    regime_rows = run_regime_monte_carlo(trades)
    concentration_rows, concentration = component_concentration(trades)
    regime_gate = all(bool(row["GatePass"]) for row in regime_rows)
    concentration_gate = bool(concentration["ConcentrationGatePass"])
    triage_pass = regime_gate and concentration_gate
    status = (
        "POSTHOC_REGIME_STRESS_TRIAGE_PASS"
        if triage_pass
        else "POSTHOC_REGIME_STRESS_TRIAGE_FAIL"
    )
    next_action = (
        "RUN_FROZEN_MT5_GATE_WHEN_UNLOCKED"
        if triage_pass
        else "REPAIR_CONCENTRATION_OR_REGIME_ROBUSTNESS_BEFORE_MT5_GATE"
    )

    write_csv(REGIME_MC_CSV, regime_rows)
    write_csv(CONCENTRATION_CSV, concentration_rows)
    decision = [
        {
            "Status": status,
            "NextAction": next_action,
            "RegimeMonteCarloGatePass": regime_gate,
            "ConcentrationGatePass": concentration_gate,
            "PassedRegimeScenarios": sum(bool(row["GatePass"]) for row in regime_rows),
            "TotalRegimeScenarios": len(regime_rows),
            "MinimumPositiveComponents": MIN_POSITIVE_COMPONENTS,
            "MaximumNetSharePercent": MAX_NET_SHARE_PERCENT,
            "MaximumRiskSharePercent": MAX_RISK_SHARE_PERCENT,
            **concentration,
            "AcceptedTrades": len(trades),
            "PostHocOnly": True,
            "ExecutableCombinedPath": False,
            "TargetCompileStatus": "NOT_RUN_LOCAL_LOCK_ACTIVE",
            "TargetBacktestStatus": "NOT_RUN_LOCAL_LOCK_ACTIVE",
            "ForwardCandidateChanged": False,
            "RealAccountApproved": False,
            "CollisionLedgerSha256": BASE.sha256(BASE.LEDGER),
            "AnalyzerIdentityMode": "LF_NORMALIZED_TEXT_SHA256",
            "RegimeAnalyzerSha256": normalized_text_sha256(REGIME_ANALYZER),
            "BaseAnalyzerSha256": normalized_text_sha256(BASE_ANALYZER),
            "IidDecisionSha256": sha256(IID_DECISION),
            "IidMonteCarloSha256": sha256(IID_MONTE_CARLO),
            "FrozenStressMethodSha256": BASE.sha256(BASE.FROZEN_METHOD),
            "TargetSourceSha256": BASE.sha256(BASE.TARGET_SOURCE),
            "TargetProfileSha256": BASE.sha256(BASE.TARGET_PROFILE),
        }
    ]
    write_csv(DECISION_CSV, decision)

    lines = [
        "# RDMC Diversified Repair Collision Regime Stress Decision",
        "",
        f"**Decision: {status.replace('_', ' ')}. This remains post-hoc triage, not executable MT5 evidence or a new best.**",
        "",
        f"- Regime Monte Carlo gate: `{regime_gate}` ({sum(bool(row['GatePass']) for row in regime_rows)}/{len(regime_rows)} scenarios)",
        f"- Component concentration gate: `{concentration_gate}`",
        f"- Largest net contributor: `{concentration['LargestNetContributor']}` at `{concentration['LargestNetSharePercent']:.3f}%` of aggregate net",
        f"- Largest risk contributor: `{concentration['LargestRiskContributor']}` at `{concentration['LargestRiskSharePercent']:.3f}%` of summed initial risk",
        f"- Net without largest contributor: `{money(float(concentration['LeaveLargestNetProfit']))}`; all broad eras positive: `{concentration['LeaveLargestAllBroadErasPositive']}`",
        f"- Next action: `{next_action}`",
        f"- Regime analyzer LF-normalized text SHA-256: `{normalized_text_sha256(REGIME_ANALYZER)}`",
        "",
        "## Order-Aware Monte Carlo",
        "",
        "| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 closed DD | P95 loss run | Red trials | Gate |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in regime_rows:
        lines.append(
            f"| {row['Sampler']} | {row['StressScenario']} | {row['Trials']} | "
            f"{money(float(row['P05NetProfit']))} | {money(float(row['MedianNetProfit']))} | "
            f"{float(row['MedianProfitFactor']):.3f} | "
            f"{float(row['P95MaxClosedDrawdownPercent']):.3f}% | "
            f"{float(row['P95MaxConsecutiveLosses']):.0f} | "
            f"{float(row['RedTrialPercent']):.3f}% | {row['GatePass']} |"
        )
    lines.extend(
        [
            "",
            "## Component Concentration",
            "",
            "The preregistered concentration gate requires at least three positive components, no more than 70% of net from one component, no more than 75% of summed initial risk from one component, and positive older/middle/recent era net after removing the largest net contributor.",
            "",
            "| Component | Trades | Net | Net share | Risk share | Leave-one-out net | Leave-one-out PF | Positive windows | Older | Middle | Recent |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in concentration_rows:
        lines.append(
            f"| {row['Component']} | {row['Trades']} | {money(float(row['NetProfit']))} | "
            f"{float(row['NetSharePercent']):.3f}% | {float(row['RiskSharePercent']):.3f}% | "
            f"{money(float(row['LeaveOneOutNetProfit']))} | "
            f"{float(row['LeaveOneOutProfitFactor']):.3f} | "
            f"{row['LeaveOneOutPositiveWindows']}/12 | "
            f"{money(float(row['LeaveOneOutOlder2015To2018']))} | "
            f"{money(float(row['LeaveOneOutMiddle2019To2022']))} | "
            f"{money(float(row['LeaveOneOutRecent2023To2026']))} |"
        )
    lines.extend(
        [
            "",
            "## Hard Boundary",
            "",
            "- Moving-block sampling preserves adjacent trade clusters; whole-window sampling preserves each sampled window's internal trade order. Neither recreates an executable combined signal path.",
            "- The source ledgers came from standalone runs. Collision blocking can alter later signals, cooldowns, limits, exits, and equity-based sizing in the actual combined EA.",
            "- Drawdown is closed-trade only. Broker fills, intratrade equity, future regimes, and cross-component state interaction remain untested.",
            "- The target source remains uncompiled and untested while both MT5 launch locks are active.",
            "- Passing can only earn scarce future MT5 gate time. It cannot change the registered forward candidate or approve real-account trading.",
        ]
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(
        f"{status} regime={sum(bool(row['GatePass']) for row in regime_rows)}/{len(regime_rows)} "
        f"concentration={concentration_gate} largest_net_share={concentration['LargestNetSharePercent']:.3f}%"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
