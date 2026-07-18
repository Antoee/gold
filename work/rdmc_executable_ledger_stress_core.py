#!/usr/bin/env python3
"""Identity-bound MT5 ledger parsing and deterministic stress primitives."""

from __future__ import annotations

import hashlib
import json
import math
import random
import re
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from html.parser import HTMLParser
from pathlib import Path
from statistics import median
from typing import Iterable


INITIAL_BALANCE = 10_000.0
CONTRACT_SIZE = 100.0
ERA_YEARS = {
    "Older2015To2018": range(2015, 2019),
    "Middle2019To2022": range(2019, 2023),
    "Recent2023To2026": range(2023, 2027),
}
COST_SCENARIOS = (
    ("base", 0.00),
    ("light", 0.02),
    ("moderate", 0.05),
    ("severe", 0.10),
)
MC_STRESS = (
    {
        "name": "standard",
        "max_slippage_r": 0.04,
        "max_delay_r": 0.06,
        "max_spread_shock_r": 0.08,
        "spread_shock_probability": 0.10,
        "missed_winner_probability": 0.05,
        "min_p05_net": 0.0,
        "min_median_pf": 1.25,
        "max_p95_dd_percent": 6.0,
        "max_red_trial_percent": 5.0,
        "max_p95_loss_run": 14.0,
    },
    {
        "name": "severe",
        "max_slippage_r": 0.08,
        "max_delay_r": 0.12,
        "max_spread_shock_r": 0.16,
        "spread_shock_probability": 0.20,
        "missed_winner_probability": 0.10,
        "min_p05_net": 0.0,
        "min_median_pf": 1.10,
        "max_p95_dd_percent": 8.0,
        "max_red_trial_percent": 5.0,
        "max_p95_loss_run": 16.0,
    },
)
MC_SAMPLERS = (
    ("moving_block_08", "moving_block", 8),
    ("moving_block_16", "moving_block", 16),
    ("moving_block_24", "moving_block", 24),
    ("calendar_year", "calendar_year", 0),
)


@dataclass(frozen=True)
class Trade:
    index: int
    entry_time: datetime
    exit_time: datetime
    entry_deal: str
    exit_deal: str
    entry_order: str
    exit_order: str
    symbol: str
    side: str
    volume: float
    entry_price: float
    exit_price: float
    initial_stop: float
    initial_target: float
    initial_risk: float
    gross_profit: float
    commission: float
    fee: float
    swap: float
    profit: float
    entry_comment: str
    exit_comment: str

    @property
    def risk_r(self) -> float:
        return self.profit / self.initial_risk

    @property
    def hold_minutes(self) -> float:
        return (self.exit_time - self.entry_time).total_seconds() / 60.0


class ReportRowsParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.rows: list[list[str]] = []
        self._row: list[str] | None = None
        self._cell: list[str] | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        del attrs
        if tag.lower() == "tr":
            self._row = []
        elif tag.lower() in {"td", "th"} and self._row is not None:
            self._cell = []

    def handle_data(self, data: str) -> None:
        if self._cell is not None:
            self._cell.append(data)

    def handle_endtag(self, tag: str) -> None:
        lower = tag.lower()
        if lower in {"td", "th"} and self._cell is not None and self._row is not None:
            self._row.append(" ".join("".join(self._cell).split()))
            self._cell = None
        elif lower == "tr" and self._row is not None:
            if self._row:
                self.rows.append(self._row)
            self._row = None
            self._cell = None


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def validated_sha256(value: object, label: str) -> str:
    normalized = str(value).upper()
    require(bool(re.fullmatch(r"[A-F0-9]{64}", normalized)), f"{label} SHA-256 is invalid")
    return normalized


def decode_report(path: Path) -> str:
    raw = path.read_bytes()
    encodings = ["utf-8-sig", "utf-8", "cp1252"]
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        encodings.insert(0, "utf-16")
    for encoding in encodings:
        try:
            return raw.decode(encoding)
        except UnicodeDecodeError:
            continue
    raise ValueError(f"Could not decode MT5 report: {path}")


