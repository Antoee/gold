#!/usr/bin/env python3
"""Join momentum telemetry to annual real-tick outcomes and scan compact filters."""

from __future__ import annotations

import csv
import itertools
import math
import re
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = ROOT / "outputs"
OLD_FEATURES = OUTPUTS / "RDMC_CAP12_MODEL4_2015_2018_MOMENTUM_FEATURES.csv"
TELEMETRY = OUTPUTS / "RC2_MOMENTUM_FEATURE_TELEMETRY_MO_2019_2022.csv"
ANNUAL_TRADES = OUTPUTS / "RDMC_CAP12_MODEL4_ANNUAL_TRADES.csv"
JOINED_NEW = OUTPUTS / "RDMC_CAP12_MODEL4_2019_2022_MOMENTUM_FEATURES.csv"
COMBINED = OUTPUTS / "RDMC_MOMENTUM_FEATURE_TRAINING_2015_2022.csv"
SINGLE_SCAN = OUTPUTS / "RDMC_MOMENTUM_FEATURE_2015_2022_SINGLE_SCAN.csv"
PAIR_SCAN = OUTPUTS / "RDMC_MOMENTUM_FEATURE_2015_2022_PAIR_SCAN.csv"
DECISION = OUTPUTS / "RDMC_MOMENTUM_FEATURE_2015_2022_DECISION.md"

FEATURES = (
    "channel_width_atr",
    "breakout_atr",
    "h1_efficiency",
    "d1_efficiency",
    "d1_momentum_pct",
    "atr_pct",
    "body_ratio",
    "close_location",
    "range_atr",
    "volume_ratio",
    "stop_atr",
)


@dataclass(frozen=True)
class Rule:
    name: str
    feature: str
    operator: str
    threshold: float

    def allows(self, row: dict[str, object]) -> bool:
        value = abs(float(row[self.feature])) if self.feature == "d1_momentum_pct" else float(row[self.feature])
        return value >= self.threshold if self.operator == "min" else value <= self.threshold


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="ascii") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def telemetry_entries() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    pattern = {feature: re.compile(rf"(?:^|;){re.escape(feature)}=([-0-9.]+)") for feature in FEATURES}
    with TELEMETRY.open(newline="", encoding="utf-16") as handle:
        reader = csv.reader(handle, delimiter="\t")
        for cells in reader:
            if len(cells) < 13 or cells[1] != "entry":
                continue
            reason = cells[9]
            row: dict[str, object] = {
                "EntryTime": datetime.strptime(cells[0], "%Y.%m.%d %H:%M:%S").isoformat(),
                "Side": cells[4].lower(),
            }
            for feature, regex in pattern.items():
                match = regex.search(reason)
                if not match:
                    raise RuntimeError(f"Telemetry entry {cells[0]} is missing {feature}")
                row[feature] = float(match.group(1))
            rows.append(row)
    if not rows:
        raise RuntimeError("No momentum telemetry entries were parsed")
    return rows


def annual_real_tick_data() -> tuple[dict[tuple[str, str], dict[str, str]], dict[int, float]]:
    momentum: dict[tuple[str, str], dict[str, str]] = {}
    reversion_by_year: dict[int, float] = defaultdict(float)
    for row in read_csv(ANNUAL_TRADES):
        year = int(row["TestWindow"].replace("_ytd", ""))
        if year < 2015 or year > 2022:
            continue
        if row["EntryComment"].startswith("MTSM_"):
            key = (row["EntryTime"], row["Side"].lower())
            if key in momentum:
                raise RuntimeError(f"Duplicate annual momentum key: {key}")
            momentum[key] = row
        else:
            reversion_by_year[year] += float(row["Profit"])
    return momentum, reversion_by_year


