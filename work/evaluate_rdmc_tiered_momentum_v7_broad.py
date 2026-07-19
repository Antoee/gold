#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_BROAD_GATE_MANIFEST.csv"
RESULTS = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_BROAD_GATE_RESULTS.csv"
EVALUATION = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_BROAD_GATE_EVALUATION.csv"
DECISION = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_BROAD_DECISION_FIXTURE.csv"
DECISION_MD = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_BROAD_DECISION.md"
EXPECTED_MANIFEST = "2FF02C9BFCA016AB43D059878B7CB16C118A859451B939F6A3D4CB8240E2F3AF"
EXPECTED_SOURCE = "27CAD37CD903032335DA570CDEC75AC39C2EA6BEF04CA264D1586EDC866F6AF6"
EXPECTED_PROFILE = "6E2EF7B031FF30216876E0232A8CE9D6BFC9F7913A863103DC9B12C1A04A100C"
WAVE_COUNTS = {1: 4, 2: 2, 3: 4}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        return []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    require(bool(rows), f"No rows for {path.name}")
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def number(row: dict[str, str], name: str) -> float | None:
    try:
        value = float(row.get(name, ""))
    except ValueError:
        return None
    return value if math.isfinite(value) or math.isinf(value) else None


def row_reasons(spec: dict[str, str], result: dict[str, str]) -> list[str]:
    reasons: list[str] = []
    checks = (
        ("NetProfit", "MinNetProfit", ">="),
        ("ProfitFactor", "MinProfitFactor", ">="),
        ("TotalTrades", "MinTrades", ">="),
        ("MaxDrawdownPercent", "MaxDrawdownPercent", "<="),
        ("RecoveryFactor", "MinRecoveryFactor", ">="),
        ("CagrPercent", "MinCagrPercent", ">="),
    )
    for metric, threshold_name, operation in checks:
        threshold = float(spec[threshold_name])
        if threshold <= 0 and metric in {"RecoveryFactor", "CagrPercent"}:
            continue
        actual = number(result, metric)
        if actual is None:
            reasons.append(f"{metric}=MISSING")
        elif operation == ">=" and actual < threshold:
            reasons.append(f"{metric}={actual:g}<{threshold:g}")
        elif operation == "<=" and actual > threshold:
            reasons.append(f"{metric}={actual:g}>{threshold:g}")
    return reasons


