#!/usr/bin/env python3
"""Screen causal momentum entry features across broad eras.

This is a nomination tool, not an executable performance claim. Removing an
observed trade can expose later signals, so every nominated rule still needs a
fresh MT5 implementation and sealed broad-window validation.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

import numpy as np
import pandas as pd


EXPECTED_LEDGER_SHA256 = "A9BD88891D0225933B56EE84B2F96C5F503EDC0DDCBB529B9440336CAD524046"
ERAS = ["era_2015_2018", "era_2019_2020", "era_2021_2023", "era_2024_2026"]
GRID = {
    ("D1MomentumPercent", "minimum"): [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
    ("D1MomentumPercent", "maximum"): [8.0, 10.0, 12.0, 14.0, 16.0, 18.0],
    ("BreakoutATR", "minimum"): [0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.40],
    ("BreakoutATR", "maximum"): [0.50, 0.75, 1.00, 1.25],
    ("BodyRatio", "minimum"): [0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
    ("BodyRatio", "maximum"): [0.70, 0.80, 0.90],
    ("CloseLocation", "minimum"): [0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90],
    ("CloseLocation", "maximum"): [0.80, 0.85, 0.90, 0.95],
    ("RangeATR", "minimum"): [0.50, 0.75, 1.00, 1.25, 1.50, 2.00],
    ("RangeATR", "maximum"): [1.50, 2.00, 2.50, 3.00, 3.50, 4.00],
    ("ATRPercent", "minimum"): [0.05, 0.075, 0.10, 0.125, 0.15, 0.20, 0.25],
    ("ATRPercent", "maximum"): [0.20, 0.25, 0.30, 0.35, 0.40, 0.50, 0.75],
    ("TickVolumeRatio", "minimum"): [0.60, 0.75, 0.90, 1.00, 1.10, 1.25, 1.50, 2.00],
    ("TickVolumeRatio", "maximum"): [1.50, 2.00, 2.50, 3.00],
    ("StopATR", "minimum"): [0.75, 1.00, 1.25, 1.50, 1.75],
    ("StopATR", "maximum"): [1.25, 1.50, 1.75, 2.00, 2.25, 2.40],
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def profit_factor(rows: pd.DataFrame) -> float:
    gross_win = float(rows.loc[rows["Profit"] > 0.0, "Profit"].sum())
    gross_loss = -float(rows.loc[rows["Profit"] < 0.0, "Profit"].sum())
    return gross_win / gross_loss if gross_loss > 0.0 else np.nan


def money(value: float) -> str:
    sign = "+" if value >= 0.0 else "-"
    return f"{sign}${abs(value):,.2f}"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--ledger",
        default="outputs/THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_MODEL4_FULL_TRADES.csv",
    )
    parser.add_argument(
        "--out-csv",
        default="outputs/THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_MODEL4_FULL_SCREEN.csv",
    )
    parser.add_argument(
        "--out-md",
        default="outputs/THREE_LANE_MOMENTUM_FEATURE_TELEMETRY_MODEL4_FULL_SCREEN.md",
    )
    args = parser.parse_args()

    ledger = Path(args.ledger)
    if sha256(ledger) != EXPECTED_LEDGER_SHA256:
        raise RuntimeError("Full Model4 telemetry ledger identity changed.")
    frame = pd.read_csv(ledger)
    if len(frame) != 310 or set(frame["Era"]) != set(ERAS):
        raise RuntimeError("Unexpected telemetry population or era set.")

    numeric = {name for name, _ in GRID} | {"Profit", "RiskR", "Year"}
    for column in numeric:
        frame[column] = pd.to_numeric(frame[column], errors="raise")

    control_net = float(frame["Profit"].sum())
    control_pf = profit_factor(frame)
    control_era_net = {era: float(frame.loc[frame["Era"] == era, "Profit"].sum()) for era in ERAS}
    control_year_net = frame.groupby("Year")["Profit"].sum().to_dict()
    rows: list[dict[str, object]] = []

    for (feature, direction), thresholds in GRID.items():
        for index, threshold in enumerate(thresholds):
            mask = frame[feature] >= threshold if direction == "minimum" else frame[feature] <= threshold
            kept = frame.loc[mask]
            kept_net = float(kept["Profit"].sum())
            era_nets: dict[str, float] = {}
            era_impacts: dict[str, float] = {}
            for era in ERAS:
                era_kept = kept.loc[kept["Era"] == era]
                era_nets[era] = float(era_kept["Profit"].sum())
                era_impacts[era] = era_nets[era] - control_era_net[era]
            year_nets = kept.groupby("Year")["Profit"].sum().to_dict()
            losing_years = sum(float(year_nets.get(year, 0.0)) < 0.0 for year in control_year_net)
            improvement = kept_net - control_net
            positive_eras = sum(value > 0.0 for value in era_impacts.values())
            broad_losing_eras = sum(value < 0.0 for value in era_nets.values())
            keep_rate = len(kept) / len(frame)
            pf = profit_factor(kept)
            weak_gate = (
                keep_rate >= 0.70
                and improvement >= 25.0
                and positive_eras >= 3
                and min(era_impacts.values()) >= -20.0
                and broad_losing_eras == 0
            )
            strict_gate = (
                keep_rate >= 0.75
                and improvement >= 50.0
                and pf >= control_pf
                and positive_eras >= 3
                and min(era_impacts.values()) >= -10.0
                and broad_losing_eras == 0
                and losing_years <= 1
            )
            rows.append(
                {
                    "Feature": feature,
                    "Direction": direction,
                    "Threshold": threshold,
                    "GridIndex": index,
                    "ControlTrades": len(frame),
                    "KeptTrades": len(kept),
                    "KeepRatePercent": round(100.0 * keep_rate, 2),
                    "ControlNet": round(control_net, 2),
                    "FilteredNet": round(kept_net, 2),
                    "Improvement": round(improvement, 2),
                    "ControlProfitFactor": round(control_pf, 4),
                    "FilteredProfitFactor": round(float(pf), 4),
                    "PositiveEraImpacts": positive_eras,
                    "WorstEraImpact": round(min(era_impacts.values()), 2),
                    "BroadLosingEras": broad_losing_eras,
                    "LosingYears": losing_years,
                    "Net2015_2018": round(era_nets[ERAS[0]], 2),
                    "Net2019_2020": round(era_nets[ERAS[1]], 2),
                    "Net2021_2023": round(era_nets[ERAS[2]], 2),
                    "Net2024_2026": round(era_nets[ERAS[3]], 2),
                    "Impact2015_2018": round(era_impacts[ERAS[0]], 2),
                    "Impact2019_2020": round(era_impacts[ERAS[1]], 2),
                    "Impact2021_2023": round(era_impacts[ERAS[2]], 2),
                    "Impact2024_2026": round(era_impacts[ERAS[3]], 2),
                    "WeakGate": weak_gate,
                    "StrictGateBeforeNeighborhood": strict_gate,
                }
            )

    results = pd.DataFrame(rows)
    results["PassingNeighbors"] = 0
    for idx, row in results.iterrows():
        family = results[(results["Feature"] == row["Feature"]) & (results["Direction"] == row["Direction"])]
        neighbor = family[abs(family["GridIndex"] - int(row["GridIndex"])) == 1]
        results.loc[idx, "PassingNeighbors"] = int(neighbor["WeakGate"].sum())
    results["EligibleForCodeTest"] = (
        results["StrictGateBeforeNeighborhood"] & (results["PassingNeighbors"] >= 1)
    )
    results = results.sort_values(
        ["EligibleForCodeTest", "BroadLosingEras", "Improvement", "KeepRatePercent"],
        ascending=[False, True, False, False],
    )
    results.to_csv(args.out_csv, index=False, lineterminator="\n")

    eligible = results.loc[results["EligibleForCodeTest"]]
    top = results.head(15)
    lines = [
        "# Full Model4 Momentum Feature Screen",
        "",
        "**Status: EXPLORATORY NOMINATION ONLY. NO HISTORICAL LEADER OR FORWARD CANDIDATE CHANGED.**",
        "",
        f"- Exact ledger SHA-256: `{EXPECTED_LEDGER_SHA256}`",
        f"- Momentum control: {len(frame)} trades, {money(control_net)}, PF `{control_pf:.3f}`",
        f"- Broad-era control nets: {', '.join(f'{era} {money(control_era_net[era])}' for era in ERAS)}",
        f"- Single-feature thresholds screened: `{len(results)}`",
        f"- Rules eligible for a fresh code test: `{len(eligible)}`",
        "- Channel-width and breakout-fraction families are intentionally excluded because their earlier reserved validation failed.",
        "- Offline trade removal is not executable evidence: a removed trade can expose later signals that this ledger never observed.",
        "",
        "## Highest-Ranked Screens",
        "",
        "| Feature | Rule | Keep | Improvement | PF | Era nets (15-18 / 19-20 / 21-23 / 24-26) | Worst impact | Neighbors | Code test |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for _, row in top.iterrows():
        relation = ">=" if row["Direction"] == "minimum" else "<="
        era_text = " / ".join(
            money(float(row[column]))
            for column in ["Net2015_2018", "Net2019_2020", "Net2021_2023", "Net2024_2026"]
        )
        lines.append(
            f"| `{row['Feature']}` | `{relation} {row['Threshold']:g}` | "
            f"{int(row['KeptTrades'])} ({row['KeepRatePercent']:.2f}%) | "
            f"{money(float(row['Improvement']))} | {row['FilteredProfitFactor']:.3f} | "
            f"{era_text} | {money(float(row['WorstEraImpact']))} | "
            f"{int(row['PassingNeighbors'])} | {bool(row['EligibleForCodeTest'])} |"
        )
    lines += ["", "## Decision", ""]
    if eligible.empty:
        lines.append(
            "No single causal entry feature passed the frozen broad-era, retention, improvement, yearly-loss, and neighborhood gates. "
            "Do not implement a feature filter from this scan."
        )
    else:
        best = eligible.iloc[0]
        relation = ">=" if best["Direction"] == "minimum" else "<="
        lines.append(
            f"The first preregistered implementation candidate is `{best['Feature']} {relation} {best['Threshold']:g}`. "
            "It may enter fresh broad Model 1 testing only; recent and Model 4 confirmation remain sealed until that gate passes."
        )
    lines += [
        "",
        "The registered demo identity remains invalid under the frozen $10,000 account contract. Real-account trading remains locked.",
    ]
    Path(args.out_md).write_text("\n".join(lines) + "\n", encoding="ascii")

    print(f"CONTROL_NET={control_net:.2f}")
    print(f"CONTROL_PF={control_pf:.4f}")
    print(f"SCREENS={len(results)}")
    print(f"ELIGIBLE={len(eligible)}")
    if not eligible.empty:
        best = eligible.iloc[0]
        print(f"BEST={best['Feature']}:{best['Direction']}:{best['Threshold']:g}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
