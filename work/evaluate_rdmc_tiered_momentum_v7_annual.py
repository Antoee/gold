#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_ANNUAL_GATE_MANIFEST.csv"
RESULTS = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_ANNUAL_GATE_RESULTS.csv"
BROAD_RESULTS = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_BROAD_GATE_RESULTS.csv"
EVALUATION = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_ANNUAL_GATE_EVALUATION.csv"
DECISION = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_ANNUAL_DECISION_FIXTURE.csv"
DECISION_MD = ROOT / "outputs" / "RDMC_TIERED_MOMENTUM_V7_ANNUAL_DECISION.md"
EXPECTED_MANIFEST = "F36D6959AF5220CD2545CE0C277EE3A917CCAEA3E1C2D075316E944CD0A25B19"
EXPECTED_SOURCE = "27CAD37CD903032335DA570CDEC75AC39C2EA6BEF04CA264D1586EDC866F6AF6"
EXPECTED_PROFILE = "6E2EF7B031FF30216876E0232A8CE9D6BFC9F7913A863103DC9B12C1A04A100C"


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


def reasons_for(spec: dict[str, str], result: dict[str, str]) -> list[str]:
    reasons: list[str] = []
    checks = (
        ("NetProfit", "MinNetProfit", ">="),
        ("ProfitFactor", "MinProfitFactor", ">="),
        ("TotalTrades", "MinTrades", ">="),
        ("MaxDrawdownPercent", "MaxDrawdownPercent", "<="),
    )
    for metric, threshold_name, operation in checks:
        try:
            actual = float(result[metric])
        except (KeyError, ValueError):
            reasons.append(f"{metric}=MISSING")
            continue
        threshold = float(spec[threshold_name])
        if operation == ">=" and actual < threshold:
            reasons.append(f"{metric}={actual:g}<{threshold:g}")
        elif operation == "<=" and actual > threshold:
            reasons.append(f"{metric}={actual:g}>{threshold:g}")
    return reasons