def normalize_header(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def report_number(value: str, *, blank: float = 0.0) -> float:
    text = value.replace("\u00a0", "").replace("\u202f", "").replace(" ", "").replace(",", "")
    if not text:
        return blank
    try:
        parsed = float(text)
    except ValueError as exc:
        raise ValueError(f"Could not parse report number: {value!r}") from exc
    require(math.isfinite(parsed), f"Non-finite report number: {value!r}")
    return parsed


def report_time(value: str) -> datetime:
    try:
        return datetime.strptime(value.strip(), "%Y.%m.%d %H:%M:%S")
    except ValueError as exc:
        raise ValueError(f"Could not parse report timestamp: {value!r}") from exc


def find_header(rows: list[list[str]], required: set[str]) -> int:
    for index, row in enumerate(rows):
        if required.issubset({normalize_header(cell) for cell in row}):
            return index
    raise ValueError(f"MT5 report table header is missing: {sorted(required)}")


def mapped_rows(rows: list[list[str]], header_index: int, stop_index: int | None = None) -> list[dict[str, str]]:
    headers = [normalize_header(cell) for cell in rows[header_index]]
    require(len(headers) == len(set(headers)), "MT5 table header contains duplicate normalized columns")
    output: list[dict[str, str]] = []
    for row in rows[header_index + 1 : stop_index]:
        if len(row) < len(headers):
            continue
        output.append(dict(zip(headers, row[: len(headers)])))
    return output


def summary_metrics(rows: list[list[str]]) -> dict[str, float]:
    wanted = {
        "totalnetprofit": "NetProfit",
        "profitfactor": "ProfitFactor",
        "totaltrades": "TotalTrades",
    }
    metrics: dict[str, float] = {}
    for row in rows:
        for index, cell in enumerate(row[:-1]):
            key = normalize_header(cell.rstrip(":"))
            if key in wanted:
                metrics[wanted[key]] = report_number(row[index + 1])
    require(set(metrics) == set(wanted.values()), "Required MT5 summary metrics are missing")
    return metrics


def parse_mt5_report(path: Path, contract_size: float = CONTRACT_SIZE) -> tuple[list[Trade], dict[str, float]]:
    require(path.is_file(), f"MT5 report is missing: {path}")
    require(contract_size > 0.0, "Contract size must be positive")
    parser = ReportRowsParser()
    parser.feed(decode_report(path))
    rows = parser.rows
    order_header = find_header(rows, {"opentime", "order", "symbol", "type", "volume", "sl", "state"})
    deal_header = find_header(rows, {"time", "deal", "symbol", "type", "direction", "volume", "profit", "balance"})
    require(order_header < deal_header, "Orders table must precede deals table")
    orders = mapped_rows(rows, order_header, deal_header)
    deals = mapped_rows(rows, deal_header)

    order_map: dict[str, dict[str, str]] = {}
    for order in orders:
        order_id = order.get("order", "").strip()
        if order_id:
            require(order_id not in order_map, f"Duplicate order ID in MT5 report: {order_id}")
            order_map[order_id] = order

    trades: list[Trade] = []
    opened: dict[str, object] | None = None
    seen_deal_ids: set[str] = set()
    for deal in deals:
        direction = deal.get("direction", "").strip().lower()
        side = deal.get("type", "").strip().lower()
        symbol = deal.get("symbol", "").strip()
        if direction not in {"in", "out", "in/out"} or side not in {"buy", "sell"}:
            continue
        require(direction != "in/out", "Reversal in/out deal is unsupported by the frozen one-position profile")
        require(symbol == "XAUUSD", f"Unexpected symbol in executable ledger: {symbol}")
        deal_id = deal.get("deal", "").strip()
        require(bool(deal_id), "Executable entry or exit deal ID is missing")
        require(deal_id not in seen_deal_ids, f"Duplicate deal ID in MT5 report: {deal_id}")
        seen_deal_ids.add(deal_id)
        timestamp = report_time(deal["time"])
        volume = report_number(deal["volume"])
        price = report_number(deal["price"])
        require(volume > 0.0 and price > 0.0, "Deal volume and price must be positive")
        commission = report_number(deal.get("commission", ""))
        fee = report_number(deal.get("fee", ""))
        swap = report_number(deal.get("swap", ""))

        if direction == "in":
            require(opened is None, "Overlapping entries violate the frozen one-position profile")
            order_id = deal.get("order", "").strip()
            require(order_id in order_map, f"Entry deal lacks its exact order row: {order_id}")
            order = order_map[order_id]
            require(order.get("type", "").strip().lower() == side, "Entry order side differs from entry deal")
            require(order.get("symbol", "").strip() == symbol, "Entry order symbol differs from entry deal")
            require(order.get("state", "").strip().lower() == "filled", "Entry order is not filled")
            require(report_time(order["opentime"]) <= timestamp, "Entry order opens after its deal")
            order_volume = report_number(order.get("volume", "").split("/")[0])
            require(abs(order_volume - volume) <= 1e-8, "Entry order/deal volume mismatch")
            stop = report_number(order.get("sl", ""))
            target = report_number(order.get("tp", ""))
            require(stop > 0.0, "Every executable trade must retain its initial stop in the order table")
            require((side == "buy" and stop < price) or (side == "sell" and stop > price), "Initial stop is on the wrong side")
            risk = abs(price - stop) * volume * contract_size
            require(risk > 0.0, "Initial risk must be positive")
            opened = {
                "time": timestamp,
                "deal": deal_id,
                "order": order_id,
                "symbol": symbol,
                "side": side,
                "volume": volume,
                "price": price,
                "stop": stop,
                "target": target,
                "risk": risk,
                "commission": commission,
                "fee": fee,
                "swap": swap,
                "comment": deal.get("comment", ""),
            }
            continue

        require(opened is not None, "Exit deal has no open executable trade")
        require(timestamp >= opened["time"], "Exit precedes entry")
        require(symbol == opened["symbol"], "Exit symbol differs from entry")
        require(side != opened["side"], "Exit deal side does not close the entry side")
        require(abs(volume - float(opened["volume"])) <= 1e-8, "Partial or oversized exits are unsupported")
        exit_order_id = deal.get("order", "").strip()
        require(exit_order_id in order_map, f"Exit deal lacks its exact order row: {exit_order_id}")
        exit_order = order_map[exit_order_id]
        require(exit_order.get("type", "").strip().lower() == side, "Exit order side differs from exit deal")
        require(exit_order.get("symbol", "").strip() == symbol, "Exit order symbol differs from exit deal")
        require(exit_order.get("state", "").strip().lower() == "filled", "Exit order is not filled")
        require(report_time(exit_order["opentime"]) <= timestamp, "Exit order opens after its deal")
        exit_order_volume = report_number(exit_order.get("volume", "").split("/")[0])
        require(abs(exit_order_volume - volume) <= 1e-8, "Exit order/deal volume mismatch")
        gross = report_number(deal.get("profit", ""))
        direction_multiplier = 1.0 if opened["side"] == "buy" else -1.0
        price_gross = (price - float(opened["price"])) * volume * contract_size * direction_multiplier
        require(abs(price_gross - gross) <= 0.02, "Deal gross profit differs from its price path")
        total_commission = float(opened["commission"]) + commission
        total_fee = float(opened["fee"]) + fee
        total_swap = float(opened["swap"]) + swap
        net = gross + total_commission + total_fee + total_swap
        trades.append(
            Trade(
                index=len(trades) + 1,
                entry_time=opened["time"],
                exit_time=timestamp,
                entry_deal=str(opened["deal"]),
                exit_deal=deal_id,
                entry_order=str(opened["order"]),
                exit_order=exit_order_id,
                symbol=symbol,
                side=str(opened["side"]),
                volume=float(opened["volume"]),
                entry_price=float(opened["price"]),
                exit_price=price,
                initial_stop=float(opened["stop"]),
                initial_target=float(opened["target"]),
                initial_risk=float(opened["risk"]),
                gross_profit=gross,
                commission=total_commission,
                fee=total_fee,
                swap=total_swap,
                profit=net,
                entry_comment=str(opened["comment"]),
                exit_comment=deal.get("comment", ""),
            )
        )
        opened = None

    require(opened is None, "MT5 report ends with an open trade")
    require(bool(trades), "No closed executable trades were parsed")
    metrics = summary_metrics(rows)
    require(int(metrics["TotalTrades"]) == len(trades), "Parsed trade count differs from MT5 Total Trades")
    require(abs(sum(trade.profit for trade in trades) - metrics["NetProfit"]) <= 0.02, "Parsed ledger net differs from MT5 Total Net Profit")
    return trades, metrics


def validate_report_identity(
    report: Path,
    identity_path: Path,
    expected_name: str,
    config_sha256: str,
    source_sha256: str,
    binary_sha256: str | None = None,
) -> dict[str, object]:
    require(report.is_file() and identity_path.is_file(), "Report or identity sidecar is missing")
    identity = json.loads(identity_path.read_text(encoding="ascii"))
    required = {
        "SchemaVersion",
        "ExpectedReportName",
        "ConfigSha256",
        "SourceSha256",
        "PortableBinarySha256",
        "ReportSha256",
        "ReportBytes",
        "CreatedUtc",
    }
    require(required.issubset(identity), "Report identity sidecar is incomplete")
    require(int(identity["SchemaVersion"]) == 1, "Unsupported report identity schema")
    require(report.stem == expected_name == str(identity["ExpectedReportName"]), "Report name identity mismatch")
    expected_config = validated_sha256(config_sha256, "Expected config")
    expected_source = validated_sha256(source_sha256, "Expected source")
    require(validated_sha256(identity["ConfigSha256"], "Report config") == expected_config, "Report config identity mismatch")
    require(validated_sha256(identity["SourceSha256"], "Report source") == expected_source, "Report source identity mismatch")
    portable_binary = validated_sha256(identity["PortableBinarySha256"], "Report binary")
    if binary_sha256 is not None:
        require(portable_binary == validated_sha256(binary_sha256, "Expected binary"), "Report binary identity mismatch")
    require(validated_sha256(identity["ReportSha256"], "Report") == sha256(report), "Report hash identity mismatch")
    require(int(identity["ReportBytes"]) == report.stat().st_size > 0, "Report byte identity mismatch")
    created_text = str(identity["CreatedUtc"]).strip()
    if created_text.endswith("Z"):
        created_text = created_text[:-1] + "+00:00"
    try:
        created_utc = datetime.fromisoformat(created_text)
    except ValueError as exc:
        raise ValueError("Report identity CreatedUtc is invalid") from exc
    require(created_utc.tzinfo is not None, "Report identity CreatedUtc lacks a UTC offset")
    require(created_utc.utcoffset() is not None and created_utc.utcoffset().total_seconds() == 0.0, "Report identity CreatedUtc is not UTC")
    require(expected_source in decode_report(report).upper(), "Report does not embed the frozen source identity")
    return identity


def percentile(values: list[float], percent: float) -> float:
    require(bool(values), "Percentile requires values")
    ordered = sorted(values)
    rank = percent / 100.0 * (len(ordered) - 1)
    lower = math.floor(rank)
    upper = math.ceil(rank)
    if lower == upper:
        return ordered[lower]
    weight = rank - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def path_metrics(values: Iterable[float], initial_balance: float = INITIAL_BALANCE) -> dict[str, float | int]:
    equity = initial_balance
    peak = initial_balance
    maximum_dd = 0.0
    maximum_dd_percent = 0.0
    gross_profit = 0.0
    gross_loss = 0.0
    current_loss_run = 0
    maximum_loss_run = 0
    net = 0.0
    for value in values:
        net += value
        equity += value
        peak = max(peak, equity)
        maximum_dd = max(maximum_dd, peak - equity)
        maximum_dd_percent = max(maximum_dd_percent, 100.0 * (peak - equity) / peak)
        if value > 0.0:
            gross_profit += value
            current_loss_run = 0
        elif value < 0.0:
            gross_loss -= value
            current_loss_run += 1
            maximum_loss_run = max(maximum_loss_run, current_loss_run)
        else:
            current_loss_run = 0
    return {
        "NetProfit": net,
        "ProfitFactor": gross_profit / gross_loss if gross_loss else float("inf"),
        "MaxClosedDrawdownMoney": maximum_dd,
        "MaxClosedDrawdownPercent": maximum_dd_percent,
        "MaxConsecutiveLosses": maximum_loss_run,
    }


def cost_stress(trades: list[Trade]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for name, added_cost_r in COST_SCENARIOS:
        adjusted = [(trade, trade.profit - added_cost_r * trade.initial_risk) for trade in trades]
        metrics = path_metrics(value for _, value in adjusted)
        era_net = {
            era: sum(value for trade, value in adjusted if trade.exit_time.year in years)
            for era, years in ERA_YEARS.items()
        }
        all_eras_positive = all(value > 0.0 for value in era_net.values())
        net = float(metrics["NetProfit"])
        pf = float(metrics["ProfitFactor"])
        dd = float(metrics["MaxClosedDrawdownPercent"])
        if name == "base":
            gate = net > 0.0 and all_eras_positive
        elif name == "light":
            gate = net > 0.0 and all_eras_positive
        elif name == "moderate":
            gate = net > 0.0 and pf >= 1.20 and dd <= 6.0 and all_eras_positive
        else:
            gate = net > 0.0 and pf >= 1.10 and dd <= 8.0 and all_eras_positive
        rows.append(
            {
                "Scenario": name,
                "AddedCostRPerTrade": added_cost_r,
                "Trades": len(trades),
                "ExtraCost": round(sum(added_cost_r * trade.initial_risk for trade in trades), 2),
                "NetProfit": round(net, 2),
                "ProfitFactor": round(pf, 4),
                "MaxClosedDrawdownPercent": round(dd, 4),
                **{key: round(value, 2) for key, value in era_net.items()},
                "AllBroadErasPositive": all_eras_positive,
                "GatePass": gate,
            }
        )
    return rows


def moving_block_sample(trades: list[Trade], block_length: int, rng: random.Random) -> list[Trade]:
    sampled: list[Trade] = []
    while len(sampled) < len(trades):
        start = rng.randrange(len(trades))
        for offset in range(block_length):
            sampled.append(trades[(start + offset) % len(trades)])
            if len(sampled) == len(trades):
                break
    return sampled


def calendar_year_sample(trades: list[Trade], rng: random.Random) -> list[Trade]:
    by_year: dict[int, list[Trade]] = defaultdict(list)
    for trade in trades:
        by_year[trade.exit_time.year].append(trade)
    years = sorted(by_year)
    require(len(years) >= 3, "Calendar-year stress requires at least three represented years")
    sampled: list[Trade] = []
    for _ in years:
        sampled.extend(by_year[years[rng.randrange(len(years))]])
    return sampled


def stressed_values(trades: list[Trade], rng: random.Random, scenario: dict[str, object]) -> list[float]:
    values: list[float] = []
    for trade in trades:
        if trade.profit > 0.0 and rng.random() < float(scenario["missed_winner_probability"]):
            continue
        stress_r = rng.random() * float(scenario["max_slippage_r"])
        stress_r += rng.random() * float(scenario["max_delay_r"])
        if rng.random() < float(scenario["spread_shock_probability"]):
            stress_r += rng.random() * float(scenario["max_spread_shock_r"])
        values.append(trade.profit - stress_r * trade.initial_risk)
    return values


def monte_carlo_stress(trades: list[Trade], trials: int = 10_000) -> list[dict[str, object]]:
    require(trials >= 100, "Monte Carlo requires at least 100 trials")
    rows: list[dict[str, object]] = []
    for sampler_index, (sampler_name, sampler_kind, block_length) in enumerate(MC_SAMPLERS):
        for stress_index, scenario in enumerate(MC_STRESS):
            seed = 26071840 + sampler_index * 2 + stress_index
            rng = random.Random(seed)
            nets: list[float] = []
            pfs: list[float] = []
            drawdowns: list[float] = []
            loss_runs: list[float] = []
            trade_counts: list[float] = []
            for _ in range(trials):
                if sampler_kind == "moving_block":
                    sampled = moving_block_sample(trades, block_length, rng)
                else:
                    sampled = calendar_year_sample(trades, rng)
                values = stressed_values(sampled, rng, scenario)
                metrics = path_metrics(values)
                nets.append(float(metrics["NetProfit"]))
                pfs.append(float(metrics["ProfitFactor"]))
                drawdowns.append(float(metrics["MaxClosedDrawdownPercent"]))
                loss_runs.append(float(metrics["MaxConsecutiveLosses"]))
                trade_counts.append(float(len(values)))
            p05_net = percentile(nets, 5.0)
            median_pf = median(pfs)
            p95_dd = percentile(drawdowns, 95.0)
            p95_loss_run = percentile(loss_runs, 95.0)
            red_percent = 100.0 * sum(value < 0.0 for value in nets) / len(nets)
            gate = (
                p05_net > float(scenario["min_p05_net"])
                and median_pf >= float(scenario["min_median_pf"])
                and p95_dd <= float(scenario["max_p95_dd_percent"])
                and red_percent <= float(scenario["max_red_trial_percent"])
                and p95_loss_run <= float(scenario["max_p95_loss_run"])
            )
            rows.append(
                {
                    "Sampler": sampler_name,
                    "StressScenario": scenario["name"],
                    "Trials": trials,
                    "Seed": seed,
                    "BlockLength": block_length,
                    "PreservesLocalOrder": True,
                    "P05TradeCount": round(percentile(trade_counts, 5.0), 2),
                    "MedianTradeCount": round(median(trade_counts), 2),
                    "P95TradeCount": round(percentile(trade_counts, 95.0), 2),
                    "P05NetProfit": round(p05_net, 2),
                    "MedianNetProfit": round(median(nets), 2),
                    "MedianProfitFactor": round(median_pf, 4),
                    "P95MaxClosedDrawdownPercent": round(p95_dd, 4),
                    "P95MaxConsecutiveLosses": round(p95_loss_run, 2),
                    "RedTrialPercent": round(red_percent, 3),
                    "GatePass": gate,
                }
            )
    return rows
