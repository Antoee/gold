#!/usr/bin/env python3
"""Static MQL5 source preflight for the XAUUSD EA.

This is not a MetaEditor compile. It catches high-signal source problems before
we spend MT5 time: missing safety gates, stale source mirror, overlong inputs,
duplicate inputs, and obvious brace/string imbalance.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Professional_XAUUSD_EA.mq5"
MIRROR = ROOT / "outputs" / "Professional_XAUUSD_EA.mq5"
MAX_MQL_IDENTIFIER = 63
MAX_MT5_TESTER_INPUTS = 1000


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def strip_comments_and_strings(text: str) -> str:
    result: list[str] = []
    i = 0
    in_line_comment = False
    in_block_comment = False
    in_string = False
    quote = ""

    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
                result.append(ch)
            else:
                result.append(" ")
            i += 1
            continue

        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
                result.extend("  ")
                i += 2
            else:
                result.append("\n" if ch == "\n" else " ")
                i += 1
            continue

        if in_string:
            if ch == "\\" and nxt:
                result.extend("  ")
                i += 2
                continue
            if ch == quote:
                in_string = False
            result.append("\n" if ch == "\n" else " ")
            i += 1
            continue

        if ch == "/" and nxt == "/":
            in_line_comment = True
            result.extend("  ")
            i += 2
            continue
        if ch == "/" and nxt == "*":
            in_block_comment = True
            result.extend("  ")
            i += 2
            continue
        if ch in {"'", '"'}:
            in_string = True
            quote = ch
            result.append(" ")
            i += 1
            continue

        result.append(ch)
        i += 1

    return "".join(result)


def input_names(code: str) -> list[str]:
    names: list[str] = []
    pattern = re.compile(r"^\s*input\s+[^;\n=]*?\b([A-Za-z_][A-Za-z0-9_]*)\s*(?:=|;)", re.MULTILINE)
    for match in pattern.finditer(code):
        names.append(match.group(1))
    return names


def default_value(code: str, name: str) -> str | None:
    pattern = re.compile(rf"^\s*input\s+[^;\n=]*?\b{re.escape(name)}\s*=\s*([^;]+);", re.MULTILINE)
    match = pattern.search(code)
    if not match:
        return None
    return match.group(1).strip()


def check_balanced(code: str) -> list[str]:
    stack: list[tuple[str, int]] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    line = 1
    failures: list[str] = []
    for ch in code:
        if ch == "\n":
            line += 1
            continue
        if ch in "([{":
            stack.append((ch, line))
        elif ch in ")]}":
            if not stack or stack[-1][0] != pairs[ch]:
                failures.append(f"unmatched {ch!r} at line {line}")
                continue
            stack.pop()
    failures.extend(f"unclosed {ch!r} from line {line_no}" for ch, line_no in stack[-10:])
    return failures


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


def repo_path(value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else ROOT / path


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default=str(SOURCE.relative_to(ROOT)))
    parser.add_argument("--mirror", default=str(MIRROR.relative_to(ROOT)))
    parser.add_argument("--skip-mirror", action="store_true")
    args = parser.parse_args()
    source = repo_path(args.source)
    mirror = None if args.skip_mirror else repo_path(args.mirror)

    audit = Audit()

    audit.check(source.exists(), f"EA source exists: {display_path(source)}")
    if mirror is not None:
        audit.check(mirror.exists(), f"mirrored EA source exists: {display_path(mirror)}")
    if not source.exists():
        return 1

    if mirror is not None and mirror.exists():
        audit.check(sha256(source) == sha256(mirror), "source/mirror SHA-256 hashes match")

    text = source.read_text(encoding="utf-8", errors="replace")
    code = strip_comments_and_strings(text)

    for marker in [
        "bool TradeEnvironmentAllows(string &reason)",
        "bool TradeReadinessSafetyGateAllows()",
        "bool SymbolSafetyLockAllows()",
        "bool RealAccountSafetyLockAllows()",
        "TradeEnvironmentAllows(environmentReason)",
        "TradeReadinessSafetyGateAllows()",
        "SymbolSafetyLockAllows()",
        "RealAccountSafetyLockAllows()",
    ]:
        audit.check(marker in text, f"required safety marker exists: {marker}")

    for marker in [
        "double RiskMoneyForOrder(const ENUM_ORDER_TYPE orderType,",
        "if(!OrderCalcProfit(orderType,",
        "riskManager.LotsForRisk(signal.bias, entry, stopDistance, riskMultiplier)",
        "riskManager.ExposureAllows(signal.bias, entry, stopDistance, lots, exposureReason)",
        "InpAllowStandaloneLiquiditySweepEntry",
    ]:
        audit.check(marker in text, f"broker-risk safety marker exists: {marker}")
    audit.check("RiskMoneyForLots(" not in text,
                "obsolete raw tick-value risk helper is absent")

    for name, expected in [
        ("InpUseRealAccountSafetyLock", "true"),
        ("InpAllowRealAccountTrading", "false"),
        ("InpUseTradeReadinessSafetyGate", "false"),
        ("InpUseTradeEnvironmentGuard", "false"),
    ]:
        actual = default_value(code, name)
        audit.check(actual is not None, f"input exists: {name}")
        if actual is not None:
            audit.check(actual.lower() == expected, f"{name} default is {expected}")

    on_tick_idx = text.find("void OnTick()")
    open_signal_idx = text.find("OpenSignal(signal)", on_tick_idx)
    env_guard_idx = text.find("TradeEnvironmentAllows(environmentReason)", on_tick_idx)
    audit.check(on_tick_idx >= 0, "OnTick exists")
    audit.check(open_signal_idx >= 0, "OnTick opens signals through OpenSignal")
    audit.check(env_guard_idx >= 0 and open_signal_idx >= 0 and env_guard_idx < open_signal_idx,
                "trade environment guard runs before new entries")

    on_init_idx = text.find("int OnInit()")
    readiness_idx = text.find("TradeReadinessSafetyGateAllows()", on_init_idx)
    symbol_idx = text.find("SymbolSafetyLockAllows()", on_init_idx)
    real_idx = text.find("RealAccountSafetyLockAllows()", on_init_idx)
    audit.check(on_init_idx >= 0, "OnInit exists")
    audit.check(symbol_idx >= 0 and real_idx >= 0 and readiness_idx >= 0,
                "OnInit calls symbol, real-account, and trade-readiness gates")

    real_decl_idx = text.find("bool RealAccountSafetyLockAllows()")
    real_end_idx = text.find("int OnInit()", real_decl_idx)
    real_section = text[real_decl_idx:real_end_idx] if real_decl_idx >= 0 and real_end_idx > real_decl_idx else ""
    audit.check("tradeMode != ACCOUNT_TRADE_MODE_REAL" in real_section,
                "real-account lock allows only non-real accounts before approval checks")
    audit.check("if(!InpUseRealAccountSafetyLock)" in real_section and
                "InpUseRealAccountSafetyLock=false is not allowed on real accounts" in real_section,
                "real-account lock rejects disabled lock state on real accounts")
    normalized_real_section = real_section.replace("\r\n", "\n").replace("\r", "\n")
    audit.check("if(!InpUseRealAccountSafetyLock)\n      return true;" not in normalized_real_section,
                "real-account lock cannot be bypassed by disabling InpUseRealAccountSafetyLock")

    names = input_names(code)
    audit.check(bool(names), "input declarations parsed")
    audit.check(len(names) <= MAX_MT5_TESTER_INPUTS,
                f"input declarations stay under MT5 tester limit guard ({len(names)}/{MAX_MT5_TESTER_INPUTS})")
    duplicates = sorted({name for name in names if names.count(name) > 1})
    audit.check(not duplicates, "input declarations are unique")
    too_long = [name for name in names if len(name) > MAX_MQL_IDENTIFIER]
    audit.check(not too_long, f"input identifiers are <= {MAX_MQL_IDENTIFIER} chars")
    if too_long:
        for name in too_long[:20]:
            print(f"LONG_INPUT: {name} length={len(name)}")

    balance_failures = check_balanced(code)
    audit.check(not balance_failures, "braces, brackets, and parentheses are balanced after stripping comments/strings")
    for failure in balance_failures[:20]:
        print(f"BALANCE: {failure}")

    init_bad_return_count = len(re.findall(r"\bINIT_PARAMETERS_INCORRECT\b", code))
    audit.check(init_bad_return_count >= 3, "initialization can fail closed for safety gate violations")

    if audit.failures:
        print()
        print(f"STATIC_MQL_COMPILE_PREFLIGHT_FAIL failures={len(audit.failures)} passes={audit.passes}")
        return 1

    print()
    print(f"STATIC_MQL_COMPILE_PREFLIGHT_PASS checks={audit.passes} inputs={len(names)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
