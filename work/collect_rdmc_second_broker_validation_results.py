#!/usr/bin/env python3
"""Collect only the admitted distinct-broker report wave into canonical results."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

import evaluate_rdmc_second_broker_validation_gate as gate
from rdmc_executable_ledger_stress_core import (
    validate_report_identity,
)


ROOT = Path(__file__).resolve().parents[1]
REPORT_EXTENSIONS = (".htm", ".html", ".xml")


def relative_repo_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        relative = resolved.relative_to(ROOT.resolve())
    except ValueError as exc:
        raise ValueError(f"Evidence path is outside repository: {resolved}") from exc
    return str(relative).replace("/", "\\")


def admitted_wave(decision: dict[str, str]) -> int:
    match = re.fullmatch(
        r"(?:LOCKED_)?AWAITING_SECOND_BROKER_WAVE_(\d{2})_REPORTS",
        decision.get("Status", ""),
    )
    if not match:
        raise ValueError(f"Second-broker report collection is not admitted: {decision.get('Status', 'MISSING')}")
    wave = int(match.group(1))
    gate.require(1 <= wave <= 3, "Admitted second-broker wave is invalid")
    gate.require(decision.get("PrimaryPrerequisitePass", "False").lower() == "true", "Primary prerequisite is false")
    gate.require(decision.get("SpecificationPass", "False").lower() == "true", "Broker specification prerequisite is false")
    return wave


def collect_wave(
    manifest: list[dict[str, str]],
    specification: dict[str, str],
    specification_hash: str,
    existing: list[dict[str, str]],
    wave: int,
) -> list[dict[str, object]]:
    prior_names = {row["ExpectedReportName"] for row in manifest if int(row["Wave"]) < wave}
    gate.require(
        all(row.get("ExpectedReportName") in prior_names for row in existing),
        "Existing results contain current, future, or unknown rows",
    )
    wave_rows = [row for row in manifest if int(row["Wave"]) == wave]
    gate.require(len(wave_rows) == gate.EXPECTED_WAVE_COUNTS[wave], "Admitted wave shape changed")
    collected: list[dict[str, object]] = [dict(row) for row in existing]
    binary_hashes = {
        row.get("PortableBinarySha256", "").upper()
        for row in existing
        if row.get("PortableBinarySha256", "").strip()
    }

    for manifest_row in wave_rows:
        name = manifest_row["ExpectedReportName"]
        candidates = [gate.REPORT_ROOT / f"{name}{extension}" for extension in REPORT_EXTENSIONS]
        present = [path for path in candidates if path.is_file()]
        gate.require(len(present) == 1, f"Expected one report for {name}; found {len(present)}")
        report = present[0]
        identity_path = gate.REPORT_ROOT / f"{name}.identity.json"
        gate.require(identity_path.is_file(), f"Report identity sidecar is missing: {identity_path.name}")
        identity_json = json.loads(identity_path.read_text(encoding="ascii"))
        binary_hash = str(identity_json.get("PortableBinarySha256", "")).upper()
        gate.require(gate.valid_sha256(binary_hash), f"Report binary identity is invalid: {name}")
        identity = validate_report_identity(
            report,
            identity_path,
            name,
            manifest_row["ConfigSha256"],
            gate.EXPECTED_SOURCE_SHA256,
            binary_hash,
        )
        gate.reject_report_account_identifier(report)
        metrics = gate.parse_bound_report_metrics(report, manifest_row)
        gate.require(
            metrics["CompanyFingerprintSha256"] == specification["CompanyFingerprintSha256"].upper(),
            f"Report company fingerprint differs from specification: {name}",
        )
        gate.require(
            metrics["AccountCurrency"] == specification["AccountCurrency"].upper(),
            f"Report currency differs from specification: {name}",
        )
        initial = float(metrics["InitialDeposit"])
        net = float(metrics["NetProfit"])
        binary_hashes.add(binary_hash)
        collected.append(
            {
                "QueueRank": manifest_row["QueueRank"],
                "Wave": manifest_row["Wave"],
                "Role": manifest_row["Role"],
                "Window": manifest_row["Window"],
                "Model": "4",
                "ExpectedReportName": name,
                "Status": "PARSED",
                "ReportPath": relative_repo_path(report),
                "ReportIdentityPath": relative_repo_path(identity_path),
                "ReportSha256": str(identity["ReportSha256"]).upper(),
                "ConfigSha256": manifest_row["ConfigSha256"],
                "SourceSha256": gate.EXPECTED_SOURCE_SHA256,
                "ProfileSha256": gate.EXPECTED_PROFILE_SHA256,
                "PortableBinarySha256": binary_hash,
                "BrokerSpecificationSha256": specification_hash,
                "ReportCompanyFingerprintSha256": metrics["CompanyFingerprintSha256"],
                "InitialDeposit": round(initial, 2),
                "NetProfit": round(net, 2),
                "Balance": round(float(metrics["Balance"]), 2),
                "TotalReturnPercent": round(100.0 * net / initial, 4),
                "CagrPercent": round(float(metrics["CagrPercent"]), 4),
                "ProfitFactor": metrics["ProfitFactor"],
                "ExpectedPayoff": metrics["ExpectedPayoff"],
                "SharpeRatio": metrics["SharpeRatio"],
                "WinRatePercent": metrics["WinRatePercent"],
                "TotalTrades": metrics["TotalTrades"],
                "MaxConsecutiveLosses": metrics["MaxConsecutiveLosses"],
                "MaxDrawdownPercent": metrics["MaxDrawdownPercent"],
                "RecoveryFactor": metrics["RecoveryFactor"],
            }
        )
    gate.require(len(binary_hashes) == 1, "Second-broker rows do not share one compiled binary identity")
    return sorted(collected, key=lambda row: int(str(row["QueueRank"])))


def main() -> int:
    gate.require(gate.DECISION_CSV.is_file(), "Second-broker decision is missing")
    decision_rows = gate.read_csv(gate.DECISION_CSV)
    gate.require(len(decision_rows) == 1, "Second-broker decision is ambiguous")
    wave = admitted_wave(decision_rows[0])
    gate.require(gate.SPECIFICATION.is_file(), "Second-broker specification is missing")
    specification_rows = gate.read_csv(gate.SPECIFICATION)
    specification_pass, reasons = gate.validate_specification(specification_rows)
    gate.require(specification_pass, "Second-broker specification failed: " + ";".join(reasons))
    specification_hash = gate.sha256(gate.SPECIFICATION)
    manifest = gate.load_manifest()
    existing = gate.read_csv(gate.RESULTS) if gate.RESULTS.is_file() else []
    canonical = collect_wave(manifest, specification_rows[0], specification_hash, existing, wave)
    gate.write_csv(gate.RESULTS, canonical)
    run = subprocess.run(
        [sys.executable, str(Path(gate.__file__).resolve())],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    print(f"SECOND_BROKER_WAVE_COLLECTED wave={wave} rows={len(canonical)}/18 evaluator={run.stdout.strip()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
