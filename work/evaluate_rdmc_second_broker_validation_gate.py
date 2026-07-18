#!/usr/bin/env python3
"""Evaluate the preregistered distinct-broker Model4 gate without launching MT5."""

from __future__ import annotations

import csv
import hashlib
import math
import re
from datetime import datetime
from pathlib import Path

from rdmc_executable_ledger_stress_core import (
    ReportRowsParser,
    decode_report,
    normalize_header,
    report_number,
    validate_report_identity,
)


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "outputs" / "RDMC_SECOND_BROKER_VALIDATION_MANIFEST.csv"
SPECIFICATION = ROOT / "outputs" / "RDMC_SECOND_BROKER_SPECIFICATION.csv"
RESULTS = ROOT / "outputs" / "RDMC_SECOND_BROKER_VALIDATION_RESULTS.csv"
PRIMARY_GATE_DECISION = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_DECISION.csv"
PRIMARY_RESULTS = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_RESULTS.csv"
LEDGER_DECISION = ROOT / "outputs" / "RDMC_EXECUTABLE_LEDGER_STRESS_DECISION.csv"
EVALUATION_CSV = ROOT / "outputs" / "RDMC_SECOND_BROKER_VALIDATION_EVALUATION.csv"
DECISION_CSV = ROOT / "outputs" / "RDMC_SECOND_BROKER_VALIDATION_DECISION.csv"
DECISION_MD = ROOT / "outputs" / "RDMC_SECOND_BROKER_VALIDATION_DECISION.md"
REPORT_ROOT = ROOT / "outputs" / "rdmc_second_broker_validation_package" / "reports_here"
REPO_LOCK = ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock"
OUTER_LOCK = ROOT.parent / "MT5_LOCAL_LAUNCH_DISABLED.lock"

