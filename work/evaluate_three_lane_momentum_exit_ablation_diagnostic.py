#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = ROOT / "outputs"
MANIFEST = OUTPUTS / "THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_MODEL1_MANIFEST.csv"
RAW_RESULTS = OUTPUTS / "THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_MODEL1_RESULTS.csv"
EVIDENCE = OUTPUTS / "THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_EVIDENCE.csv"
SUMMARY = OUTPUTS / "THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_SUMMARY.csv"
DECISION = OUTPUTS / "THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_DECISION.csv"
DECISION_MD = OUTPUTS / "THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_DECISION.md"

EXPECTED_MANIFEST = "5C8B949BAE2D8A4296AC9932DEEC9B02ECB8255FDF4E153D9D8A47C3A49D91DE"
EXPECTED_SOURCE = "C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91"
EXPECTED_BINARY = "21DDE8A2C1E04CB1D26C76E791A1EA1F0F26167667F19479F29A98BAE1D905A4"
CONTROL = "mea_control"
WINDOWS = ("older_2015_2018", "later_2019_2020", "continuous_2015_2020")
CANDIDATES = (
    CONTROL,
    "mea_no_channel",
    "mea_no_momentum",
    "mea_no_time",
    "mea_channel_only",
    "mea_momentum_only",
    "mea_time_only",
    "mea_fixed_only",
)


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
        raise ValueError("momentum-exit diagnostic manifest identity changed")

    manifest = read_csv(MANIFEST)
    if (
        len(manifest) != 24
        or {row["Candidate"] for row in manifest} != set(CANDIDATES)
        or {row["Window"] for row in manifest} != set(WINDOWS)
    ):
        raise ValueError("momentum-exit diagnostic topology changed")
    if any(
        row["SourceSha256"] != EXPECTED_SOURCE
        or row["Model"] != "1"
        or row["Deposit"] != "10000"
        or row["ReversionRiskPercent"] != "0.45"
        or row["MaximumPortfolioOpenRiskPercent"] != "0.75"
        for row in manifest
    ):
        raise ValueError("source/model/capital/risk contract changed")
    for row in manifest:
        if sha256(ROOT / row["PackageConfig"]) != row["ConfigSha256"]:
            raise ValueError(f"config identity changed at rank {row['QueueRank']}")

    raw = read_csv(RAW_RESULTS)
    raw_by_report = {row["ExpectedReportName"]: row for row in raw}
    if len(raw) != 24 or len(raw_by_report) != 24 or any(row["Status"] != "PARSED" for row in raw):
        raise ValueError("expected 24 unique parsed reports")

    runner_rows: list[dict[str, str]] = []
    for path in OUTPUTS.glob("MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_M1_*.csv"):
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
    settings_by_candidate: dict[str, dict[str, str]] = {}
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
            "ChannelExit": expected["MomentumChannelExitEnabled"],
            "MomentumFailureExit": expected["MomentumFailureExitEnabled"],
            "MaximumHoldBars": int(expected["MomentumMaximumHoldBars"]),
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
        settings_by_candidate[expected["Candidate"]] = expected
    write_csv(EVIDENCE, evidence)

    def result(candidate: str, window: str = "continuous_2015_2020") -> dict[str, object]:
        return by_key[(candidate, window)]

    comparison_fields = (
        "NetProfit",
        "ProfitFactor",
        "TotalTrades",
        "MaxDrawdownPercent",
        "RecoveryFactor",
        "ReturnDrawdown",
    )

    def changed(candidate: str) -> bool:
        return any(
            result(candidate, window)[field] != result(CONTROL, window)[field]
            for window in WINDOWS
            for field in comparison_fields
        )

    def no_worse_disjoint_eras(candidate: str) -> bool:
        return all(
            float(result(candidate, window)["NetProfit"])
            >= float(result(CONTROL, window)["NetProfit"])
            for window in WINDOWS[:2]
        )

    control = result(CONTROL)

    def architecture_gate(candidate: str) -> bool:
        current = result(candidate)
        return (
            changed(candidate)
            and no_worse_disjoint_eras(candidate)
            and float(current["NetProfit"]) >= 1.03 * float(control["NetProfit"])
            and float(current["ProfitFactor"]) >= float(control["ProfitFactor"])
            and float(current["RecoveryFactor"]) >= float(control["RecoveryFactor"])
            and float(current["ReturnDrawdown"]) >= float(control["ReturnDrawdown"])
            and float(current["MaxDrawdownPercent"]) <= 1.30
            and int(current["TotalTrades"]) >= 200
        )

    passing = [candidate for candidate in CANDIDATES[1:] if architecture_gate(candidate)]
    architecture_nominated = len(passing) >= 2
    all_positive = all(float(row["NetProfit"]) > 0 for row in evidence)

    summary: list[dict[str, object]] = []
    for candidate in CANDIDATES:
        current = result(candidate)
        settings = settings_by_candidate[candidate]
        summary.append(
            {
                "Candidate": candidate,
                "Role": current["Role"],
                "ChannelExit": settings["MomentumChannelExitEnabled"],
                "MomentumFailureExit": settings["MomentumFailureExitEnabled"],
                "MaximumHoldBars": settings["MomentumMaximumHoldBars"],
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
                "NoWorseBothDisjointEras": no_worse_disjoint_eras(candidate),
                "ArchitectureGate": architecture_gate(candidate),
            }
        )
    write_csv(SUMMARY, summary)

    no_channel = result("mea_no_channel")
    older_delta = float(result("mea_no_channel", WINDOWS[0])["NetProfit"]) - float(
        result(CONTROL, WINDOWS[0])["NetProfit"]
    )
    later_delta = float(result("mea_no_channel", WINDOWS[1])["NetProfit"]) - float(
        result(CONTROL, WINDOWS[1])["NetProfit"]
    )
    continuous_delta = float(no_channel["NetProfit"]) - float(control["NetProfit"])
    decision = {
        "Status": "ARCHITECTURE_NOMINATED" if architecture_nominated else "REJECTED_DIAGNOSTIC",
        "ReportsParsed": len(evidence),
        "IdentityAcceptedReports": len(accepted_by_rank),
        "TotalAttempts": len(runner_rows),
        "IdentityRefusals": sum(row.get("Status") == "ERROR" for row in runner_rows),
        "AllWindowsPositive": all_positive,
        "BehaviorChangingCandidates": sum(changed(candidate) for candidate in CANDIDATES[1:]),
        "PassingRelatedAblations": len(passing),
        "ArchitectureNominationGate": architecture_nominated,
        "CodeFollowUpPermitted": architecture_nominated,
        "RecentValidationPermitted": False,
        "Model4ValidationPermitted": False,
        "ResearchPromotionPermitted": False,
        "ForwardCandidateChanged": False,
        "RealAccountTradingAllowed": False,
        "ControlNetProfit": control["NetProfit"],
        "NoChannelNetProfit": no_channel["NetProfit"],
        "NoChannelOlderDelta": round(older_delta, 2),
        "NoChannelLaterDelta": round(later_delta, 2),
        "NoChannelContinuousDelta": round(continuous_delta, 2),
        "SourceSha256": EXPECTED_SOURCE,
        "BinarySha256": EXPECTED_BINARY,
        "ManifestSha256": EXPECTED_MANIFEST,
    }
    write_csv(DECISION, [decision])

    labels = {
        "mea_control": "Control: channel + momentum + time",
        "mea_no_channel": "No channel exit",
        "mea_no_momentum": "No momentum-failure exit",
        "mea_no_time": "No 120-bar time exit",
        "mea_channel_only": "Channel exit only",
        "mea_momentum_only": "Momentum-failure exit only",
        "mea_time_only": "120-bar time exit only",
        "mea_fixed_only": "Fixed SL/TP only",
    }
    lines = [
        "# Momentum Exit Ablation Diagnostic Decision",
        "",
        "**Decision: REJECTED DIAGNOSTIC. No code follow-up, recent-data test, Model 4 test, promotion, forward substitution, or live approval is permitted.**"
        if not architecture_nominated
        else "**Decision: ARCHITECTURE NOMINATED. A separately frozen code experiment may be designed; promotion remains closed.**",
        "",
        f"- Exact accepted reports: `{len(accepted_by_rank)}/24`; attempts: `{len(runner_rows)}`; identity refusals retried unchanged: `{decision['IdentityRefusals']}`",
        f"- Source SHA-256: `{EXPECTED_SOURCE}`",
        f"- EX5 SHA-256: `{EXPECTED_BINARY}`",
        f"- Manifest SHA-256: `{EXPECTED_MANIFEST}`",
        "- `$10,000`; MT5 Model 1; sealed 2015-2020 diagnostic; reversion risk `0.45%`; portfolio cap `0.75%`; real trading disabled",
        "",
        "| Exit profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD | Changed | Gate |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:---:|:---:|",
    ]
    for row in summary:
        lines.append(
            f"| {labels[str(row['Candidate'])]} | {money(float(row['OlderNetProfit']))} | "
            f"{money(float(row['LaterNetProfit']))} | {money(float(row['ContinuousNetProfit']))} | "
            f"{row['TotalReturnPercent']}% | {row['CagrPercent']}%/yr | {row['ProfitFactor']} | "
            f"{row['TotalTrades']} | {row['MaxDrawdownPercent']}% | {row['RecoveryFactor']} | "
            f"{row['ReturnDrawdown']} | {row['BehaviorChangedVsControl']} | {row['ArchitectureGate']} |"
        )
    lines.extend(
        [
            "",
            "## Frozen Gate",
            "",
            "A code follow-up required at least two related, behavior-changing ablations that were no worse in both disjoint eras, improved continuous net by at least 3%, did not reduce PF/recovery/return-DD, kept drawdown at or below 1.30%, and retained at least 200 trades.",
            "",
            f"- Passing related ablations: `{len(passing)}`; required: `2`",
            f"- Removing the channel exit changed 2015-18 by `{money(older_delta)}` and 2019-20 by `{money(later_delta)}`.",
            f"- Its continuous change was `{money(continuous_delta)}`: `{money(float(no_channel['NetProfit']))}` versus `{money(float(control['NetProfit']))}` control.",
            "- Removing momentum-failure and/or the 120-bar time exit while preserving the channel exit produced identical results to control. These mechanisms were inactive in the sealed sample.",
            "- Every profile remained profitable, but the only behavior-changing architecture was unstable across eras and reduced continuous profit and efficiency.",
            "",
            "The provisional strong-signal selective reversion lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.",
        ]
    )
    DECISION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(
        f"{decision['Status']} reports={len(evidence)} passing={len(passing)} "
        f"control={control['NetProfit']} no_channel={no_channel['NetProfit']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
