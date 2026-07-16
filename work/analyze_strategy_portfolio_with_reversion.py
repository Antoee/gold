#!/usr/bin/env python3
"""Screen the exact XAUUSD strategy portfolio after adding H1 band reversion."""

from __future__ import annotations

import argparse
import csv
from itertools import product
from pathlib import Path
import re

import analyze_strategy_portfolio as core


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_CSV = ROOT / "outputs" / "STRATEGY_PORTFOLIO_WITH_REVERSION_SCREEN.csv"
OUTPUT_MD = ROOT / "outputs" / "STRATEGY_PORTFOLIO_WITH_REVERSION_SCREEN.md"
OUTPUT_YEARLY = ROOT / "outputs" / "STRATEGY_PORTFOLIO_WITH_REVERSION_TOP_YEARLY.csv"

core.STREAM_FILES = {
    "money": ROOT / "outputs" / "MONEY_READY_BALANCED_REALTICK_RISK_TRADES.csv",
    "highprofit": ROOT / "outputs" / "PEAK_TRAIL_UNBLOCK_HIGHPROFIT_RISK_TRADES.csv",
    "donchian": ROOT / "outputs" / "DAILY_DONCHIAN_REALTICK_TRADES.csv",
    "reversion": ROOT / "outputs" / "HTF_BAND_REVERSION_MODEL4_TRADES.csv",
}


