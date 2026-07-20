"""Preregistered time-split screen for causal squeeze entry filters."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

import numpy as np
import pandas as pd


FEATURES = (
    "BreakoutATR",
    "BodyRatio",
    "CloseLocation",
    "RangeATR",
    "ExpansionRatio",
    "ChannelWidthATR",
    "SqueezeRangeATR",
    "TickVolumeRatio",
    "ATRPercent",
    "ADX",
    "TrendDistanceATR",
    "TrendSlopeATR",
    "SqueezeRatioMean",
    "SqueezeRatioMax",
    "StopATR",
)
QUANTILES = (0.15, 0.20, 0.25)
MIN_RETENTION = 0.75
MIN_CENTER_IMPROVEMENT = 5.0


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def profit_factor(values: pd.Series) -> float:
    gross_profit = float(values[values > 0.0].sum())
    gross_loss = abs(float(values[values < 0.0].sum()))
    return gross_profit / gross_loss if gross_loss > 1e-12 else float("inf")


def evaluate(frame: pd.DataFrame, feature: str, direction: str, threshold: float) -> dict[str, float | int | bool]:
    keep = frame[feature] >= threshold if direction == "minimum" else frame[feature] <= threshold
    kept = frame[keep]
    removed = frame[~keep]
    baseline_net = float(frame["Profit"].sum())
    kept_net = float(kept["Profit"].sum())
    removed_net = float(removed["Profit"].sum())
    return {
        "Trades": len(frame),
        "KeptTrades": len(kept),
        "RemovedTrades": len(removed),
        "Retention": len(kept) / len(frame) if len(frame) else 0.0,
        "BaselineNet": baseline_net,
        "KeptNet": kept_net,
        "RemovedNet": removed_net,
        "Improvement": kept_net - baseline_net,
        "BaselinePF": profit_factor(frame["Profit"]),
        "KeptPF": profit_factor(kept["Profit"]),
    }


def split_support(frame: pd.DataFrame, feature: str, direction: str, threshold: float) -> tuple[bool, dict[str, float]]:
    impacts: dict[str, float] = {}
    supported = True
    for name, years in (("early", (2015, 2016)), ("late", (2017, 2018))):
        part = frame[frame["Year"].isin(years)]
        result = evaluate(part, feature, direction, threshold)
        impacts[f"{name}_improvement"] = float(result["Improvement"])
        impacts[f"{name}_removed"] = int(result["RemovedTrades"])
        if int(result["RemovedTrades"]) < 1 or float(result["Improvement"]) < -1e-9:
            supported = False
    return supported, impacts


def validation_support(frame: pd.DataFrame, feature: str, direction: str, threshold: float) -> tuple[bool, dict[str, float]]:
    result = evaluate(frame, feature, direction, threshold)
    impacts: dict[str, float] = {
        "validation_improvement": float(result["Improvement"]),
        "validation_retention": float(result["Retention"]),
        "validation_pf": float(result["KeptPF"]),
    }
    supported = float(result["Retention"]) >= MIN_RETENTION and int(result["RemovedTrades"]) >= 1
    for year in (2019, 2020):
        part = frame[frame["Year"] == year]
        year_result = evaluate(part, feature, direction, threshold)
        impacts[f"validation_{year}_improvement"] = float(year_result["Improvement"])
        impacts[f"validation_{year}_removed"] = int(year_result["RemovedTrades"])
        if float(year_result["Improvement"]) < -1e-9:
            supported = False
    if float(result["Improvement"]) < -1e-9:
        supported = False
    return supported, impacts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ledger", default="outputs/FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_TRADES.csv")
    parser.add_argument("--expected-ledger-sha256", default="")
    parser.add_argument("--screen", default="outputs/FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_SCREEN.csv")
    parser.add_argument("--selection", default="outputs/FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_SELECTION.csv")
    parser.add_argument("--markdown", default="outputs/FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_SCREEN.md")
    args = parser.parse_args()

    ledger = Path(args.ledger)
    if args.expected_ledger_sha256 and sha256(ledger) != args.expected_ledger_sha256.upper():
        raise RuntimeError("Telemetry ledger identity changed.")
    frame = pd.read_csv(ledger)
    required = {"Year", "Profit", *FEATURES}
    if not required.issubset(frame.columns):
        raise RuntimeError(f"Ledger columns missing: {sorted(required - set(frame.columns))}")
    if len(frame) != 88 or frame["Year"].min() != 2015 or frame["Year"].max() != 2020:
        raise RuntimeError("Expected exactly 88 squeeze trades from 2015 through 2020.")
    if frame[list(FEATURES)].isna().any().any() or (frame[list(FEATURES)] < 0.0).any().any():
        raise RuntimeError("Telemetry features must be finite nonnegative completed-bar values.")

    training = frame[frame["Year"] <= 2018].copy()
    validation = frame[frame["Year"] >= 2019].copy()
    if len(training) != 55 or len(validation) != 33:
        raise RuntimeError("Frozen 55/33 training-validation population changed.")

    rows: list[dict[str, object]] = []
    families: list[dict[str, object]] = []
    for feature_index, feature in enumerate(FEATURES):
        for direction in ("minimum", "maximum"):
            thresholds: list[float] = []
            for quantile in QUANTILES:
                q = quantile if direction == "minimum" else 1.0 - quantile
                thresholds.append(float(training[feature].quantile(q, interpolation="linear")))
            family_rows: list[dict[str, object]] = []
            for neighbor, (quantile, threshold) in enumerate(zip(QUANTILES, thresholds), start=-1):
                result = evaluate(training, feature, direction, threshold)
                split_pass, split = split_support(training, feature, direction, threshold)
                row: dict[str, object] = {
                    "Feature": feature,
                    "FeatureIndex": feature_index,
                    "Direction": direction,
                    "Quantile": quantile,
                    "NeighborOffset": neighbor,
                    "Threshold": threshold,
                    **result,
                    **split,
                }
                row["TrainingSupport"] = bool(
                    split_pass
                    and float(result["Retention"]) >= MIN_RETENTION
                    and int(result["RemovedTrades"]) >= 1
                    and float(result["KeptPF"]) > float(result["BaselinePF"])
                    and float(result["Improvement"]) >= -1e-9
                )
                family_rows.append(row)
                rows.append(row)
            center = family_rows[1]
            family_pass = bool(
                all(bool(row["TrainingSupport"]) for row in family_rows)
                and float(center["Improvement"]) >= MIN_CENTER_IMPROVEMENT
            )
            robust_score = min(float(row["Improvement"]) for row in family_rows)
            families.append(
                {
                    "Feature": feature,
                    "FeatureIndex": feature_index,
                    "Direction": direction,
                    "FamilyPass": family_pass,
                    "RobustScore": robust_score,
                    "CenterThreshold": thresholds[1],
                    "LowThreshold": thresholds[0],
                    "HighThreshold": thresholds[2],
                    "CenterTrainingImprovement": float(center["Improvement"]),
                    "CenterTrainingPF": float(center["KeptPF"]),
                }
            )

    screen = pd.DataFrame(rows)
    screen.to_csv(args.screen, index=False, float_format="%.8f")
    passing = [family for family in families if bool(family["FamilyPass"])]
    passing.sort(key=lambda row: (-float(row["RobustScore"]), -float(row["CenterTrainingImprovement"]), int(row["FeatureIndex"]), str(row["Direction"])))

    selection: dict[str, object] = {
        "Status": "NO_TRAINING_CANDIDATE",
        "TrainingTrades": len(training),
        "ValidationTrades": len(validation),
        "PassingTrainingFamilies": len(passing),
        "ValidationOpened": False,
        "CodeTestPermitted": False,
        "LedgerSha256": sha256(ledger),
    }
    validation_rows: list[dict[str, object]] = []
    if passing:
        selected = passing[0]
        selection.update(selected)
        selection["ValidationOpened"] = True
        for label, threshold in (
            ("low", float(selected["LowThreshold"])),
            ("center", float(selected["CenterThreshold"])),
            ("high", float(selected["HighThreshold"])),
        ):
            valid, metrics = validation_support(validation, str(selected["Feature"]), str(selected["Direction"]), threshold)
            validation_rows.append({"Label": label, "Threshold": threshold, "Pass": valid, **metrics})
        center_pass = bool(validation_rows[1]["Pass"])
        neighbor_passes = int(bool(validation_rows[0]["Pass"])) + int(bool(validation_rows[2]["Pass"]))
        selection["ValidationCenterPass"] = center_pass
        selection["ValidationNeighborPasses"] = neighbor_passes
        selection["ValidationCenterImprovement"] = validation_rows[1]["validation_improvement"]
        selection["Status"] = "PASS_TO_CODE_TEST" if center_pass and neighbor_passes >= 1 else "REJECTED_IN_VALIDATION"
        selection["CodeTestPermitted"] = selection["Status"] == "PASS_TO_CODE_TEST"

    pd.DataFrame([selection]).to_csv(args.selection, index=False, float_format="%.8f")
    lines = [
        "# M15 Squeeze Feature-Telemetry Screen",
        "",
        f"**Decision: {selection['Status']}.**",
        "",
        f"- Ledger SHA-256: `{selection['LedgerSha256']}`",
        f"- Frozen population: `{len(training)}` training trades (2015-2018), `{len(validation)}` one-shot validation trades (2019-2020)",
        f"- Features: `{len(FEATURES)}`; directions: `2`; fixed quantile neighborhood: `15% / 20% / 25%`",
        f"- Passing training families: `{len(passing)}`",
    ]
    if passing:
        lines.extend(
            [
                f"- Selected from training only: `{selection['Feature']}` `{selection['Direction']}` at `{float(selection['CenterThreshold']):.8f}`",
                f"- Training center improvement: `${float(selection['CenterTrainingImprovement']):.2f}`; robust-neighborhood score: `${float(selection['RobustScore']):.2f}`",
                f"- Validation center pass: `{selection['ValidationCenterPass']}`; validating neighbors: `{selection['ValidationNeighborPasses']}/2`",
                "",
                "| Validation rung | Threshold | Improvement | 2019 | 2020 | Retention | PF | Pass |",
                "|---|---:|---:|---:|---:|---:|---:|---|",
            ]
        )
        for row in validation_rows:
            lines.append(
                f"| {row['Label']} | {float(row['Threshold']):.8f} | ${float(row['validation_improvement']):.2f} | "
                f"${float(row['validation_2019_improvement']):.2f} | ${float(row['validation_2020_improvement']):.2f} | "
                f"{100.0 * float(row['validation_retention']):.2f}% | {float(row['validation_pf']):.4f} | {row['Pass']} |"
            )
    lines.extend(
        [
            "",
            "This is an offline hypothesis screen, not a backtest promotion. Only `PASS_TO_CODE_TEST` permits a default-off implementation under a separately frozen MT5 neighborhood. Post-2020 data, Model 4, forward substitution, and real-account trading remain closed.",
        ]
    )
    Path(args.markdown).write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"STATUS={selection['Status']}")
    if passing:
        print(f"FEATURE={selection['Feature']}")
        print(f"DIRECTION={selection['Direction']}")
        print(f"THRESHOLD={float(selection['CenterThreshold']):.8f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