def join_features() -> tuple[list[dict[str, object]], list[tuple[str, str]]]:
    outcomes, _ = annual_real_tick_data()
    joined: list[dict[str, object]] = []
    unmatched: list[tuple[str, str]] = []
    for feature_row in telemetry_entries():
        key = (str(feature_row["EntryTime"]), str(feature_row["Side"]))
        outcome = outcomes.get(key)
        if outcome is None:
            unmatched.append(key)
            continue
        row: dict[str, object] = {
            "Year": int(outcome["TestWindow"].replace("_ytd", "")),
            "EntryTime": key[0],
            "Side": key[1],
            "Profit": float(outcome["Profit"]),
            "RiskR": float(outcome["RiskR"]),
        }
        for feature in FEATURES:
            row[feature] = feature_row[feature]
        joined.append(row)
    expected = sum(1 for key, row in outcomes.items() if 2019 <= int(row["TestWindow"].replace("_ytd", "")) <= 2022)
    if len(joined) < math.floor(expected * 0.95):
        raise RuntimeError(f"Only matched {len(joined)} of {expected} annual momentum trades")
    return joined, unmatched


def normalized_old_rows() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for source in read_csv(OLD_FEATURES):
        row: dict[str, object] = {
            "Year": int(source["Year"]),
            "EntryTime": source["EntryTime"],
            "Side": source["Side"].lower(),
            "Profit": float(source["Profit"]),
            "RiskR": float(source["RiskR"]),
        }
        for feature in FEATURES:
            row[feature] = float(source[feature])
        rows.append(row)
    return rows


def rules() -> list[Rule]:
    grid: dict[str, tuple[str, tuple[float, ...]]] = {
        "breakout_atr": ("min", (0.10, 0.20, 0.30, 0.40)),
        "h1_efficiency": ("min", (0.15, 0.20, 0.25, 0.30)),
        "h1_efficiency_max": ("max", (0.45, 0.55, 0.65, 0.75)),
        "d1_efficiency_max": ("max", (0.08, 0.12, 0.16, 0.20)),
        "d1_momentum_pct_max": ("max", (6.0, 8.0, 10.0, 12.0, 14.0)),
        "body_ratio": ("min", (0.40, 0.50, 0.60)),
        "close_location": ("min", (0.55, 0.65, 0.75)),
        "range_atr": ("min", (0.75, 1.00, 1.25, 1.50)),
        "volume_ratio": ("min", (0.75, 1.00, 1.25)),
        "channel_width_atr_max": ("max", (4.0, 5.0, 6.0, 7.0)),
        "stop_atr_max": ("max", (1.75, 2.00, 2.25, 2.50)),
    }
    result: list[Rule] = []
    for key, (operator, thresholds) in grid.items():
        feature = key.removesuffix("_max")
        for threshold in thresholds:
            result.append(Rule(f"{operator}_{feature}_{threshold:g}", feature, operator, threshold))
    return result


def metrics(rows: list[dict[str, object]], reversion: dict[int, float], selected: tuple[Rule, ...]) -> dict[str, object]:
    kept = [row for row in rows if all(rule.allows(row) for rule in selected)]
    gross_profit = sum(float(row["Profit"]) for row in kept if float(row["Profit"]) > 0)
    gross_loss = -sum(float(row["Profit"]) for row in kept if float(row["Profit"]) < 0)
    yearly_momentum = {year: sum(float(row["Profit"]) for row in kept if int(row["Year"]) == year) for year in range(2015, 2023)}
    yearly_portfolio = {year: yearly_momentum[year] + reversion.get(year, 0.0) for year in range(2015, 2023)}
    return {
        "Rule": " & ".join(rule.name for rule in selected) if selected else "control",
        "Rules": len(selected),
        "Trades": len(kept),
        "RetainedPercent": round(100.0 * len(kept) / max(1, len(rows)), 2),
        "MomentumNet": round(sum(float(row["Profit"]) for row in kept), 2),
        "MomentumPF": round(gross_profit / gross_loss, 4) if gross_loss else "INF",
        "PositivePortfolioYears": sum(net > 0 for net in yearly_portfolio.values()),
        "WorstPortfolioYearNet": round(min(yearly_portfolio.values()), 2),
        "PortfolioNet": round(sum(yearly_portfolio.values()), 2),
        **{f"Y{year}": round(yearly_portfolio[year], 2) for year in range(2015, 2023)},
    }