def pct(value: object) -> str:
    return f"{float(value):.2f}%"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--reversion-path",
        default=str(core.STREAM_FILES["reversion"]),
        help="Exact continuous Model4 reversion trade CSV.",
    )
    parser.add_argument(
        "--output-tag",
        default="",
        help="Optional artifact tag so candidate screens do not overwrite the baseline.",
    )
    parser.add_argument(
        "--title",
        default="H1 Reversion",
        help="Human-readable reversion stream label.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    reversion_path = Path(args.reversion_path)
    if not reversion_path.is_absolute():
        reversion_path = ROOT / reversion_path
    core.STREAM_FILES["reversion"] = reversion_path

    tag = re.sub(r"[^A-Za-z0-9_]+", "_", args.output_tag.strip()).strip("_").upper()
    if tag:
        output_csv = ROOT / "outputs" / f"STRATEGY_PORTFOLIO_WITH_REVERSION_{tag}_SCREEN.csv"
        output_md = ROOT / "outputs" / f"STRATEGY_PORTFOLIO_WITH_REVERSION_{tag}_SCREEN.md"
        output_yearly = ROOT / "outputs" / f"STRATEGY_PORTFOLIO_WITH_REVERSION_{tag}_TOP_YEARLY.csv"
    else:
        output_csv = OUTPUT_CSV
        output_md = OUTPUT_MD
        output_yearly = OUTPUT_YEARLY

    streams = core.load_trades()
    relationships = core.stream_relationships(streams)
    rows: list[dict[str, object]] = []
    yearly_by_key: dict[str, dict[int, dict[str, float | int]]] = {}

    highprofit_values = [0.00, 0.25, 0.50, 0.75, 1.00]
    money_values = [0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50]
    donchian_values = [0.00, 0.10, 0.20, 0.30]
    reversion_values = [0.10, 0.20, 0.30, 0.40, 0.50]

    for hp_risk, money_risk, donchian_risk, reversion_risk in product(
        highprofit_values,
        money_values,
        donchian_values,
        reversion_values,
    ):
        risks = {
            "highprofit": hp_risk,
            "money": money_risk,
            "donchian": donchian_risk,
            "reversion": reversion_risk,
        }
        base, yearly = core.simulate(streams, risks, stress_r=0.0)
        stress, _ = core.simulate(streams, risks, stress_r=core.STRESS_R_PER_TRADE)
        key = (
            f"hp{hp_risk:.2f}_mr{money_risk:.2f}_dd{donchian_risk:.2f}_"
            f"rv{reversion_risk:.2f}"
        )
        eligible = (
            base["RedYears"] == 0
            and stress["RedYears"] == 0
            and base["InactiveYears"] == 0
            and base["Trades"] >= 100
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
            - 0.50 * float(base["RedYears"])
            - 0.50 * float(stress["RedYears"])
        )
        row: dict[str, object] = {
            "Profile": key,
            "HighProfitRiskPercent": hp_risk,
            "MoneyReadyRiskPercent": money_risk,
            "DonchianRiskPercent": donchian_risk,
            "ReversionRiskPercent": reversion_risk,
            "OpenRiskCapPercent": core.OPEN_RISK_CAP_PERCENT,
            "Eligible": str(eligible),
            "Score": round(score, 4),
            **base,
            "StressRPerTrade": core.STRESS_R_PER_TRADE,
            "StressNetProfit": stress["NetProfit"],
            "StressCagrPercent": stress["CagrPercent"],
            "StressProfitFactor": stress["ProfitFactor"],
            "StressMaxRiskFloorDrawdownPercent": stress[
                "MaxRiskFloorDrawdownPercent"
            ],
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
    eligible_rows = [row for row in rows if row["Eligible"] == "True"]
    top_rows = eligible_rows[:20] if eligible_rows else rows[:20]

    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    with output_yearly.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=["Profile", "Year", "Trades", "NetProfit"]
        )
        writer.writeheader()
        for row in top_rows[:5]:
            key = str(row["Profile"])
            for year, values in yearly_by_key[key].items():
                writer.writerow({"Profile": key, "Year": year, **values})

    lines = [
        f"# Strategy Portfolio With {args.title}",
        "",
        "This is an analytical realized-R screen, not a combined MT5 backtest or live approval.",
        "",
        f"- Grid rows: `{len(rows)}`",
        f"- Eligible rows: `{len(eligible_rows)}`",
        f"- Open-risk cap: `{core.OPEN_RISK_CAP_PERCENT:.2f}%`",
        f"- Stress: `{core.STRESS_R_PER_TRADE:.2f}R` deducted from every trade",
        f"- Reversion stream: `{reversion_path.relative_to(ROOT) if reversion_path.is_relative_to(ROOT) else reversion_path}`",
        f"- Exact reversion trades: `{len(streams['reversion'])}`",
        "",
        "## Stream Relationships",
        "",
        "| Left | Right | Monthly R correlation | Same-side entries | Overlap pairs | Opposite overlaps |",
        "| --- | --- | ---: | ---: | ---: | ---: |",
    ]
    for row in relationships:
        lines.append(
            f"| {row['Left']} | {row['Right']} | "
            f"{float(row['MonthlyRCorrelation']):.4f} | "
            f"{row['ExactSameSideEntries']} | {row['OverlappingTradePairs']} | "
            f"{row['OppositeSideOverlapPairs']} |"
        )

    lines.extend(
        [
            "",
            "## Top Rows",
            "",
            "| Profile | Eligible | Net | CAGR | PF | Risk-floor DD | Recovery | Red years | Stress red years | Worst 12m |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in top_rows:
        lines.append(
            f"| `{row['Profile']}` | {row['Eligible']} | "
            f"`${float(row['NetProfit']):,.2f}` | {pct(row['CagrPercent'])} | "
            f"{float(row['ProfitFactor']):.3f} | "
            f"{pct(row['MaxRiskFloorDrawdownPercent'])} | "
            f"{float(row['RecoveryFactor']):.2f} | {row['RedYears']} | "
            f"{row['StressRedYears']} | "
            f"`${float(row['WorstRolling12MonthNet']):,.2f}` |"
        )

    lines.extend(
        [
            "",
            "## Gate",
            "",
            "Eligibility requires zero red active years in base and stress, activity in every calendar year, at least 100 trades, PF at least 1.30, recovery at least 2.0, conservative drawdown no higher than 10%, and no single year supplying more than half of net profit.",
            "",
            "A passing row would justify a true combined-EA Model4 test; it would not constitute live approval.",
        ]
    )
    output_md.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        f"STRATEGY_PORTFOLIO_WITH_REVERSION_COMPLETE rows={len(rows)} "
        f"eligible={len(eligible_rows)} top={rows[0]['Profile']} tag={tag or 'BASELINE'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
