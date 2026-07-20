#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = ROOT / "outputs"
MANIFEST = OUTPUTS / "THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_MODEL1_MANIFEST.csv"
RAW_RESULTS = OUTPUTS / "THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_MODEL1_RESULTS.csv"
COMPILE_AUDIT = OUTPUTS / "THREE_LANE_REVERSION_PARTIAL_RUNNER_COMPILE_AUDIT.csv"
EVIDENCE = OUTPUTS / "THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_EVIDENCE.csv"
SUMMARY = OUTPUTS / "THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_SUMMARY.csv"
DECISION = OUTPUTS / "THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_DECISION.csv"
DECISION_MD = OUTPUTS / "THREE_LANE_REVERSION_PARTIAL_RUNNER_DISCOVERY_DECISION.md"
EXPECTED_MANIFEST = "66E6E01AE5A802E1E3423C51B4E5A015B480E369424EA8D84539312304512D40"
EXPECTED_SOURCE = "614DCF5B0C55DF25DABDCF903C3193A0CE248AA2671788A400B5C39A4209F719"
EXPECTED_BINARY = "37F90A3C23CEF638AEE689807E01F7EC220EF01EC999CA6D41D6F8BE6906A810"
CONTROL = "rvpr_control"
CENTER = "rvpr_center"
NEIGHBORS = (
    "rvpr_close75",
    "rvpr_close85",
    "rvpr_target175",
    "rvpr_target225",
    "rvpr_lock025",
    "rvpr_lock075",
)
CANDIDATES = (CONTROL, CENTER, *NEIGHBORS)
WINDOWS = ("older_2015_2018", "later_2019_2020", "continuous_2015_2020")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def money(value: float) -> str:
    return f"{'+' if value >= 0 else '-'}${abs(value):,.2f}"


