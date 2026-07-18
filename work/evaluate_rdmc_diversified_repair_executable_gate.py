#!/usr/bin/env python3
"""Evaluate the frozen staged executable gate without launching MT5."""

from __future__ import annotations

import csv
import hashlib
import math
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv"
RESULTS = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_RESULTS.csv"
EVALUATION_CSV = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_EVALUATION.csv"
DECISION_CSV = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_DECISION.csv"
DECISION_MD = ROOT / "outputs" / "RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_DECISION.md"
REPO_LOCK = ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock"
OUTER_LOCK = ROOT.parent / "MT5_LOCAL_LAUNCH_DISABLED.lock"

EXPECTED_MANIFEST_SHA256 = "4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A"
EXPECTED_SOURCE_SHA256 = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
EXPECTED_PROFILE_SHA256 = "746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883"
EXPECTED_WAVE_COUNTS = {1: 2, 2: 4, 3: 2, 4: 4, 5: 12}
ANNUAL_RATIO_MIN = 0.75
ANNUAL_RATIO_MAX = 1.25


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    require(bool(rows), f"No rows for {path.name}")
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def load_manifest() -> list[dict[str, str]]:
    require(MANIFEST.is_file(), f"Missing gate manifest: {MANIFEST}")
    require(sha256(MANIFEST) == EXPECTED_MANIFEST_SHA256, "Gate manifest identity changed")
    rows = read_csv(MANIFEST)
    require(len(rows) == sum(EXPECTED_WAVE_COUNTS.values()), "Expected 24 gate rows")
    require([int(row["QueueRank"]) for row in rows] == list(range(1, 25)), "Queue rank changed")
    require({row["SourceSha256"] for row in rows} == {EXPECTED_SOURCE_SHA256}, "Source identity changed")
    require({row["ProfileSha256"] for row in rows} == {EXPECTED_PROFILE_SHA256}, "Profile identity changed")
    for wave, expected_count in EXPECTED_WAVE_COUNTS.items():
        require(sum(int(row["Wave"]) == wave for row in rows) == expected_count, f"Wave {wave} shape changed")
    for row in rows:
        config = ROOT / row["PackageConfig"]
        require(config.is_file(), f"Missing config: {config}")
        require(sha256(config) == row["ConfigSha256"], f"Config identity changed: {config.name}")
        require(row["Status"] == "LOCKED_LOCAL_LAUNCH_DISABLED", "Frozen queue status changed")
    return rows


def number(row: dict[str, str], name: str) -> float | None:
    value = row.get(name, "").strip()
    if not value:
        return None
    try:
        parsed = float(value)
    except ValueError:
        return None
    return parsed if math.isfinite(parsed) or math.isinf(parsed) else None


def evaluate_row(manifest_row: dict[str, str], result: dict[str, str]) -> tuple[bool, list[str]]:
    reasons: list[str] = []
    checks = (
        ("NetProfit", "MinNetProfit", ">="),
        ("ProfitFactor", "MinProfitFactor", ">="),
        ("TotalTrades", "MinTrades", ">="),
        ("MaxDrawdownPercent", "MaxDrawdownPercent", "<="),
    )
    for metric, threshold_name, direction in checks:
        actual = number(result, metric)
        threshold = float(manifest_row[threshold_name])
        if actual is None:
            reasons.append(f"{metric}=MISSING")
        elif direction == ">=" and actual < threshold:
            reasons.append(f"{metric}={actual:g}<{threshold:g}")
        elif direction == "<=" and actual > threshold:
            reasons.append(f"{metric}={actual:g}>{threshold:g}")

    optional_checks = (
        ("RecoveryFactor", "MinRecoveryFactor"),
        ("CagrPercent", "MinCagrPercent"),
    )
    for metric, threshold_name in optional_checks:
        threshold = float(manifest_row[threshold_name])
        if threshold <= 0.0:
            continue
        actual = number(result, metric)
        if actual is None:
            reasons.append(f"{metric}=MISSING")
        elif actual < threshold:
            reasons.append(f"{metric}={actual:g}<{threshold:g}")
    return not reasons, reasons


