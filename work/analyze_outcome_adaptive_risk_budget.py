from __future__ import annotations

import argparse
import csv
import hashlib
import math
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable


EXPECTED_LEDGER_SHA256 = "2F7A8A8854F8F33325498AE0F194202E7BB15F28F2644FC4F9B08DE8B740413B"
STARTING_BALANCE = 10_000.0
OPEN_RISK_CAP = 0.0075


@dataclass(frozen=True)
class Trade:
    index: int
    lane: str
    entry: datetime
    exit: datetime
    initial_risk: float
    risk_r: float
    profit: float
    actual_risk_fraction: float = 0.0


@dataclass(frozen=True)
class Variant:
    name: str
    lookback: int = 0
    hot_mean_r: float = math.inf
    cold_mean_r: float = -math.inf
    cold_multiplier: float = 1.0
    normal_multiplier: float = 1.0
    hot_multiplier: float = 1.0
    cold_drawdown_r: float = math.inf
    hot_drawdown_r: float = math.inf

    @property
    def adaptive(self) -> bool:
        return self.lookback > 0


@dataclass
class Metrics:
    net: float
    ending_balance: float
    profit_factor: float
    trades: int
    closed_drawdown_percent: float
    risk_floor_drawdown_percent: float
    recovery: float
    max_consecutive_losses: int
    hot_entries: int
    normal_entries: int
    cold_entries: int
    capped_entries: int
    year_profit: dict[int, float]


VARIANTS = [
    Variant("fixed_control"),
    Variant("oarb_center_n12_h15_c50_dd25", 12, 0.15, 0.0, 0.50, 1.0, 1.25, 2.5, 1.0),
    Variant("oarb_n08_h15_c50_dd25", 8, 0.15, 0.0, 0.50, 1.0, 1.25, 2.5, 1.0),
    Variant("oarb_n16_h15_c50_dd25", 16, 0.15, 0.0, 0.50, 1.0, 1.25, 2.5, 1.0),
    Variant("oarb_n12_h10_c50_dd25", 12, 0.10, 0.0, 0.50, 1.0, 1.25, 2.5, 1.0),
    Variant("oarb_n12_h20_c50_dd25", 12, 0.20, 0.0, 0.50, 1.0, 1.25, 2.5, 1.0),
    Variant("oarb_n12_h15_c75_dd25", 12, 0.15, 0.0, 0.75, 1.0, 1.25, 2.5, 1.0),
    Variant("oarb_n12_h15_c50_dd20", 12, 0.15, 0.0, 0.50, 1.0, 1.25, 2.0, 1.0),
    Variant("oarb_n12_h15_c50_dd30", 12, 0.15, 0.0, 0.50, 1.0, 1.25, 3.0, 1.0),
]

WINDOWS = {
    "full_2015_2026": (datetime(2015, 1, 1), datetime(2026, 7, 17)),
    "discovery_2015_2020": (datetime(2015, 1, 1), datetime(2021, 1, 1)),
    "later_2021_2026": (datetime(2021, 1, 1), datetime(2026, 7, 17)),
    "older_2015_2018": (datetime(2015, 1, 1), datetime(2019, 1, 1)),
    "middle_2019_2022": (datetime(2019, 1, 1), datetime(2023, 1, 1)),
    "recent_2023_2026": (datetime(2023, 1, 1), datetime(2026, 7, 17)),
}

COST_SCENARIOS = {"base": 0.0, "cost_005r": 0.05, "cost_010r": 0.10}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def parse_time(value: str) -> datetime:
    return datetime.strptime(value, "%Y-%m-%d %H:%M:%S")


