#!/usr/bin/env python3
"""Offline repository safety audit for the MT5 XAUUSD EA project.

This script is intentionally static: it does not launch MT5, MetaEditor, Git,
GitHub CLI, or any tester process. It is safe for GitHub Actions and local use.
"""

from __future__ import annotations

import csv
import hashlib
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def csv_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


class Audit:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.passes = 0

    def check(self, condition: bool, message: str) -> None:
        if condition:
            self.passes += 1
            print(f"PASS: {message}")
        else:
            self.failures.append(message)
            print(f"FAIL: {message}")


def main() -> int:
    audit = Audit()

    workflow = ROOT / ".github" / "workflows" / "static-safety.yml"
    workflow_text = read_text(workflow)
    workflow_lower = workflow_text.lower()

    audit.check(workflow.exists(), "static safety workflow exists")
    audit.check("workflow_dispatch:" in workflow_text, "workflow is manually dispatched")
    audit.check("push:" not in workflow_lower, "workflow has no push trigger")
    audit.check("pull_request:" not in workflow_lower, "workflow has no pull_request trigger")
    audit.check("schedule:" not in workflow_lower, "workflow has no schedule trigger")
    audit.check("terminal64.exe" not in workflow_lower and "metaeditor" not in workflow_lower,
                "workflow does not launch MT5 or MetaEditor")

    required_paths = [
        ROOT / "Professional_XAUUSD_EA.mq5",
        ROOT / "outputs" / "Professional_XAUUSD_EA.mq5",
        ROOT / "outputs" / "CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set",
        ROOT / "outputs" / "CANDIDATE_MONEY_READY_PROFILE.set",
        ROOT / "outputs" / "CANDIDATE_TRADE_READINESS_PROFILE.set",
        ROOT / "outputs" / "TRADE_READY_LIVE_READINESS_DECISION.md",
        ROOT / "outputs" / "MONEY_READY_STATUS_SCORECARD.md",
        ROOT / "outputs" / "GITHUB_PUBLICATION_SYNC.md",
        ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock",
        ROOT / "work" / "assert_mt5_launch_allowed.ps1",
        ROOT / "work" / "mt5_background_helpers.ps1",
    ]
    for path in required_paths:
        audit.check(path.exists(), f"required artifact exists: {path.relative_to(ROOT)}")

    root_source = ROOT / "Professional_XAUUSD_EA.mq5"
    mirror_source = ROOT / "outputs" / "Professional_XAUUSD_EA.mq5"
    if root_source.exists() and mirror_source.exists():
        audit.check(sha256(root_source) == sha256(mirror_source),
                    "root EA source and mirrored output source hashes match")

    unlock_files = [
        ROOT / "work" / "ALLOW_MT5_LOCAL_LAUNCH.unlock",
        ROOT / "work" / "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock",
    ]
    for path in unlock_files:
        audit.check(not path.exists(), f"MT5 launch unlock is absent: {path.relative_to(ROOT)}")

    safety_rows = csv_rows(ROOT / "outputs" / "MT5_LOCAL_SAFETY_AUDIT.csv")
    if safety_rows:
        failed = [row for row in safety_rows if row.get("Passed", "").lower() != "true"]
        audit.check(not failed, "latest local MT5 safety audit has zero failed rows")
    else:
        audit.check(False, "latest local MT5 safety audit CSV exists and is parseable")

    live_text = read_text(ROOT / "outputs" / "TRADE_READY_LIVE_READINESS_DECISION.md")
    audit.check("Overall: **PENDING**" in live_text or "Overall: **PASS**" in live_text,
                "live-readiness decision is explicit")
    audit.check("real-account trading stays blocked" in live_text.lower()
                or "real-account trading remains locked" in live_text.lower(),
                "live-readiness text keeps real-account trading locked")

    scorecard_text = read_text(ROOT / "outputs" / "MONEY_READY_STATUS_SCORECARD.md")
    audit.check("NOT_READY_PENDING_EVIDENCE" in scorecard_text or "MONEY_READY" in scorecard_text,
                "money-ready scorecard verdict is explicit")

    publication_text = read_text(ROOT / "outputs" / "GITHUB_PUBLICATION_SYNC.md")
    publication_verdicts = ("Overall: **PASS**", "Overall: **PENDING**", "Overall: **FAIL**")
    audit.check(any(verdict in publication_text for verdict in publication_verdicts)
                and "Generated offline without launching" in publication_text
                and "GitHub Actions" in publication_text,
                "GitHub publication sync status is explicit and offline")

    print()
    if audit.failures:
        print(f"STATIC_REPO_SAFETY_AUDIT_FAIL failures={len(audit.failures)} passes={audit.passes}")
        return 1

    print(f"STATIC_REPO_SAFETY_AUDIT_PASS checks={audit.passes}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
