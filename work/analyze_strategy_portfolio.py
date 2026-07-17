#!/usr/bin/env python3
"""Risk-normalized portfolio screen for independently tested XAUUSD streams."""

from __future__ import annotations

import csv
import math
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from statistics import mean


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_CSV = ROOT / "outputs" / "STRATEGY_PORTFOLIO_SCREEN.csv"
OUTPUT_MD = ROOT / "outputs" / "STRATEGY_PORTFOLIO_SCREEN.md"
OUTPUT_YEARLY = ROOT / "outputs" / "STRATEGY_PORTFOLIO_TOP_YEARLY.csv"
STARTING_BALANCE = 10_000.0
START_DATE = datetime(2015, 1, 1)
END_DATE = datetime(2026, 7, 12)
YEARS = (END_DATE - START_DATE).days / 365.25
OPEN_RISK_CAP_PERCENT = 3.0
STRESS_R_PER_TRADE = 0.05

STREAM_FILES = {
    "money": ROOT / "outputs" / "MONEY_READY_BALANCED_REALTICK_RISK_TRADES.csv",
    "highprofit": ROOT / "outputs" / "PEAK_TRAIL_UNBLOCK_HIGHPROFIT_RISK_TRADES.csv",
    "donchian": ROOT / "outputs" / "DAILY_DONCHIAN_REALTICK_TRADES.csv",
}


@dataclass(frozen=True)
class Trade:
    stream: str
    index: int
    entry: datetime
    exit: datetime
    risk_r: float
    side: str


@dataclass
class OpenTrade:
    trade: Trade
    risk_cash: float
    desired_risk_cash: float


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value)


def load_trades() -> dict[str, list[Trade]]:
    streams: dict[str, list[Trade]] = {}
    for stream, path in STREAM_FILES.items():
        if not path.exists():
            raise FileNotFoundError(path)
        trades: list[Trade] = []
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            for index, row in enumerate(csv.DictReader(handle), start=1):
                trades.append(
                    Trade(
                        stream=stream,
                        index=index,
                        entry=parse_time(row["EntryTime"]),
                        exit=parse_time(row["ExitTime"]),
                        risk_r=float(row["RiskR"]),
                        side=row["Side"].strip().lower(),
                    )
                )
        streams[stream] = trades
    return streams


def month_key(value: datetime) -> str:
    return f"{value.year:04d}-{value.month:02d}"


def month_range(start: datetime, end: datetime) -> list[str]:
    result: list[str] = []
    year, month = start.year, start.month
    while (year, month) <= (end.year, end.month):
        result.append(f"{year:04d}-{month:02d}")
        month += 1
        if month == 13:
            year += 1
            month = 1
    return result


MONTHS = month_range(START_DATE, END_DATE)


def pearson(left: list[float], right: list[float]) -> float:
    if len(left) != len(right) or len(left) < 2:
        return 0.0
    left_mean = mean(left)
    right_mean = mean(right)
    numerator = sum((a - left_mean) * (b - right_mean) for a, b in zip(left, right))
    left_sum = sum((a - left_mean) ** 2 for a in left)
    right_sum = sum((b - right_mean) ** 2 for b in right)
    denominator = math.sqrt(left_sum * right_sum)
    return numerator / denominator if denominator > 0 else 0.0


