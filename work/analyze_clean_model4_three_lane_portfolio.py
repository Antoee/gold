#!/usr/bin/env python3
"""Preregistered all-Model4 screen for Donchian, reversion, and momentum lanes."""

from __future__ import annotations

import csv
from pathlib import Path

import analyze_clean_e20_three_lane_portfolio as core


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_CSV = ROOT / "outputs" / "CLEAN_MODEL4_THREE_LANE_PORTFOLIO_SCREEN.csv"
OUTPUT_YEARLY = ROOT / "outputs" / "CLEAN_MODEL4_THREE_LANE_PORTFOLIO_YEARLY.csv"
OUTPUT_MD = ROOT / "outputs" / "CLEAN_MODEL4_THREE_LANE_PORTFOLIO_DECISION.md"

core.STREAM_FILES = {
    "donchian": ROOT / "outputs" / "DAILY_DONCHIAN_REALTICK_TRADES.csv",
    "reversion": ROOT / "outputs" / "H1_BAND_VWAP_DI_M12_COMPACT_MODEL4_TRADES.csv",
    "momentum": ROOT / "outputs" / "MTSM_M126_E20_R200_MODEL4_TRADES.csv",
}
core.EXPECTED_HASHES = {
    "donchian": "C93538E5BED6CDF1AA1AC93CCB209C54287EBBBBBF7A2DF487E3420F251013B9",
    "reversion": "E4FABDE5C1D1420FC437123F50C7D1D991511F4AB8E284DC2F84F732932EBA19",
    "momentum": "1FD616E6E163AA1F020A146C8A94037D720D10FC22334A60574CCDE195F4668C",
}
core.OPEN_RISK_CAP_PERCENT = 0.75
core.LANE_DRAWDOWN_LOCK_PERCENT = 5.0

DONCHIAN_RISKS = (0.05, 0.10, 0.15)
REVERSION_RISKS = (0.35, 0.40, 0.45, 0.50)
MOMENTUM_RISKS = (0.10, 0.15, 0.20)
STRESS_LEVELS = (0.0, 0.05, 0.10)
IMPLEMENTATION_PROFILE = "dd_0.10_rv_0.45_mom_0.15"


def era_net(
    yearly: dict[int, dict[str, float | int]], years: range
) -> float:
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


def incremental_percent(value: float, benchmark: float) -> float:
    if benchmark <= 0.0:
        return -999.0
    return 100.0 * (value - benchmark) / benchmark


