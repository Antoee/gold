#!/usr/bin/env python3
"""Static checks for the break-even probe handoff pack.

This script reads repository files only. It does not launch MT5, MetaEditor,
MetaTester, Strategy Tester, or any local backtest process.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "outputs" / "breakeven_probe_handoff"
CONFIG_DIR = PACK / "configs"
MANIFEST = PACK / "HANDOFF_MANIFEST.csv"

failures: list[str] = []


def fail(message: str) -> None:
    failures.append(message)


def first_value(value: str) -> str:
    return value.split("||", 1)[0].strip()


def parse_ini(path: Path) -> tuple[dict[str, str], dict[str, str]]:
    tester: dict[str, str] = {}
    inputs: dict[str, str] = {}
    section = ""
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith(";") or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        if section == "Tester":
            tester[key.strip()] = value.strip()
        elif section == "TesterInputs":
            inputs[key.strip()] = value.strip()
    return tester, inputs


def main() -> int:
    if not MANIFEST.exists():
        fail("Missing break-even probe manifest.")
        rows = []
    else:
        with MANIFEST.open("r", encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        if len(rows) != 4:
            fail(f"Expected 4 manifest rows, found {len(rows)}.")

    expected_profiles = {
        "baseline_promoted": ("false", "3.50", "0.00"),
        "baseline_promoted_be": ("true", "3.50", "0.00"),
        "tp38_sl18": ("false", "3.80", "4.00"),
        "tp38_sl18_be": ("true", "3.80", "4.00"),
    }

    for row in rows:
        profile = row.get("Profile", "")
        config_rel = row.get("HandoffConfig", "")
        config = ROOT / config_rel
        if profile not in expected_profiles:
            fail(f"Unexpected profile in manifest: {profile}")
            continue
        if not config.exists():
            fail(f"Missing config for {profile}: {config_rel}")
            continue

        tester, inputs = parse_ini(config)
        required_tester = {
            "Expert": "Professional_XAUUSD_EA.ex5",
            "Symbol": "XAUUSD",
            "Period": "M15",
            "Model": "2",
            "FromDate": "2026.01.01",
            "ToDate": "2026.07.02",
            "Optimization": "0",
            "Visual": "0",
            "ReplaceReport": "1",
            "ShutdownTerminal": "1",
        }
        for key, expected in required_tester.items():
            actual = tester.get(key, "")
            if actual != expected:
                fail(f"{config_rel} expected [Tester] {key}={expected}, found {actual or '<missing>'}.")

        expected_be, expected_tp, expected_dd = expected_profiles[profile]
        checks = {
            "InpUseBreakEven": expected_be,
            "InpBreakEvenTriggerATR": "1.00",
            "InpBreakEvenOffsetATR": "0.05",
            "InpTakeProfitATRMultiplier": expected_tp,
            "InpMaxEquityDrawdownPercent": expected_dd,
            "InpShowDashboard": "false",
            "InpDashboardInTester": "false",
        }
        for key, expected in checks.items():
            actual = first_value(inputs.get(key, ""))
            if actual.lower() != expected.lower():
                fail(f"{config_rel} expected {key}={expected}, found {actual or '<missing>'}.")

    if failures:
        print("Break-even probe static audit FAIL")
        for item in failures:
            print(f"FAIL: {item}")
        return 1
    print("PASS: break-even probe handoff is statically consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
