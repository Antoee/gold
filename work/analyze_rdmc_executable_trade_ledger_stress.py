#!/usr/bin/env python3
"""Run identity-bound stress only after all frozen executable MT5 waves pass."""

from __future__ import annotations

import csv
import hashlib
from dataclasses import asdict
from pathlib import Path

import rdmc_executable_ledger_stress_core as core


ROOT = Path(__file__).resolve().parents[1]
ANALYZER = Path(__file__).resolve()
MANIFEST = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv"
RESULTS = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_RESULTS.csv"
GATE_DECISION = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_DECISION.csv"
REPORT_ROOT = ROOT / "outputs" / "rdmc_diversified_repair_executable_gate_package" / "reports_here"
TRADES_CSV = ROOT / "outputs" / "RDMC_EXECUTABLE_LEDGER_TRADES.csv"
COST_CSV = ROOT / "outputs" / "RDMC_EXECUTABLE_LEDGER_COST_STRESS.csv"
MC_CSV = ROOT / "outputs" / "RDMC_EXECUTABLE_LEDGER_ORDER_AWARE_MONTE_CARLO.csv"
DECISION_CSV = ROOT / "outputs" / "RDMC_EXECUTABLE_LEDGER_STRESS_DECISION.csv"
DECISION_MD = ROOT / "outputs" / "RDMC_EXECUTABLE_LEDGER_STRESS_DECISION.md"

EXPECTED_MANIFEST_SHA256 = "4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A"
EXPECTED_SOURCE_SHA256 = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
EXPECTED_PROFILE_SHA256 = "746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883"
ADMISSION_STATUS = "EXECUTABLE_MT5_GATE_PASS_PENDING_LEDGER_STRESS"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def normalized_text_sha256(path: Path) -> str:
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\r", "\n")
    return hashlib.sha256(text.encode("utf-8")).hexdigest().upper()


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


def money(value: float) -> str:
    return f"{'+' if value >= 0.0 else '-'}${abs(value):,.2f}"


def remove_stale_stress() -> None:
    for path in (TRADES_CSV, COST_CSV, MC_CSV):
        path.unlink(missing_ok=True)


def write_waiting(gate_status: str, launch_locked: bool) -> None:
    remove_stale_stress()
    row: dict[str, object] = {
        "Status": "AWAITING_EXECUTABLE_MT5_GATE",
        "CurrentExecutableGateStatus": gate_status,
        "ExecutableGatePass": False,
        "ExecutableLedgerPresent": False,
        "CostGatePass": False,
        "OrderAwareMonteCarloPass": False,
        "LaunchLocked": launch_locked,
        "ForwardCandidateChanged": False,
        "RealAccountApproved": False,
        "ManifestSha256": sha256(MANIFEST),
        "SourceSha256": EXPECTED_SOURCE_SHA256,
        "ProfileSha256": EXPECTED_PROFILE_SHA256,
        "AnalyzerSha256": normalized_text_sha256(ANALYZER),
        "CoreSha256": normalized_text_sha256(Path(core.__file__)),
    }
    write_csv(DECISION_CSV, [row])
    lines = [
        "# RDMC Executable Ledger Stress Decision",
        "",
        "**Status: AWAITING EXECUTABLE MT5 GATE. No executable ledger exists and no stress pass is claimed.**",
        "",
        f"- Current executable status: `{gate_status}`",
        f"- Launch locked: `{launch_locked}`",
        "- Required admission status: `EXECUTABLE_MT5_GATE_PASS_PENDING_LEDGER_STRESS`",
        "- Frozen candidate changed: `False`",
        "- Real-account trading approved: `False`",
        "",
        "The analyzer will admit only the identity-bound continuous Model4 report after all 24 executable rows and annual consistency pass. Post-hoc component ledgers cannot substitute for that report.",
    ]
    write_markdown(DECISION_MD, lines)


def relative_repo_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        relative = resolved.relative_to(ROOT.resolve())
    except ValueError as exc:
        raise ValueError(f"Evidence path is outside repository: {resolved}") from exc
    return str(relative).replace("/", "\\")