def main() -> None:
    joined_new, unmatched = join_features()
    combined = normalized_old_rows() + joined_new
    _, reversion = annual_real_tick_data()
    fields = ["Year", "EntryTime", "Side", "Profit", "RiskR", *FEATURES]
    write_csv(JOINED_NEW, joined_new, fields)
    write_csv(COMBINED, combined, fields)

    primitive_rules = rules()
    single = [metrics(combined, reversion, (rule,)) for rule in primitive_rules]
    pair: list[dict[str, object]] = []
    for first, second in itertools.combinations(primitive_rules, 2):
        if first.feature == second.feature:
            continue
        result = metrics(combined, reversion, (first, second))
        if float(result["RetainedPercent"]) >= 45.0:
            pair.append(result)

    result_fields = [
        "Rule", "Rules", "Trades", "RetainedPercent", "MomentumNet", "MomentumPF",
        "PositivePortfolioYears", "WorstPortfolioYearNet", "PortfolioNet",
        *[f"Y{year}" for year in range(2015, 2023)],
    ]
    single.sort(key=lambda row: (int(row["PositivePortfolioYears"]), float(row["WorstPortfolioYearNet"]), float(row["PortfolioNet"])), reverse=True)
    pair.sort(key=lambda row: (int(row["PositivePortfolioYears"]), float(row["WorstPortfolioYearNet"]), float(row["PortfolioNet"])), reverse=True)
    write_csv(SINGLE_SCAN, single, result_fields)
    write_csv(PAIR_SCAN, pair[:250], result_fields)

    eligible_single = [row for row in single if int(row["PositivePortfolioYears"]) == 8 and float(row["RetainedPercent"]) >= 60.0]
    eligible_pair = [row for row in pair if int(row["PositivePortfolioYears"]) == 8 and float(row["RetainedPercent"]) >= 50.0]
    best = (eligible_single or eligible_pair or single)[:5]
    status = "COMPACT_FILTER_FOUND_AWAITING_EXECUTABLE_GATE" if eligible_single or eligible_pair else "NO_ROBUST_FILTER_REPLACE_MOMENTUM_ENGINE"

    lines = [
        "# RDMC Momentum Feature Training Extension",
        "",
        f"**Status: {status}. No candidate, forward, or real-money change.**",
        "",
        f"- Older exact Model4 rows: `{len(normalized_old_rows())}`",
        f"- New 2019-2022 telemetry-to-Model4 matches: `{len(joined_new)}`",
        f"- Unmatched telemetry entries: `{len(unmatched)}`",
        f"- Single rules with 8/8 positive portfolio years and at least 60% activity: `{len(eligible_single)}`",
        f"- Two-rule combinations with 8/8 positive portfolio years and at least 50% activity: `{len(eligible_pair)}`",
        "- Feature selection stops at 2022; 2023-2026 remains outside this scan.",
        "",
        "| Rule | Trades | Retained | Portfolio net | Worst year | Positive years |",
        "| --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in best:
        lines.append(
            f"| `{row['Rule']}` | {row['Trades']} | {row['RetainedPercent']}% | "
            f"${float(row['PortfolioNet']):+.2f} | ${float(row['WorstPortfolioYearNet']):+.2f} | "
            f"{row['PositivePortfolioYears']}/8 |"
        )
    lines += [
        "",
        "This is a training scan, not an executable result. Any nominated rule requires a fresh source/profile identity, exact compilation, adjacent-threshold support, and staged MT5 validation.",
    ]
    DECISION.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"{status} matched={len(joined_new)} unmatched={len(unmatched)} singles={len(eligible_single)} pairs={len(eligible_pair)}")


if __name__ == "__main__":
    main()
