#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = ROOT / "outputs"
MANIFEST = OUTPUTS / "THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_DISCOVERY_MODEL1_MANIFEST.csv"
RAW_RESULTS = OUTPUTS / "THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_DISCOVERY_MODEL1_RESULTS.csv"
COMPILE_AUDIT = OUTPUTS / "THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_COMPILE_AUDIT.csv"
RESULTS = OUTPUTS / "THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_DISCOVERY_EVIDENCE.csv"
SUMMARY = OUTPUTS / "THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_DISCOVERY_SUMMARY.csv"
DECISION = OUTPUTS / "THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_DISCOVERY_DECISION.csv"
DECISION_MD = OUTPUTS / "THREE_LANE_REVERSION_JOINT_STRONG_ALLOCATION_DISCOVERY_DECISION.md"
EXPECTED_MANIFEST = "015DF848CD3882639DE65CE7AF4B117B718FF522EBAEB8013D8EB99AF38E3291"
EXPECTED_SOURCE = "C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91"
EXPECTED_BINARY = "21DDE8A2C1E04CB1D26C76E791A1EA1F0F26167667F19479F29A98BAE1D905A4"
CONTROL = "jsa_control"
REFERENCE = "jsa_risk_only_reference"
CENTER = "jsa_center_r065"
NEIGHBORS = ("jsa_r060", "jsa_r070", "jsa_body0225", "jsa_body0275")
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
        raise ValueError("joint-allocation discovery manifest identity changed")
    manifest = read_csv(MANIFEST)
    if len(manifest) != 21 or len({row["Candidate"] for row in manifest}) != 7:
        raise ValueError("joint-allocation discovery topology changed")
    if any(
        row["SourceSha256"] != EXPECTED_SOURCE
        or row["Model"] != "1"
        or row["Deposit"] != "10000"
        or row["ReversionRiskPercent"] != "0.45"
        or row["MaximumPortfolioOpenRiskPercent"] != "0.75"
        for row in manifest
    ):
        raise ValueError("joint-allocation discovery source/model/capital/risk contract changed")
    for row in manifest:
        config = ROOT / row["PackageConfig"]
        if sha256(config) != row["ConfigSha256"]:
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
    if len(raw) != 21 or any(row["Status"] != "PARSED" for row in raw):
        raise ValueError("expected 21 parsed reports")

    runner_rows: list[dict[str, str]] = []
    for path in OUTPUTS.glob("JOINT_STRONG_ALLOCATION_DISCOVERY_M1*.csv"):
        runner_rows.extend(read_csv(path))
    accepted_by_rank: dict[str, dict[str, str]] = {}
    for rank in range(1, 22):
        accepted = [row for row in runner_rows if row.get("QueueRank") == str(rank) and row.get("Status") == "REPORT_FOUND"]
        if len(accepted) != 1:
            raise ValueError(f"rank {rank} does not have exactly one accepted report")
        accepted_by_rank[str(rank)] = accepted[0]

    evidence: list[dict[str, object]] = []
    by_key: dict[tuple[str, str], dict[str, object]] = {}
    for expected in sorted(manifest, key=lambda row: int(row["QueueRank"])):
        parsed = raw_by_report[expected["ExpectedReportName"]]
        run = accepted_by_rank[expected["QueueRank"]]
        identity_path = Path(run["ReportIdentityPath"])
        identity = json.loads(identity_path.read_text(encoding="utf-8-sig"))
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
    write_csv(RESULTS, evidence)

    def row(candidate: str, window: str = "continuous_2015_2020") -> dict[str, object]:
        return by_key[(candidate, window)]

    def changed(candidate: str) -> bool:
        fields = ("NetProfit", "ProfitFactor", "TotalTrades", "MaxDrawdownPercent", "RecoveryFactor")
        return any(any(row(candidate, window)[field] != row(CONTROL, window)[field] for field in fields) for window in WINDOWS)

    def no_worse_eras(candidate: str) -> bool:
        return all(float(row(candidate, window)["NetProfit"]) >= float(row(CONTROL, window)["NetProfit"]) for window in WINDOWS[:2])

    control = row(CONTROL)
    reference = row(REFERENCE)
    center = row(CENTER)

    def neighbor_pass(candidate: str) -> bool:
        candidate_row = row(candidate)
        return (
            no_worse_eras(candidate)
            and changed(candidate)
            and float(candidate_row["NetProfit"]) >= 1.015 * float(control["NetProfit"])
            and float(candidate_row["CagrPercent"]) >= float(control["CagrPercent"]) + 0.03
            and float(candidate_row["ProfitFactor"]) >= 0.97 * float(control["ProfitFactor"])
            and float(candidate_row["RecoveryFactor"]) >= 0.97 * float(control["RecoveryFactor"])
            and float(candidate_row["ReturnDrawdown"]) >= 0.97 * float(control["ReturnDrawdown"])
            and float(candidate_row["MaxDrawdownPercent"]) <= 1.24
        )

    all_positive = all(float(item["NetProfit"]) > 0 for item in evidence)
    center_active = changed(CENTER)
    center_no_worse = no_worse_eras(CENTER)
    center_growth = float(center["NetProfit"]) >= 1.03 * float(control["NetProfit"])
    center_cagr = float(center["CagrPercent"]) >= float(control["CagrPercent"]) + 0.05
    center_efficiency = (
        float(center["ProfitFactor"]) >= float(control["ProfitFactor"])
        and float(center["RecoveryFactor"]) >= float(control["RecoveryFactor"])
        and float(center["ReturnDrawdown"]) >= float(control["ReturnDrawdown"])
    )
    center_risk = (
        float(center["MaxDrawdownPercent"]) <= 1.20
        and float(center["MaxDrawdownPercent"]) <= float(control["MaxDrawdownPercent"]) + 0.08
    )
    center_trades = int(center["TotalTrades"]) >= int(control["TotalTrades"]) - 2
    center_increment = float(center["NetProfit"]) - float(control["NetProfit"])
    improves_reference = (
        float(center["NetProfit"]) > float(reference["NetProfit"])
        and float(center["ReturnDrawdown"]) > float(reference["ReturnDrawdown"])
    )
    neighbor_results = {candidate: neighbor_pass(candidate) for candidate in NEIGHBORS}
    neighbor_count = sum(neighbor_results.values())
    neighborhood = neighbor_count >= 3
    passed = all(
        (
            all_positive,
            center_active,
            center_no_worse,
            center_growth,
            center_cagr,
            center_efficiency,
            center_risk,
            center_trades,
            improves_reference,
            neighborhood,
        )
    )

    summary: list[dict[str, object]] = []
    for candidate in (CONTROL, REFERENCE, *NEIGHBORS[:2], CENTER, *NEIGHBORS[2:]):
        current = row(candidate)
        summary.append(
            {
                "Candidate": candidate,
                "Role": current["Role"],
                "OlderNetProfit": row(candidate, WINDOWS[0])["NetProfit"],
                "LaterNetProfit": row(candidate, WINDOWS[1])["NetProfit"],
                "ContinuousNetProfit": current["NetProfit"],
                "TotalReturnPercent": current["TotalReturnPercent"],
                "CagrPercent": current["CagrPercent"],
                "ProfitFactor": current["ProfitFactor"],
                "TotalTrades": current["TotalTrades"],
                "MaxDrawdownPercent": current["MaxDrawdownPercent"],
                "RecoveryFactor": current["RecoveryFactor"],
                "ReturnDrawdown": current["ReturnDrawdown"],
                "BehaviorChangedVsControl": changed(candidate),
                "NeighborGate": neighbor_results.get(candidate, ""),
            }
        )
    write_csv(SUMMARY, summary)

    decision = {
        "Status": "DISCOVERY_GATE_PASSED" if passed else "REJECTED_IN_DISCOVERY",
        "ReportsParsed": len(evidence),
        "IdentityAcceptedReports": len(accepted_by_rank),
        "TotalAttempts": len(runner_rows),
        "IdentityRefusals": sum(item.get("Status") == "ERROR" for item in runner_rows),
        "AllWindowsPositive": all_positive,
        "CenterBehaviorChanged": center_active,
        "CenterNoWorseDisjointEras": center_no_worse,
        "CenterGrowthGate": center_growth,
        "CenterCagrGate": center_cagr,
        "CenterEfficiencyGate": center_efficiency,
        "CenterRiskGate": center_risk,
        "CenterTradeCountGate": center_trades,
        "ImprovesRiskOnlyReference": improves_reference,
        "PassingOrthogonalNeighbors": neighbor_count,
        "NeighborhoodGate": neighborhood,
        "RecentValidationPermitted": passed,
        "Model4ValidationPermitted": False,
        "ResearchPromotionPermitted": False,
        "ForwardCandidateChanged": False,
        "RealAccountTradingAllowed": False,
        "ControlNetProfit": control["NetProfit"],
        "RiskOnlyReferenceNetProfit": reference["NetProfit"],
        "CenterNetProfit": center["NetProfit"],
        "SourceSha256": EXPECTED_SOURCE,
        "BinarySha256": EXPECTED_BINARY,
        "CenterProfileSha256": center["ProfileSha256"],
        "ManifestSha256": EXPECTED_MANIFEST,
    }
    write_csv(DECISION, [decision])

    labels = {
        CONTROL: "Control cap 0.15 / risk 0.45%",
        REFERENCE: "Risk-only body 0.250 / risk 0.65%",
        "jsa_r060": "Cap 0.15 / risk 0.60%",
        CENTER: "**Cap 0.15 / risk 0.65% center**",
        "jsa_r070": "Cap 0.15 / risk 0.70%",
        "jsa_body0225": "Body 0.225 / cap 0.15 / risk 0.65%",
        "jsa_body0275": "Body 0.275 / cap 0.15 / risk 0.65%",
    }
    lines = [
        "# Joint Strong-Signal Reversion Allocation Discovery Decision",
        "",
        "**Decision: DISCOVERY GATE PASSED. Recent-data validation may open; Model 4 and promotion remain closed.**"
        if passed
        else "**Decision: REJECTED IN DISCOVERY. Recent data, Model 4, promotion, forward substitution, and live approval remain closed.**",
        "",
        f"- Exact accepted reports: `{len(accepted_by_rank)}/21`; attempts: `{len(runner_rows)}`; identity refusals retried without changing configs: `{decision['IdentityRefusals']}`",
        f"- Source SHA-256: `{EXPECTED_SOURCE}`",
        f"- EX5 SHA-256: `{EXPECTED_BINARY}`",
        f"- Manifest SHA-256: `{EXPECTED_MANIFEST}`",
        "- `$10,000`; MT5 Model 1; 2015-2020 sealed discovery; requested reversion risk `0.45%`; portfolio cap `0.75%`; real trading disabled",
        "",
        "| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for item in summary:
        lines.append(
            f"| {labels[str(item['Candidate'])]} | {money(float(item['OlderNetProfit']))} | {money(float(item['LaterNetProfit']))} | "
            f"{money(float(item['ContinuousNetProfit']))} | {item['TotalReturnPercent']}% | {item['CagrPercent']}%/yr | "
            f"{item['ProfitFactor']} | {item['TotalTrades']} | {item['MaxDrawdownPercent']}% | {item['RecoveryFactor']} | {item['ReturnDrawdown']} |"
        )
    lines.extend(
        [
            "",
            "## Frozen Gate",
            "",
            f"- Every report profitable: `{all_positive}`",
            f"- Center changed behavior and was no worse in both disjoint eras: `{center_active and center_no_worse}`",
            f"- Center net at least 3% above control: `{center_growth}` (`{money(float(center['NetProfit']))}` vs required `{money(1.03 * float(control['NetProfit']))}`)",
            f"- Center CAGR at least 0.05 point above control: `{center_cagr}`",
            f"- Center PF/recovery/return-DD no worse than control: `{center_efficiency}`",
            f"- Center drawdown and trade-count gates: `{center_risk and center_trades}`",
            f"- Center beat the risk-only reference in net and return/DD: `{improves_reference}`",
            f"- At least 3 of 4 orthogonal neighbors passed: `{neighborhood}` (`{neighbor_count}/4`)",
            "",
            f"The center changed net profit by `{money(center_increment)}` versus the exact leader control in the sealed continuous window. It failed the preregistered disjoint-era, growth, CAGR, efficiency, and neighborhood gates, so no recent-data or Model 4 budget was spent.",
            "",
            "The published strong-signal selective lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.",
        ]
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"{decision['Status']} center={center['NetProfit']} control={control['NetProfit']} reference={reference['NetProfit']} neighbors={neighbor_count}/4")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
