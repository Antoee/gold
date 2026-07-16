#!/usr/bin/env python3
"""Join exact H1 reversion entries to diagnostics and screen simple state gates."""

from __future__ import annotations

import csv
import math
import re
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from statistics import mean, median
from typing import Callable


ROOT = Path(__file__).resolve().parents[1]
LOG_PATH = ROOT / "outputs" / "HTF_BAND_REVERSION_FEATURE_LOG.csv"
TRADES_PATH = ROOT / "outputs" / "HTF_BAND_REVERSION_FEATURE_TRADES.csv"
OUT_JOINED = ROOT / "outputs" / "HTF_BAND_REVERSION_FEATURE_JOINED.csv"
OUT_GATES = ROOT / "outputs" / "HTF_BAND_REVERSION_FEATURE_GATES.csv"
OUT_MD = ROOT / "outputs" / "HTF_BAND_REVERSION_FEATURE_ANALYSIS.md"
STRESS_R = 0.05

LOG_FIELDS = [
    "time",
    "event",
    "symbol",
    "ticket",
    "bias",
    "volume",
    "price",
    "sl",
    "tp",
    "planned_risk_r",
    "logged_profit",
    "reason",
    "atr",
    "spread_points",
    "max_favorable_r",
    "max_adverse_r",
    "held_bars",
    "entry_context",
    "profile_id",
    "source_hash",
    "run_label",
]

FEATURE_PATTERNS = {
    "RSI": r"(?:^|;)RSI (-?\d+(?:\.\d+)?)",
    "BandWidthATR": r"Band width (-?\d+(?:\.\d+)?) ATR",
    "ADX": r"(?:^|;)ADX (-?\d+(?:\.\d+)?)",
    "ADXDelta": r"ADX delta (-?\d+(?:\.\d+)?)",
    "DIEdge": r"DI edge (-?\d+(?:\.\d+)?)",
    "ATRRatio": r"ATR ratio (-?\d+(?:\.\d+)?)",
    "TrendDistATR": r"Trend dist ATR (-?\d+(?:\.\d+)?)",
    "TrendSlopeATR": r"Trend slope ATR (-?\d+(?:\.\d+)?)",
    "FastTrendDistATR": r"Fast trend dist ATR (-?\d+(?:\.\d+)?)",
    "MTFDistATR": r"MTF dist ATR (-?\d+(?:\.\d+)?)",
    "BodyPct": r"Body pct (-?\d+(?:\.\d+)?)",
    "WickPct": r"Wick pct (-?\d+(?:\.\d+)?)",
    "CloseLoc": r"Close loc (-?\d+(?:\.\d+)?)",
    "StopATR": r"Stop ATR (-?\d+(?:\.\d+)?)",
    "TargetATR": r"Target ATR (-?\d+(?:\.\d+)?)",
    "TradeRR": r"Trade RR (-?\d+(?:\.\d+)?)",
    "SpreadATRPct": r"Spread ATR pct (-?\d+(?:\.\d+)?)",
}


@dataclass(frozen=True)
class Gate:
    name: str
    feature: str
    operator: str
    threshold: float
    allows: Callable[[dict[str, object]], bool]


def parse_float(value: str) -> float:
    return float(value) if value.strip() else 0.0


def load_entries() -> dict[tuple[str, str], dict[str, object]]:
    entries: dict[tuple[str, str], dict[str, object]] = {}
    with LOG_PATH.open("r", encoding="utf-16", newline="") as handle:
        for values in csv.reader(handle, delimiter="\t"):
            if not values or len(values) < len(LOG_FIELDS):
                continue
            row = dict(zip(LOG_FIELDS, values))
            if row["event"] != "entry":
                continue
            timestamp = datetime.strptime(row["time"], "%Y.%m.%d %H:%M:%S").isoformat()
            reason = row["reason"]
            parsed: dict[str, object] = {
                "EntryTime": timestamp,
                "Side": row["bias"],
                "LoggedEntryPrice": parse_float(row["price"]),
                "LoggedStop": parse_float(row["sl"]),
                "LoggedTarget": parse_float(row["tp"]),
                "ATR": parse_float(row["atr"]),
                "SpreadPoints": parse_float(row["spread_points"]),
                "Reason": reason,
            }
            for feature, pattern in FEATURE_PATTERNS.items():
                match = re.search(pattern, reason)
                if not match:
                    raise ValueError(f"Missing {feature} in reason for {timestamp}: {reason}")
                parsed[feature] = float(match.group(1))
            rsi = float(parsed["RSI"])
            parsed["RSIDepth"] = 50.0 - rsi if row["bias"] == "buy" else rsi - 50.0
            parsed["AbsTrendDistATR"] = abs(float(parsed["TrendDistATR"]))
            parsed["AbsTrendSlopeATR"] = abs(float(parsed["TrendSlopeATR"]))
            entries[(timestamp, row["bias"])] = parsed
    return entries