def main() -> int:
    require(MANIFEST.is_file() and sha256(MANIFEST) == EXPECTED_MANIFEST, "Annual manifest identity changed")
    manifest = read_csv(MANIFEST)
    require(len(manifest) == 12, "Expected twelve annual rows")
    require([int(row["QueueRank"]) for row in manifest] == list(range(1, 13)), "Annual queue rank changed")
    require([row["Wave"] for row in manifest] == ["1", "1"] + ["2"] * 10, "Annual wave shape changed")
    require({row["SourceSha256"] for row in manifest} == {EXPECTED_SOURCE}, "Annual source identity changed")
    require({row["ProfileSha256"] for row in manifest} == {EXPECTED_PROFILE}, "Annual profile identity changed")
    for row in manifest:
        config = ROOT / row["PackageConfig"]
        require(config.is_file() and sha256(config) == row["ConfigSha256"], f"Annual config changed: {config.name}")

    results = read_csv(RESULTS)
    by_name = {row.get("ExpectedReportName", ""): row for row in results}
    require(len(by_name) == len(results), "Duplicate annual result")
    require(set(by_name).issubset({row["ExpectedReportName"] for row in manifest}), "Unknown annual result")
    details: list[dict[str, object]] = []
    passed_rows = 0
    status = ""
    current_wave = 0
    terminal = False
    next_action = ""
    ratio: float | str = "not_evaluated"

    for wave in (1, 2):
        specs = [row for row in manifest if int(row["Wave"]) == wave]
        complete = all(
            row["ExpectedReportName"] in by_name
            and by_name[row["ExpectedReportName"]].get("Status") == "PARSED"
            for row in specs
        )
        if not complete:
            status = f"AWAITING_WAVE_{wave:02d}_REPORTS"
            current_wave = wave
            next_action = "RUN_FROZEN_2017_AND_2025_RESTARTS_ONLY" if wave == 1 else "RUN_REMAINING_FROZEN_ANNUAL_RESTARTS"
            for spec in specs:
                actual = by_name.get(spec["ExpectedReportName"])
                details.append(
                    {
                        "QueueRank": spec["QueueRank"],
                        "Wave": wave,
                        "Window": spec["Window"],
                        "GatePass": False,
                        "Reasons": "REPORT_MISSING_OR_UNPARSED",
                        "NetProfit": "" if actual is None else actual.get("NetProfit", ""),
                        "ProfitFactor": "" if actual is None else actual.get("ProfitFactor", ""),
                        "TotalTrades": "" if actual is None else actual.get("TotalTrades", ""),
                        "MaxDrawdownPercent": "" if actual is None else actual.get("MaxDrawdownPercent", ""),
                    }
                )
            break

        failed = False
        for spec in specs:
            actual = by_name[spec["ExpectedReportName"]]
            reasons: list[str] = []
            if actual.get("SourceSha256") != EXPECTED_SOURCE:
                reasons.append("SOURCE_IDENTITY_MISMATCH")
            if actual.get("ProfileSha256") != EXPECTED_PROFILE:
                reasons.append("PROFILE_IDENTITY_MISMATCH")
            reasons.extend(reasons_for(spec, actual))
            passed = not reasons
            failed = failed or not passed
            passed_rows += int(passed)
            details.append(
                {
                    "QueueRank": spec["QueueRank"],
                    "Wave": wave,
                    "Window": spec["Window"],
                    "GatePass": passed,
                    "Reasons": "PASS" if passed else ";".join(reasons),
                    "NetProfit": actual.get("NetProfit", ""),
                    "ProfitFactor": actual.get("ProfitFactor", ""),
                    "TotalTrades": actual.get("TotalTrades", ""),
                    "MaxDrawdownPercent": actual.get("MaxDrawdownPercent", ""),
                }
            )
        if failed:
            status = f"ANNUAL_GATE_REJECTED_WAVE_{wave:02d}"
            current_wave = wave
            terminal = True
            next_action = "REWRITE_CROSS_YEAR_ROBUSTNESS_WITHOUT_POSTHOC_CALENDAR_BLOCKS"
            break
    else:
        broad_rows = read_csv(BROAD_RESULTS)
        continuous = [
            row for row in broad_rows
            if row.get("Window") == "continuous_2015_2026" and row.get("Model") == "4"
        ]
        require(len(continuous) == 1 and continuous[0].get("SourceSha256") == EXPECTED_SOURCE, "Broad continuous evidence changed")
        annual_net = sum(float(row["NetProfit"]) for row in results)
        continuous_net = float(continuous[0]["NetProfit"])
        ratio = round(annual_net / continuous_net, 4)
        if not 0.75 <= ratio <= 1.25:
            status = "ANNUAL_GATE_REJECTED_RESTART_CONSISTENCY"
            current_wave = 2
            terminal = True
            next_action = "REWRITE_RESTART_STATE_OR_PATH_DEPENDENCE"
        else:
            status = "ANNUAL_MODEL4_GATE_PASS_PENDING_LEDGER_STRESS"
            current_wave = 0
            next_action = "RUN_IDENTITY_BOUND_COST_AND_MONTE_CARLO_STRESS"

    launch_locked = (ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock").is_file() or (ROOT.parent / "MT5_LOCAL_LAUNCH_DISABLED.lock").is_file()
    decision = {
        "Status": status,
        "CurrentWave": current_wave,
        "PassedRows": passed_rows,
        "TotalRows": 12,
        "ReportsPresent": len(results),
        "TerminalRejection": terminal,
        "AnnualGatePass": status == "ANNUAL_MODEL4_GATE_PASS_PENDING_LEDGER_STRESS",
        "AnnualToContinuousNetRatio": ratio,
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
        "# RDMC Tiered Momentum v7 Annual Decision",
        "",
        f"**Status: {status}. No forward substitution or real-money approval.**",
        "",
        f"- Reports: `{len(results)}/12`",
        f"- Passed rows: `{passed_rows}/12`",
        f"- Current wave: `{current_wave}`",
        f"- Annual/continuous net ratio: `{ratio}`",
        f"- Launch locked: `{launch_locked}`",
        f"- Next action: `{next_action}`",
        "",
        "| Wave | Year | Pass | Net | PF | Trades | Drawdown | Reasons |",
        "|---:|---|---:|---:|---:|---:|---:|---|",
    ]
    lines.extend(
        f"| {row['Wave']} | {row['Window']} | {row['GatePass']} | {row['NetProfit']} | {row['ProfitFactor']} | {row['TotalTrades']} | {row['MaxDrawdownPercent']}% | {row['Reasons']} |"
        for row in details
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"{status} reports={len(results)}/12 passed={passed_rows}/12")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
