#!/usr/bin/env python3
"""Frozen screen for the two broad-history, date-independent XAUUSD lanes."""

from __future__ import annotations

import csv
from pathlib import Path

import analyze_strategy_portfolio as core


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_CSV = ROOT / "outputs" / "DATE_INDEPENDENT_PORTFOLIO_SCREEN.csv"
OUTPUT_YEARLY = ROOT / "outputs" / "DATE_INDEPENDENT_PORTFOLIO_YEARLY.csv"
OUTPUT_MD = ROOT / "outputs" / "DATE_INDEPENDENT_PORTFOLIO_SCREEN.md"

# Frozen before this screen was run. Total desired initial risk is always 0.50%.
# The grid changes only the allocation between the two independently tested lanes.
ALLOCATIONS = (
    (0.10, 0.40),
    (0.175, 0.325),
    (0.25, 0.25),
    (0.325, 0.175),
    (0.40, 0.10),
)
ERA_YEARS = {
    "Older2015_2018": range(2015, 2019),
    "Middle2019_2022": range(2019, 2023),
    "Recent2023_2026": range(2023, 2027),
}

core.OPEN_RISK_CAP_PERCENT = 1.0
core.STREAM_FILES = {
    "donchian": ROOT / "outputs" / "DAILY_DONCHIAN_REALTICK_TRADES.csv",
    "reversion": ROOT / "outputs" / "HTF_BAND_REVERSION_MODEL4_TRADES.csv",
}


def era_net(yearly: dict[int, dict[str, float | int]], years: range) -> float:
    return round(sum(float(yearly[year]["NetProfit"]) for year in years), 2)


def annual_returns(
    yearly: dict[int, dict[str, float | int]],
) -> dict[int, dict[str, float | int]]:
    balance = core.STARTING_BALANCE
    result: dict[int, dict[str, float | int]] = {}
    for year in range(2015, 2027):
        net = float(yearly[year]["NetProfit"])
        start = balance
        balance += net
        result[year] = {
            **yearly[year],
            "StartingBalance": round(start, 2),
            "EndingBalance": round(balance, 2),
            "ReturnPercent": round(100.0 * net / start, 3) if start else 0.0,
        }
    return result