def stream_relationships(streams: dict[str, list[Trade]]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    names = sorted(streams)
    for left_index, left_name in enumerate(names):
        left = streams[left_name]
        left_monthly = defaultdict(float)
        for trade in left:
            left_monthly[month_key(trade.exit)] += trade.risk_r
        for right_name in names[left_index + 1 :]:
            right = streams[right_name]
            right_monthly = defaultdict(float)
            for trade in right:
                right_monthly[month_key(trade.exit)] += trade.risk_r

            exact_entries = {
                (trade.entry, trade.side) for trade in left
            } & {(trade.entry, trade.side) for trade in right}
            overlap_pairs = 0
            opposite_overlap_pairs = 0
            for first in left:
                for second in right:
                    if first.entry < second.exit and second.entry < first.exit:
                        overlap_pairs += 1
                        if first.side != second.side:
                            opposite_overlap_pairs += 1

            rows.append(
                {
                    "Left": left_name,
                    "Right": right_name,
                    "MonthlyRCorrelation": round(
                        pearson(
                            [left_monthly[m] for m in MONTHS],
                            [right_monthly[m] for m in MONTHS],
                        ),
                        4,
                    ),
                    "ExactSameSideEntries": len(exact_entries),
                    "OverlappingTradePairs": overlap_pairs,
                    "OppositeSideOverlapPairs": opposite_overlap_pairs,
                }
            )
    return rows


def simulate(
    streams: dict[str, list[Trade]],
    risk_percent: dict[str, float],
    stress_r: float,
) -> tuple[dict[str, float | int], dict[int, dict[str, float | int]]]:
    events: list[tuple[datetime, int, Trade]] = []
    for stream, trades in streams.items():
        if risk_percent[stream] <= 0:
            continue
        for trade in trades:
            events.append((trade.entry, 1, trade))
            events.append((trade.exit, 0, trade))
    events.sort(key=lambda item: (item[0], item[1], item[2].stream, item[2].index))

    balance = STARTING_BALANCE
    peak_balance = balance
    max_closed_dd = 0.0
    max_floor_dd = 0.0
    max_floor_dd_money = 0.0
    max_open_risk_percent = 0.0
    open_trades: dict[tuple[str, int], OpenTrade] = {}
    open_risk = 0.0
    pnl_values: list[float] = []
    yearly_pnl = defaultdict(float)
    yearly_trades = defaultdict(int)
    monthly_pnl = defaultdict(float)
    skipped = 0
    scaled = 0
    max_consecutive_losses = 0
    consecutive_losses = 0

    def update_drawdown() -> None:
        nonlocal peak_balance, max_closed_dd, max_floor_dd, max_floor_dd_money
        peak_balance = max(peak_balance, balance)
        if peak_balance <= 0:
            return
        closed_dd = 100.0 * (peak_balance - balance) / peak_balance
        floor_equity = balance - open_risk
        floor_dd_money = peak_balance - floor_equity
        floor_dd = 100.0 * floor_dd_money / peak_balance
        max_closed_dd = max(max_closed_dd, closed_dd)
        if floor_dd > max_floor_dd:
            max_floor_dd = floor_dd
            max_floor_dd_money = floor_dd_money

    for timestamp, event_type, trade in events:
        key = (trade.stream, trade.index)
        if event_type == 0:
            opened = open_trades.pop(key, None)
            if opened is None:
                continue
            open_risk -= opened.risk_cash
            realized_r = trade.risk_r - stress_r
            pnl = realized_r * opened.risk_cash
            balance += pnl
            pnl_values.append(pnl)
            yearly_pnl[timestamp.year] += pnl
            yearly_trades[timestamp.year] += 1
            monthly_pnl[month_key(timestamp)] += pnl
            if pnl < 0:
                consecutive_losses += 1
                max_consecutive_losses = max(max_consecutive_losses, consecutive_losses)
            else:
                consecutive_losses = 0
            update_drawdown()
            continue

        desired = balance * risk_percent[trade.stream] / 100.0
        cap_cash = balance * OPEN_RISK_CAP_PERCENT / 100.0
        available = max(0.0, cap_cash - open_risk)
        allocated = min(desired, available)
        if allocated <= 0 or allocated < desired * 0.25:
            skipped += 1
            continue
        if allocated < desired - 1e-9:
            scaled += 1
        open_trades[key] = OpenTrade(trade, allocated, desired)
        open_risk += allocated
        if balance > 0:
            max_open_risk_percent = max(max_open_risk_percent, 100.0 * open_risk / balance)
        update_drawdown()

    gross_profit = sum(value for value in pnl_values if value > 0)
    gross_loss = -sum(value for value in pnl_values if value < 0)
    profit_factor = gross_profit / gross_loss if gross_loss > 0 else float("inf")
    net = balance - STARTING_BALANCE
    total_return = 100.0 * net / STARTING_BALANCE
    cagr = 100.0 * ((balance / STARTING_BALANCE) ** (1.0 / YEARS) - 1.0) if balance > 0 else -100.0
    annualized = total_return / YEARS
    active_years = sorted(yearly_trades)
    red_years = sum(1 for year in active_years if yearly_pnl[year] < 0)
    inactive_years = sum(1 for year in range(2015, 2027) if yearly_trades[year] == 0)
    worst_year = min(active_years, key=lambda year: yearly_pnl[year]) if active_years else 0
    worst_year_net = yearly_pnl[worst_year] if active_years else 0.0
    largest_year_net = max((yearly_pnl[year] for year in active_years), default=0.0)
    largest_year_share = 100.0 * largest_year_net / net if net > 0 else 999.0

    rolling_values: list[float] = []
    for index in range(11, len(MONTHS)):
        rolling_values.append(sum(monthly_pnl[month] for month in MONTHS[index - 11 : index + 1]))
    worst_rolling_12 = min(rolling_values, default=0.0)
    negative_rolling_12 = sum(1 for value in rolling_values if value < 0)
    recovery = net / max_floor_dd_money if max_floor_dd_money > 0 else 0.0
    return_dd = total_return / max_floor_dd if max_floor_dd > 0 else 0.0

    metrics: dict[str, float | int] = {
        "NetProfit": round(net, 2),
        "EndingBalance": round(balance, 2),
        "TotalReturnPercent": round(total_return, 2),
        "AnnualizedReturnPercent": round(annualized, 2),
        "CagrPercent": round(cagr, 2),
        "ProfitFactor": round(profit_factor, 3),
        "Trades": len(pnl_values),
        "SkippedTrades": skipped,
        "ScaledTrades": scaled,
        "MaxClosedDrawdownPercent": round(max_closed_dd, 2),
        "MaxRiskFloorDrawdownPercent": round(max_floor_dd, 2),
        "MaxOpenRiskPercent": round(max_open_risk_percent, 2),
        "RecoveryFactor": round(recovery, 2),
        "ReturnDrawdown": round(return_dd, 2),
        "RedYears": red_years,
        "InactiveYears": inactive_years,
        "WorstYear": worst_year,
        "WorstYearNet": round(worst_year_net, 2),
        "LargestYearSharePercent": round(largest_year_share, 2),
        "WorstRolling12MonthNet": round(worst_rolling_12, 2),
        "NegativeRolling12MonthWindows": negative_rolling_12,
        "MaxConsecutiveLosses": max_consecutive_losses,
    }
    yearly = {
        year: {
            "Trades": yearly_trades[year],
            "NetProfit": round(yearly_pnl[year], 2),
        }
        for year in range(2015, 2027)
    }
    return metrics, yearly


def format_percent(value: float) -> str:
    return f"{value:.2f}%"


def main() -> int:
    streams = load_trades()
    relationships = stream_relationships(streams)
    rows: list[dict[str, object]] = []
    yearly_by_key: dict[str, dict[int, dict[str, float | int]]] = {}

    highprofit_values = [round(value / 10.0, 2) for value in range(1, 11)]
    money_values = [round(value / 10.0, 2) for value in range(1, 16)]
    donchian_values = [round(value / 10.0, 2) for value in range(1, 7)]

    for highprofit_risk in highprofit_values:
        for money_risk in money_values:
            for donchian_risk in donchian_values:
                risks = {
                    "highprofit": highprofit_risk,
                    "money": money_risk,
                    "donchian": donchian_risk,
                }
                base, yearly = simulate(streams, risks, stress_r=0.0)
                stress, _ = simulate(streams, risks, stress_r=STRESS_R_PER_TRADE)
                key = f"hp{highprofit_risk:.2f}_mr{money_risk:.2f}_dd{donchian_risk:.2f}"
                eligible = (
                    base["RedYears"] == 0
                    and stress["RedYears"] == 0
                    and base["InactiveYears"] == 0
                    and base["Trades"] >= 150
                    and base["MaxRiskFloorDrawdownPercent"] <= 10.0
                    and base["ProfitFactor"] >= 1.30
                    and base["RecoveryFactor"] >= 2.0
                    and base["LargestYearSharePercent"] <= 50.0
                    and stress["NetProfit"] > 0
                )
                score = (
                    float(base["CagrPercent"])
                    + 0.35 * float(base["ReturnDrawdown"])
                    + 0.20 * float(base["ProfitFactor"])
                    - 0.10 * float(base["MaxRiskFloorDrawdownPercent"])
                    - 0.02 * float(base["NegativeRolling12MonthWindows"])
                )
                row: dict[str, object] = {
                    "Profile": key,
                    "HighProfitRiskPercent": highprofit_risk,
                    "MoneyReadyRiskPercent": money_risk,
                    "DonchianRiskPercent": donchian_risk,
                    "OpenRiskCapPercent": OPEN_RISK_CAP_PERCENT,
                    "Eligible": str(eligible),
                    "Score": round(score, 4),
                    **base,
                    "StressRPerTrade": STRESS_R_PER_TRADE,
                    "StressNetProfit": stress["NetProfit"],
                    "StressCagrPercent": stress["CagrPercent"],
                    "StressProfitFactor": stress["ProfitFactor"],
                    "StressMaxRiskFloorDrawdownPercent": stress["MaxRiskFloorDrawdownPercent"],
                    "StressRedYears": stress["RedYears"],
                    "StressWorstYearNet": stress["WorstYearNet"],
                }
                rows.append(row)
                yearly_by_key[key] = yearly

    rows.sort(
        key=lambda row: (
            row["Eligible"] == "True",
            float(row["Score"]),
            float(row["CagrPercent"]),
        ),
        reverse=True,
    )
    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    eligible_rows = [row for row in rows if row["Eligible"] == "True"]
    top_rows = eligible_rows[:20] if eligible_rows else rows[:20]
    top_keys = [str(row["Profile"]) for row in top_rows[:5]]
    with OUTPUT_YEARLY.open("w", encoding="utf-8", newline="") as handle:
        fieldnames = ["Profile", "Year", "Trades", "NetProfit"]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for key in top_keys:
            for year, values in yearly_by_key[key].items():
                writer.writerow({"Profile": key, "Year": year, **values})

    lines = [
        "# Strategy Portfolio Screen",
        "",
        "This is an analytical R-normalized portfolio test, not an MT5 combined-EA backtest and not live-trading approval.",
        "",
        f"- Starting balance: `${STARTING_BALANCE:,.0f}`",
        f"- Window: `{START_DATE.date()}` through `{END_DATE.date()}`",
        f"- Open-risk cap: `{OPEN_RISK_CAP_PERCENT:.2f}%`",
        f"- Stress: `{STRESS_R_PER_TRADE:.2f}R` deducted from every closed trade",
        f"- Grid rows: `{len(rows)}`",
        f"- Eligible rows: `{len(eligible_rows)}`",
        "- Conservative drawdown uses balance minus all open initial risk, not reconstructed tick-by-tick equity.",
        "",
        "## Stream Relationships",
        "",
        "| Left | Right | Monthly R correlation | Exact same-side entries | Overlap pairs | Opposite-side overlaps |",
        "| --- | --- | ---: | ---: | ---: | ---: |",
    ]
    for row in relationships:
        lines.append(
            f"| {row['Left']} | {row['Right']} | {float(row['MonthlyRCorrelation']):.4f} | "
            f"{row['ExactSameSideEntries']} | {row['OverlappingTradePairs']} | {row['OppositeSideOverlapPairs']} |"
        )

    lines.extend(
        [
            "",
            "## Top Rows",
            "",
            "| Profile | Eligible | Net | CAGR | PF | Risk-floor DD | Recovery | Red years | Stress red years | Worst rolling 12m |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in top_rows:
        lines.append(
            f"| `{row['Profile']}` | {row['Eligible']} | `${float(row['NetProfit']):,.2f}` | "
            f"{format_percent(float(row['CagrPercent']))} | {float(row['ProfitFactor']):.3f} | "
            f"{format_percent(float(row['MaxRiskFloorDrawdownPercent']))} | {float(row['RecoveryFactor']):.2f} | "
            f"{row['RedYears']} | {row['StressRedYears']} | `${float(row['WorstRolling12MonthNet']):,.2f}` |"
        )

    lines.extend(
        [
            "",
            "## Gate",
            "",
            "Eligibility requires zero red active years in base and 0.05R stress, activity in every calendar year, at least 150 trades, conservative drawdown no higher than 10%, PF at least 1.30, recovery at least 2.0, and no single year supplying more than half of total net.",
            "",
            "A passing analytical row only justifies implementing a true multi-lane MT5 test with independent position ownership, broker costs, netting/hedging behavior, and tick-level drawdown.",
        ]
    )
    OUTPUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        f"STRATEGY_PORTFOLIO_SCREEN_COMPLETE rows={len(rows)} eligible={len(eligible_rows)} "
        f"top={rows[0]['Profile']} output={OUTPUT_CSV}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
