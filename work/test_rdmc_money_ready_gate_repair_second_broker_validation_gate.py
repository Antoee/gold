#!/usr/bin/env python3
"""Regression checks for the preregistered distinct-broker Model4 gate."""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "work" / "evaluate_rdmc_money_ready_gate_repair_second_broker_validation_gate.py"
sys.path.insert(0, str(ROOT / "work"))
SPEC = importlib.util.spec_from_file_location("rdmc_second_broker_gate", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Could not load second-broker gate evaluator")
GATE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = GATE
SPEC.loader.exec_module(GATE)
import collect_rdmc_money_ready_gate_repair_second_broker_validation_results as COLLECTOR  # noqa: E402


COMPANY = "Synthetic Distinct Broker"
COMPANY_HASH = hashlib.sha256(COMPANY.casefold().encode("utf-8")).hexdigest().upper()
SERVER_HASH = "B" * 64
BINARY_HASH = "A" * 64
SPECIFICATION_HASH = "D" * 64


def expect_rejection(action, expected: str) -> None:
    try:
        action()
    except ValueError as exc:
        assert expected.lower() in str(exc).lower(), (expected, str(exc))
    else:
        raise AssertionError(f"Expected rejection containing: {expected}")


def valid_specification() -> dict[str, str]:
    return {
        "SchemaVersion": "1",
        "EnvironmentRole": "SECONDARY",
        "CompanyFingerprintSha256": COMPANY_HASH,
        "ServerFingerprintSha256": SERVER_HASH,
        "PrimaryCompanyFingerprintSha256": GATE.PRIMARY_COMPANY_FINGERPRINT,
        "Symbol": "XAUUSD",
        "AccountCurrency": "USD",
        "MarginMode": "HEDGING",
        "TerminalBuild": "6000",
        "ContractSize": "100",
        "TickSize": "0.01",
        "TickValueProfit": "1.00",
        "TickValueLoss": "1.00",
        "Point": "0.01",
        "Digits": "2",
        "VolumeMin": "0.01",
        "VolumeMax": "100.00",
        "VolumeStep": "0.01",
        "StopsLevelPoints": "0",
        "FreezeLevelPoints": "0",
        "TradeMode": "FULL",
        "SwapMode": "POINTS",
        "SwapLong": "-40.0",
        "SwapShort": "20.0",
        "SpecificationCapturedUtc": "2026-07-18T18:00:00+00:00",
        "SourceSha256": GATE.EXPECTED_SOURCE_SHA256,
        "ProfileSha256": GATE.EXPECTED_PROFILE_SHA256,
        "AccountIdentifierPublished": "False",
    }


def td(cells: list[object]) -> str:
    return "<tr>" + "".join(f"<td>{cell}</td>" for cell in cells) + "</tr>"


def write_report(
    report: Path,
    identity: Path,
    manifest_row: dict[str, str],
    net: float,
    trades: int,
) -> dict[str, str]:
    lines = [
        "<html><body>",
        td(["Company:", COMPANY]),
        td(["Currency:", "USD"]),
        td(["Initial Deposit:", "10000.00"]),
        td(["Total Net Profit:", f"{net:.2f}"]),
        td(["Profit Factor:", "2.00"]),
        td(["Expected Payoff:", "5.00"]),
        td(["Recovery Factor:", "5.00"]),
        td(["Sharpe Ratio:", "2.00"]),
        td(["Total Trades:", trades]),
        td(["Equity Drawdown Relative:", "1.00% (100.00)"]),
        td(["Profit Trades (% of total):", f"{max(1, trades // 2)} (55.00%)"]),
        td(["Maximum consecutive losses ($):", "5 (-50.00)"]),
        td(["SourceSha256:", GATE.EXPECTED_SOURCE_SHA256]),
        "</body></html>",
    ]
    report.write_text("\n".join(lines) + "\n", encoding="ascii", newline="\n")
    report_hash = hashlib.sha256(report.read_bytes()).hexdigest().upper()
    identity_payload = {
        "SchemaVersion": 1,
        "ExpectedReportName": report.stem,
        "ConfigSha256": manifest_row["ConfigSha256"],
        "SourceSha256": GATE.EXPECTED_SOURCE_SHA256,
        "PortableBinarySha256": BINARY_HASH,
        "ReportSha256": report_hash,
        "ReportBytes": report.stat().st_size,
        "CreatedUtc": "2026-07-18T18:00:00+00:00",
    }
    identity.write_text(json.dumps(identity_payload), encoding="ascii", newline="\n")
    metrics = GATE.parse_bound_report_metrics(report, manifest_row)
    return {
        "QueueRank": manifest_row["QueueRank"],
        "Wave": manifest_row["Wave"],
        "Role": manifest_row["Role"],
        "Window": manifest_row["Window"],
        "Model": "4",
        "ExpectedReportName": manifest_row["ExpectedReportName"],
        "Status": "PARSED",
        "ReportPath": str(report),
        "ReportIdentityPath": str(identity),
        "ReportSha256": report_hash,
        "ConfigSha256": manifest_row["ConfigSha256"],
        "SourceSha256": GATE.EXPECTED_SOURCE_SHA256,
        "ProfileSha256": GATE.EXPECTED_PROFILE_SHA256,
        "PortableBinarySha256": BINARY_HASH,
        "BrokerSpecificationSha256": SPECIFICATION_HASH,
        **{key: str(value) for key, value in metrics.items() if key not in {"CompanyFingerprintSha256", "AccountCurrency"}},
    }


def result_set(
    manifest: list[dict[str, str]], report_root: Path, annual_net: float = 125.0, continuous_net: float = 1500.0
) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for row in manifest:
        net = annual_net if row["Role"] == "annual" else 100.0
        if row["Role"] == "continuous":
            net = continuous_net
        trades = max(int(row["MinTrades"]) + 10, 300 if row["Role"] == "continuous" else 1)
        report = report_root / f"{row['ExpectedReportName']}.htm"
        identity = report_root / f"{row['ExpectedReportName']}.identity.json"
        rows.append(write_report(report, identity, row, net, trades))
    return rows


manifest = GATE.load_manifest()
assert len(manifest) == 18
assert [sum(int(row["Wave"]) == wave for row in manifest) for wave in range(1, 4)] == [2, 4, 12]
assert {row["Model"] for row in manifest} == {"4"}

specification = valid_specification()
passed, reasons = GATE.validate_specification([specification])
assert passed and not reasons
same_company = dict(specification, CompanyFingerprintSha256=GATE.PRIMARY_COMPANY_FINGERPRINT)
assert not GATE.validate_specification([same_company])[0]
synthetic_identifier = str(12_000_000 + 345_678)
leaked_account = dict(specification, Login=synthetic_identifier)
assert not GATE.validate_specification([leaked_account])[0]
lowercase_leak = dict(specification, account=synthetic_identifier)
assert not GATE.validate_specification([lowercase_leak])[0]
bad_time = dict(specification, SpecificationCapturedUtc="2026-07-18T18:00:00")
assert not GATE.validate_specification([bad_time])[0]
missing_swap = dict(specification, SwapLong="")
assert not GATE.validate_specification([missing_swap])[0]

with tempfile.TemporaryDirectory(prefix="rdmc_second_broker_") as temporary:
    temp = Path(temporary)
    report_root = temp / "reports_here"
    report_root.mkdir()
    primary_results = temp / "primary_results.csv"
    GATE.REPORT_ROOT = report_root
    GATE.PRIMARY_RESULTS = primary_results
    with primary_results.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["Role", "Model", "NetProfit", "TotalTrades"], lineterminator="\n")
        writer.writeheader()
        writer.writerow({"Role": "continuous", "Model": "4", "NetProfit": "1500", "TotalTrades": "300"})

    all_pass = result_set(manifest, report_root)
    COLLECTOR.gate.REPORT_ROOT = report_root
    COLLECTOR.ROOT = temp
    collector_rows = COLLECTOR.collect_wave(manifest, specification, SPECIFICATION_HASH, [], 1)
    assert len(collector_rows) == 2 and all(row["Status"] == "PARSED" for row in collector_rows)
    locked_admission = {
        "Status": "LOCKED_AWAITING_SECOND_BROKER_WAVE_01_REPORTS",
        "PrimaryPrerequisitePass": "True",
        "SpecificationPass": "True",
    }
    assert COLLECTOR.admitted_wave(locked_admission) == 1
    expect_rejection(
        lambda: COLLECTOR.admitted_wave({"Status": "AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS"}),
        "not admitted",
    )

    extra_report = report_root / f"{manifest[0]['ExpectedReportName']}.html"
    extra_report.write_bytes(Path(all_pass[0]["ReportPath"]).read_bytes())
    expect_rejection(
        lambda: COLLECTOR.collect_wave(manifest, specification, SPECIFICATION_HASH, [], 1),
        "expected one report",
    )
    extra_report.unlink()

    identifier_report = report_root / "identifier_probe.htm"
    identifier_report.write_text(td(["Login:", synthetic_identifier]), encoding="ascii", newline="\n")
    expect_rejection(
        lambda: COLLECTOR.gate.reject_report_account_identifier(identifier_report),
        "prohibited account identifier",
    )

    decision, _ = GATE.evaluate_gate(manifest, [], SPECIFICATION_HASH, specification, launch_locked=True)
    assert decision["Status"] == "LOCKED_AWAITING_SECOND_BROKER_WAVE_01_REPORTS"

    wave1 = [row for row in all_pass if row["Wave"] == "1"]
    decision, _ = GATE.evaluate_gate(manifest, wave1, SPECIFICATION_HASH, specification, launch_locked=False)
    assert decision["Status"] == "AWAITING_SECOND_BROKER_WAVE_02_REPORTS"

    losing_wave1 = [dict(row) for row in wave1]
    losing_wave1[0]["NetProfit"] = "-1.00"
    decision, details = GATE.evaluate_gate(manifest, losing_wave1, SPECIFICATION_HASH, specification, launch_locked=False)
    assert decision["Status"] == "SECOND_BROKER_GATE_REJECTED_WAVE_01"
    assert any("REPORT_MISMATCH" in str(row["Reasons"]) for row in details)

    decision, details = GATE.evaluate_gate(manifest, all_pass, SPECIFICATION_HASH, specification, launch_locked=False)
    assert decision["Status"] == "SECOND_BROKER_GATE_PASS_PENDING_VALID_FORWARD_DEMO"
    assert decision["SecondBrokerGatePass"] is True
    assert decision["AnnualToContinuousNetRatio"] == 1.0
    assert details[-1]["GatePass"] is True

    tampered = [dict(row) for row in all_pass]
    Path(tampered[0]["ReportPath"]).write_text("tampered", encoding="ascii")
    decision, details = GATE.evaluate_gate(manifest, tampered, SPECIFICATION_HASH, specification, launch_locked=False)
    assert decision["Status"] == "SECOND_BROKER_GATE_REJECTED_WAVE_01"
    assert any("BOUND_REPORT_INVALID" in str(row["Reasons"]) for row in details)