def load_trades(path: Path) -> list[Trade]:
    if sha256(path) != EXPECTED_LEDGER_SHA256:
        raise RuntimeError(f"Trade-ledger identity changed: {sha256(path)}")
    raw: list[Trade] = []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        for index, row in enumerate(csv.DictReader(handle)):
            raw.append(
                Trade(
                    index=index,
                    lane=row["Lane"],
                    entry=parse_time(row["EntryTime"]),
                    exit=parse_time(row["ExitTime"]),
                    initial_risk=float(row["InitialRiskMoney"]),
                    risk_r=float(row["RiskR"]),
                    profit=float(row["Profit"]),
                )
            )
    if len(raw) != 362:
        raise RuntimeError(f"Expected 362 trades, found {len(raw)}")
    lane_counts: dict[str, int] = defaultdict(int)
    for trade in raw:
        lane_counts[trade.lane] += 1
    if dict(lane_counts) != {"reversion": 48, "momentum": 314}:
        raise RuntimeError(f"Lane counts changed: {dict(lane_counts)}")

    events: list[tuple[datetime, int, Trade]] = []
    for trade in raw:
        events.append((trade.entry, 1, trade))
        events.append((trade.exit, 0, trade))
    events.sort(key=lambda event: (event[0], event[1], event[2].index))
    balance = STARTING_BALANCE
    entry_balance: dict[int, float] = {}
    for _, event_type, trade in events:
        if event_type == 1:
            entry_balance[trade.index] = balance
        else:
            balance += trade.profit
    if abs((balance - STARTING_BALANCE) - 1615.36) > 0.01:
        raise RuntimeError(f"Ledger net changed: {balance - STARTING_BALANCE:.2f}")
    return [
        Trade(
            **{key: getattr(trade, key) for key in ("index", "lane", "entry", "exit", "initial_risk", "risk_r", "profit")},
            actual_risk_fraction=trade.initial_risk / entry_balance[trade.index],
        )
        for trade in raw
    ]


def state_for_entry(
    variant: Variant,
    outcomes: list[float],
    cumulative_r: float,
    peak_r: float,
) -> tuple[str, float]:
    if not variant.adaptive or len(outcomes) < variant.lookback:
        return "normal", 1.0
    recent_mean = sum(outcomes[-variant.lookback :]) / variant.lookback
    drawdown_r = peak_r - cumulative_r
    if recent_mean <= variant.cold_mean_r or drawdown_r >= variant.cold_drawdown_r:
        return "cold", variant.cold_multiplier
    if recent_mean >= variant.hot_mean_r and drawdown_r <= variant.hot_drawdown_r:
        return "hot", variant.hot_multiplier
    return "normal", variant.normal_multiplier