def main() -> int:
    streams = core.load_trades()
    relationship_rows = core.relationships(streams)
    rows: list[dict[str, object]] = []
    yearly_rows: list[dict[str, object]] = []
    benchmark_cache: dict[
        tuple[float, float, float],
        tuple[dict[str, object], dict[int, dict[str, float | int]]],
    ] = {}

    for reversion_risk in REVERSION_RISKS:
        for momentum_risk in MOMENTUM_RISKS:
            for stress_r in STRESS_LEVELS:
                benchmark_cache[(reversion_risk, momentum_risk, stress_r)] = core.simulate(
                    streams,
                    {
                        "donchian": 0.0,
                        "reversion": reversion_risk,
                        "momentum": momentum_risk,
                    },
                    stress_r,
                )

    for donchian_risk in DONCHIAN_RISKS:
        for reversion_risk in REVERSION_RISKS:
            for momentum_risk in MOMENTUM_RISKS:
                profile = (
                    f"dd_{donchian_risk:.2f}_rv_{reversion_risk:.2f}_"
                    f"mom_{momentum_risk:.2f}"
                )
                risks = {
                    "donchian": donchian_risk,
                    "reversion": reversion_risk,
                    "momentum": momentum_risk,
                }
                results: dict[
                    float,
                    tuple[dict[str, object], dict[int, dict[str, float | int]]],
                ] = {}
                for stress_r in STRESS_LEVELS:
                    results[stress_r] = core.simulate(streams, risks, stress_r)
                    for year, values in annual_returns(results[stress_r][1]).items():
                        yearly_rows.append(
                            {
                                "Profile": profile,
                                "StressRPerTrade": stress_r,
                                "Year": year,
                                **values,
                            }
                        )

                base, base_yearly = results[0.0]
                stress05, stress05_yearly = results[0.05]
                stress10, stress10_yearly = results[0.10]
                benchmark_base = benchmark_cache[(reversion_risk, momentum_risk, 0.0)][0]
                benchmark05 = benchmark_cache[(reversion_risk, momentum_risk, 0.05)][0]
                benchmark10 = benchmark_cache[(reversion_risk, momentum_risk, 0.10)][0]
                base_eras = {
                    name: era_net(base_yearly, years)
                    for name, years in core.ERA_YEARS.items()
                }
                stress05_eras = {
                    name: era_net(stress05_yearly, years)
                    for name, years in core.ERA_YEARS.items()
                }
                stress10_eras = {
                    name: era_net(stress10_yearly, years)
                    for name, years in core.ERA_YEARS.items()
                }

                no_historical_lock = not any(
                    str(metrics["LaneLocks"])
                    for metrics in (base, stress05, stress10)
                )
                broad_pass = all(
                    value > 0.0
                    for group in (base_eras, stress05_eras, stress10_eras)
                    for value in group.values()
                )
                added_trades = int(base["Trades"]) - int(benchmark_base["Trades"])
                base_increment = incremental_percent(
                    float(base["NetProfit"]), float(benchmark_base["NetProfit"])
                )
                stress05_increment = incremental_percent(
                    float(stress05["NetProfit"]), float(benchmark05["NetProfit"])
                )
                stress10_increment = incremental_percent(
                    float(stress10["NetProfit"]), float(benchmark10["NetProfit"])
                )
                return_drawdown_delta = float(base["ReturnDrawdown"]) - float(
                    benchmark_base["ReturnDrawdown"]
                )
                worst_rolling_delta = float(base["WorstRolling12MonthNet"]) - float(
                    benchmark_base["WorstRolling12MonthNet"]
                )

                eligible = (
                    no_historical_lock
                    and broad_pass
                    and int(base["Trades"]) >= 380
                    and added_trades >= 30
                    and int(base["InactiveYears"]) == 0
                    and float(base["ProfitFactor"]) >= 1.45
                    and float(stress05["ProfitFactor"]) >= 1.30
                    and float(stress10["ProfitFactor"]) >= 1.20
                    and float(base["MaxRiskFloorDrawdownPercent"]) <= 5.0
                    and float(stress05["MaxRiskFloorDrawdownPercent"]) <= 6.0
                    and float(stress10["MaxRiskFloorDrawdownPercent"]) <= 7.0
                    and int(base["MaxConsecutiveLosses"]) <= 14
                    and int(stress05["MaxConsecutiveLosses"]) <= 15
                    and int(stress10["MaxConsecutiveLosses"]) <= 16
                    and float(base["WorstYearNet"]) >= -150.0
                    and float(stress05["WorstYearNet"]) >= -200.0
                    and float(stress10["WorstYearNet"]) >= -250.0
                    and float(base["LargestYearSharePercent"]) <= 35.0
                    and base_increment >= 5.0
                    and stress05_increment >= 3.0
                    and stress10_increment >= 0.0
                    and return_drawdown_delta >= 0.0
                    and worst_rolling_delta >= -50.0
                    and int(base["RedYears"]) <= int(benchmark_base["RedYears"])
                    and int(stress05["RedYears"]) <= int(benchmark05["RedYears"])
                    and int(stress10["RedYears"]) <= int(benchmark10["RedYears"])
                )
                score = (
                    0.50 * stress10_increment
                    + 0.30 * stress05_increment
                    + 0.20 * base_increment
                    + 2.0 * return_drawdown_delta
                    - 0.10 * float(base["MaxRiskFloorDrawdownPercent"])
                )
                rows.append(
                    {
                        "Profile": profile,
                        "Eligible": str(eligible),
                        "ImplementationProfile": str(profile == IMPLEMENTATION_PROFILE),
                        "DonchianRiskPercent": donchian_risk,
                        "ReversionRiskPercent": reversion_risk,
                        "MomentumRiskPercent": momentum_risk,
                        "RequestedRiskSumPercent": round(
                            donchian_risk + reversion_risk + momentum_risk, 2
                        ),
                        "OpenRiskCapPercent": core.OPEN_RISK_CAP_PERCENT,
                        "Score": round(score, 4),
                        "NoHistoricalLaneLock": str(no_historical_lock),
                        "AllBroadErasPositive": str(broad_pass),
                        "AddedTradesVsTwoLane": added_trades,
                        "BaseIncrementalNetPercent": round(base_increment, 3),
                        "Stress05IncrementalNetPercent": round(stress05_increment, 3),
                        "Stress10IncrementalNetPercent": round(stress10_increment, 3),
                        "ReturnDrawdownDelta": round(return_drawdown_delta, 3),
                        "WorstRolling12MonthDelta": round(worst_rolling_delta, 2),
                        "BenchmarkNetProfit": benchmark_base["NetProfit"],
                        "BenchmarkProfitFactor": benchmark_base["ProfitFactor"],
                        "BenchmarkMaxRiskFloorDrawdownPercent": benchmark_base[
                            "MaxRiskFloorDrawdownPercent"
                        ],
                        "BenchmarkRedYears": benchmark_base["RedYears"],
                        "BenchmarkStress05NetProfit": benchmark05["NetProfit"],
                        "BenchmarkStress10NetProfit": benchmark10["NetProfit"],
                        **base,
                        **{f"Base{name}Net": value for name, value in base_eras.items()},
                        "Stress05NetProfit": stress05["NetProfit"],
                        "Stress05ProfitFactor": stress05["ProfitFactor"],
                        "Stress05MaxRiskFloorDrawdownPercent": stress05[
                            "MaxRiskFloorDrawdownPercent"
                        ],
                        "Stress05RedYears": stress05["RedYears"],
                        "Stress05MaxConsecutiveLosses": stress05[
                            "MaxConsecutiveLosses"
                        ],
                        "Stress05WorstYearNet": stress05["WorstYearNet"],
                        **{
                            f"Stress05{name}Net": value
                            for name, value in stress05_eras.items()
                        },
                        "Stress10NetProfit": stress10["NetProfit"],
                        "Stress10ProfitFactor": stress10["ProfitFactor"],
                        "Stress10MaxRiskFloorDrawdownPercent": stress10[
                            "MaxRiskFloorDrawdownPercent"
                        ],
                        "Stress10RedYears": stress10["RedYears"],
                        "Stress10MaxConsecutiveLosses": stress10[
                            "MaxConsecutiveLosses"
                        ],
                        "Stress10WorstYearNet": stress10["WorstYearNet"],
                        **{
                            f"Stress10{name}Net": value
                            for name, value in stress10_eras.items()
                        },
                    }
                )

    rows.sort(
        key=lambda row: (row["Eligible"] == "True", float(row["Score"])),
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

    eligible_rows = [row for row in rows if row["Eligible"] == "True"]
    center = next(row for row in rows if row["ImplementationProfile"] == "True")
    donchian_neighbors = [
        row
        for row in rows
        if float(row["ReversionRiskPercent"]) == 0.45
        and float(row["MomentumRiskPercent"]) == 0.15
    ]
    structural_neighbors = [
        row
        for row in rows
        if (
            float(row["DonchianRiskPercent"]),
            float(row["ReversionRiskPercent"]),
            float(row["MomentumRiskPercent"]),
        )
        in {
            (0.05, 0.45, 0.15),
            (0.10, 0.45, 0.15),
            (0.15, 0.45, 0.15),
            (0.10, 0.40, 0.15),
            (0.10, 0.50, 0.15),
            (0.10, 0.45, 0.10),
            (0.10, 0.45, 0.20),
        }
    ]
    donchian_neighbor_passes = sum(
        row["Eligible"] == "True" for row in donchian_neighbors
    )
    structural_neighbor_passes = sum(
        row["Eligible"] == "True" for row in structural_neighbors
    )
    advance = (
        center["Eligible"] == "True"
        and donchian_neighbor_passes >= 2
        and structural_neighbor_passes >= 4
    )
    decision = "ADVANCE_TO_COMBINED_EA_IMPLEMENTATION" if advance else "REJECT_SCREEN"

    lines = [
        "# Clean Model4 Three-Lane Portfolio Decision",
        "",
        f"**Decision: {decision}.**",
        "",
        "This preregistered screen uses three exact MT5 Model 4 trade streams. It is an analytical implementation gate, not a combined-EA backtest, a replacement for the frozen forward demo, or live approval.",
        "",
        f"- Grid rows: `{len(rows)}`; row-eligible: `{len(eligible_rows)}`",
        f"- Center: `{IMPLEMENTATION_PROFILE}`; eligible: `{center['Eligible']}`",
        f"- Donchian-weight neighbors passing: `{donchian_neighbor_passes} / 3` (required 2)",
        f"- Structural neighbors passing: `{structural_neighbor_passes} / 7` (required 4)",
        f"- Shared open-risk cap: `{core.OPEN_RISK_CAP_PERCENT:.2f}%`",
        f"- Trades: Donchian `{len(streams['donchian'])}`, reversion `{len(streams['reversion'])}`, momentum `{len(streams['momentum'])}`",
        "",
        "## Center Versus Identical Two-Lane Benchmark",
        "",
        "| Metric | Three lanes | Two lanes | Change |",
        "|---|---:|---:|---:|",
        f"| Net profit | ${float(center['NetProfit']):,.2f} | ${float(center['BenchmarkNetProfit']):,.2f} | {float(center['BaseIncrementalNetPercent']):+.2f}% |",
        f"| Profit factor | {float(center['ProfitFactor']):.3f} | {float(center['BenchmarkProfitFactor']):.3f} | {float(center['ProfitFactor']) - float(center['BenchmarkProfitFactor']):+.3f} |",
        f"| Risk-floor drawdown | {float(center['MaxRiskFloorDrawdownPercent']):.2f}% | {float(center['BenchmarkMaxRiskFloorDrawdownPercent']):.2f}% | {float(center['MaxRiskFloorDrawdownPercent']) - float(center['BenchmarkMaxRiskFloorDrawdownPercent']):+.2f} pp |",
        f"| Closed trades | {center['Trades']} | {int(center['Trades']) - int(center['AddedTradesVsTwoLane'])} | {int(center['AddedTradesVsTwoLane']):+d} |",
        f"| Red years | {center['RedYears']} | {center['BenchmarkRedYears']} | {int(center['RedYears']) - int(center['BenchmarkRedYears']):+d} |",
        f"| 0.05R net | ${float(center['Stress05NetProfit']):,.2f} | ${float(center['BenchmarkStress05NetProfit']):,.2f} | {float(center['Stress05IncrementalNetPercent']):+.2f}% |",
        f"| 0.10R net | ${float(center['Stress10NetProfit']):,.2f} | ${float(center['BenchmarkStress10NetProfit']):,.2f} | {float(center['Stress10IncrementalNetPercent']):+.2f}% |",
        f"| Return / drawdown | {float(center['ReturnDrawdown']):.2f} | {float(center['ReturnDrawdown']) - float(center['ReturnDrawdownDelta']):.2f} | {float(center['ReturnDrawdownDelta']):+.2f} |",
        "",
        "## Stream Relationships",
        "",
        "| Left | Right | Monthly R correlation | Same-side entries | Overlaps | Opposite overlaps |",
        "|---|---|---:|---:|---:|---:|",
    ]
    for row in relationship_rows:
        lines.append(
            f"| {row['Left']} | {row['Right']} | {float(row['MonthlyRCorrelation']):.4f} | "
            f"{row['ExactSameSideEntries']} | {row['OverlappingTradePairs']} | "
            f"{row['OppositeSideOverlapPairs']} |"
        )
    lines.extend(
        [
            "",
            "## Frozen Neighborhood",
            "",
            "| Profile | Eligible | Net | PF | DD | Added trades | Base / 0.05R / 0.10R increment | Red years |",
            "|---|---|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in structural_neighbors:
        lines.append(
            f"| `{row['Profile']}` | {row['Eligible']} | ${float(row['NetProfit']):,.2f} | "
            f"{float(row['ProfitFactor']):.3f} | {float(row['MaxRiskFloorDrawdownPercent']):.2f}% | "
            f"{row['AddedTradesVsTwoLane']} | {float(row['BaseIncrementalNetPercent']):+.1f}% / "
            f"{float(row['Stress05IncrementalNetPercent']):+.1f}% / "
            f"{float(row['Stress10IncrementalNetPercent']):+.1f}% | {row['RedYears']} |"
        )
    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            (
                "The preregistered neighborhood passed. The next step is a separate three-lane EA whose Model 1 and Model 4 schedules must reproduce the independent streams before any performance comparison."
                if advance
                else "The preregistered center or neighborhood failed. Do not implement or tune this allocation after seeing the result; retain the files as rejected diversification evidence."
            ),
            "",
            "Real-account trading remains disabled.",
        ]
    )
    OUTPUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        "CLEAN_MODEL4_THREE_LANE_COMPLETE "
        f"decision={decision} rows={len(rows)} eligible={len(eligible_rows)} "
        f"center={center['Eligible']} donchian_neighbors={donchian_neighbor_passes} "
        f"structural_neighbors={structural_neighbor_passes}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
