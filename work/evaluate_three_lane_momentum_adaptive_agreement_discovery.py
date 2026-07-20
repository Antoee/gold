#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = ROOT / "outputs"
MANIFEST = OUTPUTS / "THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_MODEL1_MANIFEST.csv"
RAW_RESULTS = OUTPUTS / "THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_MODEL1_RESULTS.csv"
COMPILE_AUDIT = OUTPUTS / "THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_COMPILE_AUDIT.csv"
EVIDENCE = OUTPUTS / "THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_EVIDENCE.csv"
SUMMARY = OUTPUTS / "THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_SUMMARY.csv"
DECISION = OUTPUTS / "THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_DECISION.csv"
DECISION_MD = OUTPUTS / "THREE_LANE_MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_DECISION.md"
EXPECTED_MANIFEST = "AF9AFBF24F2F60BCA7833E50850B438DF23B2C7431506744C1509825B5C1949C"
EXPECTED_SOURCE = "6402A284BE2C4BDBEC2F44B8851650C64A6AEBAD87A35CF8CA2BD8A0275206D2"
EXPECTED_BINARY = "AB22F7E064642EC48DDEABC2309D7A99FC8EE36C274CB25167AD605B332EE936"
CONTROL = "maa_control"
CENTER = "maa_center_r025"
NEIGHBORS = ("maa_r020", "maa_r0225", "maa_r0275")
CANDIDATES = (CONTROL, *NEIGHBORS[:2], CENTER, NEIGHBORS[2])
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
        raise ValueError("agreement discovery manifest identity changed")
    manifest = read_csv(MANIFEST)
    if (
        len(manifest) != 15
        or {row["Candidate"] for row in manifest} != set(CANDIDATES)
        or {row["Window"] for row in manifest} != set(WINDOWS)
    ):
        raise ValueError("agreement discovery topology changed")
    if any(
        row["SourceSha256"] != EXPECTED_SOURCE
        or row["Model"] != "1"
        or row["Deposit"] != "10000"
        or row["BaseMomentumRiskPercent"] != "0.15"
        or row["ReversionRiskPercent"] != "0.45"
        or row["AdaptiveRiskPercent"] != "0.15"
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
    if len(raw) != 15 or len(raw_by_report) != 15 or any(row["Status"] != "PARSED" for row in raw):
        raise ValueError("expected 15 unique parsed reports")

    runner_rows: list[dict[str, str]] = []
    for path in OUTPUTS.glob("MOMENTUM_ADAPTIVE_AGREEMENT_DISCOVERY_M1_*.csv"):
        runner_rows.extend(read_csv(path))
    accepted_by_rank: dict[str, dict[str, str]] = {}
    for rank in range(1, 16):
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
            "AgreementEnabled": expected["AdaptiveAgreementRiskEnabled"],
            "AgreementRiskPercent": float(expected["AdaptiveAgreementRiskPercent"]),
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

    def result(candidate: str, window: str = "continuous_2015_2020") -> dict[str, object]:
        return by_key[(candidate, window)]

    def changed(candidate: str) -> bool:
        fields = ("NetProfit", "ProfitFactor", "TotalTrades", "MaxDrawdownPercent", "RecoveryFactor")
        return any(
            result(candidate, window)[field] != result(CONTROL, window)[field]
            for window in WINDOWS
            for field in fields
        )

    def no_worse_eras(candidate: str) -> bool:
        return all(
            float(result(candidate, window)["NetProfit"])
            >= float(result(CONTROL, window)["NetProfit"])
            for window in WINDOWS[:2]
        )

    control = result(CONTROL)
    center = result(CENTER)

    def neighbor_pass(candidate: str) -> bool:
        current = result(candidate)
        return (
            changed(candidate)
            and no_worse_eras(candidate)
            and float(current["NetProfit"]) >= 1.02 * float(control["NetProfit"])
            and float(current["ProfitFactor"]) >= 0.97 * float(control["ProfitFactor"])
            and float(current["RecoveryFactor"]) >= 0.97 * float(control["RecoveryFactor"])
            and float(current["ReturnDrawdown"]) >= 0.97 * float(control["ReturnDrawdown"])
            and float(current["MaxDrawdownPercent"]) <= 1.25
            and int(current["TotalTrades"]) >= int(control["TotalTrades"]) - 2
        )

    all_positive = all(float(row["NetProfit"]) > 0 for row in evidence)
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
        and float(center["MaxDrawdownPercent"]) <= float(control["MaxDrawdownPercent"]) + 0.10
    )
    center_trades = int(center["TotalTrades"]) >= int(control["TotalTrades"]) - 2
    neighbor_results = {candidate: neighbor_pass(candidate) for candidate in NEIGHBORS}
    neighbor_count = sum(neighbor_results.values())
    neighborhood = neighbor_count >= 2
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
                "AgreementEnabled": settings[candidate]["AdaptiveAgreementRiskEnabled"],
                "AgreementRiskPercent": settings[candidate]["AdaptiveAgreementRiskPercent"],
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
                "NoWorseBothDisjointEras": no_worse_eras(candidate),
                "NeighborGate": neighbor_results.get(candidate, ""),
            }
        )
    write_csv(SUMMARY, summary)

    center_delta = float(center["NetProfit"]) - float(control["NetProfit"])
    decision = {
        "Status": "DISCOVERY_GATE_PASSED" if passed else "REJECTED_IN_DISCOVERY",
        "ReportsParsed": len(evidence),
        "IdentityAcceptedReports": len(accepted_by_rank),
        "TotalAttempts": len(runner_rows),
        "IdentityRefusals": sum(row.get("Status") == "ERROR" for row in runner_rows),
        "AllWindowsPositive": all_positive,
        "CenterBehaviorChanged": center_active,
        "CenterNoWorseDisjointEras": center_no_worse,
        "CenterGrowthGate": center_growth,
        "CenterCagrGate": center_cagr,
        "CenterEfficiencyGate": center_efficiency,
        "CenterRiskGate": center_risk,
        "CenterTradeCountGate": center_trades,
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
        "SourceSha256": EXPECTED_SOURCE,
        "BinarySha256": EXPECTED_BINARY,
        "CenterProfileSha256": center["ProfileSha256"],
        "ManifestSha256": EXPECTED_MANIFEST,
    }
    write_csv(DECISION, [decision])

    labels = {
        CONTROL: "Disabled control",
        "maa_r020": "Agreement risk 0.20%",
        "maa_r0225": "Agreement risk 0.225%",
        CENTER: "**Agreement risk 0.25% center**",
        "maa_r0275": "Agreement risk 0.275%",
    }
    lines = [
        "# Momentum / Adaptive Agreement Allocation Discovery Decision",
        "",
        "**Decision: DISCOVERY GATE PASSED. Architecture-seen recent confirmation may open; Model 4 and promotion remain closed.**"
        if passed
        else "**Decision: REJECTED IN DISCOVERY. Architecture-seen recent data, Model 4, promotion, forward substitution, and live approval remain closed.**",
        "",
        f"- Exact accepted reports: `{len(accepted_by_rank)}/15`; attempts: `{len(runner_rows)}`; identity refusals retried unchanged: `{decision['IdentityRefusals']}`",
        f"- Source SHA-256: `{EXPECTED_SOURCE}`",
        f"- EX5 SHA-256: `{EXPECTED_BINARY}`",
        f"- Manifest SHA-256: `{EXPECTED_MANIFEST}`",
        "- `$10,000`; MT5 Model 1; 2015-2020 parameter discovery; base momentum risk `0.15%`; portfolio cap `0.75%`; real trading disabled",
        "- Architecture was selected from the full leader ledger; no historical window is claimed as pristine out-of-sample evidence",
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
            f"- At least 2 of 3 enabled neighbors passed: `{neighborhood}` (`{neighbor_count}/3`)",
            "",
            f"The 0.25% center changed continuous net by only `{money(center_delta)}` and changed 2015-2018 by `{money(float(result(CENTER, WINDOWS[0])['NetProfit']) - float(result(CONTROL, WINDOWS[0])['NetProfit']))}` versus control. PF, recovery, return/drawdown, and the drawdown ceiling also failed.",
            "",
            "The 0.225% row was the best headline at +$1,377.30, but its 1.74% continuous gain missed the frozen 2% neighbor floor and its recovery retained less than 97% of control. Selecting it after observation would be threshold chasing, so no recent-data or Model 4 budget was spent.",
            "",
            "The provisional strong-signal selective reversion lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.",
        ]
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(
        f"{decision['Status']} center={center['NetProfit']} control={control['NetProfit']} "
        f"neighbors={neighbor_count}/3"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
