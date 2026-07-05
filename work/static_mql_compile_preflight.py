#!/usr/bin/env python3
"""Lightweight static preflight for common MQL5 compile-risk patterns.

This does not launch MT5 or MetaEditor. It is intended to catch easy-to-fix source
issues before a non-interrupting MT5 compile/backtest environment spends time.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Professional_XAUUSD_EA.mq5"
FAILURES: list[str] = []
WARNINGS: list[str] = []


def fail(message: str) -> None:
    FAILURES.append(message)


def warn(message: str) -> None:
    WARNINGS.append(message)


def read_source() -> str:
    if not SOURCE.exists():
        fail(f"Missing EA source: {SOURCE.relative_to(ROOT)}")
        return ""
    return SOURCE.read_text(encoding="utf-8", errors="replace")


def check_required_markers(source: str) -> None:
    required = [
        '#property strict',
        '#property version   "1.09"',
        'bool NewsTimeAllowsNewTrade()',
        'bool ManualNewsWindowBlocked',
        'bool NFPFridayWindowBlocked',
        'if(!NewsTimeAllowsNewTrade())',
        'input bool   InpUseNewsTimeFilter',
        'input string InpNewsEventTime1',
    ]
    for marker in required:
        if marker not in source:
            fail(f"Missing required source marker: {marker}")


def check_forbidden_strategy_terms(source: str) -> None:
    code = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    code = re.sub(r"//.*", "", code)
    for label, pattern in {
        "martingale": r"\bmartingale\b",
        "grid": r"\bgrid\b",
        "averaging down": r"averag(?:e|ing)\s+down",
    }.items():
        if re.search(pattern, code, flags=re.I):
            fail(f"Forbidden strategy term appears in executable source: {label}")


def check_compile_risk_patterns(source: str) -> None:
    if re.search(r"int\s+\w+\s*=\s*MathMax\(", source):
        warn("An int is assigned from MathMax(...). MT5 may compile it, but explicit integer clamps are preferred before promotion testing.")
    if "StringTrimLeft(value);" in source and "StringTrimRight(value);" in source:
        # This is currently accepted MQL5 style, but keep it visible for compile review.
        warn("Manual news parsing uses StringTrimLeft/StringTrimRight; verify exact compiler signature during the next MT5 compile.")
    if re.search(r"datetime\s+\w+\s*=\s*StringToTime\(", source) is None:
        fail("Expected StringToTime datetime parsing for manual news events is missing.")


def main() -> int:
    source = read_source()
    if source:
        check_required_markers(source)
        check_forbidden_strategy_terms(source)
        check_compile_risk_patterns(source)

    print("Static MQL compile preflight")
    print(f"Warnings: {len(WARNINGS)}")
    for item in WARNINGS:
        print(f"WARNING: {item}")
    if FAILURES:
        print(f"Failures: {len(FAILURES)}")
        for item in FAILURES:
            print(f"FAIL: {item}")
        return 1
    print("PASS: no blocking static compile-preflight issues found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
