#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "outputs" / "RDMC_HARD_LANE_RISK_V4_WAVE_01_MANIFEST.csv"
RESULTS = ROOT / "outputs" / "RDMC_HARD_LANE_RISK_V4_WAVE_01_RESULTS.csv"
EVALUATION = ROOT / "outputs" / "RDMC_HARD_LANE_RISK_V4_WAVE_01_EVALUATION.csv"
DECISION = ROOT / "outputs" / "RDMC_HARD_LANE_RISK_V4_DECISION_FIXTURE.csv"
DECISION_MD = ROOT / "outputs" / "RDMC_HARD_LANE_RISK_V4_DECISION.md"
EXPECTED_MANIFEST = "636CCDBB66A43BFEDA99BBE7007A363CF666E92FB8AF2B5CB8B23A9B0C024E1C"
EXPECTED_SOURCE = "7A6CA3C9E9644656A0CDC64A6D078B446FB1A9981B16CDE727E65B13A5C06831"
EXPECTED_PROFILE = "224801DB7A02F2C54C3070ABB190187EA8C73FC7181CDD07BA33040025A2922B"


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
        raise ValueError("rewrite Wave 1 manifest identity changed")
    manifest = read_csv(MANIFEST)
    if len(manifest) != 2 or [row["Window"] for row in manifest] != ["2019", "2022"]:
        raise ValueError("rewrite Wave 1 shape changed")
    results = read_csv(RESULTS)
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

    complete = len(results) == 2 and all(row["Reasons"] != "REPORT_MISSING_OR_UNPARSED" for row in details)
    passed = complete and all(bool(row["GatePass"]) for row in details)
    if not complete:
        status = "AWAITING_WAVE_01_REPORTS"
        terminal = False
        next_action = "RUN_FROZEN_MODEL1_2019_AND_2022_ONLY"
    elif passed:
        status = "WAVE_01_PASS"
        terminal = False
        next_action = "FREEZE_WAVE_02_BROAD_MODEL1_QUEUE"
    else:
        status = "EXECUTABLE_GATE_REJECTED_WAVE_01"
        terminal = True
        reason_tokens = [token for row in details for token in str(row["Reasons"]).split(";") if token != "PASS"]
        activity_only = bool(reason_tokens) and all(token.startswith("TotalTrades=") for token in reason_tokens)
        next_action = (
            "ALLOW_ONE_NEW_IDENTITY_ONE_FACTOR_ACTIVITY_REPAIR_THEN_RESTART_WAVE_01"
            if activity_only
            else "REWRITE_ENTRY_OR_REGIME_LOGIC_THEN_RESTART_WAVE_01"
        )

    launch_locked = (ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock").is_file() or (ROOT.parent / "MT5_LOCAL_LAUNCH_DISABLED.lock").is_file()
    decision = {
        "Status": status,
        "CurrentWave": 1,
        "PassedRows": sum(bool(row["GatePass"]) for row in details),
        "TotalRows": 2,
        "ReportsPresent": len(results),
        "TerminalRejection": terminal,
        "ExecutableGatePass": passed,
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
        "# RDMC Hard Lane Risk v4 Decision",
        "",
        f"**Status: {status}. No inherited profit, forward substitution, or real-money approval.**",
        "",
        f"- Reports: `{len(results)}/2`",
        f"- Passed rows: `{decision['PassedRows']}/2`",
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
    print(f"{status} reports={len(results)}/2 passed={decision['PassedRows']}/2")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
