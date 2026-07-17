#!/usr/bin/env python3
"""Frozen stress screen for the clean H4, H1 reversion, and E20 momentum lanes."""

from __future__ import annotations

import csv
import hashlib
import math
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from statistics import mean


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_CSV = ROOT / "outputs" / "CLEAN_E20_THREE_LANE_PORTFOLIO_SCREEN.csv"
OUTPUT_YEARLY = ROOT / "outputs" / "CLEAN_E20_THREE_LANE_PORTFOLIO_YEARLY.csv"
OUTPUT_MD = ROOT / "outputs" / "CLEAN_E20_THREE_LANE_PORTFOLIO_SCREEN.md"

STARTING_BALANCE = 10_000.0
START_DATE = datetime(2015, 1, 1)
END_DATE = datetime(2026, 7, 16)
YEARS = (END_DATE - START_DATE).days / 365.25
OPEN_RISK_CAP_PERCENT = 2.5
LANE_DRAWDOWN_LOCK_PERCENT = 5.0
STRESS_LEVELS = (0.0, 0.05, 0.10)
IMPLEMENTATION_PROFILE = "h4_0.60_rv_0.60_mom_0.10"

STREAM_FILES = {
    "h4": ROOT / "outputs" / "H4CF_80_40_L20_A30_MODEL1_TRADES.csv",
    "reversion": ROOT / "outputs" / "H1_BAND_VWAP_DI_M12_COMPACT_MODEL4_TRADES.csv",
    "momentum": ROOT / "outputs" / "MTSM_M126_E20_R200_MODEL1_TRADES.csv",
}
EXPECTED_HASHES = {
    "h4": "9BB2D9E20BEBD2A24521E9B7514D27E61CB4BD582C6E5F5BA1AD56364C85AF0C",
    "reversion": "E4FABDE5C1D1420FC437123F50C7D1D991511F4AB8E284DC2F84F732932EBA19",
    "momentum": "435FA8354E723F2D2FC0D442674ECE49C28008ADDBAB288F2E0E3FD7FF58A7BE",
}
H4_RISKS = (0.50, 0.55, 0.60, 0.65, 0.70)
REVERSION_RISKS = (0.55, 0.60, 0.65)
MOMENTUM_RISK = 0.10
ERA_YEARS = {
    "Older2015_2018": range(2015, 2019),
    "Middle2019_2022": range(2019, 2023),
    "Recent2023_2026": range(2023, 2027),
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


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def load_trades() -> dict[str, list[Trade]]:
    streams: dict[str, list[Trade]] = {}
    for stream, path in STREAM_FILES.items():
        if not path.exists():
            raise FileNotFoundError(path)
        actual_hash = file_hash(path)
        if actual_hash != EXPECTED_HASHES[stream]:
            raise ValueError(f"{stream} trade identity changed: {actual_hash}")
        trades: list[Trade] = []
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            for index, row in enumerate(csv.DictReader(handle), start=1):
                entry = datetime.fromisoformat(row["EntryTime"])
                exit_time = datetime.fromisoformat(row["ExitTime"])
                if exit_time < entry:
                    raise ValueError(f"Negative hold time in {stream} trade {index}")
                trades.append(
                    Trade(
                        stream=stream,
                        index=index,
                        entry=entry,
                        exit=exit_time,
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
    left_mean = mean(left)
    right_mean = mean(right)
    numerator = sum((a - left_mean) * (b - right_mean) for a, b in zip(left, right))
    denominator = math.sqrt(
        sum((value - left_mean) ** 2 for value in left)
        * sum((value - right_mean) ** 2 for value in right)
    )
    return numerator / denominator if denominator > 0 else 0.0


def relationships(streams: dict[str, list[Trade]]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    names = sorted(streams)
    for left_index, left_name in enumerate(names):
        left = streams[left_name]
        left_monthly: dict[str, float] = defaultdict(float)
        for trade in left:
            left_monthly[month_key(trade.exit)] += trade.risk_r
        for right_name in names[left_index + 1 :]:
            right = streams[right_name]
            right_monthly: dict[str, float] = defaultdict(float)
            for trade in right:
                right_monthly[month_key(trade.exit)] += trade.risk_r
            exact_entries = {(trade.entry, trade.side) for trade in left} & {
                (trade.entry, trade.side) for trade in right
            }
            overlap_pairs = 0
            opposite_overlaps = 0
            for first in left:
                for second in right:
                    if first.entry < second.exit and second.entry < first.exit:
                        overlap_pairs += 1
                        if first.side != second.side:
                            opposite_overlaps += 1
            rows.append(
                {
                    "Left": left_name,
                    "Right": right_name,
                    "MonthlyRCorrelation": round(
                        pearson(
                            [left_monthly[month] for month in MONTHS],
                            [right_monthly[month] for month in MONTHS],
                        ),
                        4,
                    ),
                    "ExactSameSideEntries": len(exact_entries),
                    "OverlappingTradePairs": overlap_pairs,
                    "OppositeSideOverlapPairs": opposite_overlaps,
                }
            )
    return rows


def simulate(
    streams: dict[str, list[Trade]], risk_percent: dict[str, float], stress_r: float
) -> tuple[dict[str, object], dict[int, dict[str, float | int]]]:
    events: list[tuple[datetime, int, Trade]] = []
    for trades in streams.values():
        for trade in trades:
            events.append((trade.entry, 1, trade))
            events.append((trade.exit, 0, trade))
    events.sort(key=lambda item: (item[0], item[1], item[2].stream, item[2].index))

    balance = STARTING_BALANCE
    peak_balance = balance
    open_risk = 0.0
    max_closed_dd = 0.0
    max_floor_dd = 0.0
    max_floor_dd_money = 0.0
    max_open_risk_percent = 0.0
    open_trades: dict[tuple[str, int], OpenTrade] = {}
    pnl_values: list[float] = []
    yearly_pnl: dict[int, float] = defaultdict(float)
    yearly_trades: dict[int, int] = defaultdict(int)
    monthly_pnl: dict[str, float] = defaultdict(float)
    lane_balance = {name: STARTING_BALANCE for name in streams}
    lane_peak = dict(lane_balance)
    lane_locks: dict[str, datetime] = {}
    skipped = 0
    scaled = 0
    consecutive_losses = 0
    max_consecutive_losses = 0

    def update_drawdown() -> None:
        nonlocal peak_balance, max_closed_dd, max_floor_dd, max_floor_dd_money
        peak_balance = max(peak_balance, balance)
        if peak_balance <= 0:
            return
        max_closed_dd = max(max_closed_dd, 100.0 * (peak_balance - balance) / peak_balance)
        floor_equity = balance - open_risk
        floor_dd_money = peak_balance - floor_equity
        floor_dd = 100.0 * floor_dd_money / peak_balance
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
            pnl = (trade.risk_r - stress_r) * opened.risk_cash
            balance += pnl
            pnl_values.append(pnl)
            yearly_pnl[timestamp.year] += pnl
            yearly_trades[timestamp.year] += 1
            monthly_pnl[month_key(timestamp)] += pnl
            lane_balance[trade.stream] += pnl
            lane_peak[trade.stream] = max(lane_peak[trade.stream], lane_balance[trade.stream])
            lane_dd = 100.0 * (
                lane_peak[trade.stream] - lane_balance[trade.stream]
            ) / lane_peak[trade.stream]
            if lane_dd >= LANE_DRAWDOWN_LOCK_PERCENT and trade.stream not in lane_locks:
                lane_locks[trade.stream] = timestamp
            if pnl < 0:
                consecutive_losses += 1
                max_consecutive_losses = max(max_consecutive_losses, consecutive_losses)
            else:
                consecutive_losses = 0
            update_drawdown()
            continue

        if trade.stream in lane_locks:
            skipped += 1
            continue
        desired = balance * risk_percent[trade.stream] / 100.0
        cap_cash = balance * OPEN_RISK_CAP_PERCENT / 100.0
        available = max(0.0, cap_cash - open_risk)
        allocated = min(desired, available)
        if allocated <= 0.0 or allocated < desired * 0.25:
            skipped += 1
            continue
        if allocated < desired - 1e-9:
            scaled += 1
        open_trades[key] = OpenTrade(trade=trade, risk_cash=allocated)
        open_risk += allocated
        if balance > 0:
            max_open_risk_percent = max(max_open_risk_percent, 100.0 * open_risk / balance)
        update_drawdown()

    gross_profit = sum(value for value in pnl_values if value > 0)
    gross_loss = -sum(value for value in pnl_values if value < 0)
    net = balance - STARTING_BALANCE
    total_return = 100.0 * net / STARTING_BALANCE
    profit_factor = gross_profit / gross_loss if gross_loss else float("inf")
    cagr = 100.0 * ((balance / STARTING_BALANCE) ** (1.0 / YEARS) - 1.0)
    red_years = sum(1 for year in range(2015, 2027) if yearly_pnl[year] < 0)
    inactive_years = sum(1 for year in range(2015, 2027) if yearly_trades[year] == 0)
    worst_year = min(range(2015, 2027), key=lambda year: yearly_pnl[year])
    largest_year_net = max(yearly_pnl[year] for year in range(2015, 2027))
    rolling_values = [
        sum(monthly_pnl[month] for month in MONTHS[index - 11 : index + 1])
        for index in range(11, len(MONTHS))
    ]
    metrics: dict[str, object] = {
        "NetProfit": round(net, 2),
        "EndingBalance": round(balance, 2),
        "TotalReturnPercent": round(total_return, 2),
        "CagrPercent": round(cagr, 2),
        "ProfitFactor": round(profit_factor, 3),
        "Trades": len(pnl_values),
        "SkippedTrades": skipped,
        "ScaledTrades": scaled,
        "MaxClosedDrawdownPercent": round(max_closed_dd, 2),
        "MaxRiskFloorDrawdownPercent": round(max_floor_dd, 2),
        "MaxOpenRiskPercent": round(max_open_risk_percent, 2),
        "RecoveryFactor": round(net / max_floor_dd_money, 2) if max_floor_dd_money else 0.0,
        "ReturnDrawdown": round(total_return / max_floor_dd, 2) if max_floor_dd else 0.0,
        "RedYears": red_years,
        "InactiveYears": inactive_years,
        "WorstYear": worst_year,
        "WorstYearNet": round(yearly_pnl[worst_year], 2),
        "LargestYearSharePercent": round(100.0 * largest_year_net / net, 2) if net > 0 else 999.0,
        "WorstRolling12MonthNet": round(min(rolling_values), 2),
        "NegativeRolling12MonthWindows": sum(1 for value in rolling_values if value < 0),
        "MaxConsecutiveLosses": max_consecutive_losses,
        "LaneLocks": ";".join(
            f"{name}:{lane_locks[name].isoformat(sep=' ')}" for name in sorted(lane_locks)
        ),
    }
    yearly = {
        year: {"Trades": yearly_trades[year], "NetProfit": round(yearly_pnl[year], 2)}
        for year in range(2015, 2027)
    }
    return metrics, yearly


def era_net(yearly: dict[int, dict[str, float | int]], years: range) -> float:
    return round(sum(float(yearly[year]["NetProfit"]) for year in years), 2)


def main() -> int:
    streams = load_trades()
    relation_rows = relationships(streams)
    rows: list[dict[str, object]] = []
    yearly_rows: list[dict[str, object]] = []

    for h4_risk in H4_RISKS:
        for reversion_risk in REVERSION_RISKS:
            profile = f"h4_{h4_risk:.2f}_rv_{reversion_risk:.2f}_mom_{MOMENTUM_RISK:.2f}"
            risks = {"h4": h4_risk, "reversion": reversion_risk, "momentum": MOMENTUM_RISK}
            results: dict[float, tuple[dict[str, object], dict[int, dict[str, float | int]]]] = {}
            for stress_r in STRESS_LEVELS:
                results[stress_r] = simulate(streams, risks, stress_r)
                for year, values in results[stress_r][1].items():
                    yearly_rows.append(
                        {"Profile": profile, "StressRPerTrade": stress_r, "Year": year, **values}
                    )

            base, base_yearly = results[0.0]
            stress05, stress05_yearly = results[0.05]
            stress10, stress10_yearly = results[0.10]
            base_eras = {name: era_net(base_yearly, years) for name, years in ERA_YEARS.items()}
            stress05_eras = {
                name: era_net(stress05_yearly, years) for name, years in ERA_YEARS.items()
            }

            core_eligible = (
                base["RedYears"] == 0
                and stress05["RedYears"] == 0
                and base["InactiveYears"] == 0
                and int(base["Trades"]) >= 450
                and float(base["ProfitFactor"]) >= 1.30
                and float(stress05["ProfitFactor"]) >= 1.20
                and float(base["MaxRiskFloorDrawdownPercent"]) <= 10.0
                and float(base["RecoveryFactor"]) >= 2.0
                and float(base["LargestYearSharePercent"]) <= 40.0
                and all(value > 0 for value in base_eras.values())
                and all(value > 0 for value in stress05_eras.values())
            )
            strict_eligible = (
                core_eligible
                and stress10["RedYears"] == 0
                and float(stress10["ProfitFactor"]) >= 1.10
                and float(stress10["MaxRiskFloorDrawdownPercent"]) <= 12.0
            )
            score = (
                float(base["CagrPercent"])
                + 0.35 * float(base["ReturnDrawdown"])
                + 0.20 * float(stress05["ProfitFactor"])
                - 0.10 * float(base["MaxRiskFloorDrawdownPercent"])
            )
            rows.append(
                {
                    "Profile": profile,
                    "CoreEligible": str(core_eligible),
                    "StrictEligible": str(strict_eligible),
                    "ImplementationProfile": str(profile == IMPLEMENTATION_PROFILE),
                    "H4RiskPercent": h4_risk,
                    "ReversionRiskPercent": reversion_risk,
                    "MomentumRiskPercent": MOMENTUM_RISK,
                    "OpenRiskCapPercent": OPEN_RISK_CAP_PERCENT,
                    "LaneDrawdownLockPercent": LANE_DRAWDOWN_LOCK_PERCENT,
                    "Score": round(score, 4),
                    **base,
                    **{f"Base{name}Net": value for name, value in base_eras.items()},
                    "Stress05NetProfit": stress05["NetProfit"],
                    "Stress05ProfitFactor": stress05["ProfitFactor"],
                    "Stress05MaxRiskFloorDrawdownPercent": stress05["MaxRiskFloorDrawdownPercent"],
                    "Stress05RedYears": stress05["RedYears"],
                    **{f"Stress05{name}Net": value for name, value in stress05_eras.items()},
                    "Stress10NetProfit": stress10["NetProfit"],
                    "Stress10ProfitFactor": stress10["ProfitFactor"],
                    "Stress10MaxRiskFloorDrawdownPercent": stress10["MaxRiskFloorDrawdownPercent"],
                    "Stress10RedYears": stress10["RedYears"],
                    "Stress10LaneLocks": stress10["LaneLocks"],
                }
            )

    rows.sort(
        key=lambda row: (
            row["StrictEligible"] == "True",
            row["CoreEligible"] == "True",
            float(row["Score"]),
        ),
        reverse=True,
    )
    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    with OUTPUT_YEARLY.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(yearly_rows[0]))
        writer.writeheader()
        writer.writerows(yearly_rows)

    core_count = sum(row["CoreEligible"] == "True" for row in rows)
    strict_count = sum(row["StrictEligible"] == "True" for row in rows)
    implementation = next(row for row in rows if row["ImplementationProfile"] == "True")
    lines = [
        "# Clean E20 Three-Lane Portfolio Screen", "",
        "This is a chronological realized-R implementation screen, not a combined MT5 result and not live approval.",
        "All profile rows and gates are fixed in the analyzer; no calendar/month selector is used.", "",
        f"- Window: `{START_DATE.date()}` through `{END_DATE.date()}`",
        f"- Starting balance: `${STARTING_BALANCE:,.0f}`",
        f"- Exact H4 trades: `{len(streams['h4'])}`",
        f"- Exact compact H1 reversion Model4 trades: `{len(streams['reversion'])}`",
        f"- Exact E20 momentum trades: `{len(streams['momentum'])}`",
        f"- Grid rows: `{len(rows)}`; core eligible: `{core_count}`; strict eligible: `{strict_count}`",
        f"- Shared open-risk cap: `{OPEN_RISK_CAP_PERCENT:.2f}%`",
        f"- Permanent per-lane drawdown lock: `{LANE_DRAWDOWN_LOCK_PERCENT:.2f}%`",
        "- Stress levels deduct `0.05R` and `0.10R` from every realized trade.", "",
        "## Stream Relationships", "",
        "| Left | Right | Monthly R correlation | Same-side entries | Overlap pairs | Opposite overlaps |",
        "|---|---|---:|---:|---:|---:|",
    ]
    for row in relation_rows:
        lines.append(
            f"| {row['Left']} | {row['Right']} | {float(row['MonthlyRCorrelation']):.4f} | "
            f"{row['ExactSameSideEntries']} | {row['OverlappingTradePairs']} | "
            f"{row['OppositeSideOverlapPairs']} |"
        )
    lines.extend(
        [
            "", "## Grid", "",
            "| Profile | Core | Strict | Net | CAGR | PF | Risk-floor DD | 0.05R net/PF/red years | 0.10R net/PF/red years |",
            "|---|---|---|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in rows:
        lines.append(
            f"| `{row['Profile']}` | {row['CoreEligible']} | {row['StrictEligible']} | "
            f"${float(row['NetProfit']):,.2f} | {float(row['CagrPercent']):.2f}% | "
            f"{float(row['ProfitFactor']):.3f} | {float(row['MaxRiskFloorDrawdownPercent']):.2f}% | "
            f"${float(row['Stress05NetProfit']):,.2f} / {float(row['Stress05ProfitFactor']):.3f} / {row['Stress05RedYears']} | "
            f"${float(row['Stress10NetProfit']):,.2f} / {float(row['Stress10ProfitFactor']):.3f} / {row['Stress10RedYears']} |"
        )
    lines.extend(
        [
            "", "## Implementation Center", "",
            f"The predeclared balanced center is `{IMPLEMENTATION_PROFILE}`. It is selected for neighborhood support and lower risk than the highest-profit edge, not because it tops the grid.", "",
            f"- Base: `${float(implementation['NetProfit']):,.2f}`, CAGR `{float(implementation['CagrPercent']):.2f}%`, PF `{float(implementation['ProfitFactor']):.3f}`, conservative DD `{float(implementation['MaxRiskFloorDrawdownPercent']):.2f}%`",
            f"- 0.05R stress: `${float(implementation['Stress05NetProfit']):,.2f}`, PF `{float(implementation['Stress05ProfitFactor']):.3f}`, red years `{implementation['Stress05RedYears']}`",
            f"- 0.10R stress: `${float(implementation['Stress10NetProfit']):,.2f}`, PF `{float(implementation['Stress10ProfitFactor']):.3f}`, red years `{implementation['Stress10RedYears']}`",
            f"- Base lane locks: `{implementation['LaneLocks'] or 'none'}`", "",
            "Passing this screen only justifies implementing the three lanes in one EA. The combined EA must reproduce behavior on Model 1, then survive Model 4 real ticks and execution-cost checks before any trade-ready claim.",
        ]
    )
    OUTPUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        "CLEAN_E20_PORTFOLIO_COMPLETE "
        f"rows={len(rows)} core={core_count} strict={strict_count} "
        f"center_net={implementation['NetProfit']} center_stress10_red={implementation['Stress10RedYears']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