def evaluate_gate(
    manifest: list[dict[str, str]],
    results: list[dict[str, str]],
    launch_locked: bool,
) -> tuple[dict[str, object], list[dict[str, object]]]:
    result_map: dict[str, dict[str, str]] = {}
    duplicate_names: set[str] = set()
    for row in results:
        name = row.get("ExpectedReportName", "")
        if name in result_map:
            duplicate_names.add(name)
        result_map[name] = row
    require(not duplicate_names, f"Duplicate result names: {sorted(duplicate_names)}")

    details: list[dict[str, object]] = []
    passed_rows = 0
    annual_ratio: float | None = None
    for wave in range(1, 6):
        wave_rows = [row for row in manifest if int(row["Wave"]) == wave]
        missing = [row for row in wave_rows if row["ExpectedReportName"] not in result_map]
        unparsed = [
            row for row in wave_rows
            if row["ExpectedReportName"] in result_map
            and result_map[row["ExpectedReportName"]].get("Status") != "PARSED"
        ]
        if missing or unparsed:
            for row in wave_rows:
                result = result_map.get(row["ExpectedReportName"])
                report_status = "MISSING_REPORT" if result is None else result.get("Status", "UNKNOWN")
                details.append(
                    {
                        "QueueRank": row["QueueRank"],
                        "Wave": wave,
                        "ExpectedReportName": row["ExpectedReportName"],
                        "Window": row["Window"],
                        "Model": row["Model"],
                        "ReportStatus": report_status,
                        "GatePass": False,
                        "Reasons": "NOT_EVALUATED_INCOMPLETE_WAVE",
                    }
                )
            prefix = "LOCKED_" if launch_locked else ""
            decision = {
                "Status": f"{prefix}AWAITING_WAVE_{wave:02d}_REPORTS",
                "CurrentWave": wave,
                "PassedRows": passed_rows,
                "TotalRows": len(manifest),
                "NextAction": (
                    f"WAIT_FOR_LAUNCH_UNLOCK_THEN_RUN_WAVE_{wave:02d}"
                    if launch_locked
                    else f"RUN_WAVE_{wave:02d}"
                ),
                "TerminalRejection": False,
                "ExecutableGatePass": False,
                "AnnualToContinuousNetRatio": "",
            }
            return decision, details

        wave_failed = False
        for manifest_row in wave_rows:
            result = result_map[manifest_row["ExpectedReportName"]]
            passed, reasons = evaluate_row(manifest_row, result)
            passed_rows += int(passed)
            wave_failed = wave_failed or not passed
            details.append(
                {
                    "QueueRank": manifest_row["QueueRank"],
                    "Wave": wave,
                    "ExpectedReportName": manifest_row["ExpectedReportName"],
                    "Window": manifest_row["Window"],
                    "Model": manifest_row["Model"],
                    "ReportStatus": result["Status"],
                    "GatePass": passed,
                    "Reasons": "PASS" if passed else ";".join(reasons),
                }
            )
        if wave_failed:
            return (
                {
                    "Status": f"EXECUTABLE_GATE_REJECTED_WAVE_{wave:02d}",
                    "CurrentWave": wave,
                    "PassedRows": passed_rows,
                    "TotalRows": len(manifest),
                    "NextAction": "KEEP_CANDIDATE_UNPROMOTED_AND_DIAGNOSE_REJECTION",
                    "TerminalRejection": True,
                    "ExecutableGatePass": False,
                    "AnnualToContinuousNetRatio": "",
                },
                details,
            )

        if wave == 5:
            annual_net = sum(
                float(result_map[row["ExpectedReportName"]]["NetProfit"])
                for row in wave_rows
            )
            continuous_row = next(
                row for row in manifest
                if int(row["Wave"]) == 4 and row["Role"] == "continuous"
            )
            continuous_net = float(result_map[continuous_row["ExpectedReportName"]]["NetProfit"])
            annual_ratio = annual_net / continuous_net if continuous_net > 0.0 else math.inf
            ratio_pass = ANNUAL_RATIO_MIN <= annual_ratio <= ANNUAL_RATIO_MAX
            details.append(
                {
                    "QueueRank": "AGGREGATE",
                    "Wave": wave,
                    "ExpectedReportName": "annual_to_continuous_consistency",
                    "Window": "2015_2026",
                    "Model": 4,
                    "ReportStatus": "CALCULATED",
                    "GatePass": ratio_pass,
                    "Reasons": (
                        "PASS"
                        if ratio_pass
                        else f"AnnualToContinuousNetRatio={annual_ratio:.4f} outside [{ANNUAL_RATIO_MIN:.2f},{ANNUAL_RATIO_MAX:.2f}]"
                    ),
                }
            )
            if not ratio_pass:
                return (
                    {
                        "Status": "EXECUTABLE_GATE_REJECTED_WAVE_05_CONSISTENCY",
                        "CurrentWave": 5,
                        "PassedRows": passed_rows,
                        "TotalRows": len(manifest),
                        "NextAction": "KEEP_CANDIDATE_UNPROMOTED_AND_DIAGNOSE_RESTART_DIVERGENCE",
                        "TerminalRejection": True,
                        "ExecutableGatePass": False,
                        "AnnualToContinuousNetRatio": round(annual_ratio, 4),
                    },
                    details,
                )

    return (
        {
            "Status": "EXECUTABLE_MT5_GATE_PASS_PENDING_LEDGER_STRESS",
            "CurrentWave": 6,
            "PassedRows": passed_rows,
            "TotalRows": len(manifest),
            "NextAction": "EXPORT_EXECUTABLE_TRADE_LEDGER_AND_RUN_COST_REGIME_STRESS",
            "TerminalRejection": False,
            "ExecutableGatePass": True,
            "AnnualToContinuousNetRatio": round(float(annual_ratio), 4),
        },
        details,
    )