with tempfile.TemporaryDirectory(prefix="rdmc_second_broker_consistency_") as temporary:
    temp = Path(temporary)
    report_root = temp / "reports_here"
    report_root.mkdir()
    primary_results = temp / "primary_results.csv"
    GATE.REPORT_ROOT = report_root
    GATE.PRIMARY_RESULTS = primary_results
    with primary_results.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["Role", "Model", "NetProfit", "TotalTrades"], lineterminator="\n")
        writer.writeheader()
        writer.writerow({"Role": "continuous", "Model": "4", "NetProfit": "1500", "TotalTrades": "300"})
    divergent = result_set(manifest, report_root, annual_net=20.0, continuous_net=1500.0)
    decision, details = GATE.evaluate_gate(manifest, divergent, SPECIFICATION_HASH, specification, launch_locked=False)
    assert decision["Status"] == "SECOND_BROKER_GATE_REJECTED_CONSISTENCY"
    assert details[-1]["GatePass"] is False

run = subprocess.run(
    [sys.executable, str(MODULE_PATH)], cwd=ROOT, check=True, capture_output=True, text=True
)
assert "AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS" in run.stdout
with GATE.DECISION_CSV.open(encoding="utf-8-sig", newline="") as handle:
    current = list(csv.DictReader(handle))
assert len(current) == 1 and current[0]["Status"] == "AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS"
assert current[0]["ForwardCandidateChanged"] == "False" and current[0]["RealAccountApproved"] == "False"
assert (ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock").is_file()
assert (ROOT.parent / "MT5_LOCAL_LAUNCH_DISABLED.lock").is_file()

print("RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_GATE_TEST_PASS cases=16 rows=18 waves=3 model4_only=true")