EXPECTED_MANIFEST_SHA256 = "5334471DE730CA25B1028B85BCC7DACF0FC5C23BCDDB8541AED75EC320DDEC04"
EXPECTED_SOURCE_SHA256 = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
EXPECTED_PROFILE_SHA256 = "746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883"
PRIMARY_COMPANY_FINGERPRINT = "C9D9B521F3325D6CE4996576CD61C7AA3E860A08B84DC47540C2B30E98924092"
EXPECTED_WAVE_COUNTS = {1: 2, 2: 4, 3: 12}
ANNUAL_RATIO_RANGE = (0.75, 1.25)
SECONDARY_PRIMARY_NET_RATIO_RANGE = (0.50, 1.50)
SECONDARY_PRIMARY_TRADE_RATIO_RANGE = (0.70, 1.30)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def valid_sha256(value: str) -> bool:
    return bool(re.fullmatch(r"[A-Fa-f0-9]{64}", value.strip()))


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    require(bool(rows), f"No rows for {path.name}")
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def write_markdown(path: Path, lines: list[str]) -> None:
    with path.open("w", encoding="ascii", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


def number(row: dict[str, str], field: str) -> float | None:
    value = row.get(field, "").strip()
    if not value:
        return None
    try:
        parsed = float(value)
    except ValueError:
        return None
    return parsed if math.isfinite(parsed) else None


def report_value(rows: list[list[str]], label: str) -> str:
    wanted = normalize_header(label)
    for row in rows:
        for index, cell in enumerate(row[:-1]):
            if normalize_header(cell.rstrip(":")) == wanted:
                return row[index + 1]
    raise ValueError(f"MT5 report field is missing: {label}")


def first_number(value: str) -> float:
    match = re.search(r"[-+]?\d[\d\s,]*(?:\.\d+)?", value)
    if not match:
        raise ValueError(f"MT5 report value has no number: {value!r}")
    return report_number(match.group(0))


def first_percent(value: str) -> float:
    match = re.search(r"([-+]?\d+(?:\.\d+)?)\s*%", value)
    if not match:
        raise ValueError(f"MT5 report value has no percentage: {value!r}")
    return float(match.group(1))


def parse_bound_report_metrics(report: Path, manifest_row: dict[str, str]) -> dict[str, object]:
    parser = ReportRowsParser()
    parser.feed(decode_report(report))
    rows = parser.rows
    initial = report_number(report_value(rows, "Initial Deposit"))
    net = report_number(report_value(rows, "Total Net Profit"))
    balance = initial + net
    start = datetime.strptime(manifest_row["From"], "%Y.%m.%d")
    end = datetime.strptime(manifest_row["To"], "%Y.%m.%d")
    years = max((end - start).days / 365.2425, 1.0 / 365.2425)
    cagr = ((balance / initial) ** (1.0 / years) - 1.0) * 100.0 if initial > 0.0 and balance > 0.0 else -100.0
    company = report_value(rows, "Company").strip()
    require(bool(company), "MT5 report company is blank")
    return {
        "InitialDeposit": initial,
        "NetProfit": net,
        "Balance": balance,
        "ProfitFactor": report_number(report_value(rows, "Profit Factor")),
        "ExpectedPayoff": report_number(report_value(rows, "Expected Payoff")),
        "SharpeRatio": report_number(report_value(rows, "Sharpe Ratio")),
        "TotalTrades": int(report_number(report_value(rows, "Total Trades"))),
        "MaxDrawdownPercent": first_percent(report_value(rows, "Equity Drawdown Relative")),
        "RecoveryFactor": report_number(report_value(rows, "Recovery Factor")),
        "WinRatePercent": first_percent(report_value(rows, "Profit Trades (% of total)")),
        "MaxConsecutiveLosses": int(first_number(report_value(rows, "Maximum consecutive losses ($)"))),
        "CagrPercent": cagr,
        "CompanyFingerprintSha256": hashlib.sha256(company.casefold().encode("utf-8")).hexdigest().upper(),
        "AccountCurrency": report_value(rows, "Currency").strip().upper(),
    }


def reject_report_account_identifier(report: Path) -> None:
    parser = ReportRowsParser()
    parser.feed(decode_report(report))
    forbidden = {"account", "accountid", "accountidentifier", "accountnumber", "login"}
    for row in parser.rows:
        for index, cell in enumerate(row[:-1]):
            if normalize_header(cell.rstrip(":")) in forbidden and re.search(r"\d{5,}", row[index + 1]):
                raise ValueError(f"Report contains a prohibited account identifier field: {cell}")


def load_manifest() -> list[dict[str, str]]:
    require(MANIFEST.is_file(), "Second-broker manifest is missing")
    require(sha256(MANIFEST) == EXPECTED_MANIFEST_SHA256, "Second-broker manifest identity changed")
    rows = read_csv(MANIFEST)
    require(len(rows) == 18, "Expected 18 second-broker Model4 rows")
    require([int(row["QueueRank"]) for row in rows] == list(range(1, 19)), "Queue ranks changed")
    require({row["Model"] for row in rows} == {"4"}, "Second-broker gate must use real ticks only")
    require({row["SourceSha256"] for row in rows} == {EXPECTED_SOURCE_SHA256}, "Source identity changed")
    require({row["ProfileSha256"] for row in rows} == {EXPECTED_PROFILE_SHA256}, "Profile identity changed")
    require(
        {row["PrimaryCompanyFingerprintSha256"] for row in rows} == {PRIMARY_COMPANY_FINGERPRINT},
        "Primary broker-family fingerprint changed",
    )
    for wave, count in EXPECTED_WAVE_COUNTS.items():
        require(sum(int(row["Wave"]) == wave for row in rows) == count, f"Wave {wave} shape changed")
    for row in rows:
        config = ROOT / row["PackageConfig"]
        require(config.is_file(), f"Second-broker config is missing: {config.name}")
        require(sha256(config) == row["ConfigSha256"], f"Second-broker config identity changed: {config.name}")
        require(row["Status"] == "PREREQUISITE_LOCKED", "Manifest launch status changed")
    return rows


def validate_specification(rows: list[dict[str, str]]) -> tuple[bool, list[str]]:
    if len(rows) != 1:
        return False, [f"rows={len(rows)}; expected=1"]
    row = rows[0]
    reasons: list[str] = []
    forbidden = {"account", "accountid", "accountidentifier", "accountnumber", "login", "company", "server"}
    leaked = sorted(name for name in row if normalize_header(name) in forbidden and row[name].strip())
    if leaked:
        reasons.append("raw identity fields published: " + ",".join(leaked))
    if row.get("SchemaVersion") != "1":
        reasons.append("SchemaVersion must be 1")
    if row.get("EnvironmentRole", "").upper() != "SECONDARY":
        reasons.append("EnvironmentRole must be SECONDARY")
    company_hash = row.get("CompanyFingerprintSha256", "").upper()
    server_hash = row.get("ServerFingerprintSha256", "").upper()
    if not valid_sha256(company_hash):
        reasons.append("CompanyFingerprintSha256 is invalid")
    elif company_hash == PRIMARY_COMPANY_FINGERPRINT:
        reasons.append("secondary company fingerprint equals primary")
    if not valid_sha256(server_hash):
        reasons.append("ServerFingerprintSha256 is invalid")
    elif server_hash == company_hash:
        reasons.append("server and company fingerprints must differ")
    if row.get("PrimaryCompanyFingerprintSha256", "").upper() != PRIMARY_COMPANY_FINGERPRINT:
        reasons.append("primary company fingerprint mismatch")
    if row.get("Symbol", "").upper() != "XAUUSD":
        reasons.append("Symbol must be XAUUSD")
    if row.get("AccountCurrency", "").upper() != "USD":
        reasons.append("AccountCurrency must be USD")
    if row.get("MarginMode", "").upper() != "HEDGING":
        reasons.append("MarginMode must be HEDGING")
    if row.get("TradeMode", "").upper() != "FULL":
        reasons.append("TradeMode must be FULL")
    if row.get("SourceSha256", "").upper() != EXPECTED_SOURCE_SHA256:
        reasons.append("source identity mismatch")
    if row.get("ProfileSha256", "").upper() != EXPECTED_PROFILE_SHA256:
        reasons.append("profile identity mismatch")
    if row.get("AccountIdentifierPublished", "").lower() != "false":
        reasons.append("AccountIdentifierPublished must be False")

    integer_fields = ("TerminalBuild", "Digits", "StopsLevelPoints", "FreezeLevelPoints")
    positive_fields = (
        "ContractSize",
        "TickSize",
        "TickValueProfit",
        "TickValueLoss",
        "Point",
        "VolumeMin",
        "VolumeMax",
        "VolumeStep",
    )
    for field in integer_fields:
        value = number(row, field)
        if value is None or value < 0.0 or value != int(value):
            reasons.append(f"{field} must be a non-negative integer")
    build = number(row, "TerminalBuild")
    if build is not None and build < 5989:
        reasons.append("TerminalBuild predates the frozen primary runtime")
    digits = number(row, "Digits")
    if digits is not None and not 1 <= digits <= 8:
        reasons.append("Digits must be between 1 and 8")
    for field in positive_fields:
        value = number(row, field)
        if value is None or value <= 0.0:
            reasons.append(f"{field} must be positive")
    volume_min = number(row, "VolumeMin")
    volume_max = number(row, "VolumeMax")
    volume_step = number(row, "VolumeStep")
    if volume_min and volume_max and volume_min > volume_max:
        reasons.append("VolumeMin exceeds VolumeMax")
    if volume_min and volume_step:
        min_steps = volume_min / volume_step
        if min_steps < 1.0 or abs(min_steps - round(min_steps)) > 1e-8:
            reasons.append("VolumeMin is not on the broker volume grid")
    if volume_max and volume_step:
        max_steps = volume_max / volume_step
        if abs(max_steps - round(max_steps)) > 1e-8:
            reasons.append("VolumeMax is not on the broker volume grid")
    tick_size = number(row, "TickSize")
    point = number(row, "Point")
    if tick_size and point and tick_size + 1e-12 < point:
        reasons.append("TickSize is smaller than Point")
    swap_modes = {
        "DISABLED",
        "POINTS",
        "CURRENCY_SYMBOL",
        "CURRENCY_MARGIN",
        "CURRENCY_DEPOSIT",
        "INTEREST_CURRENT",
        "INTEREST_OPEN",
        "REOPEN_CURRENT",
        "REOPEN_BID",
    }
    if row.get("SwapMode", "").upper() not in swap_modes:
        reasons.append("SwapMode is invalid")
    for field in ("SwapLong", "SwapShort"):
        if number(row, field) is None:
            reasons.append(f"{field} must be finite")
    captured = row.get("SpecificationCapturedUtc", "").strip()
    if captured.endswith("Z"):
        captured = captured[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(captured)
        if parsed.tzinfo is None or parsed.utcoffset() is None or parsed.utcoffset().total_seconds() != 0.0:
            reasons.append("SpecificationCapturedUtc must include a UTC offset")
    except ValueError:
        reasons.append("SpecificationCapturedUtc is invalid")
    return not reasons, reasons


def validate_result_identity(
    manifest_row: dict[str, str],
    result: dict[str, str],
    specification_hash: str,
    specification: dict[str, str],
) -> list[str]:
    reasons: list[str] = []
    expected = {
        "ConfigSha256": manifest_row["ConfigSha256"],
        "SourceSha256": EXPECTED_SOURCE_SHA256,
        "ProfileSha256": EXPECTED_PROFILE_SHA256,
        "BrokerSpecificationSha256": specification_hash,
    }
    for field, value in expected.items():
        if result.get(field, "").upper() != value:
            reasons.append(f"{field}=MISMATCH")
    for field in ("ReportSha256", "PortableBinarySha256"):
        if not valid_sha256(result.get(field, "")):
            reasons.append(f"{field}=INVALID")
    report_path = ROOT / result.get("ReportPath", "")
    identity_path = ROOT / result.get("ReportIdentityPath", "")
    expected_identity = REPORT_ROOT / f"{manifest_row['ExpectedReportName']}.identity.json"
    try:
        if not report_path.is_file():
            reasons.append("ReportPath=MISSING")
        elif report_path.resolve().parent != REPORT_ROOT.resolve():
            reasons.append("ReportPath=OUTSIDE_CANONICAL_ROOT")
        if report_path.stem != manifest_row["ExpectedReportName"]:
            reasons.append("ReportPath=NAME_MISMATCH")
        if report_path.suffix.lower() not in {".htm", ".html", ".xml"}:
            reasons.append("ReportPath=UNSUPPORTED_EXTENSION")
        if not identity_path.is_file():
            reasons.append("ReportIdentityPath=MISSING")
        elif identity_path.resolve() != expected_identity.resolve():
            reasons.append("ReportIdentityPath=NONCANONICAL")
    except OSError:
        reasons.append("ReportPath=INVALID")
    if reasons:
        return reasons
    try:
        identity = validate_report_identity(
            report_path,
            identity_path,
            manifest_row["ExpectedReportName"],
            manifest_row["ConfigSha256"],
            EXPECTED_SOURCE_SHA256,
            result["PortableBinarySha256"],
        )
        reject_report_account_identifier(report_path)
        if str(identity["ReportSha256"]).upper() != result["ReportSha256"].upper():
            reasons.append("ReportSha256=MISMATCH")
        metrics = parse_bound_report_metrics(report_path, manifest_row)
        if metrics["CompanyFingerprintSha256"] != specification["CompanyFingerprintSha256"].upper():
            reasons.append("ReportCompanyFingerprint=MISMATCH")
        if metrics["AccountCurrency"] != specification["AccountCurrency"].upper():
            reasons.append("ReportCurrency=MISMATCH")
        tolerances = {
            "InitialDeposit": 0.01,
            "NetProfit": 0.02,
            "Balance": 0.02,
            "ProfitFactor": 0.01,
            "ExpectedPayoff": 0.01,
            "SharpeRatio": 0.01,
            "TotalTrades": 0.0,
            "MaxDrawdownPercent": 0.01,
            "RecoveryFactor": 0.01,
            "WinRatePercent": 0.01,
            "MaxConsecutiveLosses": 0.0,
            "CagrPercent": 0.02,
        }
        for field, tolerance in tolerances.items():
            supplied = number(result, field)
            if supplied is None or abs(supplied - float(metrics[field])) > tolerance:
                reasons.append(f"{field}=REPORT_MISMATCH")
    except (KeyError, OSError, ValueError) as exc:
        reasons.append(f"BOUND_REPORT_INVALID={exc}")
    return reasons


def evaluate_metric_row(manifest_row: dict[str, str], result: dict[str, str]) -> list[str]:
    reasons: list[str] = []
    comparisons = (
        ("NetProfit", "MinNetProfit", ">="),
        ("ProfitFactor", "MinProfitFactor", ">="),
        ("TotalTrades", "MinTrades", ">="),
        ("MaxDrawdownPercent", "MaxDrawdownPercent", "<="),
        ("RecoveryFactor", "MinRecoveryFactor", ">="),
        ("CagrPercent", "MinCagrPercent", ">="),
    )
    for metric, threshold_field, direction in comparisons:
        threshold = float(manifest_row[threshold_field])
        if threshold <= 0.0 and metric in {"RecoveryFactor", "CagrPercent"}:
            continue
        actual = number(result, metric)
        if actual is None:
            reasons.append(f"{metric}=MISSING")
        elif direction == ">=" and actual < threshold:
            reasons.append(f"{metric}={actual:g}<{threshold:g}")
        elif direction == "<=" and actual > threshold:
            reasons.append(f"{metric}={actual:g}>{threshold:g}")
    return reasons


def prerequisites() -> tuple[bool, str]:
    if not PRIMARY_GATE_DECISION.is_file() or not LEDGER_DECISION.is_file():
        return False, "primary executable decision artifacts are missing"
    primary = read_csv(PRIMARY_GATE_DECISION)
    ledger = read_csv(LEDGER_DECISION)
    require(len(primary) == 1 and len(ledger) == 1, "Primary prerequisite decisions are ambiguous")
    primary_pass = (
        primary[0].get("Status") == "EXECUTABLE_MT5_GATE_PASS_PENDING_LEDGER_STRESS"
        and primary[0].get("ExecutableGatePass", "False").lower() == "true"
        and primary[0].get("SourceSha256", "").upper() == EXPECTED_SOURCE_SHA256
        and primary[0].get("ProfileSha256", "").upper() == EXPECTED_PROFILE_SHA256
    )
    ledger_pass = ledger[0].get("Status") == "EXECUTABLE_LEDGER_STRESS_PASS"
    if not primary_pass:
        return False, f"primary gate={primary[0].get('Status', 'MISSING')}"
    if not ledger_pass:
        return False, f"ledger stress={ledger[0].get('Status', 'MISSING')}"
    return True, "PASS"


def waiting_decision(
    status: str,
    next_action: str,
    prerequisite_detail: str,
    reports_present: int,
    specification_pass: bool,
) -> dict[str, object]:
    return {
        "Status": status,
        "CurrentWave": 0,
        "PassedRows": 0,
        "TotalRows": 18,
        "ReportsPresent": reports_present,
        "SpecificationPass": specification_pass,
        "PrimaryPrerequisitePass": False,
        "SecondBrokerGatePass": False,
        "NextAction": next_action,
        "PrerequisiteDetail": prerequisite_detail,
        "TerminalRejection": False,
    }


def evaluate_gate(
    manifest: list[dict[str, str]],
    results: list[dict[str, str]],
    specification_hash: str,
    specification: dict[str, str],
    launch_locked: bool,
) -> tuple[dict[str, object], list[dict[str, object]]]:
    result_map: dict[str, dict[str, str]] = {}
    for row in results:
        name = row.get("ExpectedReportName", "")
        require(name and name not in result_map, f"Duplicate or blank result name: {name!r}")
        result_map[name] = row
    known_names = {row["ExpectedReportName"] for row in manifest}
    require(set(result_map).issubset(known_names), "Results contain a non-manifest report")

    details: list[dict[str, object]] = []
    passed_rows = 0
    for wave in range(1, 4):
        wave_rows = [row for row in manifest if int(row["Wave"]) == wave]
        if any(row["ExpectedReportName"] not in result_map for row in wave_rows):
            for row in wave_rows:
                present = row["ExpectedReportName"] in result_map
                details.append(
                    {
                        "QueueRank": row["QueueRank"],
                        "Wave": wave,
                        "ExpectedReportName": row["ExpectedReportName"],
                        "Window": row["Window"],
                        "ReportStatus": "PRESENT" if present else "MISSING_REPORT",
                        "GatePass": False,
                        "Reasons": "NOT_EVALUATED_INCOMPLETE_WAVE",
                    }
                )
            prefix = "LOCKED_" if launch_locked else ""
            return (
                {
                    "Status": f"{prefix}AWAITING_SECOND_BROKER_WAVE_{wave:02d}_REPORTS",
                    "CurrentWave": wave,
                    "PassedRows": passed_rows,
                    "TotalRows": 18,
                    "NextAction": (
                        f"WAIT_FOR_LAUNCH_UNLOCK_THEN_RUN_SECOND_BROKER_WAVE_{wave:02d}"
                        if launch_locked
                        else f"RUN_SECOND_BROKER_WAVE_{wave:02d}"
                    ),
                    "TerminalRejection": False,
                    "SecondBrokerGatePass": False,
                    "AnnualToContinuousNetRatio": "",
                    "SecondaryToPrimaryNetRatio": "",
                    "SecondaryToPrimaryTradeRatio": "",
                },
                details,
            )

        wave_failed = False
        for manifest_row in wave_rows:
            result = result_map[manifest_row["ExpectedReportName"]]
            reasons = []
            if result.get("Status") != "PARSED":
                reasons.append(f"Status={result.get('Status', 'MISSING')}")
            reasons.extend(validate_result_identity(manifest_row, result, specification_hash, specification))
            reasons.extend(evaluate_metric_row(manifest_row, result))
            passed = not reasons
            passed_rows += int(passed)
            wave_failed = wave_failed or not passed
            details.append(
                {
                    "QueueRank": manifest_row["QueueRank"],
                    "Wave": wave,
                    "ExpectedReportName": manifest_row["ExpectedReportName"],
                    "Window": manifest_row["Window"],
                    "ReportStatus": result.get("Status", "MISSING"),
                    "GatePass": passed,
                    "Reasons": "PASS" if passed else ";".join(reasons),
                }
            )
        if wave_failed:
            return (
                {
                    "Status": f"SECOND_BROKER_GATE_REJECTED_WAVE_{wave:02d}",
                    "CurrentWave": wave,
                    "PassedRows": passed_rows,
                    "TotalRows": 18,
                    "NextAction": "KEEP_CANDIDATE_UNAPPROVED_AND_DIAGNOSE_BROKER_DIVERGENCE",
                    "TerminalRejection": True,
                    "SecondBrokerGatePass": False,
                    "AnnualToContinuousNetRatio": "",
                    "SecondaryToPrimaryNetRatio": "",
                    "SecondaryToPrimaryTradeRatio": "",
                },
                details,
            )

    require(PRIMARY_RESULTS.is_file(), "Primary canonical results are missing after prerequisite pass")
    primary_results = read_csv(PRIMARY_RESULTS)
    primary_continuous = [row for row in primary_results if row.get("Role") == "continuous" and row.get("Model") == "4"]
    secondary_continuous_manifest = [row for row in manifest if row["Role"] == "continuous"]
    require(len(primary_continuous) == 1 and len(secondary_continuous_manifest) == 1, "Continuous evidence is ambiguous")
    secondary_continuous = result_map[secondary_continuous_manifest[0]["ExpectedReportName"]]
    annual_rows = [row for row in manifest if row["Role"] == "annual"]
    annual_net = sum(float(result_map[row["ExpectedReportName"]]["NetProfit"]) for row in annual_rows)
    secondary_net = float(secondary_continuous["NetProfit"])
    primary_net = float(primary_continuous[0]["NetProfit"])
    secondary_trades = float(secondary_continuous["TotalTrades"])
    primary_trades = float(primary_continuous[0]["TotalTrades"])
    annual_ratio = annual_net / secondary_net if secondary_net > 0.0 else math.inf
    net_ratio = secondary_net / primary_net if primary_net > 0.0 else math.inf
    trade_ratio = secondary_trades / primary_trades if primary_trades > 0.0 else math.inf
    consistency_pass = (
        ANNUAL_RATIO_RANGE[0] <= annual_ratio <= ANNUAL_RATIO_RANGE[1]
        and SECONDARY_PRIMARY_NET_RATIO_RANGE[0] <= net_ratio <= SECONDARY_PRIMARY_NET_RATIO_RANGE[1]
        and SECONDARY_PRIMARY_TRADE_RATIO_RANGE[0] <= trade_ratio <= SECONDARY_PRIMARY_TRADE_RATIO_RANGE[1]
    )
    details.append(
        {
            "QueueRank": "AGGREGATE",
            "Wave": 3,
            "ExpectedReportName": "second_broker_consistency",
            "Window": "2015_2026",
            "ReportStatus": "CALCULATED",
            "GatePass": consistency_pass,
            "Reasons": (
                "PASS"
                if consistency_pass
                else f"annual_ratio={annual_ratio:.4f};net_ratio={net_ratio:.4f};trade_ratio={trade_ratio:.4f}"
            ),
        }
    )
    if not consistency_pass:
        status = "SECOND_BROKER_GATE_REJECTED_CONSISTENCY"
        next_action = "KEEP_CANDIDATE_UNAPPROVED_AND_DIAGNOSE_BROKER_DIVERGENCE"
    else:
        status = "SECOND_BROKER_GATE_PASS_PENDING_VALID_FORWARD_DEMO"
        next_action = "COMPLETE_VALID_FROZEN_10000_DEMO_FORWARD_GATE"
    return (
        {
            "Status": status,
            "CurrentWave": 4,
            "PassedRows": passed_rows,
            "TotalRows": 18,
            "NextAction": next_action,
            "TerminalRejection": not consistency_pass,
            "SecondBrokerGatePass": consistency_pass,
            "AnnualToContinuousNetRatio": round(annual_ratio, 4),
            "SecondaryToPrimaryNetRatio": round(net_ratio, 4),
            "SecondaryToPrimaryTradeRatio": round(trade_ratio, 4),
        },
        details,
    )


def main() -> int:
    manifest = load_manifest()
    results = read_csv(RESULTS) if RESULTS.is_file() else []
    launch_locked = REPO_LOCK.is_file() or OUTER_LOCK.is_file()
    prerequisite_pass, prerequisite_detail = prerequisites()
    specification_rows = read_csv(SPECIFICATION) if SPECIFICATION.is_file() else []
    specification_pass, specification_reasons = validate_specification(specification_rows) if specification_rows else (False, ["missing"])
    details: list[dict[str, object]] = []
    specification_hash = sha256(SPECIFICATION) if SPECIFICATION.is_file() else ""

    if not prerequisite_pass:
        decision = waiting_decision(
            "AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS",
            "COMPLETE_PRIMARY_EXECUTABLE_GATE_AND_LEDGER_STRESS",
            prerequisite_detail,
            len(results),
            specification_pass,
        )
    elif not specification_pass:
        decision = waiting_decision(
            "AWAITING_DISTINCT_SECOND_BROKER_SPECIFICATION",
            "CAPTURE_ANONYMIZED_DISTINCT_BROKER_SPECIFICATION",
            ";".join(specification_reasons),
            len(results),
            False,
        )
        decision["PrimaryPrerequisitePass"] = True
    else:
        decision, details = evaluate_gate(manifest, results, specification_hash, specification_rows[0], launch_locked)
        decision["ReportsPresent"] = len(results)
        decision["SpecificationPass"] = True
        decision["PrimaryPrerequisitePass"] = True
        decision["PrerequisiteDetail"] = "PASS"

    decision_row = {
        **decision,
        "LaunchLocked": launch_locked,
        "ForwardCandidateChanged": False,
        "RealAccountApproved": False,
        "ManifestSha256": sha256(MANIFEST),
        "BrokerSpecificationSha256": specification_hash,
        "SourceSha256": EXPECTED_SOURCE_SHA256,
        "ProfileSha256": EXPECTED_PROFILE_SHA256,
        "PrimaryCompanyFingerprintSha256": PRIMARY_COMPANY_FINGERPRINT,
    }
    write_csv(DECISION_CSV, [decision_row])
    if details:
        write_csv(EVALUATION_CSV, details)
    else:
        EVALUATION_CSV.unlink(missing_ok=True)

    lines = [
        "# RDMC Second-Broker Validation Decision",
        "",
        f"**Status: {decision['Status']}. No new best, forward substitution, or real-money approval.**",
        "",
        f"- Primary executable plus ledger prerequisite: `{decision.get('PrimaryPrerequisitePass', False)}`",
        f"- Distinct broker specification: `{decision.get('SpecificationPass', False)}`",
        f"- Parsed reports supplied: `{len(results)}/18`",
        f"- Passed row gates: `{decision.get('PassedRows', 0)}/18`",
        f"- Launch locked: `{launch_locked}`",
        f"- Next action: `{decision['NextAction']}`",
        f"- Manifest SHA-256: `{sha256(MANIFEST)}`",
        f"- Source SHA-256: `{EXPECTED_SOURCE_SHA256}`",
        f"- Profile SHA-256: `{EXPECTED_PROFILE_SHA256}`",
        "",
        "## Evidence Boundary",
        "",
        "- All 52 stored MT5 reports and all four local portable roots represent only the primary broker family; none is counted as second-broker evidence.",
        "- Broker-proxy spread, commission, slippage, or margin profiles cannot satisfy this gate.",
        "- Raw broker/server names and account identifiers are excluded from public specification evidence; only SHA-256 fingerprints and trading specifications are admitted.",
        "- Two critical-year real-tick rows reject first. Broad/continuous and annual rows remain closed until earlier waves pass.",
        "- Even a full pass still requires the unchanged candidate to complete the valid frozen $10,000 forward-demo contract.",
        "- The registered forward candidate and real-account lock remain unchanged.",
    ]
    write_markdown(DECISION_MD, lines)
    print(f"{decision['Status']} reports={len(results)}/18 specification={specification_pass}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