def main() -> int:
    manifest = load_manifest()
    results = read_csv(RESULTS) if RESULTS.is_file() else []
    launch_locked = REPO_LOCK.is_file() or OUTER_LOCK.is_file()
    decision, details = evaluate_gate(manifest, results, launch_locked)
    decision_row = {
        **decision,
        "ReportsPresent": len(results),
        "LaunchLocked": launch_locked,
        "PostHocCollisionScorePromoted": False,
        "ForwardCandidateChanged": False,
        "RealAccountApproved": False,
        "ManifestSha256": sha256(MANIFEST),
        "SourceSha256": EXPECTED_SOURCE_SHA256,
        "ProfileSha256": EXPECTED_PROFILE_SHA256,
    }
    write_csv(EVALUATION_CSV, details)
    write_csv(DECISION_CSV, [decision_row])

    lines = [
        "# RDMC Diversified Repair Executable Gate Decision",
        "",
        f"**Status: {decision['Status']}. No new best, forward substitution, or real-money approval.**",
        "",
        f"- Current wave: `{decision['CurrentWave']}`",
        f"- Parsed reports supplied: `{len(results)}/24`",
        f"- Passed row gates: `{decision['PassedRows']}/24`",
        f"- Launch locked: `{launch_locked}`",
        f"- Next action: `{decision['NextAction']}`",
        f"- Manifest SHA-256: `{sha256(MANIFEST)}`",
        f"- Source SHA-256: `{EXPECTED_SOURCE_SHA256}`",
        f"- Profile SHA-256: `{EXPECTED_PROFILE_SHA256}`",
        "",
        "## Evidence Boundary",
        "",
        "- No report is inferred from a config, static check, or post-hoc component ledger.",
        "- Missing or unparsed reports keep the current wave pending; a failed completed wave rejects later testing.",
        "- Model1 can reject only. Model4 waves must pass before executable trade-ledger stress is admitted.",
        "- Even a five-wave pass is not money-ready: cost stress, order-aware Monte Carlo, broker variation, and valid forward evidence remain required.",
        "- The registered forward candidate and real-account safety lock remain unchanged.",
    ]
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(
        f"{decision['Status']} wave={decision['CurrentWave']} reports={len(results)}/24 "
        f"passed={decision['PassedRows']}/24"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
