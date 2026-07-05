#!/usr/bin/env python3
"""Static safety checks for the XAUUSD EA research repo.

This script intentionally does not launch MT5, MetaEditor, or any local tester.
It checks repository structure, risk-first input coverage, handoff config safety,
and candidate guardrail consistency before expensive tester time is spent.
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

FAILURES: list[str] = []
WARNINGS: list[str] = []


def fail(message: str) -> None:
    FAILURES.append(message)


def warn(message: str) -> None:
    WARNINGS.append(message)


def read_text(path: Path) -> str:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def strip_mql_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//.*", "", text)
    return text


def parse_ini(path: Path) -> tuple[dict[str, str], dict[str, str]]:
    tester: dict[str, str] = {}
    inputs: dict[str, str] = {}
    section = ""
    for raw in read_text(path).splitlines():
        line = raw.strip()
        if not line or line.startswith(";") or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        target = inputs if section == "TesterInputs" else tester if section == "Tester" else None
        if target is not None:
            target[key.strip()] = value.strip()
    return tester, inputs


def first_value(value: str) -> str:
    return value.split("||", 1)[0].strip()


def parse_set(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in read_text(path).splitlines():
        line = raw.strip()
        if not line or line.startswith(";") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = first_value(value)
    return values


def check_source() -> None:
    source_path = ROOT / "Professional_XAUUSD_EA.mq5"
    source = read_text(source_path)
    code = strip_mql_comments(source)

    if '#property strict' not in source:
        fail("EA source must use #property strict.")

    forbidden_patterns = {
        "martingale": r"\bmartingale\b",
        "grid": r"\bgrid\b",
        "averaging down": r"averag(?:e|ing)\s+down",
    }
    for label, pattern in forbidden_patterns.items():
        if re.search(pattern, code, flags=re.I):
            fail(f"Forbidden strategy concept appears in executable EA code: {label}")

    required_inputs = [
        "InpRiskPercent",
        "InpMinRiskReward",
        "InpStopATRMultiplier",
        "InpTakeProfitATRMultiplier",
        "InpMaxDailyLossPercent",
        "InpMaxWeeklyLossPercent",
        "InpMaxMonthlyLossPercent",
        "InpMaxEquityDrawdownPercent",
        "InpMaxConsecutiveLosses",
        "InpCooldownMinutesAfterLoss",
        "InpMaxSpreadPoints",
        "InpSlippagePoints",
        "InpUseBOS",
        "InpUseLiquiditySweep",
        "InpMinimumConfirmations",
        "InpUseATRTrailing",
        "InpUseProfitGivebackGuard",
        "InpShowDashboard",
        "InpDashboardInTester",
        "InpTesterFitnessMode",
    ]
    input_names = set(re.findall(r"^\s*input\s+(?:bool|int|long|double|string|datetime)\s+(Inp[A-Za-z0-9_]+)\s*=", source, flags=re.M))
    for name in required_inputs:
        if name not in input_names:
            fail(f"EA source missing required risk/research input: {name}")

    required_code_terms = [
        "OrderCalcProfit",
        "OrderCalcMargin",
        "HistoryDealSelect",
        "OnTester",
        "consecutiveLosses",
    ]
    for term in required_code_terms:
        if term not in source:
            fail(f"EA source missing expected safety/analytics implementation marker: {term}")


def check_hard_lock() -> None:
    lock = ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock"
    text = read_text(lock)
    if "hard lock" not in text.lower():
        fail("MT5 local launch lock exists but does not describe itself as a hard lock.")

    guard = read_text(ROOT / "work" / "assert_mt5_launch_allowed.ps1")
    for term in ["MT5_LOCAL_LAUNCH_DISABLED.lock", "ALLOW_MT5_FOCUS_RISK", "ALLOW_MT5_HIDDEN_DESKTOP_ACK", "Stop-Process"]:
        if term not in guard:
            fail(f"Launch guard missing required term: {term}")


def check_profiles() -> None:
    expected = {
        "ROBUST_BOS_SWEEP_PROFILE.set": {"InpTakeProfitATRMultiplier": "3.50", "InpRiskPercent": "1.60"},
        "CANDIDATE_RISK16_SL18_TP38_PROFILE.set": {"InpTakeProfitATRMultiplier": "3.80", "InpMaxEquityDrawdownPercent": "4.00"},
        "CANDIDATE_RISK16_SL16_TP38_PROFILE.set": {"InpTakeProfitATRMultiplier": "3.80", "InpMaxEquityDrawdownPercent": "4.00"},
    }
    for rel, required in expected.items():
        values = parse_set(ROOT / rel)
        for key, expected_value in required.items():
            actual = values.get(key, "")
            if actual != expected_value:
                fail(f"{rel} expected {key}={expected_value}, found {actual or '<missing>'}.")


def check_manifest(path: Path, expected_rows: int, label: str) -> None:
    if not path.exists():
        fail(f"Missing {label} manifest: {path.relative_to(ROOT)}")
        return
    with path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != expected_rows:
        fail(f"{label} manifest expected {expected_rows} rows, found {len(rows)}.")
    for row in rows:
        config = ROOT / row.get("HandoffConfig", "")
        report = row.get("ExpectedReportName", "")
        if not config.exists():
            fail(f"{label} manifest points at missing config: {config.relative_to(ROOT)}")
        if not report:
            fail(f"{label} manifest row missing ExpectedReportName for {row.get('Profile')} {row.get('Window')}")


def check_configs(config_dir: Path, label: str) -> None:
    configs = sorted(config_dir.glob("*.ini"))
    if not configs:
        fail(f"No configs found for {label}: {config_dir.relative_to(ROOT)}")
        return
    for config in configs:
        tester, inputs = parse_ini(config)
        rel = config.relative_to(ROOT)
        required_tester = {
            "Expert": "Professional_XAUUSD_EA.ex5",
            "Symbol": "XAUUSD",
            "Period": "M15",
            "Model": "2",
            "Optimization": "0",
            "Visual": "0",
            "ReplaceReport": "1",
            "ShutdownTerminal": "1",
        }
        for key, expected in required_tester.items():
            actual = tester.get(key, "")
            if actual != expected:
                fail(f"{rel} expected [Tester] {key}={expected}, found {actual or '<missing>'}.")

        profile_name = config.name.lower()
        if "tp38" in profile_name:
            if first_value(inputs.get("InpTakeProfitATRMultiplier", "")) != "3.80":
                fail(f"{rel} tp38 config must set InpTakeProfitATRMultiplier=3.80.")
            if first_value(inputs.get("InpMaxEquityDrawdownPercent", "")) != "4.00":
                fail(f"{rel} protected candidate must set InpMaxEquityDrawdownPercent=4.00.")
        if "baseline_promoted" in profile_name:
            if first_value(inputs.get("InpTakeProfitATRMultiplier", "")) != "3.50":
                fail(f"{rel} baseline config must set InpTakeProfitATRMultiplier=3.50.")
        if first_value(inputs.get("InpShowDashboard", "false")).lower() != "false":
            fail(f"{rel} must disable dashboard for non-interrupting tester use.")
        if first_value(inputs.get("InpDashboardInTester", "false")).lower() != "false":
            fail(f"{rel} must disable tester dashboard for non-interrupting tester use.")


def main() -> int:
    check_source()
    check_hard_lock()
    check_profiles()
    check_manifest(ROOT / "outputs" / "micro_test_handoff" / "HANDOFF_MANIFEST.csv", 8, "stress micro")
    check_manifest(ROOT / "outputs" / "recent_oos_handoff" / "HANDOFF_MANIFEST.csv", 8, "recent OOS")
    check_configs(ROOT / "outputs" / "micro_test_handoff" / "configs", "stress micro")
    check_configs(ROOT / "outputs" / "recent_oos_handoff" / "configs", "recent OOS")

    print("Static repository safety audit")
    print(f"Warnings: {len(WARNINGS)}")
    for item in WARNINGS:
        print(f"WARNING: {item}")
    if FAILURES:
        print(f"Failures: {len(FAILURES)}")
        for item in FAILURES:
            print(f"FAIL: {item}")
        return 1
    print("PASS: static safety checks completed without failures.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