def main() -> int:
    streams = core.load_trades()
    relationships = core.stream_relationships(streams)
    rows: list[dict[str, object]] = []
    yearly_by_profile: dict[str, dict[int, dict[str, float | int]]] = {}

    for donchian_risk, reversion_risk in ALLOCATIONS:
        risks = {"donchian": donchian_risk, "reversion": reversion_risk}
        base, yearly = core.simulate(streams, risks, stress_r=0.0)
        stress, stress_yearly = core.simulate(
            streams, risks, stress_r=core.STRESS_R_PER_TRADE
        )
        profile = f"dd{donchian_risk:.3f}_rv{reversion_risk:.3f}"
        base_eras = {name: era_net(yearly, years) for name, years in ERA_YEARS.items()}
        stress_eras = {
            name: era_net(stress_yearly, years) for name, years in ERA_YEARS.items()
        }

        # Promotion gate frozen before inspecting this screen's results.
        eligible = (
            base["RedYears"] == 0
            and stress["RedYears"] == 0
            and base["InactiveYears"] == 0
            and base["Trades"] >= 80
            and base["ProfitFactor"] >= 1.30
            and stress["ProfitFactor"] >= 1.10
            and base["MaxRiskFloorDrawdownPercent"] <= 5.0
            and base["RecoveryFactor"] >= 2.0
            and base["LargestYearSharePercent"] <= 40.0
            and all(value > 0 for value in base_eras.values())
            and all(value > 0 for value in stress_eras.values())
            and stress["NetProfit"] > 0
        )
        score = (
            float(base["ReturnDrawdown"])
            + 0.5 * float(base["ProfitFactor"])
            - 0.05 * float(base["NegativeRolling12MonthWindows"])
            - float(base["RedYears"])
            - float(stress["RedYears"])
        )
        rows.append(
            {
                "Profile": profile,
                "Eligible": str(eligible),
                "DonchianRiskPercent": donchian_risk,
                "ReversionRiskPercent": reversion_risk,
                "CombinedDesiredRiskPercent": round(donchian_risk + reversion_risk, 3),
                "OpenRiskCapPercent": core.OPEN_RISK_CAP_PERCENT,
                "Score": round(score, 4),
                **base,
                **{f"Base{name}Net": value for name, value in base_eras.items()},
                "StressRPerTrade": core.STRESS_R_PER_TRADE,
                "StressNetProfit": stress["NetProfit"],
                "StressProfitFactor": stress["ProfitFactor"],
                "StressMaxRiskFloorDrawdownPercent": stress[
                    "MaxRiskFloorDrawdownPercent"
                ],
                "StressRedYears": stress["RedYears"],
                **{f"Stress{name}Net": value for name, value in stress_eras.items()},
            }
        )
        yearly_by_profile[profile] = annual_returns(yearly)

    rows.sort(
        key=lambda row: (
            row["Eligible"] == "True",
            float(row["Score"]),
            float(row["NetProfit"]),
        ),
        reverse=True,
    )
    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    with OUTPUT_YEARLY.open("w", encoding="utf-8", newline="") as handle:
        fields = [
            "Profile",
            "Year",
            "Trades",
            "NetProfit",
            "StartingBalance",
            "EndingBalance",
            "ReturnPercent",
        ]
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            profile = str(row["Profile"])
            for year, values in yearly_by_profile[profile].items():
                writer.writerow({"Profile": profile, "Year": year, **values})

    eligible_rows = [row for row in rows if row["Eligible"] == "True"]
    lines = [
        "# Date-Independent Portfolio Screen",
        "",
        "This is an exact realized-R analytical screen, not a combined MT5 result or live approval.",
        "The allocations and gate were frozen before the screen was run.",
        "",
        f"- Exact Donchian trades: `{len(streams['donchian'])}`",
        f"- Exact H1 reversion trades: `{len(streams['reversion'])}`",
        f"- Allocation rows: `{len(rows)}`",
        f"- Eligible rows: `{len(eligible_rows)}`",
        f"- Desired total initial risk: `0.50%`",
        f"- Open-risk cap: `{core.OPEN_RISK_CAP_PERCENT:.2f}%`",
        f"- Execution stress: `{core.STRESS_R_PER_TRADE:.2f}R` deducted per trade",
        "",
        "## Relationship",
        "",
        "| Monthly R correlation | Same-side entries | Overlap pairs | Opposite overlaps |",
        "| ---: | ---: | ---: | ---: |",
    ]
    relationship = relationships[0]
    lines.append(
        f"| {float(relationship['MonthlyRCorrelation']):.4f} | "
        f"{relationship['ExactSameSideEntries']} | "
        f"{relationship['OverlappingTradePairs']} | "
        f"{relationship['OppositeSideOverlapPairs']} |"
    )
    lines.extend(
        [
            "",
            "## Results",
            "",
            "| Profile | Eligible | Net | CAGR | PF | Risk-floor DD | Recovery | Red years | Stress red years | Worst 12m |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in rows:
        lines.append(
            f"| `{row['Profile']}` | {row['Eligible']} | "
            f"`${float(row['NetProfit']):,.2f}` | {float(row['CagrPercent']):.2f}% | "
            f"{float(row['ProfitFactor']):.3f} | "
            f"{float(row['MaxRiskFloorDrawdownPercent']):.2f}% | "
            f"{float(row['RecoveryFactor']):.2f} | {row['RedYears']} | "
            f"{row['StressRedYears']} | `${float(row['WorstRolling12MonthNet']):,.2f}` |"
        )
    lines.extend(
        [
            "",
            "## Frozen Gate",
            "",
            "A row needs zero red years in base and stress, activity in every year, at least 80 trades, positive older/middle/recent eras in base and stress, PF at least 1.30, stressed PF at least 1.10, conservative drawdown no higher than 5%, recovery at least 2.0, and no year supplying more than 40% of profit.",
            "",
            "A passing row would only justify building and testing a combined EA on MT5 real ticks.",
        ]
    )
    OUTPUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        "DATE_INDEPENDENT_PORTFOLIO_COMPLETE "
        f"rows={len(rows)} eligible={len(eligible_rows)} top={rows[0]['Profile']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