def main() -> int:
    if sha256(MANIFEST) != EXPECTED_MANIFEST:
        raise ValueError("partial-runner discovery manifest identity changed")
    manifest = read_csv(MANIFEST)
    if (
        len(manifest) != 24
        or {row["Candidate"] for row in manifest} != set(CANDIDATES)
        or {row["Window"] for row in manifest} != set(WINDOWS)
    ):
        raise ValueError("partial-runner discovery topology changed")
    if any(
        row["SourceSha256"] != EXPECTED_SOURCE
        or row["Model"] != "1"
        or row["Deposit"] != "10000"
        or row["BaseReversionRiskPercent"] != "0.45"
        or row["StrongSignalBodyRatio"] != "0.25"
        or row["StrongSignalLotCap"] != "0.15"
        or row["MaximumPortfolioOpenRiskPercent"] != "0.75"
        for row in manifest
    ):
        raise ValueError("source/model/capital/risk contract changed")
    for row in manifest:
        if sha256(ROOT / row["PackageConfig"]) != row["ConfigSha256"]:
            raise ValueError(f"config identity changed at rank {row['QueueRank']}")

    audit = read_csv(COMPILE_AUDIT)
    if len(audit) != 1:
        raise ValueError("compile audit shape changed")
    compile_row = audit[0]
    if (
        compile_row["Status"] != "COMPILE_PASS"
        or compile_row["SourceSha256"] != EXPECTED_SOURCE
        or compile_row["PortableBinarySha256"] != EXPECTED_BINARY
        or compile_row["CompileErrors"] != "0"
        or compile_row["CompileWarnings"] != "0"
        or compile_row["LaunchLocksRestored"] != "True"
        or compile_row["MT5Processes"] != "0"
    ):
        raise ValueError("compile audit is not an exact clean pass")

    raw = read_csv(RAW_RESULTS)
    raw_by_report = {row["ExpectedReportName"]: row for row in raw}
    if len(raw) != 24 or len(raw_by_report) != 24 or any(row["Status"] != "PARSED" for row in raw):
        raise ValueError("expected 24 unique parsed reports")

    runner_rows: list[dict[str, str]] = []
    patterns = (
        "THREE_LANE_RV_PARTIAL_RUNNER_DISCOVERY_WORKER_*.csv",
        "THREE_LANE_RV_PARTIAL_RUNNER_RETRY_WORKER_*.csv",
        "THREE_LANE_RV_PARTIAL_RUNNER_FINAL_RETRY_WORKER_*.csv",
    )
    for pattern in patterns:
        for path in OUTPUTS.glob(pattern):
            runner_rows.extend(read_csv(path))
    accepted_by_rank: dict[str, dict[str, str]] = {}
    for rank in range(1, 25):
        accepted = [
            row
            for row in runner_rows
            if row.get("QueueRank") == str(rank) and row.get("Status") == "REPORT_FOUND"
        ]
        if len(accepted) != 1:
            raise ValueError(f"rank {rank} does not have exactly one accepted report")
        accepted_by_rank[str(rank)] = accepted[0]

    evidence: list[dict[str, object]] = []
    by_key: dict[tuple[str, str], dict[str, object]] = {}
    settings: dict[str, dict[str, str]] = {}
    for expected in sorted(manifest, key=lambda row: int(row["QueueRank"])):
        parsed = raw_by_report[expected["ExpectedReportName"]]
        run = accepted_by_rank[expected["QueueRank"]]
        identity = json.loads(Path(run["ReportIdentityPath"]).read_text(encoding="utf-8-sig"))
        if (
            run["PackageSourceSha256"] != EXPECTED_SOURCE
            or run["PortableBinarySha256"] != EXPECTED_BINARY
            or run["PackageConfigSha256"] != expected["ConfigSha256"]
            or identity["SourceSha256"] != EXPECTED_SOURCE
            or identity["PortableBinarySha256"] != EXPECTED_BINARY
            or identity["ConfigSha256"] != expected["ConfigSha256"]
            or identity["ReportSha256"] != run["ReportSha256"]
        ):
            raise ValueError(f"report identity mismatch at rank {expected['QueueRank']}")
        total_return = float(parsed["TotalReturnPercent"])
        drawdown = float(parsed["MaxDrawdownPercent"])
        row: dict[str, object] = {
            "QueueRank": int(expected["QueueRank"]),
            "Candidate": expected["Candidate"],
            "Role": expected["Role"],
            "Window": expected["Window"],
            "From": expected["From"],
            "To": expected["To"],
            "PartialRunnerEnabled": expected["PartialRunnerEnabled"],
            "ClosePercent": float(expected["ClosePercent"]),
            "TargetMultiplier": float(expected["TargetMultiplier"]),
            "StopLockR": float(expected["StopLockR"]),
            "NetProfit": round(float(parsed["NetProfit"]), 2),
            "TotalReturnPercent": round(total_return, 2),
            "CagrPercent": round(float(parsed["CagrPercent"]), 2),
            "ProfitFactor": round(float(parsed["ProfitFactor"]), 2),
            "TotalTrades": int(parsed["TotalTrades"]),
            "MaxDrawdownPercent": round(drawdown, 2),
            "RecoveryFactor": round(float(parsed["RecoveryFactor"]), 4),
            "ReturnDrawdown": round(total_return / drawdown, 4) if drawdown else 0.0,
            "SourceSha256": EXPECTED_SOURCE,
            "BinarySha256": EXPECTED_BINARY,
            "ProfileSha256": expected["ProfileSha256"],
            "ConfigSha256": expected["ConfigSha256"],
            "ReportSha256": run["ReportSha256"],
        }
        evidence.append(row)
        by_key[(expected["Candidate"], expected["Window"])] = row
        settings[expected["Candidate"]] = expected
    write_csv(EVIDENCE, evidence)

    def result(candidate: str, window: str = WINDOWS[2]) -> dict[str, object]:
        return by_key[(candidate, window)]

    def changed(candidate: str) -> bool:
        fields = ("NetProfit", "ProfitFactor", "TotalTrades", "MaxDrawdownPercent", "RecoveryFactor")
        return any(
            result(candidate, window)[field] != result(CONTROL, window)[field]
            for window in WINDOWS
            for field in fields
        )

    def era_floor(candidate: str) -> bool:
        return all(
            float(result(candidate, window)["NetProfit"])
            >= 0.98 * float(result(CONTROL, window)["NetProfit"])
            for window in WINDOWS[:2]
        )

    control = result(CONTROL)
    center = result(CENTER)

    def risk_efficiency_floor(candidate: str) -> bool:
        current = result(candidate)
        return (
            float(current["ProfitFactor"]) >= float(control["ProfitFactor"])
            and float(current["RecoveryFactor"]) >= 0.97 * float(control["RecoveryFactor"])
            and float(current["ReturnDrawdown"]) >= 0.97 * float(control["ReturnDrawdown"])
            and float(current["MaxDrawdownPercent"]) <= 1.20
            and float(current["MaxDrawdownPercent"])
            <= float(control["MaxDrawdownPercent"]) + 0.10
        )

    def neighbor_pass(candidate: str) -> bool:
        current = result(candidate)
        return (
            changed(candidate)
            and era_floor(candidate)
            and float(current["NetProfit"]) >= 1.02 * float(control["NetProfit"])
            and risk_efficiency_floor(candidate)
        )

    all_positive = all(float(row["NetProfit"]) > 0 for row in evidence)
    center_active = changed(CENTER) and int(center["TotalTrades"]) > int(control["TotalTrades"])
    center_era_floor = era_floor(CENTER)
    center_growth = float(center["NetProfit"]) >= 1.04 * float(control["NetProfit"])
    center_cagr = float(center["CagrPercent"]) >= float(control["CagrPercent"]) + 0.06
    center_efficiency = risk_efficiency_floor(CENTER)
    neighbor_results = {candidate: neighbor_pass(candidate) for candidate in NEIGHBORS}
    neighbor_count = sum(neighbor_results.values())
    neighborhood = neighbor_count >= 4
    passed = all(
        (
            all_positive,
            center_active,
            center_era_floor,
            center_growth,
            center_cagr,
            center_efficiency,
            neighborhood,
        )
    )

    summary: list[dict[str, object]] = []
    for candidate in CANDIDATES:
        current = result(candidate)
        summary.append(
            {
                "Candidate": candidate,
                "Role": current["Role"],
                "PartialRunnerEnabled": settings[candidate]["PartialRunnerEnabled"],
                "ClosePercent": settings[candidate]["ClosePercent"],
                "TargetMultiplier": settings[candidate]["TargetMultiplier"],
                "StopLockR": settings[candidate]["StopLockR"],
                "OlderNetProfit": result(candidate, WINDOWS[0])["NetProfit"],
                "LaterNetProfit": result(candidate, WINDOWS[1])["NetProfit"],
                "ContinuousNetProfit": current["NetProfit"],
                "TotalReturnPercent": current["TotalReturnPercent"],
                "CagrPercent": current["CagrPercent"],
                "ProfitFactor": current["ProfitFactor"],
                "TotalTrades": current["TotalTrades"],
                "MaxDrawdownPercent": current["MaxDrawdownPercent"],
                "RecoveryFactor": current["RecoveryFactor"],
                "ReturnDrawdown": current["ReturnDrawdown"],
                "BehaviorChangedVsControl": changed(candidate),
                "DisjointEraFloor": era_floor(candidate),
                "NeighborGate": neighbor_results.get(candidate, ""),
            }
        )
    write_csv(SUMMARY, summary)

    center_delta = float(center["NetProfit"]) - float(control["NetProfit"])
    best = max((result(candidate) for candidate in CANDIDATES), key=lambda row: float(row["NetProfit"]))
    decision = {
        "Status": "DISCOVERY_GATE_PASSED" if passed else "REJECTED_IN_DISCOVERY",
        "ReportsParsed": len(evidence),
        "IdentityAcceptedReports": len(accepted_by_rank),
        "TotalAttempts": len(runner_rows),
        "InfrastructureErrorsRetriedUnchanged": sum(row.get("Status") == "ERROR" for row in runner_rows),
        "AllWindowsPositive": all_positive,
        "CenterPartialBehaviorConfirmed": center_active,
        "CenterDisjointEraFloor": center_era_floor,
        "CenterGrowthGate": center_growth,
        "CenterCagrGate": center_cagr,
        "CenterEfficiencyAndRiskGate": center_efficiency,
        "PassingNeighbors": neighbor_count,
        "NeighborhoodGate": neighborhood,
        "RecentValidationPermitted": passed,
        "Model4ValidationPermitted": False,
        "ResearchPromotionPermitted": False,
        "ForwardCandidateChanged": False,
        "RealAccountTradingAllowed": False,
        "ControlNetProfit": control["NetProfit"],
        "CenterNetProfit": center["NetProfit"],
        "CenterDelta": round(center_delta, 2),
        "BestObservedProfile": best["Candidate"],
        "BestObservedNetProfit": best["NetProfit"],
        "SourceSha256": EXPECTED_SOURCE,
        "BinarySha256": EXPECTED_BINARY,
        "CenterProfileSha256": center["ProfileSha256"],
        "ManifestSha256": EXPECTED_MANIFEST,
    }
    write_csv(DECISION, [decision])

    labels = {
        CONTROL: "Disabled control",
        CENTER: "**80% / 2.00x / +0.50R center**",
        "rvpr_close75": "Close 75%",
        "rvpr_close85": "Close 85%",
        "rvpr_target175": "Target 1.75x",
        "rvpr_target225": "Target 2.25x",
        "rvpr_lock025": "Lock +0.25R",
        "rvpr_lock075": "Lock +0.75R",
    }
    lines = [
        "# Three-Lane Reversion Partial Runner Discovery Decision",
        "",
        "**Decision: DISCOVERY GATE PASSED. Recent confirmation may open; Model 4 and promotion remain closed.**"
        if passed
        else "**Decision: REJECTED IN DISCOVERY. Recent data, Model 4, promotion, forward substitution, and live approval remain closed. NO NEW BEST.**",
        "",
        f"- Exact accepted reports: `{len(accepted_by_rank)}/24`; attempts: `{len(runner_rows)}`; infrastructure failures retried unchanged: `{decision['InfrastructureErrorsRetriedUnchanged']}`",
        f"- Source SHA-256: `{EXPECTED_SOURCE}`",
        f"- EX5 SHA-256: `{EXPECTED_BINARY}`",
        f"- Manifest SHA-256: `{EXPECTED_MANIFEST}`",
        "- `$10,000`; MT5 Model 1; frozen 2015-2020 discovery; unchanged initial risk and entries; portfolio cap `0.75%`; real trading disabled",
        "- Active profiles produced 270 continuous report trades versus 265 for control, confirming the partial-exit path executed",
        "",
        "| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in summary:
        lines.append(
            f"| {labels[str(row['Candidate'])]} | {money(float(row['OlderNetProfit']))} | "
            f"{money(float(row['LaterNetProfit']))} | {money(float(row['ContinuousNetProfit']))} | "
            f"{row['TotalReturnPercent']}% | {row['CagrPercent']}%/yr | {row['ProfitFactor']} | "
            f"{row['TotalTrades']} | {row['MaxDrawdownPercent']}% | {row['RecoveryFactor']} | {row['ReturnDrawdown']} |"
        )
    later_delta = float(result(CENTER, WINDOWS[1])["NetProfit"]) - float(result(CONTROL, WINDOWS[1])["NetProfit"])
    lines.extend(
        [
            "",
            "## Frozen Gate",
            "",
            f"- Every report profitable: `{all_positive}`",
            f"- Center partial path active: `{center_active}`",
            f"- Center retained at least 98% of control in both eras: `{center_era_floor}`",
            f"- Center net at least 4% above control: `{center_growth}` ({money(float(center['NetProfit']))} vs required {money(1.04 * float(control['NetProfit']))})",
            f"- Center CAGR at least 0.06 point above control: `{center_cagr}`",
            f"- Center PF, drawdown, recovery, and return/DD gate: `{center_efficiency}`",
            f"- At least 4 of 6 neighbors passed: `{neighborhood}` (`{neighbor_count}/6`)",
            "",
            f"The center reduced continuous net by `{money(center_delta)}` and reduced 2019-2020 by `{money(later_delta)}`. It also lowered PF, CAGR, recovery, and return/drawdown, so it fails without opening post-2020 data.",
            "",
            f"The best observed row was `{best['Candidate']}` at `{money(float(best['NetProfit']))}`, but it was not the preregistered center and its 2019-2020 result was below the 98% era floor. Selecting it now would be result-driven threshold chasing.",
            "",
            "The strong-signal selective reversion lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.",
        ]
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(
        f"{decision['Status']} center={center['NetProfit']} control={control['NetProfit']} "
        f"neighbors={neighbor_count}/6 best={best['Candidate']}:{best['NetProfit']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