def simulate(
    trades: Iterable[Trade],
    variant: Variant,
    start: datetime,
    end: datetime,
    cost_r: float,
) -> Metrics:
    selected = [trade for trade in trades if trade.entry >= start and trade.exit < end]
    events: list[tuple[datetime, int, Trade]] = []
    for trade in selected:
        events.append((trade.entry, 1, trade))
        events.append((trade.exit, 0, trade))
    events.sort(key=lambda event: (event[0], event[1], event[2].index))

    balance = STARTING_BALANCE
    closed_peak = balance
    risk_floor_peak = balance
    closed_max_dd = 0.0
    risk_floor_max_dd = 0.0
    risk_floor_max_dd_money = 0.0
    open_risk: dict[int, float] = {}
    lane_outcomes: dict[str, list[float]] = defaultdict(list)
    lane_cumulative: dict[str, float] = defaultdict(float)
    lane_peak: dict[str, float] = defaultdict(float)
    state_counts = defaultdict(int)
    capped_entries = 0
    gross_profit = 0.0
    gross_loss = 0.0
    consecutive_losses = 0
    max_consecutive_losses = 0
    year_profit: dict[int, float] = defaultdict(float)

    for _, event_type, trade in events:
        if event_type == 1:
            state, multiplier = state_for_entry(
                variant,
                lane_outcomes[trade.lane],
                lane_cumulative[trade.lane],
                lane_peak[trade.lane],
            )
            desired_risk = balance * trade.actual_risk_fraction * multiplier
            available_risk = max(0.0, balance * OPEN_RISK_CAP - sum(open_risk.values()))
            risk_money = min(desired_risk, available_risk)
            if risk_money + 1e-9 < desired_risk:
                capped_entries += 1
            open_risk[trade.index] = risk_money
            state_counts[state] += 1
        else:
            risk_money = open_risk.pop(trade.index)
            observed_r = trade.risk_r - cost_r
            profit = risk_money * observed_r
            balance += profit
            year_profit[trade.exit.year] += profit
            if profit >= 0.0:
                gross_profit += profit
                consecutive_losses = 0
            else:
                gross_loss += -profit
                consecutive_losses += 1
                max_consecutive_losses = max(max_consecutive_losses, consecutive_losses)
            lane_outcomes[trade.lane].append(observed_r)
            lane_cumulative[trade.lane] += observed_r
            lane_peak[trade.lane] = max(lane_peak[trade.lane], lane_cumulative[trade.lane])
            closed_peak = max(closed_peak, balance)
            if closed_peak > 0.0:
                closed_max_dd = max(closed_max_dd, 100.0 * (closed_peak - balance) / closed_peak)

        risk_floor = balance - sum(open_risk.values())
        risk_floor_peak = max(risk_floor_peak, balance)
        if risk_floor_peak > 0.0:
            risk_floor_max_dd_money = max(risk_floor_max_dd_money, risk_floor_peak - risk_floor)
            risk_floor_max_dd = max(
                risk_floor_max_dd,
                100.0 * (risk_floor_peak - risk_floor) / risk_floor_peak,
            )

    net = balance - STARTING_BALANCE
    return Metrics(
        net=net,
        ending_balance=balance,
        profit_factor=gross_profit / gross_loss if gross_loss > 0.0 else math.inf,
        trades=len(selected),
        closed_drawdown_percent=closed_max_dd,
        risk_floor_drawdown_percent=risk_floor_max_dd,
        recovery=net / risk_floor_max_dd_money if risk_floor_max_dd_money > 0.0 else math.inf,
        max_consecutive_losses=max_consecutive_losses,
        hot_entries=state_counts["hot"],
        normal_entries=state_counts["normal"],
        cold_entries=state_counts["cold"],
        capped_entries=capped_entries,
        year_profit=dict(sorted(year_profit.items())),
    )


