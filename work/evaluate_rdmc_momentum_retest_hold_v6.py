#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "outputs" / "RDMC_MOMENTUM_RETEST_HOLD_V6_GATE_MANIFEST.csv"
RESULTS = ROOT / "outputs" / "RDMC_MOMENTUM_RETEST_HOLD_V6_GATE_RESULTS.csv"
EVALUATION = ROOT / "outputs" / "RDMC_MOMENTUM_RETEST_HOLD_V6_GATE_EVALUATION.csv"
DECISION = ROOT / "outputs" / "RDMC_MOMENTUM_RETEST_HOLD_V6_DECISION_FIXTURE.csv"
DECISION_MD = ROOT / "outputs" / "RDMC_MOMENTUM_RETEST_HOLD_V6_DECISION.md"
EXPECTED_MANIFEST = "EB636293E3A74D260B82D1720D57EB11EBEEC2B1FCF2C55FD091E0A60AFA9B02"
EXPECTED_SOURCE = "B99BEFF28BB0D28596F4D7786C65BDA11001B0BC4924F269F534817EADC6CDCC"
EXPECTED_PROFILE = "9E8AC3C528860799CB152245CF1FFB084A8E9FD07A2A33F70FD927EFA077D390"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        return []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    if sha256(MANIFEST) != EXPECTED_MANIFEST:
        raise ValueError("breakout-retest gate manifest identity changed")
    manifest = read_csv(MANIFEST)
    if (
        len(manifest) != 3
        or [row["Window"] for row in manifest] != ["2015_2018", "2019", "2022"]
        or [row["Wave"] for row in manifest] != ["1", "2", "2"]
    ):
        raise ValueError("breakout-retest staged gate shape changed")
    results = read_csv(RESULTS)
    expected_names = {row["ExpectedReportName"] for row in manifest}
    if any(row.get("ExpectedReportName") not in expected_names for row in results):
        raise ValueError("results contain an unknown gate row")
    by_name = {row["ExpectedReportName"]: row for row in results}
    details: list[dict[str, object]] = []
    for expected in manifest:
        actual = by_name.get(expected["ExpectedReportName"])
        reasons: list[str] = []
        if actual is None or actual.get("Status") != "PARSED":
            reasons.append("REPORT_MISSING_OR_UNPARSED")
        else:
            if actual.get("SourceSha256") != EXPECTED_SOURCE:
                reasons.append("SOURCE_IDENTITY_MISMATCH")
            if actual.get("ProfileSha256") != EXPECTED_PROFILE:
                reasons.append("PROFILE_IDENTITY_MISMATCH")
            checks = (
                ("NetProfit", float(actual["NetProfit"]), float(expected["MinNetProfit"]), ">="),
                ("ProfitFactor", float(actual["ProfitFactor"]), float(expected["MinProfitFactor"]), ">="),
                ("TotalTrades", float(actual["TotalTrades"]), float(expected["MinTrades"]), ">="),
                ("MaxDrawdownPercent", float(actual["MaxDrawdownPercent"]), float(expected["MaxDrawdownPercent"]), "<="),
                ("RecoveryFactor", float(actual["RecoveryFactor"]), float(expected["MinRecoveryFactor"]), ">="),
            )
            for name, value, threshold, operation in checks:
                passed = value >= threshold if operation == ">=" else value <= threshold
                if not passed:
                    failed_relation = "<" if operation == ">=" else ">"
                    reasons.append(f"{name}={value:g}{failed_relation}{threshold:g}")
        details.append(
            {
                "QueueRank": expected["QueueRank"],
                "Window": expected["Window"],
                "ExpectedReportName": expected["ExpectedReportName"],
                "GatePass": not reasons,
                "Reasons": "PASS" if not reasons else ";".join(reasons),
                "NetProfit": "" if actual is None else actual.get("NetProfit", ""),
                "ProfitFactor": "" if actual is None else actual.get("ProfitFactor", ""),
                "TotalTrades": "" if actual is None else actual.get("TotalTrades", ""),
                "MaxDrawdownPercent": "" if actual is None else actual.get("MaxDrawdownPercent", ""),
                "RecoveryFactor": "" if actual is None else actual.get("RecoveryFactor", ""),
            }
        )

    wave1 = details[:1]
    wave2 = details[1:]
    wave1_complete = all(row["Reasons"] != "REPORT_MISSING_OR_UNPARSED" for row in wave1)
    wave1_pass = wave1_complete and all(bool(row["GatePass"]) for row in wave1)
    wave2_complete = all(row["Reasons"] != "REPORT_MISSING_OR_UNPARSED" for row in wave2)
    wave2_pass = wave2_complete and all(bool(row["GatePass"]) for row in wave2)
    staged_gate_pass = wave1_pass and wave2_pass

    if not wave1_complete:
        status = "AWAITING_WAVE_01_REPORTS"
        current_wave = 1
        terminal = False
        next_action = "RUN_FROZEN_2015_2018_TRAINING_GATE_ONLY"
    elif not wave1_pass:
        status = "EXECUTABLE_GATE_REJECTED_WAVE_01"
        current_wave = 0
        terminal = True
        next_action = "REWRITE_ENTRY_OR_REGIME_LOGIC_WITHOUT_OPENING_CRITICAL_YEARS"
    elif not wave2_complete:
        status = "AWAITING_WAVE_02_REPORTS"
        current_wave = 2
        terminal = False
        next_action = "RUN_FROZEN_MODEL1_2019_AND_2022_ONLY"
    elif wave2_pass:
        status = "WAVE_02_PASS"
        current_wave = 0
        terminal = False
        next_action = "FREEZE_BROAD_MODEL1_AND_MODEL4_GATES_WITHOUT_CHANGING_IDENTITY"
    else:
        status = "EXECUTABLE_GATE_REJECTED_WAVE_02"
        current_wave = 0
        terminal = True
        next_action = "REWRITE_ENTRY_OR_REGIME_LOGIC_THEN_RESTART_WITH_OLDER_TRAINING_GATE"

    launch_locked = (ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock").is_file() or (ROOT.parent / "MT5_LOCAL_LAUNCH_DISABLED.lock").is_file()
    decision = {
        "Status": status,
        "CurrentWave": current_wave,
        "PassedRows": sum(bool(row["GatePass"]) for row in details),
        "TotalRows": 3,
        "ReportsPresent": len(results),
        "TerminalRejection": terminal,
        "StagedGatePass": staged_gate_pass,
        "ExecutableGatePass": False,
        "NextAction": next_action,
        "LaunchLocked": launch_locked,
        "ForwardCandidateChanged": False,
        "RealAccountApproved": False,
        "ManifestSha256": EXPECTED_MANIFEST,
        "SourceSha256": EXPECTED_SOURCE,
        "ProfileSha256": EXPECTED_PROFILE,
    }
    write_csv(EVALUATION, details)
    write_csv(DECISION, [decision])
    lines = [
        "# RDMC Momentum Retest/Hold v6 Decision",
        "",
        f"**Status: {status}. No inherited profit, forward substitution, or real-money approval.**",
        "",
        f"- Reports: `{len(results)}/3`",
        f"- Passed rows: `{decision['PassedRows']}/3`",
        f"- Current wave: `{current_wave}`",
        f"- Launch locked: `{launch_locked}`",
        f"- Next action: `{next_action}`",
        f"- Source SHA-256: `{EXPECTED_SOURCE}`",
        f"- Profile SHA-256: `{EXPECTED_PROFILE}`",
        f"- Manifest SHA-256: `{EXPECTED_MANIFEST}`",
        "",
        "| Window | Pass | Net | PF | Trades | Drawdown | Reasons |",
        "|---|---:|---:|---:|---:|---:|---|",
    ]
    lines.extend(
        f"| {row['Window']} | {row['GatePass']} | {row['NetProfit']} | {row['ProfitFactor']} | {row['TotalTrades']} | {row['MaxDrawdownPercent']}% | {row['Reasons']} |"
        for row in details
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"{status} reports={len(results)}/3 passed={decision['PassedRows']}/3")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