def main() -> int:
    require(MANIFEST.is_file(), "Broad manifest is missing")
    require(sha256(MANIFEST) == EXPECTED_MANIFEST, "Broad manifest identity changed")
    manifest = read_csv(MANIFEST)
    require(len(manifest) == 10, "Expected ten broad-gate rows")
    require([int(row["QueueRank"]) for row in manifest] == list(range(1, 11)), "Queue rank changed")
    require({row["SourceSha256"] for row in manifest} == {EXPECTED_SOURCE}, "Source identity changed")
    require({row["ProfileSha256"] for row in manifest} == {EXPECTED_PROFILE}, "Profile identity changed")
    for wave, count in WAVE_COUNTS.items():
        require(sum(int(row["Wave"]) == wave for row in manifest) == count, f"Wave {wave} shape changed")
    for row in manifest:
        config = ROOT / row["PackageConfig"]
        require(config.is_file() and sha256(config) == row["ConfigSha256"], f"Config identity changed: {config.name}")

    results = read_csv(RESULTS)
    by_name = {row.get("ExpectedReportName", ""): row for row in results}
    require(len(by_name) == len(results), "Duplicate result name")
    require(set(by_name).issubset({row["ExpectedReportName"] for row in manifest}), "Unknown result row")
    details: list[dict[str, object]] = []
    passed_rows = 0
    status = ""
    current_wave = 0
    terminal = False
    next_action = ""

    for wave in range(1, 4):
        specs = [row for row in manifest if int(row["Wave"]) == wave]
        complete = all(
            row["ExpectedReportName"] in by_name
            and by_name[row["ExpectedReportName"]].get("Status") == "PARSED"
            for row in specs
        )
        if not complete:
            status = f"AWAITING_WAVE_{wave:02d}_REPORTS"
            current_wave = wave
            next_action = {
                1: "RUN_FROZEN_MODEL1_BROAD_GATE_ONLY",
                2: "RUN_FROZEN_MODEL4_CRITICAL_GATE_ONLY",
                3: "RUN_FROZEN_MODEL4_BROAD_GATE_ONLY",
            }[wave]
            for spec in specs:
                actual = by_name.get(spec["ExpectedReportName"])
                details.append(
                    {
                        "QueueRank": spec["QueueRank"],
                        "Wave": wave,
                        "Window": spec["Window"],
                        "Model": spec["Model"],
                        "GatePass": False,
                        "Reasons": "REPORT_MISSING_OR_UNPARSED",
                        "NetProfit": "" if actual is None else actual.get("NetProfit", ""),
                        "ProfitFactor": "" if actual is None else actual.get("ProfitFactor", ""),
                        "TotalTrades": "" if actual is None else actual.get("TotalTrades", ""),
                        "MaxDrawdownPercent": "" if actual is None else actual.get("MaxDrawdownPercent", ""),
                        "RecoveryFactor": "" if actual is None else actual.get("RecoveryFactor", ""),
                    }
                )
            break

        failed = False
        for spec in specs:
            actual = by_name[spec["ExpectedReportName"]]
            reasons = []
            if actual.get("SourceSha256") != EXPECTED_SOURCE:
                reasons.append("SOURCE_IDENTITY_MISMATCH")
            if actual.get("ProfileSha256") != EXPECTED_PROFILE:
                reasons.append("PROFILE_IDENTITY_MISMATCH")
            reasons.extend(row_reasons(spec, actual))
            passed = not reasons
            passed_rows += int(passed)
            failed = failed or not passed
            details.append(
                {
                    "QueueRank": spec["QueueRank"],
                    "Wave": wave,
                    "Window": spec["Window"],
                    "Model": spec["Model"],
                    "GatePass": passed,
                    "Reasons": "PASS" if passed else ";".join(reasons),
                    "NetProfit": actual.get("NetProfit", ""),
                    "ProfitFactor": actual.get("ProfitFactor", ""),
                    "TotalTrades": actual.get("TotalTrades", ""),
                    "MaxDrawdownPercent": actual.get("MaxDrawdownPercent", ""),
                    "RecoveryFactor": actual.get("RecoveryFactor", ""),
                }
            )
        if failed:
            status = f"BROAD_GATE_REJECTED_WAVE_{wave:02d}"
            current_wave = wave
            terminal = True
            next_action = "REWRITE_STRATEGY_CODE_AND_RESTART_FROM_OLDER_TRAINING"
            break
    else:
        status = "BROAD_MODEL4_GATE_PASS_PENDING_ANNUAL_AND_STRESS"
        current_wave = 0
        next_action = "FREEZE_ANNUAL_MODEL4_RESTART_AND_LEDGER_STRESS_GATES"

    launch_locked = (ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock").is_file() or (
        ROOT.parent / "MT5_LOCAL_LAUNCH_DISABLED.lock"
    ).is_file()
    decision = {
        "Status": status,
        "CurrentWave": current_wave,
        "PassedRows": passed_rows,
        "TotalRows": 10,
        "ReportsPresent": len(results),
        "TerminalRejection": terminal,
        "BroadGatePass": status == "BROAD_MODEL4_GATE_PASS_PENDING_ANNUAL_AND_STRESS",
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
        "# RDMC Tiered Momentum v7 Broad Decision",
        "",
        f"**Status: {status}. No forward substitution or real-money approval.**",
        "",
        f"- Reports: `{len(results)}/10`",
        f"- Passed rows: `{passed_rows}/10`",
        f"- Current wave: `{current_wave}`",
        f"- Launch locked: `{launch_locked}`",
        f"- Next action: `{next_action}`",
        f"- Source SHA-256: `{EXPECTED_SOURCE}`",
        f"- Profile SHA-256: `{EXPECTED_PROFILE}`",
        f"- Manifest SHA-256: `{EXPECTED_MANIFEST}`",
        "",
        "| Wave | Model | Window | Pass | Net | PF | Trades | Drawdown | Recovery | Reasons |",
        "|---:|---:|---|---:|---:|---:|---:|---:|---:|---|",
    ]
    lines.extend(
        f"| {row['Wave']} | {row['Model']} | {row['Window']} | {row['GatePass']} | {row['NetProfit']} | {row['ProfitFactor']} | {row['TotalTrades']} | {row['MaxDrawdownPercent']}% | {row['RecoveryFactor']} | {row['Reasons']} |"
        for row in details
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"{status} reports={len(results)}/10 passed={passed_rows}/10")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
