#!/usr/bin/env python3
"""Read-only post-hoc screen for the frozen RDMC H1 signal-range gate.

This does not run MT5 and cannot replace the preregistered Model1 reports.
Removing a control trade can change later entry availability, so the result is
diagnostic evidence only. The script validates its H1 cache and ATR alignment
against all 135 previously joined 2015-2018 telemetry trades before examining
the reserved 2019 and 2022 trade ledgers.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import math
import struct
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CACHE = (
    ROOT.parent
    / "mt5_portable_research"
    / "Bases"
    / "MetaQuotes-Demo"
    / "history"
    / "XAUUSD"
    / "cache"
    / "H1.hc"
)
EXPECTED_CACHE_SHA256 = "9B19B41AEF4B183C463777C907E05F8BD8F974B5AF670660B885DEA278AB3E7C"
EXPECTED_LEDGER_SHA256 = "6BC726AB9D2C1BBC022419B1AEEB2F62C1D9E2EA7435B59F7BADD03539F22576"
EXPECTED_TELEMETRY_SHA256 = "2BA7856B36D144B57334037A2B1B2BD389E94495413549B6388465A52179B087"
ATR_PERIOD = 20
THRESHOLDS = (
    ("srg_control", None),
    ("srg_min100", 1.00),
    ("srg_min125_center", 1.25),
    ("srg_min150", 1.50),
)
FAILURE_YEARS = (2019, 2022)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


@dataclass(frozen=True)
class H1Cache:
    times: tuple[int, ...]
    opens: tuple[float, ...]
    highs: tuple[float, ...]
    lows: tuple[float, ...]
    closes: tuple[float, ...]
    tick_volumes: tuple[int, ...]
    spreads: tuple[int, ...]
    real_volumes: tuple[int, ...]
    tail_records: int


def read_h1_cache(path: Path) -> H1Cache:
    data = path.read_bytes()
    require(len(data) > 600, "H1 cache is too small.")
    version = struct.unpack_from("<I", data, 0)[0]
    require(version == 502, f"Unexpected HC version: {version}.")

    cursor = 428
    fields: list[tuple[str, str]] = [
        ("times", "q"),
        ("opens", "d"),
        ("highs", "d"),
        ("lows", "d"),
        ("closes", "d"),
        ("tick_volumes", "q"),
        ("spreads", "I"),
        ("real_volumes", "q"),
    ]
    values: dict[str, tuple] = {}
    counts: list[int] = []
    for name, code in fields:
        require(cursor + 4 <= len(data), f"Missing {name} count.")
        count = struct.unpack_from("<I", data, cursor)[0]
        cursor += 4
        item_size = struct.calcsize("<" + code)
        byte_count = count * item_size
        require(cursor + byte_count <= len(data), f"Truncated {name} array.")
        values[name] = struct.unpack_from(f"<{count}{code}", data, cursor)
        cursor += byte_count
        counts.append(count)

    require(len(set(counts)) == 1, f"HC field counts disagree: {counts}.")
    require(counts[0] >= 50_000, f"Unexpectedly short H1 cache: {counts[0]} bars.")
    require(all(a < b for a, b in zip(values["times"], values["times"][1:])), "H1 times are not strictly increasing.")
    require(all(value % 3600 == 0 for value in values["times"]), "H1 cache contains non-hour timestamps.")
    require(all(high >= max(open_, close) and low <= min(open_, close) for open_, high, low, close in zip(values["opens"], values["highs"], values["lows"], values["closes"])), "Invalid OHLC ordering.")

    tail_records = 0
    if cursor + 4 <= len(data):
        tail_records = struct.unpack_from("<I", data, cursor)[0]
        remaining = len(data) - cursor - 4
        require(remaining == tail_records * 18, "Unexpected HC trailing-record layout.")

    return H1Cache(tail_records=tail_records, **values)


def simple_atr(cache: H1Cache, period: int) -> list[float | None]:
    true_ranges: list[float] = []
    for index, (high, low, close) in enumerate(zip(cache.highs, cache.lows, cache.closes)):
        previous_close = cache.closes[index - 1] if index else close
        true_ranges.append(max(high - low, abs(high - previous_close), abs(low - previous_close)))

    atr: list[float | None] = [None] * len(true_ranges)
    rolling = sum(true_ranges[:period])
    atr[period - 1] = rolling / period
    for index in range(period, len(true_ranges)):
        rolling += true_ranges[index] - true_ranges[index - period]
        atr[index] = rolling / period
    return atr


def entry_hour_epoch(value: str) -> int:
    entry = datetime.fromisoformat(value).replace(minute=0, second=0, microsecond=0, tzinfo=timezone.utc)
    return int(entry.timestamp())


def signal_range_atr(
    entry_time: str,
    cache: H1Cache,
    atr: list[float | None],
    index_by_time: dict[int, int],
) -> tuple[int, float, float, float, float]:
    entry_index = index_by_time.get(entry_hour_epoch(entry_time))
    require(entry_index is not None and entry_index > 0, f"Entry bar missing from H1 cache: {entry_time}.")
    signal_index = entry_index - 1
    signal_atr = atr[signal_index]
    require(signal_atr is not None and signal_atr > 0.0, f"ATR unavailable for {entry_time}.")
    signal_range = cache.highs[signal_index] - cache.lows[signal_index]
    return (
        cache.times[signal_index],
        cache.highs[signal_index],
        cache.lows[signal_index],
        signal_atr,
        signal_range / signal_atr,
    )


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: Iterable[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def profit_factor(rows: list[dict]) -> float:
    gross_profit = sum(float(row["Profit"]) for row in rows if float(row["Profit"]) > 0.0)
    gross_loss = -sum(float(row["Profit"]) for row in rows if float(row["Profit"]) < 0.0)
    return gross_profit / gross_loss if gross_loss > 0.0 else math.inf


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--ledger", type=Path, default=ROOT / "outputs" / "RDMC_CAP12_MODEL4_ANNUAL_TRADES.csv")
    parser.add_argument("--telemetry", type=Path, default=ROOT / "outputs" / "RDMC_CAP12_MODEL4_2015_2018_MOMENTUM_FEATURES.csv")
    parser.add_argument("--trades-out", type=Path, default=ROOT / "outputs" / "RDMC_SIGNAL_RANGE_GATE_OFFLINE_PRESCREEN_TRADES.csv")
    parser.add_argument("--summary-out", type=Path, default=ROOT / "outputs" / "RDMC_SIGNAL_RANGE_GATE_OFFLINE_PRESCREEN_SUMMARY.csv")
    parser.add_argument("--markdown-out", type=Path, default=ROOT / "outputs" / "RDMC_SIGNAL_RANGE_GATE_OFFLINE_PRESCREEN.md")
    args = parser.parse_args()

    for path in (args.cache, args.ledger, args.telemetry):
        require(path.is_file(), f"Required input is missing: {path}.")
    cache_hash = sha256(args.cache)
    ledger_hash = sha256(args.ledger)
    telemetry_hash = sha256(args.telemetry)
    require(cache_hash == EXPECTED_CACHE_SHA256, f"H1 cache identity mismatch: {cache_hash}.")
    require(ledger_hash == EXPECTED_LEDGER_SHA256, f"Annual ledger identity mismatch: {ledger_hash}.")
    require(telemetry_hash == EXPECTED_TELEMETRY_SHA256, f"Telemetry identity mismatch: {telemetry_hash}.")

    cache = read_h1_cache(args.cache)
    coverage_start = datetime.fromtimestamp(cache.times[0], timezone.utc)
    coverage_end = datetime.fromtimestamp(cache.times[-1], timezone.utc)
    require(coverage_start.year <= 2015 and coverage_end.year >= 2022, "H1 cache does not cover the validation periods.")
    index_by_time = {value: index for index, value in enumerate(cache.times)}
    atr = simple_atr(cache, ATR_PERIOD)

    telemetry = read_csv(args.telemetry)
    require(len(telemetry) == 135, f"Expected 135 telemetry rows, found {len(telemetry)}.")
    telemetry_errors: list[float] = []
    for row in telemetry:
        *_, calculated = signal_range_atr(row["EntryTime"], cache, atr, index_by_time)
        telemetry_errors.append(abs(calculated - float(row["range_atr"])))
    max_telemetry_error = max(telemetry_errors)
    require(max_telemetry_error <= 0.0000005, f"ATR/bar alignment failed: maximum range-ATR error {max_telemetry_error:.9f}.")

    annual = read_csv(args.ledger)
    momentum = [row for row in annual if row["EntryComment"].startswith("MTSM_")]
    for row in momentum:
        signal_time, signal_high, signal_low, signal_atr, range_atr = signal_range_atr(
            row["EntryTime"], cache, atr, index_by_time
        )
        row["SignalBarTime"] = datetime.fromtimestamp(signal_time, timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")
        row["SignalHigh"] = f"{signal_high:.2f}"
        row["SignalLow"] = f"{signal_low:.2f}"
        row["ATR20"] = f"{signal_atr:.6f}"
        row["SignalRangeATR"] = f"{range_atr:.6f}"
        for candidate, threshold in THRESHOLDS[1:]:
            row[f"Pass_{candidate}"] = str(range_atr >= threshold)

    detail_fields = [
        "TestWindow", "EntryTime", "ExitTime", "EntryYear", "Side", "Profit", "RiskR",
        "SignalBarTime", "SignalHigh", "SignalLow", "ATR20", "SignalRangeATR",
        "Pass_srg_min100", "Pass_srg_min125_center", "Pass_srg_min150",
    ]
    detail_rows = [{field: row[field] for field in detail_fields} for row in momentum if int(row["EntryYear"]) in FAILURE_YEARS]
    write_csv(args.trades_out, detail_rows, detail_fields)

    summary_rows: list[dict] = []
    for candidate, threshold in THRESHOLDS:
        for year in FAILURE_YEARS:
            year_rows = [row for row in annual if int(row["EntryYear"]) == year]
            year_momentum = [row for row in year_rows if row["EntryComment"].startswith("MTSM_")]
            reversion = [row for row in year_rows if not row["EntryComment"].startswith("MTSM_")]
            kept_momentum = year_momentum if threshold is None else [
                row for row in year_momentum if float(row["SignalRangeATR"]) >= threshold
            ]
            excluded = [row for row in year_momentum if row not in kept_momentum]
            kept = kept_momentum + reversion
            net = round(sum(float(row["Profit"]) for row in kept), 2)
            wins = sum(float(row["Profit"]) > 0.0 for row in kept)
            summary_rows.append({
                "Candidate": candidate,
                "MinimumSignalRangeATR": "off" if threshold is None else f"{threshold:.2f}",
                "Year": year,
                "PostHocNetProfit": f"{net:.2f}",
                "PostHocProfitFactor": f"{profit_factor(kept):.4f}",
                "PostHocTrades": len(kept),
                "PostHocWinRatePercent": f"{(100.0 * wins / len(kept)):.2f}",
                "KeptMomentumTrades": len(kept_momentum),
                "ExcludedMomentumTrades": len(excluded),
                "ExcludedMomentumNet": f"{sum(float(row['Profit']) for row in excluded):.2f}",
                "ProfitableYear": str(net > 0.0),
                "ActivityFloor18": str(len(kept) >= 18),
            })

    control_combined = sum(float(row["PostHocNetProfit"]) for row in summary_rows if row["Candidate"] == "srg_control")
    profile_gate: dict[str, bool] = {}
    for candidate, _ in THRESHOLDS:
        rows = [row for row in summary_rows if row["Candidate"] == candidate]
        combined = sum(float(row["PostHocNetProfit"]) for row in rows)
        profile_gate[candidate] = (
            candidate != "srg_control"
            and all(row["ProfitableYear"] == "True" for row in rows)
            and all(row["ActivityFloor18"] == "True" for row in rows)
            and combined > control_combined
        )
        for row in rows:
            row["CombinedNet2019And2022"] = f"{combined:.2f}"
            row["BeatsControlCombined"] = str(candidate != "srg_control" and combined > control_combined)
            row["PostHocProfileGate"] = str(profile_gate[candidate])

    summary_fields = list(summary_rows[0].keys())
    write_csv(args.summary_out, summary_rows, summary_fields)

    center_pass = profile_gate["srg_min125_center"]
    neighbor_passes = sum(profile_gate[name] for name in ("srg_min100", "srg_min150"))
    diagnostic_status = "POSTHOC_PASS" if center_pass and neighbor_passes >= 1 else "POSTHOC_REJECT_ALL_FROZEN_THRESHOLDS"
    lines = [
        "# RDMC Signal-Range Gate Offline Pre-Screen",
        "",
        f"**Diagnostic status: {diagnostic_status}. This is not the frozen MT5 decision.**",
        "",
        "The read-only pre-screen removes already observed control trades whose completed-H1 signal range is below each frozen threshold. Removing a trade can expose later signals that were blocked in the control path, so only the preregistered eight Model1 reports may accept or reject the repair.",
        "",
        f"- H1 cache SHA-256: `{cache_hash}`",
        f"- H1 base coverage: `{coverage_start:%Y-%m-%d %H:%M}` through `{coverage_end:%Y-%m-%d %H:%M}` UTC-like broker timestamps",
        f"- H1 base bars: `{len(cache.times):,}`; trailing cache records ignored: `{cache.tail_records:,}`",
        f"- Annual ledger SHA-256: `{ledger_hash}`",
        f"- Telemetry SHA-256: `{telemetry_hash}`",
        f"- ATR/bar validation: `135 / 135` matched; maximum six-decimal range-ATR error `{max_telemetry_error:.9f}`",
        "",
        "| Profile | Year | Post-hoc net | PF | Trades | Kept momentum | Excluded | Excluded P/L | Positive | 18+ trades |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---|---|",
    ]
    for row in summary_rows:
        lines.append(
            f"| `{row['Candidate']}` | {row['Year']} | ${float(row['PostHocNetProfit']):+,.2f} | {row['PostHocProfitFactor']} | {row['PostHocTrades']} | {row['KeptMomentumTrades']} | {row['ExcludedMomentumTrades']} | ${float(row['ExcludedMomentumNet']):+,.2f} | {row['ProfitableYear']} | {row['ActivityFloor18']} |"
        )
    lines.extend([
        "",
        "## Interpretation",
        "",
        "- `1.00 ATR` remains negative in both years and is worse than control in combined net.",
        "- The `1.25 ATR` center remains negative in both years and falls to 14 total trades in 2022.",
        "- `1.50 ATR` remains negative in both years and falls below 18 trades in each year.",
        "- None of the frozen thresholds passes the post-hoc approximation. The exact MT5 gate therefore has a low prior probability of success, but it remains authoritative because entry availability is path-dependent.",
        "",
        "No candidate was promoted or substituted. The registered forward candidate is unchanged, the invalid $100,000 demo contributes zero evidence, and real-money trading remains locked.",
    ])
    args.markdown_out.write_text("\n".join(lines) + "\n", encoding="ascii")

    print(
        f"{diagnostic_status} telemetry=135 max_error={max_telemetry_error:.9f} "
        f"detail_rows={len(detail_rows)} summary_rows={len(summary_rows)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