def metric_row(scenario: str, variant: Variant, window: str, metrics: Metrics) -> dict[str, object]:
    return {
        "Scenario": scenario,
        "Variant": variant.name,
        "Window": window,
        "NetProfit": f"{metrics.net:.2f}",
        "EndingBalance": f"{metrics.ending_balance:.2f}",
        "ProfitFactor": f"{metrics.profit_factor:.4f}",
        "Trades": metrics.trades,
        "ClosedDrawdownPercent": f"{metrics.closed_drawdown_percent:.4f}",
        "RiskFloorDrawdownPercent": f"{metrics.risk_floor_drawdown_percent:.4f}",
        "Recovery": f"{metrics.recovery:.4f}",
        "MaxConsecutiveLosses": metrics.max_consecutive_losses,
        "HotEntries": metrics.hot_entries,
        "NormalEntries": metrics.normal_entries,
        "ColdEntries": metrics.cold_entries,
        "CappedEntries": metrics.capped_entries,
    }


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def percent_improvement(candidate: float, control: float) -> float:
    if control <= 0.0:
        return -math.inf
    return 100.0 * (candidate - control) / control


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--ledger",
        default="release/transferable-portfolio-v0.1/evidence/TRANSFERABLE_PORTFOLIO_MODEL4_TRADES.csv",
    )
    parser.add_argument("--results", default="outputs/OUTCOME_ADAPTIVE_RISK_BUDGET_RESULTS.csv")
    parser.add_argument("--annual", default="outputs/OUTCOME_ADAPTIVE_RISK_BUDGET_ANNUAL.csv")
    parser.add_argument("--gates", default="outputs/OUTCOME_ADAPTIVE_RISK_BUDGET_GATES.csv")
    parser.add_argument("--decision", default="outputs/OUTCOME_ADAPTIVE_RISK_BUDGET_DECISION.md")
    args = parser.parse_args()

    ledger = Path(args.ledger)
    trades = load_trades(ledger)
    results: dict[tuple[str, str, str], Metrics] = {}
    rows: list[dict[str, object]] = []
    for scenario, cost_r in COST_SCENARIOS.items():
        for variant in VARIANTS:
            for window, (start, end) in WINDOWS.items():
                metrics = simulate(trades, variant, start, end, cost_r)
                results[(scenario, variant.name, window)] = metrics
                rows.append(metric_row(scenario, variant, window, metrics))
    write_csv(Path(args.results), rows)

    annual_rows: list[dict[str, object]] = []
    for variant in VARIANTS:
        full = results[("base", variant.name, "full_2015_2026")]
        for year in range(2015, 2027):
            annual_rows.append(
                {
                    "Variant": variant.name,
                    "Year": year,
                    "NetProfit": f"{full.year_profit.get(year, 0.0):.2f}",
                    "Positive": full.year_profit.get(year, 0.0) >= 0.0,
                }
            )
    write_csv(Path(args.annual), annual_rows)

    control_name = "fixed_control"
    center_name = "oarb_center_n12_h15_c50_dd25"
    control_full = results[("base", control_name, "full_2015_2026")]
    center_full = results[("base", center_name, "full_2015_2026")]
    center_cost = results[("cost_005r", center_name, "full_2015_2026")]
    control_cost = results[("cost_005r", control_name, "full_2015_2026")]
    broad_windows = ("older_2015_2018", "middle_2019_2022", "recent_2023_2026")
    center_red_years = sum(value < 0.0 for value in center_full.year_profit.values())
    control_red_years = sum(value < 0.0 for value in control_full.year_profit.values())
    hot_percent = 100.0 * center_full.hot_entries / center_full.trades
    cold_percent = 100.0 * center_full.cold_entries / center_full.trades

    gate_rows: list[dict[str, object]] = []

    def gate(name: str, passed: bool, evidence: str) -> None:
        gate_rows.append({"Gate": name, "Pass": passed, "Evidence": evidence})

    gate("control-reproduction", abs(control_full.net - 1615.36) <= 0.01 and control_full.trades == 362, f"net={control_full.net:.2f};trades={control_full.trades}")
    discovery_improvement = percent_improvement(
        results[("base", center_name, "discovery_2015_2020")].net,
        results[("base", control_name, "discovery_2015_2020")].net,
    )
    later_improvement = percent_improvement(
        results[("base", center_name, "later_2021_2026")].net,
        results[("base", control_name, "later_2021_2026")].net,
    )
    full_improvement = percent_improvement(center_full.net, control_full.net)
    cost_improvement = percent_improvement(center_cost.net, control_cost.net)
    gate("discovery-improvement", discovery_improvement >= 5.0, f"improvement={discovery_improvement:.3f}%")
    gate("later-improvement", later_improvement >= 3.0, f"improvement={later_improvement:.3f}%")
    gate("continuous-improvement", full_improvement >= 7.5, f"improvement={full_improvement:.3f}%")
    gate("cost-improvement", cost_improvement >= 5.0, f"improvement={cost_improvement:.3f}%")
    gate("broad-restarts-positive", all(results[("base", center_name, window)].net > 0.0 for window in broad_windows), ";".join(f"{window}={results[('base', center_name, window)].net:.2f}" for window in broad_windows))
    gate("profit-factor", center_full.profit_factor >= 1.50 and center_full.profit_factor >= control_full.profit_factor - 0.05, f"center={center_full.profit_factor:.4f};control={control_full.profit_factor:.4f}")
    gate("risk-floor-drawdown", center_full.risk_floor_drawdown_percent <= 4.0 and center_full.risk_floor_drawdown_percent <= control_full.risk_floor_drawdown_percent + 0.50, f"center={center_full.risk_floor_drawdown_percent:.4f}%;control={control_full.risk_floor_drawdown_percent:.4f}%")
    gate("red-years", center_red_years <= control_red_years, f"center={center_red_years};control={control_red_years}")
    gate("state-activity", 5.0 <= hot_percent <= 60.0 and cold_percent > 0.0, f"hot={hot_percent:.2f}%;cold={cold_percent:.2f}%")

    neighbor_names = [variant.name for variant in VARIANTS if variant.adaptive and variant.name != center_name]
    neighbor_passes = 0
    for name in neighbor_names:
        full = results[("base", name, "full_2015_2026")]
        cost = results[("cost_005r", name, "full_2015_2026")]
        if (
            full.net >= control_full.net
            and full.risk_floor_drawdown_percent <= 4.0
            and cost.net > 0.0
            and all(results[("base", name, window)].net > 0.0 for window in broad_windows)
        ):
            neighbor_passes += 1
    gate("neighbor-support", neighbor_passes >= 5, f"passes={neighbor_passes}/{len(neighbor_names)}")
    write_csv(Path(args.gates), gate_rows)

    passed = all(bool(row["Pass"]) for row in gate_rows)
    decision = "ADVANCE TO SEPARATE MQL RESEARCH FORK" if passed else "REJECT BEFORE MQL IMPLEMENTATION"
    table_lines = []
    for variant in VARIANTS:
        full = results[("base", variant.name, "full_2015_2026")]
        discovery = results[("base", variant.name, "discovery_2015_2020")]
        later = results[("base", variant.name, "later_2021_2026")]
        stressed = results[("cost_005r", variant.name, "full_2015_2026")]
        table_lines.append(
            f"| `{variant.name}` | ${full.net:,.2f} | ${discovery.net:,.2f} | ${later.net:,.2f} | {full.profit_factor:.3f} | {full.risk_floor_drawdown_percent:.3f}% | ${stressed.net:,.2f} |"
        )
    gate_lines = [f"| {row['Gate']} | {row['Pass']} | {row['Evidence']} |" for row in gate_rows]
    markdown = [
        "# Outcome-Adaptive Risk-Budget Decision",
        "",
        f"**Decision: {decision}.**",
        "",
        "This analytical screen used only previously closed same-lane outcomes at each entry. It changed no signal, exit, stop, date, month, or account risk cap. It is not an MT5 implementation or live approval.",
        "",
        "## Full Results",
        "",
        "| Variant | Full net | Discovery net | Later net | PF | Risk-floor DD | 0.05R net |",
        "|---|---:|---:|---:|---:|---:|---:|",
        *table_lines,
        "",
        "## Frozen Gates",
        "",
        "| Gate | Pass | Evidence |",
        "|---|---:|---|",
        *gate_lines,
        "",
        f"Fixed-control reproduction: `${control_full.net:,.2f}` across `{control_full.trades}` trades. Center full improvement: `{full_improvement:.3f}%`; discovery: `{discovery_improvement:.3f}%`; later chronological: `{later_improvement:.3f}%`; 0.05R stress: `{cost_improvement:.3f}%`.",
        "",
        "The operational RC2 candidate, forward profile, registration drafts, and real-account lock remain unchanged.",
    ]
    Path(args.decision).write_text("\n".join(markdown) + "\n", encoding="ascii")
    print(f"DECISION={decision}")
    print(f"CONTROL_NET={control_full.net:.2f}")
    print(f"CENTER_NET={center_full.net:.2f}")
    print(f"FULL_IMPROVEMENT={full_improvement:.3f}%")
    print(f"DISCOVERY_IMPROVEMENT={discovery_improvement:.3f}%")
    print(f"LATER_IMPROVEMENT={later_improvement:.3f}%")
    print(f"COST_IMPROVEMENT={cost_improvement:.3f}%")
    print(f"GATES={sum(bool(row['Pass']) for row in gate_rows)}/{len(gate_rows)}")
    print(f"NEIGHBORS={neighbor_passes}/{len(neighbor_names)}")


if __name__ == "__main__":
    main()