def join_trades(entries: dict[tuple[str, str], dict[str, object]]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    with TRADES_PATH.open("r", encoding="utf-8-sig", newline="") as handle:
        for trade in csv.DictReader(handle):
            key = (trade["EntryTime"], trade["Side"])
            if key not in entries:
                raise KeyError(f"No feature row for {key}")
            row = {
                **trade,
                **entries[key],
                "EntryYear": int(trade["EntryYear"]),
                "ExitYear": datetime.fromisoformat(trade["ExitTime"]).year,
                "RiskR": float(trade["RiskR"]),
                "Profit": float(trade["Profit"]),
                "Winner": float(trade["RiskR"]) > 0.0,
            }
            rows.append(row)
    if len(rows) != len(entries):
        raise ValueError(f"Entry/trade count mismatch: entries={len(entries)} trades={len(rows)}")
    return rows


def metrics(rows: list[dict[str, object]], stress_r: float = 0.0) -> dict[str, object]:
    values = [float(row["RiskR"]) - stress_r for row in rows]
    gross_profit = sum(value for value in values if value > 0)
    gross_loss = -sum(value for value in values if value < 0)
    yearly: dict[int, float] = defaultdict(float)
    for row, value in zip(rows, values):
        yearly[int(row["ExitYear"])] += value
    red = {year: value for year, value in yearly.items() if value < 0}
    discovery = sum(
        value for row, value in zip(rows, values) if int(row["EntryYear"]) <= 2022
    )
    recent = sum(
        value for row, value in zip(rows, values) if int(row["EntryYear"]) >= 2023
    )
    return {
        "Trades": len(rows),
        "NetR": round(sum(values), 4),
        "ProfitFactor": round(gross_profit / gross_loss, 4) if gross_loss else math.inf,
        "WinRatePercent": round(100.0 * sum(value > 0 for value in values) / max(1, len(values)), 2),
        "RedYears": len(red),
        "WorstYear": min(red, key=red.get) if red else 0,
        "WorstYearR": round(min(red.values()), 4) if red else 0.0,
        "DiscoveryR": round(discovery, 4),
        "RecentR": round(recent, 4),
    }


def make_gates() -> list[Gate]:
    definitions = [
        ("ADX", "<=", [18, 19, 20, 21, 22]),
        ("ADXDelta", "<=", [-10, -5, 0, 1, 2, 5, 10]),
        ("DIEdge", ">=", [-20, -15, -10, -5, 0, 5]),
        ("ATRRatio", "<=", [0.9, 1.0, 1.1, 1.15, 1.2, 1.3, 1.4]),
        ("AbsTrendDistATR", "<=", [4, 6, 8, 10, 12]),
        ("AbsTrendSlopeATR", "<=", [0.1, 0.2, 0.3, 0.4, 0.5, 0.75]),
        ("BodyPct", ">=", [0, 5, 10, 15, 20, 25, 30]),
        ("WickPct", ">=", [15, 20, 25, 30, 35, 40]),
        ("RSIDepth", ">=", [10, 11, 12, 13, 14, 15]),
        ("StopATR", ">=", [0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2]),
        ("TargetATR", ">=", [1.0, 1.25, 1.5, 1.75, 2.0, 2.5]),
        ("TradeRR", "<=", [2.0, 2.5, 3.0, 3.5, 4.0, 5.0]),
        ("SpreadATRPct", "<=", [8, 10, 12, 14, 16, 18]),
        ("BandWidthATR", "<=", [2.0, 2.5, 3.0, 3.5, 4.0, 4.5]),
    ]
    gates: list[Gate] = []
    for feature, operator, thresholds in definitions:
        for threshold in thresholds:
            if operator == "<=":
                allows = lambda row, f=feature, t=threshold: float(row[f]) <= t
            else:
                allows = lambda row, f=feature, t=threshold: float(row[f]) >= t
            gates.append(
                Gate(
                    name=f"{feature}{operator}{threshold:g}",
                    feature=feature,
                    operator=operator,
                    threshold=float(threshold),
                    allows=allows,
                )
            )
    return gates


def feature_summary(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    winners = [row for row in rows if bool(row["Winner"])]
    losers = [row for row in rows if not bool(row["Winner"])]
    red_year_rows = [row for row in rows if int(row["ExitYear"]) in {2016, 2020, 2024}]
    result: list[dict[str, object]] = []
    for feature in [*FEATURE_PATTERNS, "RSIDepth", "AbsTrendDistATR", "AbsTrendSlopeATR"]:
        all_values = [float(row[feature]) for row in rows]
        win_values = [float(row[feature]) for row in winners]
        loss_values = [float(row[feature]) for row in losers]
        red_values = [float(row[feature]) for row in red_year_rows]
        result.append(
            {
                "Feature": feature,
                "AllMedian": round(median(all_values), 4),
                "WinnerMedian": round(median(win_values), 4),
                "LoserMedian": round(median(loss_values), 4),
                "RedYearMedian": round(median(red_values), 4),
                "WinnerMean": round(mean(win_values), 4),
                "LoserMean": round(mean(loss_values), 4),
            }
        )
    return result


def main() -> int:
    rows = join_trades(load_entries())
    with OUT_JOINED.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    gate_rows: list[dict[str, object]] = []
    baseline = metrics(rows)
    baseline_stress = metrics(rows, STRESS_R)
    for gate in make_gates():
        kept = [row for row in rows if gate.allows(row)]
        base = metrics(kept)
        stress = metrics(kept, STRESS_R)
        eligible = (
            int(base["RedYears"]) == 0
            and int(stress["RedYears"]) == 0
            and int(base["Trades"]) >= 20
            and float(base["ProfitFactor"]) >= 1.30
            and float(base["DiscoveryR"]) > 0
            and float(base["RecentR"]) > 0
        )
        score = (
            -4.0 * int(base["RedYears"])
            - 4.0 * int(stress["RedYears"])
            + 0.15 * float(base["NetR"])
            + 0.5 * min(float(base["ProfitFactor"]), 5.0)
            + 0.02 * int(base["Trades"])
        )
        gate_rows.append(
            {
                "Gate": gate.name,
                "Feature": gate.feature,
                "Operator": gate.operator,
                "Threshold": gate.threshold,
                "EligibleDiagnostic": str(eligible),
                "Score": round(score, 4),
                **base,
                "StressNetR": stress["NetR"],
                "StressProfitFactor": stress["ProfitFactor"],
                "StressRedYears": stress["RedYears"],
                "StressWorstYear": stress["WorstYear"],
                "StressWorstYearR": stress["WorstYearR"],
            }
        )
    gate_rows.sort(
        key=lambda row: (
            row["EligibleDiagnostic"] == "True",
            float(row["Score"]),
            int(row["Trades"]),
        ),
        reverse=True,
    )
    with OUT_GATES.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(gate_rows[0]))
        writer.writeheader()
        writer.writerows(gate_rows)

    summaries = feature_summary(rows)
    eligible = [row for row in gate_rows if row["EligibleDiagnostic"] == "True"]
    lines = [
        "# H1 Band Reversion Feature Analysis",
        "",
        "This is a hypothesis-generation screen over exact Model4 trades, not promotion evidence.",
        "",
        f"- Exact joined trades: `{len(rows)}`",
        f"- Baseline: `{baseline['NetR']}R`, PF `{baseline['ProfitFactor']}`, red years `{baseline['RedYears']}`",
        f"- Baseline 0.05R stress: `{baseline_stress['NetR']}R`, PF `{baseline_stress['ProfitFactor']}`, red years `{baseline_stress['RedYears']}`",
        f"- One-factor gates screened: `{len(gate_rows)}`",
        f"- Diagnostic gate passes: `{len(eligible)}`",
        "",
        "## Feature Separation",
        "",
        "| Feature | All median | Winner median | Loser median | Red-year median | Winner mean | Loser mean |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in summaries:
        lines.append(
            f"| {row['Feature']} | {row['AllMedian']} | {row['WinnerMedian']} | "
            f"{row['LoserMedian']} | {row['RedYearMedian']} | {row['WinnerMean']} | {row['LoserMean']} |"
        )
    lines.extend(
        [
            "",
            "## Top One-Factor Gates",
            "",
            "| Gate | Diagnostic pass | Trades | Net R | PF | Red years | Stress red years | Discovery R | Recent R |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in gate_rows[:25]:
        lines.append(
            f"| `{row['Gate']}` | {row['EligibleDiagnostic']} | {row['Trades']} | "
            f"{row['NetR']} | {row['ProfitFactor']} | {row['RedYears']} | "
            f"{row['StressRedYears']} | {row['DiscoveryR']} | {row['RecentR']} |"
        )
    lines.extend(
        [
            "",
            "Any selected gate must be predeclared as a small neighboring MT5 parameter test and pass continuous plus yearly Model4. Offline filtering alone cannot change the strategy decision.",
        ]
    )
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(
        f"HTF_BAND_REVERSION_FEATURE_ANALYSIS_COMPLETE trades={len(rows)} "
        f"gates={len(gate_rows)} eligible={len(eligible)} top={gate_rows[0]['Gate']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