def trade_row(trade: core.Trade) -> dict[str, object]:
    raw = asdict(trade)
    return {
        "TradeIndex": raw["index"],
        "EntryTime": trade.entry_time.isoformat(),
        "ExitTime": trade.exit_time.isoformat(),
        "EntryDeal": trade.entry_deal,
        "ExitDeal": trade.exit_deal,
        "EntryOrder": trade.entry_order,
        "ExitOrder": trade.exit_order,
        "Symbol": trade.symbol,
        "Side": trade.side,
        "Volume": trade.volume,
        "EntryPrice": trade.entry_price,
        "ExitPrice": trade.exit_price,
        "InitialStop": trade.initial_stop,
        "InitialTarget": trade.initial_target,
        "InitialRiskMoney": round(trade.initial_risk, 6),
        "RiskR": round(trade.risk_r, 8),
        "GrossProfit": round(trade.gross_profit, 2),
        "Commission": round(trade.commission, 2),
        "Fee": round(trade.fee, 2),
        "Swap": round(trade.swap, 2),
        "NetProfit": round(trade.profit, 2),
        "HoldMinutes": round(trade.hold_minutes, 2),
        "EntryComment": trade.entry_comment,
        "ExitComment": trade.exit_comment,
    }


def run_admitted_stress(
    manifest: list[dict[str, str]],
    results: list[dict[str, str]],
    launch_locked: bool,
) -> None:
    require(len(results) == 24, "Executable stress requires all 24 canonical result rows")
    continuous = [
        row
        for row in manifest
        if row["Wave"] == "4" and row["Role"] == "continuous" and row["Model"] == "4"
    ]
    require(len(continuous) == 1, "Expected one frozen continuous Model4 row")
    manifest_row = continuous[0]
    matched = [row for row in results if row["ExpectedReportName"] == manifest_row["ExpectedReportName"]]
    require(len(matched) == 1, "Expected one canonical continuous Model4 result")
    result = matched[0]
    require(result["Status"] == "PARSED", "Continuous Model4 result is not parsed")
    require(result["ConfigSha256"].upper() == manifest_row["ConfigSha256"], "Continuous config identity mismatch")
    require(result["SourceSha256"].upper() == EXPECTED_SOURCE_SHA256, "Continuous source identity mismatch")
    require(result["ProfileSha256"].upper() == EXPECTED_PROFILE_SHA256, "Continuous profile identity mismatch")
    binary_hash = result["PortableBinarySha256"].upper()
    require(len(binary_hash) == 64, "Continuous binary identity is missing")

    report = ROOT / result["ReportPath"]
    identity_path = ROOT / result["ReportIdentityPath"]
    require(report.resolve().parent == REPORT_ROOT.resolve(), "Continuous report is outside the admitted report root")
    expected_identity_path = REPORT_ROOT / f"{manifest_row['ExpectedReportName']}.identity.json"
    require(identity_path.resolve() == expected_identity_path.resolve(), "Continuous identity sidecar path is not canonical")
    identity = core.validate_report_identity(
        report,
        identity_path,
        manifest_row["ExpectedReportName"],
        manifest_row["ConfigSha256"],
        EXPECTED_SOURCE_SHA256,
        binary_hash,
    )
    require(str(identity["ReportSha256"]).upper() == result["ReportSha256"].upper(), "Canonical report hash mismatch")
    trades, report_metrics = core.parse_mt5_report(report)
    require(len(trades) == int(float(result["TotalTrades"])), "Ledger trade count differs from canonical result")
    require(abs(sum(trade.profit for trade in trades) - float(result["NetProfit"])) <= 0.02, "Ledger net differs from canonical result")
    require(abs(report_metrics["ProfitFactor"] - float(result["ProfitFactor"])) <= 0.01, "Report PF differs from canonical result")

    write_csv(TRADES_CSV, [trade_row(trade) for trade in trades])
    cost_rows = core.cost_stress(trades)
    mc_rows = core.monte_carlo_stress(trades)
    write_csv(COST_CSV, cost_rows)
    write_csv(MC_CSV, mc_rows)
    cost_pass = all(bool(row["GatePass"]) for row in cost_rows)
    mc_pass = all(bool(row["GatePass"]) for row in mc_rows)
    status = "EXECUTABLE_LEDGER_STRESS_PASS" if cost_pass and mc_pass else "EXECUTABLE_LEDGER_STRESS_FAIL"
    decision: dict[str, object] = {
        "Status": status,
        "CurrentExecutableGateStatus": ADMISSION_STATUS,
        "ExecutableGatePass": True,
        "ExecutableLedgerPresent": True,
        "CostGatePass": cost_pass,
        "OrderAwareMonteCarloPass": mc_pass,
        "Trades": len(trades),
        "NetProfit": round(sum(trade.profit for trade in trades), 2),
        "LedgerSha256": sha256(TRADES_CSV),
        "ReportSha256": sha256(report),
        "PortableBinarySha256": binary_hash,
        "LaunchLocked": launch_locked,
        "ForwardCandidateChanged": False,
        "RealAccountApproved": False,
        "ManifestSha256": sha256(MANIFEST),
        "SourceSha256": EXPECTED_SOURCE_SHA256,
        "ProfileSha256": EXPECTED_PROFILE_SHA256,
        "AnalyzerSha256": normalized_text_sha256(ANALYZER),
        "CoreSha256": normalized_text_sha256(Path(core.__file__)),
    }
    write_csv(DECISION_CSV, [decision])

    lines = [
        "# RDMC Executable Ledger Stress Decision",
        "",
        f"**Status: {status.replace('_', ' ')}. This is trade-level executable evidence, not real-money approval.**",
        "",
        f"- Trades: `{len(trades)}`; parsed net: `{money(float(decision['NetProfit']))}`",
        f"- Cost gate: `{cost_pass}`; order-aware Monte Carlo gate: `{mc_pass}`",
        f"- Report: `{relative_repo_path(report)}`",
        f"- Report SHA-256: `{decision['ReportSha256']}`",
        f"- Ledger SHA-256: `{decision['LedgerSha256']}`",
        "",
        "## Added Execution Cost",
        "",
        "| Scenario | Added R/trade | Extra cost | Net | PF | Closed DD | Older | Middle | Recent | Gate |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in cost_rows:
        lines.append(
            f"| {row['Scenario']} | {float(row['AddedCostRPerTrade']):.2f}R | "
            f"${float(row['ExtraCost']):,.2f} | {money(float(row['NetProfit']))} | "
            f"{float(row['ProfitFactor']):.3f} | {float(row['MaxClosedDrawdownPercent']):.3f}% | "
            f"{money(float(row['Older2015To2018']))} | {money(float(row['Middle2019To2022']))} | "
            f"{money(float(row['Recent2023To2026']))} | {row['GatePass']} |"
        )
    lines.extend(
        [
            "",
            "## Order-Aware Monte Carlo",
            "",
            "| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 closed DD | P95 loss run | Red trials | Gate |",
            "|---|---|---:|---:|---:|---:|---:|---:|---:|---|",
        ]
    )
    for row in mc_rows:
        lines.append(
            f"| {row['Sampler']} | {row['StressScenario']} | {row['Trials']} | "
            f"{money(float(row['P05NetProfit']))} | {money(float(row['MedianNetProfit']))} | "
            f"{float(row['MedianProfitFactor']):.3f} | {float(row['P95MaxClosedDrawdownPercent']):.3f}% | "
            f"{float(row['P95MaxConsecutiveLosses']):.0f} | {float(row['RedTrialPercent']):.3f}% | {row['GatePass']} |"
        )
    lines.extend(
        [
            "",
            "## Remaining Boundary",
            "",
            "- Drawdown here is closed-trade path drawdown; the executable MT5 reports remain authoritative for intratrade equity drawdown.",
            "- Passing still requires broker-specification variation and a valid forward demo before any money-ready decision.",
            "- The registered candidate and real-account safety lock remain unchanged.",
        ]
    )
    write_markdown(DECISION_MD, lines)


def main() -> int:
    require(MANIFEST.is_file() and GATE_DECISION.is_file(), "Executable gate artifacts are missing")
    require(sha256(MANIFEST) == EXPECTED_MANIFEST_SHA256, "Executable manifest identity changed")
    manifest = read_csv(MANIFEST)
    require(len(manifest) == 24, "Expected 24 frozen executable rows")
    require({row["SourceSha256"] for row in manifest} == {EXPECTED_SOURCE_SHA256}, "Manifest source changed")
    require({row["ProfileSha256"] for row in manifest} == {EXPECTED_PROFILE_SHA256}, "Manifest profile changed")
    decision_rows = read_csv(GATE_DECISION)
    require(len(decision_rows) == 1, "Expected one executable decision row")
    gate = decision_rows[0]
    require(gate["ManifestSha256"].upper() == EXPECTED_MANIFEST_SHA256, "Decision manifest identity changed")
    require(gate["SourceSha256"].upper() == EXPECTED_SOURCE_SHA256, "Decision source identity changed")
    require(gate["ProfileSha256"].upper() == EXPECTED_PROFILE_SHA256, "Decision profile identity changed")
    gate_status = gate["Status"]
    launch_locked = gate.get("LaunchLocked", "False").lower() == "true"
    if gate_status != ADMISSION_STATUS:
        write_waiting(gate_status, launch_locked)
        print(f"AWAITING_EXECUTABLE_MT5_GATE current={gate_status}")
        return 0
    require(gate.get("ExecutableGatePass", "False").lower() == "true", "Executable pass flag is false")
    require(RESULTS.is_file(), "Canonical executable results are missing")
    run_admitted_stress(manifest, read_csv(RESULTS), launch_locked)
    print(read_csv(DECISION_CSV)[0]["Status"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
